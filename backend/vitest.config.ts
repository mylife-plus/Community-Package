import { existsSync, readFileSync } from 'node:fs';
import path from 'node:path';
import { cloudflareTest, readD1Migrations } from '@cloudflare/vitest-plugin';
import { defineConfig } from 'vitest/config';

// Tests run on the committed template, so they work the same for everyone.
const template = path.join(import.meta.dirname, 'wrangler.example.jsonc');
const local = path.join(import.meta.dirname, 'wrangler.jsonc');

/// The config without comments and the account's own values, for comparing
/// a local wrangler.jsonc with the template.
function sharedConfig(file: string): unknown {
  const json = readFileSync(file, 'utf8')
    .split('\n')
    // Comments in these files always sit on their own lines.
    .filter((line) => !line.trimStart().startsWith('//'))
    .join('\n')
    .replace(/,(\s*[}\]])/g, '$1');
  const config = JSON.parse(json);
  delete config.name;
  for (const db of config.d1_databases ?? []) {
    delete db.database_name;
    delete db.database_id;
  }
  return config;
}

// A deploy uses wrangler.jsonc; a binding or limit changed in only one of
// the two files would test one thing and deploy another.
if (existsSync(local)) {
  const a = JSON.stringify(sharedConfig(template));
  const b = JSON.stringify(sharedConfig(local));
  if (a !== b) {
    throw new Error(
      'wrangler.jsonc and wrangler.example.jsonc differ in more than the Worker name and ' +
        'the D1 database. Make the same change in both files.',
    );
  }
}

export default defineConfig({
  plugins: [
    cloudflareTest(async () => {
      const migrations = await readD1Migrations(path.join(import.meta.dirname, 'migrations'));
      return {
        wrangler: { configPath: './wrangler.example.jsonc' },
        // Test-only binding, read by test/apply-migrations.ts.
        miniflare: { bindings: { TEST_MIGRATIONS: migrations } },
      };
    }),
  ],
  test: {
    setupFiles: ['./test/apply-migrations.ts'],
  },
});
