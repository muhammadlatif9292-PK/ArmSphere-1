-- Idempotent migration for real organization-issued referee certifications & targeted role applications

ALTER TABLE "referee_certifications"
  ADD COLUMN IF NOT EXISTS "issuing_organization_id" uuid;

ALTER TABLE "referee_certifications"
  ADD COLUMN IF NOT EXISTS "athlete_id" uuid;

ALTER TABLE "referee_certifications"
  ADD COLUMN IF NOT EXISTS "issued_by_user_id" uuid;

ALTER TABLE "referee_certifications"
  ADD COLUMN IF NOT EXISTS "notes" text;

DO $$ BEGIN
  ALTER TABLE "referee_certifications"
    ADD CONSTRAINT "referee_certifications_issuing_organization_id_organizations_id_fk"
    FOREIGN KEY ("issuing_organization_id") REFERENCES "organizations"("id") ON DELETE SET NULL;
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  ALTER TABLE "referee_certifications"
    ADD CONSTRAINT "referee_certifications_issued_by_user_id_users_id_fk"
    FOREIGN KEY ("issued_by_user_id") REFERENCES "users"("id") ON DELETE SET NULL;
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

CREATE INDEX IF NOT EXISTS "idx_referee_certifications_org_id"
  ON "referee_certifications" ("issuing_organization_id");

CREATE INDEX IF NOT EXISTS "idx_referee_certifications_athlete_id"
  ON "referee_certifications" ("athlete_id");

ALTER TABLE "role_applications"
  ADD COLUMN IF NOT EXISTS "target_organization_id" uuid;

ALTER TABLE "role_applications"
  ADD COLUMN IF NOT EXISTS "athlete_id" uuid;

DO $$ BEGIN
  ALTER TABLE "role_applications"
    ADD CONSTRAINT "role_applications_target_organization_id_organizations_id_fk"
    FOREIGN KEY ("target_organization_id") REFERENCES "organizations"("id") ON DELETE SET NULL;
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

CREATE INDEX IF NOT EXISTS "idx_role_applications_target_org_status"
  ON "role_applications" ("target_organization_id", "status");
