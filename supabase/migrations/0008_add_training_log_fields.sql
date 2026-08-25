ALTER TABLE "community_posts" ADD COLUMN IF NOT EXISTS "exercise_type" varchar(50);--> statement-breakpoint
ALTER TABLE "community_posts" ADD COLUMN IF NOT EXISTS "weight_kg" numeric(10, 2);--> statement-breakpoint
ALTER TABLE "community_posts" ADD COLUMN IF NOT EXISTS "reps" integer;
