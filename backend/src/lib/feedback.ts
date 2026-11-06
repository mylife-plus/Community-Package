/**
 * Columns read for a feedback item, as seen by the caller.
 * `?1` must be bound to the caller's anonymous ID, or null.
 * `author_id` is never selected, so it can never leak into a response.
 */
export const FEEDBACK_SELECT = `
  f.id, f.number, f.type, f.text, f.lang, f.status, f.cost_cents, f.github_url,
  f.screen_path, f.steps_json, f.os_version, f.app_version, f.device_model,
  f.reaction_count, f.comment_count, f.created_at, f.updated_at,
  CASE WHEN ?1 IS NOT NULL AND f.author_id = ?1 THEN 1 ELSE 0 END AS is_mine,
  EXISTS (SELECT 1 FROM reactions r WHERE r.feedback_id = f.id AND r.anon_id = ?1) AS reacted`;

export type FeedbackRow = {
  id: number;
  number: number;
  type: 'improvement' | 'problem' | 'idea';
  text: string;
  lang: string;
  status: 'planned' | 'in_progress' | 'done' | null;
  cost_cents: number | null;
  github_url: string | null;
  screen_path: string | null;
  steps_json: string | null;
  os_version: string | null;
  app_version: string | null;
  device_model: string | null;
  reaction_count: number;
  comment_count: number;
  created_at: number;
  updated_at: number;
  is_mine: number;
  reacted: number;
};

/** The JSON shape of a feedback item in API responses. */
export function toFeedbackJson(row: FeedbackRow) {
  return {
    number: row.number,
    type: row.type,
    text: row.text,
    lang: row.lang,
    status: row.status,
    costCents: row.cost_cents,
    githubUrl: row.github_url,
    screenPath: row.screen_path,
    steps: parseSteps(row),
    osVersion: row.os_version,
    appVersion: row.app_version,
    deviceModel: row.device_model,
    reactionCount: row.reaction_count,
    commentCount: row.comment_count,
    reacted: row.reacted === 1,
    isMine: row.is_mine === 1,
    createdAt: new Date(row.created_at).toISOString(),
    updatedAt: new Date(row.updated_at).toISOString(),
  };
}

function parseSteps(row: FeedbackRow): string[] | null {
  if (row.steps_json === null) return null;
  try {
    const steps: unknown = JSON.parse(row.steps_json);
    if (Array.isArray(steps) && steps.every((s) => typeof s === 'string')) return steps;
  } catch {
    // Logged below.
  }
  console.error('feedback: bad steps_json', { id: row.id });
  return null;
}
