import { describe, it, expect, beforeEach } from "vitest";
import request from "supertest";
import { testDbStore } from "./setup.js";
import { app } from "../app.js";
import { UserRole } from "@armsphere/types";
import { generateAccessToken } from "@armsphere/cryptography";
import env from "../config/env.js";

describe("Social, Follows & Teams API Suite", () => {
  let athleteUser1: any;
  let athleteToken1: string;
  let athleteUser2: any;
  let athleteToken2: string;
  let adminUser: any;
  let adminToken: string;

  const athleteUserId1 = "11111111-1111-1111-1111-111111111111";
  const athleteUserId2 = "22222222-2222-2222-2222-222222222222";
  const athleteProfileId1 = "33333333-3333-3333-3333-333333333333";
  const athleteProfileId2 = "44444444-4444-4444-4444-444444444444";
  const clubId = "88888888-8888-8888-8888-888888888888";

  beforeEach(async () => {
    // Clear the store
    testDbStore.users = [];
    testDbStore.athleteProfiles = [];
    testDbStore.athleteClubs = [];
    testDbStore.follows = [];
    testDbStore.teams = [];
    testDbStore.teamMembers = [];

    // Seed User 1 (Athlete 1)
    athleteUser1 = {
      id: athleteUserId1,
      email: "athlete1@armsphere.com",
      username: "athlete1",
      role: UserRole.ATHLETE,
      fullName: "Athlete One",
      isActive: true,
    };
    testDbStore.users.push(athleteUser1);
    athleteToken1 = `Bearer ${generateAccessToken(
      athleteUser1.id,
      athleteUser1.email,
      athleteUser1.role,
      env.JWT_ACCESS_SECRET
    )}`;

    // Seed Profile 1
    testDbStore.athleteProfiles.push({
      id: athleteProfileId1,
      userId: athleteUserId1,
      displayName: "Athlete One Profile",
      province: "Punjab",
      city: "Lahore",
      handedness: "RIGHT",
      dominantArm: "RIGHT",
      gender: "MALE",
      weightClass: "80kg",
      isDeleted: false,
    });

    // Seed User 2 (Athlete 2)
    athleteUser2 = {
      id: athleteUserId2,
      email: "athlete2@armsphere.com",
      username: "athlete2",
      role: UserRole.ATHLETE,
      fullName: "Athlete Two",
      isActive: true,
    };
    testDbStore.users.push(athleteUser2);
    athleteToken2 = `Bearer ${generateAccessToken(
      athleteUser2.id,
      athleteUser2.email,
      athleteUser2.role,
      env.JWT_ACCESS_SECRET
    )}`;

    // Seed Profile 2
    testDbStore.athleteProfiles.push({
      id: athleteProfileId2,
      userId: athleteUserId2,
      displayName: "Athlete Two Profile",
      province: "Sindh",
      city: "Karachi",
      handedness: "LEFT",
      dominantArm: "LEFT",
      gender: "MALE",
      weightClass: "90kg",
      isDeleted: false,
    });

    // Seed Admin User
    adminUser = {
      id: "admin-user-id-999",
      email: "admin@armsphere.com",
      username: "admin",
      role: UserRole.SYSTEM_ADMIN,
      fullName: "Admin User",
      isActive: true,
    };
    testDbStore.users.push(adminUser);
    adminToken = `Bearer ${generateAccessToken(
      adminUser.id,
      adminUser.email,
      adminUser.role,
      env.JWT_ACCESS_SECRET
    )}`;

    // Seed an Athlete Club
    testDbStore.athleteClubs.push({
      id: clubId,
      name: "Standard Armwrestling Club",
      city: "Lahore",
      province: "Punjab",
      isDeleted: false,
    });
  });

  describe("POST /social/follow - Follow Athlete", () => {
    it("should allow an athlete to follow another athlete profile", async () => {
      const res = await request(app)
        .post("/social/follow")
        .set("Authorization", athleteToken1)
        .send({ followingId: athleteProfileId2 });

      expect(res.status).toBe(201);
      expect(res.body.success).toBe(true);
      expect(res.body.data.followerId).toBe(athleteProfileId1);
      expect(res.body.data.followingId).toBe(athleteProfileId2);

      // Verify follow record exists in mock store
      expect(testDbStore.follows.length).toBe(1);
    });

    it("should reject self-follow with a 400 Bad Request error", async () => {
      const res = await request(app)
        .post("/social/follow")
        .set("Authorization", athleteToken1)
        .send({ followingId: athleteProfileId1 });

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
      expect(res.body.detail).toContain("You cannot follow yourself");
    });

    it("should reject duplicate follows with a 409 Conflict error", async () => {
      // Pre-seed a follow relationship
      testDbStore.follows.push({
        id: "follow-1",
        followerId: athleteProfileId1,
        followingId: athleteProfileId2,
        createdAt: new Date(),
      });

      const res = await request(app)
        .post("/social/follow")
        .set("Authorization", athleteToken1)
        .send({ followingId: athleteProfileId2 });

      expect(res.status).toBe(409);
      expect(res.body.success).toBe(false);
      expect(res.body.detail).toContain("You are already following this athlete");
    });
  });

  describe("DELETE /social/follow/:followingId - Unfollow Athlete", () => {
    it("should allow an athlete to unfollow an already followed athlete", async () => {
      // Pre-seed the follow
      testDbStore.follows.push({
        id: "follow-1",
        followerId: athleteProfileId1,
        followingId: athleteProfileId2,
        createdAt: new Date(),
      });

      const res = await request(app)
        .delete(`/social/follow/${athleteProfileId2}`)
        .set("Authorization", athleteToken1);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(testDbStore.follows.length).toBe(0);
    });

    it("should return 404 if trying to unfollow someone they do not follow", async () => {
      const res = await request(app)
        .delete(`/social/follow/${athleteProfileId2}`)
        .set("Authorization", athleteToken1);

      expect(res.status).toBe(404);
      expect(res.body.success).toBe(false);
    });
  });

  describe("GET /social/follow-status/:followingId - Follow Status Check", () => {
    it("should return isFollowing: false if not following target", async () => {
      const res = await request(app)
        .get(`/social/follow-status/${athleteProfileId2}`)
        .set("Authorization", athleteToken1);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.isFollowing).toBe(false);
    });

    it("should return isFollowing: true if currently following target", async () => {
      // Pre-seed follow
      testDbStore.follows.push({
        id: "follow-1",
        followerId: athleteProfileId1,
        followingId: athleteProfileId2,
        createdAt: new Date(),
      });

      const res = await request(app)
        .get(`/social/follow-status/${athleteProfileId2}`)
        .set("Authorization", athleteToken1);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.isFollowing).toBe(true);
    });
  });

  describe("POST /social/teams - Teams and Memberships", () => {
    it("should allow creating a team with optional club association and automatically make the creator a CAPTAIN", async () => {
      const res = await request(app)
        .post("/social/teams")
        .set("Authorization", athleteToken1)
        .send({
          name: "Lahore Lions",
          description: "Top team in Punjab",
          clubId: clubId,
        });

      expect(res.status).toBe(201);
      expect(res.body.success).toBe(true);
      expect(res.body.data.name).toBe("Lahore Lions");
      expect(res.body.data.clubId).toBe(clubId);
      expect(testDbStore.teams.length).toBe(1);

      // Verify team creator is automatically seeded as a CAPTAIN member
      expect(testDbStore.teamMembers.length).toBe(1);
      expect(testDbStore.teamMembers[0].athleteId).toBe(athleteProfileId1);
      expect(testDbStore.teamMembers[0].role).toBe("CAPTAIN");
    });

    it("should validate and add members to teams with accepted roles if requested by captain", async () => {
      // Seed a team
      const teamId = "99999999-9999-9999-9999-999999999999";
      testDbStore.teams.push({
        id: teamId,
        name: "Sindh Superstars",
        clubId: null,
      });

      // Seed Athlete 1 as CAPTAIN of this team
      testDbStore.teamMembers.push({
        id: "mem-1",
        teamId,
        athleteId: athleteProfileId1,
        role: "CAPTAIN",
        joinedAt: new Date(),
      });

      // Add member as MEMBER
      const res1 = await request(app)
        .post(`/social/teams/${teamId}/members`)
        .set("Authorization", athleteToken1)
        .send({
          athleteId: athleteProfileId2,
          role: "MEMBER",
        });

      expect(res1.status).toBe(201);
      expect(res1.body.success).toBe(true);
      expect(res1.body.data.role).toBe("MEMBER");

      // Attempt to add with invalid role
      const res2 = await request(app)
        .post(`/social/teams/${teamId}/members`)
        .set("Authorization", athleteToken1)
        .send({
          athleteId: athleteProfileId2,
          role: "COACH", // Invalid role (only MEMBER/CAPTAIN accepted by Zod)
        });

      expect(res2.status).toBe(400);
      expect(res2.body.success).toBe(false);
    });

    it("should reject non-captain, non-admin athlete with a 403 when trying to add/remove members", async () => {
      const teamId = "99999999-9999-9999-9999-999999999999";
      testDbStore.teams.push({
        id: teamId,
        name: "Sindh Superstars",
        clubId: null,
      });

      // Athlete 1 is CAPTAIN, Athlete 2 is just an athlete (not a member or captain)
      testDbStore.teamMembers.push({
        id: "mem-1",
        teamId,
        athleteId: athleteProfileId1,
        role: "CAPTAIN",
        joinedAt: new Date(),
      });

      // Athlete 2 tries to add Athlete 1 to the team
      const addRes = await request(app)
        .post(`/social/teams/${teamId}/members`)
        .set("Authorization", athleteToken2)
        .send({
          athleteId: athleteProfileId1,
          role: "MEMBER",
        });

      expect(addRes.status).toBe(403);
      expect(addRes.body.success).toBe(false);
      expect(addRes.body.detail).toContain("You must be a team captain or administrator");

      // Athlete 2 tries to remove Athlete 1 from the team
      const removeRes = await request(app)
        .delete(`/social/teams/${teamId}/members/${athleteProfileId1}`)
        .set("Authorization", athleteToken2);

      expect(removeRes.status).toBe(403);
      expect(removeRes.body.success).toBe(false);
      expect(removeRes.body.detail).toContain("You must be a team captain or administrator");
    });

    it("should allow a CAPTAIN of that specific team to add/remove members successfully", async () => {
      const teamId = "99999999-9999-9999-9999-999999999999";
      testDbStore.teams.push({
        id: teamId,
        name: "Sindh Superstars",
        clubId: null,
      });

      // Athlete 1 is CAPTAIN
      testDbStore.teamMembers.push({
        id: "mem-1",
        teamId,
        athleteId: athleteProfileId1,
        role: "CAPTAIN",
        joinedAt: new Date(),
      });

      // Add Athlete 2 as member
      const addRes = await request(app)
        .post(`/social/teams/${teamId}/members`)
        .set("Authorization", athleteToken1)
        .send({
          athleteId: athleteProfileId2,
          role: "MEMBER",
        });

      expect(addRes.status).toBe(201);
      expect(addRes.body.success).toBe(true);

      // Remove Athlete 2
      const removeRes = await request(app)
        .delete(`/social/teams/${teamId}/members/${athleteProfileId2}`)
        .set("Authorization", athleteToken1);

      expect(removeRes.status).toBe(200);
      expect(removeRes.body.success).toBe(true);
    });

    it("should allow an admin-tier user to add/remove members on a team they're not part of", async () => {
      const teamId = "99999999-9999-9999-9999-999999999999";
      testDbStore.teams.push({
        id: teamId,
        name: "Sindh Superstars",
        clubId: null,
      });

      // Add Athlete 2 as member via Admin
      const addRes = await request(app)
        .post(`/social/teams/${teamId}/members`)
        .set("Authorization", adminToken)
        .send({
          athleteId: athleteProfileId2,
          role: "MEMBER",
        });

      expect(addRes.status).toBe(201);
      expect(addRes.body.success).toBe(true);

      // Remove Athlete 2 via Admin
      const removeRes = await request(app)
        .delete(`/social/teams/${teamId}/members/${athleteProfileId2}`)
        .set("Authorization", adminToken);

      expect(removeRes.status).toBe(200);
      expect(removeRes.body.success).toBe(true);
    });
  });

  describe("Blocking API & Enforcement", () => {
    it("should allow a user to block and unblock another user", async () => {
      // 1. Block User 2
      const blockRes = await request(app)
        .post(`/social/block/${athleteProfileId2}`)
        .set("Authorization", athleteToken1);

      expect(blockRes.status).toBe(201);
      expect(blockRes.body.success).toBe(true);
      expect(testDbStore.blockedUsers.length).toBe(1);
      expect(testDbStore.blockedUsers[0].blockerId).toBe(athleteProfileId1);
      expect(testDbStore.blockedUsers[0].blockedId).toBe(athleteProfileId2);

      // 2. Get blocked list
      const listRes = await request(app)
        .get("/social/blocked")
        .set("Authorization", athleteToken1);

      expect(listRes.status).toBe(200);
      expect(listRes.body.success).toBe(true);
      expect(listRes.body.data.length).toBe(1);
      expect(listRes.body.data[0].id).toBe(athleteProfileId2);

      // 3. Unblock User 2
      const unblockRes = await request(app)
        .delete(`/social/block/${athleteProfileId2}`)
        .set("Authorization", athleteToken1);

      expect(unblockRes.status).toBe(200);
      expect(unblockRes.body.success).toBe(true);
      expect(testDbStore.blockedUsers.length).toBe(0);
    });

    it("should enforce blocking on starting conversation and sending messages in both directions", async () => {
      // Seed a block: User 1 blocks User 2
      testDbStore.blockedUsers.push({
        id: "block-1",
        blockerId: athleteProfileId1,
        blockedId: athleteProfileId2,
        createdAt: new Date(),
      });

      // 1. User 1 tries to start conversation with User 2
      const convRes1 = await request(app)
        .post("/communication/conversations")
        .set("Authorization", athleteToken1)
        .send({ participantId: athleteUserId2, type: "DIRECT" });

      expect(convRes1.status).toBe(403);

      // 2. User 2 tries to start conversation with User 1
      const convRes2 = await request(app)
        .post("/communication/conversations")
        .set("Authorization", athleteToken2)
        .send({ participantId: athleteUserId1, type: "DIRECT" });

      expect(convRes2.status).toBe(403);

      // Seed a conversation between the two users
      const convId = "conv-123";
      testDbStore.conversations.push({ id: convId, type: "DIRECT" });
      testDbStore.conversationParticipants.push(
        { id: "cp-1", conversationId: convId, userId: athleteUserId1 },
        { id: "cp-2", conversationId: convId, userId: athleteUserId2 }
      );

      // 3. User 1 tries to send a message to User 2
      const msgRes1 = await request(app)
        .post(`/communication/conversations/${convId}/messages`)
        .set("Authorization", athleteToken1)
        .send({ content: "Hello" });

      expect(msgRes1.status).toBe(403);

      // 4. User 2 tries to send a message to User 1
      const msgRes2 = await request(app)
        .post(`/communication/conversations/${convId}/messages`)
        .set("Authorization", athleteToken2)
        .send({ content: "Hi" });

      expect(msgRes2.status).toBe(403);
    });

    it("should exclude blocked user's posts from the blocker's feed", async () => {
      // Seed posts from both User 1 and User 2
      testDbStore.communityPosts.push(
        {
          id: "post-1",
          athleteId: athleteProfileId1,
          caption: "Post from Athlete One",
          moderationStatus: "APPROVED",
          isDeleted: false,
          createdAt: new Date(),
        },
        {
          id: "post-2",
          athleteId: athleteProfileId2,
          caption: "Post from Athlete Two",
          moderationStatus: "APPROVED",
          isDeleted: false,
          createdAt: new Date(Date.now() - 10000),
        }
      );

      // Seed a block: User 1 blocks User 2
      testDbStore.blockedUsers.push({
        id: "block-1",
        blockerId: athleteProfileId1,
        blockedId: athleteProfileId2,
        createdAt: new Date(),
      });

      // Fetch feed as User 1
      const feedRes = await request(app)
        .get("/community/feed")
        .set("Authorization", athleteToken1);

      expect(feedRes.status).toBe(200);
      expect(feedRes.body.success).toBe(true);
      // User 2's post should be excluded
      expect(feedRes.body.data.length).toBe(1);
      expect(feedRes.body.data[0].id).toBe("post-1");
    });
  });
});
