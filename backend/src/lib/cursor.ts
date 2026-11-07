import { ApiError } from './errors';

/** The orders the feedback list can be sorted in. */
export const SORTS = ['newest', 'oldest', 'reactions', 'comments'] as const;
export type Sort = (typeof SORTS)[number];

/**
 * Position after the last item of a page, for keyset pagination. [count] is
 * the sort column's value for the count sorts, null for the date sorts.
 */
export type Cursor = { sort: Sort; count: number | null; createdAt: number; id: number };

/** Encodes a cursor as an opaque base64url string. */
export function encodeCursor(cursor: Cursor): string {
  const values =
    cursor.count === null
      ? [cursor.sort, cursor.createdAt, cursor.id]
      : [cursor.sort, cursor.count, cursor.createdAt, cursor.id];
  return btoa(JSON.stringify(values)).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

/**
 * Decodes a cursor from the query string. Throws `bad_request` when it is
 * malformed or was made for another sort.
 */
export function decodeCursor(value: string | undefined, sort: Sort): Cursor | null {
  if (value === undefined || value === '') return null;
  try {
    const base64 = value.replace(/-/g, '+').replace(/_/g, '/');
    const parsed: unknown = JSON.parse(atob(base64));
    if (Array.isArray(parsed) && parsed[0] === sort && parsed.slice(1).every(Number.isSafeInteger)) {
      const numbers = parsed.slice(1) as number[];
      const hasCount = sort === 'reactions' || sort === 'comments';
      if (hasCount && numbers.length === 3) {
        return { sort, count: numbers[0]!, createdAt: numbers[1]!, id: numbers[2]! };
      }
      if (!hasCount && numbers.length === 2) {
        return { sort, count: null, createdAt: numbers[0]!, id: numbers[1]! };
      }
    }
  } catch {
    // Falls through to the error below.
  }
  throw new ApiError('bad_request', 'Invalid cursor', 400);
}
