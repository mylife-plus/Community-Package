import { exports } from 'cloudflare:workers';
import { describe, expect, it } from 'vitest';

describe('GET /v1/health', () => {
  it('returns ok when D1 answers', async () => {
    const res = await exports.default.fetch('https://example.com/v1/health');

    expect(res.status).toBe(200);
    expect(await res.json()).toEqual({ status: 'ok', db: 'ok' });
  });
});

describe('unknown routes', () => {
  it('return the standard error shape', async () => {
    const res = await exports.default.fetch('https://example.com/v1/nope');

    expect(res.status).toBe(404);
    expect(await res.json()).toEqual({
      error: { code: 'not_found', message: 'Not found' },
    });
  });

  it('outside /v1 are not found either', async () => {
    const res = await exports.default.fetch('https://example.com/health');

    expect(res.status).toBe(404);
  });
});
