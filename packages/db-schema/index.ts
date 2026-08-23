import { pgTable, text, timestamp, integer, boolean, uuid, jsonb, real, varchar, numeric, uniqueIndex } from "drizzle-orm/pg-core";

export const users = pgTable("users", {
  id: uuid("id").primaryKey().defaultRandom(),
  email: varchar("email", { length: 255 }).notNull().unique(),
  username: varchar("username", { length: 100 }).notNull().unique(),
  passwordHash: text("password_hash").notNull(),
  role: varchar("role", { length: 50 }).notNull().default("ATHLETE"),
  fullName: varchar("full_name", { length: 255 }).notNull(),
  isActive: boolean("is_active").notNull().default(true),
  mfaSecret: text("mfa_secret"),
  mfaEnabled: boolean("mfa_enabled").notNull().default(false),
  mfaRecoveryCodes: text("mfa_recovery_codes"),
  googleId: varchar("google_id", { length: 255 }),
  appleId: varchar("apple_id", { length: 255 }),
  regionalCoverage: varchar("regional_coverage", { length: 100 }),
  createdAt: timestamp("created_at").notNull().defaultNow(),
  updatedAt: timestamp("updated_at").notNull().defaultNow(),
});

export const userSessions = pgTable("user_sessions", {
  id: uuid("id").primaryKey().defaultRandom(),
  userId: uuid("user_id").references(() => users.id).notNull(),
  tokenFamily: uuid("token_family").notNull(),
  refreshTokenHash: text("refresh_token_hash").notNull(),
  isRevoked: boolean("is_revoked").notNull().default(false),
  expiresAt: timestamp("expires_at").notNull(),
  ipAddress: varchar("ip_address", { length: 45 }),
  userAgent: text("user_agent"),
  createdAt: timestamp("created_at").notNull().defaultNow(),
});

export const auditLogs = pgTable("audit_logs", {
  id: uuid("id").primaryKey().defaultRandom(),
  userId: uuid("user_id").references(() => users.id),
  action: varchar("action", { length: 255 }).notNull(),
  details: jsonb("details"),
  ipAddress: varchar("ip_address", { length: 45 }),
  userAgent: text("user_agent"),
  createdAt: timestamp("created_at").notNull().defaultNow(),
});

export const athleteProfiles = pgTable("athlete_profiles", {
  id: uuid("id").primaryKey().defaultRandom(),
  userId: uuid("user_id").references(() => users.id).notNull().unique(),
  displayName: varchar("display_name", { length: 255 }).notNull(),
  biography: text("biography"),
  province: varchar("province", { length: 100 }).notNull(),
  city: varchar("city", { length: 100 }).notNull(),
  clubId: uuid("club_id").references(() => athleteClubs.id),
  handedness: varchar("handedness", { length: 50 }).notNull(),
  dominantArm: varchar("dominant_arm", { length: 50 }).notNull(),
  dateOfBirth: timestamp("date_of_birth").notNull(),
  gender: varchar("gender", { length: 50 }).notNull(),
  weightClass: varchar("weight_class", { length: 50 }).notNull(),
  height: real("height"),
  weight: real("weight"),
  reach: real("reach"),
  profilePhoto: text("profile_photo"),
  leftArmElo: integer("left_arm_elo").notNull().default(1000),
  rightArmElo: integer("right_arm_elo").notNull().default(1000),
  leftArmConfidence: real("left_arm_confidence").notNull().default(1),
  rightArmConfidence: real("right_arm_confidence").notNull().default(1),
  profileVisibility: varchar("profile_visibility", { length: 20 }).notNull().default("PUBLIC"),
  isSearchable: boolean("is_searchable").notNull().default(true),
  isDeleted: boolean("is_deleted").notNull().default(false),
  createdAt: timestamp("created_at").notNull().defaultNow(),
  updatedAt: timestamp("updated_at").notNull().defaultNow(),
  deletedAt: timestamp("deleted_at"),
  stripeCustomerId: varchar("stripe_customer_id", { length: 255 }),
});

export const athleteClubs = pgTable("athlete_clubs", {
  id: uuid("id").primaryKey().defaultRandom(),
  name: varchar("name", { length: 255 }).notNull(),
  city: varchar("city", { length: 100 }).notNull(),
  province: varchar("province", { length: 100 }).notNull(),
  isDeleted: boolean("is_deleted").notNull().default(false),
  createdAt: timestamp("created_at").notNull().defaultNow(),
  updatedAt: timestamp("updated_at").notNull().defaultNow(),
});

export const athleteVerifications = pgTable("athlete_verifications", {
  id: uuid("id").primaryKey().defaultRandom(),
  athleteId: uuid("athlete_id").references(() => users.id).notNull(),
  status: varchar("status", { length: 50 }).notNull().default("UNVERIFIED"),
  reviewerId: uuid("reviewer_id").references(() => users.id),
  rejectionReason: text("rejection_reason"),
  createdAt: timestamp("created_at").notNull().defaultNow(),
  updatedAt: timestamp("updated_at").notNull().defaultNow(),
});

export const athleteDocuments = pgTable("athlete_documents", {
  id: uuid("id").primaryKey().defaultRandom(),
  athleteId: uuid("athlete_id").references(() => users.id).notNull(),
  documentType: varchar("document_type", { length: 100 }).notNull(),
  fileKey: varchar("file_key", { length: 512 }).notNull(),
  bucketName: varchar("bucket_name", { length: 100 }).notNull(),
  sha256Hash: varchar("sha256_hash", { length: 64 }).notNull(),
  isDeleted: boolean("is_deleted").notNull().default(false),
  createdAt: timestamp("created_at").notNull().defaultNow(),
  updatedAt: timestamp("updated_at").notNull().defaultNow(),
});

export const athleteBiometrics = pgTable("athlete_biometrics", {
  id: uuid("id").primaryKey().defaultRandom(),
  athleteId: uuid("athlete_id").references(() => users.id).notNull(),
  handLength: real("hand_length"),
  handWidth: real("hand_width"),
  palmLength: real("palm_length"),
  armSpan: real("arm_span"),
  forearmCircumference: real("forearm_circumference"),
  bicepCircumference: real("bicep_circumference"),
  createdAt: timestamp("created_at").notNull().defaultNow(),
  updatedAt: timestamp("updated_at").notNull().defaultNow(),
});

export const athleteMeasurements = pgTable("athlete_measurements", {
  id: uuid("id").primaryKey().defaultRandom(),
  athleteId: uuid("athlete_id").references(() => users.id).notNull(),
  height: real("height"),
  weight: real("weight"),
  reach: real("reach"),
  createdAt: timestamp("created_at").notNull().defaultNow(),
  updatedAt: timestamp("updated_at").notNull().defaultNow(),
});

export const athleteSocialLinks = pgTable("athlete_social_links", {
  id: uuid("id").primaryKey().defaultRandom(),
  athleteId: uuid("athlete_id").references(() => users.id).notNull(),
  instagram: varchar("instagram", { length: 255 }),
  youtube: varchar("youtube", { length: 255 }),
  facebook: varchar("facebook", { length: 255 }),
  createdAt: timestamp("created_at").notNull().defaultNow(),
  updatedAt: timestamp("updated_at").notNull().defaultNow(),
});

export const athleteProfileHistory = pgTable("athlete_profile_history", {
  id: uuid("id").primaryKey().defaultRandom(),
  athleteId: uuid("athlete_id").references(() => users.id).notNull(),
  changedBy: uuid("changed_by").references(() => users.id).notNull(),
  oldData: jsonb("old_data"),
  newData: jsonb("new_data"),
  createdAt: timestamp("created_at").notNull().defaultNow(),
});

export const authTokens = pgTable("auth_tokens", {
  id: uuid("id").primaryKey().defaultRandom(),
  userId: uuid("user_id").references(() => users.id).notNull(),
  tokenHash: text("token_hash").notNull(),
  tokenType: varchar("token_type", { length: 50 }).notNull(),
  expiresAt: timestamp("expires_at").notNull(),
  usedAt: timestamp("used_at"),
  createdAt: timestamp("created_at").notNull().defaultNow(),
});

export const auditEvents = pgTable("audit_events", {
  id: uuid("id").primaryKey().defaultRandom(),
  eventId: uuid("event_id").notNull(),
  parentHash: varchar("parent_hash", { length: 64 }).notNull(),
  eventHash: varchar("event_hash", { length: 64 }).notNull(),
  actorId: uuid("actor_id").references(() => users.id),
  entityType: varchar("entity_type", { length: 100 }).notNull(),
  entityId: uuid("entity_id").notNull(),
  action: varchar("action", { length: 255 }).notNull(),
  payload: jsonb("payload"),
  createdAt: timestamp("created_at").notNull().defaultNow(),
});

export const venuePartners = pgTable("venue_partners", {
  id: uuid("id").primaryKey().defaultRandom(),
  name: varchar("name", { length: 255 }).notNull(),
  city: varchar("city", { length: 100 }).notNull(),
  province: varchar("province", { length: 100 }).notNull(),
  address: text("address").notNull(),
  contactInfo: varchar("contact_info", { length: 255 }),
  description: text("description"),
  logoUrl: varchar("logo_url", { length: 1024 }),
  ownerUserId: uuid("owner_user_id").references(() => users.id),
  isVerified: boolean("is_verified").notNull().default(false),
  createdAt: timestamp("created_at").notNull().defaultNow(),
  updatedAt: timestamp("updated_at").notNull().defaultNow(),
});

export const rankingSnapshots = pgTable("ranking_snapshots", {
  id: uuid("id").primaryKey().defaultRandom(),
  athleteId: uuid("athlete_id").references(() => athleteProfiles.id).notNull(),
  snapshotType: varchar("snapshot_type", { length: 50 }).notNull(),
  arm: varchar("arm", { length: 5 }).notNull(),
  division: varchar("division", { length: 50 }).notNull(),
  weightClass: varchar("weight_class", { length: 50 }).notNull(),
  eloRating: integer("elo_rating").notNull(),
  rank: integer("rank").notNull(),
  previousRank: integer("previous_rank"),
  rankMovement: varchar("rank_movement", { length: 20 }).notNull().default("UNCHANGED"),
  snapshotDate: timestamp("snapshot_date").notNull(),
  createdAt: timestamp("created_at").notNull().defaultNow(),
});

export const payments = pgTable("payments", {
  id: uuid("id").primaryKey().defaultRandom(),
  eventRegistrationId: uuid("event_registration_id").references(() => eventRegistrations.id).notNull(),
  amountCents: integer("amount_cents").notNull(),
  currency: varchar("currency", { length: 10 }).notNull().default("CAD"),
  stripePaymentIntentId: varchar("stripe_payment_intent_id", { length: 255 }).notNull(),
  status: varchar("status", { length: 50 }).notNull().default("PENDING"),
  createdAt: timestamp("created_at").notNull().defaultNow(),
  updatedAt: timestamp("updated_at").notNull().defaultNow(),
});

export const eventRegistrations = pgTable("event_registrations", {
  id: uuid("id").primaryKey().defaultRandom(),
  eventId: uuid("event_id").references(() => events.id).notNull(),
  athleteId: uuid("athlete_id").references(() => athleteProfiles.id).notNull(),
  division: varchar("division", { length: 50 }).notNull(),
  weightClass: varchar("weight_class", { length: 50 }).notNull(),
  arm: varchar("arm", { length: 10 }).notNull(),
  status: varchar("status", { length: 50 }).notNull().default("PENDING"),
  notes: text("notes"),
  approvedBy: uuid("approved_by").references(() => users.id),
  paymentConfirmedByOrganizer: boolean("payment_confirmed_by_organizer").notNull().default(false),
  paymentConfirmedAt: timestamp("payment_confirmed_at"),
  createdAt: timestamp("created_at").notNull().defaultNow(),
  updatedAt: timestamp("updated_at").notNull().defaultNow(),
});

export const processedStripeEvents = pgTable("processed_stripe_events", {
  id: varchar("id", { length: 255 }).primaryKey(),
  createdAt: timestamp("created_at").notNull().defaultNow(),
});

export const ticketTypes = pgTable("ticket_types", {
  id: uuid("id").primaryKey().defaultRandom(),
  eventId: uuid("event_id").references(() => events.id).notNull(),
  name: varchar("name", { length: 255 }).notNull(),
  priceCents: integer("price_cents").notNull(),
  quantityAvailable: integer("quantity_available").notNull(),
  quantitySold: integer("quantity_sold").notNull().default(0),
  createdAt: timestamp("created_at").notNull().defaultNow(),
  updatedAt: timestamp("updated_at").notNull().defaultNow(),
});

export const tickets = pgTable("tickets", {
  id: uuid("id").primaryKey().defaultRandom(),
  ticketTypeId: uuid("ticket_type_id").references(() => ticketTypes.id).notNull(),
  purchaserUserId: uuid("purchaser_user_id").references(() => users.id).notNull(),
  stripePaymentIntentId: varchar("stripe_payment_intent_id", { length: 255 }),
  status: varchar("status", { length: 50 }).notNull().default("PENDING"),
  purchasedAt: timestamp("purchased_at").notNull().defaultNow(),
  confirmationCode: varchar("confirmation_code", { length: 255 }).notNull().unique(),
  createdAt: timestamp("created_at").notNull().defaultNow(),
  updatedAt: timestamp("updated_at").notNull().defaultNow(),
});

export const events = pgTable("events", {
  id: uuid("id").primaryKey().defaultRandom(),
  name: varchar("name", { length: 255 }).notNull(),
  startDate: timestamp("start_date").notNull(),
  endDate: timestamp("end_date").notNull(),
  registrationStart: timestamp("registration_start").notNull(),
  registrationEnd: timestamp("registration_end").notNull(),
  province: varchar("province", { length: 100 }).notNull(),
  city: varchar("city", { length: 100 }).notNull(),
  venue: varchar("venue", { length: 255 }).notNull(),
  capacity: integer("capacity").notNull(),
  registrationFeeCents: integer("registration_fee_cents"),
  status: varchar("status", { length: 50 }).notNull().default("DRAFT"),
  paymentQrImageUrl: varchar("payment_qr_image_url", { length: 1024 }),
  organizerId: uuid("organizer_id").references(() => users.id),
  paymentMethod: varchar("payment_method", { length: 50 }).notNull().default("STRIPE"),
  createdAt: timestamp("created_at").notNull().defaultNow(),
  updatedAt: timestamp("updated_at").notNull().defaultNow(),
});

export const announcements = pgTable("announcements", {
  id: uuid("id").primaryKey().defaultRandom(),
  title: varchar("title", { length: 255 }).notNull(),
  content: text("content").notNull(),
  scope: varchar("scope", { length: 50 }).notNull(),
  scopeId: varchar("scope_id", { length: 255 }),
  createdById: uuid("created_by_id").references(() => users.id).notNull(),
  isPinned: boolean("is_pinned").notNull().default(false),
  isArchived: boolean("is_archived").notNull().default(false),
  scheduledFor: timestamp("scheduled_for"),
  publishedAt: timestamp("published_at"),
  createdAt: timestamp("created_at").notNull().defaultNow(),
  updatedAt: timestamp("updated_at").notNull().defaultNow(),
});

export const matches = pgTable("matches", {
  id: uuid("id").primaryKey().defaultRandom(),
  challengerId: uuid("challenger_id").references(() => athleteProfiles.id).notNull(),
  opponentId: uuid("opponent_id").references(() => athleteProfiles.id).notNull(),
  arm: varchar("arm", { length: 5 }).notNull(),
  refereeId: uuid("referee_id").references(() => users.id).notNull(),
  winnerId: uuid("winner_id").references(() => athleteProfiles.id).notNull(),
  scoreLine: varchar("score_line", { length: 10 }).notNull(),
  status: varchar("status", { length: 50 }).notNull().default("DRAFT"),
  evidenceUrl: varchar("evidence_url", { length: 1024 }),
  idempotencyKey: varchar("idempotency_key", { length: 255 }).unique(),
  createdAt: timestamp("created_at").notNull().defaultNow(),
  updatedAt: timestamp("updated_at").notNull().defaultNow(),
  verifiedAt: timestamp("verified_at"),
});

export const disputes = pgTable("disputes", {
  id: uuid("id").primaryKey().defaultRandom(),
  matchId: uuid("match_id").references(() => tournamentMatches.id),
  creatorId: uuid("creator_id").references(() => users.id).notNull(),
  title: varchar("title", { length: 255 }).notNull(),
  description: text("description").notNull(),
  status: varchar("status", { length: 50 }).notNull().default("OPEN"),
  resolutionDetails: text("resolution_details"),
  assignedReviewerId: uuid("assigned_reviewer_id").references(() => users.id),
  createdAt: timestamp("created_at").notNull().defaultNow(),
  updatedAt: timestamp("updated_at").notNull().defaultNow(),
});

export const disputeEvidence = pgTable("dispute_evidence", {
  id: uuid("id").primaryKey().defaultRandom(),
  disputeId: uuid("dispute_id").references(() => disputes.id).notNull(),
  submitterId: uuid("submitter_id").references(() => users.id).notNull(),
  fileUrl: text("file_url").notNull(),
  fileType: varchar("file_type", { length: 50 }).notNull(),
  sha256Hash: varchar("sha256_hash", { length: 64 }).notNull(),
  virusScanned: boolean("virus_scanned").notNull().default(false),
  virusScanResult: varchar("virus_scan_result", { length: 50 }).notNull().default("PENDING"),
  createdAt: timestamp("created_at").notNull().defaultNow(),
});

export const disputeComments = pgTable("dispute_comments", {
  id: uuid("id").primaryKey().defaultRandom(),
  disputeId: uuid("dispute_id").references(() => disputes.id).notNull(),
  authorId: uuid("author_id").references(() => users.id).notNull(),
  comment: text("comment").notNull(),
  createdAt: timestamp("created_at").notNull().defaultNow(),
});

export const sanctions = pgTable("sanctions", {
  id: uuid("id").primaryKey().defaultRandom(),
  userId: uuid("user_id").references(() => users.id).notNull(),
  type: varchar("type", { length: 50 }).notNull(),
  reason: text("reason").notNull(),
  issuedById: uuid("issued_by_id").references(() => users.id).notNull(),
  startsAt: timestamp("starts_at").notNull(),
  endsAt: timestamp("ends_at"),
  status: varchar("status", { length: 50 }).notNull().default("ACTIVE"),
  createdAt: timestamp("created_at").notNull().defaultNow(),
  updatedAt: timestamp("updated_at").notNull().defaultNow(),
});

export const blockedUsers = pgTable("blocked_users", {
  id: uuid("id").primaryKey().defaultRandom(),
  blockerId: uuid("blocker_id").references(() => athleteProfiles.id).notNull(),
  blockedId: uuid("blocked_id").references(() => athleteProfiles.id).notNull(),
  createdAt: timestamp("created_at").notNull().defaultNow(),
});

export const eloLedger = pgTable("elo_ledger", {
  id: uuid("id").primaryKey().defaultRandom(),
  matchId: uuid("match_id").references(() => matches.id).notNull(),
  athleteId: uuid("athlete_id").references(() => athleteProfiles.id).notNull(),
  arm: varchar("arm", { length: 5 }).notNull(),
  previousElo: integer("previous_elo").notNull(),
  newElo: integer("new_elo").notNull(),
  eloDelta: integer("elo_delta").notNull(),
  createdAt: timestamp("created_at").notNull().defaultNow(),
}, (table) => {
  return {
    // verifyMatch() inserts exactly one row per (matchId, athleteId) —
    // never more, since a match has exactly two participants and is only
    // meant to be verified once. This is the database-level backstop: even
    // if two concurrent verification requests both pass the application's
    // status check before either commits, the second transaction's ELO
    // ledger insert hits this constraint and the whole transaction rolls
    // back — real ELO can't be double-applied. `arm` is not part of the key
    // because a single match has exactly one arm value; including it would
    // be redundant, not more correct.
    matchAthleteUnique: uniqueIndex("idx_elo_ledger_match_athlete").on(table.matchId, table.athleteId),
  };
});

export const brackets = pgTable("brackets", {
  id: uuid("id").primaryKey().defaultRandom(),
  eventId: uuid("event_id").references(() => events.id).notNull(),
  name: varchar("name", { length: 255 }).notNull(),
  format: varchar("format", { length: 50 }).notNull(),
  division: varchar("division", { length: 50 }).notNull(),
  weightClass: varchar("weight_class", { length: 50 }).notNull(),
  arm: varchar("arm", { length: 10 }).notNull(),
  status: varchar("status", { length: 50 }).notNull().default("DRAFT"),
  seedingLocked: boolean("seeding_locked").notNull().default(false),
  createdAt: timestamp("created_at").notNull().defaultNow(),
  updatedAt: timestamp("updated_at").notNull().defaultNow(),
});

export const bracketSeeds = pgTable("bracket_seeds", {
  id: uuid("id").primaryKey().defaultRandom(),
  bracketId: uuid("bracket_id").references(() => brackets.id).notNull(),
  athleteId: uuid("athlete_id").references(() => athleteProfiles.id).notNull(),
  seedPosition: integer("seed_position").notNull(),
  isManualOverride: boolean("is_manual_override").notNull().default(false),
  createdAt: timestamp("created_at").notNull().defaultNow(),
  updatedAt: timestamp("updated_at").notNull().defaultNow(),
});

export const matchTables = pgTable("match_tables", {
  id: uuid("id").primaryKey().defaultRandom(),
  name: varchar("name", { length: 100 }).notNull(),
  status: varchar("status", { length: 50 }).notNull().default("IDLE"),
  currentMatchId: uuid("current_match_id"),
  createdAt: timestamp("created_at").notNull().defaultNow(),
  updatedAt: timestamp("updated_at").notNull().defaultNow(),
});

export const tournamentMatches = pgTable("tournament_matches", {
  id: uuid("id").primaryKey().defaultRandom(),
  bracketId: uuid("bracket_id").references(() => brackets.id).notNull(),
  round: integer("round").notNull(),
  matchIndex: integer("match_index").notNull(),
  bracketType: varchar("bracket_type", { length: 50 }).notNull().default("PRIMARY"),
  athleteAId: uuid("athlete_a_id").references(() => athleteProfiles.id),
  athleteBId: uuid("athlete_b_id").references(() => athleteProfiles.id),
  winnerId: uuid("winner_id").references(() => athleteProfiles.id),
  scoreLine: varchar("score_line", { length: 50 }),
  status: varchar("status", { length: 50 }).notNull().default("PENDING"),
  tableId: uuid("table_id").references(() => matchTables.id),
  refereeId: uuid("referee_id").references(() => users.id),
  nextMatchId: uuid("next_match_id"),
  nextMatchPlayerPosition: varchar("next_match_player_position", { length: 1 }),
  losersNextMatchId: uuid("losers_next_match_id"),
  createdAt: timestamp("created_at").notNull().defaultNow(),
  updatedAt: timestamp("updated_at").notNull().defaultNow(),
});

export const officialWeighins = pgTable("official_weighins", {
  id: uuid("id").primaryKey().defaultRandom(),
  registrationId: uuid("registration_id").references(() => eventRegistrations.id).notNull(),
  attemptNumber: integer("attempt_number").notNull(),
  weight: real("weight").notNull(),
  status: varchar("status", { length: 50 }).notNull(),
  certifiedBy: uuid("certified_by").references(() => users.id).notNull(),
  isLocked: boolean("is_locked").notNull().default(false),
  reassignedDivision: varchar("reassigned_division", { length: 50 }),
  reassignedWeightClass: varchar("reassigned_weight_class", { length: 50 }),
  createdAt: timestamp("created_at").notNull().defaultNow(),
  updatedAt: timestamp("updated_at").notNull().defaultNow(),
});

export const pendingActions = pgTable("pending_actions", {
  id: uuid("id").primaryKey().defaultRandom(),
  userId: uuid("user_id").references(() => users.id).notNull(),
  idempotencyKey: varchar("idempotency_key", { length: 255 }).notNull().unique(),
  actionType: varchar("action_type", { length: 100 }).notNull(),
  payload: jsonb("payload").notNull(),
  status: varchar("status", { length: 50 }).notNull().default("PENDING"),
  errorReason: text("error_reason"),
  createdAt: timestamp("created_at").notNull().defaultNow(),
  updatedAt: timestamp("updated_at").notNull().defaultNow(),
});

export const syncTombstones = pgTable("sync_tombstones", {
  id: uuid("id").primaryKey().defaultRandom(),
  tableName: varchar("table_name", { length: 100 }).notNull(),
  recordId: uuid("record_id").notNull(),
  ownerUserId: uuid("owner_user_id").references(() => users.id),
  deletedAt: timestamp("deleted_at").notNull().defaultNow(),
});

export const scheduledJobs = pgTable("scheduled_jobs", {
  id: uuid("id").primaryKey().defaultRandom(),
  jobType: text("job_type").notNull(),
  payload: jsonb("payload"),
  status: text("status").notNull().default("pending"),
  scheduledFor: timestamp("scheduled_for").notNull(),
  lastRunAt: timestamp("last_run_at"),
  lastError: text("last_error"),
  createdAt: timestamp("created_at").notNull().defaultNow(),
  updatedAt: timestamp("updated_at").notNull().defaultNow(),
});

export const informalEvents = pgTable("informal_events", {
  id: uuid("id").primaryKey().defaultRandom(),
  createdByUserId: uuid("created_by_user_id").references(() => users.id).notNull(),
  title: varchar("title", { length: 255 }).notNull(),
  description: text("description").notNull(),
  city: varchar("city", { length: 100 }).notNull(),
  province: varchar("province", { length: 100 }),
  scheduledAt: timestamp("scheduled_at").notNull(),
  maxParticipants: integer("max_participants"),
  isPublic: boolean("is_public").notNull().default(true),
  createdAt: timestamp("created_at").notNull().defaultNow(),
  updatedAt: timestamp("updated_at").notNull().defaultNow(),
});

export const informalEventParticipants = pgTable("informal_event_participants", {
  id: uuid("id").primaryKey().defaultRandom(),
  informalEventId: uuid("informal_event_id").references(() => informalEvents.id).notNull(),
  userId: uuid("user_id").references(() => users.id).notNull(),
  joinedAt: timestamp("joined_at").notNull().defaultNow(),
});

export const userDevices = pgTable("user_devices", {
  id: uuid("id").primaryKey().defaultRandom(),
  userId: uuid("user_id").references(() => users.id).notNull(),
  deviceId: varchar("device_id", { length: 255 }).notNull().unique(),
  platform: varchar("platform", { length: 50 }).notNull(),
  fcmToken: varchar("fcm_token", { length: 512 }),
  apnsToken: varchar("apns_token", { length: 512 }),
  appVersion: varchar("app_version", { length: 50 }),
  locale: varchar("locale", { length: 50 }),
  timezone: varchar("timezone", { length: 100 }),
  pushEnabled: boolean("push_enabled").notNull().default(true),
  lastActiveAt: timestamp("last_active_at").notNull().defaultNow(),
  createdAt: timestamp("created_at").notNull().defaultNow(),
  updatedAt: timestamp("updated_at").notNull().defaultNow(),
});

export const userDeviceTokens = pgTable("user_device_tokens", {
  id: uuid("id").primaryKey().defaultRandom(),
  userId: uuid("user_id").references(() => users.id).notNull(),
  token: varchar("token", { length: 255 }).notNull(),
  deviceType: varchar("device_type", { length: 50 }).notNull(),
  lastUsedAt: timestamp("last_used_at").notNull().defaultNow(),
  createdAt: timestamp("created_at").notNull().defaultNow(),
});

export const notifications = pgTable("notifications", {
  id: uuid("id").primaryKey().defaultRandom(),
  userId: uuid("user_id").references(() => users.id).notNull(),
  title: varchar("title", { length: 255 }).notNull(),
  content: text("content").notNull(),
  priority: varchar("priority", { length: 20 }).notNull().default("LOW"),
  category: varchar("category", { length: 50 }).notNull(),
  status: varchar("status", { length: 20 }).notNull().default("UNREAD"),
  groupId: varchar("group_id", { length: 100 }),
  expiresAt: timestamp("expires_at"),
  metadata: jsonb("metadata"),
  deliveryReceipts: jsonb("delivery_receipts"),
  retryCount: integer("retry_count").notNull().default(0),
  maxRetries: integer("max_retries").notNull().default(3),
  lastAttemptAt: timestamp("last_attempt_at"),
  createdAt: timestamp("created_at").notNull().defaultNow(),
  updatedAt: timestamp("updated_at").notNull().defaultNow(),
});

export const refereeCertifications = pgTable("referee_certifications", {
  id: uuid("id").primaryKey().defaultRandom(),
  userId: uuid("user_id").references(() => users.id).notNull(),
  certificationLevel: varchar("certification_level", { length: 100 }).notNull(),
  issuedAt: timestamp("issued_at").notNull(),
  expiresAt: timestamp("expires_at"),
  issuingBody: varchar("issuing_body", { length: 255 }).notNull(),
  status: varchar("status", { length: 50 }).notNull().default("ACTIVE"),
  createdAt: timestamp("created_at").notNull().defaultNow(),
  updatedAt: timestamp("updated_at").notNull().defaultNow(),
});

export const talentNominations = pgTable("talent_nominations", {
  id: uuid("id").primaryKey().defaultRandom(),
  nominatedByUserId: uuid("nominated_by_user_id").references(() => users.id).notNull(),
  nomineeName: varchar("nominee_name", { length: 255 }).notNull(),
  nomineeContact: varchar("nominee_contact", { length: 255 }),
  city: varchar("city", { length: 100 }).notNull(),
  province: varchar("province", { length: 100 }).notNull(),
  notes: text("notes"),
  status: varchar("status", { length: 50 }).notNull().default("PENDING"),
  createdAt: timestamp("created_at").notNull().defaultNow(),
});

export const teamMembers = pgTable("team_members", {
  id: uuid("id").primaryKey().defaultRandom(),
  teamId: uuid("team_id").references(() => teams.id).notNull(),
  athleteId: uuid("athlete_id").references(() => athleteProfiles.id).notNull(),
  role: varchar("role", { length: 50 }).notNull().default("MEMBER"),
  joinedAt: timestamp("joined_at").notNull().defaultNow(),
}, (table) => {
  return {
    // The real database has enforced this since migration 0000
    // (idx_team_members_team_athlete) — the Drizzle schema just never
    // declared it, so drizzle-kit had no way to know about it. Declaring it
    // now reconciles the two; drizzle-kit generate below should therefore
    // detect NO diff for this table (it already exists in the DB).
    teamAthleteUnique: uniqueIndex("idx_team_members_team_athlete").on(table.teamId, table.athleteId),
  };
});

export const teams = pgTable("teams", {
  id: uuid("id").primaryKey().defaultRandom(),
  name: varchar("name", { length: 255 }).notNull(),
  description: text("description"),
  foundedAt: timestamp("founded_at"),
  clubId: uuid("club_id").references(() => athleteClubs.id),
  createdAt: timestamp("created_at").notNull().defaultNow(),
  updatedAt: timestamp("updated_at").notNull().defaultNow(),
});

export const communityPosts = pgTable("community_posts", {
  id: uuid("id").primaryKey().defaultRandom(),
  athleteId: uuid("athlete_id").references(() => athleteProfiles.id).notNull(),
  externalUrl: varchar("external_url", { length: 1024 }).notNull(),
  platform: varchar("platform", { length: 50 }).notNull(),
  category: varchar("category", { length: 50 }),
  exerciseType: varchar("exercise_type", { length: 50 }),
  weightKg: numeric("weight_kg", { precision: 10, scale: 2 }),
  reps: integer("reps"),
  caption: text("caption"),
  matchId: uuid("match_id").references(() => matches.id),
  moderationStatus: varchar("moderation_status", { length: 50 }).notNull().default("PENDING"),
  moderatedBy: uuid("moderated_by").references(() => users.id),
  moderatedAt: timestamp("moderated_at"),
  isDeleted: boolean("is_deleted").notNull().default(false),
  createdAt: timestamp("created_at").notNull().defaultNow(),
  updatedAt: timestamp("updated_at").notNull().defaultNow(),
});

export const postComments = pgTable("post_comments", {
  id: uuid("id").primaryKey().defaultRandom(),
  postId: uuid("post_id").references(() => communityPosts.id).notNull(),
  athleteId: uuid("athlete_id").references(() => athleteProfiles.id).notNull(),
  body: text("body").notNull(),
  isDeleted: boolean("is_deleted").notNull().default(false),
  createdAt: timestamp("created_at").notNull().defaultNow(),
});

export const postLikes = pgTable("post_likes", {
  id: uuid("id").primaryKey().defaultRandom(),
  postId: uuid("post_id").references(() => communityPosts.id).notNull(),
  athleteId: uuid("athlete_id").references(() => athleteProfiles.id).notNull(),
  createdAt: timestamp("created_at").notNull().defaultNow(),
});

export const championshipTitles = pgTable("championship_titles", {
  id: uuid("id").primaryKey().defaultRandom(),
  name: varchar("name", { length: 255 }).notNull(),
  arm: varchar("arm", { length: 5 }).notNull(),
  division: varchar("division", { length: 50 }).notNull(),
  weightClass: varchar("weight_class", { length: 50 }).notNull(),
  activeChampionId: uuid("active_champion_id").references(() => athleteProfiles.id),
  createdAt: timestamp("created_at").notNull().defaultNow(),
  updatedAt: timestamp("updated_at").notNull().defaultNow(),
});

export const beltLineage = pgTable("belt_lineage", {
  id: uuid("id").primaryKey().defaultRandom(),
  titleId: uuid("title_id").references(() => championshipTitles.id).notNull(),
  athleteId: uuid("athlete_id").references(() => athleteProfiles.id).notNull(),
  acquiredAt: timestamp("acquired_at").notNull(),
  vacatedAt: timestamp("vacated_at"),
  reason: varchar("reason", { length: 255 }).notNull(),
  defensesCount: integer("defenses_count").notNull().default(0),
  createdAt: timestamp("created_at").notNull().defaultNow(),
  updatedAt: timestamp("updated_at").notNull().defaultNow(),
});

export const championshipChallenges = pgTable("championship_challenges", {
  id: uuid("id").primaryKey().defaultRandom(),
  titleId: uuid("title_id").references(() => championshipTitles.id).notNull(),
  challengerId: uuid("challenger_id").references(() => athleteProfiles.id).notNull(),
  status: varchar("status", { length: 50 }).notNull().default("PENDING"),
  createdAt: timestamp("created_at").notNull().defaultNow(),
  updatedAt: timestamp("updated_at").notNull().defaultNow(),
});

export const prestigeMetrics = pgTable("prestige_metrics", {
  id: uuid("id").primaryKey().defaultRandom(),
  athleteId: uuid("athlete_id").references(() => athleteProfiles.id).notNull().unique(),
  prestigeScore: real("prestige_score").notNull().default(0),
  pfpRank: integer("pfp_rank").notNull().default(0),
  dominanceMetric: real("dominance_metric").notNull().default(0),
  createdAt: timestamp("created_at").notNull().defaultNow(),
  updatedAt: timestamp("updated_at").notNull().defaultNow(),
});

export const conversations = pgTable("conversations", {
  id: uuid("id").primaryKey().defaultRandom(),
  type: varchar("type", { length: 50 }).notNull().default("DIRECT"),
  metadata: jsonb("metadata"),
  createdAt: timestamp("created_at").notNull().defaultNow(),
  updatedAt: timestamp("updated_at").notNull().defaultNow(),
});

export const conversationParticipants = pgTable("conversation_participants", {
  id: uuid("id").primaryKey().defaultRandom(),
  conversationId: uuid("conversation_id").references(() => conversations.id).notNull(),
  userId: uuid("user_id").references(() => users.id).notNull(),
  joinedAt: timestamp("joined_at").notNull().defaultNow(),
  lastReadAt: timestamp("last_read_at"),
});

export const messages = pgTable("messages", {
  id: uuid("id").primaryKey().defaultRandom(),
  conversationId: uuid("conversation_id").references(() => conversations.id).notNull(),
  senderId: uuid("sender_id").references(() => users.id).notNull(),
  content: text("content").notNull(),
  attachments: jsonb("attachments"),
  isEdited: boolean("is_edited").notNull().default(false),
  isDeleted: boolean("is_deleted").notNull().default(false),
  sequence: integer("sequence").notNull().default(1),
  createdAt: timestamp("created_at").notNull().defaultNow(),
  updatedAt: timestamp("updated_at").notNull().defaultNow(),
});

export const userCommunicationPreferences = pgTable("user_communication_preferences", {
  id: uuid("id").primaryKey().defaultRandom(),
  userId: uuid("user_id").references(() => users.id).notNull().unique(),
  pushEnabled: boolean("push_enabled").notNull().default(true),
  emailEnabled: boolean("email_enabled").notNull().default(true),
  smsEnabled: boolean("sms_enabled").notNull().default(true),
  quietHoursEnabled: boolean("quiet_hours_enabled").notNull().default(false),
  quietHoursStart: varchar("quiet_hours_start", { length: 5 }),
  quietHoursEnd: varchar("quiet_hours_end", { length: 5 }),
  quietHoursTimezone: varchar("quiet_hours_timezone", { length: 50 }),
  categoriesConfig: jsonb("categories_config"),
  createdAt: timestamp("created_at").notNull().defaultNow(),
  updatedAt: timestamp("updated_at").notNull().defaultNow(),
});

export const follows = pgTable("follows", {
  id: uuid("id").primaryKey().defaultRandom(),
  followerId: uuid("follower_id").references(() => athleteProfiles.id).notNull(),
  followingId: uuid("following_id").references(() => athleteProfiles.id).notNull(),
  createdAt: timestamp("created_at").notNull().defaultNow(),
});
