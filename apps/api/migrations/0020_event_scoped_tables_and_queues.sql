ALTER TABLE "match_tables" ADD COLUMN "event_id" uuid NOT NULL;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "match_tables" ADD CONSTRAINT "match_tables_event_id_events_id_fk" FOREIGN KEY ("event_id") REFERENCES "events"("id") ON DELETE cascade ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "idx_match_tables_event_id" ON "match_tables" ("event_id");
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "tournament_table_queue" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"table_id" uuid NOT NULL,
	"match_id" uuid NOT NULL,
	"position" integer NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "tournament_table_queue" ADD CONSTRAINT "tournament_table_queue_table_id_match_tables_id_fk" FOREIGN KEY ("table_id") REFERENCES "match_tables"("id") ON DELETE cascade ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "tournament_table_queue" ADD CONSTRAINT "tournament_table_queue_match_id_tournament_matches_id_fk" FOREIGN KEY ("match_id") REFERENCES "tournament_matches"("id") ON DELETE cascade ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
CREATE UNIQUE INDEX IF NOT EXISTS "idx_tournament_table_queue_match_id" ON "tournament_table_queue" ("match_id");
--> statement-breakpoint
CREATE UNIQUE INDEX IF NOT EXISTS "idx_tournament_table_queue_table_position" ON "tournament_table_queue" ("table_id", "position");
--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "idx_tournament_table_queue_table_id" ON "tournament_table_queue" ("table_id");
