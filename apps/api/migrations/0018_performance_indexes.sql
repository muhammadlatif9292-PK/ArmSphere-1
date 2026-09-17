-- Database Performance & Composite Index Migration
-- Optimizes high-frequency match, tournament, event, registration, and governance queries

-- 1. Matches: Opponent and Challenger status & arm lookups for match history and ELO verification
CREATE INDEX IF NOT EXISTS "idx_matches_opponent_status" ON "matches" ("opponent_id", "status");
--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "idx_matches_challenger_status" ON "matches" ("challenger_id", "status");
--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "idx_matches_status_verified" ON "matches" ("status", "verified_at" DESC);
--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "idx_matches_referee" ON "matches" ("referee_id");
--> statement-breakpoint

-- 2. Tournament Matches: High-frequency bracket, table, referee, and competitor lookups
CREATE INDEX IF NOT EXISTS "idx_tournament_matches_bracket" ON "tournament_matches" ("bracket_id");
--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "idx_tournament_matches_bracket_status" ON "tournament_matches" ("bracket_id", "status");
--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "idx_tournament_matches_table" ON "tournament_matches" ("table_id");
--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "idx_tournament_matches_referee" ON "tournament_matches" ("referee_id");
--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "idx_tournament_matches_athletes" ON "tournament_matches" ("athlete_a_id", "athlete_b_id");
--> statement-breakpoint

-- 3. Events: Status, chronological ordering, and regional discovery lookups
CREATE INDEX IF NOT EXISTS "idx_events_status_start_date" ON "events" ("status", "start_date" DESC);
--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "idx_events_province" ON "events" ("province");
--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "idx_events_organizer" ON "events" ("organizer_id");
--> statement-breakpoint

-- 4. Event Registrations: Athlete lookup, status filtering, and bracket seeding query
CREATE INDEX IF NOT EXISTS "idx_event_registrations_athlete" ON "event_registrations" ("athlete_id");
--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "idx_event_registrations_status" ON "event_registrations" ("status");
--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "idx_event_registrations_seeding" ON "event_registrations" ("event_id", "division", "weight_class", "arm", "status");
--> statement-breakpoint

-- 5. Brackets & Weigh-ins: Event association and registration lookups
CREATE INDEX IF NOT EXISTS "idx_brackets_event" ON "brackets" ("event_id");
--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "idx_official_weighins_registration" ON "official_weighins" ("registration_id");
--> statement-breakpoint

-- 6. Athlete Profiles: High-performance leaderboard ranking index
CREATE INDEX IF NOT EXISTS "idx_athlete_profiles_leaderboard_left" ON "athlete_profiles" ("is_deleted", "left_arm_elo" DESC);
--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "idx_athlete_profiles_leaderboard_right" ON "athlete_profiles" ("is_deleted", "right_arm_elo" DESC);
--> statement-breakpoint

-- 7. Disputes & Sanctions: Creator queries and governance status filtering
CREATE INDEX IF NOT EXISTS "idx_disputes_creator" ON "disputes" ("creator_id", "created_at" DESC);
--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "idx_disputes_status" ON "disputes" ("status");
--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "idx_users_role" ON "users" ("role");
--> statement-breakpoint
