import { describe, it, expect, beforeEach } from "vitest";
import request from "supertest";
import { testDbStore } from "./setup.js";
import { app } from "../app.js";
import { UserRole } from "@armsphere/types";
import { generateAccessToken } from "@armsphere/cryptography";
import { v4 as uuidv4 } from "uuid";
import env from "../config/env.js";
import { GovernanceService } from "../services/governance.js";

describe("Comment canonical-identity authorization", () => {
  const creatorId = uuidv4();
  const reviewerId = uuidv4();
  const adminId = uuidv4();
  const strangerAthleteId = uuidv4();
  const supportId = uuidv4();
  const tok = (uid: string, email: string, role: UserRole) =>
    generateAccessToken(uid, email, role, env.JWT_ACCESS_SECRET);

  beforeEach(() => {
    testDbStore.users = [];
    testDbStore.disputes = [];
    testDbStore.auditEvents = [];
    testDbStore.disputeEvidence = [];
    testDbStore.disputeComments = [];
    testDbStore.users = [
      { id: creatorId, email: "cmtp1-creator@x.test", username: "cmtp1_creator", role: UserRole.ATHLETE, fullName: "CMTP1 Creator", isActive: true },
      { id: reviewerId, email: "cmtp1-rev@x.test", username: "cmtp1_rev", role: UserRole.REFEREE, fullName: "CMTP1 Reviewer", isActive: true },
      { id: adminId, email: "cmtp1-admin@x.test", username: "cmtp1_admin", role: UserRole.SYSTEM_ADMIN, fullName: "CMTP1 Admin", isActive: true },
      { id: strangerAthleteId, email: "cmtp1-str@x.test", username: "cmtp1_str", role: UserRole.ATHLETE, fullName: "CMTP1 Stranger", isActive: true },
      { id: supportId, email: "cmtp1-sup@x.test", username: "cmtp1_sup", role: UserRole.SUPPORT_AGENT, fullName: "CMTP1 Support", isActive: true },
    ];
  });

  async function freshDispute() {
    const d: any = await GovernanceService.createDispute(
      creatorId, null, "CMTP1 dispute title", "CMTP1 dispute description body."
    );
    const row = testDbStore.disputes.find((x: any) => x.id === d.id);
    row.assignedReviewerId = reviewerId;
    return row;
  }

  async function postCmt(disputeId: string, bearer: string, body: any) {
    return request(app)
      .post(`/governance/disputes/${disputeId}/comments`)
      .set("Authorization", bearer)
      .send(body);
  }
  const GOOD = { comment: "CMTP1 legitimate participant comment here." };


  it("B/C/D. creator, reviewer, admin comment -> 201 + row + audit", async () => {
    const d1 = await freshDispute();
    const nC = testDbStore.disputeComments.length;
    const nA = testDbStore.auditEvents.length;
    const r1 = await postCmt(d1.id, `Bearer ${tok(creatorId, "cmtp1-creator@x.test", UserRole.ATHLETE)}`, GOOD);
    expect(r1.status).toBe(201);
    expect(testDbStore.disputeComments.length).toBe(nC + 1);
    expect(testDbStore.auditEvents.length).toBeGreaterThan(nA);
    expect(testDbStore.auditEvents[testDbStore.auditEvents.length - 1].action).toBe("COMMENT_ADDED");
    const d2 = await freshDispute();
    const r2 = await postCmt(d2.id, `Bearer ${tok(reviewerId, "cmtp1-rev@x.test", UserRole.REFEREE)}`, GOOD);
    expect(r2.status).toBe(201);
    const d3 = await freshDispute();
    const r3 = await postCmt(d3.id, `Bearer ${tok(adminId, "cmtp1-admin@x.test", UserRole.SYSTEM_ADMIN)}`, GOOD);
    expect(r3.status).toBe(201);
  });

  it("E/F. unrelated athlete + SUPPORT_AGENT -> 403 zero mutation", async () => {
    const d = await freshDispute();
    const nC = testDbStore.disputeComments.length;
    const nA = testDbStore.auditEvents.length;
    const before = JSON.stringify(testDbStore.disputes.find((x: any) => x.id === d.id));
    const r1 = await postCmt(d.id, `Bearer ${tok(strangerAthleteId, "cmtp1-str@x.test", UserRole.ATHLETE)}`, GOOD);
    expect(r1.status).toBe(403);
    const r2 = await postCmt(d.id, `Bearer ${tok(supportId, "cmtp1-sup@x.test", UserRole.SUPPORT_AGENT)}`, GOOD);
    expect(r2.status).toBe(403);
    expect(testDbStore.disputeComments.length).toBe(nC);
    expect(testDbStore.auditEvents.length).toBe(nA);
    expect(JSON.stringify(testDbStore.disputes.find((x: any) => x.id === d.id))).toBe(before);
  });

  it("G. spoofed JWT role ignored: DB ATHLETE stranger with ADMIN JWT -> 403", async () => {
    const d = await freshDispute();
    const nC = testDbStore.disputeComments.length;
    const nA = testDbStore.auditEvents.length;
    const spoofed = generateAccessToken(strangerAthleteId, "cmtp1-str@x.test", UserRole.SYSTEM_ADMIN, env.JWT_ACCESS_SECRET);
    const res = await postCmt(d.id, `Bearer ${spoofed}`, GOOD);
    expect(res.status).toBe(403);
    expect(testDbStore.disputeComments.length).toBe(nC);
    expect(testDbStore.auditEvents.length).toBe(nA);
  });

  it("H. reverse spoof: DB ADMIN with ATHLETE JWT still succeeds via DB role", async () => {
    const d = await freshDispute();
    const down = generateAccessToken(adminId, "cmtp1-admin@x.test", UserRole.ATHLETE, env.JWT_ACCESS_SECRET);
    const res = await postCmt(d.id, `Bearer ${down}`, GOOD);
    expect(res.status).toBe(201);
  });

  it("J. validation (400) + 404 intact", async () => {
    const d = await freshDispute();
    const bad = await postCmt(d.id, `Bearer ${tok(creatorId, "cmtp1-creator@x.test", UserRole.ATHLETE)}`, { comment: "x" });
    expect(bad.status).toBe(400);
    const nf = await postCmt(uuidv4(), `Bearer ${tok(creatorId, "cmtp1-creator@x.test", UserRole.ATHLETE)}`, GOOD);
    expect(nf.status).toBe(404);
  });
});