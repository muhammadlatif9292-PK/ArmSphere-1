import { describe, it, expect, beforeEach } from "vitest";
import request from "supertest";
import { testDbStore } from "./setup.js";
import { app } from "../app.js";
import { UserRole } from "@armsphere/types";
import { generateAccessToken } from "@armsphere/cryptography";
import env from "../config/env.js";

describe("Sprint 9 - Administration & Operations Center Integration Suite", () => {
  let adminToken: string;
  let directorToken: string;
  let opToken: string;
  let complianceToken: string;
  let athleteToken: string;

  const adminId = "11111111-1111-1111-1111-111111111111";
  const directorId = "22222222-2222-2222-2222-222222222222";
  const opId = "33333333-3333-3333-3333-333333333333";
  const complianceId = "44444444-4444-4444-4444-444444444444";
  const athleteId = "55555555-5555-5555-5555-555555555555";
  const refereeId = "66666666-6666-6666-6666-666666666666";

  const athleteProfileId1 = "11111111-1111-1111-1111-111111111112";
  const athleteProfileId2 = "22222222-2222-2222-2222-222222222223";

  beforeEach(() => {
    // Reset store
    testDbStore.users = [];
    testDbStore.athleteProfiles = [];
    testDbStore.athleteVerifications = [];
    testDbStore.matches = [];
    testDbStore.tournamentMatches = [];
    testDbStore.disputes = [];
    testDbStore.sanctions = [];
    testDbStore.auditEvents = [];
    testDbStore.auditLogs = [];

    // Setup user mock data
    const adminUser = { id: adminId, email: "admin@armsphere.com", username: "admin", role: UserRole.SYSTEM_ADMIN, fullName: "System Admin", isActive: true };
    const directorUser = { id: directorId, email: "director@armsphere.com", username: "director", role: UserRole.NATIONAL_DIRECTOR, fullName: "National Director", isActive: true };
    const opUser = { id: opId, email: "op@armsphere.com", username: "operator", role: UserRole.TOURNAMENT_OPERATOR, fullName: "Tournament Operator", isActive: true };
    const complianceUser = { id: complianceId, email: "compliance@armsphere.com", username: "compliance", role: UserRole.COMPLIANCE_OFFICER, fullName: "Compliance Officer", isActive: true };
    const athleteUser = { id: athleteId, email: "athlete@armsphere.com", username: "athlete", role: UserRole.ATHLETE, fullName: "John Athlete", isActive: true };
    const refereeUser = { id: refereeId, email: "referee@armsphere.com", username: "referee", role: UserRole.REFEREE, fullName: "Referee Joe", isActive: true };

    testDbStore.users.push(adminUser, directorUser, opUser, complianceUser, athleteUser, refereeUser);

    // Generate valid JWT tokens
    adminToken = `Bearer ${generateAccessToken(adminId, adminUser.email, adminUser.role, env.JWT_ACCESS_SECRET)}`;
    directorToken = `Bearer ${generateAccessToken(directorId, directorUser.email, directorUser.role, env.JWT_ACCESS_SECRET)}`;
    opToken = `Bearer ${generateAccessToken(opId, opUser.email, opUser.role, env.JWT_ACCESS_SECRET)}`;
    complianceToken = `Bearer ${generateAccessToken(complianceId, complianceUser.email, complianceUser.role, env.JWT_ACCESS_SECRET)}`;
    athleteToken = `Bearer ${generateAccessToken(athleteId, athleteUser.email, athleteUser.role, env.JWT_ACCESS_SECRET)}`;

    // Add some initial profiles, matches, etc.
    testDbStore.athleteProfiles.push({
      id: athleteProfileId1,
      userId: athleteId,
      displayName: "John Athlete",
      province: "Gauteng",
      city: "Johannesburg",
      handedness: "RIGHT",
      dominantArm: "RIGHT",
      weightClass: "95kg",
      leftArmElo: 1200,
      rightArmElo: 1250,
      createdAt: new Date(),
      updatedAt: new Date(),
    });

    testDbStore.athleteProfiles.push({
      id: athleteProfileId2,
      userId: "some-other-id",
      displayName: "Other Wrestler",
      province: "Western Cape",
      city: "Cape Town",
      handedness: "LEFT",
      dominantArm: "LEFT",
      weightClass: "85kg",
      leftArmElo: 1100,
      rightArmElo: 1150,
      createdAt: new Date(),
      updatedAt: new Date(),
    });
  });

  describe("1. Executive Dashboard API", () => {
    it("should return correct platform KPIs and growth metrics for admin", async () => {
      const res = await request(app)
        .get("/admin/dashboard/stats")
        .set("Authorization", adminToken);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.kpis.totalAthletes).toBe(2);
      expect(res.body.data.kpis.totalReferees).toBe(1);
      expect(res.body.data.systemStatus.database).toBe("healthy");
    });

    it("should compute activeChampionships from real title-holder data, not a hardcoded number", async () => {
      testDbStore.championshipTitles.push(
        { id: "title-1", name: "National Right Arm", arm: "RIGHT", division: "SENIOR", weightClass: "80kg", activeChampionId: "some-athlete-id" },
        { id: "title-2", name: "National Left Arm", arm: "LEFT", division: "SENIOR", weightClass: "80kg", activeChampionId: "another-athlete-id" },
        { id: "title-3", name: "Vacant Title", arm: "RIGHT", division: "JUNIOR", weightClass: "60kg", activeChampionId: null }
      );

      const res = await request(app)
        .get("/admin/dashboard/stats")
        .set("Authorization", adminToken);

      expect(res.status).toBe(200);
      // Exactly 2 titles have a holder; the 3rd is vacant and must not count
      expect(res.body.data.kpis.activeChampionships).toBe(2);
    });

    it("should block non-administrative role (ATHLETE) with 403 Forbidden", async () => {
      const res = await request(app)
        .get("/admin/dashboard/stats")
        .set("Authorization", athleteToken);

      expect(res.status).toBe(403);
    });
  });

  describe("2. Athlete Administration API", () => {
    it("should list athletes with optional search queries", async () => {
      const res = await request(app)
        .get("/admin/athletes?search=John")
        .set("Authorization", adminToken);

      expect(res.status).toBe(200);
      expect(res.body.data.length).toBe(1);
      expect(res.body.data[0].displayName).toBe("John Athlete");
    });

    it("should verify/approve an athlete profile", async () => {
      const res = await request(app)
        .post(`/admin/athletes/${athleteProfileId1}/review`)
        .set("Authorization", adminToken)
        .send({ status: "VERIFIED" });

      expect(res.status).toBe(200);
      expect(res.body.data.status).toBe("VERIFIED");
    });

    it("should suspend an athlete and write to sanctions registry", async () => {
      const res = await request(app)
        .post(`/admin/athletes/${athleteProfileId1}/suspend`)
        .set("Authorization", adminToken)
        .send({ reason: "Violation of anti-doping policy", durationDays: 15 });

      expect(res.status).toBe(200);
      expect(testDbStore.sanctions.length).toBe(1);
      expect(testDbStore.sanctions[0].type).toBe("SUSPENSION");
    });

    it("should blacklist an athlete and set user active state to false", async () => {
      const res = await request(app)
        .post(`/admin/athletes/${athleteProfileId1}/blacklist`)
        .set("Authorization", adminToken)
        .send({ reason: "Unsportsmanlike behavior" });

      expect(res.status).toBe(200);
      const athleteUser = testDbStore.users.find(u => u.id === athleteId);
      expect(athleteUser.isActive).toBe(false);
    });

    it("should recover an athlete account and revoke active sanctions", async () => {
      // Setup active blacklist
      testDbStore.users.find(u => u.id === athleteId).isActive = false;
      testDbStore.sanctions.push({
        id: "sanction-1",
        userId: athleteId,
        type: "PERMANENT_BAN",
        reason: "Banned",
        issuedById: adminId,
        startsAt: new Date(),
        status: "ACTIVE",
      });

      const res = await request(app)
        .post(`/admin/athletes/${athleteProfileId1}/recover`)
        .set("Authorization", adminToken);

      expect(res.status).toBe(200);
      const athleteUser = testDbStore.users.find(u => u.id === athleteId);
      expect(athleteUser.isActive).toBe(true);
      expect(testDbStore.sanctions[0].status).toBe("REVOKED");
    });
  });

  describe("3. Referee Administration API", () => {
    it("should list registered referees with their performance analytics", async () => {
      const res = await request(app)
        .get("/admin/referees")
        .set("Authorization", adminToken);

      expect(res.status).toBe(200);
      expect(res.body.data.length).toBe(1);
      expect(res.body.data[0].fullName).toBe("Referee Joe");
    });

    it("should assign referee regional coverage details", async () => {
      const res = await request(app)
        .post(`/admin/referees/${refereeId}/region`)
        .set("Authorization", adminToken)
        .send({ region: "Western Cape" });

      expect(res.status).toBe(200);
      expect(res.body.data.region).toBe("Western Cape");
    });

    it("should PERSIST the assigned region, not just echo it back (regression: old version never saved it)", async () => {
      await request(app)
        .post(`/admin/referees/${refereeId}/region`)
        .set("Authorization", adminToken)
        .send({ region: "Punjab" });

      // A fresh, independent call — proves the assignment actually landed in
      // the database rather than just being reflected in the write response.
      const res = await request(app)
        .get("/admin/referees")
        .set("Authorization", adminToken);

      expect(res.status).toBe(200);
      const referee = res.body.data.find((r: any) => r.id === refereeId);
      expect(referee.region).toBe("Punjab");
    });

    it("should return real certification data for referees, not hardcoded values", async () => {
      testDbStore.refereeCertifications.push({
        id: "cert-1",
        userId: refereeId,
        certificationLevel: "Class II (Provincial)",
        status: "ACTIVE",
        issuingBody: "PASF",
        issuedAt: new Date(Date.now() - 1000 * 60 * 60 * 24 * 30),
      });

      const res = await request(app)
        .get("/admin/referees")
        .set("Authorization", adminToken);

      expect(res.status).toBe(200);
      const referee = res.body.data.find((r: any) => r.id === refereeId);
      expect(referee.licenseClass).toBe("Class II (Provincial)");
      expect(referee.certificationStatus).toBe("ACTIVE");
    });

    it("should return null (not a fabricated number) for referees with no certification on file", async () => {
      const res = await request(app)
        .get("/admin/referees")
        .set("Authorization", adminToken);

      expect(res.status).toBe(200);
      const referee = res.body.data.find((r: any) => r.id === refereeId);
      expect(referee.licenseClass).toBeNull();
      expect(referee.certificationStatus).toBeNull();
      expect(referee.performance.accuracyRate).toBeNull();
      expect(referee.performance.disputeRate).toBeNull();
    });
  });

  describe("4. Match Administration API", () => {
    it("should allow administrators to manually correct match scores", async () => {
      testDbStore.matches.push({
        id: "11111111-1111-1111-1111-111111111113",
        challengerId: athleteProfileId1,
        opponentId: athleteProfileId2,
        arm: "RIGHT",
        refereeId,
        winnerId: athleteProfileId2,
        scoreLine: "0-3",
        status: "VERIFIED",
        createdAt: new Date(),
      });

      const res = await request(app)
        .post("/admin/matches/11111111-1111-1111-1111-111111111113/correct")
        .set("Authorization", adminToken)
        .send({ winnerId: athleteProfileId1, scoreLine: "3-0" });

      expect(res.status).toBe(200);
      expect(testDbStore.matches[0].winnerId).toBe(athleteProfileId1);
      expect(testDbStore.matches[0].scoreLine).toBe("3-0");
    });

    it("FOUND AND FIXED: score correction must actually recompute ELO, not just overwrite the winner field", async () => {
      // Real end-to-end flow: submit → verify (real ELO application) →
      // correct with a flipped winner → assert ELO actually changed to
      // reflect the new winner, not silently left stale from the old one.
      const matchId = "cccccccc-1111-1111-1111-111111111199";
      testDbStore.matches.push({
        id: matchId,
        challengerId: athleteProfileId1,
        opponentId: athleteProfileId2,
        arm: "RIGHT",
        refereeId,
        winnerId: athleteProfileId2, // originally: athlete2 wins
        scoreLine: "0-3",
        status: "PENDING_VERIFICATION",
        createdAt: new Date(),
        updatedAt: new Date(),
      });

      // Real verification — creates real eloLedger rows and real ELO changes.
      const verifyRes = await request(app)
        .post(`/matches/${matchId}/verify`)
        .set("Authorization", adminToken);
      expect(verifyRes.status).toBe(200);

      const ledgerAfterVerify = testDbStore.eloLedger.filter((l) => l.matchId === matchId);
      expect(ledgerAfterVerify).toHaveLength(2);
      const winnerEntry = ledgerAfterVerify.find((l) => l.athleteId === athleteProfileId2);
      expect(winnerEntry.eloDelta).toBeGreaterThan(0); // athlete2 (original winner) gained ELO

      // Now correct it: athlete1 actually won, not athlete2.
      const correctRes = await request(app)
        .post(`/admin/matches/${matchId}/correct`)
        .set("Authorization", adminToken)
        .send({ winnerId: athleteProfileId1, scoreLine: "3-0" });
      expect(correctRes.status).toBe(200);

      // The critical assertions: ELO was actually recomputed, not left stale.
      const ledgerAfterCorrection = testDbStore.eloLedger.filter((l) => l.matchId === matchId);
      expect(ledgerAfterCorrection).toHaveLength(2); // old entries replaced, not accumulated

      const newWinnerEntry = ledgerAfterCorrection.find((l) => l.athleteId === athleteProfileId1);
      const newLoserEntry = ledgerAfterCorrection.find((l) => l.athleteId === athleteProfileId2);
      expect(newWinnerEntry.eloDelta).toBeGreaterThan(0); // athlete1 (corrected winner) now gains ELO
      expect(newLoserEntry.eloDelta).toBeLessThan(0); // athlete2 (corrected loser) now loses ELO

      const match = testDbStore.matches.find((m) => m.id === matchId);
      expect(match.status).toBe("VERIFIED"); // re-verified after the correction, not left VOID
      expect(match.winnerId).toBe(athleteProfileId1);
    });
  });

  describe("5. Immutable Audit Explorer API", () => {
    it("should run dynamic cryptographic validation of hash chains", async () => {
      const res = await request(app)
        .get("/admin/audit/verify")
        .set("Authorization", adminToken);

      expect(res.status).toBe(200);
      expect(res.body.data.isValid).toBe(true);
    });
  });

  describe("6. Background Workers & Reports", async () => {
    it("should successfully trigger a manual background queue worker execution", async () => {
      const res = await request(app)
        .post("/admin/workers/trigger")
        .set("Authorization", adminToken)
        .send({ workerName: "audit.integrity.scan" });

      expect(res.status).toBe(200);
      expect(res.body.data.status).toBe("queued");
    });

    it("should download federation report in CSV format", async () => {
      const res = await request(app)
        .post("/admin/reports/export")
        .set("Authorization", adminToken)
        .send({ format: "csv", reportType: "athletes" });

      expect(res.status).toBe(200);
      expect(res.headers["content-type"]).toContain("text/csv");
      expect(res.text).toContain("Federation Report");
    });
  });
});
