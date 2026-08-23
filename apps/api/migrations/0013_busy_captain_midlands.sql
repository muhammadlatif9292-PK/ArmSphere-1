ALTER TABLE "matches" ADD COLUMN "idempotency_key" varchar(255);--> statement-breakpoint
ALTER TABLE "matches" ADD CONSTRAINT "matches_idempotency_key_unique" UNIQUE("idempotency_key");