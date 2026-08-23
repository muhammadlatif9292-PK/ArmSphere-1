CREATE TABLE IF NOT EXISTS "community_posts" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"athlete_id" uuid NOT NULL,
	"media_type" varchar(50) NOT NULL,
	"file_key" varchar(512) NOT NULL,
	"bucket_name" varchar(255) NOT NULL,
	"caption" text,
	"match_id" uuid,
	"is_deleted" boolean DEFAULT false NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "post_comments" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"post_id" uuid NOT NULL,
	"athlete_id" uuid NOT NULL,
	"body" text NOT NULL,
	"is_deleted" boolean DEFAULT false NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "post_likes" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"post_id" uuid NOT NULL,
	"athlete_id" uuid NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "idx_community_posts_athlete" ON "community_posts" ("athlete_id");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "idx_community_posts_created_at" ON "community_posts" ("created_at");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "idx_post_comments_post" ON "post_comments" ("post_id");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "idx_post_comments_athlete" ON "post_comments" ("athlete_id");--> statement-breakpoint
CREATE UNIQUE INDEX IF NOT EXISTS "idx_post_likes_post_athlete" ON "post_likes" ("post_id","athlete_id");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "idx_post_likes_post" ON "post_likes" ("post_id");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "idx_post_likes_athlete" ON "post_likes" ("athlete_id");--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "community_posts" ADD CONSTRAINT "community_posts_athlete_id_athlete_profiles_id_fk" FOREIGN KEY ("athlete_id") REFERENCES "athlete_profiles"("id") ON DELETE cascade ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "community_posts" ADD CONSTRAINT "community_posts_match_id_matches_id_fk" FOREIGN KEY ("match_id") REFERENCES "matches"("id") ON DELETE set null ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "post_comments" ADD CONSTRAINT "post_comments_post_id_community_posts_id_fk" FOREIGN KEY ("post_id") REFERENCES "community_posts"("id") ON DELETE cascade ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "post_comments" ADD CONSTRAINT "post_comments_athlete_id_athlete_profiles_id_fk" FOREIGN KEY ("athlete_id") REFERENCES "athlete_profiles"("id") ON DELETE cascade ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "post_likes" ADD CONSTRAINT "post_likes_post_id_community_posts_id_fk" FOREIGN KEY ("post_id") REFERENCES "community_posts"("id") ON DELETE cascade ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "post_likes" ADD CONSTRAINT "post_likes_athlete_id_athlete_profiles_id_fk" FOREIGN KEY ("athlete_id") REFERENCES "athlete_profiles"("id") ON DELETE cascade ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
