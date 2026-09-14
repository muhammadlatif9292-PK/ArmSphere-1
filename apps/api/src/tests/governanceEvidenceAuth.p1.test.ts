import { describe, it, expect, beforeEach } from "vitest";
import request from "supertest";
import { testDbStore } from "./setup.js";
import { app } from "../app.js";
import { UserRole } from "@armsphere/types";
import { generateAccessToken } from "@armsphere/cryptography";
import { v4 as uuidv4 } from "uuid";
import env from "../config/env.js";
import { GovernanceService } from "../services/governance.js";

describe("Evidence canonical-identity authorization", () => {
  const creatorId = uuidv4();
  const reviewerId = uuidv4();
  const adminId = uuidv4();
  const complianceId = uuidv4();
  const strangerAthleteId = uuidv4();
  const supportId = uuidv4();
  const tok = (uid: string, email: string, role: UserRole) =>
    generateAccessToken(uid, email, role, env.JWT_ACCESS_SECRET);
  const EV = { fileType: "DOCUMENT", fileUrl: "https://example.com/p1-evidence-doc.pdf" };
  const CTOK = `Bearer ${tok(creatorId, "evp1-creator@x.test", UserRole.ATHLETE)}`;

  beforeEach(() => {
    testDbStore.users = [];
    testDbStore.disputes = [];
    testDbStore.auditEvents = [];
    testDbStore.disputeEvidence = [];
    testDbStore.disputeComments = [];
    testDbStore.users = [
      { id: creatorId, email: "evp1-creator@x.test", username: "evp1_creator", role: UserRole.ATHLETE, fullName: "EVP1 Creator", isActive: true },
      { id: reviewerId, email: "evp1-rev@x.test", username: "evp1_rev", role: UserRole.REFEREE, fullName: "EVP1 Reviewer", isActive: true },
      { id: adminId, email: "evp1-admin@x.test", username: "evp1_admin", role: UserRole.SYSTEM_ADMIN, fullName: "EVP1 Admin", isActive: true },
      { id: complianceId, email: "evp1-comp@x.test", username: "evp1_comp", role: UserRole.COMPLIANCE_OFFICER, fullName: "EVP1 Compliance", isActive: true },
      { id: strangerAthleteId, email: "evp1-str@x.test", username: "evp1_str", role: UserRole.ATHLETE, fullName: "EVP1 Stranger", isActive: true },
      { id: supportId, email: "evp1-sup@x.test", username: "evp1_sup", role: UserRole.SUPPORT_AGENT, fullName: "EVP1 Support", isActive: true },
    ];
  });

  async function freshDispute() {
    const d: any = await GovernanceService.createDispute(
      creatorId, null, "EVP1 dispute title", "EVP1 dispute description body."
    );
    const row = testDbStore.disputes.find((x: any) => x.id === d.id);
    row.assignedReviewerId = reviewerId;
    return row;
  }

  async function postEv(disputeId: string, bearer: string, body: any) {
    return request(app)
      .post(`/governance/disputes/${disputeId}/evidence`)
      .set("Authorization", bearer)
      .send(body);
  }

  it("B. creator submits -> 201 + row + audit", async () => {
    const d = await freshDispute();
    const nEv = testDbStore.disputeEvidence.length;
    const nAu = testDbStore.auditEvents.length;
    const res = await postEv(d.id, CTOK, EV);
    expect(res.status).toBe(201);
    expect(testDbStore.disputeEvidence.length).toBe(nEv + 1);
    expect(testDbStore.auditEvents.length).toBeGreaterThan(nAu);
    expect(testDbStore.auditEvents[testDbStore.auditEvents.length - 1].action).toBe("EVIDENCE_SUBMITTED");
  });

  it("C. assigned reviewer submits -> 201", async () => {
    const d = await freshDispute();
    const bearer = `Bearer ${tok(reviewerId, "evp1-rev@x.test", UserRole.REFEREE)}`;
    const res = await postEv(d.id, bearer, EV);
    expect(res.status).toBe(201);
  });

  it("D. staff roles submit -> 201", async () => {
    const d1 = await freshDispute();
    const r1 = await postEv(d1.id, `Bearer ${tok(adminId, "evp1-admin@x.test", UserRole.SYSTEM_ADMIN)}`, EV);
    expect(r1.status).toBe(201);
    const d2 = await freshDispute();
    const r2 = await postEv(d2.id, `Bearer ${tok(complianceId, "evp1-comp@x.test", UserRole.COMPLIANCE_OFFICER)}`, EV);
    expect(r2.status).toBe(201);
  });

  it("E/F. unrelated athlete + SUPPORT_AGENT -> 403 zero mutation", async () => {
    const d = await freshDispute();
    const nEv = testDbStore.disputeEvidence.length;
    const nAu = testDbStore.auditEvents.length;
    const before = JSON.stringify(testDbStore.disputes.find((x: any) => x.id === d.id));
    const r1 = await postEv(d.id, `Bearer ${tok(strangerAthleteId, "evp1-str@x.test", UserRole.ATHLETE)}`, EV);
    expect(r1.status).toBe(403);
    const r2 = await postEv(d.id, `Bearer ${tok(supportId, "evp1-sup@x.test", UserRole.SUPPORT_AGENT)}`, EV);
    expect(r2.status).toBe(403);
    expect(testDbStore.disputeEvidence.length).toBe(nEv);
    expect(testDbStore.auditEvents.length).toBe(nAu);
    expect(JSON.stringify(testDbStore.disputes.find((x: any) => x.id === d.id))).toBe(before);
  });

  it("G. spoofed JWT role ignored: DB ATHLETE stranger with ADMIN JWT -> 403", async () => {
    const d = await freshDispute();
    const nEv = testDbStore.disputeEvidence.length;
    const nAu = testDbStore.auditEvents.length;
    const spoofed = generateAccessToken(strangerAthleteId, "evp1-str@x.test", UserRole.SYSTEM_ADMIN, env.JWT_ACCESS_SECRET);
    const res = await postEv(d.id, `Bearer ${spoofed}`, EV);
    expect(res.status).toBe(403);
    expect(testDbStore.disputeEvidence.length).toBe(nEv);
    expect(testDbStore.auditEvents.length).toBe(nAu);
  });

  it("G2. spoofed-down staff: DB ADMIN with ATHLETE JWT still succeeds via DB role", async () => {
    const d = await freshDispute();
    const down = generateAccessToken(adminId, "evp1-admin@x.test", UserRole.ATHLETE, env.JWT_ACCESS_SECRET);
    const res = await postEv(d.id, `Bearer ${down}`, EV);
    expect(res.status).toBe(201);
  });

  it("J. validation errors intact (400) + 404 intact", async () => {
    const d = await freshDispute();
    const bad = await postEv(d.id, CTOK, { fileType: "DOCUMENT", fileUrl: "not-a-url" });
    expect(bad.status).toBe(400);
    const nf = await postEv(uuidv4(), CTOK, EV);
    expect(nf.status).toBe(404);
  });
});
