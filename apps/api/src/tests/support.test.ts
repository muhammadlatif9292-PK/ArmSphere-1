import { describe, it, expect, beforeEach } from "vitest";
import request from "supertest";
import { testDbStore } from "./setup.js";
import { app } from "../app.js";
import { UserRole, SupportTicketStatus, SupportTicketPriority, SupportTicketCategory } from "@armsphere/types";
import { generateAccessToken } from "@armsphere/cryptography";
import { v4 as uuidv4 } from "uuid";
import env from "../config/env.js";

describe("Customer Support & Helpdesk Ticketing System", () => {
  const athlete1Id = uuidv4();
  const athlete2Id = uuidv4();
  const supportAgentId = uuidv4();
  const supportAgent2Id = uuidv4();
  const adminId = uuidv4();

  let athlete1Token: string;
  let athlete2Token: string;
  let supportToken: string;
  let support2Token: string;
  let adminToken: string;

  beforeEach(() => {
    testDbStore.users = [];
    testDbStore.athleteProfiles = [];
    testDbStore.supportTickets = [];
    testDbStore.supportTicketMessages = [];
    testDbStore.auditEvents = [];

    const athlete1 = {
      id: athlete1Id,
      email: "athlete1@armsphere.test",
      username: "athlete1",
      role: UserRole.ATHLETE,
      fullName: "Hamza Contender",
      isActive: true,
    };

    const athlete2 = {
      id: athlete2Id,
      email: "athlete2@armsphere.test",
      username: "athlete2",
      role: UserRole.ATHLETE,
      fullName: "Tariq Contender",
      isActive: true,
    };

    const supportAgent = {
      id: supportAgentId,
      email: "support@armsphere.test",
      username: "support_agent",
      role: UserRole.SUPPORT_AGENT,
      fullName: "Agent Sarah",
      isActive: true,
    };

    const supportAgent2 = {
      id: supportAgent2Id,
      email: "support2@armsphere.test",
      username: "support_agent_2",
      role: UserRole.SUPPORT_AGENT,
      fullName: "Agent Marcus",
      isActive: true,
    };

    const admin = {
      id: adminId,
      email: "admin@armsphere.test",
      username: "system_admin",
      role: UserRole.SYSTEM_ADMIN,
      fullName: "System Admin",
      isActive: true,
    };

    testDbStore.users.push(athlete1, athlete2, supportAgent, supportAgent2, admin);

    athlete1Token = `Bearer ${generateAccessToken(athlete1Id, athlete1.email, athlete1.role, env.JWT_ACCESS_SECRET)}`;
    athlete2Token = `Bearer ${generateAccessToken(athlete2Id, athlete2.email, athlete2.role, env.JWT_ACCESS_SECRET)}`;
    supportToken = `Bearer ${generateAccessToken(supportAgentId, supportAgent.email, supportAgent.role, env.JWT_ACCESS_SECRET)}`;
    support2Token = `Bearer ${generateAccessToken(supportAgent2Id, supportAgent2.email, supportAgent2.role, env.JWT_ACCESS_SECRET)}`;
    adminToken = `Bearer ${generateAccessToken(adminId, admin.email, admin.role, env.JWT_ACCESS_SECRET)}`;
  });

  describe("1. Ticket Creation", () => {
    it("allows an authenticated athlete to create a support ticket with valid data (201 Created)", async () => {
      const res = await request(app)
        .post("/support/tickets")
        .set("Authorization", athlete1Token)
        .send({
          subject: "Issue with weight class change",
          description: "I need to update my registered weight class from -85kg to -95kg.",
          category: SupportTicketCategory.EVENT,
          priority: SupportTicketPriority.HIGH,
        });

      expect(res.status).toBe(201);
      expect(res.body.success).toBe(true);
      expect(res.body.data).toBeDefined();
      expect(res.body.data.id).toBeDefined();
      expect(res.body.data.userId).toBe(athlete1Id);
      expect(res.body.data.subject).toBe("Issue with weight class change");
      expect(res.body.data.status).toBe(SupportTicketStatus.OPEN);

      // Verify audit event was logged
      const audit = testDbStore.auditEvents.find(
        (e: any) => e.entityId === res.body.data.id && e.action === "SUPPORT_TICKET_CREATED"
      );
      expect(audit).toBeDefined();
      expect(audit.actorId).toBe(athlete1Id);
    });

    it("rejects ticket creation with empty subject or description (400 Bad Request)", async () => {
      const res = await request(app)
        .post("/support/tickets")
        .set("Authorization", athlete1Token)
        .send({
          subject: "",
          description: "Missing subject",
        });

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
    });

    it("rejects unauthenticated ticket creation (401 Unauthorized)", async () => {
      const res = await request(app)
        .post("/support/tickets")
        .send({
          subject: "Cannot login",
          description: "Please help",
        });

      expect(res.status).toBe(401);
    });
  });

  describe("2. Own-Ticket Scoping & Confidentiality", () => {
    let ticketAId: string;
    let ticketBId: string;

    beforeEach(async () => {
      const resA = await request(app)
        .post("/support/tickets")
        .set("Authorization", athlete1Token)
        .send({
          subject: "Athlete 1 Ticket",
          description: "Private issue for Athlete 1",
        });
      ticketAId = resA.body.data.id;

      const resB = await request(app)
        .post("/support/tickets")
        .set("Authorization", athlete2Token)
        .send({
          subject: "Athlete 2 Ticket",
          description: "Private issue for Athlete 2",
        });
      ticketBId = resB.body.data.id;
    });

    it("allows athlete to view their own ticket (200 OK)", async () => {
      const res = await request(app)
        .get(`/support/tickets/${ticketAId}`)
        .set("Authorization", athlete1Token);

      expect(res.status).toBe(200);
      expect(res.body.data.id).toBe(ticketAId);
      expect(res.body.data.subject).toBe("Athlete 1 Ticket");
    });

    it("strictly forbids an athlete from viewing another athlete's ticket (403 Forbidden)", async () => {
      const res = await request(app)
        .get(`/support/tickets/${ticketAId}`)
        .set("Authorization", athlete2Token);

      expect(res.status).toBe(403);
      expect(res.body.detail || res.body.message).toMatch(/not authorized/i);
    });

    it("filters ticket list so athlete only sees their own tickets", async () => {
      const res = await request(app)
        .get("/support/tickets")
        .set("Authorization", athlete1Token);

      expect(res.status).toBe(200);
      expect(res.body.data.length).toBe(1);
      expect(res.body.data[0].id).toBe(ticketAId);
    });

    it("allows Support Agent to see all tickets across all athletes", async () => {
      const res = await request(app)
        .get("/support/tickets")
        .set("Authorization", supportToken);

      expect(res.status).toBe(200);
      expect(res.body.data.length).toBe(2);
      const ids = res.body.data.map((t: any) => t.id);
      expect(ids).toContain(ticketAId);
      expect(ids).toContain(ticketBId);
    });

    it("allows System Admin to see all tickets across all athletes", async () => {
      const res = await request(app)
        .get("/support/tickets")
        .set("Authorization", adminToken);

      expect(res.status).toBe(200);
      expect(res.body.data.length).toBe(2);
    });
  });

  describe("3. Ticket Assignment", () => {
    let ticketId: string;

    beforeEach(async () => {
      const res = await request(app)
        .post("/support/tickets")
        .set("Authorization", athlete1Token)
        .send({
          subject: "Referee certification question",
          description: "How do I upgrade to National Level 1?",
        });
      ticketId = res.body.data.id;
    });

    it("allows Support Agent to assign ticket to themselves and promotes status to IN_PROGRESS", async () => {
      const res = await request(app)
        .post(`/support/tickets/${ticketId}/assign`)
        .set("Authorization", supportToken)
        .send({ agentId: supportAgentId });

      expect(res.status).toBe(200);
      expect(res.body.data.assignedAgentId).toBe(supportAgentId);
      expect(res.body.data.status).toBe(SupportTicketStatus.IN_PROGRESS);

      const audit = testDbStore.auditEvents.find(
        (e: any) => e.entityId === ticketId && e.action === "SUPPORT_TICKET_ASSIGNED"
      );
      expect(audit).toBeDefined();
    });

    it("allows Support Agent to reassign ticket to another agent", async () => {
      const res = await request(app)
        .post(`/support/tickets/${ticketId}/assign`)
        .set("Authorization", supportToken)
        .send({ agentId: supportAgent2Id });

      expect(res.status).toBe(200);
      expect(res.body.data.assignedAgentId).toBe(supportAgent2Id);
    });

    it("rejects assigning ticket to a regular athlete (400 Bad Request)", async () => {
      const res = await request(app)
        .post(`/support/tickets/${ticketId}/assign`)
        .set("Authorization", supportToken)
        .send({ agentId: athlete2Id });

      expect(res.status).toBe(400);
      expect(res.body.detail || res.body.message).toMatch(/support agents or administrators/i);
    });

    it("forbids an athlete from assigning tickets (403 Forbidden)", async () => {
      const res = await request(app)
        .post(`/support/tickets/${ticketId}/assign`)
        .set("Authorization", athlete1Token)
        .send({ agentId: supportAgentId });

      expect(res.status).toBe(403);
    });
  });

  describe("4. Status Updates & Transitions", () => {
    let ticketId: string;

    beforeEach(async () => {
      const res = await request(app)
        .post("/support/tickets")
        .set("Authorization", athlete1Token)
        .send({
          subject: "Dispute clarification",
          description: "Need help reviewing foul call",
        });
      ticketId = res.body.data.id;
    });

    it("allows Support Agent to resolve a ticket with resolution notes", async () => {
      const res = await request(app)
        .patch(`/support/tickets/${ticketId}/status`)
        .set("Authorization", supportToken)
        .send({
          status: SupportTicketStatus.RESOLVED,
          resolutionNotes: "Explained rule 4.2 to athlete and confirmed video review was accurate.",
        });

      expect(res.status).toBe(200);
      expect(res.body.data.status).toBe(SupportTicketStatus.RESOLVED);
      expect(res.body.data.resolutionNotes).toBe("Explained rule 4.2 to athlete and confirmed video review was accurate.");
      expect(res.body.data.resolvedAt).toBeDefined();
      expect(res.body.data.resolvedById).toBe(supportAgentId);

      const audit = testDbStore.auditEvents.find(
        (e: any) => e.entityId === ticketId && e.action === "SUPPORT_TICKET_STATUS_UPDATED"
      );
      expect(audit).toBeDefined();
    });

    it("allows athlete to close their own ticket (200 OK)", async () => {
      const res = await request(app)
        .patch(`/support/tickets/${ticketId}/status`)
        .set("Authorization", athlete1Token)
        .send({
          status: SupportTicketStatus.CLOSED,
        });

      expect(res.status).toBe(200);
      expect(res.body.data.status).toBe(SupportTicketStatus.CLOSED);
    });

    it("forbids athlete from marking ticket as RESOLVED or IN_PROGRESS (403 Forbidden)", async () => {
      const res = await request(app)
        .patch(`/support/tickets/${ticketId}/status`)
        .set("Authorization", athlete1Token)
        .send({
          status: SupportTicketStatus.RESOLVED,
        });

      expect(res.status).toBe(403);
      expect(res.body.detail || res.body.message).toMatch(/CLOSED/i);
    });

    it("rejects an invalid status transition (400 Bad Request)", async () => {
      const res = await request(app)
        .patch(`/support/tickets/${ticketId}/status`)
        .set("Authorization", supportToken)
        .send({
          status: "INVALID_STATUS_CODE",
        });

      expect(res.status).toBe(400);
    });
  });

  describe("5. Messages & Internal Notes Privacy", () => {
    let ticketId: string;

    beforeEach(async () => {
      const res = await request(app)
        .post("/support/tickets")
        .set("Authorization", athlete1Token)
        .send({
          subject: "Weigh-in timing",
          description: "When does official weigh-in close?",
        });
      ticketId = res.body.data.id;
    });

    it("allows athlete to post a public reply to their ticket", async () => {
      const res = await request(app)
        .post(`/support/tickets/${ticketId}/messages`)
        .set("Authorization", athlete1Token)
        .send({
          message: "Also, what scale brand is being used?",
        });

      expect(res.status).toBe(201);
      expect(res.body.data.message).toBe("Also, what scale brand is being used?");
      expect(res.body.data.isInternal).toBe(false);
    });

    it("allows Support Agent to post an internal note not visible to the athlete", async () => {
      // 1. Support agent posts an internal note
      const internalRes = await request(app)
        .post(`/support/tickets/${ticketId}/messages`)
        .set("Authorization", supportToken)
        .send({
          message: "INTERNAL NOTE: Athlete has a history of border-line weigh-in disputes.",
          isInternal: true,
        });

      expect(internalRes.status).toBe(201);
      expect(internalRes.body.data.isInternal).toBe(true);

      // 2. Support agent posts a public response
      await request(app)
        .post(`/support/tickets/${ticketId}/messages`)
        .set("Authorization", supportToken)
        .send({
          message: "Official weigh-in closes at 18:00 local time.",
          isInternal: false,
        });

      // 3. Support Agent views ticket -> Sees BOTH messages (total 2)
      const agentView = await request(app)
        .get(`/support/tickets/${ticketId}`)
        .set("Authorization", supportToken);

      expect(agentView.status).toBe(200);
      expect(agentView.body.data.messages.length).toBe(2);

      // 4. Athlete views ticket -> Only sees the public message (internal note is hidden)
      const athleteView = await request(app)
        .get(`/support/tickets/${ticketId}`)
        .set("Authorization", athlete1Token);

      expect(athleteView.status).toBe(200);
      expect(athleteView.body.data.messages.length).toBe(1);
      expect(athleteView.body.data.messages[0].isInternal).toBe(false);
      expect(athleteView.body.data.messages[0].message).toBe("Official weigh-in closes at 18:00 local time.");
    });

    it("forces isInternal = false if an athlete tries to submit an internal note", async () => {
      const res = await request(app)
        .post(`/support/tickets/${ticketId}/messages`)
        .set("Authorization", athlete1Token)
        .send({
          message: "Attempting to create internal note",
          isInternal: true,
        });

      expect(res.status).toBe(201);
      expect(res.body.data.isInternal).toBe(false);
    });

    it("forbids an unrelated athlete from posting messages to the ticket (403 Forbidden)", async () => {
      const res = await request(app)
        .post(`/support/tickets/${ticketId}/messages`)
        .set("Authorization", athlete2Token)
        .send({
          message: "Unrelated message",
        });

      expect(res.status).toBe(403);
    });
  });
});
