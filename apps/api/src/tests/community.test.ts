import { describe, it, expect, beforeEach } from "vitest";
import request from "supertest";
import { testDbStore } from "./setup.js";
import { app } from "../app.js";
import { generateAccessToken } from "@armsphere/cryptography";
import { UserRole } from "@armsphere/types";
import env from "../config/env.js";

function authHeader(role: UserRole = UserRole.ATHLETE, userId = "user-123") {
  const token = generateAccessToken(userId, "test@armsphere.com", role, env.JWT_ACCESS_SECRET);
  return `Bearer ${token}`;
}

describe("Community & Training Log System Tests", () => {
  const athleteUserId = "athlete-user-id";
  const athleteId = "athlete-profile-id";

  beforeEach(() => {
    // Clear relevant stores
    testDbStore.users = [];
    testDbStore.athleteProfiles = [];
    testDbStore.communityPosts = [];

    // Seed test user & athlete profile
    testDbStore.users.push({
      id: athleteUserId,
      email: "athlete@armsphere.com",
      username: "athlete1",
      passwordHash: "hash",
      role: UserRole.ATHLETE,
      fullName: "Arm Wrestler",
      isActive: true,
    });

    testDbStore.athleteProfiles.push({
      id: athleteId,
      userId: athleteUserId,
      displayName: "John Doe",
      isDeleted: false,
    });
  });

  describe("Post Creation & Exercise Validations", () => {
    it("should successfully create a standard non-GYM post", async () => {
      const response = await request(app)
        .post("/community/links")
        .set("Authorization", authHeader(UserRole.ATHLETE, athleteUserId))
        .send({
          externalUrl: "https://www.youtube.com/watch?v=123",
          category: "HIGHLIGHTS",
          caption: "Awesome pull!",
        });

      expect(response.status).toBe(201);
      expect(response.body.success).toBe(true);
      expect(response.body.data.category).toBe("HIGHLIGHTS");
      expect(response.body.data.exerciseType).toBeNull();
    });

    it("should reject exercise fields on non-GYM posts", async () => {
      const response = await request(app)
        .post("/community/links")
        .set("Authorization", authHeader(UserRole.ATHLETE, athleteUserId))
        .send({
          externalUrl: "https://www.youtube.com/watch?v=123",
          category: "HIGHLIGHTS",
          caption: "Failed lift",
          exerciseType: "WRIST_CURL",
          weightKg: 50,
          reps: 10,
        });

      expect(response.status).toBe(400);
      expect(response.body.detail).toContain("Exercise fields are only allowed for posts in the GYM category");
    });

    it("should reject GYM category post without exerciseType", async () => {
      const response = await request(app)
        .post("/community/links")
        .set("Authorization", authHeader(UserRole.ATHLETE, athleteUserId))
        .send({
          externalUrl: "https://www.youtube.com/watch?v=123",
          category: "GYM",
          caption: "My workout",
          weightKg: 50,
        });

      expect(response.status).toBe(400);
      expect(response.body.detail).toContain("exerciseType is required");
    });

    it("should successfully create a GYM post with valid exercise data", async () => {
      const response = await request(app)
        .post("/community/links")
        .set("Authorization", authHeader(UserRole.ATHLETE, athleteUserId))
        .send({
          externalUrl: "https://www.youtube.com/watch?v=123",
          category: "GYM",
          caption: "Wrist curl PR attempt",
          exerciseType: "WRIST_CURL",
          weightKg: 60,
          reps: 5,
        });

      expect(response.status).toBe(201);
      expect(response.body.success).toBe(true);
      expect(response.body.data.category).toBe("GYM");
      expect(response.body.data.exerciseType).toBe("WRIST_CURL");
      expect(Number(response.body.data.weightKg)).toBe(60);
      expect(response.body.data.reps).toBe(5);
    });
  });

  describe("Daily Training Post Limit", () => {
    it("should enforce a limit of 2 GYM category posts per day", async () => {
      // 1st GYM post
      const res1 = await request(app)
        .post("/community/links")
        .set("Authorization", authHeader(UserRole.ATHLETE, athleteUserId))
        .send({
          externalUrl: "https://www.youtube.com/watch?v=1",
          category: "GYM",
          exerciseType: "CUPPING",
          weightKg: 40,
          reps: 8,
        });
      expect(res1.status).toBe(201);

      // 2nd GYM post
      const res2 = await request(app)
        .post("/community/links")
        .set("Authorization", authHeader(UserRole.ATHLETE, athleteUserId))
        .send({
          externalUrl: "https://www.youtube.com/watch?v=2",
          category: "GYM",
          exerciseType: "CUPPING",
          weightKg: 45,
          reps: 6,
        });
      expect(res2.status).toBe(201);

      // 3rd GYM post (should be blocked)
      const res3 = await request(app)
        .post("/community/links")
        .set("Authorization", authHeader(UserRole.ATHLETE, athleteUserId))
        .send({
          externalUrl: "https://www.youtube.com/watch?v=3",
          category: "GYM",
          exerciseType: "CUPPING",
          weightKg: 50,
          reps: 5,
        });
      expect(res3.status).toBe(400);
      expect(res3.body.detail).toContain("Daily training post limit exceeded");
    });
  });

  describe("Training Log & PR Retrieval", () => {
    beforeEach(() => {
      // Seed several training posts
      testDbStore.communityPosts.push(
        {
          id: "post-1",
          athleteId: athleteId,
          externalUrl: "https://youtube.com/watch?v=1",
          platform: "YOUTUBE",
          category: "GYM",
          exerciseType: "WRIST_CURL",
          weightKg: "40.00",
          reps: 10,
          moderationStatus: "APPROVED",
          isDeleted: false,
          createdAt: new Date("2026-07-10T10:00:00Z"),
        },
        {
          id: "post-2",
          athleteId: athleteId,
          externalUrl: "https://youtube.com/watch?v=2",
          platform: "YOUTUBE",
          category: "GYM",
          exerciseType: "WRIST_CURL",
          weightKg: "60.00", // Max weight / PR
          reps: 5,
          moderationStatus: "APPROVED",
          isDeleted: false,
          createdAt: new Date("2026-07-12T10:00:00Z"),
        },
        {
          id: "post-3",
          athleteId: athleteId,
          externalUrl: "https://youtube.com/watch?v=3",
          platform: "YOUTUBE",
          category: "GYM",
          exerciseType: "WRIST_CURL",
          weightKg: "50.00",
          reps: 8,
          moderationStatus: "APPROVED",
          isDeleted: false,
          createdAt: new Date("2026-07-14T10:00:00Z"),
        },
        {
          id: "post-4",
          athleteId: athleteId,
          externalUrl: "https://youtube.com/watch?v=4",
          platform: "YOUTUBE",
          category: "GYM",
          exerciseType: "HAMMER_CURL",
          weightKg: "35.00",
          reps: 12,
          moderationStatus: "APPROVED",
          isDeleted: false,
          createdAt: new Date("2026-07-15T10:00:00Z"),
        }
      );
    });

    it("should fetch training log for athlete most recent first", async () => {
      const response = await request(app)
        .get(`/athletes/${athleteId}/training-log`)
        .set("Authorization", authHeader(UserRole.ATHLETE, athleteUserId));

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveLength(4);

      // Order should be most recent first: post-4, post-3, post-2, post-1
      expect(response.body.data[0].id).toBe("post-4");
      expect(response.body.data[1].id).toBe("post-3");
    });

    it("should filter training log by exerciseType", async () => {
      const response = await request(app)
        .get(`/athletes/${athleteId}/training-log`)
        .query({ exerciseType: "HAMMER_CURL" })
        .set("Authorization", authHeader(UserRole.ATHLETE, athleteUserId));

      expect(response.status).toBe(200);
      expect(response.body.data).toHaveLength(1);
      expect(response.body.data[0].id).toBe("post-4");
    });

    it("should dynamically calculate correct PRs from training log history", async () => {
      const response = await request(app)
        .get(`/athletes/${athleteId}/training-log/prs`)
        .set("Authorization", authHeader(UserRole.ATHLETE, athleteUserId));

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveLength(2); // WRIST_CURL and HAMMER_CURL

      const wristCurlPr = response.body.data.find((p: any) => p.exerciseType === "WRIST_CURL");
      const hammerCurlPr = response.body.data.find((p: any) => p.exerciseType === "HAMMER_CURL");

      expect(wristCurlPr).toBeDefined();
      expect(wristCurlPr.weightKg).toBe(60); // Verify it returns the maximum weightKg (60), not the most recent (50)
      expect(new Date(wristCurlPr.createdAt).toISOString()).toBe(new Date("2026-07-12T10:00:00Z").toISOString());

      expect(hammerCurlPr).toBeDefined();
      expect(hammerCurlPr.weightKg).toBe(35);
    });

    it("should filter out PENDING and REJECTED posts when returning training log and PRs", async () => {
      // Seed a PENDING post with a higher weight for WRIST_CURL
      testDbStore.communityPosts.push({
        id: "post-pending",
        athleteId: athleteId,
        externalUrl: "https://youtube.com/watch?v=pending",
        platform: "YOUTUBE",
        category: "GYM",
        exerciseType: "WRIST_CURL",
        weightKg: "90.00",
        reps: 5,
        moderationStatus: "PENDING",
        isDeleted: false,
        createdAt: new Date("2026-07-16T10:00:00Z"),
      });

      // Seed a REJECTED post with a higher weight for HAMMER_CURL
      testDbStore.communityPosts.push({
        id: "post-rejected",
        athleteId: athleteId,
        externalUrl: "https://youtube.com/watch?v=rejected",
        platform: "YOUTUBE",
        category: "GYM",
        exerciseType: "HAMMER_CURL",
        weightKg: "100.00",
        reps: 5,
        moderationStatus: "REJECTED",
        isDeleted: false,
        createdAt: new Date("2026-07-17T10:00:00Z"),
      });

      // Fetch training log: shouldn't contain pending or rejected
      const logRes = await request(app)
        .get(`/athletes/${athleteId}/training-log`)
        .set("Authorization", authHeader(UserRole.ATHLETE, athleteUserId));

      expect(logRes.status).toBe(200);
      expect(logRes.body.data).toHaveLength(4); // original 4 approved ones
      const postIds = logRes.body.data.map((p: any) => p.id);
      expect(postIds).not.toContain("post-pending");
      expect(postIds).not.toContain("post-rejected");

      // Fetch PRs: should still be 60 for WRIST_CURL and 35 for HAMMER_CURL
      const prRes = await request(app)
        .get(`/athletes/${athleteId}/training-log/prs`)
        .set("Authorization", authHeader(UserRole.ATHLETE, athleteUserId));

      expect(prRes.status).toBe(200);
      expect(prRes.body.success).toBe(true);
      expect(prRes.body.data).toHaveLength(2);

      const wristCurlPr = prRes.body.data.find((p: any) => p.exerciseType === "WRIST_CURL");
      const hammerCurlPr = prRes.body.data.find((p: any) => p.exerciseType === "HAMMER_CURL");

      expect(wristCurlPr.weightKg).toBe(60); // Not 90
      expect(hammerCurlPr.weightKg).toBe(35); // Not 100
    });
  });
});
