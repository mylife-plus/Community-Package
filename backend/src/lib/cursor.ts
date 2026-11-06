import { ApiError } from './errors';

/** Position after the last item of a page, for keyset pagination. */
export type Cursor = { createdAt: number; id: number };

/** Encodes a cursor as an opaque base64url string. */
export function encodeCursor(cursor: Cursor): string {
  const json = JSON.stringify([cursor.createdAt, cursor.id]);
  return btoa(json).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

/** Decodes a cursor from the query string. Throws `bad_request` when it is malformed. */
export function decodeCursor(value: string | undefined): Cursor | null {
  if (value === undefined || value === '') return null;
  try {
    const base64 = value.replace(/-/g, '+').replace(/_/g, '/');
    const parsed: unknown = JSON.parse(atob(base64));
    if (
      Array.isArray(parsed) &&
      parsed.length === 2 &&
      Number.isSafeInteger(parsed[0]) &&
      Number.isSafeInteger(parsed[1])
    ) {
      return { createdAt: parsed[0] as number, id: parsed[1] as number };
    }
  } catch {
    // Falls through to the error below.
  }
  throw new ApiError('bad_request', 'Invalid cursor', 400);
}
