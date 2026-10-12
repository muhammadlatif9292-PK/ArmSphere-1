import { describe, it, expect, beforeEach } from "vitest";
import request from "supertest";
import { testDbStore } from "./setup.js";
import { app } from "../app.js";
import { UserRole } from "@armsphere/types";
import { generateAccessToken } from "@armsphere/cryptography";
import env from "../config/env.js";
import { RefereeCertificationService } from "../services/refereeCertification.js";
import { scheduleJob, runDueScheduledJobs, processedJobsTracker, resetJobTrackers, SCHEDULED_JOB_TYPES } from "../services/scheduledJobs.js";

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
    testDbStore.notifications = [];
    testDbStore.scheduledJobs = [];
    testDbStore.events = [];
    testDbStore.eventRegistrations = [];
    testDbStore.officialWeighins = [];
    resetJobTrackers();

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

  describe("Referee Certification Expiry Processing & Notifications", () => {
    it("should process expired certifications, transition status to EXPIRED, and notify referees", async () => {
      // 1. Seed one active unexpired cert and one active expired cert
      const activeUnexpiredId = "cert-active-unexpired";
      const activeExpiredId = "cert-active-expired";

      testDbStore.refereeCertifications.push(
        {
          id: activeUnexpiredId,
          userId: refereeId,
          certificationLevel: "PRO_LEVEL_1",
          issuedAt: new Date(Date.now() - 86400000 * 30),
          expiresAt: new Date(Date.now() + 86400000 * 60), // expires in 60 days
          status: "ACTIVE",
          issuingBody: "WAF_OFFICIAL",
        },
        {
          id: activeExpiredId,
          userId: refereeId,
          certificationLevel: "PRO_LEVEL_2",
          issuedAt: new Date(Date.now() - 86400000 * 400),
          expiresAt: new Date(Date.now() - 86400000 * 30), // expired 30 days ago
          status: "ACTIVE",
          issuingBody: "WAF_OFFICIAL",
        }
      );

      const result = await RefereeCertificationService.processExpiredCertifications();

      expect(result.expiredCount).toBe(1);
      expect(result.expiredIds).toEqual([activeExpiredId]);

      // Verify status in database
      const expiredCert = testDbStore.refereeCertifications.find((c) => c.id === activeExpiredId);
      expect(expiredCert?.status).toBe("EXPIRED");

      const unexpiredCert = testDbStore.refereeCertifications.find((c) => c.id === activeUnexpiredId);
      expect(unexpiredCert?.status).toBe("ACTIVE");

      // Verify in-app notification sent to the referee
      const notifications = testDbStore.notifications.filter((n) => n.userId === refereeId);
      expect(notifications.length).toBeGreaterThan(0);
      const expiryNotification = notifications.find((n) => n.title.includes("Referee Certification Expired"));
      expect(expiryNotification).toBeDefined();
      expect(expiryNotification?.priority).toBe("HIGH");
      expect(expiryNotification?.content).toContain("PRO_LEVEL_2");
    });

    it("should execute certification expiry through the postgres scheduled jobs runner", async () => {
      const activeExpiredId = "cert-job-expired";
      testDbStore.refereeCertifications.push({
        id: activeExpiredId,
        userId: refereeId,
        certificationLevel: "MASTER_OFFICIAL",
        issuedAt: new Date(Date.now() - 86400000 * 500),
        expiresAt: new Date(Date.now() - 86400000 * 5),
        status: "ACTIVE",
        issuingBody: "WAF_OFFICIAL",
      });

      // Schedule the job
      await scheduleJob(SCHEDULED_JOB_TYPES.CERTIFICATION_EXPIRY, new Date(Date.now() - 1000));

      // Run due scheduled jobs
      const runResult = await runDueScheduledJobs();
      expect(runResult.executedCount).toBeGreaterThanOrEqual(1);

      // Verify job tracker recorded the expiry execution
      expect(processedJobsTracker.certificationExpiries.length).toBe(1);
      expect(processedJobsTracker.certificationExpiries[0].result.expiredCount).toBe(1);

      // Verify database certification status
      const cert = testDbStore.refereeCertifications.find((c) => c.id === activeExpiredId);
      expect(cert?.status).toBe("EXPIRED");
    });
  });

  describe("Referee Certification Listing by Province (users.province join)", () => {
    const directorPunjabId = "director-punjab-uuid";
    const directorSindhId = "director-sindh-uuid";
    const refereePunjabId = "referee-punjab-uuid";
    const refereeSindhId = "referee-sindh-uuid";

    beforeEach(() => {
      testDbStore.users.push(
        {
          id: directorPunjabId,
          email: "director.punjab@armsphere.com",
          username: "director_punjab",
          role: UserRole.PROVINCIAL_DIRECTOR,
          province: "Punjab",
          fullName: "Punjab Director",
          isActive: true,
        },
        {
          id: directorSindhId,
          email: "director.sindh@armsphere.com",
          username: "director_sindh",
          role: UserRole.PROVINCIAL_DIRECTOR,
          province: "Sindh",
          fullName: "Sindh Director",
          isActive: true,
        },
        {
          id: refereePunjabId,
          email: "referee.punjab@armsphere.com",
          username: "referee_punjab",
          role: UserRole.REFEREE,
          province: "Punjab",
          fullName: "Punjab Official",
          isActive: true,
        },
        {
          id: refereeSindhId,
          email: "referee.sindh@armsphere.com",
          username: "referee_sindh",
          role: UserRole.REFEREE,
          province: "Sindh",
          fullName: "Sindh Official",
          isActive: true,
        }
      );

      testDbStore.refereeCertifications.push(
        {
          id: "cert-punjab-1",
          userId: refereePunjabId,
          certificationLevel: "PRO_LEVEL_1",
          issuedAt: new Date(),
          status: "ACTIVE",
          issuingBody: "WAF_OFFICIAL",
        },
        {
          id: "cert-sindh-1",
          userId: refereeSindhId,
          certificationLevel: "NATIONAL_LEVEL_2",
          issuedAt: new Date(),
          status: "ACTIVE",
          issuingBody: "WAF_OFFICIAL",
        }
      );
    });

    it("should allow SYSTEM_ADMIN to list certifications in any province", async () => {
      const response = await request(app)
        .get("/referees/by-province/Punjab")
        .set("Authorization", authHeader(UserRole.SYSTEM_ADMIN, systemAdminId));

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveLength(1);
      expect(response.body.data[0].userId).toBe(refereePunjabId);
      expect(response.body.data[0].userProvince).toBe("Punjab");
    });

    it("should allow Provincial Director to list certifications in their own province", async () => {
      const response = await request(app)
        .get("/referees/by-province/Punjab")
        .set("Authorization", authHeader(UserRole.PROVINCIAL_DIRECTOR, directorPunjabId));

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveLength(1);
      expect(response.body.data[0].userId).toBe(refereePunjabId);
    });

    it("should reject Provincial Director attempting to view certifications in a different province (403)", async () => {
      const response = await request(app)
        .get("/referees/by-province/Punjab")
        .set("Authorization", authHeader(UserRole.PROVINCIAL_DIRECTOR, directorSindhId));

      expect(response.status).toBe(403);
      expect(response.body.detail || response.body.error?.detail).toContain("own province");
    });

    it("should reject non-director non-admin roles from accessing by-province endpoint (403)", async () => {
      const response = await request(app)
        .get("/referees/by-province/Punjab")
        .set("Authorization", authHeader(UserRole.ATHLETE, athleteId));

      expect(response.status).toBe(403);
    });
  });
});
