-- Migration 0026: Canonical Permanent Profile QR Identity & Unified Gate/Weigh-In/Table Chain
-- Idempotent migration establishing ONE immutable `profile_qr_code` per ArmSphere account,
-- deterministic backfill for existing accounts/profiles/registrations, and gate check-in columns.

BEGIN;

-- 1. Add canonical `profile_qr_code` column to `users`
ALTER TABLE users
  ADD COLUMN IF NOT EXISTS profile_qr_code VARCHAR(255);

-- Deterministic, idempotent backfill for all existing accounts (never regenerates once set)
UPDATE users
SET profile_qr_code = 'ARMSPHERE-ATHLETE-QR:' || id::text
WHERE profile_qr_code IS NULL OR btrim(profile_qr_code) = '';

-- Enforce uniqueness & NOT NULL + automatic fallback default on inserts
ALTER TABLE users
  ALTER COLUMN profile_qr_code SET DEFAULT ('ARMSPHERE-ATHLETE-QR:' || gen_random_uuid()::text),
  ALTER COLUMN profile_qr_code SET NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS idx_users_profile_qr_code
  ON users(profile_qr_code);

-- Guarantee new user rows always receive canonical ARMSPHERE-ATHLETE-QR:<id> when profile_qr_code is omitted,
-- and protect profile_qr_code against accidental mutation after creation.
CREATE OR REPLACE FUNCTION armsphere_assign_canonical_profile_qr()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.id IS NULL THEN
    NEW.id := gen_random_uuid();
  END IF;
  IF NEW.profile_qr_code IS NULL OR btrim(NEW.profile_qr_code) = '' THEN
    NEW.profile_qr_code := 'ARMSPHERE-ATHLETE-QR:' || NEW.id::text;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_users_assign_profile_qr ON users;
CREATE TRIGGER trg_users_assign_profile_qr
  BEFORE INSERT ON users
  FOR EACH ROW
  EXECUTE FUNCTION armsphere_assign_canonical_profile_qr();

CREATE OR REPLACE FUNCTION armsphere_protect_immutable_profile_qr()
RETURNS TRIGGER AS $$
BEGIN
  IF OLD.profile_qr_code IS NOT NULL AND NEW.profile_qr_code IS DISTINCT FROM OLD.profile_qr_code THEN
    NEW.profile_qr_code := OLD.profile_qr_code;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_users_protect_profile_qr ON users;
CREATE TRIGGER trg_users_protect_profile_qr
  BEFORE UPDATE ON users
  FOR EACH ROW
  EXECUTE FUNCTION armsphere_protect_immutable_profile_qr();

-- 2. Mirror canonical `profile_qr_code` onto `athlete_profiles`
ALTER TABLE athlete_profiles
  ADD COLUMN IF NOT EXISTS profile_qr_code VARCHAR(255);

UPDATE athlete_profiles ap
SET profile_qr_code = u.profile_qr_code
FROM users u
WHERE ap.user_id = u.id
  AND (ap.profile_qr_code IS NULL OR ap.profile_qr_code IS DISTINCT FROM u.profile_qr_code);

CREATE INDEX IF NOT EXISTS idx_athlete_profiles_profile_qr_code
  ON athlete_profiles(profile_qr_code);

-- 3. Snapshot canonical `profile_qr_code`, `athlete_full_name`, and gate check-in fields on `event_registrations`
ALTER TABLE event_registrations
  ADD COLUMN IF NOT EXISTS profile_qr_code VARCHAR(255),
  ADD COLUMN IF NOT EXISTS athlete_full_name VARCHAR(255),
  ADD COLUMN IF NOT EXISTS checked_in_at TIMESTAMP,
  ADD COLUMN IF NOT EXISTS checked_in_by UUID REFERENCES users(id);

UPDATE event_registrations er
SET
  profile_qr_code = COALESCE(NULLIF(btrim(er.profile_qr_code), ''), u.profile_qr_code),
  athlete_full_name = COALESCE(NULLIF(btrim(er.athlete_full_name), ''), ap.display_name, u.full_name)
FROM athlete_profiles ap
JOIN users u ON u.id = ap.user_id
WHERE er.athlete_id = ap.id
  AND (
    er.profile_qr_code IS NULL
    OR btrim(er.profile_qr_code) = ''
    OR er.athlete_full_name IS NULL
    OR btrim(er.athlete_full_name) = ''
  );

CREATE INDEX IF NOT EXISTS idx_event_registrations_profile_qr_code
  ON event_registrations(profile_qr_code);

COMMIT;
