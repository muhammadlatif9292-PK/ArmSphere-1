import { describe, it, expect, beforeEach } from "vitest";
import request from "supertest";
import { testDbStore } from "./setup.js";
import { app } from "../app.js";
import { UserRole } from "@armsphere/types";
import { generateAccessToken } from "@armsphere/cryptography";
import env from "../config/env.js";

describe("Talent Nominations API Suite", () => {
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
    testDbStore.talentNominations = [];

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

  describe("POST /nominations - Submit Nomination", () => {
    it("should reject unauthenticated submissions on the versioned API contract", async () => {
      const response = await request(app)
        .post("/api/v1/nominations")
        .send({
          nomineeName: "John Smith",
          city: "Calgary",
          province: "Alberta",
        });

      expect(response.status).toBe(401);
    });

    it("should reject unauthenticated submissions", async () => {
      const response = await request(app)
        .post("/nominations")
        .send({
          nomineeName: "John Smith",
          city: "Calgary",
          province: "Alberta",
        });

      expect(response.status).toBe(401);
    });

    it("should allow authenticated users to submit a nomination, defaulting status to PENDING", async () => {
      const response = await request(app)
        .post("/nominations")
        .set("Authorization", user1Token)
        .send({
          nomineeName: "John Smith",
          nomineeContact: "john@smith.com",
          city: "Calgary",
          province: "Alberta",
          notes: "Incredible grip strength!",
        });

      expect(response.status).toBe(201);
      expect(response.body.success).toBe(true);
      expect(response.body.data).toBeDefined();
      expect(response.body.data.nomineeName).toBe("John Smith");
      expect(response.body.data.status).toBe("PENDING");
      expect(response.body.data.nominatedByUserId).toBe(user1Id);
    });

    it("should reject submissions with missing mandatory fields", async () => {
      const response = await request(app)
        .post("/nominations")
        .set("Authorization", user1Token)
        .send({
          nomineeName: "",
          city: "Calgary",
          province: "Alberta",
        });

      expect(response.status).toBe(400);
    });
  });

  describe("GET /nominations - List All (Admins Only)", () => {
    beforeEach(() => {
      testDbStore.talentNominations = [
        {
          id: "nom-1",
          nominatedByUserId: user1Id,
          nomineeName: "Nominee A",
          city: "Calgary",
          province: "Alberta",
          status: "PENDING",
        },
        {
          id: "nom-2",
          nominatedByUserId: user2Id,
          nomineeName: "Nominee B",
          city: "Vancouver",
          province: "British Columbia",
          status: "CONTACTED",
        },
      ];
    });

    it("should reject access to regular users", async () => {
      const response = await request(app)
        .get("/nominations")
        .set("Authorization", user1Token);

      expect(response.status).toBe(403);
    });

    it("should allow admins to list all nominations", async () => {
      const response = await request(app)
        .get("/nominations")
        .set("Authorization", adminToken);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data.length).toBe(2);
    });

    it("should allow admins to filter nominations by status", async () => {
      const response = await request(app)
        .get("/nominations")
        .query({ status: "CONTACTED" })
        .set("Authorization", adminToken);

      expect(response.status).toBe(200);
      expect(response.body.data.length).toBe(1);
      expect(response.body.data[0].id).toBe("nom-2");
    });
  });

  describe("GET /nominations/mine - List My Submissions", () => {
    beforeEach(() => {
      testDbStore.talentNominations = [
        {
          id: "nom-1",
          nominatedByUserId: user1Id,
          nomineeName: "Nominee A",
          city: "Calgary",
          province: "Alberta",
          status: "PENDING",
        },
        {
          id: "nom-2",
          nominatedByUserId: user2Id,
          nomineeName: "Nominee B",
          city: "Vancouver",
          province: "British Columbia",
          status: "CONTACTED",
        },
      ];
    });

    it("should allow regular users to retrieve only their own nominations", async () => {
      const response = await request(app)
        .get("/nominations/mine")
        .set("Authorization", user1Token);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data.length).toBe(1);
      expect(response.body.data[0].id).toBe("nom-1");
      expect(response.body.data[0].nominatedByUserId).toBe(user1Id);
    });
  });

  describe("PATCH /nominations/:id/status - Update Status", () => {
    beforeEach(() => {
      testDbStore.talentNominations = [
        {
          id: "nom-1",
          nominatedByUserId: user1Id,
          nomineeName: "Nominee A",
          city: "Calgary",
          province: "Alberta",
          status: "PENDING",
        },
      ];
    });

    it("should reject non-admin status changes", async () => {
      const response = await request(app)
        .patch("/nominations/nom-1/status")
        .set("Authorization", user1Token)
        .send({ status: "CONTACTED" });

      expect(response.status).toBe(403);
    });

    it("should allow admins to update status", async () => {
      const response = await request(app)
        .patch("/nominations/nom-1/status")
        .set("Authorization", adminToken)
        .send({ status: "CONTACTED" });

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data.status).toBe("CONTACTED");
    });

    it("should reject updates to invalid statuses", async () => {
      const response = await request(app)
        .patch("/nominations/nom-1/status")
        .set("Authorization", adminToken)
        .send({ status: "SUPERSTAR" });

      expect(response.status).toBe(400);
    });
  });
});
