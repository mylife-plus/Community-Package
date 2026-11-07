import { env, exports } from 'cloudflare:workers';
import { beforeAll, describe, expect, it } from 'vitest';

const BASE = 'https://example.com/v1/feedback';
const T0 = Date.UTC(2026, 9, 1);
const HOUR = 3_600_000;

type ListBody = {
  items: Array<Record<string, unknown> & { number: number }>;
  nextCursor: string | null;
};

type Row = {
  number: number;
  type: 'improvement' | 'problem' | 'idea';
  status: 'planned' | 'in_progress' | 'done' | null;
  reactions: number;
  comments: number;
  createdAt: number;
  text: string;
};

const TYPES = ['idea', 'improvement', 'problem'] as const;
const STATUS: Record<number, Row['status']> = {
  2: 'planned', 6: 'planned', 10: 'planned',
  3: 'in_progress', 7: 'in_progress',
  4: 'done', 8: 'done', 12: 'done',
};
// No text holds its own number, so number search and text search can be told apart.
const TEXT: Record<number, string> = {
  5: 'Scan a barcode to find stock',
  7: 'Crashes after 21 items in the cart',
  9: 'Barcodes for every shelf',
  11: 'Käse is not found by the search',
  14: 'Use "quote" and -minus signs in names',
  21: 'Totals per shelf',
};

// Inventory #1..#25, one hour apart. Counts repeat, so ties are common.
const ROWS: Row[] = Array.from({ length: 25 }, (_, i) => {
  const n = i + 1;
  return {
    number: n,
    type: TYPES[n % 3]!,
    status: STATUS[n] ?? null,
    reactions: n % 5,
    comments: (25 - n) % 4,
    createdAt: T0 + n * HOUR,
    text: `${TEXT[n] ?? 'Something to change'}, please.`,
  };
});

const newest = (a: Row, b: Row) => b.createdAt - a.createdAt;
const ORDERS: Record<string, (a: Row, b: Row) => number> = {
  newest,
  oldest: (a, b) => a.createdAt - b.createdAt,
  reactions: (a, b) => b.reactions - a.reactions || newest(a, b),
  comments: (a, b) => b.comments - a.comments || newest(a, b),
};

function numbers(rows: Row[], sort = 'newest'): number[] {
  return [...rows].sort(ORDERS[sort]).map((r) => r.number);
}

function get(params: Record<string, string> = {}, app = 'inventory') {
  const query = new URLSearchParams(params).toString();
  return exports.default.fetch(query ? `${BASE}?${query}` : BASE, { headers: { 'X-App-Id': app } });
}

async function list(params: Record<string, string> = {}): Promise<ListBody> {
  const res = await get(params);
  expect(res.status).toBe(200);
  return (await res.json()) as ListBody;
}

/** Every page of a query, in order. */
async function allPages(params: Record<string, string> = {}): Promise<{ numbers: number[]; pages: number }> {
  const found: number[] = [];
  let cursor: string | null = null;
  let pages = 0;
  do {
    const body: ListBody = await list(cursor ? { ...params, cursor } : params);
    found.push(...body.items.map((i) => i.number));
    cursor = body.nextCursor;
    pages++;
  } while (cursor && pages < 10);
  return { numbers: found, pages };
}

async function expectBadRequest(params: Record<string, string>, message: string) {
  const res = await get(params);
  expect(res.status).toBe(400);
  expect(await res.json()).toEqual({ error: { code: 'bad_request', message } });
}

beforeAll(async () => {
  const db = env.DB;
  await db.batch([
    db.prepare("INSERT INTO apps (id, name, next_number) VALUES ('inventory', 'Inventory', 26)"),
    db.prepare("INSERT INTO apps (id, name, next_number) VALUES ('spacetime', 'SpaceTime', 3)"),
  ]);
  const insert = db.prepare(
    `INSERT INTO feedback (app_id, number, type, text, lang, status, reaction_count, comment_count,
       created_at, updated_at, last_activity_at)
     VALUES (?1, ?2, ?3, ?4, 'en', ?5, ?6, ?7, ?8, ?8, ?8)`,
  );
  await db.batch([
    ...ROWS.map((r) =>
      insert.bind('inventory', r.number, r.type, r.text, r.status, r.reactions, r.comments, r.createdAt),
    ),
    // Another app with matching words and numbers, never in Inventory's results.
    insert.bind('spacetime', 21, 'idea', 'Scan a barcode on the shelf', null, 9, 9, T0),
  ]);
});

describe('GET /v1/feedback sort', () => {
  for (const sort of ['newest', 'oldest', 'reactions', 'comments']) {
    it(`pages through every item by ${sort}`, async () => {
      const { numbers: found, pages } = await allPages({ sort });

      expect(pages).toBe(2);
      expect(found).toEqual(numbers(ROWS, sort));
    });
  }

  it('sorts newest first without a sort', async () => {
    const body = await list();

    expect(body.items.map((i) => i.number)).toEqual(numbers(ROWS).slice(0, 20));
  });

  it('rejects an unknown sort', async () => {
    await expectBadRequest({ sort: 'random' }, 'Invalid sort');
  });

  it('rejects a cursor made for another sort', async () => {
    const first = await list({ sort: 'newest' });

    await expectBadRequest({ sort: 'reactions', cursor: first.nextCursor! }, 'Invalid cursor');
  });

  it('rejects a cursor in the old format', async () => {
    const old = btoa(JSON.stringify([T0, 5])).replace(/=+$/, '');

    await expectBadRequest({ cursor: old }, 'Invalid cursor');
  });
});

describe('GET /v1/feedback filters', () => {
  it('filters by one type', async () => {
    const { numbers: found } = await allPages({ type: 'idea' });

    expect(found).toEqual(numbers(ROWS.filter((r) => r.type === 'idea')));
  });

  it('filters by several types', async () => {
    const { numbers: found } = await allPages({ type: 'idea,problem' });

    expect(found).toEqual(numbers(ROWS.filter((r) => r.type !== 'improvement')));
  });

  it('filters by several statuses', async () => {
    const { numbers: found } = await allPages({ status: 'planned,done' });

    expect(found).toEqual(numbers(ROWS.filter((r) => r.status === 'planned' || r.status === 'done')));
  });

  it('combines type, status and sort', async () => {
    const { numbers: found } = await allPages({ type: 'improvement,idea', status: 'in_progress,done', sort: 'oldest' });

    const expected = ROWS.filter(
      (r) => r.type !== 'problem' && (r.status === 'in_progress' || r.status === 'done'),
    );
    expect(found).toEqual(numbers(expected, 'oldest'));
    expect(found.length).toBeGreaterThan(0);
  });

  it('treats a blank filter as no filter', async () => {
    const { numbers: found } = await allPages({ type: '', status: '' });

    expect(found).toHaveLength(25);
  });

  it('rejects unknown values', async () => {
    await expectBadRequest({ type: 'idea,bug' }, 'Invalid type');
    await expectBadRequest({ status: 'open' }, 'Invalid status');
  });
});

describe('GET /v1/feedback search', () => {
  const search = async (q: string, params: Record<string, string> = {}) =>
    (await allPages({ ...params, q })).numbers;

  it('matches the start of words, ignoring case', async () => {
    expect(await search('barc')).toEqual([9, 5]);
    expect(await search('BARCODE')).toEqual([9, 5]);
  });

  it('ignores accents', async () => {
    expect(await search('kase')).toEqual([11]);
    expect(await search('Käse')).toEqual([11]);
  });

  it('needs every word', async () => {
    expect(await search('shelf barcodes')).toEqual([9]);
    expect(await search('shelf')).toEqual([21, 9]);
  });

  it('finds a number, with or without #, and the same number in texts', async () => {
    expect(await search('#21')).toEqual([21, 7]);
    expect(await search('21')).toEqual([21, 7]);
    expect(await search('# 3')).toEqual([3]);
  });

  it('treats quotes, operators and brackets as plain words', async () => {
    expect(await search('"quote" AND -minus*')).toEqual([14]);
    expect(await search('NEAR( barcode )')).toEqual([]);
    expect(await search('shelf OR')).toEqual([]);
  });

  it('ignores a search without words', async () => {
    expect(await search('#')).toHaveLength(25);
    expect(await search('  ')).toHaveLength(25);
  });

  it('pages through search results', async () => {
    const { numbers: found, pages } = await allPages({ q: 'please', sort: 'reactions' });

    expect(pages).toBe(2);
    expect(found).toEqual(numbers(ROWS, 'reactions'));
  });

  it('combines search with a filter and a sort', async () => {
    expect(await search('shelf', { type: 'idea', sort: 'oldest' })).toEqual([9, 21]);
    expect(await search('shelf', { type: 'problem' })).toEqual([]);
  });

  it('stays within the app', async () => {
    const res = await get({ q: 'barcode' }, 'spacetime');
    const body = (await res.json()) as ListBody;

    expect(body.items.map((i) => i.number)).toEqual([21]);
  });

  it('rejects a search over 100 characters', async () => {
    await expectBadRequest({ q: 'a'.repeat(101) }, 'Search must be at most 100 characters');
    expect((await get({ q: 'ä'.repeat(100) })).status).toBe(200);
  });
});
