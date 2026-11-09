import { Hono } from 'hono';
import { appContext } from './lib/context';
import { ApiError, errorResponse } from './lib/errors';
import { comments } from './routes/comments';
import { feedback } from './routes/feedback';
import { health } from './routes/health';

const app = new Hono<{ Bindings: Env }>().basePath('/v1');

app.route('/health', health);

// Routes that belong to one app need X-App-Id. Listed by path, so unknown
// paths still answer 404 instead of complaining about a missing header.
app.use('/feedback', appContext);
app.use('/feedback/*', appContext);
app.route('/feedback', feedback);
app.use('/comments/*', appContext);
app.route('/comments', comments);

app.notFound((c) => errorResponse(c, new ApiError('not_found', 'Not found', 404)));

app.onError((err, c) => {
  if (err instanceof ApiError) return errorResponse(c, err);
  console.error('unhandled error', err);
  return errorResponse(c, new ApiError('server_error', 'Something went wrong', 500));
});

export default app;
