import { describe, it, expect, beforeEach } from "vitest";
import request from "supertest";
import { testDbStore } from "./setup.js";
import { app } from "../app.js";
import { UserRole, SparringInviteStatus } from "@armsphere/types";
import { generateAccessToken } from "@armsphere/cryptography";
import { v4 as uuidv4 } from "uuid";
import env from "../config/env.js";

describe("Organization Leader / Sparring Invites API & Lifecycle", () => {
  const leaderUser1Id = uuidv4();
  const leaderUser2Id = uuidv4();
  const randomUserId = uuidv4();
  const adminUserId = uuidv4();

  const athlete1Id = uuidv4();
  const athlete2Id = uuidv4();
  const randomAthleteId = uuidv4();

  const team1Id = uuidv4();
  const team2Id = uuidv4();
  const team3Id = uuidv4();

  let leader1Token: string;
  let leader2Token: string;
  let randomUserToken: string;
  let adminToken: string;

  beforeEach(() => {
    testDbStore.users = [];
    testDbStore.athleteProfiles = [];
    testDbStore.teams = [];
    testDbStore.teamMembers = [];
    testDbStore.sparringInvites = [];
    testDbStore.auditEvents = [];
    testDbStore.notifications = [];
    testDbStore.conversations = [];
    testDbStore.conversationParticipants = [];
    testDbStore.messages = [];

    // 1. Seed Users
    const leader1 = {
      id: leaderUser1Id,
      email: "leader1@punjab-pullers.test",
      username: "punjab_captain",
      role: UserRole.ORGANIZATION_LEADER,
      fullName: "Captain Haris (Punjab Pullers)",
      isActive: true,
    };

    const leader2 = {
      id: leaderUser2Id,
      email: "leader2@karachi-grippers.test",
      username: "karachi_captain",
      role: UserRole.ORGANIZATION_LEADER,
      fullName: "Captain Tariq (Karachi Grippers)",
      isActive: true,
    };

    const randomUser = {
      id: randomUserId,
      email: "regular@armsphere.test",
      username: "regular_athlete",
      role: UserRole.ATHLETE,
      fullName: "Bilal Contender",
      isActive: true,
    };

    const adminUser = {
      id: adminUserId,
      email: "admin@armsphere.test",
      username: "system_admin",
      role: UserRole.SYSTEM_ADMIN,
      fullName: "System Admin",
      isActive: true,
    };

    testDbStore.users.push(leader1, leader2, randomUser, adminUser);

    // 2. Seed Athlete Profiles
    testDbStore.athleteProfiles.push(
      { id: athlete1Id, userId: leaderUser1Id, displayName: "Haris Leader", province: "Punjab" },
      { id: athlete2Id, userId: leaderUser2Id, displayName: "Tariq Leader", province: "Sindh" },
      { id: randomAthleteId, userId: randomUserId, displayName: "Bilal Contender", province: "Punjab" }
    );

    // 3. Seed Teams
    testDbStore.teams.push(
      { id: team1Id, name: "Lahore Iron Arms", province: "Punjab", city: "Lahore" },
      { id: team2Id, name: "Karachi Steel Grippers", province: "Sindh", city: "Karachi" },
      { id: team3Id, name: "Islamabad Titans", province: "Islamabad", city: "Islamabad" }
    );

    // 4. Seed Team Memberships (Captains)
    testDbStore.teamMembers.push(
      { id: uuidv4(), teamId: team1Id, athleteId: athlete1Id, role: "CAPTAIN" },
      { id: uuidv4(), teamId: team2Id, athleteId: athlete2Id, role: "CAPTAIN" },
      { id: uuidv4(), teamId: team3Id, athleteId: randomAthleteId, role: "MEMBER" }
    );

    // 5. Generate Auth Tokens
    leader1Token = `Bearer ${generateAccessToken(leaderUser1Id, leader1.email, leader1.role, env.JWT_ACCESS_SECRET)}`;
    leader2Token = `Bearer ${generateAccessToken(leaderUser2Id, leader2.email, leader2.role, env.JWT_ACCESS_SECRET)}`;
    randomUserToken = `Bearer ${generateAccessToken(randomUserId, randomUser.email, randomUser.role, env.JWT_ACCESS_SECRET)}`;
    adminToken = `Bearer ${generateAccessToken(adminUserId, adminUser.email, adminUser.role, env.JWT_ACCESS_SECRET)}`;
  });

  describe("1. Sparring Invitation Creation & Invariants", () => {
    it("allows a team leader to dispatch a sparring invitation to another organization (201 Created)", async () => {
      const res = await request(app)
        .post("/sparring-invites")
        .set("Authorization", leader1Token)
        .send({
          senderTeamId: team1Id,
          recipientTeamId: team2Id,
          scheduledDate: new Date(Date.now() + 86400000 * 3).toISOString(),
          location: "Lahore Combat Center Table 1",
          message: "Friendly 5v5 supermatch sparring before the National Championship.",
        });

      expect(res.status).toBe(201);
      expect(res.body.success).toBe(true);
      expect(res.body.data).toBeDefined();
      expect(res.body.data.id).toBeDefined();
      expect(res.body.data.senderTeamId).toBe(team1Id);
      expect(res.body.data.recipientTeamId).toBe(team2Id);
      expect(res.body.data.status).toBe(SparringInviteStatus.PENDING);
      expect(res.body.data.senderTeam.name).toBe("Lahore Iron Arms");
      expect(res.body.data.recipientTeam.name).toBe("Karachi Steel Grippers");

      // Verify audit event was logged
      const auditLog = testDbStore.auditEvents.find((e) => e.action === "SPARRING_INVITE_CREATED");
      expect(auditLog).toBeDefined();
      expect(auditLog.actorId).toBe(leaderUser1Id);
    });

    it("rejects invitation creation if sender and recipient teams are identical (400 Bad Request)", async () => {
      const res = await request(app)
        .post("/sparring-invites")
        .set("Authorization", leader1Token)
        .send({
          senderTeamId: team1Id,
          recipientTeamId: team1Id,
          message: "Self match",
        });

      expect(res.status).toBe(400);
      expect((res.body.detail || res.body.message)).toContain("own organization");
    });

    it("rejects duplicate PENDING invitation between the same organizations (409 Conflict)", async () => {
      // First invite
      await request(app)
        .post("/sparring-invites")
        .set("Authorization", leader1Token)
        .send({
          senderTeamId: team1Id,
          recipientTeamId: team2Id,
          message: "First invite",
        });

      // Second duplicate invite
      const res = await request(app)
        .post("/sparring-invites")
        .set("Authorization", leader1Token)
        .send({
          senderTeamId: team1Id,
          recipientTeamId: team2Id,
          message: "Second duplicate invite",
        });

      expect(res.status).toBe(409);
      expect((res.body.detail || res.body.message)).toContain("already exists");
    });

    it("forbids an unauthorized regular member from creating an invitation on behalf of a team (403 Forbidden)", async () => {
      const res = await request(app)
        .post("/sparring-invites")
        .set("Authorization", randomUserToken)
        .send({
          senderTeamId: team3Id,
          recipientTeamId: team1Id,
          message: "Unauthorized invitation attempt",
        });

      expect(res.status).toBe(403);
      expect((res.body.detail || res.body.message)).toContain("not authorized");
    });

    it("returns 404 if sending or recipient organization does not exist", async () => {
      const res = await request(app)
        .post("/sparring-invites")
        .set("Authorization", leader1Token)
        .send({
          senderTeamId: team1Id,
          recipientTeamId: uuidv4(),
          message: "Ghost team invite",
        });

      expect(res.status).toBe(404);
      expect((res.body.detail || res.body.message)).toContain("organization not found");
    });
  });

  describe("2. Listing Sparring Invitations & Scoping", () => {
    let invite1Id: string;
    let invite2Id: string;

    beforeEach(async () => {
      // Create invite from Team 1 to Team 2
      const res1 = await request(app)
        .post("/sparring-invites")
        .set("Authorization", leader1Token)
        .send({
          senderTeamId: team1Id,
          recipientTeamId: team2Id,
          message: "Team 1 -> Team 2",
        });
      invite1Id = res1.body.data.id;

      // Seed another invite from Team 2 to Team 3 directly into store
      invite2Id = uuidv4();
      testDbStore.sparringInvites.push({
        id: invite2Id,
        senderTeamId: team2Id,
        recipientTeamId: team3Id,
        creatorId: leaderUser2Id,
        status: SparringInviteStatus.PENDING,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
      });
    });

    it("allows a team leader to list all invites sent or received by their organization", async () => {
      const res = await request(app)
        .get("/sparring-invites")
        .set("Authorization", leader1Token);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(Array.isArray(res.body.data)).toBe(true);
      expect(res.body.data.length).toBeGreaterThanOrEqual(1);

      const found = res.body.data.find((i: any) => i.id === invite1Id);
      expect(found).toBeDefined();
      expect(found.senderTeamName).toBe("Lahore Iron Arms");
      expect(found.recipientTeamName).toBe("Karachi Steel Grippers");
    });

    it("allows filtering invites by direction ('sent' vs 'received')", async () => {
      const resSent = await request(app)
        .get(`/sparring-invites?teamId=${team1Id}&direction=sent`)
        .set("Authorization", leader1Token);

      expect(resSent.status).toBe(200);
      const sentItem = resSent.body.data.find((i: any) => i.id === invite1Id);
      expect(sentItem).toBeDefined();

      const resReceived = await request(app)
        .get(`/sparring-invites?teamId=${team1Id}&direction=received`)
        .set("Authorization", leader1Token);

      expect(resReceived.status).toBe(200);
      const receivedItem = resReceived.body.data.find((i: any) => i.id === invite1Id);
      expect(receivedItem).toBeUndefined();
    });

    it("forbids unauthorized regular athlete from viewing invites of a team they do not lead (403 Forbidden)", async () => {
      const res = await request(app)
        .get(`/sparring-invites?teamId=${team1Id}`)
        .set("Authorization", randomUserToken);

      expect(res.status).toBe(403);
    });

    it("allows System Admin to view invitations across all organizations", async () => {
      const res = await request(app)
        .get("/sparring-invites")
        .set("Authorization", adminToken);

      expect(res.status).toBe(200);
      expect(res.body.data.length).toBe(2);
    });
  });

  describe("3. Getting Sparring Invite Details", () => {
    let inviteId: string;

    beforeEach(async () => {
      const res = await request(app)
        .post("/sparring-invites")
        .set("Authorization", leader1Token)
        .send({
          senderTeamId: team1Id,
          recipientTeamId: team2Id,
          location: "Lahore Stadium",
          message: "Detailed invite",
        });
      inviteId = res.body.data.id;
    });

    it("allows sender and recipient participants to retrieve invite details with enriched team metadata", async () => {
      const res = await request(app)
        .get(`/sparring-invites/${inviteId}`)
        .set("Authorization", leader2Token);

      expect(res.status).toBe(200);
      expect(res.body.data.id).toBe(inviteId);
      expect(res.body.data.senderTeam.id).toBe(team1Id);
      expect(res.body.data.recipientTeam.id).toBe(team2Id);
    });

    it("forbids an uninvolved athlete from viewing invite details (403 Forbidden)", async () => {
      const res = await request(app)
        .get(`/sparring-invites/${inviteId}`)
        .set("Authorization", randomUserToken);

      expect(res.status).toBe(403);
    });

    it("returns 404 for non-existent invite ID", async () => {
      const res = await request(app)
        .get(`/sparring-invites/${uuidv4()}`)
        .set("Authorization", leader1Token);

      expect(res.status).toBe(404);
    });
  });

  describe("4. Responding to Sparring Invites (ACCEPT / DECLINE)", () => {
    let inviteId: string;

    beforeEach(async () => {
      const res = await request(app)
        .post("/sparring-invites")
        .set("Authorization", leader1Token)
        .send({
          senderTeamId: team1Id,
          recipientTeamId: team2Id,
          message: "Will you spar with us?",
        });
      inviteId = res.body.data.id;
    });

    it("allows recipient organization leader to ACCEPT an invitation, establishing direct conversation and updating status (200 OK)", async () => {
      const res = await request(app)
        .post(`/sparring-invites/${inviteId}/respond`)
        .set("Authorization", leader2Token)
        .send({ action: "ACCEPT" });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.status).toBe(SparringInviteStatus.ACCEPTED);
      expect(res.body.data.responderId).toBe(leaderUser2Id);
      expect(res.body.data.respondedAt).toBeDefined();

      // Verify audit log
      const auditLog = testDbStore.auditEvents.find((e) => e.action === "SPARRING_INVITE_ACCEPTED");
      expect(auditLog).toBeDefined();
      expect(auditLog.actorId).toBe(leaderUser2Id);
    });

    it("allows recipient organization leader to DECLINE an invitation (200 OK)", async () => {
      const res = await request(app)
        .post(`/sparring-invites/${inviteId}/respond`)
        .set("Authorization", leader2Token)
        .send({ action: "DECLINE" });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.status).toBe(SparringInviteStatus.DECLINED);
      expect(res.body.data.responderId).toBe(leaderUser2Id);

      // Verify audit log
      const auditLog = testDbStore.auditEvents.find((e) => e.action === "SPARRING_INVITE_DECLINED");
      expect(auditLog).toBeDefined();
    });

    it("forbids sender from responding to their own invitation (403 Forbidden)", async () => {
      const res = await request(app)
        .post(`/sparring-invites/${inviteId}/respond`)
        .set("Authorization", leader1Token)
        .send({ action: "ACCEPT" });

      expect(res.status).toBe(403);
      expect((res.body.detail || res.body.message)).toContain("recipient organization");
    });

    it("cannot respond to an invitation that is already accepted or declined (400 Bad Request)", async () => {
      // First acceptance
      await request(app)
        .post(`/sparring-invites/${inviteId}/respond`)
        .set("Authorization", leader2Token)
        .send({ action: "ACCEPT" });

      // Second attempt to decline
      const res = await request(app)
        .post(`/sparring-invites/${inviteId}/respond`)
        .set("Authorization", leader2Token)
        .send({ action: "DECLINE" });

      expect(res.status).toBe(400);
      expect((res.body.detail || res.body.message)).toContain("ACCEPTED status");
    });
  });

  describe("5. Cancelling Sparring Invites (Sender Only)", () => {
    let inviteId: string;

    beforeEach(async () => {
      const res = await request(app)
        .post("/sparring-invites")
        .set("Authorization", leader1Token)
        .send({
          senderTeamId: team1Id,
          recipientTeamId: team2Id,
          message: "Pending cancellation test",
        });
      inviteId = res.body.data.id;
    });

    it("allows sender leader to cancel a pending invitation (200 OK)", async () => {
      const res = await request(app)
        .post(`/sparring-invites/${inviteId}/cancel`)
        .set("Authorization", leader1Token);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.status).toBe(SparringInviteStatus.CANCELLED);

      // Verify audit log
      const auditLog = testDbStore.auditEvents.find((e) => e.action === "SPARRING_INVITE_CANCELLED");
      expect(auditLog).toBeDefined();
    });

    it("forbids recipient from cancelling sender's invitation (403 Forbidden)", async () => {
      const res = await request(app)
        .post(`/sparring-invites/${inviteId}/cancel`)
        .set("Authorization", leader2Token);

      expect(res.status).toBe(403);
      expect((res.body.detail || res.body.message)).toContain("sending organization");
    });

    it("cannot cancel an invitation that is already cancelled or resolved (400 Bad Request)", async () => {
      await request(app)
        .post(`/sparring-invites/${inviteId}/cancel`)
        .set("Authorization", leader1Token);

      const res = await request(app)
        .post(`/sparring-invites/${inviteId}/cancel`)
        .set("Authorization", leader1Token);

      expect(res.status).toBe(400);
      expect((res.body.detail || res.body.message)).toContain("CANCELLED status");
    });
  });
});
