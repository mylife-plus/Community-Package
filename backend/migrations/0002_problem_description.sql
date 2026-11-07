-- Optional "What went wrong?" text of a Problem. For Problems, `text` holds
-- this description (if any) plus the steps, so search, similar search and
-- translation keep working on one column.
ALTER TABLE feedback ADD COLUMN description TEXT;
