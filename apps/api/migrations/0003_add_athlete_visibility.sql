ALTER TABLE "athlete_profiles" ADD COLUMN IF NOT EXISTS "profile_visibility" varchar(20) DEFAULT 'PUBLIC' NOT NULL;--> statement-breakpoint
ALTER TABLE "athlete_profiles" ADD COLUMN IF NOT EXISTS "is_searchable" boolean DEFAULT true NOT NULL;
