/**
 * Local rate limit windows are aligned to the wall clock (miniflare
 * src/workers/ratelimit/ratelimit-object.worker.ts: epoch = now / period).
 * A burst that crosses a window edge would be split over two windows, so
 * wait for a fresh window when the current one is about to end.
 */
export async function awaitFreshWindow() {
  const intoWindow = Date.now() % 60_000;
  if (intoWindow > 50_000) await new Promise((r) => setTimeout(r, 60_000 - intoWindow + 50));
}

/**
 * Timeout for tests that call [awaitFreshWindow]: the wait alone can take
 * 10 s, twice Vitest's default 5 s test timeout.
 */
export const RATE_LIMIT_TEST_TIMEOUT = 30_000;
