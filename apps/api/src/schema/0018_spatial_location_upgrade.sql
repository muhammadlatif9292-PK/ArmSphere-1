-- Migration 0018: Spatial Location Upgrade & Radar Beacons (Non-Destructive / Idempotent)
-- Adds nullable latitude/longitude columns and athlete location privacy controls across
-- core spatial entities, plus the ephemeral `radar_beacons` table.

ALTER TABLE athlete_profiles
  ADD COLUMN IF NOT EXISTS latitude REAL,
  ADD COLUMN IF NOT EXISTS longitude REAL,
  ADD COLUMN IF NOT EXISTS location_visibility VARCHAR(20) NOT NULL DEFAULT 'AREA',
  ADD COLUMN IF NOT EXISTS location_fuzz_seed VARCHAR(64);

ALTER TABLE events
  ADD COLUMN IF NOT EXISTS latitude REAL,
  ADD COLUMN IF NOT EXISTS longitude REAL;

ALTER TABLE venue_partners
  ADD COLUMN IF NOT EXISTS latitude REAL,
  ADD COLUMN IF NOT EXISTS longitude REAL;

ALTER TABLE athlete_clubs
  ADD COLUMN IF NOT EXISTS latitude REAL,
  ADD COLUMN IF NOT EXISTS longitude REAL;

ALTER TABLE informal_events
  ADD COLUMN IF NOT EXISTS latitude REAL,
  ADD COLUMN IF NOT EXISTS longitude REAL;

CREATE TABLE IF NOT EXISTS radar_beacons (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id),
  beacon_type VARCHAR(30) NOT NULL,
  title VARCHAR(255) NOT NULL,
  latitude REAL NOT NULL,
  longitude REAL NOT NULL,
  weight_class VARCHAR(50),
  arm_preference VARCHAR(20),
  expires_at TIMESTAMP NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_athlete_profiles_spatial
  ON athlete_profiles (latitude, longitude);

CREATE INDEX IF NOT EXISTS idx_events_spatial
  ON events (latitude, longitude);

CREATE INDEX IF NOT EXISTS idx_venue_partners_spatial
  ON venue_partners (latitude, longitude);

CREATE INDEX IF NOT EXISTS idx_athlete_clubs_spatial
  ON athlete_clubs (latitude, longitude);

CREATE INDEX IF NOT EXISTS idx_informal_events_spatial
  ON informal_events (latitude, longitude);

CREATE INDEX IF NOT EXISTS idx_radar_beacons_expires_at
  ON radar_beacons (expires_at);

CREATE INDEX IF NOT EXISTS idx_radar_beacons_spatial
  ON radar_beacons (latitude, longitude);

CREATE INDEX IF NOT EXISTS idx_radar_beacons_user_id
  ON radar_beacons (user_id);
