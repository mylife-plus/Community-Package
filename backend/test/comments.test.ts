import { env, exports } from 'cloudflare:workers';
import { beforeAll, describe, expect, it } from 'vitest';
import { RATE_LIMIT_TEST_TIMEOUT, awaitFreshWindow } from './rate-limit-window';

const ORIGIN = 'https://example.com/v1';
const AUTHOR = '11111111-1111-4111-8111-111111111111';
const OTHER = '22222222-2222-4222-8222-222222222222';
const T0 = Date.UTC(2026, 9, 1);

type Comment = {
  id: number;
  parentId: number | null;
  text: string;
  lang: string;
  isAdmin: boolean;
  isMine: boolean;
  deleted: boolean;
  edited: boolean;
  createdAt: string;
  updatedAt: string;
  replyCount: number;
  replies: Comment[];
};
type Page = { items: Comment[]; nextCursor: string | null };
type Item = Record<string, unknown> & { number: number; commentCount: number; isMine: boolean };

type Options = { app?: string; anonId?: string | null; ip?: string };

function request(method: string, path: string, { app = 'inventory', anonId = null, ip }: Options = {}, body?: unknown) {
  const headers: Record<string, string> = { 'X-App-Id': app };
  if (anonId) headers['X-Anon-Id'] = anonId;
  if (ip) headers['CF-Connecting-IP'] = ip;
  if (body !== undefined) headers['Content-Type'] = 'application/json';
  return exports.default.fetch(`${ORIGIN}${path}`, {
    method,
    headers,
    body: body === undefined ? undefined : typeof body === 'string' ? body : JSON.stringify(body),
  });
}

async function list(number: number, query = '', options: Options = {}): Promise<Page> {
  const res = await request('GET', `/feedback/${number}/comments${query}`, options);
  expect(res.status).toBe(200);
  return (await res.json()) as Page;
}

function comment(number: number, body: unknown, options: Options = {}, lang = 'en') {
  return request('POST', `/feedback/${number}/comments?lang=${lang}`, { anonId: crypto.randomUUID(), ...options }, body);
}

async function created(number: number, body: unknown, options: Options = {}) {
  const res = await comment(number, body, options);
  expect(res.status).toBe(201);
  return (await res.json()) as { comment: Comment; feedback: Item };
}

/** Feedback row ID for an inventory number. */
async function feedbackRowId(number: number, app = 'inventory'): Promise<number> {
  const row = await env.DB.prepare('SELECT id FROM feedback WHERE app_id = ?1 AND number = ?2')
    .bind(app, number)
    .first<{ id: number }>();
  return row!.id;
}

/** Inserts a comment directly, with a fixed time. Returns its ID. */
async function seed(
  number: number,
  text: string,
  { parentId = null, author = OTHER, admin = false, at = T0 }: {
    parentId?: number | null;
    author?: string | null;
    admin?: boolean;
    at?: number;
  } = {},
): Promise<number> {
  const row = await env.DB.prepare(
    `INSERT INTO comments (feedback_id, parent_id, author_id, is_admin, text, lang, created_at, updated_at)
     VALUES (?1, ?2, ?3, ?4, ?5, 'en', ?6, ?6) RETURNING id`,
  )
    .bind(await feedbackRowId(number), parentId, author, admin ? 1 : 0, text, at)
    .first<{ id: number }>();
  return row!.id;
}

async function feedbackRow(number: number) {
  return env.DB.prepare(
    'SELECT comment_count, updated_at, last_activity_at FROM feedback WHERE app_id = ?1 AND number = ?2',
  )
    .bind('inventory', number)
    .first<{ comment_count: number; updated_at: number; last_activity_at: number }>();
}

beforeAll(async () => {
  const db = env.DB;
  const insert = db.prepare(
    `INSERT INTO feedback (app_id, number, type, text, lang, author_id, created_at, updated_at, last_activity_at)
     VALUES (?1, ?2, 'idea', ?3, 'en', ?4, ?5, ?5, ?5)`,
  );
  await db.batch([
    db.prepare("INSERT INTO apps (id, name, next_number) VALUES ('inventory', 'Inventory', 31)"),
    db.prepare("INSERT INTO apps (id, name, next_number) VALUES ('spacetime', 'SpaceTime', 2)"),
    ...Array.from({ length: 30 }, (_, i) => insert.bind('inventory', i + 1, `Inventory ${i + 1}`, AUTHOR, T0)),
    insert.bind('spacetime', 1, 'SpaceTime 1', AUTHOR, T0),
  ]);
});

describe('GET /v1/feedback/:number', () => {
  it('returns the feedback as seen by the caller', async () => {
    const res = await request('GET', '/feedback/1', { anonId: AUTHOR });
    expect(res.status).toBe(200);
    expect(await res.json()).toMatchObject({ number: 1, text: 'Inventory 1', isMine: true, commentCount: 0 });
  });

  it('answers 404 for a number of another app or no feedback', async () => {
    expect((await request('GET', '/feedback/2', { app: 'spacetime' })).status).toBe(404);
    const res = await request('GET', '/feedback/999');
    expect(res.status).toBe(404);
    expect(await res.json()).toEqual({ error: { code: 'not_found', message: 'Feedback not found' } });
  });

  it('rejects a malformed number', async () => {
    const res = await request('GET', '/feedback/abc');
    expect(res.status).toBe(400);
    expect(await res.json()).toMatchObject({ error: { message: 'Invalid number' } });
  });
});

describe('GET /v1/feedback/:number/comments', () => {
  it('lists top-level comments newest first, each with its replies oldest first', async () => {
    const first = await seed(2, 'First', { at: T0 + 1 });
    const second = await seed(2, 'Second', { at: T0 + 2, admin: true, author: null });
    await seed(2, 'Reply B', { parentId: first, at: T0 + 20 });
    await seed(2, 'Reply A', { parentId: first, at: T0 + 10, author: AUTHOR });

    const page = await list(2, '', { anonId: AUTHOR });
    expect(page.nextCursor).toBeNull();
    expect(page.items.map((c) => c.text)).toEqual(['Second', 'First']);
    expect(page.items[0]).toEqual({
      id: second,
      parentId: null,
      text: 'Second',
      lang: 'en',
      isAdmin: true,
      isMine: false,
      deleted: false,
      edited: false,
      createdAt: new Date(T0 + 2).toISOString(),
      updatedAt: new Date(T0 + 2).toISOString(),
      replyCount: 0,
      replies: [],
    });
    const thread = page.items[1]!;
    expect(thread.replyCount).toBe(2);
    expect(thread.replies.map((r) => [r.text, r.parentId, r.isMine])).toEqual([
      ['Reply A', first, true],
      ['Reply B', first, false],
    ]);
    expect(JSON.stringify(page)).not.toContain('author');
  });

  it('sorts oldest first and by most replies', async () => {
    const a = await seed(3, 'A', { at: T0 + 1 });
    const b = await seed(3, 'B', { at: T0 + 2 });
    const c = await seed(3, 'C', { at: T0 + 3 });
    await seed(3, 'to A', { parentId: a, at: T0 + 10 });
    await seed(3, 'to C', { parentId: c, at: T0 + 11 });
    await seed(3, 'to C again', { parentId: c, at: T0 + 12 });

    expect((await list(3, '?sort=oldest')).items.map((x) => x.id)).toEqual([a, b, c]);
    expect((await list(3, '?sort=replies')).items.map((x) => x.id)).toEqual([c, a, b]);
  });

  it('pages 20 top-level comments at a time, in every sort, without repeats', async () => {
    for (let i = 0; i < 25; i++) {
      const id = await seed(4, `Comment ${i}`, { at: T0 + i });
      for (let r = 0; r < i % 3; r++) await seed(4, `Reply ${i}.${r}`, { parentId: id, at: T0 + 100 + r });
    }
    for (const sort of ['newest', 'oldest', 'replies']) {
      const first = await list(4, `?sort=${sort}`);
      expect(first.items).toHaveLength(20);
      expect(first.nextCursor).not.toBeNull();
      const second = await list(4, `?sort=${sort}&cursor=${first.nextCursor}`);
      expect(second.items).toHaveLength(5);
      expect(second.nextCursor).toBeNull();
      const ids = [...first.items, ...second.items].map((x) => x.id);
      expect(new Set(ids).size).toBe(25);
      if (sort === 'replies') {
        const counts = [...first.items, ...second.items].map((x) => x.replyCount);
        expect(counts).toEqual([...counts].sort((x, y) => y - x));
      }
    }
  });

  it('rejects a cursor made for another sort', async () => {
    const first = await list(4, '?sort=newest');
    const res = await request('GET', `/feedback/4/comments?sort=replies&cursor=${first.nextCursor}`);
    expect(res.status).toBe(400);
    expect(await res.json()).toMatchObject({ error: { message: 'Invalid cursor' } });
  });

  it('filters by mine and admin, keeping threads where a reply matches', async () => {
    const mine = await seed(5, 'Mine', { author: AUTHOR, at: T0 + 1 });
    const admin = await seed(5, 'From the team', { admin: true, author: null, at: T0 + 2 });
    const replied = await seed(5, 'Question', { at: T0 + 3 });
    await seed(5, 'My answer', { parentId: replied, author: AUTHOR, at: T0 + 4 });
    await seed(5, 'Unrelated', { at: T0 + 5 });

    const ids = async (query: string, anonId: string | null = AUTHOR) =>
      (await list(5, query, { anonId })).items.map((x) => x.id);
    expect(await ids('?filter=mine')).toEqual([replied, mine]);
    expect(await ids('?filter=admin')).toEqual([admin]);
    expect(await ids('?filter=mine,admin')).toEqual([replied, admin, mine]);
    expect(await ids('?filter=mine', null)).toEqual([]);
  });

  it('searches comment text, keeping threads where a reply matches', async () => {
    const top = await seed(6, 'Barcode scanning is slow', { at: T0 + 1 });
    const parent = await seed(6, 'Any update?', { at: T0 + 2 });
    await seed(6, 'Scanning works now on my phone', { parentId: parent, at: T0 + 3 });
    await seed(6, 'Something else', { at: T0 + 4 });

    const page = await list(6, '?q=scann');
    expect(page.items.map((x) => x.id)).toEqual([parent, top]);
    expect(page.items[0]!.replies).toHaveLength(1);
    expect((await list(6, '?q=barcode%20slow')).items.map((x) => x.id)).toEqual([top]);
    expect((await list(6, `?q=${encodeURIComponent('"* - NEAR(')}`)).items).toEqual([]);
  });

  it('keeps each app apart', async () => {
    await env.DB.prepare(
      `INSERT INTO comments (feedback_id, parent_id, author_id, is_admin, text, lang, created_at, updated_at)
       VALUES (?1, NULL, ?2, 0, 'SpaceTime comment', 'en', ?3, ?3)`,
    )
      .bind(await feedbackRowId(1, 'spacetime'), OTHER, T0)
      .run();
    expect((await list(1)).items).toEqual([]);
    expect((await list(1, '', { app: 'spacetime' })).items.map((x) => x.text)).toEqual(['SpaceTime comment']);
  });

  it('rejects bad values and unknown feedback', async () => {
    for (const [query, message] of [
      ['?sort=hearts', 'Invalid sort'],
      ['?filter=friends', 'Invalid filter'],
      [`?q=${'a'.repeat(101)}`, 'Search must be at most 100 characters'],
    ]) {
      const res = await request('GET', `/feedback/1/comments${query}`);
      expect(res.status).toBe(400);
      expect(await res.json()).toMatchObject({ error: { message } });
    }
    expect((await request('GET', '/feedback/999/comments')).status).toBe(404);
  });
});

describe('POST /v1/feedback/:number/comments', () => {
  it('creates a comment and returns it with the new count', async () => {
    const anonId = crypto.randomUUID();
    const before = await feedbackRow(7);
    const { comment: c, feedback } = await created(7, { text: '  Me too  ' }, { anonId });

    expect(c).toMatchObject({
      parentId: null,
      text: 'Me too',
      lang: 'en',
      isAdmin: false,
      isMine: true,
      deleted: false,
      edited: false,
      replyCount: 0,
      replies: [],
    });
    expect(feedback).toMatchObject({ number: 7, commentCount: 1 });
    const row = await env.DB.prepare('SELECT author_id FROM comments WHERE id = ?').bind(c.id).first<{ author_id: string }>();
    expect(row?.author_id).toBe(anonId);
    // A comment is not an edit of the feedback.
    expect((await feedbackRow(7))?.updated_at).toBe(before?.updated_at);
    expect((await list(7, '?q=too')).items.map((x) => x.id)).toEqual([c.id]);
  });

  it('stores the writer language', async () => {
    const res = await comment(7, { text: 'Ich auch' }, {}, 'de');
    expect(((await res.json()) as { comment: Comment }).comment.lang).toBe('de');
  });

  it('adds a reply to a top-level comment and counts it', async () => {
    const parent = await created(8, { text: 'Question' });
    const { comment: reply, feedback } = await created(8, { text: 'Answer', parentId: parent.comment.id });

    expect(reply.parentId).toBe(parent.comment.id);
    expect(feedback.commentCount).toBe(2);
    expect((await list(8)).items[0]!.replies.map((r) => r.text)).toEqual(['Answer']);
  });

  it('keeps replies one level deep and on the same feedback', async () => {
    const parent = await created(9, { text: 'Top' });
    const reply = await created(9, { text: 'Reply', parentId: parent.comment.id });
    const elsewhere = await created(10, { text: 'On another feedback' });

    for (const parentId of [reply.comment.id, elsewhere.comment.id, 999999, 'x', 0, 1.5]) {
      const res = await comment(9, { text: 'Nested', parentId });
      expect(res.status).toBe(400);
      expect(await res.json()).toMatchObject({ error: { message: 'Invalid parentId', details: { field: 'parentId' } } });
    }
    expect((await feedbackRow(9))?.comment_count).toBe(2);
  });

  it('marks activity only when someone other than the author comments', async () => {
    await created(11, { text: 'By the author' }, { anonId: AUTHOR });
    expect((await feedbackRow(11))?.last_activity_at).toBe(T0);

    await created(11, { text: 'By someone else' });
    expect((await feedbackRow(11))?.last_activity_at).toBeGreaterThan(T0);
  });

  it('rejects bad requests', async () => {
    const cases: [Options, unknown, string, string][] = [
      [{ anonId: null }, { text: 'Hi' }, 'en', 'Missing X-Anon-Id header'],
      [{}, { text: 'Hi' }, 'english', 'Invalid lang'],
      [{}, { text: '   ' }, 'en', 'Text must be 1 to 2000 characters'],
      [{}, { text: 'x'.repeat(2001) }, 'en', 'Text must be 1 to 2000 characters'],
      [{}, { text: 5 }, 'en', 'Invalid text'],
      [{}, 'not json', 'en', 'Body must be JSON'],
    ];
    for (const [options, body, lang, message] of cases) {
      const res = await comment(12, body, options, lang);
      expect(res.status).toBe(400);
      expect(await res.json()).toMatchObject({ error: { code: 'bad_request', message } });
    }
    expect((await comment(999, { text: 'Hi' })).status).toBe(404);
    expect((await feedbackRow(12))?.comment_count).toBe(0);
  });

  it('counts emoji as one character each', async () => {
    const res = await comment(12, { text: '👍'.repeat(2000) });
    expect(res.status).toBe(201);
  });
});

describe('PATCH /v1/comments/:id', () => {
  it('edits your own comment and marks it edited', async () => {
    const anonId = crypto.randomUUID();
    const { comment: c } = await created(13, { text: 'Old words' }, { anonId });

    const res = await request('PATCH', `/comments/${c.id}`, { anonId }, { text: ' New words ' });
    expect(res.status).toBe(200);
    const edited = ((await res.json()) as { comment: Comment }).comment;
    expect(edited).toMatchObject({ id: c.id, text: 'New words', edited: true, isMine: true });
    expect(edited.createdAt).toBe(c.createdAt);
    expect((await list(13, '?q=old')).items).toEqual([]);
    expect((await list(13, '?q=new')).items.map((x) => x.id)).toEqual([c.id]);
  });

  it('does not mark a comment edited when the text is the same', async () => {
    const anonId = crypto.randomUUID();
    const { comment: c } = await created(13, { text: 'Same' }, { anonId });
    const res = await request('PATCH', `/comments/${c.id}`, { anonId }, { text: 'Same ' });
    expect(((await res.json()) as { comment: Comment }).comment.edited).toBe(false);
  });

  it('returns a top-level comment with its replies', async () => {
    const anonId = crypto.randomUUID();
    const { comment: c } = await created(14, { text: 'Top' }, { anonId });
    await created(14, { text: 'Reply', parentId: c.id });
    const res = await request('PATCH', `/comments/${c.id}`, { anonId }, { text: 'Top, edited' });
    expect(((await res.json()) as { comment: Comment }).comment.replies.map((r) => r.text)).toEqual(['Reply']);
  });

  it("refuses someone else's comment, another app's and unknown IDs", async () => {
    const { comment: c } = await created(15, { text: 'Not yours' });

    const forbidden = await request('PATCH', `/comments/${c.id}`, { anonId: OTHER }, { text: 'Changed' });
    expect(forbidden.status).toBe(403);
    expect(await forbidden.json()).toEqual({
      error: { code: 'forbidden', message: 'You can only change your own comments' },
    });
    const otherApp = await request('PATCH', `/comments/${c.id}`, { app: 'spacetime', anonId: OTHER }, { text: 'x' });
    expect(otherApp.status).toBe(404);
    expect((await request('PATCH', '/comments/999999', { anonId: OTHER }, { text: 'x' })).status).toBe(404);
    expect((await request('PATCH', '/comments/abc', { anonId: OTHER }, { text: 'x' })).status).toBe(400);
    expect((await request('PATCH', `/comments/${c.id}`, {}, { text: 'x' })).status).toBe(400);
  });
});

describe('DELETE /v1/comments/:id', () => {
  it('removes a comment without replies and returns the new count', async () => {
    const anonId = crypto.randomUUID();
    const { comment: c } = await created(16, { text: 'Gone soon' }, { anonId });
    await created(16, { text: 'Stays' });

    const res = await request('DELETE', `/comments/${c.id}`, { anonId });
    expect(res.status).toBe(200);
    expect(((await res.json()) as { feedback: Item }).feedback).toMatchObject({ number: 16, commentCount: 1 });
    expect((await list(16)).items.map((x) => x.text)).toEqual(['Stays']);
    expect((await list(16, '?q=gone')).items).toEqual([]);
  });

  it('keeps a comment with replies as a placeholder that does not count', async () => {
    const anonId = crypto.randomUUID();
    const { comment: c } = await created(17, { text: 'Started a thread' }, { anonId });
    await created(17, { text: 'Reply one', parentId: c.id });
    await created(17, { text: 'Reply two', parentId: c.id });

    const res = await request('DELETE', `/comments/${c.id}`, { anonId });
    expect(((await res.json()) as { feedback: Item }).feedback.commentCount).toBe(2);

    const [placeholder] = (await list(17, '', { anonId })).items;
    expect(placeholder).toMatchObject({ id: c.id, text: '', deleted: true, isMine: false, edited: false, replyCount: 2 });
    expect((await list(17, '?q=thread')).items).toEqual([]);
    expect((await list(17, '?filter=mine', { anonId })).items).toEqual([]);
    // A deleted comment can't be changed again.
    expect((await request('PATCH', `/comments/${c.id}`, { anonId }, { text: 'Back' })).status).toBe(404);
    expect((await request('DELETE', `/comments/${c.id}`, { anonId })).status).toBe(404);
  });

  it('removes a placeholder once its last reply is deleted', async () => {
    const author = crypto.randomUUID();
    const replier = crypto.randomUUID();
    const { comment: top } = await created(18, { text: 'Top' }, { anonId: author });
    const { comment: reply } = await created(18, { text: 'Reply', parentId: top.id }, { anonId: replier });
    await request('DELETE', `/comments/${top.id}`, { anonId: author });

    const res = await request('DELETE', `/comments/${reply.id}`, { anonId: replier });
    expect(((await res.json()) as { feedback: Item }).feedback.commentCount).toBe(0);
    expect((await list(18)).items).toEqual([]);
  });

  it('removes a reply and keeps its parent', async () => {
    const replier = crypto.randomUUID();
    const { comment: top } = await created(19, { text: 'Top' });
    const { comment: reply } = await created(19, { text: 'Reply', parentId: top.id }, { anonId: replier });

    await request('DELETE', `/comments/${reply.id}`, { anonId: replier });
    const [thread] = (await list(19)).items;
    expect(thread).toMatchObject({ id: top.id, text: 'Top', deleted: false, replyCount: 0 });
    expect((await feedbackRow(19))?.comment_count).toBe(1);
  });

  it("refuses someone else's comment", async () => {
    const { comment: c } = await created(20, { text: 'Not yours' });
    const res = await request('DELETE', `/comments/${c.id}`, { anonId: OTHER });
    expect(res.status).toBe(403);
    expect((await list(20)).items).toHaveLength(1);
  });
});

describe('comment rate limits', { timeout: RATE_LIMIT_TEST_TIMEOUT }, () => {
  it('allows 10 comment writes per minute per ID, apart from posts', async () => {
    await awaitFreshWindow();
    const anonId = crypto.randomUUID();
    for (let i = 0; i < 10; i++) {
      expect((await comment(21, { text: `Comment ${i}` }, { anonId })).status).toBe(201);
    }
    const limited = await comment(21, { text: 'One more' }, { anonId });
    expect(limited.status).toBe(429);
    expect(await limited.json()).toEqual({
      error: { code: 'rate_limited', message: 'Too many comments, try again soon' },
    });

    const post = await request('POST', '/feedback?lang=en', { anonId }, { type: 'idea', text: 'Still allowed' });
    expect(post.status).toBe(201);
  });

  it('allows 60 comment writes per minute per IP, across IDs', async () => {
    await awaitFreshWindow();
    const ip = '203.0.113.9';
    for (let i = 0; i < 60; i++) {
      expect((await comment(22, { text: `Comment ${i}` }, { ip })).status).toBe(201);
    }
    expect((await comment(22, { text: 'One more' }, { ip })).status).toBe(429);
  });
});

describe('comments_fts', () => {
  it('indexes comments that existed before the migration', async () => {
    // The migration's 'rebuild' ran on an empty table here; rebuilding again
    // must keep every row searchable.
    await env.DB.prepare("INSERT INTO comments_fts (comments_fts) VALUES ('rebuild')").run();
    expect((await list(6, '?q=barcode')).items).toHaveLength(1);
  });
});
