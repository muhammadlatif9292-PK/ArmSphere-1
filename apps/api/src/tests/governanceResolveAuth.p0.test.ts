import { describe, it, expect, beforeEach } from "vitest";
import request from "supertest";
import { testDbStore } from "./setup.js";
import { app } from "../app.js";
import { UserRole } from "@armsphere/types";
import { generateAccessToken } from "@armsphere/cryptography";
import { v4 as uuidv4 } from "uuid";
import env from "../config/env.js";
import { GovernanceService } from "../services/governance.js";

describe("P0 resolve authorization (IDOR fix)", () => {
  const creatorId = uuidv4();
  const adminId = uuidv4();
  const nationalId = uuidv4();
  const directorInId = uuidv4();
  const directorOutId = uuidv4();
  const refereeAssignedId = uuidv4();
  const refereeOtherId = uuidv4();
  const complianceId = uuidv4();
  const athleteId = uuidv4();
  const PROVINCE = "P0-Test-Province-Alpha";
  const OTHER_PROVINCE = "P0-Test-Province-Beta";
  const tok = (uid: string, email: string, role: UserRole) => generateAccessToken(uid, email, role, env.JWT_ACCESS_SECRET);
  beforeEach(() => {
    testDbStore.users = [];
    testDbStore.disputes = [];
    testDbStore.auditEvents = [];
    testDbStore.disputeEvidence = [];
    testDbStore.disputeComments = [];
    testDbStore.users = [
      { id: creatorId, email: "p0-creator@x.test", username: "p0_creator", role: UserRole.ATHLETE, fullName: "P0 Creator", isActive: true },
      { id: adminId, email: "p0-admin@x.test", username: "p0_admin", role: UserRole.SYSTEM_ADMIN, fullName: "P0 Admin", isActive: true },
      { id: nationalId, email: "p0-national@x.test", username: "p0_national", role: UserRole.NATIONAL_DIRECTOR, fullName: "P0 National", isActive: true },
      { id: directorInId, email: "p0-dir-in@x.test", username: "p0_dir_in", role: UserRole.PROVINCIAL_DIRECTOR, fullName: "P0 Dir In", isActive: true, province: PROVINCE, regionalCoverage: PROVINCE },
      { id: directorOutId, email: "p0-dir-out@x.test", username: "p0_dir_out", role: UserRole.PROVINCIAL_DIRECTOR, fullName: "P0 Dir Out", isActive: true, province: OTHER_PROVINCE, regionalCoverage: OTHER_PROVINCE },
      { id: refereeAssignedId, email: "p0-ref-a@x.test", username: "p0_ref_a", role: UserRole.REFEREE, fullName: "P0 Ref Assigned", isActive: true },
      { id: refereeOtherId, email: "p0-ref-b@x.test", username: "p0_ref_b", role: UserRole.REFEREE, fullName: "P0 Ref Other", isActive: true },
      { id: complianceId, email: "p0-comp@x.test", username: "p0_comp", role: UserRole.COMPLIANCE_OFFICER, fullName: "P0 Compliance", isActive: true },
      { id: athleteId, email: "p0-ath@x.test", username: "p0_ath", role: UserRole.ATHLETE, fullName: "P0 Athlete", isActive: true },
    ];
  });
  async function scopedDispute() {
    const d: any = await GovernanceService.createDispute(creatorId, null, "P0 scoped dispute title", "P0 scoped dispute description body.");
    const row = testDbStore.disputes.find((x: any) => x.id === d.id);
    row.province = PROVINCE;
    row.status = "UNDER_REVIEW";
    row.assignedReviewerId = refereeAssignedId;
    return row;
  }
  async function unscopedDispute() {
    const d: any = await GovernanceService.createDispute(creatorId, null, "P0 unscoped dispute title", "P0 unscoped dispute description body.");
    return testDbStore.disputes.find((x: any) => x.id === d.id);
  }
  it("A. SYSTEM_ADMIN resolves with audit event", async () => {
    const d = await scopedDispute();
    const n = testDbStore.auditEvents.length;
    const res = await request(app).post(`/governance/disputes/${d.id}/resolve`).set("Authorization", `Bearer ${tok(adminId, "p0-admin@x.test", UserRole.SYSTEM_ADMIN)}`).send({ resolutionDetails: "P0 admin decision details", decision: "RESOLVED" });
    expect(res.status).toBe(200);
    expect(res.body.dispute.status).toBe("RESOLVED");
    const after = testDbStore.disputes.find((x: any) => x.id === d.id);
    expect(after.status).toBe("RESOLVED");
    expect(after.resolutionDetails).toBe("P0 admin decision details");
    expect(testDbStore.auditEvents.length).toBeGreaterThan(n);
    expect(testDbStore.auditEvents[testDbStore.auditEvents.length - 1].action).toBe("DISPUTE_RESOLVED");
  });
  it("B. NATIONAL_DIRECTOR resolves", async () => {
    const d = await scopedDispute();
    const res = await request(app).post(`/governance/disputes/${d.id}/resolve`).set("Authorization", `Bearer ${tok(nationalId, "p0-national@x.test", UserRole.NATIONAL_DIRECTOR)}`).send({ resolutionDetails: "P0 national decision details", decision: "RESOLVED" });
    expect(res.status).toBe(200);
    expect(res.body.dispute.status).toBe("RESOLVED");
  });
  it("C. in-jurisdiction PROVINCIAL_DIRECTOR resolves", async () => {
    const d = await scopedDispute();
    d.assignedReviewerId = null;
    const res = await request(app).post(`/governance/disputes/${d.id}/resolve`).set("Authorization", `Bearer ${tok(directorInId, "p0-dir-in@x.test", UserRole.PROVINCIAL_DIRECTOR)}`).send({ resolutionDetails: "P0 in-province director decision", decision: "RESOLVED" });
    expect(res.status).toBe(200);
    expect(res.body.dispute.status).toBe("RESOLVED");
  });
  it("D. out-of-jurisdiction PROVINCIAL_DIRECTOR 403 zero mutation", async () => {
    const d = await scopedDispute();
    d.assignedReviewerId = null;
    const n = testDbStore.auditEvents.length;
    const res = await request(app).post(`/governance/disputes/${d.id}/resolve`).set("Authorization", `Bearer ${tok(directorOutId, "p0-dir-out@x.test", UserRole.PROVINCIAL_DIRECTOR)}`).send({ resolutionDetails: "P0 out-of-province attempt", decision: "RESOLVED" });
    expect(res.status).toBe(403);
    const after = testDbStore.disputes.find((x: any) => x.id === d.id);
    expect(after.status).toBe("UNDER_REVIEW");
    expect(after.resolutionDetails ?? null).toBeNull();
    expect(testDbStore.auditEvents.length).toBe(n);
  });
  it("E. assigned REFEREE resolves", async () => {
    const d = await scopedDispute();
    const res = await request(app).post(`/governance/disputes/${d.id}/resolve`).set("Authorization", `Bearer ${tok(refereeAssignedId, "p0-ref-a@x.test", UserRole.REFEREE)}`).send({ resolutionDetails: "P0 assigned referee decision text", decision: "RESOLVED" });
    expect(res.status).toBe(200);
    expect(res.body.dispute.status).toBe("RESOLVED");
  });
  it("F1. unrelated REFEREE 403 zero mutation", async () => {
    const d = await scopedDispute();
    const n = testDbStore.auditEvents.length;
    const res = await request(app).post(`/governance/disputes/${d.id}/resolve`).set("Authorization", `Bearer ${tok(refereeOtherId, "p0-ref-b@x.test", UserRole.REFEREE)}`).send({ resolutionDetails: "P0 unrelated referee attempt", decision: "RESOLVED" });
    expect(res.status).toBe(403);
    expect(testDbStore.disputes.find((x: any) => x.id === d.id).status).toBe("UNDER_REVIEW");
    expect(testDbStore.auditEvents.length).toBe(n);
  });
  it("F2. COMPLIANCE_OFFICER blocked at route gate 403", async () => {
    const d = await scopedDispute();
    const n = testDbStore.auditEvents.length;
    const res = await request(app).post(`/governance/disputes/${d.id}/resolve`).set("Authorization", `Bearer ${tok(complianceId, "p0-comp@x.test", UserRole.COMPLIANCE_OFFICER)}`).send({ resolutionDetails: "P0 compliance attempt", decision: "RESOLVED" });
    expect(res.status).toBe(403);
    expect(testDbStore.disputes.find((x: any) => x.id === d.id).status).toBe("UNDER_REVIEW");
    expect(testDbStore.auditEvents.length).toBe(n);
  });
  it("G. ATHLETE 403 zero mutation", async () => {
    const d = await scopedDispute();
    const n = testDbStore.auditEvents.length;
    const res = await request(app).post(`/governance/disputes/${d.id}/resolve`).set("Authorization", `Bearer ${tok(athleteId, "p0-ath@x.test", UserRole.ATHLETE)}`).send({ resolutionDetails: "P0 athlete attempt", decision: "RESOLVED" });
    expect(res.status).toBe(403);
    expect(testDbStore.disputes.find((x: any) => x.id === d.id).status).toBe("UNDER_REVIEW");
    expect(testDbStore.auditEvents.length).toBe(n);
  });
  it("H. spoofed JWT role ignored, canonical DB role enforced", async () => {
    const d = await scopedDispute();
    const n = testDbStore.auditEvents.length;
    const spoofed = generateAccessToken(refereeOtherId, "p0-ref-b@x.test", UserRole.SYSTEM_ADMIN, env.JWT_ACCESS_SECRET);
    const res = await request(app).post(`/governance/disputes/${d.id}/resolve`).set("Authorization", `Bearer ${spoofed}`).send({ resolutionDetails: "P0 spoofed role attempt", decision: "RESOLVED" });
    expect(res.status).toBe(403);
    expect(testDbStore.disputes.find((x: any) => x.id === d.id).status).toBe("UNDER_REVIEW");
    expect(testDbStore.auditEvents.length).toBe(n);
  });
  it("J. already-resolved dispute 409 Conflict", async () => {
    const d = await unscopedDispute();
    const first = await request(app).post(`/governance/disputes/${d.id}/resolve`).set("Authorization", `Bearer ${tok(adminId, "p0-admin@x.test", UserRole.SYSTEM_ADMIN)}`).send({ resolutionDetails: "P0 first resolution details", decision: "RESOLVED" });
    expect(first.status).toBe(200);
    const second = await request(app).post(`/governance/disputes/${d.id}/resolve`).set("Authorization", `Bearer ${tok(adminId, "p0-admin@x.test", UserRole.SYSTEM_ADMIN)}`).send({ resolutionDetails: "P0 second resolution attempt", decision: "RESOLVED" });
    expect(second.status).toBe(409);
    expect(testDbStore.disputes.find((x: any) => x.id === d.id).resolutionDetails).toBe("P0 first resolution details");
  });
});
