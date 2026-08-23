CREATE TABLE IF NOT EXISTS "scheduled_jobs" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"job_type" text NOT NULL,
	"payload" jsonb,
	"status" text DEFAULT 'pending' NOT NULL,
	"scheduled_for" timestamp NOT NULL,
	"last_run_at" timestamp,
	"last_error" text,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
ALTER TABLE "events" ADD COLUMN "organizer_id" uuid;--> statement-breakpoint
ALTER TABLE "events" ADD COLUMN "payment_method" varchar(50) DEFAULT 'STRIPE' NOT NULL;--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "idx_scheduled_jobs_status" ON "scheduled_jobs" ("status");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "idx_scheduled_jobs_type" ON "scheduled_jobs" ("job_type");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "idx_scheduled_jobs_scheduled_for" ON "scheduled_jobs" ("scheduled_for");--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "events" ADD CONSTRAINT "events_organizer_id_users_id_fk" FOREIGN KEY ("organizer_id") REFERENCES "users"("id") ON DELETE set null ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;

