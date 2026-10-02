import { describe, it, expect, beforeEach, vi } from "vitest";
import request from "supertest";
import { testDbStore } from "./setup.js";
import { app } from "../app.js";
import { AdministrationService } from "../services/administration.js";
import { VenueService } from "../services/venue.js";
import { NominationService } from "../services/nomination.js";
import { AuthService } from "../services/auth.js";
import { UserRole } from "@armsphere/types";
import { generateAccessToken, generateRefreshToken, hashPassword } from "@armsphere/cryptography";
import env from "../config/env.js";

describe("Production Security & Hardening Verification Suite", () => {
  const punjabDirectorId = "10000000-0000-0000-0000-000000000001";
  const sindhDirectorId = "10000000-0000-0000-0000-000000000002";
  const nationalDirectorId = "10000000-0000-0000-0000-000000000003";
  const systemAdminId = "10000000-0000-0000-0000-000000000004";
  const sindhAthleteUserId = "20000000-0000-0000-0000-000000000001";
  const sindhAthleteProfileId = "20000000-0000-0000-0000-000000000002";
  const punjabAthleteUserId = "20000000-0000-0000-0000-000000000003";
  const punjabAthleteProfileId = "20000000-0000-0000-0000-000000000004";

  beforeEach(async () => {
    // Reset data stores
    testDbStore.users = [];
    testDbStore.athleteProfiles = [];
    testDbStore.athleteVerifications = [];
    testDbStore.sanctions = [];
    testDbStore.auditLogs = [];
    testDbStore.venuePartners = [];
    testDbStore.talentNominations = [];
    testDbStore.userSessions = [];
    testDbStore.processedStripeEvents = [];

    // Seed Directors & Admins
    testDbStore.users.push(
      {
        id: punjabDirectorId,
        email: "punjab.director@armsphere.com",
        username: "punjab_director",
        role: UserRole.PROVINCIAL_DIRECTOR,
        regionalCoverage: "Punjab",
        fullName: "Punjab Director",
        isActive: true,
      },
      {
        id: sindhDirectorId,
        email: "sindh.director@armsphere.com",
        username: "sindh_director",
        role: UserRole.PROVINCIAL_DIRECTOR,
        regionalCoverage: "Sindh",
        fullName: "Sindh Director",
        isActive: true,
      },
      {
        id: nationalDirectorId,
        email: "national.director@armsphere.com",
        username: "national_director",
        role: UserRole.NATIONAL_DIRECTOR,
        regionalCoverage: null,
        fullName: "National Director",
        isActive: true,
      },
      {
        id: systemAdminId,
        email: "sysadmin@armsphere.com",
        username: "system_admin",
        role: UserRole.SYSTEM_ADMIN,
        regionalCoverage: null,
        fullName: "System Administrator",
        isActive: true,
      },
      {
        id: sindhAthleteUserId,
        email: "sindh.athlete@armsphere.com",
        username: "sindh_athlete",
        role: UserRole.ATHLETE,
        fullName: "Sindh Athlete",
        isActive: true,
      },
      {
        id: punjabAthleteUserId,
        email: "punjab.athlete@armsphere.com",
        username: "punjab_athlete",
        role: UserRole.ATHLETE,
        fullName: "Punjab Athlete",
        isActive: true,
      }
    );

    // Seed Athlete Profiles
    testDbStore.athleteProfiles.push(
      {
        id: sindhAthleteProfileId,
        userId: sindhAthleteUserId,
        displayName: "Sindh Puller",
        province: "Sindh",
        city: "Karachi",
        handedness: "RIGHT",
        dominantArm: "RIGHT",
        weightClass: "SENIOR_86KG",
        leftArmElo: 1200,
        rightArmElo: 1200,
      },
      {
        id: punjabAthleteProfileId,
        userId: punjabAthleteUserId,
        displayName: "Punjab Puller",
        province: "Punjab",
        city: "Lahore",
        handedness: "RIGHT",
        dominantArm: "RIGHT",
        weightClass: "SENIOR_86KG",
        leftArmElo: 1200,
        rightArmElo: 1200,
      }
    );
  });

  // =========================================================================
  // 1. PROVINCIAL JURISDICTION BOUNDARY ENFORCEMENT
  // =========================================================================
  describe("Provincial Jurisdiction Enforcement", () => {
    it("should prevent Provincial Director from reviewing athlete profiles outside jurisdiction", async () => {
      // Punjab Director attempting to verify Sindh athlete profile
      await expect(
        AdministrationService.reviewProfile(sindhAthleteProfileId, punjabDirectorId, "VERIFIED")
      ).rejects.toThrow("You can only review profiles within your provincial jurisdiction.");

      // Punjab Director reviewing Punjab athlete profile succeeds
      const result = await AdministrationService.reviewProfile(
        punjabAthleteProfileId,
        punjabDirectorId,
        "VERIFIED"
      );
      expect(result.status).toBe("VERIFIED");
    });

    it("should prevent Provincial Director from suspending athletes outside jurisdiction", async () => {
      // Punjab Director attempting to suspend Sindh athlete
      await expect(
        AdministrationService.suspendAthlete(
          sindhAthleteProfileId,
          punjabDirectorId,
          "Disciplinary infraction"
        )
      ).rejects.toThrow("You can only suspend athletes within your provincial jurisdiction.");

      // Punjab Director suspending Punjab athlete succeeds
      const result = await AdministrationService.suspendAthlete(
        punjabAthleteProfileId,
        punjabDirectorId,
        "Legitimate provincial suspension"
      );
      expect(result).toBeDefined();
    });

    it("should prevent Provincial Director from verifying venues outside jurisdiction", async () => {
      const sindhVenueId = "30000000-0000-0000-0000-000000000001";
      const punjabVenueId = "30000000-0000-0000-0000-000000000002";

      testDbStore.venuePartners.push(
        {
          id: sindhVenueId,
          name: "Karachi Arm Club",
          city: "Karachi",
          province: "Sindh",
          address: "Clifton Block 2",
          ownerUserId: sindhAthleteUserId,
          isVerified: false,
          createdAt: new Date(),
        },
        {
          id: punjabVenueId,
          name: "Lahore Arm Club",
          city: "Lahore",
          province: "Punjab",
          address: "Gulberg III",
          ownerUserId: punjabAthleteUserId,
          isVerified: false,
          createdAt: new Date(),
        }
      );

      // Punjab Director attempting to verify Sindh venue
      await expect(
        VenueService.verifyVenue(punjabDirectorId, sindhVenueId, "PROVINCIAL_DIRECTOR")
      ).rejects.toThrow("You can only verify venues within your provincial jurisdiction.");

      // Punjab Director verifying Punjab venue succeeds
      const verified = await VenueService.verifyVenue(
        punjabDirectorId,
        punjabVenueId,
        "PROVINCIAL_DIRECTOR"
      );
      expect(verified.isVerified).toBe(true);
    });

    it("should prevent Provincial Director from updating nominations outside jurisdiction", async () => {
      const sindhNominationId = "40000000-0000-0000-0000-000000000001";
      const punjabNominationId = "40000000-0000-0000-0000-000000000002";

      testDbStore.talentNominations.push(
        {
          id: sindhNominationId,
          nominatedByUserId: sindhAthleteUserId,
          nomineeName: "Sindh Prospect",
          city: "Karachi",
          province: "Sindh",
          status: "PENDING",
          createdAt: new Date(),
        },
        {
          id: punjabNominationId,
          nominatedByUserId: punjabAthleteUserId,
          nomineeName: "Punjab Prospect",
          city: "Lahore",
          province: "Punjab",
          status: "PENDING",
          createdAt: new Date(),
        }
      );

      // Punjab Director attempting to update status of Sindh nomination
      await expect(
        NominationService.updateNominationStatus(
          punjabDirectorId,
          sindhNominationId,
          "CONTACTED",
          "PROVINCIAL_DIRECTOR"
        )
      ).rejects.toThrow("You can only update nomination status within your provincial jurisdiction.");

      // Punjab Director updating status of Punjab nomination succeeds
      const updated = await NominationService.updateNominationStatus(
        punjabDirectorId,
        punjabNominationId,
        "CONTACTED",
        "PROVINCIAL_DIRECTOR"
      );
      expect(updated.status).toBe("CONTACTED");
    });

    it("should scope NominationService.getNominations to director province", async () => {
      testDbStore.talentNominations.push(
        {
          id: "nom-sindh",
          nominatedByUserId: sindhAthleteUserId,
          nomineeName: "Sindh Prospect",
          city: "Karachi",
          province: "Sindh",
          status: "PENDING",
          createdAt: new Date(),
        },
        {
          id: "nom-punjab",
          nominatedByUserId: punjabAthleteUserId,
          nomineeName: "Punjab Prospect",
          city: "Lahore",
          province: "Punjab",
          status: "PENDING",
          createdAt: new Date(),
        }
      );

      // Punjab Director query should only return Punjab nominations
      const nominations = await NominationService.getNominations(
        { limit: 20, offset: 0 },
        punjabDirectorId,
        "PROVINCIAL_DIRECTOR"
      );

      expect(nominations).toHaveLength(1);
      expect(nominations[0].province).toBe("Punjab");
    });
  });

  // =========================================================================
  // 2. NATIONAL & SYSTEM ADMIN AUTHORITY OVERRIDE
  // =========================================================================
  describe("National and System Admin Cross-Province Authorization", () => {
    it("should allow National Director and System Admin to review and suspend across all provinces", async () => {
      // National Director reviews Sindh athlete
      const ndReview = await AdministrationService.reviewProfile(
        sindhAthleteProfileId,
        nationalDirectorId,
        "VERIFIED"
      );
      expect(ndReview.status).toBe("VERIFIED");

      // System Admin suspends Punjab athlete
      const saSuspend = await AdministrationService.suspendAthlete(
        punjabAthleteProfileId,
        systemAdminId,
        "System administrative sanction"
      );
      expect(saSuspend).toBeDefined();
    });

    it("should allow System Admin and National Director to verify venues anywhere", async () => {
      const sindhVenueId = "30000000-0000-0000-0000-000000000003";
      testDbStore.venuePartners.push({
        id: sindhVenueId,
        name: "National Arm Arena",
        city: "Karachi",
        province: "Sindh",
        address: "Shahrah-e-Faisal",
        ownerUserId: sindhAthleteUserId,
        isVerified: false,
        createdAt: new Date(),
      });

      const verified = await VenueService.verifyVenue(
        nationalDirectorId,
        sindhVenueId,
        "NATIONAL_DIRECTOR"
      );
      expect(verified.isVerified).toBe(true);
    });
  });

  // =========================================================================
  // 3. SESSION SECURITY & TOKEN COMPROMISE DETECTION
  // =========================================================================
  describe("Session Security & Token Reuse Detection", () => {
    it("should detect rotated refresh token reuse and invalidate the entire token family", async () => {
      const userId = sindhAthleteUserId;
      const familyId = "fam-security-test-123";

      // 1. Create original valid session
      const originalToken = generateRefreshToken(
        userId,
        "sindh.athlete@armsphere.com",
        UserRole.ATHLETE,
        familyId,
        env.JWT_REFRESH_SECRET
      );
      const crypto = await import("crypto");
      const originalHash = crypto.createHash("sha256").update(originalToken).digest("hex");

      testDbStore.userSessions.push({
        id: "session-1",
        userId,
        tokenFamily: familyId,
        refreshTokenHash: originalHash,
        isRevoked: true, // Already revoked due to previous rotation
        expiresAt: new Date(Date.now() + 1000 * 60 * 60 * 24),
      });

      // 2. Active session in the family
      testDbStore.userSessions.push({
        id: "session-2",
        userId,
        tokenFamily: familyId,
        refreshTokenHash: "hash-secondary-token",
        isRevoked: false,
        expiresAt: new Date(Date.now() + 1000 * 60 * 60 * 24),
      });

      // 3. Attacker presents the old, already-revoked token to /auth/refresh
      const response = await request(app)
        .post("/auth/refresh")
        .send({ refreshToken: originalToken });

      expect(response.status).toBe(401);
      expect(response.body.detail).toContain("security compromise detected");

      // 4. Verify all sessions in the family are now revoked
      const familySessions = testDbStore.userSessions.filter((s) => s.tokenFamily === familyId);
      expect(familySessions.every((s) => s.isRevoked)).toBe(true);

      // 5. Verify security audit log record was created
      const alertLogs = testDbStore.auditLogs.filter((l) => l.action === "AUTH_TOKEN_REUSE_ALERT");
      expect(alertLogs.length).toBeGreaterThanOrEqual(1);
    });
  });

  // =========================================================================
  // 4. STRIPE WEBHOOK DEFENSE & FAIL-CLOSED GATING
  // =========================================================================
  describe("Stripe Webhook Defense & Fail-Closed Gating", () => {
    it("should reject webhook requests missing stripe-signature header with 400", async () => {
      const response = await request(app)
        .post("/payments/webhook")
        .send({ id: "evt_test", object: "event" });

      expect(response.status).toBe(400);
      expect(response.body.error).toBe("Missing stripe-signature header");
    });

    it("should fail closed with 503 if webhook secret is unset or empty", async () => {
      const originalSecret = env.STRIPE_WEBHOOK_SECRET;
      try {
        (env as any).STRIPE_WEBHOOK_SECRET = "";

        const response = await request(app)
          .post("/payments/webhook")
          .set("stripe-signature", "t=123,v1=fake_signature")
          .send({ id: "evt_test" });

        expect(response.status).toBe(503);
        expect(response.body.error).toBe("Webhook processing unavailable");
      } finally {
        (env as any).STRIPE_WEBHOOK_SECRET = originalSecret;
      }
    });

    it("should reject invalid webhook signatures with 400", async () => {
      const response = await request(app)
        .post("/payments/webhook")
        .set("stripe-signature", "t=123,v1=tampered_invalid_signature")
        .send({ id: "evt_test", type: "payment_intent.succeeded" });

      expect(response.status).toBe(400);
      expect(response.text).toContain("Webhook Error");
    });
  });
});
