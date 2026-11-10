import { env, exports } from 'cloudflare:workers';
import { beforeAll, describe, expect, it } from 'vitest';
import { problemText } from '../src/routes/feedback';

const BASE = 'https://example.com/v1/feedback';

type Item = Record<string, unknown> & { number: number };

function post(body: unknown) {
  return exports.default.fetch(`${BASE}?lang=en`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-App-Id': 'inventory',
      'X-Anon-Id': crypto.randomUUID(),
    },
    body: JSON.stringify(body),
  });
}

async function nextNumber() {
  const row = await env.DB.prepare("SELECT next_number FROM apps WHERE id = 'inventory'").first<{
    next_number: number;
  }>();
  return row?.next_number;
}

const problem = {
  type: 'problem',
  screenPath: 'Inventory > Sell Items > Add Items',
  steps: ['Tap plus', 'Add an item'],
  osVersion: 'iOS 18.1',
  appVersion: '3.2.0',
  deviceModel: 'iPhone 15 Pro',
};

beforeAll(async () => {
  await env.DB.prepare("INSERT INTO apps (id, name, next_number) VALUES ('inventory', 'Inventory', 26)").run();
});

describe('POST /v1/feedback with a Problem', () => {
  it('saves the path, steps, description and device details', async () => {
    const res = await post({
      ...problem,
      steps: ['  Tap plus ', 'Add an item'],
      description: '  No item gets added.  ',
    });

    expect(res.status).toBe(201);
    expect((await res.json()) as Item).toMatchObject({
      number: 26,
      type: 'problem',
      text: 'No item gets added.\n\n1. Tap plus\n2. Add an item',
      screenPath: 'Inventory > Sell Items > Add Items',
      steps: ['Tap plus', 'Add an item'],
      description: 'No item gets added.',
      osVersion: 'iOS 18.1',
      appVersion: '3.2.0',
      deviceModel: 'iPhone 15 Pro',
      isMine: true,
    });
  });

  it('accepts a description of 100 characters', async () => {
    const res = await post({ ...problem, description: 'a'.repeat(100) });

    expect(res.status).toBe(201);
  });

  it('builds the text from the steps alone without a description', async () => {
    const res = await post({ ...problem, description: '   ' });
    const item = (await res.json()) as Item;

    expect(res.status).toBe(201);
    expect(item.text).toBe('1. Tap plus\n2. Add an item');
    expect(item.description).toBeNull();
  });

  it('ignores a text sent with a Problem', async () => {
    const item = (await (await post({ ...problem, text: 'Something else' })).json()) as Item;

    expect(item.text).toBe('1. Tap plus\n2. Add an item');
  });

  it('accepts a Problem without a screen or device details', async () => {
    const res = await post({ type: 'problem', steps: ['Open the app'] });

    expect(res.status).toBe(201);
    expect((await res.json()) as Item).toMatchObject({
      screenPath: null,
      osVersion: null,
      appVersion: null,
      deviceModel: null,
    });
  });

  it('accepts 10 steps of 500 characters', async () => {
    const res = await post({ ...problem, steps: Array.from({ length: 10 }, () => '👍🏽'.repeat(500)) });

    expect(res.status).toBe(201);
  });

  it('keeps the search index on the built text', async () => {
    const item = (await (await post({ ...problem, steps: ['Scan a barcode twice'] })).json()) as Item;
    const hit = await env.DB.prepare(
      `SELECT f.number FROM feedback_fts JOIN feedback f ON f.id = feedback_fts.rowid
       WHERE feedback_fts MATCH 'barcode'`,
    ).first<{ number: number }>();

    expect(hit?.number).toBe(item.number);
  });
});

describe('POST /v1/feedback rejects a Problem with', () => {
  const cases: Array<[string, Record<string, unknown>, string, Record<string, unknown>]> = [
    ['no steps', { steps: undefined }, 'Invalid steps', { field: 'steps' }],
    ['steps that are not a list', { steps: 'Tap plus' }, 'Invalid steps', { field: 'steps' }],
    ['a step that is not text', { steps: ['Tap plus', 3] }, 'Invalid steps', { field: 'steps' }],
    ['an empty step list', { steps: [] }, 'Problems need 1 to 10 steps', { field: 'steps' }],
    ['11 steps', { steps: Array.from({ length: 11 }, () => 'Tap') }, 'Problems need 1 to 10 steps', { field: 'steps' }],
    ['a blank step', { steps: ['Tap plus', '  '] }, 'Each step must be 1 to 500 characters', { field: 'steps', index: 1 }],
    ['a step over 500 characters', { steps: ['a'.repeat(501)] }, 'Each step must be 1 to 500 characters', { field: 'steps', index: 0, maxLength: 500 }],
    ['a description over 100 characters', { description: 'a'.repeat(101) }, 'description must be at most 100 characters', { field: 'description', maxLength: 100 }],
    ['a description that is not text', { description: 5 }, 'Invalid description', { field: 'description' }],
    ['a screen path over 300 characters', { screenPath: 'a'.repeat(301) }, 'screenPath must be at most 300 characters', { field: 'screenPath', maxLength: 300 }],
    ['a screen path that is not text', { screenPath: ['Sell Items'] }, 'Invalid screenPath', { field: 'screenPath' }],
    ['a device detail over 100 characters', { deviceModel: 'a'.repeat(101) }, 'deviceModel must be at most 100 characters', { field: 'deviceModel', maxLength: 100 }],
    ['a device detail that is not text', { osVersion: 18 }, 'Invalid osVersion', { field: 'osVersion' }],
  ];

  it.each(cases)('%s with 400', async (_, change, message, details) => {
    const before = await nextNumber();
    const res = await post({ ...problem, ...change });

    expect(res.status).toBe(400);
    expect(await res.json()).toEqual({ error: { code: 'bad_request', message, details } });
    expect(await nextNumber()).toBe(before);
  });
});

describe('problemText', () => {
  it('numbers the steps from 1, one per line', () => {
    expect(problemText(null, ['a', 'b', 'c'])).toBe('1. a\n2. b\n3. c');
  });

  it('puts the description first, then a blank line', () => {
    expect(problemText('Broken', ['a'])).toBe('Broken\n\n1. a');
  });
});
