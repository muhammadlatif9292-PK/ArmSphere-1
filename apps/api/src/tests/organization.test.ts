import { describe, it, expect, beforeEach } from "vitest";
import request from "supertest";
import { testDbStore } from "./setup.js";
import { app } from "../app.js";
import { UserRole } from "@armsphere/types";
import { generateAccessToken } from "@armsphere/cryptography";
import env from "../config/env.js";

describe("Organization & Federation Portal API Suite", () => {
  let adminUser: any;
  let adminToken: string;
  let athleteUser: any;
  let athleteToken: string;

  const adminUserId = "55555555-5555-5555-5555-555555555555";
  const athleteUserId = "11111111-1111-1111-1111-111111111111";

  beforeEach(() => {
    testDbStore.users = [];
    testDbStore.organizations = [];
    testDbStore.events = [];
    testDbStore.auditLogs = [];

    // Seed Admin User
    adminUser = {
      id: adminUserId,
      email: "admin@armsphere.com",
      username: "superadmin",
      role: UserRole.SYSTEM_ADMIN,
      fullName: "Super Admin",
      isActive: true,
    };
    testDbStore.users.push(adminUser);
    adminToken = `Bearer ${generateAccessToken(
      adminUser.id,
      adminUser.email,
      adminUser.role,
      env.JWT_ACCESS_SECRET
    )}`;

    // Seed Regular Athlete
    athleteUser = {
      id: athleteUserId,
      email: "athlete@armsphere.com",
      username: "athlete",
      role: UserRole.ATHLETE,
      fullName: "Regular Athlete",
      isActive: true,
    };
    testDbStore.users.push(athleteUser);
    athleteToken = `Bearer ${generateAccessToken(
      athleteUser.id,
      athleteUser.email,
      athleteUser.role,
      env.JWT_ACCESS_SECRET
    )}`;
  });

  describe("Public Organization Discovery & Verification", () => {
    it("should return the list of approved organizations and seed canonicals if empty", async () => {
      const res = await request(app).get("/organizations");
      expect(res.status).toBe(200);
      const orgs = res.body.data ?? res.body;
      expect(Array.isArray(orgs)).toBe(true);
      expect(orgs.length).toBeGreaterThan(0);

      const paff = orgs.find((o: any) => o.slug === "paff");
      expect(paff).toBeDefined();
      expect(paff.name).toBe("Pakistan Armwrestling Federation (PAFF)");
      // Ensure accessCodeHash is never leaked to public consumers
      expect(paff.accessCodeHash).toBeUndefined();
    });

    it("should reject access code verification when parameters are missing", async () => {
      const res = await request(app)
        .post("/organizations/verify-access")
        .send({});
      expect(res.status).toBe(400);
    });

    it("should reject access code verification with an invalid code", async () => {
      // First ensure canonical organizations are seeded
      await request(app).get("/organizations");
      const paff = testDbStore.organizations.find((o) => o.slug === "paff");
      expect(paff).toBeDefined();

      const res = await request(app)
        .post("/organizations/verify-access")
        .send({
          organizationId: paff.id,
          accessCode: "WRONG-CODE-9999",
        });

      expect(res.status).toBe(401);
      expect(res.body.detail || res.body.message || "").toContain("Invalid organization access code");
    });

    it("should successfully verify access code and issue a 24-hour scoped token", async () => {
      // Ensure canonical organizations are seeded
      await request(app).get("/organizations");
      const paff = testDbStore.organizations.find((o) => o.slug === "paff");
      expect(paff).toBeDefined();

      const res = await request(app)
        .post("/organizations/verify-access")
        .send({
          organizationId: paff.id,
          accessCode: "PAFF-2026-X89K",
        });

      expect(res.status).toBe(200);
      expect(res.body.token).toBeDefined();
      expect(res.body.organization).toBeDefined();
      expect(res.body.organization.id).toBe(paff.id);
      expect(res.body.organization.accessCodeHash).toBeUndefined();
    });
  });

  describe("Organization First-Time Onboarding", () => {
    it("should reject onboarding without an authenticated bearer token", async () => {
      const res = await request(app)
        .post("/organizations/test-org-id/onboard")
        .send({
          presidentName: "Qaiser Khan",
          foundationDate: "2015-06-15T00:00:00.000Z",
          province: "Punjab",
          city: "Lahore",
        });
      expect(res.status).toBe(401);
    });

    it("should successfully complete onboarding when authenticated", async () => {
      await request(app).get("/organizations");
      const paff = testDbStore.organizations.find((o) => o.slug === "paff");

      const verifyRes = await request(app)
        .post("/organizations/verify-access")
        .send({
          organizationId: paff.id,
          accessCode: "PAFF-2026-X89K",
        });
      const orgToken = `Bearer ${verifyRes.body.token}`;

      const res = await request(app)
        .post(`/organizations/${paff.id}/onboard`)
        .set("Authorization", orgToken)
        .send({
          presidentName: "Qaiser Khan Niazi",
          foundationDate: "2015-06-15T00:00:00.000Z",
          province: "Islamabad",
          city: "Islamabad Capital Territory",
          contactEmail: "president@paff.pk",
          contactPhone: "+92 300 1234567",
        });

      expect(res.status).toBe(200);
      const updatedOrg = res.body.organization ?? res.body;
      expect(updatedOrg.isOnboarded).toBe(true);
      expect(updatedOrg.presidentName).toBe("Qaiser Khan Niazi");
      expect(updatedOrg.contactEmail).toBe("president@paff.pk");
    });
  });

  describe("Admin Organization Provisioning & Code Rotation", () => {
    it("should forbid non-admins from creating an organization", async () => {
      const res = await request(app)
        .post("/admin/organizations")
        .set("Authorization", athleteToken)
        .send({
          name: "Rogue Federation",
          province: "Sindh",
        });
      expect(res.status).toBe(403);
    });

    it("should allow SYSTEM_ADMIN to provision a new organization and receive access code", async () => {
      const res = await request(app)
        .post("/admin/organizations")
        .set("Authorization", adminToken)
        .send({
          name: "Balochistan Armwrestling Association",
          province: "Balochistan",
          city: "Quetta",
          accessCode: "BALOCH-2026-TITAN",
        });

      expect(res.status).toBe(201);
      expect(res.body.organization).toBeDefined();
      expect(res.body.organization.name).toBe("Balochistan Armwrestling Association");
      expect(res.body.plainAccessCode).toBe("BALOCH-2026-TITAN");

      // Verify that this newly created organization can verify its code
      const verifyRes = await request(app)
        .post("/organizations/verify-access")
        .send({
          organizationId: res.body.organization.id,
          accessCode: "BALOCH-2026-TITAN",
        });
      expect(verifyRes.status).toBe(200);
      expect(verifyRes.body.token).toBeDefined();
    });

    it("should allow SYSTEM_ADMIN to rotate an organization access code", async () => {
      await request(app).get("/organizations");
      const paff = testDbStore.organizations.find((o) => o.slug === "paff");

      const rotateRes = await request(app)
        .post(`/admin/organizations/${paff.id}/rotate-code`)
        .set("Authorization", adminToken)
        .send({
          newCode: "PAFF-2026-ROTATED-99",
        });

      expect(rotateRes.status).toBe(200);
      expect(rotateRes.body.plainAccessCode).toBe("PAFF-2026-ROTATED-99");

      // Old code should now be rejected
      const oldVerify = await request(app)
        .post("/organizations/verify-access")
        .send({
          organizationId: paff.id,
          accessCode: "PAFF-2026-X89K",
        });
      expect(oldVerify.status).toBe(401);

      // New code should be accepted
      const newVerify = await request(app)
        .post("/organizations/verify-access")
        .send({
          organizationId: paff.id,
          accessCode: "PAFF-2026-ROTATED-99",
        });
      expect(newVerify.status).toBe(200);
    });
  });

  describe("Tournament Organization Scope Filtering", () => {
    it("should filter events by organizationId", async () => {
      const orgAId = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa";
      const orgBId = "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb";

      testDbStore.events.push(
        {
          id: "11111111-1111-1111-1111-111111111111",
          name: "PAFF National Cup",
          status: "UPCOMING",
          organizationId: orgAId,
          startDate: new Date("2026-12-01"),
        },
        {
          id: "22222222-2222-2222-2222-222222222222",
          name: "EvW Elite Showcase",
          status: "UPCOMING",
          organizationId: orgBId,
          startDate: new Date("2026-12-05"),
        }
      );

      const resA = await request(app)
        .get(`/tournaments/events?organizationId=${orgAId}`)
        .set("Authorization", athleteToken);
      expect(resA.status).toBe(200);
      expect(resA.body.length).toBe(1);
      expect(resA.body[0].name).toBe("PAFF National Cup");

      const resB = await request(app)
        .get(`/tournaments/events?organizationId=${orgBId}`)
        .set("Authorization", athleteToken);
      expect(resB.status).toBe(200);
      expect(resB.body.length).toBe(1);
      expect(resB.body[0].name).toBe("EvW Elite Showcase");
    });
  });
});
