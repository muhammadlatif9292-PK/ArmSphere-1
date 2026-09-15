import { describe, it, expect, beforeEach } from "vitest";
import request from "supertest";
import { testDbStore } from "./setup.js";
import { app } from "../app.js";
import { UserRole } from "@armsphere/types";
import { generateAccessToken } from "@armsphere/cryptography";
import { v4 as uuidv4 } from "uuid";
import env from "../config/env.js";
import { GovernanceService } from "../services/governance.js";

describe("Dispute appeal canonical-identity authorization (creator-only)", () => {
  const creatorId = uuidv4();
  const adminId = uuidv4();
  const directorId = uuidv4();
  const refereeId = uuidv4();
  const strangerAthleteId = uuidv4();
  const nonexistentUserId = uuidv4();
  const PROVINCE = "APPL-Province-Alpha";

  const tok = (uid: string, email: string, role: UserRole) =>
    generateAccessToken(uid, email, role, env.JWT_ACCESS_SECRET);

  beforeEach(() => {
    testDbStore.users = [];
    testDbStore.disputes = [];
    testDbStore.auditEvents = [];
    testDbStore.disputeEvidence = [];
    testDbStore.disputeComments = [];
    testDbStore.users = [
      { id: creatorId, email: "appl-creator@x.test", username: "appl_creator", role: UserRole.ATHLETE, fullName: "APPL Creator", isActive: true },
      { id: adminId, email: "appl-admin@x.test", username: "appl_admin", role: UserRole.SYSTEM_ADMIN, fullName: "APPL Admin", isActive: true },
      { id: directorId, email: "appl-dir@x.test", username: "appl_dir", role: UserRole.PROVINCIAL_DIRECTOR, fullName: "APPL Dir", isActive: true, province: PROVINCE, regionalCoverage: PROVINCE },
      { id: refereeId, email: "appl-ref@x.test", username: "appl_ref", role: UserRole.REFEREE, fullName: "APPL Ref", isActive: true },
      { id: strangerAthleteId, email: "appl-str@x.test", username: "appl_str", role: UserRole.ATHLETE, fullName: "APPL Stranger", isActive: true },
    ];
  });

  async function freshResolvedDispute(status: "RESOLVED" | "REJECTED" = "RESOLVED") {
    const d: any = await GovernanceService.createDispute(creatorId, null, "APPL dispute title", "APPL dispute description body.");
    const row = testDbStore.disputes.find((x: any) => x.id === d.id);
    row.status = status;
    row.resolutionDetails = "Initial resolution decision.";
    row.province = PROVINCE;
    return row;
  }

  async function freshOpenDispute() {
    const d: any = await GovernanceService.createDispute(creatorId, null, "APPL open dispute", "APPL open description.");
    return testDbStore.disputes.find((x: any) => x.id === d.id);
  }

  it("A. valid creator + RESOLVED dispute -> success (200 + AWAITING_EVIDENCE + audit event)", async () => {
    const d = await freshResolvedDispute("RESOLVED");
    const n = testDbStore.auditEvents.length;
    const res = await request(app)
      .post(`/governance/disputes/${d.id}/appeal`)
      .set("Authorization", `Bearer ${tok(creatorId, "appl-creator@x.test", UserRole.ATHLETE)}`)
      .send({ appealReason: "New video angle proves fair grip setup." });

    expect(res.status).toBe(200);
    expect(res.body.dispute.status).toBe("AWAITING_EVIDENCE");
    expect(res.body.dispute.appealReason).toContain("New video angle");

    const after = testDbStore.disputes.find((x: any) => x.id === d.id);
    expect(after.status).toBe("AWAITING_EVIDENCE");
    expect(after.resolutionDetails).toContain("New video angle");
    expect(testDbStore.auditEvents.length).toBeGreaterThan(n);
    expect(testDbStore.auditEvents[testDbStore.auditEvents.length - 1].action).toBe("DISPUTE_APPEALED");
  });

  it("B. valid creator + REJECTED dispute -> success", async () => {
    const d = await freshResolvedDispute("REJECTED");
    const res = await request(app)
      .post(`/governance/disputes/${d.id}/appeal`)
      .set("Authorization", `Bearer ${tok(creatorId, "appl-creator@x.test", UserRole.ATHLETE)}`)
      .send({ appealReason: "Overlooked match timestamps clarify the foul order." });

    expect(res.status).toBe(200);
    expect(res.body.dispute.status).toBe("AWAITING_EVIDENCE");
    const after = testDbStore.disputes.find((x: any) => x.id === d.id);
    expect(after.status).toBe("AWAITING_EVIDENCE");
  });

  it("C. valid non-creator athlete -> 403 zero mutation", async () => {
    const d = await freshResolvedDispute("RESOLVED");
    const n = testDbStore.auditEvents.length;
    const before = JSON.stringify(testDbStore.disputes.find((x: any) => x.id === d.id));

    const res = await request(app)
      .post(`/governance/disputes/${d.id}/appeal`)
      .set("Authorization", `Bearer ${tok(strangerAthleteId, "appl-str@x.test", UserRole.ATHLETE)}`)
      .send({ appealReason: "Stranger athlete tries to appeal." });

    expect(res.status).toBe(403);
    expect(JSON.stringify(testDbStore.disputes.find((x: any) => x.id === d.id))).toBe(before);
    expect(testDbStore.auditEvents.length).toBe(n);
  });

  it("D. nonexistent actor users.id -> fail closed (404 Actor not found)", async () => {
    const d = await freshResolvedDispute("RESOLVED");
    const n = testDbStore.auditEvents.length;
    const before = JSON.stringify(testDbStore.disputes.find((x: any) => x.id === d.id));

    const res = await request(app)
      .post(`/governance/disputes/${d.id}/appeal`)
      .set("Authorization", `Bearer ${tok(nonexistentUserId, "ghost@x.test", UserRole.ATHLETE)}`)
      .send({ appealReason: "Ghost user appeals." });

    expect(res.status).toBe(404);
    expect(res.body.detail).toContain("Appeal actor not found");
    expect(JSON.stringify(testDbStore.disputes.find((x: any) => x.id === d.id))).toBe(before);
    expect(testDbStore.auditEvents.length).toBe(n);
  });

  it("E. creator with arbitrary/spoofed role -> creator-only policy still succeeds", async () => {
    const d = await freshResolvedDispute("RESOLVED");
    const spoofed = generateAccessToken(creatorId, "appl-creator@x.test", UserRole.PROVINCIAL_DIRECTOR, env.JWT_ACCESS_SECRET);

    const res = await request(app)
      .post(`/governance/disputes/${d.id}/appeal`)
      .set("Authorization", `Bearer ${spoofed}`)
      .send({ appealReason: "Creator with spoofed JWT role appeals validly." });

    expect(res.status).toBe(200);
    expect(res.body.dispute.status).toBe("AWAITING_EVIDENCE");
  });

  it("F. non-creator privileged role (SYSTEM_ADMIN, PROVINCIAL_DIRECTOR, REFEREE) -> still 403", async () => {
    const d = await freshResolvedDispute("RESOLVED");
    const n = testDbStore.auditEvents.length;

    const resAdmin = await request(app)
      .post(`/governance/disputes/${d.id}/appeal`)
      .set("Authorization", `Bearer ${tok(adminId, "appl-admin@x.test", UserRole.SYSTEM_ADMIN)}`)
      .send({ appealReason: "Admin tries to appeal another dispute." });
    expect(resAdmin.status).toBe(403);

    const resDir = await request(app)
      .post(`/governance/disputes/${d.id}/appeal`)
      .set("Authorization", `Bearer ${tok(directorId, "appl-dir@x.test", UserRole.PROVINCIAL_DIRECTOR)}`)
      .send({ appealReason: "Director tries to appeal another dispute." });
    expect(resDir.status).toBe(403);

    const resRef = await request(app)
      .post(`/governance/disputes/${d.id}/appeal`)
      .set("Authorization", `Bearer ${tok(refereeId, "appl-ref@x.test", UserRole.REFEREE)}`)
      .send({ appealReason: "Referee tries to appeal another dispute." });
    expect(resRef.status).toBe(403);

    expect(testDbStore.auditEvents.length).toBe(n);
  });

  it("G. OPEN / invalid-state dispute -> existing 400 behavior", async () => {
    const d = await freshOpenDispute();
    const n = testDbStore.auditEvents.length;

    const res = await request(app)
      .post(`/governance/disputes/${d.id}/appeal`)
      .set("Authorization", `Bearer ${tok(creatorId, "appl-creator@x.test", UserRole.ATHLETE)}`)
      .send({ appealReason: "Cannot appeal open dispute." });

    expect(res.status).toBe(400);
    expect(res.body.detail).toContain("Only resolved or rejected disputes can be appealed");
    expect(testDbStore.auditEvents.length).toBe(n);
  });

  it("H. rejected unauthorized attempt: no state change, no resolution details change, no audit event", async () => {
    const d = await freshResolvedDispute("RESOLVED");
    const n = testDbStore.auditEvents.length;
    const initialResolution = d.resolutionDetails;

    const res = await request(app)
      .post(`/governance/disputes/${d.id}/appeal`)
      .set("Authorization", `Bearer ${tok(strangerAthleteId, "appl-str@x.test", UserRole.ATHLETE)}`)
      .send({ appealReason: "Malicious appeal attempt." });

    expect(res.status).toBe(403);

    const stored = testDbStore.disputes.find((x: any) => x.id === d.id);
    expect(stored.status).toBe("RESOLVED");
    expect(stored.resolutionDetails).toBe(initialResolution);
    expect(testDbStore.auditEvents.length).toBe(n);
  });

  it("I. successful appeal: expected state transition to AWAITING_EVIDENCE and DISPUTE_APPEALED audit event", async () => {
    const d = await freshResolvedDispute("RESOLVED");
    const n = testDbStore.auditEvents.length;

    const res = await request(app)
      .post(`/governance/disputes/${d.id}/appeal`)
      .set("Authorization", `Bearer ${tok(creatorId, "appl-creator@x.test", UserRole.ATHLETE)}`)
      .send({ appealReason: "Complete review with photographic evidence attached." });

    expect(res.status).toBe(200);

    const stored = testDbStore.disputes.find((x: any) => x.id === d.id);
    expect(stored.status).toBe("AWAITING_EVIDENCE");
    expect(stored.resolutionDetails).toBe("Appealed. Reason: Complete review with photographic evidence attached.");

    expect(testDbStore.auditEvents.length).toBe(n + 1);
    const lastAudit = testDbStore.auditEvents[testDbStore.auditEvents.length - 1];
    expect(lastAudit.action).toBe("DISPUTE_APPEALED");
    expect(lastAudit.entityId).toBe(d.id);
    expect(lastAudit.actorId).toBe(creatorId);
  });
});
