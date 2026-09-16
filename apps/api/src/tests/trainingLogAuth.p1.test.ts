import { describe, it, expect, beforeEach } from "vitest";
import request from "supertest";
import { testDbStore } from "./setup.js";
import { app } from "../app.js";
import { UserRole } from "@armsphere/types";
import { generateAccessToken } from "@armsphere/cryptography";
import { v4 as uuidv4 } from "uuid";
import env from "../config/env.js";

describe("Training Log & PR Access Authorization Hardening (P1 IDOR)", () => {
  const ownerUserId = uuidv4();
  const targetAthleteProfileId = uuidv4();

  const strangerUserId = uuidv4();
  const adminUserId = uuidv4();
  const nationalUserId = uuidv4();
  const directorSameProvId = uuidv4();
  const directorDiffProvId = uuidv4();
  const directorNoJurId = uuidv4();
  const refereeUserId = uuidv4();
  const complianceUserId = uuidv4();
  const nonexistentAthleteProfileId = uuidv4();

  const PROVINCE_PUNJAB = "Punjab";
  const PROVINCE_SINDH = "Sindh";

  const tok = (uid: string, email: string, role: UserRole) =>
    generateAccessToken(uid, email, role, env.JWT_ACCESS_SECRET);

  beforeEach(() => {
    // Reset relevant stores
    testDbStore.users = [];
    testDbStore.athleteProfiles = [];
    testDbStore.communityPosts = [];

    // Seed test users
    testDbStore.users = [
      {
        id: ownerUserId,
        email: "owner@armsphere.test",
        username: "owner_athlete",
        role: UserRole.ATHLETE,
        fullName: "Owner Athlete",
        isActive: true,
      },
      {
        id: strangerUserId,
        email: "stranger@armsphere.test",
        username: "stranger_athlete",
        role: UserRole.ATHLETE,
        fullName: "Stranger Athlete",
        isActive: true,
      },
      {
        id: adminUserId,
        email: "admin@armsphere.test",
        username: "admin_user",
        role: UserRole.SYSTEM_ADMIN,
        fullName: "System Admin",
        isActive: true,
      },
      {
        id: nationalUserId,
        email: "national@armsphere.test",
        username: "national_director",
        role: UserRole.NATIONAL_DIRECTOR,
        fullName: "National Director",
        isActive: true,
      },
      {
        id: directorSameProvId,
        email: "dir_punjab@armsphere.test",
        username: "dir_punjab",
        role: UserRole.PROVINCIAL_DIRECTOR,
        fullName: "Punjab Director",
        isActive: true,
        province: PROVINCE_PUNJAB,
        regionalCoverage: PROVINCE_PUNJAB,
      },
      {
        id: directorDiffProvId,
        email: "dir_sindh@armsphere.test",
        username: "dir_sindh",
        role: UserRole.PROVINCIAL_DIRECTOR,
        fullName: "Sindh Director",
        isActive: true,
        province: PROVINCE_SINDH,
        regionalCoverage: PROVINCE_SINDH,
      },
      {
        id: directorNoJurId,
        email: "dir_nojur@armsphere.test",
        username: "dir_nojur",
        role: UserRole.PROVINCIAL_DIRECTOR,
        fullName: "No Jurisdiction Director",
        isActive: true,
        province: null,
        regionalCoverage: null,
      },
      {
        id: refereeUserId,
        email: "referee@armsphere.test",
        username: "referee_user",
        role: UserRole.REFEREE,
        fullName: "Referee User",
        isActive: true,
      },
      {
        id: complianceUserId,
        email: "compliance@armsphere.test",
        username: "compliance_user",
        role: UserRole.COMPLIANCE_OFFICER,
        fullName: "Compliance Officer",
        isActive: true,
      },
    ];

    // Seed target athlete profile (owned by ownerUserId, province Punjab)
    testDbStore.athleteProfiles = [
      {
        id: targetAthleteProfileId,
        userId: ownerUserId,
        displayName: "Owner Athlete Profile",
        province: PROVINCE_PUNJAB,
        city: "Lahore",
        handedness: "RIGHT",
        dominantArm: "RIGHT",
        dateOfBirth: new Date("1995-01-01"),
        gender: "MALE",
        weightClass: "80kg",
        isDeleted: false,
      },
    ];

    // Seed GYM posts for target athlete
    testDbStore.communityPosts = [
      {
        id: "post-gym-1",
        athleteId: targetAthleteProfileId,
        externalUrl: "https://youtube.com/watch?v=workout1",
        platform: "YOUTUBE",
        category: "GYM",
        caption: "Wrist curls 60kg",
        exerciseType: "WRIST_CURL",
        weightKg: 60,
        reps: 10,
        moderationStatus: "APPROVED",
        isDeleted: false,
        createdAt: new Date("2026-08-01T10:00:00Z"),
        updatedAt: new Date("2026-08-01T10:00:00Z"),
      },
      {
        id: "post-gym-2",
        athleteId: targetAthleteProfileId,
        externalUrl: "https://youtube.com/watch?v=workout2",
        platform: "YOUTUBE",
        category: "GYM",
        caption: "Hammer curls 35kg",
        exerciseType: "HAMMER_CURL",
        weightKg: 35,
        reps: 8,
        moderationStatus: "APPROVED",
        isDeleted: false,
        createdAt: new Date("2026-08-02T10:00:00Z"),
        updatedAt: new Date("2026-08-02T10:00:00Z"),
      },
    ];
  });

  const endpoints = [
    { name: "GET /athletes/:id/training-log", path: (id: string) => `/athletes/${id}/training-log` },
    { name: "GET /athletes/:id/training-log/prs", path: (id: string) => `/athletes/${id}/training-log/prs` },
  ];

  for (const endpoint of endpoints) {
    describe(endpoint.name, () => {
      it("A. Owner athlete -> 200 (allows access to own training data)", async () => {
        const token = tok(ownerUserId, "owner@armsphere.test", UserRole.ATHLETE);
        const res = await request(app)
          .get(endpoint.path(targetAthleteProfileId))
          .set("Authorization", `Bearer ${token}`);

        expect(res.status).toBe(200);
        expect(res.body.success).toBe(true);
        expect(Array.isArray(res.body.data)).toBe(true);
        expect(res.body.data.length).toBeGreaterThan(0);
      });

      it("B. Stranger ATHLETE -> 403 (forbids cross-athlete access)", async () => {
        const token = tok(strangerUserId, "stranger@armsphere.test", UserRole.ATHLETE);
        const res = await request(app)
          .get(endpoint.path(targetAthleteProfileId))
          .set("Authorization", `Bearer ${token}`);

        expect(res.status).toBe(403);
        expect(res.body.data).toBeUndefined();
      });

      it("C. SYSTEM_ADMIN viewing another athlete -> 200", async () => {
        const token = tok(adminUserId, "admin@armsphere.test", UserRole.SYSTEM_ADMIN);
        const res = await request(app)
          .get(endpoint.path(targetAthleteProfileId))
          .set("Authorization", `Bearer ${token}`);

        expect(res.status).toBe(200);
        expect(res.body.success).toBe(true);
        expect(Array.isArray(res.body.data)).toBe(true);
      });

      it("D. NATIONAL_DIRECTOR viewing another athlete -> 200", async () => {
        const token = tok(nationalUserId, "national@armsphere.test", UserRole.NATIONAL_DIRECTOR);
        const res = await request(app)
          .get(endpoint.path(targetAthleteProfileId))
          .set("Authorization", `Bearer ${token}`);

        expect(res.status).toBe(200);
        expect(res.body.success).toBe(true);
        expect(Array.isArray(res.body.data)).toBe(true);
      });

      it("E. Same-province PROVINCIAL_DIRECTOR -> 200", async () => {
        const token = tok(directorSameProvId, "dir_punjab@armsphere.test", UserRole.PROVINCIAL_DIRECTOR);
        const res = await request(app)
          .get(endpoint.path(targetAthleteProfileId))
          .set("Authorization", `Bearer ${token}`);

        expect(res.status).toBe(200);
        expect(res.body.success).toBe(true);
        expect(Array.isArray(res.body.data)).toBe(true);
      });

      it("F. Wrong-province PROVINCIAL_DIRECTOR -> 403", async () => {
        const token = tok(directorDiffProvId, "dir_sindh@armsphere.test", UserRole.PROVINCIAL_DIRECTOR);
        const res = await request(app)
          .get(endpoint.path(targetAthleteProfileId))
          .set("Authorization", `Bearer ${token}`);

        expect(res.status).toBe(403);
        expect(res.body.data).toBeUndefined();
      });

      it("F2. PROVINCIAL_DIRECTOR without assigned jurisdiction -> 403 (fails closed)", async () => {
        const token = tok(directorNoJurId, "dir_nojur@armsphere.test", UserRole.PROVINCIAL_DIRECTOR);
        const res = await request(app)
          .get(endpoint.path(targetAthleteProfileId))
          .set("Authorization", `Bearer ${token}`);

        expect(res.status).toBe(403);
        expect(res.body.data).toBeUndefined();
      });

      it("G. Other staff role (REFEREE) -> 403", async () => {
        const token = tok(refereeUserId, "referee@armsphere.test", UserRole.REFEREE);
        const res = await request(app)
          .get(endpoint.path(targetAthleteProfileId))
          .set("Authorization", `Bearer ${token}`);

        expect(res.status).toBe(403);
        expect(res.body.data).toBeUndefined();
      });

      it("G2. Other staff role (COMPLIANCE_OFFICER) -> 403", async () => {
        const token = tok(complianceUserId, "compliance@armsphere.test", UserRole.COMPLIANCE_OFFICER);
        const res = await request(app)
          .get(endpoint.path(targetAthleteProfileId))
          .set("Authorization", `Bearer ${token}`);

        expect(res.status).toBe(403);
        expect(res.body.data).toBeUndefined();
      });

      it("H. Spoofed privileged JWT role on a normal athlete user -> 403", async () => {
        // User strangerUserId has DB role ATHLETE, but JWT claims SYSTEM_ADMIN
        const spoofedToken = tok(strangerUserId, "stranger@armsphere.test", UserRole.SYSTEM_ADMIN);
        const res = await request(app)
          .get(endpoint.path(targetAthleteProfileId))
          .set("Authorization", `Bearer ${spoofedToken}`);

        expect(res.status).toBe(403);
        expect(res.body.data).toBeUndefined();
      });

      it("I. Canonical privileged DB identity with lower-privilege JWT claim -> 200", async () => {
        // User adminUserId has DB role SYSTEM_ADMIN, but JWT claims ATHLETE
        const lowerClaimToken = tok(adminUserId, "admin@armsphere.test", UserRole.ATHLETE);
        const res = await request(app)
          .get(endpoint.path(targetAthleteProfileId))
          .set("Authorization", `Bearer ${lowerClaimToken}`);

        expect(res.status).toBe(200);
        expect(res.body.success).toBe(true);
      });

      it("J. Nonexistent athlete profile -> 404", async () => {
        const token = tok(adminUserId, "admin@armsphere.test", UserRole.SYSTEM_ADMIN);
        const res = await request(app)
          .get(endpoint.path(nonexistentAthleteProfileId))
          .set("Authorization", `Bearer ${token}`);

        expect(res.status).toBe(404);
      });

      it("K. Unauthenticated -> 401", async () => {
        const res = await request(app)
          .get(endpoint.path(targetAthleteProfileId));

        expect(res.status).toBe(401);
      });

      it("L. Verify denied cross-athlete access does not leak any training rows or PR data", async () => {
        const token = tok(strangerUserId, "stranger@armsphere.test", UserRole.ATHLETE);
        const res = await request(app)
          .get(endpoint.path(targetAthleteProfileId))
          .set("Authorization", `Bearer ${token}`);

        expect(res.status).toBe(403);
        expect(res.body.data).toBeUndefined();
        // Ensure no post IDs or exercises are leaked in error body
        expect(JSON.stringify(res.body)).not.toContain("post-gym-1");
        expect(JSON.stringify(res.body)).not.toContain("WRIST_CURL");
        expect(JSON.stringify(res.body)).not.toContain("60");
      });
    });
  }
});