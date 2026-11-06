import { Hono } from 'hono';
import { ApiError } from '../lib/errors';

export const health = new Hono<{ Bindings: Env }>();

health.get('/', async (c) => {
  try {
    await c.env.DB.prepare('SELECT 1').first();
  } catch (err) {
    console.error('health: D1 check failed', err);
    throw new ApiError('server_error', 'Database unavailable', 503);
  }
  return c.json({ status: 'ok', db: 'ok' });
});
