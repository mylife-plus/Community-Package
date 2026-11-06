import { Hono } from 'hono';
import { ApiError, errorResponse } from './lib/errors';
import { health } from './routes/health';

const app = new Hono<{ Bindings: Env }>().basePath('/v1');

app.route('/health', health);

app.notFound((c) => errorResponse(c, new ApiError('not_found', 'Not found', 404)));

app.onError((err, c) => {
  if (err instanceof ApiError) return errorResponse(c, err);
  console.error('unhandled error', err);
  return errorResponse(c, new ApiError('server_error', 'Something went wrong', 500));
});

export default app;
