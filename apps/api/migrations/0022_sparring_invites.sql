CREATE TABLE IF NOT EXISTS "sparring_invites" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"sender_team_id" uuid NOT NULL,
	"recipient_team_id" uuid NOT NULL,
	"creator_id" uuid NOT NULL,
	"responder_id" uuid,
	"status" varchar(50) DEFAULT 'PENDING' NOT NULL,
	"scheduled_date" timestamp,
	"location" varchar(255),
	"message" text,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL,
	"responded_at" timestamp,
	CONSTRAINT "sparring_invites_sender_team_id_teams_id_fk" FOREIGN KEY ("sender_team_id") REFERENCES "public"."teams"("id") ON DELETE cascade ON UPDATE no action,
	CONSTRAINT "sparring_invites_recipient_team_id_teams_id_fk" FOREIGN KEY ("recipient_team_id") REFERENCES "public"."teams"("id") ON DELETE cascade ON UPDATE no action,
	CONSTRAINT "sparring_invites_creator_id_users_id_fk" FOREIGN KEY ("creator_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action,
	CONSTRAINT "sparring_invites_responder_id_users_id_fk" FOREIGN KEY ("responder_id") REFERENCES "public"."users"("id") ON DELETE set null ON UPDATE no action
);

CREATE INDEX IF NOT EXISTS "idx_sparring_invites_sender_team" ON "sparring_invites" ("sender_team_id");
CREATE INDEX IF NOT EXISTS "idx_sparring_invites_recipient_team" ON "sparring_invites" ("recipient_team_id");
CREATE INDEX IF NOT EXISTS "idx_sparring_invites_status" ON "sparring_invites" ("status");
