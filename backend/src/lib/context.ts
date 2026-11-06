import { createMiddleware } from 'hono/factory';
import { ApiError } from './errors';

/** Hono environment for routes that belong to one app. */
export type AppEnv = {
  Bindings: Env;
  Variables: {
    /** From the `X-App-Id` header, checked against the `apps` table. */
    appId: string;
    /** From the optional `X-Anon-Id` header, lowercased. */
    anonId: string | null;
  };
};

const APP_ID_PATTERN = /^[a-z][a-z0-9_-]{0,31}$/;
const UUID_PATTERN = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/;

// Apps are only ever added, never removed, so a known ID can stay cached for
// the life of the isolate. Unknown IDs are not cached, so a new app works
// without a redeploy.
const knownApps = new Set<string>();

/** Reads and checks `X-App-Id` and `X-Anon-Id` for app-scoped routes. */
export const appContext = createMiddleware<AppEnv>(async (c, next) => {
  const appId = c.req.header('X-App-Id')?.trim();
  if (!appId) {
    throw new ApiError('bad_request', 'Missing X-App-Id header', 400);
  }
  if (!APP_ID_PATTERN.test(appId) || !(await appExists(c.env.DB, appId))) {
    throw new ApiError('bad_request', 'Unknown app', 400);
  }

  const rawAnonId = c.req.header('X-Anon-Id')?.trim().toLowerCase();
  if (rawAnonId && !UUID_PATTERN.test(rawAnonId)) {
    throw new ApiError('bad_request', 'Invalid X-Anon-Id header', 400);
  }

  c.set('appId', appId);
  c.set('anonId', rawAnonId || null);
  await next();
});

/** For writes: the user must have an anonymous ID (agreed to the privacy notice). */
export const requireAnonId = createMiddleware<AppEnv>(async (c, next) => {
  if (!c.get('anonId')) {
    throw new ApiError('bad_request', 'Missing X-Anon-Id header', 400);
  }
  await next();
});

async function appExists(db: D1Database, appId: string): Promise<boolean> {
  if (knownApps.has(appId)) return true;
  const row = await db.prepare('SELECT 1 AS found FROM apps WHERE id = ?').bind(appId).first();
  if (!row) return false;
  knownApps.add(appId);
  return true;
}
