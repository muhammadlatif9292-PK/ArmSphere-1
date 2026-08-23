import { describe, it, expect, beforeEach } from "vitest";
import request from "supertest";
import { testDbStore } from "./setup.js";
import { app } from "../app.js";
import { UserRole } from "@armsphere/types";
import { generateAccessToken } from "@armsphere/cryptography";
import env from "../config/env.js";

function authHeader(role: UserRole = UserRole.ATHLETE, userId = "00000000-0000-0000-0000-000000000099") {
  const token = generateAccessToken(userId, "test@armsphere.com", role, env.JWT_ACCESS_SECRET);
  return `Bearer ${token}`;
}

describe("Referee Certification and Action Gating API Suite", () => {
  const systemAdminId = "99999999-9999-9999-9999-999999999999";
  const refereeId = "00000000-0000-0000-0000-000000000005";
  const athleteId = "00000000-0000-0000-0000-000000000001";
  const eventId = "11111111-1111-1111-1111-222222222222";
  const registrationId = "22222222-2222-2222-2222-111111111111";

  beforeEach(() => {
    // Clear & Seed base objects
    testDbStore.users = [];
    testDbStore.refereeCertifications = [];
    testDbStore.events = [];
    testDbStore.eventRegistrations = [];
    testDbStore.officialWeighins = [];

    // Seed users
    testDbStore.users.push(
      {
        id: systemAdminId,
        email: "admin@armsphere.com",
        username: "admin",
        role: UserRole.SYSTEM_ADMIN,
        fullName: "System Admin",
        isActive: true,
      },
      {
        id: refereeId,
        email: "referee@armsphere.com",
        username: "referee",
        role: UserRole.REFEREE,
        fullName: "Official Referee",
        isActive: true,
      },
      {
        id: athleteId,
        email: "athlete@armsphere.com",
        username: "athlete",
        role: UserRole.ATHLETE,
        fullName: "Elite Athlete",
        isActive: true,
      }
    );

    // Seed events & registrations
    testDbStore.events.push({
      id: eventId,
      name: "Championship Tournament",
      status: "PUBLISHED",
    });

    testDbStore.eventRegistrations.push({
      id: registrationId,
      eventId: eventId,
      athleteId: athleteId,
      division: "SENIOR",
      weightClass: "70KG",
      arm: "RIGHT",
      status: "APPROVED",
    });
  });

  describe("Certification CRUD operations", () => {
    it("should allow a system admin to issue a referee certification", async () => {
      const response = await request(app)
        .post(`/referees/${refereeId}/certifications`)
        .set("Authorization", authHeader(UserRole.SYSTEM_ADMIN, systemAdminId))
        .send({
          certificationLevel: "PRO_LEVEL_1",
          issuedAt: new Date().toISOString(),
          expiresAt: new Date(Date.now() + 86400000 * 365).toISOString(),
          issuingBody: "WAF_OFFICIAL",
        });

      expect(response.status).toBe(201);
      expect(response.body.success).toBe(true);
      expect(response.body.data.userId).toBe(refereeId);
      expect(response.body.data.status).toBe("ACTIVE");
    });

    it("should reject issuing certification if the actor is not an admin", async () => {
      const response = await request(app)
        .post(`/referees/${refereeId}/certifications`)
        .set("Authorization", authHeader(UserRole.ATHLETE, athleteId))
        .send({
          certificationLevel: "PRO_LEVEL_1",
          issuedAt: new Date().toISOString(),
          issuingBody: "WAF_OFFICIAL",
        });

      expect(response.status).toBe(403);
    });

    it("should list referee's own certifications", async () => {
      // Seed a certification
      const certId = "cert-123";
      testDbStore.refereeCertifications.push({
        id: certId,
        userId: refereeId,
        certificationLevel: "PRO_LEVEL_1",
        issuedAt: new Date(),
        status: "ACTIVE",
        issuingBody: "WAF_OFFICIAL",
      });

      const response = await request(app)
        .get(`/referees/${refereeId}/certifications`)
        .set("Authorization", authHeader(UserRole.REFEREE, refereeId));

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveLength(1);
    });

    it("should reject listing certifications of another referee if not admin", async () => {
      const response = await request(app)
        .get(`/referees/${refereeId}/certifications`)
        .set("Authorization", authHeader(UserRole.ATHLETE, athleteId));

      expect(response.status).toBe(403);
    });

    it("should allow system admin to revoke a certification", async () => {
      const certId = "cert-123";
      testDbStore.refereeCertifications.push({
        id: certId,
        userId: refereeId,
        certificationLevel: "PRO_LEVEL_1",
        issuedAt: new Date(),
        status: "ACTIVE",
        issuingBody: "WAF_OFFICIAL",
      });

      const response = await request(app)
        .patch(`/referees/certifications/${certId}/revoke`)
        .set("Authorization", authHeader(UserRole.SYSTEM_ADMIN, systemAdminId))
        .send();

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data.status).toBe("REVOKED");
    });
  });

  describe("Referee Action Gating Enforcement", () => {
    it("should reject referee from recording a weigh-in when they have NO certifications", async () => {
      const response = await request(app)
        .post("/tournaments/weighins")
        .set("Authorization", authHeader(UserRole.REFEREE, refereeId))
        .send({
          registrationId: registrationId,
          weight: 68.5,
          certifiedBy: refereeId,
        });

      expect(response.status).toBe(403);
      expect(response.body.detail || response.body.error?.detail).toContain("Referee does not hold an active referee certification");
    });

    it("should allow referee to record a weigh-in when they have an ACTIVE certification", async () => {
      // Seed active certification
      testDbStore.refereeCertifications.push({
        id: "cert-active",
        userId: refereeId,
        certificationLevel: "PRO_LEVEL_1",
        issuedAt: new Date(),
        expiresAt: new Date(Date.now() + 86400000 * 30), // 30 days from now
        status: "ACTIVE",
        issuingBody: "WAF_OFFICIAL",
      });

      const response = await request(app)
        .post("/tournaments/weighins")
        .set("Authorization", authHeader(UserRole.REFEREE, refereeId))
        .send({
          registrationId: registrationId,
          weight: 68.5,
          certifiedBy: refereeId,
        });

      expect(response.status).toBe(201);
    });

    it("should reject referee from recording a weigh-in when their certification has EXPIRED", async () => {
      // Seed expired certification
      testDbStore.refereeCertifications.push({
        id: "cert-expired",
        userId: refereeId,
        certificationLevel: "PRO_LEVEL_1",
        issuedAt: new Date(Date.now() - 86400000 * 30),
        expiresAt: new Date(Date.now() - 86400000 * 10), // expired 10 days ago
        status: "ACTIVE",
        issuingBody: "WAF_OFFICIAL",
      });

      const response = await request(app)
        .post("/tournaments/weighins")
        .set("Authorization", authHeader(UserRole.REFEREE, refereeId))
        .send({
          registrationId: registrationId,
          weight: 68.5,
          certifiedBy: refereeId,
        });

      expect(response.status).toBe(403);
    });

    it("should reject referee from recording a weigh-in when their certification is REVOKED", async () => {
      // Seed revoked certification
      testDbStore.refereeCertifications.push({
        id: "cert-revoked",
        userId: refereeId,
        certificationLevel: "PRO_LEVEL_1",
        issuedAt: new Date(),
        expiresAt: new Date(Date.now() + 86400000 * 30),
        status: "REVOKED",
        issuingBody: "WAF_OFFICIAL",
      });

      const response = await request(app)
        .post("/tournaments/weighins")
        .set("Authorization", authHeader(UserRole.REFEREE, refereeId))
        .send({
          registrationId: registrationId,
          weight: 68.5,
          certifiedBy: refereeId,
        });

      expect(response.status).toBe(403);
    });

    it("should allow director/admin to record weigh-in without a certification", async () => {
      const response = await request(app)
        .post("/tournaments/weighins")
        .set("Authorization", authHeader(UserRole.SYSTEM_ADMIN, systemAdminId))
        .send({
          registrationId: registrationId,
          weight: 68.5,
          certifiedBy: systemAdminId,
        });

      expect(response.status).toBe(201);
    });
  });
});
