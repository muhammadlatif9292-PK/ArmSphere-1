CREATE TABLE IF NOT EXISTS "sync_tombstones" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"table_name" varchar(100) NOT NULL,
	"record_id" uuid NOT NULL,
	"owner_user_id" uuid,
	"deleted_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
ALTER TABLE "matches" ADD COLUMN IF NOT EXISTS "updated_at" timestamp DEFAULT now() NOT NULL;--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "idx_tombstones_owner_deleted" ON "sync_tombstones" ("owner_user_id","deleted_at");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "idx_tombstones_table_record" ON "sync_tombstones" ("table_name","record_id");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "idx_matches_updated_at" ON "matches" ("updated_at");--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "sync_tombstones" ADD CONSTRAINT "sync_tombstones_owner_user_id_users_id_fk" FOREIGN KEY ("owner_user_id") REFERENCES "users"("id") ON DELETE cascade ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
