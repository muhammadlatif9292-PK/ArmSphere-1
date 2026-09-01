-- Provincial Jurisdiction Enforcement
-- Adds province field to disputes, sanctions, and matches tables to enable
-- PROVINCIAL_DIRECTOR role filtering. This is a backfill-friendly
-- nullable column — existing rows remain valid until explicitly
-- populated. New rows created via services must include province.

ALTER TABLE "disputes" ADD COLUMN IF NOT EXISTS "province" varchar(100);
ALTER TABLE "sanctions" ADD COLUMN IF NOT EXISTS "province" varchar(100);
ALTER TABLE "matches" ADD COLUMN IF NOT EXISTS "province" varchar(100);

-- Index for efficient province filtering on disputes
CREATE INDEX IF NOT EXISTS "idx_disputes_province" ON "disputes" ("province");
-- Index for efficient province filtering on sanctions
CREATE INDEX IF NOT EXISTS "idx_sanctions_province" ON "sanctions" ("province");

--> statement-breakpoint