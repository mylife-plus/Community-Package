import { type Cursor, type Sort, SORTS, decodeCursor } from './cursor';
import { ApiError } from './errors';

/** Longest search text, in characters. */
export const MAX_SEARCH_LENGTH = 100;

const TYPES = new Set(['improvement', 'problem', 'idea']);
const STATUSES = new Set(['planned', 'in_progress', 'done']);

/** What the caller asked the feedback list for. */
export type ListQuery = {
  sort: Sort;
  /** Empty means every type. */
  types: string[];
  /** Empty means any status, including none. */
  statuses: string[];
  /** FTS5 expression for the search words, or null without words. */
  match: string | null;
  /** A search that is only a number, with or without #, also finds that number. */
  number: number | null;
  cursor: Cursor | null;
};

/** Reads `sort`, `type`, `status`, `q` and `cursor`. Throws `bad_request` on bad values. */
export function readListQuery(query: (name: string) => string | undefined): ListQuery {
  const sortParam = query('sort') || 'newest';
  if (!(SORTS as readonly string[]).includes(sortParam)) {
    throw new ApiError('bad_request', 'Invalid sort', 400);
  }
  const sort = sortParam as Sort;
  const search = readSearch(query('q'));
  return {
    sort,
    types: readList(query('type'), TYPES, 'type'),
    statuses: readList(query('status'), STATUSES, 'status'),
    ...search,
    cursor: decodeCursor(query('cursor'), sort),
  };
}

/** A comma-separated list of known values. Blank means none. */
function readList(value: string | undefined, allowed: Set<string>, name: string): string[] {
  if (!value) return [];
  const parts = value
    .split(',')
    .map((part) => part.trim())
    .filter((part) => part !== '');
  if (!parts.every((part) => allowed.has(part))) {
    throw new ApiError('bad_request', `Invalid ${name}`, 400);
  }
  return [...new Set(parts)];
}

// Letters, digits and combining marks: what FTS5's default unicode61
// tokenizer keeps as token characters (everything else separates words,
// https://www.sqlite.org/fts5.html#unicode61_tokenizer). Taking only these
// means quotes, *, - or AND in the search text can never become FTS5
// syntax.
const WORD = /[\p{L}\p{N}\p{M}\p{Co}]+/gu;

const NUMBER = /^#?\s*(\d{1,9})$/;

function readSearch(value: string | undefined): { match: string | null; number: number | null } {
  const text = (value ?? '').normalize('NFC').trim();
  if ([...text].length > MAX_SEARCH_LENGTH) {
    throw new ApiError('bad_request', `Search must be at most ${MAX_SEARCH_LENGTH} characters`, 400);
  }
  const words = text.match(WORD) ?? [];
  // Every word must appear, each matching the start of a word in the text
  // (FTS5 prefix query: https://www.sqlite.org/fts5.html#fts5_prefix_queries).
  // Case and accents are ignored by the tokenizer.
  const match = words.length === 0 ? null : words.map((word) => `"${word}"*`).join(' ');
  const number = NUMBER.exec(text)?.[1];
  return { match, number: number === undefined ? null : Number(number) };
}

/** ORDER BY for each sort. Ties go newest first, then by ID. */
const ORDER: Record<Sort, string> = {
  newest: 'f.created_at DESC, f.id DESC',
  oldest: 'f.created_at ASC, f.id ASC',
  reactions: 'f.reaction_count DESC, f.created_at DESC, f.id DESC',
  comments: 'f.comment_count DESC, f.created_at DESC, f.id DESC',
};

const COUNT_COLUMN: Partial<Record<Sort, string>> = {
  reactions: 'f.reaction_count',
  comments: 'f.comment_count',
};

/**
 * The list query's SQL. `?1` is the caller's anonymous ID, as
 * [FEEDBACK_SELECT] expects; [params] holds every value in order.
 */
export function listSql(
  select: string,
  appId: string,
  anonId: string | null,
  query: ListQuery,
  limit: number,
): { sql: string; params: unknown[] } {
  const params: unknown[] = [anonId];
  const param = (value: unknown) => {
    params.push(value);
    return `?${params.length}`;
  };

  const where = [`f.app_id = ${param(appId)}`];
  if (query.types.length > 0) {
    where.push(`f.type IN (${query.types.map(param).join(', ')})`);
  }
  if (query.statuses.length > 0) {
    where.push(`f.status IN (${query.statuses.map(param).join(', ')})`);
  }
  const textMatch =
    query.match === null
      ? null
      : `f.id IN (SELECT rowid FROM feedback_fts WHERE feedback_fts MATCH ${param(query.match)})`;
  const numberMatch = query.number === null ? null : `f.number = ${param(query.number)}`;
  const search = [numberMatch, textMatch].filter((part) => part !== null);
  if (search.length > 0) where.push(`(${search.join(' OR ')})`);

  const cursor = query.cursor;
  if (cursor) {
    const after = query.sort === 'oldest' ? '>' : '<';
    const count = COUNT_COLUMN[query.sort];
    where.push(
      count
        ? `(${count}, f.created_at, f.id) < (${param(cursor.count)}, ${param(cursor.createdAt)}, ${param(cursor.id)})`
        : `(f.created_at, f.id) ${after} (${param(cursor.createdAt)}, ${param(cursor.id)})`,
    );
  }

  const sql = `SELECT ${select} FROM feedback f WHERE ${where.join(' AND ')}
    ORDER BY ${ORDER[query.sort]} LIMIT ${param(limit)}`;
  return { sql, params };
}

/** The cursor that continues after [row] in [sort]. */
export function cursorAfter(
  sort: Sort,
  row: { reaction_count: number; comment_count: number; created_at: number; id: number },
): Cursor {
  const count = sort === 'reactions' ? row.reaction_count : sort === 'comments' ? row.comment_count : null;
  return { sort, count, createdAt: row.created_at, id: row.id };
}
