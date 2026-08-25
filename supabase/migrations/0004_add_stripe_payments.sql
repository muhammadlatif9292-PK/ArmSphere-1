ALTER TABLE "community_posts" ADD COLUMN IF NOT EXISTS "external_url" varchar(1024) NOT NULL;--> statement-breakpoint
ALTER TABLE "community_posts" ADD COLUMN IF NOT EXISTS "platform" varchar(50) NOT NULL;--> statement-breakpoint
ALTER TABLE "community_posts" ADD COLUMN IF NOT EXISTS "category" varchar(50);--> statement-breakpoint
ALTER TABLE "community_posts" ADD COLUMN IF NOT EXISTS "moderation_status" varchar(50) DEFAULT 'PENDING' NOT NULL;--> statement-breakpoint
ALTER TABLE "community_posts" ADD COLUMN IF NOT EXISTS "moderated_by" uuid;--> statement-breakpoint
ALTER TABLE "community_posts" ADD COLUMN IF NOT EXISTS "moderated_at" timestamp;--> statement-breakpoint
DROP INDEX IF EXISTS "idx_community_posts_created_at";--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "idx_community_posts_status_created_at" ON "community_posts" ("moderation_status","created_at");--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "community_posts" ADD CONSTRAINT "community_posts_moderated_by_users_id_fk" FOREIGN KEY ("moderated_by") REFERENCES "users"("id") ON DELETE set null ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
