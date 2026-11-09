import { createMiddleware } from 'hono/factory';
import { type AppEnv } from './context';
import { ApiError } from './errors';

type LimitBinding = {
  [K in keyof Env]: Env[K] extends RateLimit ? K : never;
}[keyof Env];

/**
 * Limits requests per anonymous ID and, more loosely, per IP. Limits are
 * set in wrangler.jsonc. Run after `appContext` and `requireAnonId`.
 */
function rateLimit(anonLimit: LimitBinding, ipLimit: LimitBinding, message: string) {
  return createMiddleware<AppEnv>(async (c, next) => {
    // Always set on Cloudflare; missing only in local tests.
    const ip = c.req.header('CF-Connecting-IP');
    if (ip && !(await c.env[ipLimit].limit({ key: `ip:${ip}` })).success) {
      throw new ApiError('rate_limited', message, 429);
    }
    const anonId = c.get('anonId');
    if (anonId && !(await c.env[anonLimit].limit({ key: `anon:${anonId}` })).success) {
      throw new ApiError('rate_limited', message, 429);
    }
    await next();
  });
}

/** New feedback. */
export const writeRateLimit = rateLimit('WRITE_LIMIT_ANON', 'WRITE_LIMIT_IP', 'Too many posts, try again soon');

/** Hearts, counted apart from posts so tapping hearts never blocks a post. */
export const reactionRateLimit = rateLimit(
  'REACTION_LIMIT_ANON',
  'REACTION_LIMIT_IP',
  'Too many hearts, try again soon',
);

/** New, edited and deleted comments, counted apart from posts. */
export const commentRateLimit = rateLimit(
  'COMMENT_LIMIT_ANON',
  'COMMENT_LIMIT_IP',
  'Too many comments, try again soon',
);
