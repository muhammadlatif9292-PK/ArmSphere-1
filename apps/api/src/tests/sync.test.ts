import { describe, it, expect, beforeEach, vi } from "vitest";
import request from "supertest";
import { testDbStore } from "./setup.js";
import { app } from "../app.js";
import { SyncService } from "../services/sync.js";
import { UserRole, SyncStatus } from "@armsphere/types";
import { generateAccessToken } from "@armsphere/cryptography";
import env from "../config/env.js";
import { processedJobsTracker, resetJobTrackers } from "../services/scheduledJobs.js";

describe("ArmSphere Offline Synchronization & Queue Observability Tests", () => {
  let athleteToken: string;
  const userId = "athlete-sync-user";

  beforeEach(() => {
    // 1. Clean DB state
    testDbStore.users = [];
    testDbStore.pendingActions = [];
    testDbStore.auditLogs = [];
    testDbStore.athleteProfiles = [];
    testDbStore.matches = [];
    testDbStore.syncTombstones = [];
    resetJobTrackers();

    // 2. Seed an Athlete User
    testDbStore.users.push({
      id: userId,
      email: "athlete@armsphere.com",
      username: "athlete1",
      passwordHash: "hash",
      role: UserRole.ATHLETE,
      fullName: "Syncer Athlete",
      isActive: true,
      updatedAt: new Date(Date.now() - 1000 * 60), // Updated 1 minute ago
    });

    // 3. Generate token
    athleteToken = generateAccessToken(userId, "athlete@armsphere.com", UserRole.ATHLETE, env.JWT_ACCESS_SECRET);
  });

  // ==========================================
  // 1. OFFLINE SYNC REGISTRATION & REPLAY DEDUPLICATION
  // ==========================================
  describe("POST /sync/queue (Queue Action)", () => {
    it("should successfully register and queue a pending offline action", async () => {
      const payload = { matchId: "match-abc-123", refereeId: "ref-456" };
      const response = await request(app)
        .post("/sync/queue")
        .set("Authorization", `Bearer ${athleteToken}`)
        .send({
          idempotencyKey: "unique-idempotency-key-1",
          actionType: "SUBMIT_MATCH",
          payload,
        });

      expect(response.status).toBe(202);
      expect(response.body.success).toBe(true);
      expect(response.body.data.idempotencyKey).toBe("unique-idempotency-key-1");
      expect(response.body.data.status).toBe(SyncStatus.PENDING);

      // Verify DB persistence
      expect(testDbStore.pendingActions).toHaveLength(1);
      expect(testDbStore.pendingActions[0].idempotencyKey).toBe("unique-idempotency-key-1");

      // Verify audit logs
      const audit = testDbStore.auditLogs.filter((l) => l.action === "OFFLINE_SYNC_QUEUE");
      expect(audit).toHaveLength(1);
    });

    it("should return the original record (idempotency safety) when the same idempotency key is submitted again", async () => {
      // Pre-seed an already registered completed action
      testDbStore.pendingActions.push({
        id: "preseeded-id",
        userId,
        idempotencyKey: "dup-key-123",
        actionType: "SUBMIT_MATCH",
        payload: { test: "data" },
        status: SyncStatus.COMPLETED,
        createdAt: new Date(),
        updatedAt: new Date(),
      });

      const response = await request(app)
        .post("/sync/queue")
        .set("Authorization", `Bearer ${athleteToken}`)
        .send({
          idempotencyKey: "dup-key-123",
          actionType: "SUBMIT_MATCH",
          payload: { different: "payload" }, // Should be ignored
        });

      expect(response.status).toBe(202);
      expect(response.body.data.id).toBe("preseeded-id");
      expect(response.body.data.status).toBe(SyncStatus.COMPLETED);

      // Verify that no second record was created
      expect(testDbStore.pendingActions).toHaveLength(1);
    });

    it("should fail validation if idempotencyKey or actionType are missing", async () => {
      const response = await request(app)
        .post("/sync/queue")
        .set("Authorization", `Bearer ${athleteToken}`)
        .send({
          payload: { some: "data" },
        });

      expect(response.status).toBe(400);
      expect(response.body.title).toBe("Validation Failed");
    });
  });

  // ==========================================
  // 2. SYNCHRONIZATION HISTORY RETRIEVAL
  // ==========================================
  describe("GET /sync/history", () => {
    it("should return a clean chronological array of synchronization actions", async () => {
      // Pre-seed a few actions
      testDbStore.pendingActions.push({
        id: "a1",
        userId,
        idempotencyKey: "key-1",
        actionType: "UPDATE_PROFILE",
        payload: {},
        status: SyncStatus.COMPLETED,
        createdAt: new Date(Date.now() - 5000),
      });

      testDbStore.pendingActions.push({
        id: "a2",
        userId,
        idempotencyKey: "key-2",
        actionType: "SUBMIT_MATCH",
        payload: {},
        status: SyncStatus.PENDING,
        createdAt: new Date(),
      });

      const response = await request(app)
        .get("/sync/history")
        .set("Authorization", `Bearer ${athleteToken}`);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveLength(2);
      expect(response.body.data[0].id).toBe("a1");
      expect(response.body.data[1].id).toBe("a2");
    });
  });

  // ==========================================
  // 3. CONFLICT DETECTION & MERGE POLICIES
  // ==========================================
  describe("SyncService Business Logic & Conflict Detection", () => {
    it("should correctly update profile if there are no conflicts", async () => {
      const clientEditDate = new Date(); // Client modification date is newer than userRecord.updatedAt

      const actionRecord = {
        id: "sync-profile-id",
        userId,
        actionType: "UPDATE_PROFILE",
        payload: {
          fullName: "Fully Synced Champion",
          clientLastUpdated: clientEditDate.toISOString(),
        },
        status: SyncStatus.PENDING,
      };

      testDbStore.pendingActions.push(actionRecord);

      const result = await SyncService.processActionById("sync-profile-id");

      expect(result.status).toBe("PROFILE_SYNCED");
      expect(result.fullName).toBe("Fully Synced Champion");

      // Verify in DB store
      const updatedUser = testDbStore.users.find((u) => u.id === userId);
      expect(updatedUser.fullName).toBe("Fully Synced Champion");

      const completedAction = testDbStore.pendingActions.find((p) => p.id === "sync-profile-id");
      expect(completedAction.status).toBe(SyncStatus.COMPLETED);
    });

    it("should reject offline profile updates with ConflictError if the server holds a newer update", async () => {
      // Server record holds newer timestamp (updatedAt set to now)
      const serverUpdatedNow = new Date();
      testDbStore.users[0].updatedAt = serverUpdatedNow;

      // Client modified it 5 minutes earlier
      const clientOlderEditDate = new Date(Date.now() - 1000 * 60 * 5);

      const actionRecord = {
        id: "conflict-profile-id",
        userId,
        actionType: "UPDATE_PROFILE",
        payload: {
          fullName: "Conflicting Outdated Athlete",
          clientLastUpdated: clientOlderEditDate.toISOString(),
        },
        status: SyncStatus.PENDING,
      };

      testDbStore.pendingActions.push(actionRecord);

      await expect(SyncService.processActionById("conflict-profile-id")).rejects.toThrow(
        "Conflict detected: The server contains a newer profile"
      );

      // Verify sync state is set to FAILED in database
      const completedAction = testDbStore.pendingActions.find((p) => p.id === "conflict-profile-id");
      expect(completedAction.status).toBe(SyncStatus.FAILED);
      expect(completedAction.errorReason).toContain("Conflict detected");
    });

    it("should fail validation gracefully for completely unsupported action types", async () => {
      const actionRecord = {
        id: "bad-action-id",
        userId,
        actionType: "DESTROY_THE_MATRIX",
        payload: {},
        status: SyncStatus.PENDING,
      };

      testDbStore.pendingActions.push(actionRecord);

      await expect(SyncService.processActionById("bad-action-id")).rejects.toThrow(
        "Unsupported offline sync action type"
      );
    });
  });

  // ==========================================
  // 4. ACTION PROCESSING & METRICS
  // ==========================================
  describe("Action Processing & Observability", () => {
    it("should process pending action and record completed status", async () => {
      const actionRecord = {
        id: "test-action-1",
        userId,
        actionType: "SUBMIT_MATCH",
        payload: { matchId: "123" },
        status: SyncStatus.PENDING,
      };

      testDbStore.pendingActions.push(actionRecord);

      await SyncService.processActionById("test-action-1");

      const updated = testDbStore.pendingActions.find(a => a.id === "test-action-1");
      expect(updated.status).toBe(SyncStatus.COMPLETED);
    });

    it("should fetch queue metrics from observability endpoint", async () => {
      const response = await request(app)
        .get("/sync/metrics")
        .set("Authorization", `Bearer ${athleteToken}`);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data).toBeDefined();
    });
  });

  // ==========================================
  // 5. DIFFERENTIAL PULL SYNC — GET /sync
  // ==========================================
  describe("GET /sync?since= (Differential Pull Sync)", () => {
    it("should return a full snapshot (profile + matches) when no 'since' cursor is provided", async () => {
      testDbStore.athleteProfiles.push({
        id: "profile-sync-1",
        userId,
        displayName: "Syncer Athlete",
        province: "Punjab",
        city: "Lahore",
        isDeleted: false,
        profilePhoto: "avatars/sync-user.jpg",
        updatedAt: new Date(Date.now() - 1000 * 60 * 60 * 24),
      });
      testDbStore.matches.push({
        id: "match-1",
        challengerId: "profile-sync-1",
        opponentId: "profile-other",
        arm: "RIGHT",
        status: "VERIFIED",
        scoreLine: "3-1",
        createdAt: new Date(Date.now() - 1000 * 60 * 60 * 24),
        updatedAt: new Date(Date.now() - 1000 * 60 * 60 * 24),
      });

      const res = await request(app).get("/sync").set("Authorization", `Bearer ${athleteToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.profile.id).toBe("profile-sync-1");
      // Private-bucket avatar key must come back as a presigned URL, never the raw key
      expect(res.body.data.profile.profilePhoto).toBe(
        `http://localhost:9000/mock-download-url/${env.B2_BUCKET_ATHLETE_AVATARS}/avatars/sync-user.jpg`
      );
      expect(res.body.data.matches).toHaveLength(1);
      expect(res.body.data.matches[0].id).toBe("match-1");
      expect(res.body.data.serverTime).toBeDefined();
    });

    it("should only return matches whose status changed after the given 'since' cursor", async () => {
      const since = new Date(Date.now() - 1000 * 60 * 10).toISOString(); // 10 min ago

      testDbStore.athleteProfiles.push({
        id: "profile-sync-2",
        userId,
        displayName: "Syncer Athlete",
        province: "Punjab",
        city: "Lahore",
        isDeleted: false,
        updatedAt: new Date(Date.now() - 1000 * 60 * 60), // 1hr ago — unchanged since cursor
      });

      // Stale match: last updated before the cursor — should NOT be returned
      testDbStore.matches.push({
        id: "match-stale",
        challengerId: "profile-sync-2",
        opponentId: "profile-other",
        arm: "LEFT",
        status: "VERIFIED",
        scoreLine: "3-0",
        createdAt: new Date(Date.now() - 1000 * 60 * 60),
        updatedAt: new Date(Date.now() - 1000 * 60 * 60), // 1hr ago
      });

      // Fresh match: just transitioned to VERIFIED after the cursor — SHOULD be returned
      testDbStore.matches.push({
        id: "match-fresh",
        challengerId: "profile-other-2",
        opponentId: "profile-sync-2",
        arm: "RIGHT",
        status: "VERIFIED",
        scoreLine: "3-2",
        createdAt: new Date(Date.now() - 1000 * 60 * 60),
        updatedAt: new Date(), // just now
      });

      const res = await request(app)
        .get("/sync")
        .query({ since })
        .set("Authorization", `Bearer ${athleteToken}`);

      expect(res.status).toBe(200);
      // Profile itself didn't change since cursor -> null, not the stale row
      expect(res.body.data.profile).toBeNull();
      expect(res.body.data.matches).toHaveLength(1);
      expect(res.body.data.matches[0].id).toBe("match-fresh");
    });

    it("should include tombstones for hard-deleted records owned by this user, scoped to since", async () => {
      const since = new Date(Date.now() - 1000 * 60 * 5).toISOString();

      testDbStore.syncTombstones.push({
        id: "tomb-old",
        tableName: "some_table",
        recordId: "rec-old",
        ownerUserId: userId,
        deletedAt: new Date(Date.now() - 1000 * 60 * 60), // before cursor, excluded
      });
      testDbStore.syncTombstones.push({
        id: "tomb-new",
        tableName: "some_table",
        recordId: "rec-new",
        ownerUserId: userId,
        deletedAt: new Date(), // after cursor, included
      });
      testDbStore.syncTombstones.push({
        id: "tomb-other-user",
        tableName: "some_table",
        recordId: "rec-not-mine",
        ownerUserId: "someone-else",
        deletedAt: new Date(), // after cursor but not owned by this user, excluded
      });

      const res = await request(app)
        .get("/sync")
        .query({ since })
        .set("Authorization", `Bearer ${athleteToken}`);

      expect(res.status).toBe(200);
      expect(res.body.data.deletions).toHaveLength(1);
      expect(res.body.data.deletions[0].recordId).toBe("rec-new");
    });

    it("should reject a malformed 'since' cursor with a 400", async () => {
      const res = await request(app)
        .get("/sync")
        .query({ since: "not-a-real-date" })
        .set("Authorization", `Bearer ${athleteToken}`);

      expect(res.status).toBe(400);
    });

    it("should return an empty (not error) delta for a user with no athlete profile at all", async () => {
      const res = await request(app).get("/sync").set("Authorization", `Bearer ${athleteToken}`);

      expect(res.status).toBe(200);
      expect(res.body.data.profile).toBeNull();
      expect(res.body.data.matches).toEqual([]);
    });

    it("should require authentication", async () => {
      const res = await request(app).get("/sync");
      expect(res.status).toBe(401);
    });
  });
});
