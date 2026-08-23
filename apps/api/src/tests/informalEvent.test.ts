import { describe, it, expect, beforeEach } from "vitest";
import request from "supertest";
import { testDbStore } from "./setup.js";
import { app } from "../app.js";
import { UserRole } from "@armsphere/types";
import { generateAccessToken } from "@armsphere/cryptography";
import env from "../config/env.js";

describe("Informal Events API Suite", () => {
  let user1: any;
  let user1Token: string;
  let user2: any;
  let user2Token: string;
  let adminUser: any;
  let adminToken: string;

  const user1Id = "11111111-1111-1111-1111-111111111111";
  const user2Id = "22222222-2222-2222-2222-222222222222";
  const adminUserId = "55555555-5555-5555-5555-555555555555";

  beforeEach(() => {
    testDbStore.users = [];
    testDbStore.athleteProfiles = [];
    testDbStore.informalEvents = [];
    testDbStore.informalEventParticipants = [];

    // Seed User 1 (Regular Athlete)
    user1 = {
      id: user1Id,
      email: "user1@armsphere.com",
      username: "user1",
      role: UserRole.ATHLETE,
      fullName: "User One",
      isActive: true,
    };
    testDbStore.users.push(user1);
    testDbStore.athleteProfiles.push({
      id: "prof-1",
      userId: user1Id,
      displayName: "User One Profile",
      province: "Alberta",
      city: "Calgary",
      profilePhoto: "http://example.com/photo1.jpg",
    });
    user1Token = `Bearer ${generateAccessToken(
      user1.id,
      user1.email,
      user1.role,
      env.JWT_ACCESS_SECRET
    )}`;

    // Seed User 2 (Another Athlete)
    user2 = {
      id: user2Id,
      email: "user2@armsphere.com",
      username: "user2",
      role: UserRole.ATHLETE,
      fullName: "User Two",
      isActive: true,
    };
    testDbStore.users.push(user2);
    testDbStore.athleteProfiles.push({
      id: "prof-2",
      userId: user2Id,
      displayName: "User Two Profile",
      province: "Alberta",
      city: "Calgary",
      profilePhoto: "http://example.com/photo2.jpg",
    });
    user2Token = `Bearer ${generateAccessToken(
      user2.id,
      user2.email,
      user2.role,
      env.JWT_ACCESS_SECRET
    )}`;

    // Seed Admin User
    adminUser = {
      id: adminUserId,
      email: "admin@armsphere.com",
      username: "admin123",
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
  });

  describe("POST /informal-events - Create Event", () => {
    it("should reject unauthenticated submissions", async () => {
      const response = await request(app)
        .post("/informal-events")
        .send({
          title: "Calgary Armwrestling Pickup",
          description: "Come practice high hook techniques!",
          city: "Calgary",
          province: "Alberta",
          scheduledAt: new Date(Date.now() + 86400000).toISOString(),
        });

      expect(response.status).toBe(401);
    });

    it("should allow authenticated users to create an event and make them first participant", async () => {
      const futureDate = new Date(Date.now() + 86400000).toISOString();
      const response = await request(app)
        .post("/informal-events")
        .set("Authorization", user1Token)
        .send({
          title: "Calgary Armwrestling Practice",
          description: "Practice hook and top roll.",
          city: "Calgary",
          province: "Alberta",
          scheduledAt: futureDate,
          maxParticipants: 10,
          isPublic: true,
        });

      expect(response.status).toBe(201);
      expect(response.body.success).toBe(true);
      expect(response.body.data.title).toBe("Calgary Armwrestling Practice");
      expect(response.body.data.createdByUserId).toBe(user1Id);

      // Verify participant was added
      expect(testDbStore.informalEventParticipants.length).toBe(1);
      expect(testDbStore.informalEventParticipants[0].userId).toBe(user1Id);
      expect(testDbStore.informalEventParticipants[0].informalEventId).toBe(response.body.data.id);
    });

    it("should reject creation if scheduledAt is in the past", async () => {
      const pastDate = new Date(Date.now() - 86400000).toISOString();
      const response = await request(app)
        .post("/informal-events")
        .set("Authorization", user1Token)
        .send({
          title: "Calgary Armwrestling Practice",
          description: "Practice hook and top roll.",
          city: "Calgary",
          province: "Alberta",
          scheduledAt: pastDate,
        });

      expect(response.status).toBe(400);
      expect(response.body.detail).toContain("Scheduled time must be in the future");
    });
  });

  describe("GET /informal-events - List Events", () => {
    beforeEach(() => {
      testDbStore.informalEvents = [
        {
          id: "event-1",
          createdByUserId: user1Id,
          title: "Calgary Open Table",
          description: "Friendly pull and talk tech.",
          city: "Calgary",
          province: "Alberta",
          scheduledAt: new Date(Date.now() + 86400000), // future
          maxParticipants: 5,
          isPublic: true,
        },
        {
          id: "event-2",
          createdByUserId: user2Id,
          title: "Edmonton Table Practice",
          description: "Heavy hook training.",
          city: "Edmonton",
          province: "Alberta",
          scheduledAt: new Date(Date.now() + 172800000), // future
          maxParticipants: 10,
          isPublic: true,
        },
        {
          id: "event-3",
          createdByUserId: user1Id,
          title: "Private Club Practice",
          description: "Club members only.",
          city: "Calgary",
          province: "Alberta",
          scheduledAt: new Date(Date.now() + 86400000),
          maxParticipants: 5,
          isPublic: false,
        },
      ];

      testDbStore.informalEventParticipants = [
        { id: "p-1", informalEventId: "event-1", userId: user1Id },
        { id: "p-2", informalEventId: "event-2", userId: user2Id },
      ];
    });

    it("should return public events list only", async () => {
      const response = await request(app).get("/informal-events");

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data.length).toBe(2); // event-1 and event-2, not event-3
      expect(response.body.data[0].participantCount).toBeDefined();
    });

    it("should support city filtering", async () => {
      const response = await request(app)
        .get("/informal-events")
        .query({ city: "Edmonton" });

      expect(response.status).toBe(200);
      expect(response.body.data.length).toBe(1);
      expect(response.body.data[0].id).toBe("event-2");
    });
  });

  describe("GET /informal-events/:id - Event Details", () => {
    beforeEach(() => {
      testDbStore.informalEvents = [
        {
          id: "event-1",
          createdByUserId: user1Id,
          title: "Calgary Open Table",
          description: "Friendly pull and talk tech.",
          city: "Calgary",
          province: "Alberta",
          scheduledAt: new Date(Date.now() + 86400000),
          maxParticipants: 5,
          isPublic: true,
        },
      ];

      testDbStore.informalEventParticipants = [
        { id: "p-1", informalEventId: "event-1", userId: user1Id },
        { id: "p-2", informalEventId: "event-1", userId: user2Id },
      ];
    });

    it("should return detailed view with participant list names and avatars", async () => {
      const response = await request(app).get("/informal-events/event-1");

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data.title).toBe("Calgary Open Table");
      expect(response.body.data.participants).toBeDefined();
      expect(response.body.data.participants.length).toBe(2);
      expect(response.body.data.participants[0].fullName).toBe("User One");
      expect(response.body.data.participants[0].profilePhoto).toBe("http://example.com/photo1.jpg");
    });
  });

  describe("POST /informal-events/:id/join - Join Event", () => {
    beforeEach(() => {
      testDbStore.informalEvents = [
        {
          id: "event-1",
          createdByUserId: user1Id,
          title: "Calgary Open Table",
          description: "Friendly pull and talk tech.",
          city: "Calgary",
          province: "Alberta",
          scheduledAt: new Date(Date.now() + 86400000),
          maxParticipants: 2,
          isPublic: true,
        },
        {
          id: "event-past",
          createdByUserId: user1Id,
          title: "Past Table",
          description: "Pull in the past.",
          city: "Calgary",
          province: "Alberta",
          scheduledAt: new Date(Date.now() - 86400000),
          maxParticipants: 5,
          isPublic: true,
        },
      ];

      testDbStore.informalEventParticipants = [
        { id: "p-1", informalEventId: "event-1", userId: user1Id },
      ];
    });

    it("should allow a user to join an event successfully", async () => {
      const response = await request(app)
        .post("/informal-events/event-1/join")
        .set("Authorization", user2Token);

      expect(response.status).toBe(201);
      expect(response.body.success).toBe(true);
    });

    it("should reject if already joined", async () => {
      const response = await request(app)
        .post("/informal-events/event-1/join")
        .set("Authorization", user1Token);

      expect(response.status).toBe(400);
      expect(response.body.detail).toContain("You have already joined this event");
    });

    it("should reject if event has reached capacity limit", async () => {
      // Seed another participant so capacity (2) is reached
      testDbStore.informalEventParticipants.push({
        id: "p-extra",
        informalEventId: "event-1",
        userId: "some-other-user",
      });

      const response = await request(app)
        .post("/informal-events/event-1/join")
        .set("Authorization", user2Token);

      expect(response.status).toBe(400);
      expect(response.body.detail).toContain("reached its maximum participant limit");
    });

    it("should reject if event has already occurred", async () => {
      const response = await request(app)
        .post("/informal-events/event-past/join")
        .set("Authorization", user2Token);

      expect(response.status).toBe(400);
      expect(response.body.detail).toContain("Cannot join an event that has already occurred");
    });
  });

  describe("DELETE /informal-events/:id/leave - Leave Event", () => {
    beforeEach(() => {
      testDbStore.informalEvents = [
        {
          id: "event-1",
          createdByUserId: user1Id,
          title: "Calgary Open Table",
          description: "Friendly pull and talk tech.",
          city: "Calgary",
          province: "Alberta",
          scheduledAt: new Date(Date.now() + 86400000),
          maxParticipants: 5,
          isPublic: true,
        },
      ];

      testDbStore.informalEventParticipants = [
        { id: "p-1", informalEventId: "event-1", userId: user1Id },
        { id: "p-2", informalEventId: "event-1", userId: user2Id },
      ];
    });

    it("should allow participant to leave event", async () => {
      const response = await request(app)
        .delete("/informal-events/event-1/leave")
        .set("Authorization", user2Token);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
    });

    it("should reject creator from leaving", async () => {
      const response = await request(app)
        .delete("/informal-events/event-1/leave")
        .set("Authorization", user1Token);

      expect(response.status).toBe(400);
      expect(response.body.detail).toContain("Creator cannot leave their own event");
    });
  });

  describe("DELETE /informal-events/:id - Delete/Cancel Event", () => {
    beforeEach(() => {
      testDbStore.informalEvents = [
        {
          id: "event-1",
          createdByUserId: user1Id,
          title: "Calgary Open Table",
          description: "Friendly pull and talk tech.",
          city: "Calgary",
          province: "Alberta",
          scheduledAt: new Date(Date.now() + 86400000),
          maxParticipants: 5,
          isPublic: true,
        },
      ];
    });

    it("should allow creator to delete event", async () => {
      const response = await request(app)
        .delete("/informal-events/event-1")
        .set("Authorization", user1Token);

      expect(response.status).toBe(200);
      expect(testDbStore.informalEvents.length).toBe(0);
    });

    it("should allow admin to delete event", async () => {
      const response = await request(app)
        .delete("/informal-events/event-1")
        .set("Authorization", adminToken);

      expect(response.status).toBe(200);
      expect(testDbStore.informalEvents.length).toBe(0);
    });

    it("should reject non-creator/non-admin from deleting event", async () => {
      const response = await request(app)
        .delete("/informal-events/event-1")
        .set("Authorization", user2Token);

      expect(response.status).toBe(403);
      expect(testDbStore.informalEvents.length).toBe(1);
    });
  });
});
