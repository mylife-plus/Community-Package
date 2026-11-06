import type { Context } from 'hono';
import type { ContentfulStatusCode } from 'hono/utils/http-status';

export type ErrorCode = 'not_found' | 'server_error';

/** An error the API returns to the client as `{ error: { code, message, details } }`. */
export class ApiError extends Error {
  constructor(
    readonly code: ErrorCode,
    message: string,
    readonly status: ContentfulStatusCode,
    readonly details?: Record<string, unknown>,
  ) {
    super(message);
  }
}

export function errorResponse(c: Context, err: ApiError): Response {
  return c.json(
    {
      error: {
        code: err.code,
        message: err.message,
        ...(err.details ? { details: err.details } : {}),
      },
    },
    err.status,
  );
}
