import { type Context, Hono } from 'hono';
import { type AppEnv, requireAnonId } from '../lib/context';
import { type Cursor, decodeCursor, encodeCursor } from '../lib/cursor';
import { ApiError } from '../lib/errors';
import { FEEDBACK_SELECT, type FeedbackRow, toFeedbackJson } from '../lib/feedback';
import { readSearchMatch } from '../lib/listQuery';
import { commentRateLimit } from '../lib/rateLimit';
import { readJsonBody, readLang, readPathId, readText } from '../lib/text';

/** Top-level comments per page. Each comes with all its replies. */
export const COMMENT_PAGE_SIZE = 20;

/** The orders top-level comments can be sorted in. Replies are always oldest first. */
export const COMMENT_SORTS = ['newest', 'oldest', 'replies'] as const;
type CommentSort = (typeof COMMENT_SORTS)[number];

const FILTERS = new Set(['mine', 'admin']);

/**
 * Columns read for a comment, as seen by the caller. `?1` must be bound to
 * the caller's anonymous ID, or null. `author_id` is never selected.
 */
function commentColumns(alias: string): string {
  return `${alias}.id, ${alias}.parent_id, ${alias}.is_admin, ${alias}.text, ${alias}.lang,
    ${alias}.created_at, ${alias}.updated_at, ${alias}.deleted_at,
    CASE WHEN ?1 IS NOT NULL AND ${alias}.author_id = ?1 THEN 1 ELSE 0 END AS is_mine`;
}

type CommentRow = {
  id: number;
  parent_id: number | null;
  is_admin: number;
  text: string;
  lang: string;
  created_at: number;
  updated_at: number;
  deleted_at: number | null;
  is_mine: number;
};

type ThreadRow = CommentRow & { reply_count: number };

/** The JSON shape of a comment. Top-level comments carry their replies, oldest first. */
function toCommentJson(row: CommentRow, replies: CommentRow[]): Record<string, unknown> {
  const deleted = row.deleted_at !== null;
  return {
    id: row.id,
    parentId: row.parent_id,
    text: deleted ? '' : row.text,
    lang: row.lang,
    isAdmin: row.is_admin === 1,
    isMine: !deleted && row.is_mine === 1,
    deleted,
    edited: !deleted && row.updated_at > row.created_at,
    createdAt: new Date(row.created_at).toISOString(),
    updatedAt: new Date(row.updated_at).toISOString(),
    replyCount: replies.length,
    replies: replies.map((reply) => toCommentJson(reply, [])),
  };
}

/** Recounts a feedback's comments from the rows. Placeholders of deleted comments don't count. */
const RECOUNT = `UPDATE feedback
  SET comment_count = (SELECT COUNT(*) FROM comments c WHERE c.feedback_id = feedback.id AND c.deleted_at IS NULL)`;

async function feedbackId(c: Context<AppEnv>, number: number): Promise<number> {
  const row = await c.env.DB.prepare('SELECT id FROM feedback WHERE app_id = ?1 AND number = ?2')
    .bind(c.get('appId'), number)
    .first<{ id: number }>();
  if (!row) throw new ApiError('not_found', 'Feedback not found', 404);
  return row.id;
}

/**
 * `GET /feedback/:number/comments?sort=&filter=&q=&cursor=`. A top-level
 * comment is listed when it or one of its replies matches the filter and
 * the search; it always comes with all its replies.
 */
export async function listComments(c: Context<AppEnv>, number: number) {
  const id = await feedbackId(c, number);
  const sortParam = c.req.query('sort') || 'newest';
  if (!(COMMENT_SORTS as readonly string[]).includes(sortParam)) {
    throw new ApiError('bad_request', 'Invalid sort', 400);
  }
  const sort = sortParam as CommentSort;
  const filters = readFilters(c.req.query('filter'));
  const match = readSearchMatch(c.req.query('q'));
  const cursor = decodeCursor(c.req.query('cursor'), sort, sort === 'replies');

  const params: unknown[] = [c.get('anonId')];
  const param = (value: unknown) => {
    params.push(value);
    return `?${params.length}`;
  };

  const where = [`t.feedback_id = ${param(id)}`, 't.parent_id IS NULL'];
  if (filters.length > 0 || match !== null) {
    const matchParam = match === null ? null : param(match);
    const matches = (alias: string) => {
      const parts = [`${alias}.deleted_at IS NULL`];
      if (filters.length > 0) {
        const any = filters.map((filter) =>
          filter === 'mine' ? `(?1 IS NOT NULL AND ${alias}.author_id = ?1)` : `${alias}.is_admin = 1`,
        );
        parts.push(`(${any.join(' OR ')})`);
      }
      if (matchParam !== null) {
        parts.push(`${alias}.id IN (SELECT rowid FROM comments_fts WHERE comments_fts MATCH ${matchParam})`);
      }
      return parts.join(' AND ');
    };
    where.push(`(${matches('t')} OR EXISTS (SELECT 1 FROM comments r WHERE r.parent_id = t.id AND ${matches('r')}))`);
  }

  const after: string[] = [];
  if (cursor) {
    after.push(
      sort === 'replies'
        ? `(reply_count, created_at, id) < (${param(cursor.count)}, ${param(cursor.createdAt)}, ${param(cursor.id)})`
        : `(created_at, id) ${sort === 'oldest' ? '>' : '<'} (${param(cursor.createdAt)}, ${param(cursor.id)})`,
    );
  }

  const order: Record<CommentSort, string> = {
    newest: 'created_at DESC, id DESC',
    oldest: 'created_at ASC, id ASC',
    replies: 'reply_count DESC, created_at DESC, id DESC',
  };

  const db = c.env.DB;
  const { results } = await db
    .prepare(
      `SELECT * FROM (
         SELECT ${commentColumns('t')},
           (SELECT COUNT(*) FROM comments r WHERE r.parent_id = t.id) AS reply_count
         FROM comments t WHERE ${where.join(' AND ')}
       )
       ${after.length > 0 ? `WHERE ${after.join(' AND ')}` : ''}
       ORDER BY ${order[sort]} LIMIT ${param(COMMENT_PAGE_SIZE + 1)}`,
    )
    .bind(...params)
    .all<ThreadRow>();

  const page = results.slice(0, COMMENT_PAGE_SIZE);
  const replies = await repliesOf(db, c.get('anonId'), page.map((row) => row.id));
  const last = page.at(-1);
  const nextCursor =
    results.length > COMMENT_PAGE_SIZE && last ? encodeCursor(threadCursor(sort, last)) : null;

  return c.json({
    items: page.map((row) => toCommentJson(row, replies.get(row.id) ?? [])),
    nextCursor,
  });
}

function threadCursor(sort: CommentSort, row: ThreadRow): Cursor<CommentSort> {
  return { sort, count: sort === 'replies' ? row.reply_count : null, createdAt: row.created_at, id: row.id };
}

/** A comma-separated list of filters. Blank means none. */
function readFilters(value: string | undefined): string[] {
  if (!value) return [];
  const parts = value
    .split(',')
    .map((part) => part.trim())
    .filter((part) => part !== '');
  if (!parts.every((part) => FILTERS.has(part))) {
    throw new ApiError('bad_request', 'Invalid filter', 400);
  }
  return [...new Set(parts)];
}

/** Replies of the given top-level comments, oldest first, by parent ID. */
async function repliesOf(db: D1Database, anonId: string | null, parentIds: number[]) {
  const byParent = new Map<number, CommentRow[]>();
  if (parentIds.length === 0) return byParent;
  const placeholders = parentIds.map((_, i) => `?${i + 2}`).join(', ');
  const { results } = await db
    .prepare(
      `SELECT ${commentColumns('c')} FROM comments c
       WHERE c.parent_id IN (${placeholders}) ORDER BY c.created_at ASC, c.id ASC`,
    )
    .bind(anonId, ...parentIds)
    .all<CommentRow>();
  for (const row of results) {
    const parentId = row.parent_id as number;
    byParent.set(parentId, [...(byParent.get(parentId) ?? []), row]);
  }
  return byParent;
}

/**
 * `POST /feedback/:number/comments` with `{ text, parentId? }`. A reply's
 * parent must be a top-level comment of the same feedback, so replies stay
 * one level deep. Returns the comment and the feedback with its new count.
 */
export async function createComment(c: Context<AppEnv>, number: number) {
  const fields = await readJsonBody(c.req.raw);
  const text = readText(fields.text);
  const parentId = readParentId(fields.parentId);
  const lang = readLang(c.req.query('lang'));
  const id = await feedbackId(c, number);
  const anonId = c.get('anonId');
  const now = Date.now();
  const db = c.env.DB;

  // One batch, so one transaction
  // (https://developers.cloudflare.com/d1/worker-api/d1-database/#batch).
  // The parent check sits in the INSERT itself, so a parent deleted
  // meanwhile can't get a reply.
  const results = await db.batch([
    db
      .prepare(
        `INSERT INTO comments (feedback_id, parent_id, author_id, is_admin, text, lang, created_at, updated_at)
         SELECT ?1, ?2, ?3, 0, ?4, ?5, ?6, ?6
         WHERE ?2 IS NULL OR EXISTS (
           SELECT 1 FROM comments p WHERE p.id = ?2 AND p.feedback_id = ?1 AND p.parent_id IS NULL)
         RETURNING id, parent_id, is_admin, text, lang, created_at, updated_at, deleted_at, 1 AS is_mine`,
      )
      .bind(id, parentId, anonId, text, lang, now),
    // A comment by someone other than the author is news for the author
    // (unread dots, plan 4.1).
    db
      .prepare(
        `${RECOUNT},
           last_activity_at = CASE WHEN author_id IS NULL OR author_id != ?2 THEN ?3 ELSE last_activity_at END
         WHERE id = ?1`,
      )
      .bind(id, anonId, now),
    db.prepare(`SELECT ${FEEDBACK_SELECT} FROM feedback f WHERE f.id = ?2`).bind(anonId, id),
  ]);

  const row = results[0]?.results[0] as CommentRow | undefined;
  if (!row) throw new ApiError('bad_request', 'Invalid parentId', 400, { field: 'parentId' });
  const item = results[2]?.results[0] as FeedbackRow | undefined;
  if (!item) throw new ApiError('not_found', 'Feedback not found', 404);
  return c.json({ comment: toCommentJson(row, []), feedback: toFeedbackJson(item) }, 201);
}

function readParentId(value: unknown): number | null {
  if (value === undefined || value === null) return null;
  if (typeof value !== 'number' || !Number.isSafeInteger(value) || value < 1) {
    throw new ApiError('bad_request', 'Invalid parentId', 400, { field: 'parentId' });
  }
  return value;
}

/** `/comments/:id`: edit and delete your own comment. */
export const comments = new Hono<AppEnv>();

type OwnComment = { id: number; feedback_id: number; parent_id: number | null; text: string };

/** The caller's own, not deleted comment in this app. 404 when missing, 403 when someone else's. */
async function ownComment(c: Context<AppEnv>): Promise<OwnComment> {
  const id = readPathId(c.req.param('id'), 'Invalid id');
  const row = await c.env.DB.prepare(
    `SELECT c.id, c.feedback_id, c.parent_id, c.text, c.author_id FROM comments c
     JOIN feedback f ON f.id = c.feedback_id
     WHERE c.id = ?1 AND f.app_id = ?2 AND c.deleted_at IS NULL`,
  )
    .bind(id, c.get('appId'))
    .first<OwnComment & { author_id: string | null }>();
  if (!row) throw new ApiError('not_found', 'Comment not found', 404);
  if (row.author_id === null || row.author_id !== c.get('anonId')) {
    throw new ApiError('forbidden', 'You can only change your own comments', 403);
  }
  return row;
}

// Edit. Saving the same text changes nothing, so it isn't marked edited.
comments.patch('/:id', requireAnonId, commentRateLimit, async (c) => {
  const text = readText((await readJsonBody(c.req.raw)).text);
  const own = await ownComment(c);
  const db = c.env.DB;
  const anonId = c.get('anonId');

  if (text !== own.text) {
    await db
      .prepare('UPDATE comments SET text = ?2, updated_at = ?3 WHERE id = ?1 AND author_id = ?4 AND deleted_at IS NULL')
      .bind(own.id, text, Date.now(), anonId)
      .run();
  }
  const row = await db.prepare(`SELECT ${commentColumns('c')} FROM comments c WHERE c.id = ?2`)
    .bind(anonId, own.id)
    .first<CommentRow>();
  if (!row) throw new ApiError('not_found', 'Comment not found', 404);
  const replies = own.parent_id === null ? ((await repliesOf(db, anonId, [own.id])).get(own.id) ?? []) : [];
  return c.json({ comment: toCommentJson(row, replies) });
});

// Delete. A top-level comment with replies stays as an empty placeholder
// ("Comment deleted"), so the replies keep their place; anything else is
// removed. A placeholder goes too once its last reply is deleted. Returns
// the feedback with its new count.
comments.delete('/:id', requireAnonId, commentRateLimit, async (c) => {
  const own = await ownComment(c);
  const db = c.env.DB;
  const anonId = c.get('anonId');
  const now = Date.now();

  const results = await db.batch([
    db
      .prepare(
        `UPDATE comments SET text = '', deleted_at = ?3, author_id = NULL
         WHERE id = ?1 AND author_id = ?2 AND EXISTS (SELECT 1 FROM comments r WHERE r.parent_id = ?1)`,
      )
      .bind(own.id, anonId, now),
    // Still owned only when the statement above did not keep it.
    db.prepare('DELETE FROM comments WHERE id = ?1 AND author_id = ?2 AND deleted_at IS NULL').bind(own.id, anonId),
    db
      .prepare(
        `DELETE FROM comments WHERE id = ?1 AND deleted_at IS NOT NULL
           AND NOT EXISTS (SELECT 1 FROM comments r WHERE r.parent_id = ?1)`,
      )
      .bind(own.parent_id),
    db.prepare(`${RECOUNT} WHERE id = ?1`).bind(own.feedback_id),
    db.prepare(`SELECT ${FEEDBACK_SELECT} FROM feedback f WHERE f.id = ?2`).bind(anonId, own.feedback_id),
  ]);

  const item = results[4]?.results[0] as FeedbackRow | undefined;
  if (!item) throw new ApiError('not_found', 'Feedback not found', 404);
  return c.json({ feedback: toFeedbackJson(item) });
});
