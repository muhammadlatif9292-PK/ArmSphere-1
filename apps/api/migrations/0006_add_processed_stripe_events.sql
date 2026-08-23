CREATE TABLE IF NOT EXISTS "processed_stripe_events" (
	"id" varchar(255) PRIMARY KEY NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE UNIQUE INDEX IF NOT EXISTS "idx_event_regs_event_athlete_not_rejected" ON "event_registrations" ("event_id", "athlete_id") WHERE (status != 'REJECTED');
