import { describe, it, expect, beforeEach } from "vitest";
import request from "supertest";
import { testDbStore } from "./setup.js";
import { app } from "../app.js";
import { UserRole } from "@armsphere/types";
import { generateAccessToken } from "@armsphere/cryptography";
import { v4 as uuidv4 } from "uuid";
import env from "../config/env.js";
import { GovernanceService } from "../services/governance.js";

describe("Reviewer assignment authorization & jurisdiction hardening", () => {
  const adminId = uuidv4();
  const nationalId = uuidv4();
  const directorInId = uuidv4();
  const directorOutId = uuidv4();
  const directorNoJurId = uuidv4();
  const refereeValidId = uuidv4();
  const refereeInactiveId = uuidv4();
  const athleteId = uuidv4();
  const complianceId = uuidv4();
  const creatorId = uuidv4();
  const nonexistentUserId = uuidv4();

  const PROVINCE = "ASGN-Province-Ontario";
  const OTHER_PROVINCE = "ASGN-Province-Quebec";

  const tok = (uid: string, email: string, role: UserRole) =>
    generateAccessToken(uid, email, role, env.JWT_ACCESS_SECRET);

  beforeEach(() => {
    testDbStore.users = [];
    testDbStore.disputes = [];
    testDbStore.auditEvents = [];
    testDbStore.disputeEvidence = [];
    testDbStore.disputeComments = [];
    testDbStore.users = [
      { id: creatorId, email: "asgn-creator@x.test", username: "asgn_creator", role: UserRole.ATHLETE, fullName: "ASGN Creator", isActive: true },
      { id: adminId, email: "asgn-admin@x.test", username: "asgn_admin", role: UserRole.SYSTEM_ADMIN, fullName: "ASGN Admin", isActive: true },
      { id: nationalId, email: "asgn-national@x.test", username: "asgn_national", role: UserRole.NATIONAL_DIRECTOR, fullName: "ASGN National", isActive: true },
      { id: directorInId, email: "asgn-dir-in@x.test", username: "asgn_dir_in", role: UserRole.PROVINCIAL_DIRECTOR, fullName: "ASGN Dir In", isActive: true, province: PROVINCE, regionalCoverage: PROVINCE },
      { id: directorOutId, email: "asgn-dir-out@x.test", username: "asgn_dir_out", role: UserRole.PROVINCIAL_DIRECTOR, fullName: "ASGN Dir Out", isActive: true, province: OTHER_PROVINCE, regionalCoverage: OTHER_PROVINCE },
      { id: directorNoJurId, email: "asgn-dir-nojur@x.test", username: "asgn_dir_nojur", role: UserRole.PROVINCIAL_DIRECTOR, fullName: "ASGN Dir NoJur", isActive: true, province: null, regionalCoverage: null },
      { id: refereeValidId, email: "asgn-ref@x.test", username: "asgn_ref", role: UserRole.REFEREE, fullName: "ASGN Referee", isActive: true },
      { id: refereeInactiveId, email: "asgn-ref-inact@x.test", username: "asgn_ref_inact", role: UserRole.REFEREE, fullName: "ASGN Inactive Referee", isActive: false },
      { id: athleteId, email: "asgn-ath@x.test", username: "asgn_ath", role: UserRole.ATHLETE, fullName: "ASGN Athlete", isActive: true },
      { id: complianceId, email: "asgn-comp@x.test", username: "asgn_comp", role: UserRole.COMPLIANCE_OFFICER, fullName: "ASGN Compliance", isActive: true },
    ];
  });

  async function freshScopedDispute() {
    const d: any = await GovernanceService.createDispute(creatorId, null, "ASGN scoped dispute", "ASGN scoped description.");
    const row = testDbStore.disputes.find((x: any) => x.id === d.id);
    row.province = PROVINCE;
    return row;
  }

  async function freshUnscopedDispute() {
    const d: any = await GovernanceService.createDispute(creatorId, null, "ASGN unscoped dispute", "ASGN unscoped description.");
    return testDbStore.disputes.find((x: any) => x.id === d.id);
  }

  it("A. valid authorized SYSTEM_ADMIN -> success (200 + UNDER_REVIEW + audit)", async () => {
    const d = await freshScopedDispute();
    const n = testDbStore.auditEvents.length;
    const res = await request(app)
      .post(`/governance/disputes/${d.id}/assign`)
      .set("Authorization", `Bearer ${tok(adminId, "asgn-admin@x.test", UserRole.SYSTEM_ADMIN)}`)
      .send({ reviewerId: refereeValidId });

    expect(res.status).toBe(200);
    expect(res.body.dispute.status).toBe("UNDER_REVIEW");
    expect(res.body.dispute.assignedReviewerId).toBe(refereeValidId);

    const after = testDbStore.disputes.find((x: any) => x.id === d.id);
    expect(after.status).toBe("UNDER_REVIEW");
    expect(after.assignedReviewerId).toBe(refereeValidId);
    expect(testDbStore.auditEvents.length).toBeGreaterThan(n);
    expect(testDbStore.auditEvents[testDbStore.auditEvents.length - 1].action).toBe("REVIEWER_ASSIGNED");
    expect(testDbStore.auditEvents[testDbStore.auditEvents.length - 1].actorId).toBe(adminId);
  });

  it("B. valid authorized NATIONAL_DIRECTOR -> success", async () => {
    const d = await freshScopedDispute();
    const res = await request(app)
      .post(`/governance/disputes/${d.id}/assign`)
      .set("Authorization", `Bearer ${tok(nationalId, "asgn-national@x.test", UserRole.NATIONAL_DIRECTOR)}`)
      .send({ reviewerId: refereeValidId });

    expect(res.status).toBe(200);
    expect(res.body.dispute.status).toBe("UNDER_REVIEW");
    expect(res.body.dispute.assignedReviewerId).toBe(refereeValidId);
  });

  it("C. PROVINCIAL_DIRECTOR same province -> success", async () => {
    const d = await freshScopedDispute();
    const res = await request(app)
      .post(`/governance/disputes/${d.id}/assign`)
      .set("Authorization", `Bearer ${tok(directorInId, "asgn-dir-in@x.test", UserRole.PROVINCIAL_DIRECTOR)}`)
      .send({ reviewerId: refereeValidId });

    expect(res.status).toBe(200);
    expect(res.body.dispute.status).toBe("UNDER_REVIEW");
    expect(res.body.dispute.assignedReviewerId).toBe(refereeValidId);
  });

  it("D. PROVINCIAL_DIRECTOR wrong province -> 403 zero mutation", async () => {
    const d = await freshScopedDispute();
    const n = testDbStore.auditEvents.length;
    const before = JSON.stringify(testDbStore.disputes.find((x: any) => x.id === d.id));

    const res = await request(app)
      .post(`/governance/disputes/${d.id}/assign`)
      .set("Authorization", `Bearer ${tok(directorOutId, "asgn-dir-out@x.test", UserRole.PROVINCIAL_DIRECTOR)}`)
      .send({ reviewerId: refereeValidId });

    expect(res.status).toBe(403);
    expect(res.body.detail).toContain("Provincial Director can only assign reviewers for disputes in their assigned province");
    expect(JSON.stringify(testDbStore.disputes.find((x: any) => x.id === d.id))).toBe(before);
    expect(testDbStore.auditEvents.length).toBe(n);
  });

  it("E. no-jurisdiction provincial actor + scoped dispute -> 403 fail closed", async () => {
    const d = await freshScopedDispute();
    const n = testDbStore.auditEvents.length;

    const res = await request(app)
      .post(`/governance/disputes/${d.id}/assign`)
      .set("Authorization", `Bearer ${tok(directorNoJurId, "asgn-dir-nojur@x.test", UserRole.PROVINCIAL_DIRECTOR)}`)
      .send({ reviewerId: refereeValidId });

    expect(res.status).toBe(403);
    expect(res.body.detail).toContain("PROVINCIAL_DIRECTOR must have an assigned province to assign reviewers");
    expect(testDbStore.auditEvents.length).toBe(n);
  });

  it("E2. unscoped dispute with PROVINCIAL_DIRECTOR -> success (backward compatible)", async () => {
    const d = await freshUnscopedDispute();
    const res = await request(app)
      .post(`/governance/disputes/${d.id}/assign`)
      .set("Authorization", `Bearer ${tok(directorInId, "asgn-dir-in@x.test", UserRole.PROVINCIAL_DIRECTOR)}`)
      .send({ reviewerId: refereeValidId });

    expect(res.status).toBe(200);
    expect(res.body.dispute.status).toBe("UNDER_REVIEW");
  });

  it("F. ATHLETE -> 403", async () => {
    const d = await freshScopedDispute();
    const res = await request(app)
      .post(`/governance/disputes/${d.id}/assign`)
      .set("Authorization", `Bearer ${tok(athleteId, "asgn-ath@x.test", UserRole.ATHLETE)}`)
      .send({ reviewerId: refereeValidId });

    expect(res.status).toBe(403);
  });

  it("G. REFEREE / COMPLIANCE_OFFICER -> 403", async () => {
    const d = await freshScopedDispute();
    const resRef = await request(app)
      .post(`/governance/disputes/${d.id}/assign`)
      .set("Authorization", `Bearer ${tok(refereeValidId, "asgn-ref@x.test", UserRole.REFEREE)}`)
      .send({ reviewerId: refereeValidId });
    expect(resRef.status).toBe(403);

    const resComp = await request(app)
      .post(`/governance/disputes/${d.id}/assign`)
      .set("Authorization", `Bearer ${tok(complianceId, "asgn-comp@x.test", UserRole.COMPLIANCE_OFFICER)}`)
      .send({ reviewerId: refereeValidId });
    expect(resComp.status).toBe(403);
  });

  it("H. nonexistent actor -> fail closed 404", async () => {
    const d = await freshScopedDispute();
    // Simulate valid-format JWT from a deleted or nonexistent user ID
    const ghostToken = generateAccessToken(nonexistentUserId, "ghost@x.test", UserRole.SYSTEM_ADMIN, env.JWT_ACCESS_SECRET);
    const res = await request(app)
      .post(`/governance/disputes/${d.id}/assign`)
      .set("Authorization", `Bearer ${ghostToken}`)
      .send({ reviewerId: refereeValidId });

    expect(res.status).toBe(404);
    expect(res.body.detail).toContain("Assigning actor not found");
  });

  it("I. spoofed JWT: DB ATHLETE + JWT SYSTEM_ADMIN -> 403 Forbidden", async () => {
    const d = await freshScopedDispute();
    const n = testDbStore.auditEvents.length;
    const spoofed = generateAccessToken(athleteId, "asgn-ath@x.test", UserRole.SYSTEM_ADMIN, env.JWT_ACCESS_SECRET);

    const res = await request(app)
      .post(`/governance/disputes/${d.id}/assign`)
      .set("Authorization", `Bearer ${spoofed}`)
      .send({ reviewerId: refereeValidId });

    expect(res.status).toBe(403);
    expect(testDbStore.auditEvents.length).toBe(n);
  });

  it("J. reverse spoof: DB SYSTEM_ADMIN with lower JWT role -> follows canonical DB role", async () => {
    const d = await freshScopedDispute();
    // The route requires PROVINCIAL_DIRECTOR, NATIONAL_DIRECTOR, or SYSTEM_ADMIN.
    // If the token claims PROVINCIAL_DIRECTOR (valid at route), but DB is SYSTEM_ADMIN (universal),
    // service executes with SYSTEM_ADMIN authority:
    const token = generateAccessToken(adminId, "asgn-admin@x.test", UserRole.PROVINCIAL_DIRECTOR, env.JWT_ACCESS_SECRET);

    const res = await request(app)
      .post(`/governance/disputes/${d.id}/assign`)
      .set("Authorization", `Bearer ${token}`)
      .send({ reviewerId: refereeValidId });

    expect(res.status).toBe(200);
    expect(res.body.dispute.status).toBe("UNDER_REVIEW");
  });

  it("K1. nonexistent reviewer -> 404 Reviewer not found", async () => {
    const d = await freshScopedDispute();
    const n = testDbStore.auditEvents.length;
    const res = await request(app)
      .post(`/governance/disputes/${d.id}/assign`)
      .set("Authorization", `Bearer ${tok(adminId, "asgn-admin@x.test", UserRole.SYSTEM_ADMIN)}`)
      .send({ reviewerId: uuidv4() });

    expect(res.status).toBe(404);
    expect(res.body.detail).toContain("Reviewer not found");
    expect(testDbStore.auditEvents.length).toBe(n);
  });

  it("K2. inactive reviewer -> 400 Target reviewer is inactive", async () => {
    const d = await freshScopedDispute();
    const n = testDbStore.auditEvents.length;
    const res = await request(app)
      .post(`/governance/disputes/${d.id}/assign`)
      .set("Authorization", `Bearer ${tok(adminId, "asgn-admin@x.test", UserRole.SYSTEM_ADMIN)}`)
      .send({ reviewerId: refereeInactiveId });

    expect(res.status).toBe(400);
    expect(res.body.detail).toContain("Target reviewer is inactive");
    expect(testDbStore.auditEvents.length).toBe(n);
  });

  it("L. terminal dispute (RESOLVED / CLOSED) cannot be assigned -> 409 Conflict", async () => {
    const d = await freshScopedDispute();
    d.status = "RESOLVED";
    const n = testDbStore.auditEvents.length;

    const res = await request(app)
      .post(`/governance/disputes/${d.id}/assign`)
      .set("Authorization", `Bearer ${tok(adminId, "asgn-admin@x.test", UserRole.SYSTEM_ADMIN)}`)
      .send({ reviewerId: refereeValidId });

    expect(res.status).toBe(409);
    expect(res.body.detail).toContain("Dispute has already been resolved");
    expect(testDbStore.auditEvents.length).toBe(n);
  });

  it("M. reassignment allowed while dispute is UNDER_REVIEW", async () => {
    const d = await freshScopedDispute();
    d.status = "UNDER_REVIEW";
    d.assignedReviewerId = refereeValidId;

    const res = await request(app)
      .post(`/governance/disputes/${d.id}/assign`)
      .set("Authorization", `Bearer ${tok(adminId, "asgn-admin@x.test", UserRole.SYSTEM_ADMIN)}`)
      .send({ reviewerId: nationalId });

    expect(res.status).toBe(200);
    expect(res.body.dispute.assignedReviewerId).toBe(nationalId);
    const after = testDbStore.disputes.find((x: any) => x.id === d.id);
    expect(after.assignedReviewerId).toBe(nationalId);
  });
});
