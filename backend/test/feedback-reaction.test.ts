import { env, exports } from 'cloudflare:workers';
import { beforeAll, describe, expect, it } from 'vitest';
import { RATE_LIMIT_TEST_TIMEOUT, awaitFreshWindow } from './rate-limit-window';

const BASE = 'https://example.com/v1/feedback';
const AUTHOR = '11111111-1111-4111-8111-111111111111';
const T0 = Date.UTC(2026, 9, 1);

type Item = Record<string, unknown> & { number: number; reactionCount: number; reacted: boolean };

function react(
  number: number | string,
  on: boolean,
  { app = 'inventory', anonId = crypto.randomUUID(), ip }: { app?: string; anonId?: string | null; ip?: string } = {},
) {
  const headers: Record<string, string> = { 'X-App-Id': app };
  if (anonId) headers['X-Anon-Id'] = anonId;
  if (ip) headers['CF-Connecting-IP'] = ip;
  return exports.default.fetch(`${BASE}/${number}/reaction`, { method: on ? 'PUT' : 'DELETE', headers });
}

async function reactionRows(number: number): Promise<number> {
  const row = await env.DB.prepare(
    `SELECT COUNT(*) AS n FROM reactions r JOIN feedback f ON f.id = r.feedback_id
     WHERE f.app_id = 'inventory' AND f.number = ?1`,
  )
    .bind(number)
    .first<{ n: number }>();
  return row?.n ?? 0;
}

beforeAll(async () => {
  const db = env.DB;
  const insert = db.prepare(
    `INSERT INTO feedback (app_id, number, type, text, lang, author_id, reaction_count,
       created_at, updated_at, last_activity_at)
     VALUES (?1, ?2, 'idea', ?3, 'en', ?4, 0, ?5, ?5, ?5)`,
  );
  await db.batch([
    db.prepare("INSERT INTO apps (id, name, next_number) VALUES ('inventory', 'Inventory', 5)"),
    db.prepare("INSERT INTO apps (id, name, next_number) VALUES ('spacetime', 'SpaceTime', 51)"),
    ...[1, 2, 3, 4].map((n) => insert.bind('inventory', n, `Inventory ${n}`, AUTHOR, T0 + n)),
    insert.bind('spacetime', 50, 'SpaceTime 50', AUTHOR, T0),
  ]);
});

describe('PUT and DELETE /v1/feedback/:number/reaction', () => {
  it('adds a heart and returns the item', async () => {
    const anonId = crypto.randomUUID();
    const res = await react(1, true, { anonId });

    expect(res.status).toBe(200);
    expect(await res.json()).toMatchObject({ number: 1, text: 'Inventory 1', reactionCount: 1, reacted: true });
    expect(await reactionRows(1)).toBe(1);
  });

  it('counts a repeated heart once', async () => {
    const anonId = crypto.randomUUID();
    await react(2, true, { anonId });
    const res = await react(2, true, { anonId });

    expect(await res.json()).toMatchObject({ reactionCount: 1, reacted: true });
    expect(await reactionRows(2)).toBe(1);
  });

  it('removes a heart, and a repeated removal changes nothing', async () => {
    const anonId = crypto.randomUUID();
    await react(3, true, { anonId });
    await react(3, true);

    const removed = (await (await react(3, false, { anonId })).json()) as Item;
    expect(removed).toMatchObject({ reactionCount: 1, reacted: false });

    const again = (await (await react(3, false, { anonId })).json()) as Item;
    expect(again).toMatchObject({ reactionCount: 1, reacted: false });
    expect(await reactionRows(3)).toBe(1);
  });

  it('lets the author heart their own feedback', async () => {
    const res = await react(4, true, { anonId: AUTHOR });

    expect(await res.json()).toMatchObject({ number: 4, isMine: true, reacted: true });
  });

  it('recounts from the reactions, fixing a count that drifted', async () => {
    await env.DB.prepare("UPDATE feedback SET reaction_count = 99 WHERE app_id = 'inventory' AND number = 1").run();

    const res = await react(1, true);

    expect(await res.json()).toMatchObject({ reactionCount: (await reactionRows(1)) });
    expect(await reactionRows(1)).toBe(2);
  });

  it('leaves the update and activity times alone', async () => {
    await react(2, true);

    const row = await env.DB.prepare(
      "SELECT updated_at, last_activity_at FROM feedback WHERE app_id = 'inventory' AND number = 2",
    ).first<{ updated_at: number; last_activity_at: number }>();
    expect(row).toEqual({ updated_at: T0 + 2, last_activity_at: T0 + 2 });
  });

  it('answers 404 for a number the app does not have', async () => {
    for (const on of [true, false]) {
      const res = await react(50, on);

      expect(res.status).toBe(404);
      expect(await res.json()).toEqual({ error: { code: 'not_found', message: 'Feedback not found' } });
    }
    const spacetime = await env.DB.prepare(
      "SELECT reaction_count FROM feedback WHERE app_id = 'spacetime' AND number = 50",
    ).first<{ reaction_count: number }>();
    expect(spacetime?.reaction_count).toBe(0);
  });

  it('rejects a number that is not a positive whole number', async () => {
    for (const number of ['abc', '0', '-1', '1.5', '01']) {
      const res = await react(number, true);

      expect(res.status).toBe(400);
      expect(await res.json()).toEqual({ error: { code: 'bad_request', message: 'Invalid number' } });
    }
  });

  it('needs an anonymous ID', async () => {
    const res = await react(1, true, { anonId: null });

    expect(res.status).toBe(400);
    expect(await res.json()).toEqual({ error: { code: 'bad_request', message: 'Missing X-Anon-Id header' } });
  });

  it('shows the heart as the caller\'s own only to that caller', async () => {
    const anonId = crypto.randomUUID();
    await react(4, true, { anonId });

    const list = async (id: string) => {
      const res = await exports.default.fetch(BASE, { headers: { 'X-App-Id': 'inventory', 'X-Anon-Id': id } });
      const body = (await res.json()) as { items: Item[] };
      return body.items.find((i) => i.number === 4);
    };
    expect(await list(anonId)).toMatchObject({ reacted: true });
    expect(await list(crypto.randomUUID())).toMatchObject({ reacted: false });
  });
});

describe('reaction rate limits', { timeout: RATE_LIMIT_TEST_TIMEOUT }, () => {
  it('allows 30 hearts per minute per anonymous ID, apart from posts', async () => {
    await awaitFreshWindow();
    const anonId = crypto.randomUUID();
    for (let i = 0; i < 30; i++) {
      expect((await react(1, i % 2 === 0, { anonId })).status).toBe(200);
    }

    const res = await react(1, true, { anonId });
    expect(res.status).toBe(429);
    expect(await res.json()).toEqual({
      error: { code: 'rate_limited', message: 'Too many hearts, try again soon' },
    });
    // Posting still works for the same user, and someone else can still heart.
    const post = await exports.default.fetch(`${BASE}?lang=en`, {
      method: 'POST',
      headers: { 'X-App-Id': 'inventory', 'X-Anon-Id': anonId, 'Content-Type': 'application/json' },
      body: JSON.stringify({ type: 'idea', text: 'Still allowed' }),
    });
    expect(post.status).toBe(201);
    expect((await react(1, true)).status).toBe(200);
  });

  it('allows 120 hearts per minute per IP, across IDs', async () => {
    await awaitFreshWindow();
    const ip = '203.0.113.9';
    for (let i = 0; i < 120; i++) {
      expect((await react(2, true, { ip })).status).toBe(200);
    }

    expect((await react(2, true, { ip })).status).toBe(429);
    expect((await react(2, true, { ip: '203.0.113.10' })).status).toBe(200);
  });
});
