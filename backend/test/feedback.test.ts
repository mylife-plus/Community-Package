import { env, exports } from 'cloudflare:workers';
import { beforeAll, describe, expect, it } from 'vitest';

const BASE = 'https://example.com/v1/feedback';
const ANON_A = '11111111-1111-4111-8111-111111111111';
const ANON_B = '22222222-2222-4222-8222-222222222222';
const T0 = Date.UTC(2026, 9, 1);
const HOUR = 3_600_000;

type ListBody = {
  items: Array<Record<string, unknown> & { number: number }>;
  nextCursor: string | null;
};

function get(url: string, headers: Record<string, string> = { 'X-App-Id': 'inventory' }) {
  return exports.default.fetch(url, { headers });
}

beforeAll(async () => {
  const db = env.DB;
  await db.batch([
    db.prepare("INSERT INTO apps (id, name, next_number) VALUES ('inventory', 'Inventory', 26)"),
    db.prepare("INSERT INTO apps (id, name, next_number) VALUES ('spacetime', 'SpaceTime', 3)"),
  ]);

  const insert = db.prepare(
    `INSERT INTO feedback (id, app_id, number, type, text, lang, author_id, status, cost_cents,
       screen_path, steps_json, os_version, app_version, device_model,
       reaction_count, comment_count, created_at, updated_at, last_activity_at)
     VALUES (?1, ?2, ?3, ?4, ?5, 'en', ?6, ?7, ?8, ?9, ?10, ?11, ?12, ?13, ?14, 0, ?15, ?15, ?15)`,
  );
  const rows = [];
  // Inventory #1..#25, one hour apart, so #25 is the newest.
  for (let n = 1; n <= 25; n++) {
    const isProblem = n === 25;
    rows.push(
      insert.bind(
        n,
        'inventory',
        n,
        isProblem ? 'problem' : 'idea',
        `Inventory feedback ${n}`,
        n === 24 ? ANON_A : ANON_B,
        n === 23 ? 'in_progress' : null,
        n === 23 ? 5000 : null,
        isProblem ? 'Inventory > Sell Item > Add Item' : null,
        isProblem ? JSON.stringify(['Tap plus', 'Add an item']) : null,
        isProblem ? 'iOS 17.4.1' : null,
        isProblem ? '1.0.0' : null,
        isProblem ? 'iPhone 15 Pro' : null,
        n === 25 ? 1 : 0,
        T0 + n * HOUR,
      ),
    );
  }
  // SpaceTime items, newer than every Inventory item.
  for (let n = 1; n <= 2; n++) {
    rows.push(
      insert.bind(100 + n, 'spacetime', n, 'idea', `SpaceTime feedback ${n}`, ANON_B, null, null,
        null, null, null, null, null, 0, T0 + 100 * HOUR + n),
    );
  }
  rows.push(
    db.prepare('INSERT INTO reactions (feedback_id, anon_id, created_at) VALUES (25, ?1, ?2)').bind(ANON_A, T0),
  );
  await db.batch(rows);
});

describe('GET /v1/feedback headers', () => {
  it('rejects a missing X-App-Id', async () => {
    const res = await get(BASE, {});

    expect(res.status).toBe(400);
    expect(await res.json()).toEqual({
      error: { code: 'bad_request', message: 'Missing X-App-Id header' },
    });
  });

  it('rejects an unknown app', async () => {
    const res = await get(BASE, { 'X-App-Id': 'nope' });

    expect(res.status).toBe(400);
    expect(await res.json()).toEqual({ error: { code: 'bad_request', message: 'Unknown app' } });
  });

  it('rejects a malformed X-Anon-Id', async () => {
    const res = await get(BASE, { 'X-App-Id': 'inventory', 'X-Anon-Id': 'not-a-uuid' });

    expect(res.status).toBe(400);
  });

  it('rejects a malformed cursor', async () => {
    const res = await get(`${BASE}?cursor=abc`);

    expect(res.status).toBe(400);
    expect(await res.json()).toEqual({ error: { code: 'bad_request', message: 'Invalid cursor' } });
  });
});

describe('GET /v1/feedback list', () => {
  it('returns 20 items of the app, newest first, with a cursor', async () => {
    const res = await get(BASE);
    const body = (await res.json()) as ListBody;

    expect(res.status).toBe(200);
    expect(body.items).toHaveLength(20);
    expect(body.items.map((i) => i.number)).toEqual(
      Array.from({ length: 20 }, (_, i) => 25 - i),
    );
    expect(body.items.every((i) => String(i.text).startsWith('Inventory'))).toBe(true);
    expect(body.nextCursor).toEqual(expect.any(String));
  });

  it('returns the rest on the next page, with no further cursor', async () => {
    const first = (await (await get(BASE)).json()) as ListBody;
    const res = await get(`${BASE}?cursor=${first.nextCursor}`);
    const body = (await res.json()) as ListBody;

    expect(body.items.map((i) => i.number)).toEqual([5, 4, 3, 2, 1]);
    expect(body.nextCursor).toBeNull();
  });

  it('only shows the requesting app', async () => {
    const res = await get(BASE, { 'X-App-Id': 'spacetime' });
    const body = (await res.json()) as ListBody;

    expect(body.items.map((i) => i.text)).toEqual(['SpaceTime feedback 2', 'SpaceTime feedback 1']);
  });

  it('returns the full item shape, without author IDs', async () => {
    const body = (await (await get(BASE)).json()) as ListBody;

    expect(body.items[0]).toEqual({
      number: 25,
      type: 'problem',
      text: 'Inventory feedback 25',
      lang: 'en',
      status: null,
      costCents: null,
      githubUrl: null,
      screenPath: 'Inventory > Sell Item > Add Item',
      steps: ['Tap plus', 'Add an item'],
      description: null,
      osVersion: 'iOS 17.4.1',
      appVersion: '1.0.0',
      deviceModel: 'iPhone 15 Pro',
      reactionCount: 1,
      commentCount: 0,
      reacted: false,
      isMine: false,
      createdAt: new Date(T0 + 25 * HOUR).toISOString(),
      updatedAt: new Date(T0 + 25 * HOUR).toISOString(),
    });
    expect(body.items[2]).toMatchObject({ number: 23, status: 'in_progress', costCents: 5000 });
    expect(JSON.stringify(body)).not.toContain(ANON_B);
  });

  it('marks own items and own reactions for the caller', async () => {
    const res = await get(BASE, { 'X-App-Id': 'inventory', 'X-Anon-Id': ANON_A.toUpperCase() });
    const body = (await res.json()) as ListBody;
    const byNumber = new Map(body.items.map((i) => [i.number, i]));

    expect(byNumber.get(25)).toMatchObject({ reacted: true, isMine: false });
    expect(byNumber.get(24)).toMatchObject({ reacted: false, isMine: true });
    expect(byNumber.get(23)).toMatchObject({ reacted: false, isMine: false });
  });
});
