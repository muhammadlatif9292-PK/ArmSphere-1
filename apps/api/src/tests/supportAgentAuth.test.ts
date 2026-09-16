import { describe, it, expect, beforeEach } from "vitest";
import request from "supertest";
import { testDbStore } from "./setup.js";
import { app } from "../app.js";
import { UserRole } from "@armsphere/types";
import { generateAccessToken } from "@armsphere/cryptography";
import { v4 as uuidv4 } from "uuid";
import env from "../config/env.js";

describe("Task 16 — Support-Agent Authorization Audit & Boundary Verification", () => {
  const supportAgentId = uuidv4();
  const athleteUserId = uuidv4();
  const organizerId = uuidv4();
  const eventId = uuidv4();
  const ticketTypeId = uuidv4();
  const ticketId = uuidv4();
  const registrationId = uuidv4();
  const disputeId = uuidv4();
  const matchId = uuidv4();
  const refereeId = uuidv4();

  let supportToken: string;
  let athleteToken: string;

  beforeEach(() => {
    // 1. Reset all relevant testDbStore collections
    testDbStore.users = [];
    testDbStore.athleteProfiles = [];
    testDbStore.events = [];
    testDbStore.eventRegistrations = [];
    testDbStore.ticketTypes = [];
    testDbStore.tickets = [];
    testDbStore.disputes = [];
    testDbStore.disputeEvidence = [];
    testDbStore.disputeComments = [];
    testDbStore.auditEvents = [];
    testDbStore.auditLogs = [];
    testDbStore.matches = [];
    testDbStore.notifications = [];

    // 2. Setup mock users
    const supportUser = {
      id: supportAgentId,
      email: "support@armsphere.com",
      username: "support_agent_01",
      role: UserRole.SUPPORT_AGENT,
      fullName: "Support Agent Jane",
      isActive: true,
    };

    const athleteUser = {
      id: athleteUserId,
      email: "athlete@armsphere.com",
      username: "athlete_01",
      role: UserRole.ATHLETE,
      fullName: "Athlete Bob",
      isActive: true,
    };

    const organizerUser = {
      id: organizerId,
      email: "organizer@armsphere.com",
      username: "organizer_01",
      role: UserRole.TOURNAMENT_OPERATOR,
      fullName: "Event Organizer Dave",
      isActive: true,
    };

    testDbStore.users.push(supportUser, athleteUser, organizerUser);

    // 3. Generate Auth Tokens
    supportToken = `Bearer ${generateAccessToken(
      supportAgentId,
      supportUser.email,
      supportUser.role,
      env.JWT_ACCESS_SECRET
    )}`;

    athleteToken = `Bearer ${generateAccessToken(
      athleteUserId,
      athleteUser.email,
      athleteUser.role,
      env.JWT_ACCESS_SECRET
    )}`;

    // 4. Seed basic tournament, ticketing, and dispute context
    testDbStore.athleteProfiles.push({
      id: uuidv4(),
      userId: athleteUserId,
      displayName: "Athlete Bob",
      province: "Gauteng",
      city: "Johannesburg",
      handedness: "RIGHT",
      dominantArm: "RIGHT",
      weightClass: "85kg",
      leftArmElo: 1200,
      rightArmElo: 1250,
      createdAt: new Date(),
      updatedAt: new Date(),
    });

    testDbStore.events.push({
      id: eventId,
      name: "Gauteng Armwrestling Championship",
      organizerId: organizerId,
      province: "Gauteng",
      city: "Johannesburg",
      venue: "Ellis Park Arena",
      status: "PUBLISHED",
      registrationFeeCents: 2500,
      paymentMethod: "MANUAL_QR",
      startDate: new Date(),
      endDate: new Date(),
      createdAt: new Date(),
      updatedAt: new Date(),
    });

    testDbStore.ticketTypes.push({
      id: ticketTypeId,
      eventId: eventId,
      name: "VIP Spectator Pass",
      priceCents: 5000,
      quantityAvailable: 100,
      quantitySold: 1,
      createdAt: new Date(),
      updatedAt: new Date(),
    });

    testDbStore.tickets.push({
      id: ticketId,
      ticketTypeId: ticketTypeId,
      purchaserUserId: athleteUserId,
      status: "PAID",
      qrCodeData: "TICKET-SAMPLE-01",
      createdAt: new Date(),
      updatedAt: new Date(),
    });

    testDbStore.eventRegistrations.push({
      id: registrationId,
      eventId: eventId,
      athleteId: athleteUserId,
      status: "PENDING",
      paymentStatus: "PENDING_VERIFICATION",
      weightClass: "85kg",
      arm: "RIGHT",
      createdAt: new Date(),
      updatedAt: new Date(),
    });

    testDbStore.disputes.push({
      id: disputeId,
      creatorId: athleteUserId,
      province: "Gauteng",
      title: "Grip Slip Grievance",
      description: "Contested referee slip call in round 3 finals.",
      status: "UNDER_REVIEW",
      createdAt: new Date(),
      updatedAt: new Date(),
    });
  });

  describe("PART 1: Permitted SUPPORT_AGENT Capabilities", () => {
    it("should allow SUPPORT_AGENT to inspect executive dashboard stats (200 OK)", async () => {
      const res = await request(app)
        .get("/admin/dashboard/stats")
        .set("Authorization", supportToken);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data).toBeDefined();
    });

    it("should allow SUPPORT_AGENT to query the athlete directory for user lookup (200 OK)", async () => {
      const res = await request(app)
        .get("/admin/athletes")
        .set("Authorization", supportToken);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data).toBeInstanceOf(Array);
      expect(res.body.data.length).toBeGreaterThan(0);
    });

    it("should allow SUPPORT_AGENT to view admin disputes timeline (200 OK)", async () => {
      const res = await request(app)
        .get("/admin/disputes")
        .set("Authorization", supportToken);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data).toBeInstanceOf(Array);
    });

    it("should allow SUPPORT_AGENT to list governance disputes for support triage (200 OK)", async () => {
      const res = await request(app)
        .get("/governance/disputes")
        .set("Authorization", supportToken);

      expect(res.status).toBe(200);
      expect(res.body).toBeInstanceOf(Array);
      expect(res.body.length).toBeGreaterThan(0);
    });

    it("should allow SUPPORT_AGENT to send customer support alerts/notifications (201 Created)", async () => {
      const res = await request(app)
        .post("/communication/notifications")
        .set("Authorization", supportToken)
        .send({
          userId: athleteUserId,
          title: "Support Ticket Update",
          content: "Your query regarding weigh-in timings has been answered.",
          priority: "NORMAL",
          category: "GENERAL",
        });

      expect(res.status).toBe(201);
      expect(res.body.success).toBe(true);
      expect(res.body.data).toBeDefined();
    });
  });

  describe("PART 2: Forbidden System-Admin & Governance Mutations (403 Forbidden)", () => {
    it("should forbid SUPPORT_AGENT from triggering background workers", async () => {
      const res = await request(app)
        .post("/admin/workers/trigger")
        .set("Authorization", supportToken)
        .send({ jobType: "ELO_RECALCULATION" });

      expect(res.status).toBe(403);
    });

    it("should forbid SUPPORT_AGENT from triggering scheduled jobs", async () => {
      const res = await request(app)
        .post("/admin/scheduled-jobs/run")
        .set("Authorization", supportToken)
        .send({ jobName: "SWEEP_STALE_MATCHES" });

      expect(res.status).toBe(403);
    });

    it("should forbid SUPPORT_AGENT from reading immutable audit events ledger", async () => {
      const res = await request(app)
        .get("/admin/audit/events")
        .set("Authorization", supportToken);

      expect(res.status).toBe(403);
    });

    it("should forbid SUPPORT_AGENT from verifying admin cryptographic audit ledger", async () => {
      const res = await request(app)
        .get("/admin/audit/verify")
        .set("Authorization", supportToken);

      expect(res.status).toBe(403);
    });

    it("should forbid SUPPORT_AGENT from verifying governance cryptographic audit ledger", async () => {
      const res = await request(app)
        .get("/governance/audit/verify")
        .set("Authorization", supportToken);

      expect(res.status).toBe(403);
    });

    it("should forbid SUPPORT_AGENT from triggering ELO recalculation replay engine", async () => {
      const res = await request(app)
        .post("/governance/replay")
        .set("Authorization", supportToken)
        .send({ reason: "Unauthorized replay attempt" });

      expect(res.status).toBe(403);
    });

    it("should forbid SUPPORT_AGENT from suspending athletes", async () => {
      const res = await request(app)
        .post(`/admin/athletes/${athleteUserId}/suspend`)
        .set("Authorization", supportToken)
        .send({ reason: "Unauthorized suspension", durationDays: 30 });

      expect(res.status).toBe(403);
    });

    it("should forbid SUPPORT_AGENT from blacklisting athletes", async () => {
      const res = await request(app)
        .post(`/admin/athletes/${athleteUserId}/blacklist`)
        .set("Authorization", supportToken)
        .send({ reason: "Unauthorized blacklist" });

      expect(res.status).toBe(403);
    });

    it("should forbid SUPPORT_AGENT from recovering blacklisted athletes", async () => {
      const res = await request(app)
        .post(`/admin/athletes/${athleteUserId}/recover`)
        .set("Authorization", supportToken)
        .send({ reason: "Unauthorized recovery" });

      expect(res.status).toBe(403);
    });

    it("should forbid SUPPORT_AGENT from manually correcting athlete records", async () => {
      const res = await request(app)
        .patch(`/admin/athletes/${athleteUserId}/correct`)
        .set("Authorization", supportToken)
        .send({ weightClass: "100kg+" });

      expect(res.status).toBe(403);
    });

    it("should forbid SUPPORT_AGENT from approving athlete profile reviews", async () => {
      const res = await request(app)
        .post(`/admin/athletes/${athleteUserId}/review`)
        .set("Authorization", supportToken)
        .send({ status: "VERIFIED" });

      expect(res.status).toBe(403);
    });

    it("should forbid SUPPORT_AGENT from listing referee registry details", async () => {
      const res = await request(app)
        .get("/admin/referees")
        .set("Authorization", supportToken);

      expect(res.status).toBe(403);
    });

    it("should forbid SUPPORT_AGENT from updating referee license status", async () => {
      const res = await request(app)
        .post(`/admin/referees/${refereeId}/license`)
        .set("Authorization", supportToken)
        .send({ licenseTier: "NATIONAL_MASTER" });

      expect(res.status).toBe(403);
    });

    it("should forbid SUPPORT_AGENT from suspending referees", async () => {
      const res = await request(app)
        .post(`/admin/referees/${refereeId}/suspend`)
        .set("Authorization", supportToken)
        .send({ reason: "Unauthorized referee suspension" });

      expect(res.status).toBe(403);
    });

    it("should forbid SUPPORT_AGENT from modifying or correcting official match scores", async () => {
      const res = await request(app)
        .post(`/admin/matches/${matchId}/correct`)
        .set("Authorization", supportToken)
        .send({ reason: "Unauthorized score change", correctedWinnerId: athleteUserId });

      expect(res.status).toBe(403);
    });

    it("should forbid SUPPORT_AGENT from voiding official matches", async () => {
      const res = await request(app)
        .post(`/admin/matches/${matchId}/void`)
        .set("Authorization", supportToken)
        .send({ reason: "Unauthorized void" });

      expect(res.status).toBe(403);
    });

    it("should forbid SUPPORT_AGENT from creating formal disciplinary sanctions", async () => {
      const res = await request(app)
        .post("/governance/sanctions")
        .set("Authorization", supportToken)
        .send({
          targetUserId: athleteUserId,
          reason: "Unauthorized sanction",
          sanctionType: "SUSPENSION",
        });

      expect(res.status).toBe(403);
    });

    it("should forbid SUPPORT_AGENT from resolving disputes via admin disputes route", async () => {
      const res = await request(app)
        .post(`/admin/disputes/${disputeId}/resolve`)
        .set("Authorization", supportToken)
        .send({ resolution: "Dispute dismissed", decision: "DISMISSED" });

      expect(res.status).toBe(403);
    });

    it("should forbid SUPPORT_AGENT from resolving disputes via governance disputes route", async () => {
      const res = await request(app)
        .post(`/governance/disputes/${disputeId}/resolve`)
        .set("Authorization", supportToken)
        .send({ resolutionDetails: "Dispute resolved by agent", decision: "RESOLVED" });

      expect(res.status).toBe(403);
    });
  });

  describe("PART 3: Forbidden Financial & Ticketing Mutations (403 Forbidden)", () => {
    it("should forbid SUPPORT_AGENT from creating event ticket tiers", async () => {
      const res = await request(app)
        .post(`/events/${eventId}/ticket-types`)
        .set("Authorization", supportToken)
        .send({
          name: "Ringside VIP",
          priceCents: 10000,
          quantityAvailable: 50,
        });

      expect(res.status).toBe(403);
    });

    it("should forbid SUPPORT_AGENT from editing ticket tier pricing", async () => {
      const res = await request(app)
        .patch(`/ticket-types/${ticketTypeId}`)
        .set("Authorization", supportToken)
        .send({ priceCents: 1500 });

      expect(res.status).toBe(403);
    });

    it("should forbid SUPPORT_AGENT from executing ticket refunds", async () => {
      const res = await request(app)
        .post(`/tickets/${ticketId}/refund`)
        .set("Authorization", supportToken);

      expect(res.status).toBe(403);
    });

    it("should forbid SUPPORT_AGENT from confirming tournament registration payments", async () => {
      const res = await request(app)
        .post(`/tournaments/registrations/${registrationId}/confirm-manual-payment`)
        .set("Authorization", supportToken);

      expect(res.status).toBe(403);
    });
  });
});
