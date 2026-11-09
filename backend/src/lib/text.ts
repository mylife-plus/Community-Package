import { ApiError } from './errors';

/**
 * Longest feedback text, Problem description and comment, in
 * user-perceived characters, after trimming.
 */
export const MAX_TEXT_LENGTH = 2000;

const LANG_PATTERN = /^[a-z]{2,3}$/;

/** The writer's app language from `?lang=`. Throws `bad_request` when missing or malformed. */
export function readLang(value: string | undefined): string {
  if (!value || !LANG_PATTERN.test(value)) {
    throw new ApiError('bad_request', 'Invalid lang', 400);
  }
  return value;
}

/** A JSON request body. Throws `bad_request` when it is not JSON. */
export async function readJsonBody(request: Request): Promise<Record<string, unknown>> {
  let body: unknown;
  try {
    body = await request.json();
  } catch {
    throw new ApiError('bad_request', 'Body must be JSON', 400);
  }
  return (body ?? {}) as Record<string, unknown>;
}

/**
 * A required text field, trimmed, 1 to [MAX_TEXT_LENGTH] characters.
 * Throws `bad_request` with `details.field` otherwise.
 */
export function readText(value: unknown): string {
  if (typeof value !== 'string') {
    throw new ApiError('bad_request', 'Invalid text', 400);
  }
  const trimmed = value.trim();
  const length = graphemeCount(trimmed);
  if (length === 0 || length > MAX_TEXT_LENGTH) {
    throw new ApiError('bad_request', `Text must be 1 to ${MAX_TEXT_LENGTH} characters`, 400, { field: 'text' });
  }
  return trimmed;
}

// Counts what the user sees as characters (an emoji is one), the way
// Flutter's TextField maxLength does (LengthLimitingTextInputFormatter counts
// `text.characters`, flutter/lib/src/services/text_formatter.dart), so both
// sides agree on the limit.
const segmenter = new Intl.Segmenter(undefined, { granularity: 'grapheme' });

export function graphemeCount(text: string): number {
  return Array.from(segmenter.segment(text)).length;
}

/** A positive ID or number from the path. Throws `bad_request` with [message] otherwise. */
export function readPathId(value: string | undefined, message: string): number {
  if (!value || !/^[1-9]\d{0,8}$/.test(value)) {
    throw new ApiError('bad_request', message, 400);
  }
  return Number(value);
}
