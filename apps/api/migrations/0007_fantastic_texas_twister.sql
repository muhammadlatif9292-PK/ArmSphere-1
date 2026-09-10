CREATE TABLE IF NOT EXISTS "blocked_users" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"blocker_id" uuid NOT NULL,
	"blocked_id" uuid NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "informal_event_participants" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"informal_event_id" uuid NOT NULL,
	"user_id" uuid NOT NULL,
	"joined_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "informal_events" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"created_by_user_id" uuid NOT NULL,
	"title" varchar(255) NOT NULL,
	"description" text NOT NULL,
	"city" varchar(100) NOT NULL,
	"province" varchar(100),
	"scheduled_at" timestamp NOT NULL,
	"max_participants" integer,
	"is_public" boolean DEFAULT true NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "payments" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"event_registration_id" uuid NOT NULL,
	"amount_cents" integer NOT NULL,
	"currency" varchar(10) DEFAULT 'CAD' NOT NULL,
	"stripe_payment_intent_id" varchar(255) NOT NULL,
	"status" varchar(50) DEFAULT 'PENDING' NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "processed_stripe_events" (
	"id" varchar(255) PRIMARY KEY NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "referee_certifications" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" uuid NOT NULL,
	"certification_level" varchar(100) NOT NULL,
	"issued_at" timestamp NOT NULL,
	"expires_at" timestamp,
	"issuing_body" varchar(255) NOT NULL,
	"status" varchar(50) DEFAULT 'ACTIVE' NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "talent_nominations" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"nominated_by_user_id" uuid NOT NULL,
	"nominee_name" varchar(255) NOT NULL,
	"nominee_contact" varchar(255),
	"city" varchar(100) NOT NULL,
	"province" varchar(100) NOT NULL,
	"notes" text,
	"status" varchar(50) DEFAULT 'PENDING' NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "venue_partners" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"name" varchar(255) NOT NULL,
	"city" varchar(100) NOT NULL,
	"province" varchar(100) NOT NULL,
	"address" text NOT NULL,
	"contact_info" varchar(255),
	"description" text,
	"logo_url" varchar(1024),
	"owner_user_id" uuid,
	"is_verified" boolean DEFAULT false NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
DROP INDEX IF EXISTS "idx_community_posts_created_at";--> statement-breakpoint
ALTER TABLE "athlete_profiles" ADD COLUMN IF NOT EXISTS "profile_visibility" varchar(20) DEFAULT 'PUBLIC' NOT NULL;--> statement-breakpoint
ALTER TABLE "athlete_profiles" ADD COLUMN IF NOT EXISTS "is_searchable" boolean DEFAULT true NOT NULL;--> statement-breakpoint
ALTER TABLE "athlete_profiles" ADD COLUMN IF NOT EXISTS "stripe_customer_id" varchar(255);--> statement-breakpoint
ALTER TABLE "community_posts" ADD COLUMN IF NOT EXISTS "external_url" varchar(1024) NOT NULL;--> statement-breakpoint
ALTER TABLE "community_posts" ADD COLUMN IF NOT EXISTS "platform" varchar(50) NOT NULL;--> statement-breakpoint
ALTER TABLE "community_posts" ADD COLUMN IF NOT EXISTS "category" varchar(50);--> statement-breakpoint
ALTER TABLE "community_posts" ADD COLUMN IF NOT EXISTS "moderation_status" varchar(50) DEFAULT 'PENDING' NOT NULL;--> statement-breakpoint
ALTER TABLE "community_posts" ADD COLUMN IF NOT EXISTS "moderated_by" uuid;--> statement-breakpoint
ALTER TABLE "community_posts" ADD COLUMN IF NOT EXISTS "moderated_at" timestamp;--> statement-breakpoint
ALTER TABLE "event_registrations" ADD COLUMN IF NOT EXISTS "payment_confirmed_by_organizer" boolean DEFAULT false NOT NULL;--> statement-breakpoint
ALTER TABLE "event_registrations" ADD COLUMN IF NOT EXISTS "payment_confirmed_at" timestamp;--> statement-breakpoint
ALTER TABLE "events" ADD COLUMN IF NOT EXISTS "registration_fee_cents" integer;--> statement-breakpoint
ALTER TABLE "events" ADD COLUMN IF NOT EXISTS "payment_qr_image_url" varchar(1024);--> statement-breakpoint
CREATE UNIQUE INDEX IF NOT EXISTS "idx_blocked_users_blocker_blocked" ON "blocked_users" ("blocker_id","blocked_id");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "idx_blocked_users_blocker" ON "blocked_users" ("blocker_id");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "idx_blocked_users_blocked" ON "blocked_users" ("blocked_id");--> statement-breakpoint
CREATE UNIQUE INDEX IF NOT EXISTS "idx_informal_event_parts_event_user" ON "informal_event_participants" ("informal_event_id","user_id");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "idx_informal_event_parts_event" ON "informal_event_participants" ("informal_event_id");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "idx_informal_event_parts_user" ON "informal_event_participants" ("user_id");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "idx_informal_events_creator" ON "informal_events" ("created_by_user_id");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "idx_informal_events_city" ON "informal_events" ("city");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "idx_ref_certs_user" ON "referee_certifications" ("user_id");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "idx_ref_certs_status" ON "referee_certifications" ("status");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "idx_talent_noms_nominator" ON "talent_nominations" ("nominated_by_user_id");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "idx_talent_noms_status" ON "talent_nominations" ("status");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "idx_venue_partners_owner" ON "venue_partners" ("owner_user_id");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "idx_venue_partners_city" ON "venue_partners" ("city");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "idx_venue_partners_province" ON "venue_partners" ("province");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "idx_community_posts_status_created_at" ON "community_posts" ("moderation_status","created_at");--> statement-breakpoint
CREATE UNIQUE INDEX IF NOT EXISTS "idx_event_regs_event_athlete_not_rejected" ON "event_registrations" ("event_id","athlete_id");--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "community_posts" ADD CONSTRAINT "community_posts_moderated_by_users_id_fk" FOREIGN KEY ("moderated_by") REFERENCES "users"("id") ON DELETE set null ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
ALTER TABLE "community_posts" DROP COLUMN IF EXISTS "media_type";--> statement-breakpoint
ALTER TABLE "community_posts" DROP COLUMN IF EXISTS "file_key";--> statement-breakpoint
ALTER TABLE "community_posts" DROP COLUMN IF EXISTS "bucket_name";--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "blocked_users" ADD CONSTRAINT "blocked_users_blocker_id_athlete_profiles_id_fk" FOREIGN KEY ("blocker_id") REFERENCES "athlete_profiles"("id") ON DELETE cascade ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "blocked_users" ADD CONSTRAINT "blocked_users_blocked_id_athlete_profiles_id_fk" FOREIGN KEY ("blocked_id") REFERENCES "athlete_profiles"("id") ON DELETE cascade ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "informal_event_participants" ADD CONSTRAINT "informal_event_participants_informal_event_id_informal_events_id_fk" FOREIGN KEY ("informal_event_id") REFERENCES "informal_events"("id") ON DELETE cascade ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "informal_event_participants" ADD CONSTRAINT "informal_event_participants_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE cascade ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "informal_events" ADD CONSTRAINT "informal_events_created_by_user_id_users_id_fk" FOREIGN KEY ("created_by_user_id") REFERENCES "users"("id") ON DELETE cascade ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "payments" ADD CONSTRAINT "payments_event_registration_id_event_registrations_id_fk" FOREIGN KEY ("event_registration_id") REFERENCES "event_registrations"("id") ON DELETE cascade ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "referee_certifications" ADD CONSTRAINT "referee_certifications_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE cascade ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "talent_nominations" ADD CONSTRAINT "talent_nominations_nominated_by_user_id_users_id_fk" FOREIGN KEY ("nominated_by_user_id") REFERENCES "users"("id") ON DELETE cascade ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "venue_partners" ADD CONSTRAINT "venue_partners_owner_user_id_users_id_fk" FOREIGN KEY ("owner_user_id") REFERENCES "users"("id") ON DELETE set null ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
