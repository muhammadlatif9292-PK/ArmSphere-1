-- Hand-trimmed, matching this project's established precedent (see migration
-- 0010): drizzle-kit's raw diff for this snapshot transition included dozens
-- of unrelated DROP CONSTRAINT / DROP INDEX statements for indexes that
-- index.ts's index-declaration blocks don't currently list but that earlier
-- migrations already created and that the real database still needs —
-- applying that raw diff would have destructively dropped real, in-use
-- indexes without recreating them. This file keeps only the two statements
-- that were actually intended:
--
-- 1. elo_ledger: composite uniqueness on (match_id, athlete_id). verifyMatch()
--    inserts exactly one ELO ledger row per athlete per match verification —
--    this is the database-level backstop against a match's ELO being applied
--    twice (e.g. two verification requests racing past the application-level
--    status check before either commits).
--
-- 2. team_members: composite uniqueness on (team_id, athlete_id). This index
--    already exists in the real database (created by migration 0000,
--    idx_team_members_team_athlete) — the Drizzle schema just never declared
--    it until now. IF NOT EXISTS makes this a safe no-op against a database
--    that already has it, and a real create against one that doesn't.

CREATE UNIQUE INDEX IF NOT EXISTS "idx_elo_ledger_match_athlete" ON "elo_ledger" ("match_id","athlete_id");--> statement-breakpoint
CREATE UNIQUE INDEX IF NOT EXISTS "idx_team_members_team_athlete" ON "team_members" ("team_id","athlete_id");
