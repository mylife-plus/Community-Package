import { env, exports } from 'cloudflare:workers';
import { beforeAll, describe, expect, it } from 'vitest';

const BASE = 'https://example.com/v1/feedback';

type Item = Record<string, unknown> & { number: number };

function post(
  body: unknown,
  { app = 'inventory', anonId = newAnonId(), lang = 'en', ip }: {
    app?: string | null;
    anonId?: string | null;
    lang?: string | null;
    ip?: string;
  } = {},
) {
  const headers: Record<string, string> = { 'Content-Type': 'application/json' };
  if (app) headers['X-App-Id'] = app;
  if (anonId) headers['X-Anon-Id'] = anonId;
  if (ip) headers['CF-Connecting-IP'] = ip;
  const url = lang === null ? BASE : `${BASE}?lang=${lang}`;
  return exports.default.fetch(url, {
    method: 'POST',
    headers,
    body: typeof body === 'string' ? body : JSON.stringify(body),
  });
}

function newAnonId() {
  return crypto.randomUUID();
}

async function nextNumber(app: string) {
  const row = await env.DB.prepare('SELECT next_number FROM apps WHERE id = ?').bind(app).first<{ next_number: number }>();
  return row?.next_number;
}

/**
 * Local rate limit windows are aligned to the wall clock (miniflare
 * src/workers/ratelimit/ratelimit-object.worker.ts: epoch = now / period).
 * A burst that crosses a window edge would be split over two windows, so
 * wait for a fresh window when the current one is about to end.
 */
async function awaitFreshWindow() {
  const intoWindow = Date.now() % 60_000;
  if (intoWindow > 50_000) await new Promise((r) => setTimeout(r, 60_000 - intoWindow + 50));
}

beforeAll(async () => {
  await env.DB.batch([
    env.DB.prepare("INSERT INTO apps (id, name, next_number) VALUES ('inventory', 'Inventory', 26)"),
    env.DB.prepare("INSERT INTO apps (id, name, next_number) VALUES ('spacetime', 'SpaceTime', 3)"),
  ]);
});

describe('POST /v1/feedback', () => {
  it('creates feedback with the next number of the app', async () => {
    const anonId = newAnonId();
    const res = await post({ type: 'improvement', text: '  Show totals per shelf  ' }, { anonId, lang: 'de' });

    expect(res.status).toBe(201);
    const item = (await res.json()) as Item;
    expect(item).toEqual({
      number: 26,
      type: 'improvement',
      text: 'Show totals per shelf',
      lang: 'de',
      status: null,
      costCents: null,
      githubUrl: null,
      screenPath: null,
      steps: null,
      description: null,
      osVersion: null,
      appVersion: null,
      deviceModel: null,
      reactionCount: 0,
      commentCount: 0,
      reacted: false,
      isMine: true,
      createdAt: expect.any(String),
      updatedAt: item.createdAt,
    });
    expect(await nextNumber('inventory')).toBe(27);
  });

  it('keeps the author ID in the database, never in the response', async () => {
    const anonId = newAnonId();
    const res = await post({ type: 'idea', text: 'Dark app icon' }, { anonId });
    const item = (await res.json()) as Item;

    expect(JSON.stringify(item)).not.toContain(anonId);
    const row = await env.DB.prepare('SELECT author_id FROM feedback WHERE app_id = ? AND number = ?')
      .bind('inventory', item.number)
      .first<{ author_id: string }>();
    expect(row?.author_id).toBe(anonId);
  });

  it('numbers each app separately', async () => {
    const before = await nextNumber('inventory');
    const res = await post({ type: 'idea', text: 'Repeat a session' }, { app: 'spacetime' });

    expect(((await res.json()) as Item).number).toBe(3);
    expect(await nextNumber('spacetime')).toBe(4);
    expect(await nextNumber('inventory')).toBe(before);
  });

  it('gives posts sent at the same time different numbers', async () => {
    const start = (await nextNumber('inventory'))!;
    const responses = await Promise.all(
      Array.from({ length: 5 }, (_, i) => post({ type: 'idea', text: `Parallel ${i}` })),
    );
    const numbers = await Promise.all(responses.map(async (r) => ((await r.json()) as Item).number));

    expect(responses.every((r) => r.status === 201)).toBe(true);
    expect([...numbers].sort((a, b) => a - b)).toEqual([start, start + 1, start + 2, start + 3, start + 4]);
    expect(await nextNumber('inventory')).toBe(start + 5);
  });

  it('puts the new post first in the list', async () => {
    const anonId = newAnonId();
    const created = (await (await post({ type: 'improvement', text: 'Newest one' }, { anonId })).json()) as Item;

    const res = await exports.default.fetch(BASE, { headers: { 'X-App-Id': 'inventory', 'X-Anon-Id': anonId } });
    const list = (await res.json()) as { items: Item[] };
    expect(list.items[0]).toEqual(created);
  });

  it('records a "created" timeline event', async () => {
    const item = (await (await post({ type: 'idea', text: 'Timeline please' })).json()) as Item & { createdAt: string };

    const { results } = await env.DB.prepare(
      `SELECT e.kind, e.at FROM feedback_events e JOIN feedback f ON f.id = e.feedback_id
       WHERE f.app_id = 'inventory' AND f.number = ?`,
    )
      .bind(item.number)
      .all<{ kind: string; at: number }>();
    expect(results).toEqual([{ kind: 'created', at: Date.parse(item.createdAt) }]);
  });

  it('counts emoji as one character each', async () => {
    const res = await post({ type: 'idea', text: '👍🏽'.repeat(2000) });

    expect(res.status).toBe(201);
  });
});

describe('POST /v1/feedback rejects', () => {
  const cases: Array<[string, unknown, Parameters<typeof post>[1], string]> = [
    ['a missing X-Anon-Id', { type: 'idea', text: 'Hi' }, { anonId: null }, 'Missing X-Anon-Id header'],
    ['a problem without steps', { type: 'problem', text: 'Crash' }, {}, 'Invalid steps'],
    ['an unknown type', { type: 'bug', text: 'Crash' }, {}, 'Invalid type'],
    ['a missing text', { type: 'idea' }, {}, 'Invalid text'],
    ['an empty text', { type: 'idea', text: '' }, {}, 'Text must be 1 to 2000 characters'],
    ['a text of only spaces', { type: 'idea', text: ' \n\t ' }, {}, 'Text must be 1 to 2000 characters'],
    ['a text over 2000 characters', { type: 'idea', text: 'a'.repeat(2001) }, {}, 'Text must be 1 to 2000 characters'],
    ['a body that is not JSON', 'type=idea', {}, 'Body must be JSON'],
    ['a missing lang', { type: 'idea', text: 'Hi' }, { lang: null }, 'Invalid lang'],
    ['a malformed lang', { type: 'idea', text: 'Hi' }, { lang: 'EN-us' }, 'Invalid lang'],
    ['an unknown app', { type: 'idea', text: 'Hi' }, { app: 'nope' }, 'Unknown app'],
  ];

  it.each(cases)('%s with 400', async (_, body, options, message) => {
    const before = await nextNumber('inventory');
    const res = await post(body, options);

    expect(res.status).toBe(400);
    expect(((await res.json()) as { error: { code: string; message: string } }).error).toMatchObject({
      code: 'bad_request',
      message,
    });
    expect(await nextNumber('inventory')).toBe(before);
  });
});

describe('POST /v1/feedback rate limits', () => {
  it('allows 10 posts per minute per anonymous ID', async () => {
    await awaitFreshWindow();
    const anonId = newAnonId();
    for (let i = 0; i < 10; i++) {
      expect((await post({ type: 'idea', text: `Burst ${i}` }, { anonId })).status).toBe(201);
    }

    const res = await post({ type: 'idea', text: 'One too many' }, { anonId });
    expect(res.status).toBe(429);
    expect(await res.json()).toEqual({
      error: { code: 'rate_limited', message: 'Too many posts, try again soon' },
    });
    // Someone else can still post.
    expect((await post({ type: 'idea', text: 'Other user' })).status).toBe(201);
  });

  it('allows 60 posts per minute per IP, across IDs', async () => {
    await awaitFreshWindow();
    const ip = '203.0.113.7';
    for (let i = 0; i < 60; i++) {
      expect((await post({ type: 'idea', text: `Shared IP ${i}` }, { ip })).status).toBe(201);
    }

    expect((await post({ type: 'idea', text: 'One too many' }, { ip })).status).toBe(429);
    expect((await post({ type: 'idea', text: 'Other IP' }, { ip: '203.0.113.8' })).status).toBe(201);
  });
});
