CREATE TABLE IF NOT EXISTS "ticket_types" (
  "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  "event_id" uuid NOT NULL,
  "name" varchar(255) NOT NULL,
  "price_cents" integer NOT NULL,
  "quantity_available" integer NOT NULL,
  "quantity_sold" integer DEFAULT 0 NOT NULL,
  "created_at" timestamp DEFAULT now() NOT NULL,
  "updated_at" timestamp DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS "tickets" (
  "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  "ticket_type_id" uuid NOT NULL,
  "purchaser_user_id" uuid NOT NULL,
  "stripe_payment_intent_id" varchar(255),
  "status" varchar(50) DEFAULT 'PENDING' NOT NULL,
  "purchased_at" timestamp DEFAULT now() NOT NULL,
  "confirmation_code" varchar(255) NOT NULL UNIQUE,
  "created_at" timestamp DEFAULT now() NOT NULL,
  "updated_at" timestamp DEFAULT now() NOT NULL
);

CREATE INDEX IF NOT EXISTS "idx_ticket_types_event" ON "ticket_types" ("event_id");
CREATE INDEX IF NOT EXISTS "idx_tickets_type" ON "tickets" ("ticket_type_id");
CREATE INDEX IF NOT EXISTS "idx_tickets_purchaser" ON "tickets" ("purchaser_user_id");
CREATE INDEX IF NOT EXISTS "idx_tickets_stripe" ON "tickets" ("stripe_payment_intent_id");

-- Foreign key constraints (idempotent)
DO $$ BEGIN
 ALTER TABLE "ticket_types" ADD CONSTRAINT "ticket_types_event_id_events_id_fk" FOREIGN KEY ("event_id") REFERENCES "events"("id") ON DELETE CASCADE;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
DO $$ BEGIN
 ALTER TABLE "tickets" ADD CONSTRAINT "tickets_ticket_type_id_ticket_types_id_fk" FOREIGN KEY ("ticket_type_id") REFERENCES "ticket_types"("id") ON DELETE CASCADE;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
DO $$ BEGIN
 ALTER TABLE "tickets" ADD CONSTRAINT "tickets_purchaser_user_id_users_id_fk" FOREIGN KEY ("purchaser_user_id") REFERENCES "users"("id") ON DELETE CASCADE;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
