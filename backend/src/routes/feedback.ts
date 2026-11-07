import { type Context, Hono } from 'hono';
import { type AppEnv, requireAnonId } from '../lib/context';
import { encodeCursor } from '../lib/cursor';
import { ApiError } from '../lib/errors';
import { FEEDBACK_SELECT, type FeedbackRow, toFeedbackJson } from '../lib/feedback';
import { cursorAfter, listSql, readListQuery } from '../lib/listQuery';
import { reactionRateLimit, writeRateLimit } from '../lib/rateLimit';

export const PAGE_SIZE = 20;

/**
 * Longest feedback text and Problem description, in user-perceived
 * characters, after trimming.
 */
export const MAX_TEXT_LENGTH = 2000;

/** Problems: how many steps to reproduce, and the longest step. */
export const MAX_STEPS = 10;
export const MAX_STEP_LENGTH = 500;

/** Problems: the longest screen path and device detail. */
export const MAX_SCREEN_PATH_LENGTH = 300;
export const MAX_DEVICE_FIELD_LENGTH = 100;

/** Types posted with a single text field. Problems have their own fields. */
const TEXT_TYPES = new Set(['improvement', 'idea']);

type NewFeedback = {
  type: string;
  text: string;
  screenPath: string | null;
  steps: string[] | null;
  description: string | null;
  osVersion: string | null;
  appVersion: string | null;
  deviceModel: string | null;
};

const LANG_PATTERN = /^[a-z]{2,3}$/;

export const feedback = new Hono<AppEnv>();

// List, sorted, filtered and searched as asked (lib/listQuery.ts).
feedback.get('/', async (c) => {
  const query = readListQuery((name) => c.req.query(name));
  const { sql, params } = listSql(FEEDBACK_SELECT, c.get('appId'), c.get('anonId'), query, PAGE_SIZE + 1);

  const { results } = await c.env.DB.prepare(sql)
    .bind(...params)
    .all<FeedbackRow>();

  const page = results.slice(0, PAGE_SIZE);
  const last = page.at(-1);
  const nextCursor = results.length > PAGE_SIZE && last ? encodeCursor(cursorAfter(query.sort, last)) : null;

  return c.json({ items: page.map(toFeedbackJson), nextCursor });
});

// Heart on and off. Both are safe to repeat. The count is recounted from
// the reactions table, so it can never drift from the rows.
feedback.put('/:number/reaction', requireAnonId, reactionRateLimit, (c) => setReaction(c, true));
feedback.delete('/:number/reaction', requireAnonId, reactionRateLimit, (c) => setReaction(c, false));

async function setReaction(c: Context<AppEnv>, on: boolean) {
  const number = readNumber(c.req.param('number') ?? '');
  const db = c.env.DB;
  const appId = c.get('appId');
  const anonId = c.get('anonId');

  const change = on
    ? db
        .prepare(
          `INSERT OR IGNORE INTO reactions (feedback_id, anon_id, created_at)
           SELECT id, ?3, ?4 FROM feedback WHERE app_id = ?1 AND number = ?2`,
        )
        .bind(appId, number, anonId, Date.now())
    : db
        .prepare(
          `DELETE FROM reactions WHERE anon_id = ?3
             AND feedback_id = (SELECT id FROM feedback WHERE app_id = ?1 AND number = ?2)`,
        )
        .bind(appId, number, anonId);

  // One batch, so one transaction (see the create route below).
  const results = await db.batch([
    change,
    db
      .prepare(
        `UPDATE feedback
         SET reaction_count = (SELECT COUNT(*) FROM reactions r WHERE r.feedback_id = feedback.id)
         WHERE app_id = ?1 AND number = ?2`,
      )
      .bind(appId, number),
    db.prepare(`SELECT ${FEEDBACK_SELECT} FROM feedback f WHERE f.app_id = ?2 AND f.number = ?3`).bind(anonId, appId, number),
  ]);

  const row = results[2]?.results[0] as FeedbackRow | undefined;
  if (!row) throw new ApiError('not_found', 'Feedback not found', 404);
  return c.json(toFeedbackJson(row));
}

/** A feedback number from the path. */
function readNumber(value: string): number {
  if (!/^[1-9]\d{0,8}$/.test(value)) {
    throw new ApiError('bad_request', 'Invalid number', 400);
  }
  return Number(value);
}

// Create. The number is the app's next one; taking it, saving the post and
// its "created" timeline event run in one batch, which D1 runs as one
// transaction (https://developers.cloudflare.com/d1/worker-api/d1-database/#batch).
feedback.post('/', requireAnonId, writeRateLimit, async (c) => {
  const post = await readCreateBody(c.req.raw);
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
           created_at, updated_at, last_activity_at,
           screen_path, steps_json, description, os_version, app_version, device_model)
         SELECT id, next_number, ?2, ?3, ?4, ?5, ?6, ?6, ?6, ?7, ?8, ?9, ?10, ?11, ?12
         FROM apps WHERE id = ?1`,
      )
      .bind(
        appId,
        post.type,
        post.text,
        lang,
        c.get('anonId'),
        now,
        post.screenPath,
        post.steps === null ? null : JSON.stringify(post.steps),
        post.description,
        post.osVersion,
        post.appVersion,
        post.deviceModel,
      ),
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

async function readCreateBody(request: Request): Promise<NewFeedback> {
  let body: unknown;
  try {
    body = await request.json();
  } catch {
    throw new ApiError('bad_request', 'Body must be JSON', 400);
  }
  const fields = (body ?? {}) as Record<string, unknown>;
  const { type, text } = fields;
  if (type === 'problem') return readProblem(fields);
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
  return {
    type,
    text: trimmed,
    screenPath: null,
    steps: null,
    description: null,
    osVersion: null,
    appVersion: null,
    deviceModel: null,
  };
}

// A Problem has no text field of its own: the steps, an optional
// description, the screen it happens on and the device details.
function readProblem(fields: Record<string, unknown>): NewFeedback {
  const steps = readSteps(fields.steps);
  const description = readOptional(fields.description, 'description', MAX_TEXT_LENGTH);
  return {
    type: 'problem',
    text: problemText(description, steps),
    screenPath: readOptional(fields.screenPath, 'screenPath', MAX_SCREEN_PATH_LENGTH),
    steps,
    description,
    osVersion: readOptional(fields.osVersion, 'osVersion', MAX_DEVICE_FIELD_LENGTH),
    appVersion: readOptional(fields.appVersion, 'appVersion', MAX_DEVICE_FIELD_LENGTH),
    deviceModel: readOptional(fields.deviceModel, 'deviceModel', MAX_DEVICE_FIELD_LENGTH),
  };
}

function readSteps(value: unknown): string[] {
  if (!Array.isArray(value) || !value.every((step) => typeof step === 'string')) {
    throw new ApiError('bad_request', 'Invalid steps', 400, { field: 'steps' });
  }
  if (value.length === 0 || value.length > MAX_STEPS) {
    throw new ApiError('bad_request', `Problems need 1 to ${MAX_STEPS} steps`, 400, { field: 'steps' });
  }
  return value.map((step: string, index) => {
    const trimmed = step.trim();
    const length = graphemeCount(trimmed);
    if (length === 0 || length > MAX_STEP_LENGTH) {
      throw new ApiError('bad_request', `Each step must be 1 to ${MAX_STEP_LENGTH} characters`, 400, {
        field: 'steps',
        index,
      });
    }
    return trimmed;
  });
}

/** A trimmed optional string field. Missing, null or blank is null. */
function readOptional(value: unknown, field: string, maxLength: number): string | null {
  if (value === undefined || value === null) return null;
  if (typeof value !== 'string') {
    throw new ApiError('bad_request', `Invalid ${field}`, 400, { field });
  }
  const trimmed = value.trim();
  if (trimmed === '') return null;
  if (graphemeCount(trimmed) > maxLength) {
    throw new ApiError('bad_request', `${field} must be at most ${maxLength} characters`, 400, { field });
  }
  return trimmed;
}

/**
 * The text of a Problem, kept for search, similar search and translation:
 * the description (if any), a blank line, then the numbered steps.
 */
export function problemText(description: string | null, steps: string[]): string {
  const numbered = steps.map((step, i) => `${i + 1}. ${step}`).join('\n');
  return description === null ? numbered : `${description}\n\n${numbered}`;
}

// Counts what the user sees as characters (an emoji is one), the way
// Flutter's TextField maxLength does (LengthLimitingTextInputFormatter counts
// `text.characters`, flutter/lib/src/services/text_formatter.dart), so both
// sides agree on the limit.
const segmenter = new Intl.Segmenter(undefined, { granularity: 'grapheme' });

function graphemeCount(text: string): number {
  return Array.from(segmenter.segment(text)).length;
}
