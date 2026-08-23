import { describe, it, expect, beforeEach } from "vitest";
import request from "supertest";
import { testDbStore } from "./setup.js";
import { app } from "../app.js";
import { UserRole } from "@armsphere/types";
import { generateAccessToken } from "@armsphere/cryptography";
import env from "../config/env.js";

describe("Venue Partners API Suite", () => {
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
    testDbStore.venuePartners = [];

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

  describe("POST /venues - Submit Venue", () => {
    it("should reject unauthenticated submissions", async () => {
      const response = await request(app)
        .post("/venues")
        .send({
          name: "Metro Fitness",
          city: "Toronto",
          province: "Ontario",
          address: "123 King St W",
        });

      expect(response.status).toBe(401); // 401 Unauthorized
    });

    it("should allow authenticated users to submit a venue, defaulting isVerified to false", async () => {
      const response = await request(app)
        .post("/venues")
        .set("Authorization", user1Token)
        .send({
          name: "Metro Fitness",
          city: "Toronto",
          province: "Ontario",
          address: "123 King St W",
          contactInfo: "info@metrofitness.ca",
          description: "Top tier gym in the heart of Toronto.",
        });

      expect(response.status).toBe(201);
      expect(response.body.success).toBe(true);
      expect(response.body.data.id).toBeDefined();
      expect(response.body.data.name).toBe("Metro Fitness");
      expect(response.body.data.ownerUserId).toBe(user1Id);
      expect(response.body.data.isVerified).toBe(false);
    });
  });

  describe("GET /venues - List & Filter Venues", () => {
    beforeEach(() => {
      // Pre-populate mock store with venues
      testDbStore.venuePartners.push(
        {
          id: "v1",
          name: "Metro Fitness",
          city: "Toronto",
          province: "Ontario",
          address: "123 King St W",
          ownerUserId: user1Id,
          isVerified: true,
          createdAt: new Date(),
          updatedAt: new Date(),
        },
        {
          id: "v2",
          name: "Powerhouse Gym",
          city: "Vancouver",
          province: "British Columbia",
          address: "456 Robson St",
          ownerUserId: user2Id,
          isVerified: false,
          createdAt: new Date(),
          updatedAt: new Date(),
        }
      );
    });

    it("should return public list of all venues paginated", async () => {
      const response = await request(app).get("/venues");

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data.length).toBe(2);
    });

    it("should filter venues by city", async () => {
      const response = await request(app).get("/venues?city=Toronto");

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data.length).toBe(1);
      expect(response.body.data[0].city).toBe("Toronto");
    });

    it("should filter venues by province", async () => {
      const response = await request(app).get("/venues?province=British Columbia");

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data.length).toBe(1);
      expect(response.body.data[0].province).toBe("British Columbia");
    });
  });

  describe("GET /venues/:id - Detail View", () => {
    beforeEach(() => {
      testDbStore.venuePartners.push({
        id: "v1",
        name: "Metro Fitness",
        city: "Toronto",
        province: "Ontario",
        address: "123 King St W",
        ownerUserId: user1Id,
        isVerified: true,
        createdAt: new Date(),
        updatedAt: new Date(),
      });
    });

    it("should return detailed view of a venue", async () => {
      const response = await request(app).get("/venues/v1");

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data.name).toBe("Metro Fitness");
    });

    it("should return 404 for non-existent venue", async () => {
      const response = await request(app).get("/venues/non-existent-id");

      expect(response.status).toBe(404);
    });
  });

  describe("PATCH /venues/:id - Edit Venue", () => {
    beforeEach(() => {
      testDbStore.venuePartners.push({
        id: "v1",
        name: "Metro Fitness",
        city: "Toronto",
        province: "Ontario",
        address: "123 King St W",
        ownerUserId: user1Id,
        isVerified: false,
        createdAt: new Date(),
        updatedAt: new Date(),
      });
    });

    it("should reject non-owners and non-admins", async () => {
      const response = await request(app)
        .patch("/venues/v1")
        .set("Authorization", user2Token)
        .send({
          name: "Hacked Fitness",
        });

      expect(response.status).toBe(403);
    });

    it("should allow the owner to edit the venue", async () => {
      const response = await request(app)
        .patch("/venues/v1")
        .set("Authorization", user1Token)
        .send({
          name: "Metro Fitness New Name",
          city: "North York",
        });

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data.name).toBe("Metro Fitness New Name");
      expect(response.body.data.city).toBe("North York");
    });

    it("should allow an admin to edit the venue", async () => {
      const response = await request(app)
        .patch("/venues/v1")
        .set("Authorization", adminToken)
        .send({
          name: "Metro Fitness Admin Override",
        });

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data.name).toBe("Metro Fitness Admin Override");
    });
  });

  describe("POST /venues/:id/verify - Admin Verify Venue", () => {
    beforeEach(() => {
      testDbStore.venuePartners.push({
        id: "v1",
        name: "Metro Fitness",
        city: "Toronto",
        province: "Ontario",
        address: "123 King St W",
        ownerUserId: user1Id,
        isVerified: false,
        createdAt: new Date(),
        updatedAt: new Date(),
      });
    });

    it("should reject verification request from non-admin", async () => {
      const response = await request(app)
        .post("/venues/v1/verify")
        .set("Authorization", user1Token);

      expect(response.status).toBe(403);
    });

    it("should allow admin to verify the venue", async () => {
      const response = await request(app)
        .post("/venues/v1/verify")
        .set("Authorization", adminToken);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data.isVerified).toBe(true);
    });
  });
});
