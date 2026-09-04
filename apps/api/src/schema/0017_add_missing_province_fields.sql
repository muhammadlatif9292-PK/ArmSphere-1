-- Migration: Add additional missing province fields for provincial jurisdiction enforcement
-- Date: 2026-09-01

-- Add province field to users table (missing)
ALTER TABLE users
ADD COLUMN province VARCHAR(100);

-- Add province field to athlete_profiles table (already in 0016, but ensure)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'athlete_profiles' AND column_name = 'province'
    ) THEN
        ALTER TABLE athlete_profiles ADD COLUMN province VARCHAR(100);
    END IF;
END $$;

-- Add province field to matches table (already in 0016, but ensure)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'matches' AND column_name = 'province'
    ) THEN
        ALTER TABLE matches ADD COLUMN province VARCHAR(100);
    END IF;
END $$;

-- Add province field to tournament_matches table (already in 0016, but ensure)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'tournament_matches' AND column_name = 'province'
    ) THEN
        ALTER TABLE tournament_matches ADD COLUMN province VARCHAR(100);
    END IF;
END $$;

-- Add province field to events table (already in 0016, but ensure)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'events' AND column_name = 'province'
    ) THEN
        ALTER TABLE events ADD COLUMN province VARCHAR(100);
    END IF;
END $$;

-- Add province field to event_registrations table (already in 0016, but ensure)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'event_registrations' AND column_name = 'province'
    ) THEN
        ALTER TABLE event_registrations ADD COLUMN province VARCHAR(100);
    END IF;
END $$;

-- Add province field to sanctions table (already in 0016, but ensure)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'sanctions' AND column_name = 'province'
    ) THEN
        ALTER TABLE sanctions ADD COLUMN province VARCHAR(100);
    END IF;
END $$;

-- Create unique index to prevent duplicate provinces on users
CREATE UNIQUE INDEX idx_users_unique_province ON users(province) WHERE province IS NOT NULL;

-- Create unique index to prevent duplicate provinces on athlete_profiles
CREATE UNIQUE INDEX idx_athlete_profiles_unique_province ON athlete_profiles(province) WHERE province IS NOT NULL;

-- Create unique index to prevent duplicate provinces on matches
CREATE UNIQUE INDEX idx_matches_unique_province ON matches(province) WHERE province IS NOT NULL;

-- Create unique index to prevent duplicate provinces on tournament_matches
CREATE UNIQUE INDEX idx_tournament_matches_unique_province ON tournament_matches(province) WHERE province IS NOT NULL;

-- Create unique index to prevent duplicate provinces on events
CREATE UNIQUE INDEX idx_events_unique_province ON events(province) WHERE province IS NOT NULL;

-- Create unique index to prevent duplicate provinces on event_registrations
CREATE UNIQUE INDEX idx_event_registrations_unique_province ON event_registrations(province) WHERE province IS NOT NULL;

-- Create unique index to prevent duplicate provinces on sanctions
CREATE UNIQUE INDEX idx_sanctions_unique_province ON sanctions(province) WHERE province IS NOT NULL;

-- Add NOT NULL constraint to ensure province field is populated for key tables
ALTER TABLE users ALTER COLUMN province SET NOT NULL;
ALTER TABLE athlete_profiles ALTER COLUMN province SET NOT NULL;
ALTER TABLE matches ALTER COLUMN province SET NOT NULL;
ALTER TABLE tournament_matches ALTER COLUMN province SET NOT NULL;
ALTER TABLE events ALTER COLUMN province SET NOT NULL;