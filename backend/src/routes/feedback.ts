import { Hono } from 'hono';
import { type AppEnv } from '../lib/context';
import { decodeCursor, encodeCursor } from '../lib/cursor';
import { FEEDBACK_SELECT, type FeedbackRow, toFeedbackJson } from '../lib/feedback';

export const PAGE_SIZE = 20;

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
