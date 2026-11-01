-- Allow formal governance disputes to reference either tournament_matches(id) or matches(id)
ALTER TABLE "disputes" DROP CONSTRAINT IF EXISTS "disputes_match_id_tournament_matches_id_fk";
CREATE INDEX IF NOT EXISTS "idx_disputes_match_id" ON "disputes" ("match_id");
