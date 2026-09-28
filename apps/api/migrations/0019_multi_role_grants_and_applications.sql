CREATE TABLE IF NOT EXISTS "user_role_grants" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" uuid NOT NULL,
	"role" varchar(50) NOT NULL,
	"status" varchar(50) DEFAULT 'ACTIVE' NOT NULL,
	"scope" varchar(100),
	"granted_by" uuid,
	"granted_at" timestamp DEFAULT now() NOT NULL,
	"revoked_at" timestamp,
	"revocation_reason" text,
	"verification_metadata" jsonb,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "user_role_grants" ADD CONSTRAINT "user_role_grants_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE cascade ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "user_role_grants" ADD CONSTRAINT "user_role_grants_granted_by_users_id_fk" FOREIGN KEY ("granted_by") REFERENCES "users"("id") ON DELETE set null ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
CREATE UNIQUE INDEX IF NOT EXISTS "idx_user_role_grants_user_role" ON "user_role_grants" ("user_id", "role");
--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "idx_user_role_grants_user_status" ON "user_role_grants" ("user_id", "status");
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "role_applications" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" uuid NOT NULL,
	"role" varchar(50) NOT NULL,
	"status" varchar(50) DEFAULT 'PENDING' NOT NULL,
	"experience_details" text,
	"certification_number" varchar(100),
	"documents" jsonb,
	"reviewer_id" uuid,
	"reviewed_at" timestamp,
	"review_notes" text,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "role_applications" ADD CONSTRAINT "role_applications_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE cascade ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "role_applications" ADD CONSTRAINT "role_applications_reviewer_id_users_id_fk" FOREIGN KEY ("reviewer_id") REFERENCES "users"("id") ON DELETE set null ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "idx_role_applications_user_role_status" ON "role_applications" ("user_id", "role", "status");
--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "idx_role_applications_status" ON "role_applications" ("status");
--> statement-breakpoint
-- Backfill all existing users with their current users.role as an ACTIVE grant
INSERT INTO "user_role_grants" ("user_id", "role", "status")
SELECT "id", "role", 'ACTIVE' FROM "users"
ON CONFLICT ("user_id", "role") DO NOTHING;
