import { applyD1Migrations } from 'cloudflare:test';
import { env } from 'cloudflare:workers';

// Each test file gets its own storage, so this runs once per file.
await applyD1Migrations(env.DB, env.TEST_MIGRATIONS);
