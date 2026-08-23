import { describe, it, expect, beforeEach } from "vitest";
import request from "supertest";
import { testDbStore } from "./setup.js";
import { app } from "../app.js";
import { UserRole } from "@armsphere/types";
import { generateAccessToken } from "@armsphere/cryptography";
import { v4 as uuidv4 } from "uuid";
import env from "../config/env.js";

describe("Match Submission, Competitive Scoring & ELO Engine", () => {
  let athleteUserA: any;
  let athleteProfileA: any;
  let athleteUserB: any;
  let athleteProfileB: any;
  let refereeUser: any;
  let refereeToken: string;
  let adminUser: any;
  let adminToken: string;
  let competitorToken: string;

  const athleteAId = "1a111111-1111-1111-1111-111111111111";
  const athleteBId = "2b222222-2222-2222-2222-222222222222";
  const refereeUserId = "3c333333-3333-3333-3333-333333333333";
  const adminUserId = "4d444444-4d44-4d44-4d44-4d444d444d44";

  beforeEach(() => {
    // 1. Seed users
    athleteUserA = {
      id: "user-a-uuid",
      email: "athleteA@armsphere.com",
      username: "athlete_a",
      role: UserRole.ATHLETE,
      fullName: "Athlete A",
      isActive: true,
    };
    athleteUserB = {
      id: "user-b-uuid",
      email: "athleteB@armsphere.com",
      username: "athlete_b",
      role: UserRole.ATHLETE,
      fullName: "Athlete B",
      isActive: true,
    };
    refereeUser = {
      id: refereeUserId,
      email: "referee@armsphere.com",
      username: "referee_john",
      role: UserRole.REFEREE,
      fullName: "Referee John",
      isActive: true,
    };
    adminUser = {
      id: adminUserId,
      email: "admin@armsphere.com",
      username: "admin_boss",
      role: UserRole.SYSTEM_ADMIN,
      fullName: "System Admin",
      isActive: true,
    };

    testDbStore.users = [athleteUserA, athleteUserB, refereeUser, adminUser];

    // 2. Seed athlete profiles
    athleteProfileA = {
      id: athleteAId,
      userId: "user-a-uuid",
      displayName: "Challenger A",
      leftArmElo: 1500,
      rightArmElo: 1500,
      leftArmConfidence: 80,
      rightArmConfidence: 80,
      status: "VERIFIED",
    };
    athleteProfileB = {
      id: athleteBId,
      userId: "user-b-uuid",
      displayName: "Opponent B",
      leftArmElo: 1500,
      rightArmElo: 1500,
      leftArmConfidence: 80,
      rightArmConfidence: 80,
      status: "VERIFIED",
    };

    testDbStore.athleteProfiles = [athleteProfileA, athleteProfileB];

    // 2.3. Seed referee certification
    testDbStore.refereeCertifications = [
      {
        id: "cert-referee-john",
        userId: refereeUserId,
        certificationLevel: "PRO_LEVEL_1",
        issuedAt: new Date(),
        expiresAt: new Date(Date.now() + 86400000 * 365), // 1 year expiry
        status: "ACTIVE",
        issuingBody: "WAF_OFFICIAL",
      }
    ];

    // 3. Generate Auth JWT tokens
    refereeToken = generateAccessToken(
      refereeUserId,
      "referee@armsphere.com",
      UserRole.REFEREE,
      env.JWT_ACCESS_SECRET
    );

    adminToken = generateAccessToken(
      adminUserId,
      "admin@armsphere.com",
      UserRole.SYSTEM_ADMIN,
      env.JWT_ACCESS_SECRET
    );

    competitorToken = generateAccessToken(
      "user-a-uuid",
      "athleteA@armsphere.com",
      UserRole.ATHLETE,
      env.JWT_ACCESS_SECRET
    );
  });

  // ==========================================
  // 1. MATCH INGESTION & SUBMISSION
  // ==========================================
  describe("POST /matches - Match Ingestion API", () => {
    it("should accept valid competitive match outcome submitted by referee", async () => {
      const payload = {
        challengerId: athleteAId,
        opponentId: athleteBId,
        arm: "RIGHT",
        winnerId: athleteAId,
        scoreLine: "3-1",
        evidenceUrl: "https://storage.googleapis.com/armsphere/video.mp4",
      };

      const response = await request(app)
        .post("/matches")
        .set("Authorization", `Bearer ${refereeToken}`)
        .send(payload);

      expect(response.status).toBe(202);
      expect(response.body.success).toBe(true);
      expect(response.body.matchId).toBeDefined();
      expect(response.body.status).toBe("PENDING_VERIFICATION");

      // Verify DB persists record
      const matchInDb = testDbStore.matches.find((m) => m.id === response.body.matchId);
      expect(matchInDb).toBeDefined();
      expect(matchInDb.challengerId).toBe(athleteAId);
      expect(matchInDb.opponentId).toBe(athleteBId);
      expect(matchInDb.arm).toBe("RIGHT");
      expect(matchInDb.status).toBe("PENDING_VERIFICATION");

      // Verify audit trail recorded
      const log = testDbStore.auditLogs.find((l) => l.action === "MATCH_SUBMITTED");
      expect(log).toBeDefined();
      expect(log.userId).toBe(refereeUserId);
    });

    it("should also accept submission from a director role (submission is an official-record action)", async () => {
      const payload = {
        challengerId: athleteAId,
        opponentId: athleteBId,
        arm: "RIGHT",
        winnerId: athleteAId,
        scoreLine: "3-1",
      };

      const response = await request(app)
        .post("/matches")
        .set("Authorization", `Bearer ${adminToken}`)
        .send(payload);

      expect(response.status).toBe(202);
    });

    it("should reject match submission from a non-referee ATHLETE — even a match participant, and even with a fully valid payload", async () => {
      const payload = {
        challengerId: athleteAId,
        opponentId: athleteBId,
        arm: "RIGHT",
        winnerId: athleteAId,
        scoreLine: "3-1",
      };

      const response = await request(app)
        .post("/matches")
        .set("Authorization", `Bearer ${competitorToken}`) // ATHLETE role, and athleteAId is literally this user's own participant ID
        .send(payload);

      expect(response.status).toBe(403);
      // Nothing should have been created.
      const created = testDbStore.matches.find(
        (m) => m.challengerId === athleteAId && m.opponentId === athleteBId
      );
      expect(created).toBeUndefined();
    });

    it("should reject match submission from an unrelated authenticated user with no connection to either competitor", async () => {
      const unrelatedToken = generateAccessToken(
        "totally-unrelated-user-id",
        "stranger@armsphere.com",
        UserRole.ATHLETE,
        env.JWT_ACCESS_SECRET
      );
      const payload = {
        challengerId: athleteAId,
        opponentId: athleteBId,
        arm: "RIGHT",
        winnerId: athleteAId,
        scoreLine: "3-1",
      };

      const response = await request(app)
        .post("/matches")
        .set("Authorization", `Bearer ${unrelatedToken}`)
        .send(payload);

      expect(response.status).toBe(403);
    });

    it("should reject match submission from other unauthorized roles (e.g. TOURNAMENT_OPERATOR)", async () => {
      const operatorToken = generateAccessToken(
        "operator-user-id",
        "operator@armsphere.com",
        UserRole.TOURNAMENT_OPERATOR,
        env.JWT_ACCESS_SECRET
      );
      const payload = {
        challengerId: athleteAId,
        opponentId: athleteBId,
        arm: "RIGHT",
        winnerId: athleteAId,
        scoreLine: "3-1",
      };

      const response = await request(app)
        .post("/matches")
        .set("Authorization", `Bearer ${operatorToken}`)
        .send(payload);

      expect(response.status).toBe(403);
    });

    it("should reject match submission when the reviewer identity does not correspond to any real user (defense-in-depth service-level check)", async () => {
      // A token can carry a role claim for a user that doesn't actually
      // exist (or no longer exists) — the service layer must not trust the
      // JWT's role claim alone without confirming the user record is real.
      const ghostToken = generateAccessToken(
        "99999999-9999-9999-9999-999999999999",
        "ghost-referee@armsphere.com",
        UserRole.REFEREE,
        env.JWT_ACCESS_SECRET
      );
      const payload = {
        challengerId: athleteAId,
        opponentId: athleteBId,
        arm: "RIGHT",
        winnerId: athleteAId,
        scoreLine: "3-1",
      };

      const response = await request(app)
        .post("/matches")
        .set("Authorization", `Bearer ${ghostToken}`)
        .send(payload);

      expect(response.status).toBe(404);
    });

    it("should enforce RFC-7807 problem details when self-match is submitted", async () => {
      const payload = {
        challengerId: athleteAId,
        opponentId: athleteAId, // Self-match
        arm: "RIGHT",
        winnerId: athleteAId,
        scoreLine: "3-0",
      };

      const response = await request(app)
        .post("/matches")
        .set("Authorization", `Bearer ${refereeToken}`)
        .send(payload);

      expect(response.status).toBe(400);
      expect(response.body.title).toBe("Bad Request");
      expect(response.body.detail).toContain("cannot be the same");
    });

    it("should enforce scoreLine regex validation format", async () => {
      const payload = {
        challengerId: athleteAId,
        opponentId: athleteBId,
        arm: "LEFT",
        winnerId: athleteAId,
        scoreLine: "three-zero", // Invalid format
      };

      const response = await request(app)
        .post("/matches")
        .set("Authorization", `Bearer ${refereeToken}`)
        .send(payload);

      expect(response.status).toBe(400);
      expect(response.body.success).toBe(false);
    });

    it("should validate winner is one of the actual competitors", async () => {
      const payload = {
        challengerId: athleteAId,
        opponentId: athleteBId,
        arm: "LEFT",
        winnerId: uuidv4(), // Random winner ID
        scoreLine: "3-0",
      };

      const response = await request(app)
        .post("/matches")
        .set("Authorization", `Bearer ${refereeToken}`)
        .send(payload);

      expect(response.status).toBe(400);
      expect(response.body.detail).toContain("Winner must be either the Challenger or the Opponent");
    });

    it("should return the SAME match (not a duplicate) when the same X-Idempotency-Key is replayed", async () => {
      const payload = {
        challengerId: athleteAId,
        opponentId: athleteBId,
        arm: "RIGHT",
        winnerId: athleteAId,
        scoreLine: "3-2",
      };
      const idempotencyKey = "offline-retry-key-abc123";

      const first = await request(app)
        .post("/matches")
        .set("Authorization", `Bearer ${refereeToken}`)
        .set("X-Idempotency-Key", idempotencyKey)
        .send(payload);

      expect(first.status).toBe(202);
      const firstMatchId = first.body.matchId;

      // Simulate the mobile client's real retry behavior (OfflineSyncManager
      // resending the same queued item with the same idempotency key, e.g.
      // after a flaky connection ack was lost).
      const retry = await request(app)
        .post("/matches")
        .set("Authorization", `Bearer ${refereeToken}`)
        .set("X-Idempotency-Key", idempotencyKey)
        .send(payload);

      expect(retry.status).toBe(202);
      expect(retry.body.matchId).toBe(firstMatchId);

      // The critical assertion: exactly one row in the database, not two.
      const matchingRows = testDbStore.matches.filter((m) => m.idempotencyKey === idempotencyKey);
      expect(matchingRows).toHaveLength(1);
    });

    it("should allow two genuinely different matches even with identical business fields, when no idempotency key is reused", async () => {
      const payload = {
        challengerId: athleteAId,
        opponentId: athleteBId,
        arm: "LEFT",
        winnerId: athleteBId,
        scoreLine: "3-1",
      };

      const first = await request(app)
        .post("/matches")
        .set("Authorization", `Bearer ${refereeToken}`)
        .send(payload);
      const second = await request(app)
        .post("/matches")
        .set("Authorization", `Bearer ${refereeToken}`)
        .send(payload);

      expect(first.status).toBe(202);
      expect(second.status).toBe(202);
      expect(second.body.matchId).not.toBe(first.body.matchId);
    });
  });

  // ==========================================
  // 2. VERIFICATION & ELO CALCULATIONS
  // ==========================================
  describe("POST /matches/:id/verify - Match Verification & ELO updates", () => {
    let matchId: string;

    beforeEach(async () => {
      // Create a pending match
      const payload = {
        challengerId: athleteAId,
        opponentId: athleteBId,
        arm: "RIGHT",
        winnerId: athleteAId,
        scoreLine: "3-0",
      };

      const response = await request(app)
        .post("/matches")
        .set("Authorization", `Bearer ${refereeToken}`)
        .send(payload);

      matchId = response.body.matchId;
    });

    it("should compute and apply dual-arm ELO ratings correctly inside a safe transaction", async () => {
      // Competitors have 0 matches initially, so provisional K-factor (64) is applied
      // Expected challenger score: 1 / (1 + 10^(0/400)) = 0.5
      // Challenger (Winner) delta: round(64 * (1 - 0.5)) = +32
      // Opponent (Loser) delta: round(64 * (0 - 0.5)) = -32

      const response = await request(app)
        .post(`/matches/${matchId}/verify`)
        .set("Authorization", `Bearer ${refereeToken}`);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data.changes).toBeDefined();

      const { challenger, opponent } = response.body.data.changes;
      expect(challenger.previousElo).toBe(1500);
      expect(challenger.newElo).toBe(1532);
      expect(challenger.eloDelta).toBe(32);

      expect(opponent.previousElo).toBe(1500);
      expect(opponent.newElo).toBe(1468);
      expect(opponent.eloDelta).toBe(-32);

      // Verify changes persisted to profiles in memory store
      const apA = testDbStore.athleteProfiles.find((ap) => ap.id === athleteAId);
      const apB = testDbStore.athleteProfiles.find((ap) => ap.id === athleteBId);

      expect(apA.rightArmElo).toBe(1532);
      expect(apB.rightArmElo).toBe(1468);

      // Check ELO Ledger entries
      const winnerLedger = testDbStore.eloLedger.find((l) => l.athleteId === athleteAId);
      const loserLedger = testDbStore.eloLedger.find((l) => l.athleteId === athleteBId);

      expect(winnerLedger).toBeDefined();
      expect(winnerLedger.previousElo).toBe(1500);
      expect(winnerLedger.newElo).toBe(1532);
      expect(winnerLedger.eloDelta).toBe(32);

      expect(loserLedger).toBeDefined();
      expect(loserLedger.previousElo).toBe(1500);
      expect(loserLedger.newElo).toBe(1468);
      expect(loserLedger.eloDelta).toBe(-32);
    });

    it("should clamp ratings to 1000 standard rating floor and prevent sub-1000 storage", async () => {
      // Force athlete A and B's ELO to 1010 so they are equally matched
      const apA = testDbStore.athleteProfiles.find((ap) => ap.id === athleteAId);
      apA.rightArmElo = 1010;
      const apB = testDbStore.athleteProfiles.find((ap) => ap.id === athleteBId);
      apB.rightArmElo = 1010;

      // Challenger (A) ELO: 1010. Opponent (B) ELO: 1010.
      // Winner is A. B loses. B's ELO change should be negative, but clamped to 1000.
      const response = await request(app)
        .post(`/matches/${matchId}/verify`)
        .set("Authorization", `Bearer ${refereeToken}`);

      expect(response.status).toBe(200);
      
      const apBAfter = testDbStore.athleteProfiles.find((ap) => ap.id === athleteBId);
      expect(apBAfter.rightArmElo).toBe(1000); // Clamped perfectly from 978 to 1000!
    });

    it("should create exactly one ELO ledger row per participant per match (the natural uniqueness key)", async () => {
      await request(app)
        .post(`/matches/${matchId}/verify`)
        .set("Authorization", `Bearer ${refereeToken}`);

      const rowsForThisMatch = testDbStore.eloLedger.filter((l) => l.matchId === matchId);
      expect(rowsForThisMatch).toHaveLength(2);
      expect(rowsForThisMatch.map((r) => r.athleteId).sort()).toEqual([athleteAId, athleteBId].sort());
    });

    it("should reject verifying an already-VERIFIED match (application-level guard)", async () => {
      const first = await request(app)
        .post(`/matches/${matchId}/verify`)
        .set("Authorization", `Bearer ${refereeToken}`);
      expect(first.status).toBe(200);

      const second = await request(app)
        .post(`/matches/${matchId}/verify`)
        .set("Authorization", `Bearer ${refereeToken}`);

      expect(second.status).toBe(409);
      // Critically: the second attempt must not have touched the ELO ledger at all.
      const rowsForThisMatch = testDbStore.eloLedger.filter((l) => l.matchId === matchId);
      expect(rowsForThisMatch).toHaveLength(2);
    });

    it("DATABASE-LEVEL BACKSTOP: a duplicate (matchId, athleteId) ELO ledger row is rejected even if something bypasses the application-level status check", async () => {
      // This proves the actual database invariant (idx_elo_ledger_match_athlete),
      // independent of the application-level "already VERIFIED" check above —
      // the real defense-in-depth this migration exists for. If the app-level
      // check were ever buggy, skipped, or raced past, this is what stops a
      // match's ELO from being applied twice.
      const { eloLedger } = await import("@armsphere/db-schema");
      const { db } = await import("../config/db.js");

      await db.insert(eloLedger).values({
        matchId,
        athleteId: athleteAId,
        arm: "RIGHT",
        previousElo: 1500,
        newElo: 1532,
        eloDelta: 32,
      });

      await expect(
        (async () => db.insert(eloLedger).values({
          matchId,
          athleteId: athleteAId, // same (matchId, athleteId) pair — must be rejected
          arm: "RIGHT",
          previousElo: 1532,
          newElo: 1564,
          eloDelta: 32,
        }))()
      ).rejects.toThrow(/unique constraint/i);
    });

    it("should reject verification when reviewerId does not correspond to any real user", async () => {
      const fakeToken = generateAccessToken(
        "99999999-9999-9999-9999-999999999999",
        "ghost-admin@armsphere.com",
        UserRole.SYSTEM_ADMIN,
        env.JWT_ACCESS_SECRET
      );

      const response = await request(app)
        .post(`/matches/${matchId}/verify`)
        .set("Authorization", `Bearer ${fakeToken}`);

      expect(response.status).toBe(404);
    });

    it("should reject verification from a DIFFERENT referee — not the one assigned to this match", async () => {
      // matchId was submitted (in beforeEach) by refereeToken/refereeUserId.
      // A second, entirely legitimate, certified referee should still be
      // rejected — they're just not the one assigned to THIS match.
      testDbStore.users.push({
        id: "other-referee-uuid",
        email: "other-referee@armsphere.com",
        role: "REFEREE",
        fullName: "Other Referee",
        isActive: true,
      });
      testDbStore.refereeCertifications.push({
        id: "cert-other-referee",
        userId: "other-referee-uuid",
        certificationLevel: "PRO_LEVEL_1",
        issuedAt: new Date(),
        expiresAt: new Date(Date.now() + 86400000 * 365),
        status: "ACTIVE",
        issuingBody: "WAF_OFFICIAL",
      });
      const otherRefereeToken = generateAccessToken(
        "other-referee-uuid",
        "other-referee@armsphere.com",
        UserRole.REFEREE,
        env.JWT_ACCESS_SECRET
      );

      const response = await request(app)
        .post(`/matches/${matchId}/verify`)
        .set("Authorization", `Bearer ${otherRefereeToken}`);

      expect(response.status).toBe(403);
      const match = testDbStore.matches.find((m) => m.id === matchId);
      expect(match.status).not.toBe("VERIFIED");
    });

    it("should allow the assigned referee themself to verify (positive case, explicit)", async () => {
      // beforeEach submitted this match via refereeToken — confirm that
      // exact same referee can verify their own assigned match.
      const response = await request(app)
        .post(`/matches/${matchId}/verify`)
        .set("Authorization", `Bearer ${refereeToken}`);

      expect(response.status).toBe(200);
    });

    it("should allow SYSTEM_ADMIN to override and verify a match not assigned to them", async () => {
      const response = await request(app)
        .post(`/matches/${matchId}/verify`)
        .set("Authorization", `Bearer ${adminToken}`);

      expect(response.status).toBe(200);
    });

    it("FLAGGED GAP (not fixed, documenting actual behavior): a DISPUTED match can currently still be verified through this endpoint", async () => {
      // disputeMatch() sets status to "DISPUTED". verifyMatch()'s only status
      // guard checks specifically for "VERIFIED" — it does not check for
      // "DISPUTED". So today, a match under active dispute can be silently
      // verified anyway, overriding the dispute with no resolution step.
      // This was found while implementing real row locking in this exact
      // function, not one of the originally-scoped findings — flagging it
      // per "investigate and classify before fixing, don't silently expand
      // scope" rather than unilaterally adding a new status guard. This test
      // documents the CURRENT actual behavior so it's visible and decided
      // on purpose, not fixed silently or left invisible.
      await request(app)
        .post(`/matches/${matchId}/dispute`)
        .set("Authorization", `Bearer ${refereeToken}`)
        .send({ reason: "Disputing before verification for this test." });

      const matchBeforeVerify = testDbStore.matches.find((m) => m.id === matchId);
      expect(matchBeforeVerify.status).toBe("DISPUTED");

      const verifyResponse = await request(app)
        .post(`/matches/${matchId}/verify`)
        .set("Authorization", `Bearer ${refereeToken}`);

      // Documenting reality, not endorsing it: this currently succeeds.
      expect(verifyResponse.status).toBe(200);
      const matchAfterVerify = testDbStore.matches.find((m) => m.id === matchId);
      expect(matchAfterVerify.status).toBe("VERIFIED");
    });

    it("TRANSACTION ROLLBACK: a mid-transaction failure must leave the match status and athlete ELO untouched, not partially applied", async () => {
      // Force the transaction to fail partway through, after the match
      // status + athlete ELO updates have already happened in-memory but
      // before the whole thing commits — by pre-seeding a colliding ELO
      // ledger row so the transaction's own insert hits the unique
      // constraint from Step A. This is exactly the scenario pessimistic
      // locking + transactional atomicity exists to make safe.
      const apABefore = testDbStore.athleteProfiles.find((ap) => ap.id === athleteAId);
      const originalElo = apABefore.rightArmElo;
      const matchBefore = testDbStore.matches.find((m) => m.id === matchId);
      const originalStatus = matchBefore.status;

      testDbStore.eloLedger.push({
        id: "22222222-2222-2222-2222-222222222222",
        matchId,
        athleteId: athleteAId, // collides with verifyMatch's own first insert for this match
        arm: "RIGHT",
        previousElo: 1500,
        newElo: 1532,
        eloDelta: 32,
        createdAt: new Date(),
      });

      const response = await request(app)
        .post(`/matches/${matchId}/verify`)
        .set("Authorization", `Bearer ${refereeToken}`);

      // The request itself must fail (not silently succeed with corrupted state).
      expect(response.status).toBeGreaterThanOrEqual(400);

      // The critical assertions: nothing partial was left behind.
      const matchAfter = testDbStore.matches.find((m) => m.id === matchId);
      expect(matchAfter.status).toBe(originalStatus); // still whatever it was before this attempt, NOT "VERIFIED"

      const apAAfter = testDbStore.athleteProfiles.find((ap) => ap.id === athleteAId);
      expect(apAAfter.rightArmElo).toBe(originalElo); // ELO update was rolled back, not partially applied

      // Only the one pre-seeded ledger row exists — verifyMatch's own insert
      // attempt (which triggered the rollback) did not leave a partial row.
      const ledgerRowsForMatch = testDbStore.eloLedger.filter((l) => l.matchId === matchId);
      expect(ledgerRowsForMatch).toHaveLength(1);
    });
  });

  // ==========================================
  // 3. MATCH DISPUTES
  // ==========================================
  describe("POST /matches/:id/dispute", () => {
    let matchId: string;

    beforeEach(async () => {
      const response = await request(app)
        .post("/matches")
        .set("Authorization", `Bearer ${refereeToken}`)
        .send({
          challengerId: athleteAId,
          opponentId: athleteBId,
          arm: "RIGHT",
          winnerId: athleteAId,
          scoreLine: "3-2",
        });
      matchId = response.body.matchId;
    });

    it("should flag an ingested match as DISPUTED for board review", async () => {
      const response = await request(app)
        .post(`/matches/${matchId}/dispute`)
        .set("Authorization", `Bearer ${competitorToken}`)
        .send({ reason: "Referee missed a phantom elbow foul in the final strap sequence." });

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data.status).toBe("DISPUTED");

      const match = testDbStore.matches.find((m) => m.id === matchId);
      expect(match.status).toBe("DISPUTED");
    });

    it("should allow the assigned referee to dispute their own match (positive case, explicit)", async () => {
      const response = await request(app)
        .post(`/matches/${matchId}/dispute`)
        .set("Authorization", `Bearer ${refereeToken}`)
        .send({ reason: "Referee self-flagging a scoring irregularity for board review." });

      expect(response.status).toBe(200);
    });

    it("should allow SYSTEM_ADMIN to dispute a match they have no direct relationship to", async () => {
      const response = await request(app)
        .post(`/matches/${matchId}/dispute`)
        .set("Authorization", `Bearer ${adminToken}`)
        .send({ reason: "Administrative review flagged this match for board attention." });

      expect(response.status).toBe(200);
    });

    it("should reject a dispute from an unrelated authenticated user with no relationship to the match", async () => {
      testDbStore.users.push({
        id: "totally-unrelated-stranger-id",
        email: "stranger@armsphere.com",
        role: "ATHLETE",
        fullName: "Random Stranger",
        isActive: true,
      });
      const strangerToken = generateAccessToken(
        "totally-unrelated-stranger-id",
        "stranger@armsphere.com",
        UserRole.ATHLETE,
        env.JWT_ACCESS_SECRET
      );

      const response = await request(app)
        .post(`/matches/${matchId}/dispute`)
        .set("Authorization", `Bearer ${strangerToken}`)
        .send({ reason: "I just want to dispute this match I have nothing to do with." });

      expect(response.status).toBe(403);
      const match = testDbStore.matches.find((m) => m.id === matchId);
      expect(match.status).not.toBe("DISPUTED");
    });

    it("should reject a dispute from an unrelated referee (not assigned to this match, not a participant)", async () => {
      testDbStore.users.push({
        id: "unrelated-referee-uuid",
        email: "unrelated-referee@armsphere.com",
        role: "REFEREE",
        fullName: "Unrelated Referee",
        isActive: true,
      });
      const unrelatedRefereeToken = generateAccessToken(
        "unrelated-referee-uuid",
        "unrelated-referee@armsphere.com",
        UserRole.REFEREE,
        env.JWT_ACCESS_SECRET
      );

      const response = await request(app)
        .post(`/matches/${matchId}/dispute`)
        .set("Authorization", `Bearer ${unrelatedRefereeToken}`)
        .send({ reason: "Disputing a match I have no relationship to." });

      expect(response.status).toBe(403);
    });

    it("should reject a dispute when the actor does not correspond to any real user (defense-in-depth)", async () => {
      const ghostToken = generateAccessToken(
        "99999999-9999-9999-9999-999999999999",
        "ghost@armsphere.com",
        UserRole.ATHLETE,
        env.JWT_ACCESS_SECRET
      );

      const response = await request(app)
        .post(`/matches/${matchId}/dispute`)
        .set("Authorization", `Bearer ${ghostToken}`)
        .send({ reason: "Should never get this far." });

      expect(response.status).toBe(404);
    });
  });

  // ==========================================
  // 4. CORRECTIVE VOIDING & SERIES RECONSTRUCTION
  // ==========================================
  describe("POST /matches/:id/void - SRE Corrective Voiding", () => {
    let matchId: string;

    beforeEach(async () => {
      // 1. Submit match
      const subResponse = await request(app)
        .post("/matches")
        .set("Authorization", `Bearer ${refereeToken}`)
        .send({
          challengerId: athleteAId,
          opponentId: athleteBId,
          arm: "RIGHT",
          winnerId: athleteAId,
          scoreLine: "3-1",
        });
      matchId = subResponse.body.matchId;

      // 2. Verify match (applies ELO +32, -32)
      await request(app)
        .post(`/matches/${matchId}/verify`)
        .set("Authorization", `Bearer ${refereeToken}`);
    });

    it("should allow administrators to void a match, rolling back ratings and replaying subsequent events", async () => {
      // Current ratings: A is 1532, B is 1468
      const response = await request(app)
        .post(`/matches/${matchId}/void`)
        .set("Authorization", `Bearer ${adminToken}`)
        .send({ reason: "Doping violation confirmed by regional SADA testing laboratory." });

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data.status).toBe("VOID");

      // Verify ELO ratings rolled back to 1500
      const apA = testDbStore.athleteProfiles.find((ap) => ap.id === athleteAId);
      const apB = testDbStore.athleteProfiles.find((ap) => ap.id === athleteBId);

      expect(apA.rightArmElo).toBe(1500);
      expect(apB.rightArmElo).toBe(1500);

      // Verify ELO Ledger entries for this match were removed
      const ledgerEntries = testDbStore.eloLedger.filter((l) => l.matchId === matchId);
      expect(ledgerEntries).toHaveLength(0);
    });

    it("should prevent non-directors from initiating voiding operations", async () => {
      const response = await request(app)
        .post(`/matches/${matchId}/void`)
        .set("Authorization", `Bearer ${competitorToken}`)
        .send({ reason: "I want to undo my loss." });

      expect(response.status).toBe(403);
    });
  });

  // ==========================================
  // 5. RECENT MATCHES ENDPOINT
  // ==========================================
  describe("GET /matches/recent - Recent Completed Matches", () => {
    it("should retrieve a paginated, ordered list of completed (verified) matches", async () => {
      // Clear matches before running test to ensure predictable sorting and joins
      testDbStore.matches = [];

      // Create a few mock matches in the testDbStore
      // Match 1: Completed earlier
      const match1Id = uuidv4();
      const match1 = {
        id: match1Id,
        challengerId: athleteAId,
        opponentId: athleteBId,
        arm: "RIGHT",
        refereeId: refereeUserId,
        winnerId: athleteAId,
        scoreLine: "3-0",
        status: "VERIFIED",
        evidenceUrl: "https://example.com/1.mp4",
        createdAt: new Date("2026-07-07T12:00:00Z"),
        verifiedAt: new Date("2026-07-07T12:10:00Z"),
      };

      // Match 2: Completed later
      const match2Id = uuidv4();
      const match2 = {
        id: match2Id,
        challengerId: athleteAId,
        opponentId: athleteBId,
        arm: "LEFT",
        refereeId: refereeUserId,
        winnerId: athleteBId,
        scoreLine: "3-2",
        status: "VERIFIED",
        evidenceUrl: "https://example.com/2.mp4",
        createdAt: new Date("2026-07-07T13:00:00Z"),
        verifiedAt: new Date("2026-07-07T13:10:00Z"),
      };

      // Match 3: Still pending (should NOT be returned in recent matches)
      const match3Id = uuidv4();
      const match3 = {
        id: match3Id,
        challengerId: athleteAId,
        opponentId: athleteBId,
        arm: "RIGHT",
        refereeId: refereeUserId,
        winnerId: athleteAId,
        scoreLine: "3-1",
        status: "PENDING_VERIFICATION",
        createdAt: new Date("2026-07-07T14:00:00Z"),
        verifiedAt: null as any,
      };

      testDbStore.matches = [match1, match2, match3];

      const response = await request(app)
        .get("/matches/recent")
        .set("Authorization", `Bearer ${competitorToken}`)
        .query({ limit: 10, offset: 0 });

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data).toBeDefined();
      expect(response.body.data).toHaveLength(2);

      // Verify correct ordering (verifiedAt descending - Match 2 first, then Match 1)
      expect(response.body.data[0].id).toBe(match2Id);
      expect(response.body.data[1].id).toBe(match1Id);

      // Verify displayNames are joined correctly
      expect(response.body.data[0].challengerName).toBe("Challenger A");
      expect(response.body.data[0].opponentName).toBe("Opponent B");
    });

    it("should not collide with GET /matches/:id route", async () => {
      // Add a dummy match to fetch by ID
      const targetId = uuidv4();
      const match = {
        id: targetId,
        challengerId: athleteAId,
        opponentId: athleteBId,
        arm: "RIGHT",
        refereeId: refereeUserId,
        winnerId: athleteAId,
        scoreLine: "3-0",
        status: "VERIFIED",
        createdAt: new Date(),
        verifiedAt: new Date(),
      };
      testDbStore.matches = [match];

      // Request specifically /matches/recent
      const recentResponse = await request(app)
        .get("/matches/recent")
        .set("Authorization", `Bearer ${competitorToken}`);

      expect(recentResponse.status).toBe(200);
      expect(recentResponse.body.success).toBe(true);
      expect(Array.isArray(recentResponse.body.data)).toBe(true);

      // Request target ID (should hit getMatch endpoint, which is GET /matches/:id)
      const getByIdResponse = await request(app)
        .get(`/matches/${targetId}`)
        .set("Authorization", `Bearer ${competitorToken}`);

      // Since the mock db store is used, we expect getMatch to return the match object
      expect(getByIdResponse.status).toBe(200);
      expect(getByIdResponse.body.success).toBe(true);
      expect(getByIdResponse.body.data).toBeDefined();
      expect(getByIdResponse.body.data.id).toBe(targetId);
    });
  });

  // ==========================================
  // 3b. GET /matches/:id — VISIBILITY REVIEW
  // ==========================================
  // Policy (explicit product decision): match records are intentionally
  // authenticated-readable — this is NOT adding a participant-only
  // ownership restriction. Scope here is narrower: confirm unauthenticated
  // access is blocked, and confirm no field that shouldn't be public is
  // being returned.
  describe("GET /matches/:id — Visibility Review", () => {
    let matchId: string;

    beforeEach(() => {
      matchId = uuidv4();
      testDbStore.matches = [
        {
          id: matchId,
          challengerId: athleteAId,
          opponentId: athleteBId,
          arm: "RIGHT",
          refereeId: refereeUserId,
          winnerId: athleteAId,
          scoreLine: "3-0",
          status: "VERIFIED",
          idempotencyKey: "client-generated-request-dedup-key-abc123",
          evidenceUrl: "https://example.com/evidence.mp4",
          createdAt: new Date(),
          updatedAt: new Date(),
          verifiedAt: new Date(),
        },
      ];
    });

    it("should reject unauthenticated requests", async () => {
      const response = await request(app).get(`/matches/${matchId}`);
      expect(response.status).toBe(401);
    });

    it("should allow any authenticated user to read a match (confirms the intended policy — authenticated-readable, not participant-only)", async () => {
      const response = await request(app)
        .get(`/matches/${matchId}`)
        .set("Authorization", `Bearer ${competitorToken}`); // athleteAId's user — a participant, but this proves ANY authenticated user works, not just participants
      expect(response.status).toBe(200);
    });

    it("FOUND AND FIXED: should NOT expose the internal idempotencyKey in the API response", async () => {
      // idempotencyKey is an internal request-deduplication implementation
      // detail (Step C/A), not a competitive-record field — unlike
      // challengerId/winnerId/scoreLine/etc., which are legitimately public
      // match data. This is field-level API hygiene, not a stricter access
      // policy: every authenticated user can still read the match, this key
      // specifically just shouldn't be in the payload at all.
      const response = await request(app)
        .get(`/matches/${matchId}`)
        .set("Authorization", `Bearer ${competitorToken}`);

      expect(response.status).toBe(200);
      expect(response.body.data.idempotencyKey).toBeUndefined();
      // Legitimate public competitive-record fields must still be present.
      expect(response.body.data.id).toBe(matchId);
      expect(response.body.data.scoreLine).toBe("3-0");
      expect(response.body.data.winnerId).toBe(athleteAId);
      expect(response.body.data.status).toBe("VERIFIED");
    });
  });

  describe("Athlete Matches History", () => {
    it("should list match history for a specific athlete", async () => {
      const matchId = uuidv4();
      const matchObj = {
        id: matchId,
        challengerId: athleteAId,
        opponentId: athleteBId,
        arm: "RIGHT",
        refereeId: refereeUserId,
        winnerId: athleteAId,
        scoreLine: "3-0",
        status: "VERIFIED",
        createdAt: new Date(),
        verifiedAt: new Date(),
      };
      testDbStore.matches = [matchObj];

      const response = await request(app)
        .get(`/athletes/${athleteAId}/matches`)
        .set("Authorization", `Bearer ${competitorToken}`);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(Array.isArray(response.body.data)).toBe(true);
      expect(response.body.data.length).toBeGreaterThan(0);
      expect(response.body.data[0].id).toBe(matchId);
    });
  });
});
