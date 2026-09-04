-- Migration: Add province field to users table for provincial jurisdiction enforcement
-- Date: 2026-09-01

-- Add province field to users table
ALTER TABLE users
ADD COLUMN province VARCHAR(100);

-- Add province field to athlete_profiles table
ALTER TABLE athlete_profiles
ADD COLUMN province VARCHAR(100);

-- Add province field to matches table
ALTER TABLE matches
ADD COLUMN province VARCHAR(100);

-- Add province field to tournament_matches table
ALTER TABLE tournament_matches
ADD COLUMN province VARCHAR(100);

-- Add province field to events table
ALTER TABLE events
ADD COLUMN province VARCHAR(100);

-- Add province field to event_registrations table
ALTER TABLE event_registrations
ADD COLUMN province VARCHAR(100);

-- Add province field to sanctions table
ALTER TABLE sanctions
ADD COLUMN province VARCHAR(100);

-- Create index on users.province for faster lookups
CREATE INDEX idx_users_province ON users(province);

-- Create index on athlete_profiles.province for faster lookups
CREATE INDEX idx_athlete_profiles_province ON athlete_profiles(province);

-- Create index on matches.province for faster lookups
CREATE INDEX idx_matches_province ON matches(province);

-- Create index on tournament_matches.province for faster lookups
CREATE INDEX idx_tournament_matches_province ON tournament_matches(province);

-- Create index on events.province for faster lookups
CREATE INDEX idx_events_province ON events(province);

-- Create index on event_registrations.province for faster lookups
CREATE INDEX idx_event_registrations_province ON event_registrations(province);

-- Create index on sanctions.province for faster lookups
CREATE INDEX idx_sanctions_province ON sanctions(province);