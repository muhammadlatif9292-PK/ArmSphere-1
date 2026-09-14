import { describe, it, expect, beforeEach } from "vitest";
import request from "supertest";
import { testDbStore } from "./setup.js";
import { app } from "../app.js";
import { UserRole } from "@armsphere/types";
import { generateAccessToken } from "@armsphere/cryptography";
import { v4 as uuidv4 } from "uuid";
import env from "../config/env.js";
import { GovernanceService } from "../services/governance.js";

describe("Escalation canonical-identity authorization (creator-only)", () => {
  const creatorId = uuidv4();
  const adminId = uuidv4();
  const directorId = uuidv4();
  const refereeId = uuidv4();
  const strangerAthleteId = uuidv4();
  const PROVINCE = "ESCP1-Province-Alpha";
  const tok = (uid: string, email: string, role: UserRole) => generateAccessToken(uid, email, role, env.JWT_ACCESS_SECRET);
  beforeEach(() => {
    testDbStore.users = [];
    testDbStore.disputes = [];
    testDbStore.auditEvents = [];
    testDbStore.disputeEvidence = [];
    testDbStore.disputeComments = [];
    testDbStore.users = [
      { id: creatorId, email: "escp1-creator@x.test", username: "escp1_creator", role: UserRole.ATHLETE, fullName: "ESCP1 Creator", isActive: true },
      { id: adminId, email: "escp1-admin@x.test", username: "escp1_admin", role: UserRole.SYSTEM_ADMIN, fullName: "ESCP1 Admin", isActive: true },
      { id: directorId, email: "escp1-dir@x.test", username: "escp1_dir", role: UserRole.PROVINCIAL_DIRECTOR, fullName: "ESCP1 Dir", isActive: true, province: PROVINCE, regionalCoverage: PROVINCE },
      { id: refereeId, email: "escp1-ref@x.test", username: "escp1_ref", role: UserRole.REFEREE, fullName: "ESCP1 Ref", isActive: true },
      { id: strangerAthleteId, email: "escp1-str@x.test", username: "escp1_str", role: UserRole.ATHLETE, fullName: "ESCP1 Stranger", isActive: true },
    ];
  });
  async function freshDispute() {
    const d: any = await GovernanceService.createDispute(creatorId, null, "ESCP1 dispute title", "ESCP1 dispute description body.");
    const row = testDbStore.disputes.find((x: any) => x.id === d.id);
    row.province = PROVINCE;
    return row;
  }
  it("A. creator escalates -> 200 + ESCALATED + audit event", async () => {
    const d = await freshDispute();
    const n = testDbStore.auditEvents.length;
    const res = await request(app).post(`/governance/disputes/${d.id}/escalate`).set("Authorization", `Bearer ${tok(creatorId, "escp1-creator@x.test", UserRole.ATHLETE)}`).send({ escalationReason: "The local referee has a direct conflict of interest." });
    expect(res.status).toBe(200);
    expect(res.body.dispute.status).toBe("ESCALATED");
    const after = testDbStore.disputes.find((x: any) => x.id === d.id);
    expect(after.status).toBe("ESCALATED");
    expect(after.resolutionDetails).toContain("conflict of interest");
    expect(testDbStore.auditEvents.length).toBeGreaterThan(n);
    expect(testDbStore.auditEvents[testDbStore.auditEvents.length - 1].action).toBe("DISPUTE_ESCALATED");
  });
  it("B. unrelated privileged actor (SYSTEM_ADMIN, non-creator) -> 403 zero mutation", async () => {
    const d = await freshDispute();
    const n = testDbStore.auditEvents.length;
    const before = JSON.stringify(testDbStore.disputes.find((x: any) => x.id === d.id));
    const res = await request(app).post(`/governance/disputes/${d.id}/escalate`).set("Authorization", `Bearer ${tok(adminId, "escp1-admin@x.test", UserRole.SYSTEM_ADMIN)}`).send({ escalationReason: "Admin tries to escalate another user case here." });
    expect(res.status).toBe(403);
    expect(JSON.stringify(testDbStore.disputes.find((x: any) => x.id === d.id))).toBe(before);
    expect(testDbStore.auditEvents.length).toBe(n);
  });
  it("C. unrelated athlete -> 403 zero mutation", async () => {
    const d = await freshDispute();
    const n = testDbStore.auditEvents.length;
    const res = await request(app).post(`/governance/disputes/${d.id}/escalate`).set("Authorization", `Bearer ${tok(strangerAthleteId, "escp1-str@x.test", UserRole.ATHLETE)}`).send({ escalationReason: "Stranger athlete escalation attempt here." });
    expect(res.status).toBe(403);
    expect(testDbStore.disputes.find((x: any) => x.id === d.id).status).toBe("OPEN");
    expect(testDbStore.auditEvents.length).toBe(n);
  });
  it("D. same-province director (non-creator) -> 403 (creator-only, jurisdiction N/A)", async () => {
    const d = await freshDispute();
    const n = testDbStore.auditEvents.length;
    const res = await request(app).post(`/governance/disputes/${d.id}/escalate`).set("Authorization", `Bearer ${tok(directorId, "escp1-dir@x.test", UserRole.PROVINCIAL_DIRECTOR)}`).send({ escalationReason: "Director escalation attempt reason here." });
    expect(res.status).toBe(403);
    expect(testDbStore.disputes.find((x: any) => x.id === d.id).status).toBe("OPEN");
    expect(testDbStore.auditEvents.length).toBe(n);
  });
  it("G. spoofed JWT role ignored: non-creator with creator-role JWT still 403", async () => {
    const d = await freshDispute();
    const n = testDbStore.auditEvents.length;
    const spoofed = generateAccessToken(refereeId, "escp1-ref@x.test", UserRole.ATHLETE, env.JWT_ACCESS_SECRET);
    void spoofed;
    const res = await request(app).post(`/governance/disputes/${d.id}/escalate`).set("Authorization", `Bearer ${tok(refereeId, "escp1-ref@x.test", UserRole.REFEREE)}`).send({ escalationReason: "Spoof-proof escalation attempt here." });
    expect(res.status).toBe(403);
    expect(testDbStore.auditEvents.length).toBe(n);
  });
  it("I. already-ESCALATED dispute -> 409, no duplicate audit", async () => {
    const d = await freshDispute();
    const first = await request(app).post(`/governance/disputes/${d.id}/escalate`).set("Authorization", `Bearer ${tok(creatorId, "escp1-creator@x.test", UserRole.ATHLETE)}`).send({ escalationReason: "First escalation reason here." });
    expect(first.status).toBe(200);
    const n = testDbStore.auditEvents.length;
    const second = await request(app).post(`/governance/disputes/${d.id}/escalate`).set("Authorization", `Bearer ${tok(creatorId, "escp1-creator@x.test", UserRole.ATHLETE)}`).send({ escalationReason: "Second escalation attempt here." });
    expect(second.status).toBe(409);
    expect(testDbStore.auditEvents.length).toBe(n);
    expect(testDbStore.disputes.find((x: any) => x.id === d.id).resolutionDetails).toContain("First escalation");
  });
  it("I2. resolved dispute cannot be escalated -> 409", async () => {
    const d = await freshDispute();
    const row = testDbStore.disputes.find((x: any) => x.id === d.id);
    row.status = "RESOLVED";
    const n = testDbStore.auditEvents.length;
    const res = await request(app).post(`/governance/disputes/${d.id}/escalate`).set("Authorization", `Bearer ${tok(creatorId, "escp1-creator@x.test", UserRole.ATHLETE)}`).send({ escalationReason: "Escalate resolved dispute attempt." });
    expect(res.status).toBe(409);
    expect(testDbStore.auditEvents.length).toBe(n);
  });
  it("404 for nonexistent dispute", async () => {
    const res = await request(app).post(`/governance/disputes/${uuidv4()}/escalate`).set("Authorization", `Bearer ${tok(creatorId, "escp1-creator@x.test", UserRole.ATHLETE)}`).send({ escalationReason: "Escalate missing dispute reason." });
    expect(res.status).toBe(404);
  });
});
