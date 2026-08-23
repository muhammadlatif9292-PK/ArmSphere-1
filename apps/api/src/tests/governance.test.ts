import { describe, it, expect, beforeEach, vi } from "vitest";
import request from "supertest";
import { testDbStore } from "./setup.js";
import { app } from "../app.js";
import { UserRole } from "@armsphere/types";
import { generateAccessToken } from "@armsphere/cryptography";
import { v4 as uuidv4 } from "uuid";
import env from "../config/env.js";
import { GovernanceService } from "../services/governance.js";
import { processedJobsTracker, resetJobTrackers } from "../services/scheduledJobs.js";
import crypto from "crypto";

describe("Sprint 6 — Governance, Disputes, Sanctions & ELO Replay System", () => {
  let athleteUserA: any;
  let athleteProfileA: any;
  let athleteUserB: any;
  let athleteProfileB: any;
  let refereeUser: any;
  let refereeToken: string;
  let directorUser: any;
  let directorToken: string;
  let adminUser: any;
  let adminToken: string;
  let competitorToken: string;

  const athleteAId = "1a111111-1111-1111-1111-111111111111";
  const athleteBId = "2b222222-2222-2222-2222-222222222222";
  const refereeUserId = "3c333333-3333-3333-3333-333333333333";
  const directorUserId = "4d444444-4d44-4d44-4d44-4d444d444d44";
  const adminUserId = "5e555555-5555-5555-5555-555555555555";

  beforeEach(() => {
    // 1. Reset the mocked store and queues
    resetJobTrackers();
    testDbStore.users = [];
    testDbStore.athleteProfiles = [];
    testDbStore.disputes = [];
    testDbStore.disputeEvidence = [];
    testDbStore.disputeComments = [];
    testDbStore.sanctions = [];
    testDbStore.auditEvents = [];
    testDbStore.brackets = [];
    testDbStore.tournamentMatches = [];
    testDbStore.eloLedger = [];

    // 2. Seed basic fixtures
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
    directorUser = {
      id: directorUserId,
      email: "director@armsphere.com",
      username: "director_bob",
      role: UserRole.PROVINCIAL_DIRECTOR,
      fullName: "Director Bob",
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

    testDbStore.users = [athleteUserA, athleteUserB, refereeUser, directorUser, adminUser];

    athleteProfileA = {
      id: athleteAId,
      userId: "user-a-uuid",
      displayName: "Challenger A",
      leftArmElo: 1500,
      rightArmElo: 1500,
      status: "VERIFIED",
    };
    athleteProfileB = {
      id: athleteBId,
      userId: "user-b-uuid",
      displayName: "Opponent B",
      leftArmElo: 1500,
      rightArmElo: 1500,
      status: "VERIFIED",
    };

    testDbStore.athleteProfiles = [athleteProfileA, athleteProfileB];

    // 3. Generate access tokens
    refereeToken = generateAccessToken(
      refereeUserId,
      "referee@armsphere.com",
      UserRole.REFEREE,
      env.JWT_ACCESS_SECRET
    );

    directorToken = generateAccessToken(
      directorUserId,
      "director@armsphere.com",
      UserRole.PROVINCIAL_DIRECTOR,
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

  describe("Dispute Management API Flow", () => {
    it("should allow a competitor to file a dispute on a match", async () => {
      const response = await request(app)
        .post("/governance/disputes")
        .set("Authorization", `Bearer ${competitorToken}`)
        .send({
          matchId: uuidv4(),
          title: "False start at regional championships round 2",
          description: "Athlete B pulled before referee signaled START. Footage shows clear infraction.",
        });

      expect(response.status).toBe(201);
      expect(response.body.success).toBe(true);
      expect(response.body.dispute.status).toBe("OPEN");
      expect(response.body.dispute.title).toContain("False start");
      expect(testDbStore.disputes.length).toBe(1);
    });

    it("should allow a director to assign a reviewer to the dispute", async () => {
      // 1. Create a dispute
      const dispute = await GovernanceService.createDispute(
        "user-a-uuid",
        null,
        "Bad Calls",
        "The referee did not enforce straight wrist positions."
      );

      // 2. Assign reviewer
      const response = await request(app)
        .post(`/governance/disputes/${dispute.id}/assign`)
        .set("Authorization", `Bearer ${directorToken}`)
        .send({
          reviewerId: refereeUserId,
        });

      expect(response.status).toBe(200);
      expect(response.body.dispute.reviewerId).toBe(refereeUserId);
      expect(response.body.dispute.status).toBe("UNDER_REVIEW");
    });

    it("should support submitting evidence with SHA-256 integrity hashes and queueing virus scanning", async () => {
      const dispute = await GovernanceService.createDispute(
        "user-a-uuid",
        null,
        "Bad Calls",
        "The referee did not enforce straight wrist positions."
      );

      const response = await request(app)
        .post(`/governance/disputes/${dispute.id}/evidence`)
        .set("Authorization", `Bearer ${competitorToken}`)
        .send({
          fileType: "VIDEO",
          fileUrl: "https://cloud-storage.armsphere.com/evidence/match-1234.mp4",
          rawFileContent: "Some raw video byte simulation stream",
        });

      expect(response.status).toBe(201);
      expect(response.body.evidence.sha256Hash).toBeDefined();
      expect(response.body.evidence.virusScanned).toBe(true);

      // Verify that the evidence scanning was executed directly
      const simulatedScanJob = processedJobsTracker.virusScans.length;
      expect(simulatedScanJob).toBe(1);
    });

    it("should allow any participant to post comments/notes on a dispute", async () => {
      const dispute = await GovernanceService.createDispute(
        "user-a-uuid",
        null,
        "Faulty Grip",
        "The match grip was completely misaligned."
      );

      const response = await request(app)
        .post(`/governance/disputes/${dispute.id}/comments`)
        .set("Authorization", `Bearer ${refereeToken}`)
        .send({
          comment: "I have reviewed the tape. The grip was correct.",
        });

      expect(response.status).toBe(201);
      expect(response.body.comment.comment).toContain("reviewed the tape");
      expect(testDbStore.disputeComments.length).toBe(1);
    });

    it("should support complete dispute resolution (RESOLVED / REJECTED)", async () => {
      const dispute = await GovernanceService.createDispute(
        "user-a-uuid",
        null,
        "Faulty Grip",
        "The match grip was completely misaligned."
      );

      // Assign reviewer
      await GovernanceService.assignReviewer(dispute.id, refereeUserId, directorUserId);

      // Resolve dispute
      const response = await request(app)
        .post(`/governance/disputes/${dispute.id}/resolve`)
        .set("Authorization", `Bearer ${refereeToken}`)
        .send({
          resolutionDetails: "We found clear alignment and verified the grip was fair.",
          decision: "RESOLVED",
        });

      expect(response.status).toBe(200);
      expect(response.body.dispute.status).toBe("RESOLVED");
      expect(response.body.dispute.resolutionDetails).toBe("We found clear alignment and verified the grip was fair.");
    });

    it("should support escalations and appeals", async () => {
      const dispute = await GovernanceService.createDispute(
        "user-a-uuid",
        null,
        "Dispute for Escalation",
        "Some details."
      );

      // 1. Escalate
      const escResponse = await request(app)
        .post(`/governance/disputes/${dispute.id}/escalate`)
        .set("Authorization", `Bearer ${competitorToken}`)
        .send({
          escalationReason: "The local referee has a direct conflict of interest.",
        });

      expect(escResponse.status).toBe(200);
      expect(escResponse.body.dispute.status).toBe("ESCALATED");
      expect(escResponse.body.dispute.escalationReason).toContain("conflict of interest");

      // 2. Appeal resolved dispute
      const resolvedDispute = await GovernanceService.resolveDispute(
        dispute.id,
        "Initial decision",
        "REJECTED",
        directorUserId
      );

      const appealResponse = await request(app)
        .post(`/governance/disputes/${resolvedDispute.id}/appeal`)
        .set("Authorization", `Bearer ${competitorToken}`)
        .send({
          appealReason: "New angles of footage have been found in high resolution.",
        });

      expect(appealResponse.status).toBe(200);
      expect(appealResponse.body.dispute.status).toBe("AWAITING_EVIDENCE");
      expect(appealResponse.body.dispute.appealReason).toContain("New angles");
    });
  });

  describe("Sanctions System & Warnings Management", () => {
    it("should issue warnings, suspensions, and bans against athletes", async () => {
      const response = await request(app)
        .post("/governance/sanctions")
        .set("Authorization", `Bearer ${adminToken}`)
        .send({
          userId: "user-a-uuid",
          type: "SUSPENSION",
          reason: "Unsportsmanlike conduct at National armwrestling tournament.",
          durationDays: 30,
        });

      expect(response.status).toBe(201);
      expect(response.body.sanction.status).toBe("ACTIVE");
      expect(response.body.sanction.expiresAt).toBeDefined();

      // Ensure user role profile state tracks bans/suspensions if needed
      expect(testDbStore.sanctions.length).toBe(1);
    });

    it("should support automatic expiry sweeps of sanctions", async () => {
      const sanctionPast = {
        id: uuidv4(),
        userId: "user-a-uuid",
        type: "WARNING",
        reason: "Minor foul warning",
        status: "ACTIVE",
        issuedBy: adminUserId,
        createdAt: new Date(Date.now() - 10 * 24 * 60 * 60 * 1000), // 10 days ago
        expiresAt: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000), // expired yesterday
        updatedAt: new Date(),
      };

      testDbStore.sanctions = [sanctionPast];

      const response = await request(app)
        .post("/governance/sanctions/sweep")
        .set("Authorization", `Bearer ${adminToken}`)
        .send();

      expect(response.status).toBe(200);
      expect(response.body.expiredCount).toBe(1);
      expect(testDbStore.sanctions[0].status).toBe("EXPIRED");
    });
  });

  describe("Cryptographically Chained Immutable Audit Ledger", () => {
    it("should chain hashes sequentially for tamper protection", async () => {
      // Log two events
      await GovernanceService.logAuditEvent(adminUserId, "USER", "user-a-uuid", "ROLE_CHANGED", { role: "PROVINCIAL_DIRECTOR" });
      await GovernanceService.logAuditEvent(adminUserId, "ATHLETE", athleteAId, "BIO_UPDATED", { weight: 92 });

      expect(testDbStore.auditEvents.length).toBe(2);
      
      const firstEvent = testDbStore.auditEvents[0];
      const secondEvent = testDbStore.auditEvents[1];

      // Second event parent_hash must match first event event_hash
      expect(secondEvent.parentHash).toBe(firstEvent.eventHash);

      // Verify the ledger
      const verification = await GovernanceService.verifyAuditLedger();
      expect(verification.isValid).toBe(true);
      expect(verification.tamperedEventId).toBeUndefined();
    });

    it("should fail ledger verification if an intermediate block is modified (tamper-proofing)", async () => {
      await GovernanceService.logAuditEvent(adminUserId, "USER", "user-a-uuid", "ROLE_CHANGED", { role: "PROVINCIAL_DIRECTOR" });
      await GovernanceService.logAuditEvent(adminUserId, "ATHLETE", athleteAId, "BIO_UPDATED", { weight: 92 });
      await GovernanceService.logAuditEvent(adminUserId, "USER", "user-b-uuid", "BANNED", { reason: "doping" });

      expect(testDbStore.auditEvents.length).toBe(3);

      // TAMPER WITH EVENT #2 PAYLOAD
      testDbStore.auditEvents[1].payload = { weight: 105 }; // changed secretly!

      // Verify the ledger - should detect corrupt hash chaining
      const verification = await GovernanceService.verifyAuditLedger();
      expect(verification.isValid).toBe(false);
      expect(verification.tamperedEventId).toBe(testDbStore.auditEvents[1].id);
    });
  });

  describe("Administrative Overrides & Chronological ELO Replay Engine", () => {
    it("should process match corrections and recalculate rankings correctly starting from timestamp checkpoint", async () => {
      // 1. Setup tournament and bracket
      const eventId = uuidv4();
      const bracketId = uuidv4();

      testDbStore.brackets = [{
        id: bracketId,
        eventId,
        name: "Pro Left Hand Open",
        format: "SINGLE_ELIMINATION",
        division: "PRO_MEN",
        weightClass: "OPEN",
        arm: "LEFT",
        status: "ACTIVE",
      }];

      // 2. Setup match history
      const matchId1 = uuidv4();
      const matchId2 = uuidv4();

      const time1 = new Date("2026-06-01T12:00:00Z");
      const time2 = new Date("2026-06-01T13:00:00Z");

      testDbStore.tournamentMatches = [
        {
          id: matchId1,
          bracketId,
          round: 1,
          matchIndex: 0,
          athleteAId,
          athleteBId,
          winnerId: athleteBId, // Opponent B won initially
          status: "VERIFIED",
          createdAt: time1,
          updatedAt: time1,
        },
        {
          id: matchId2,
          bracketId,
          round: 2,
          matchIndex: 1,
          athleteAId,
          athleteBId,
          winnerId: athleteAId, // Challenger A won
          status: "VERIFIED",
          createdAt: time2,
          updatedAt: time2,
        },
      ];

      // Reset ratings
      testDbStore.athleteProfiles[0].leftArmElo = 1500;
      testDbStore.athleteProfiles[1].leftArmElo = 1500;

      // 3. Trigger correction via API
      const response = await request(app)
        .post(`/governance/matches/${matchId1}/correct`)
        .set("Authorization", `Bearer ${adminToken}`)
        .send({
          actualWinnerId: athleteAId, // Challenger A is the true winner
        });

      expect(response.status).toBe(200);
      expect(response.body.match.winnerId).toBe(athleteAId);

      // 4. Manually run ELO sequence replay worker to update ratings chronologically
      const replayedCount = await GovernanceService.executeEloRecalculation(time1.toISOString());
      expect(replayedCount).toBe(2);

      // Verify recalculated ratings
      // Match 1: Challenger A (1500) beats Opponent B (1500). Challenger A rating increases (+32 K-factor as matches < 10)
      // Match 2: Challenger A (1532) beats Opponent B (1468). Challenger A rating increases again.
      const updatedA = testDbStore.athleteProfiles.find((p: any) => p.id === athleteAId);
      const updatedB = testDbStore.athleteProfiles.find((p: any) => p.id === athleteBId);

      expect(updatedA.leftArmElo).toBeGreaterThan(1500);
      expect(updatedB.leftArmElo).toBeLessThan(1500);
    });
  });
});
