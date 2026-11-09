-- Comments: soft delete for comments that still have replies, a parent
-- index for loading replies, and full-text search over comment text.

-- Set when the author deletes a top-level comment that has replies from
-- others. The row stays as a "Comment deleted" placeholder with an empty
-- text; it is removed once its last reply is gone.
ALTER TABLE comments ADD COLUMN deleted_at INTEGER;

CREATE INDEX idx_comments_parent ON comments (parent_id);

-- Same external-content setup as feedback_fts in 0001:
-- https://www.sqlite.org/fts5.html#external_content_tables
CREATE VIRTUAL TABLE comments_fts USING fts5(text, content='comments', content_rowid='id');

CREATE TRIGGER comments_fts_insert AFTER INSERT ON comments BEGIN
  INSERT INTO comments_fts (rowid, text) VALUES (new.id, new.text);
END;

CREATE TRIGGER comments_fts_delete AFTER DELETE ON comments BEGIN
  INSERT INTO comments_fts (comments_fts, rowid, text) VALUES ('delete', old.id, old.text);
END;

CREATE TRIGGER comments_fts_update AFTER UPDATE OF text ON comments BEGIN
  INSERT INTO comments_fts (comments_fts, rowid, text) VALUES ('delete', old.id, old.text);
  INSERT INTO comments_fts (rowid, text) VALUES (new.id, new.text);
END;

-- Index the comments that already exist:
-- https://www.sqlite.org/fts5.html#the_rebuild_command
INSERT INTO comments_fts (comments_fts) VALUES ('rebuild');
