import { env } from 'cloudflare:workers';
import { describe, expect, it } from 'vitest';

async function search(term: string): Promise<number[]> {
  const { results } = await env.DB.prepare(
    'SELECT rowid FROM feedback_fts WHERE feedback_fts MATCH ?1 ORDER BY rowid',
  )
    .bind(term)
    .all<{ rowid: number }>();
  return results.map((r) => r.rowid);
}

describe('feedback_fts', () => {
  it('follows inserts, text edits and deletes', async () => {
    const db = env.DB;
    await db.prepare("INSERT INTO apps (id, name) VALUES ('money', 'money')").run();
    await db
      .prepare(
        `INSERT INTO feedback (id, app_id, number, type, text, lang, created_at, updated_at, last_activity_at)
         VALUES (1, 'money', 1, 'idea', 'Export receipts as PDF', 'en', 0, 0, 0)`,
      )
      .run();
    expect(await search('receipts')).toEqual([1]);

    await db.prepare("UPDATE feedback SET text = 'Export invoices as CSV' WHERE id = 1").run();
    expect(await search('receipts')).toEqual([]);
    expect(await search('invoices')).toEqual([1]);

    await db.prepare('DELETE FROM feedback WHERE id = 1').run();
    expect(await search('invoices')).toEqual([]);
  });
});
