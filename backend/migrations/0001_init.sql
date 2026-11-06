-- Initial schema. All timestamps are Unix epoch milliseconds.

CREATE TABLE apps (
  id TEXT PRIMARY KEY,                 -- 'inventory', 'spacetime', 'money'
  name TEXT NOT NULL,
  payment_link_id TEXT,                -- Stripe plink_..., one per app
  next_number INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE feedback (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  app_id TEXT NOT NULL REFERENCES apps(id),
  number INTEGER NOT NULL,             -- shown as #21, counted per app
  type TEXT NOT NULL CHECK (type IN ('improvement','problem','idea')),
  text TEXT NOT NULL,
  lang TEXT NOT NULL,                  -- author's app language
  author_id TEXT,                      -- NULL after unlink
  status TEXT CHECK (status IN ('planned','in_progress','done')),
  cost_cents INTEGER,
  github_url TEXT,
  screen_path TEXT,                    -- Problems: 'Inventory > Sell Item > Add Item'
  steps_json TEXT,                     -- Problems: ["step 1","step 2"]
  os_version TEXT,
  app_version TEXT,
  device_model TEXT,
  reaction_count INTEGER NOT NULL DEFAULT 0,
  comment_count INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  last_activity_at INTEGER NOT NULL,   -- new comment by someone else, or status change
  UNIQUE (app_id, number)
);

CREATE TABLE comments (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  feedback_id INTEGER NOT NULL REFERENCES feedback(id) ON DELETE CASCADE,
  parent_id INTEGER REFERENCES comments(id) ON DELETE CASCADE,  -- one level only
  author_id TEXT,
  is_admin INTEGER NOT NULL DEFAULT 0,
  text TEXT NOT NULL,
  lang TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);

CREATE TABLE reactions (
  feedback_id INTEGER NOT NULL REFERENCES feedback(id) ON DELETE CASCADE,
  anon_id TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  PRIMARY KEY (feedback_id, anon_id)
);

CREATE TABLE feedback_events (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  feedback_id INTEGER NOT NULL REFERENCES feedback(id) ON DELETE CASCADE,
  kind TEXT NOT NULL CHECK (kind IN ('created','edited','planned','in_progress','done')),
  at INTEGER NOT NULL
);

CREATE TABLE reads (
  anon_id TEXT NOT NULL,
  feedback_id INTEGER NOT NULL REFERENCES feedback(id) ON DELETE CASCADE,
  last_seen_at INTEGER NOT NULL,
  PRIMARY KEY (anon_id, feedback_id)
);

CREATE TABLE blocks (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  app_id TEXT NOT NULL,
  anon_id TEXT NOT NULL,
  target_type TEXT NOT NULL CHECK (target_type IN ('feedback','comment')),
  target_id INTEGER NOT NULL,
  reason TEXT NOT NULL,                -- the broken rule
  until_at INTEGER NOT NULL,
  created_at INTEGER NOT NULL
);

CREATE TABLE translations (
  source_hash TEXT NOT NULL,           -- sha256(text), so an edit changes the hash
  target_lang TEXT NOT NULL,
  text TEXT NOT NULL,
  PRIMARY KEY (source_hash, target_lang)
);

CREATE TABLE tips (                    -- cache of completed Stripe Checkout Sessions
  session_id TEXT PRIMARY KEY,
  app_id TEXT NOT NULL,
  name TEXT NOT NULL,                  -- product name, e.g. 'Coffee Tip'
  amount_cents INTEGER NOT NULL,
  created_at INTEGER NOT NULL
);

CREATE INDEX idx_feedback_app_created ON feedback (app_id, created_at);
CREATE INDEX idx_feedback_app_status ON feedback (app_id, status);
CREATE INDEX idx_feedback_author ON feedback (author_id);
CREATE INDEX idx_comments_feedback ON comments (feedback_id);

-- Full-text search over feedback.text. External-content table, kept in sync
-- by the triggers below: https://www.sqlite.org/fts5.html#external_content_tables
CREATE VIRTUAL TABLE feedback_fts USING fts5(text, content='feedback', content_rowid='id');

CREATE TRIGGER feedback_fts_insert AFTER INSERT ON feedback BEGIN
  INSERT INTO feedback_fts (rowid, text) VALUES (new.id, new.text);
END;

CREATE TRIGGER feedback_fts_delete AFTER DELETE ON feedback BEGIN
  INSERT INTO feedback_fts (feedback_fts, rowid, text) VALUES ('delete', old.id, old.text);
END;

CREATE TRIGGER feedback_fts_update AFTER UPDATE OF text ON feedback BEGIN
  INSERT INTO feedback_fts (feedback_fts, rowid, text) VALUES ('delete', old.id, old.text);
  INSERT INTO feedback_fts (rowid, text) VALUES (new.id, new.text);
END;
