ALTER TABLE "matches" ADD COLUMN IF NOT EXISTS "idempotency_key" varchar(255);--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "matches" ADD CONSTRAINT "matches_idempotency_key_unique" UNIQUE("idempotency_key");
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
