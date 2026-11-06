import { Hono } from 'hono';
import { type AppEnv, requireAnonId } from '../lib/context';
import { decodeCursor, encodeCursor } from '../lib/cursor';
import { ApiError } from '../lib/errors';
import { FEEDBACK_SELECT, type FeedbackRow, toFeedbackJson } from '../lib/feedback';

export const PAGE_SIZE = 20;

/** Longest feedback text, in user-perceived characters, after trimming. */
export const MAX_TEXT_LENGTH = 2000;

/** Types the plain text form can post. Problems need the problem form. */
const TEXT_TYPES = new Set(['improvement', 'idea']);

const LANG_PATTERN = /^[a-z]{2,3}$/;

export const feedback = new Hono<AppEnv>();

// List, newest first. Sort, filters and search arrive with the list toolbar.
feedback.get('/', async (c) => {
  const cursor = decodeCursor(c.req.query('cursor'));

  const where = cursor ? 'f.app_id = ?2 AND (f.created_at, f.id) < (?3, ?4)' : 'f.app_id = ?2';
  const sql = `SELECT ${FEEDBACK_SELECT} FROM feedback f WHERE ${where}
    ORDER BY f.created_at DESC, f.id DESC LIMIT ?5`;

  const { results } = await c.env.DB.prepare(sql)
    .bind(c.get('anonId'), c.get('appId'), cursor?.createdAt ?? null, cursor?.id ?? null, PAGE_SIZE + 1)
    .all<FeedbackRow>();

  const page = results.slice(0, PAGE_SIZE);
  const last = page.at(-1);
  const nextCursor =
    results.length > PAGE_SIZE && last ? encodeCursor({ createdAt: last.created_at, id: last.id }) : null;

  return c.json({ items: page.map(toFeedbackJson), nextCursor });
});

// Create. The number is the app's next one; taking it, saving the post and
// its "created" timeline event run in one batch, which D1 runs as one
// transaction (https://developers.cloudflare.com/d1/worker-api/d1-database/#batch).
feedback.post('/', requireAnonId, async (c) => {
  const { type, text } = await readCreateBody(c.req.raw);
  const lang = c.req.query('lang');
  if (!lang || !LANG_PATTERN.test(lang)) {
    throw new ApiError('bad_request', 'Invalid lang', 400);
  }

  const db = c.env.DB;
  const appId = c.get('appId');
  const now = Date.now();
  // The number just taken, once the counter has moved on.
  const takenNumber = (appParam: string) => `(SELECT next_number - 1 FROM apps WHERE id = ${appParam})`;

  const results = await db.batch([
    db
      .prepare(
        `INSERT INTO feedback (app_id, number, type, text, lang, author_id,
           created_at, updated_at, last_activity_at)
         SELECT id, next_number, ?2, ?3, ?4, ?5, ?6, ?6, ?6 FROM apps WHERE id = ?1`,
      )
      .bind(appId, type, text, lang, c.get('anonId'), now),
    db.prepare('UPDATE apps SET next_number = next_number + 1 WHERE id = ?1').bind(appId),
    db
      .prepare(
        `INSERT INTO feedback_events (feedback_id, kind, at)
         SELECT id, 'created', ?2 FROM feedback WHERE app_id = ?1 AND number = ${takenNumber('?1')}`,
      )
      .bind(appId, now),
    db
      .prepare(`SELECT ${FEEDBACK_SELECT} FROM feedback f WHERE f.app_id = ?2 AND f.number = ${takenNumber('?2')}`)
      .bind(c.get('anonId'), appId),
  ]);

  const row = results[3]?.results[0] as FeedbackRow | undefined;
  if (!row) {
    console.error('feedback: created row not found', { appId });
    throw new ApiError('server_error', 'Something went wrong', 500);
  }
  return c.json(toFeedbackJson(row), 201);
});

async function readCreateBody(request: Request): Promise<{ type: string; text: string }> {
  let body: unknown;
  try {
    body = await request.json();
  } catch {
    throw new ApiError('bad_request', 'Body must be JSON', 400);
  }
  const { type, text } = (body ?? {}) as Record<string, unknown>;
  if (typeof type !== 'string' || !TEXT_TYPES.has(type)) {
    throw new ApiError('bad_request', 'Invalid type', 400);
  }
  if (typeof text !== 'string') {
    throw new ApiError('bad_request', 'Invalid text', 400);
  }
  const trimmed = text.trim();
  const length = graphemeCount(trimmed);
  if (length === 0 || length > MAX_TEXT_LENGTH) {
    throw new ApiError('bad_request', 'Text must be 1 to 2000 characters', 400, { field: 'text' });
  }
  return { type, text: trimmed };
}

// Counts what the user sees as characters (an emoji is one), the way
// Flutter's TextField maxLength does (LengthLimitingTextInputFormatter counts
// `text.characters`, flutter/lib/src/services/text_formatter.dart), so both
// sides agree on the limit.
const segmenter = new Intl.Segmenter(undefined, { granularity: 'grapheme' });

function graphemeCount(text: string): number {
  return Array.from(segmenter.segment(text)).length;
}
