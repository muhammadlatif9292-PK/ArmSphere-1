-- Add Missing Province Fields for Complete Jurisdiction Enforcement
-- Adds province fields to users, matches, and tournament_matches tables
-- Required for complete PROVINCIAL_DIRECTOR role-based filtering and authorization

ALTER TABLE "users" ADD COLUMN IF NOT EXISTS "province" varchar(100);
ALTER TABLE "matches" ADD COLUMN IF NOT EXISTS "province" varchar(100);
ALTER TABLE "tournament_matches" ADD COLUMN IF NOT EXISTS "province" varchar(100);

-- Index for efficient province filtering on users (for director lookups)
CREATE INDEX IF NOT EXISTS "idx_users_province" ON "users" ("province");

-- Index for efficient province filtering on matches
CREATE INDEX IF NOT EXISTS "idx_matches_province" ON "matches" ("province");

-- Index for efficient province filtering on tournament_matches
CREATE INDEX IF NOT EXISTS "idx_tournament_matches_province" ON "tournament_matches" ("province");

--> statement-breakpoint