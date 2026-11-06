import { createMiddleware } from 'hono/factory';
import { type AppEnv } from './context';
import { ApiError } from './errors';

/**
 * Limits writes per anonymous ID and, more loosely, per IP. Limits are set
 * in wrangler.jsonc. Run after `appContext` and `requireAnonId`.
 */
export const writeRateLimit = createMiddleware<AppEnv>(async (c, next) => {
  // Always set on Cloudflare; missing only in local tests.
  const ip = c.req.header('CF-Connecting-IP');
  if (ip && !(await c.env.WRITE_LIMIT_IP.limit({ key: `ip:${ip}` })).success) {
    throw tooMany();
  }
  const anonId = c.get('anonId');
  if (anonId && !(await c.env.WRITE_LIMIT_ANON.limit({ key: `anon:${anonId}` })).success) {
    throw tooMany();
  }
  await next();
});

function tooMany() {
  return new ApiError('rate_limited', 'Too many posts, try again soon', 429);
}
