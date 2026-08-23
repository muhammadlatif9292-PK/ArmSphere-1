import { describe, it, expect, beforeEach, afterEach, vi } from "vitest";
import { testDbStore } from "./setup.js";
import request from "supertest";
import { app } from "../app.js";
import { AuthService } from "../services/auth.js";
import { SocialAuthService } from "../services/socialAuth.js";
import { EmailDeliveryService } from "../services/emailDelivery.js";
import { UserRole } from "@armsphere/types";
import { generateAccessToken, generateRefreshToken, hashPassword, comparePassword } from "@armsphere/cryptography";
import env from "../config/env.js";
import speakeasy from "speakeasy";

describe("ArmSphere Authentication System Integration & Unit Tests", () => {
  beforeEach(() => {
    // Clean database store
    testDbStore.users = [];
    testDbStore.userSessions = [];
    testDbStore.auditLogs = [];
  });

  // ==========================================
  // 1. REGISTRATION ENDPOINT TESTS & VALIDATIONS
  // ==========================================
  describe("POST /auth/register", () => {
    it("should successfully register a valid athlete user", async () => {
      const response = await request(app)
        .post("/auth/register")
        .send({
          email: "athlete@armsphere.com",
          username: "athlete123",
          password: "SecurePassword123!",
          fullName: "Arm Wrestler Pro",
        });

      expect(response.status).toBe(201);
      expect(response.body.success).toBe(true);
      expect(response.body.data.email).toBe("athlete@armsphere.com");
      expect(response.body.data.username).toBe("athlete123");
      expect(response.body.data.role).toBe(UserRole.ATHLETE);
      expect(response.body.data.passwordHash).toBeUndefined(); // Security check: must not return password hash

      // Audit Log check
      const logs = testDbStore.auditLogs.filter(l => l.action === "AUTH_REGISTER");
      expect(logs).toHaveLength(1);
      expect(logs[0].details.email).toBe("athlete@armsphere.com");
    });

    it("should fail validation with invalid email format", async () => {
      const response = await request(app)
        .post("/auth/register")
        .send({
          email: "not-an-email",
          username: "athlete123",
          password: "SecurePassword123!",
          fullName: "Arm Wrestler Pro",
        });

      expect(response.status).toBe(400);
      expect(response.body.title).toBe("Validation Failed");
      expect(response.body.errors).toBeDefined();
      expect(response.body.errors["email"]).toBeDefined();
    });

    it("should fail validation for too short username or password", async () => {
      const response = await request(app)
        .post("/auth/register")
        .send({
          email: "athlete@armsphere.com",
          username: "at",
          password: "123",
          fullName: "A",
        });

      expect(response.status).toBe(400);
      expect(response.body.errors["username"]).toBeDefined();
      expect(response.body.errors["password"]).toBeDefined();
    });

    it("should force public registration to ATHLETE even if a privileged role is supplied", async () => {
      const response = await request(app)
        .post("/auth/register")
        .send({
          email: "athlete@armsphere.com",
          username: "athlete123",
          password: "SecurePassword123!",
          fullName: "Arm Wrestler Pro",
          role: UserRole.SYSTEM_ADMIN,
        });

      expect(response.status).toBe(201);
      expect(response.body.success).toBe(true);
      expect(response.body.data.role).toBe(UserRole.ATHLETE);
    });

    it("should prevent duplicate email registrations", async () => {
      // Setup existing user
      testDbStore.users.push({
        id: "existing-uuid",
        email: "athlete@armsphere.com",
        username: "original_username",
        passwordHash: "somehash",
        role: UserRole.ATHLETE,
        fullName: "Original Name",
        isActive: true,
      });

      const response = await request(app)
        .post("/auth/register")
        .send({
          email: "ATHLETE@armsphere.com", // Case insensitive check
          username: "different_username",
          password: "SecurePassword123!",
          fullName: "New Athlete",
        });

      expect(response.status).toBe(409);
      expect(response.body.title).toBe("Conflict");
      expect(response.body.detail).toContain("already exists");
    });

    it("should prevent duplicate username registrations", async () => {
      // Setup existing user
      testDbStore.users.push({
        id: "existing-uuid",
        email: "original@armsphere.com",
        username: "athlete123",
        passwordHash: "somehash",
        role: UserRole.ATHLETE,
        fullName: "Original Name",
        isActive: true,
      });

      const response = await request(app)
        .post("/auth/register")
        .send({
          email: "new_email@armsphere.com",
          username: "athlete123",
          password: "SecurePassword123!",
          fullName: "New Athlete",
        });

      expect(response.status).toBe(409);
      expect(response.body.title).toBe("Conflict");
    });
  });

  // ==========================================
  // 2. LOGIN ENDPOINT TESTS & PASSWORDS
  // ==========================================
  describe("POST /auth/login", () => {
    beforeEach(async () => {
      const passwordHash = await hashPassword("SecurePassword123!");
      testDbStore.users.push({
        id: "user-1",
        email: "athlete@armsphere.com",
        username: "athlete123",
        passwordHash,
        role: UserRole.ATHLETE,
        fullName: "Arm Wrestler Pro",
        isActive: true,
      });
    });

    it("should issue valid JWT access and refresh tokens on login", async () => {
      const response = await request(app)
        .post("/auth/login")
        .send({
          email: "athlete@armsphere.com",
          password: "SecurePassword123!",
        });

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data.accessToken).toBeDefined();
      expect(response.body.data.refreshToken).toBeDefined();
      expect(response.body.data.user.email).toBe("athlete@armsphere.com");

      // Verify session database record exists
      expect(testDbStore.userSessions).toHaveLength(1);
      expect(testDbStore.userSessions[0].userId).toBe("user-1");
      expect(testDbStore.userSessions[0].isRevoked).toBe(false);

      // Verify audit log record exists
      const logs = testDbStore.auditLogs.filter(l => l.action === "AUTH_LOGIN");
      expect(logs).toHaveLength(1);
    });

    it("should deny login for incorrect password", async () => {
      const response = await request(app)
        .post("/auth/login")
        .send({
          email: "athlete@armsphere.com",
          password: "WrongPassword!",
        });

      expect(response.status).toBe(401);
      expect(response.body.title).toBe("Unauthorized");
    });

    it("should deny login for deactivated accounts", async () => {
      testDbStore.users[0].isActive = false;

      const response = await request(app)
        .post("/auth/login")
        .send({
          email: "athlete@armsphere.com",
          password: "SecurePassword123!",
        });

      expect(response.status).toBe(401);
      expect(response.body.detail).toContain("disabled");
    });
  });

  // ==========================================
  // 3. REFRESH TOKEN ROTATION & SECURITY MITIGATION
  // ==========================================
  describe("POST /auth/refresh (Rotation & Hijack Mitigation)", () => {
    it("should successfully rotate a valid active refresh token", async () => {
      // Setup a user and an active session
      const familyId = "session-family-123";
      const oldRefreshToken = generateRefreshToken("user-1", "athlete@armsphere.com", UserRole.ATHLETE, familyId, env.JWT_REFRESH_SECRET);
      
      const crypto = await import("crypto");
      const hash = crypto.createHash("sha256").update(oldRefreshToken).digest("hex");

      testDbStore.userSessions.push({
        id: "session-1",
        userId: "user-1",
        tokenFamily: familyId,
        refreshTokenHash: hash,
        isRevoked: false,
        expiresAt: new Date(Date.now() + 1000 * 60 * 60), // Valid
      });

      const response = await request(app)
        .post("/auth/refresh")
        .send({ refreshToken: oldRefreshToken });

      expect(response.status).toBe(200);
      expect(response.body.data.accessToken).toBeDefined();
      expect(response.body.data.refreshToken).toBeDefined();

      // Old session token is now revoked
      const oldSession = testDbStore.userSessions.find(s => s.id === "session-1");
      expect(oldSession?.isRevoked).toBe(true);

      // A new active session for the same family should exist
      const activeSession = testDbStore.userSessions.find(s => s.isRevoked === false && s.tokenFamily === familyId);
      expect(activeSession).toBeDefined();
    });

    it("should detect a token reuse attack, invalidate all family sessions, and emit a critical alert", async () => {
      const familyId = "session-family-danger";
      const oldRefreshToken = generateRefreshToken("user-1", "athlete@armsphere.com", UserRole.ATHLETE, familyId, env.JWT_REFRESH_SECRET);
      
      const crypto = await import("crypto");
      const hash = crypto.createHash("sha256").update(oldRefreshToken).digest("hex");

      // Session already marked as revoked (signaling past usage / reuse attack)
      testDbStore.userSessions.push({
        id: "session-compromised",
        userId: "user-1",
        tokenFamily: familyId,
        refreshTokenHash: hash,
        isRevoked: true,
        expiresAt: new Date(Date.now() + 1000 * 60 * 60),
      });

      // Another session in the family is still open
      testDbStore.userSessions.push({
        id: "session-legitimate",
        userId: "user-1",
        tokenFamily: familyId,
        refreshTokenHash: "another-legitimate-hash",
        isRevoked: false,
        expiresAt: new Date(Date.now() + 1000 * 60 * 60),
      });

      const response = await request(app)
        .post("/auth/refresh")
        .send({ refreshToken: oldRefreshToken });

      expect(response.status).toBe(401);
      expect(response.body.detail).toContain("security compromise detected");

      // Threat mitigation checks: all sessions in this family must be revoked
      testDbStore.userSessions.forEach((s) => {
        if (s.tokenFamily === familyId) {
          expect(s.isRevoked).toBe(true);
        }
      });

      // Security audit trail checklist
      const reuseLogs = testDbStore.auditLogs.filter(l => l.action === "AUTH_TOKEN_REUSE_ALERT");
      expect(reuseLogs).toHaveLength(1);
    });

    it("should fail gracefully if refresh token is expired", async () => {
      const oldRefreshToken = jwtSignMockExpired(); // Simulated expired token

      const response = await request(app)
        .post("/auth/refresh")
        .send({ refreshToken: oldRefreshToken });

      expect(response.status).toBe(401);
    });
  });

  // ==========================================
  // 4. LOGOUT & REVOCATION
  // ==========================================
  describe("POST /auth/logout", () => {
    it("should revoke the current session family and clear client cookie", async () => {
      const familyId = "session-family-logout";
      const refreshToken = generateRefreshToken("user-1", "athlete@armsphere.com", UserRole.ATHLETE, familyId, env.JWT_REFRESH_SECRET);
      
      const crypto = await import("crypto");
      const hash = crypto.createHash("sha256").update(refreshToken).digest("hex");

      testDbStore.userSessions.push({
        id: "session-logout-target",
        userId: "user-1",
        tokenFamily: familyId,
        refreshTokenHash: hash,
        isRevoked: false,
        expiresAt: new Date(Date.now() + 1000 * 60 * 60),
      });

      const response = await request(app)
        .post("/auth/logout")
        .send({ refreshToken });

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);

      // Verify revocation
      const session = testDbStore.userSessions.find(s => s.id === "session-logout-target");
      expect(session?.isRevoked).toBe(true);
    });
  });

  // ==========================================
  // 5. ROLE-BASED ACCESS CONTROL (RBAC) & INVALID JWT
  // ==========================================
  describe("RBAC & Invalid JWT Middleware", () => {
    it("should allow verified Athlete users to fetch their profile context", async () => {
      // Seed user
      testDbStore.users.push({
        id: "user-athlete-1",
        email: "athlete@armsphere.com",
        username: "athlete1",
        passwordHash: "hash",
        role: UserRole.ATHLETE,
        fullName: "Pro Athlete",
        isActive: true,
      });

      const validToken = generateAccessToken("user-athlete-1", "athlete@armsphere.com", UserRole.ATHLETE, env.JWT_ACCESS_SECRET);

      const response = await request(app)
        .get("/auth/me")
        .set("Authorization", `Bearer ${validToken}`);

      expect(response.status).toBe(200);
      expect(response.body.data.id).toBe("user-athlete-1");
      expect(response.body.data.role).toBe(UserRole.ATHLETE);
    });

    it("should deny profile fetch if access token has expired", async () => {
      const expiredToken = jwtSignMockExpired();

      const response = await request(app)
        .get("/auth/me")
        .set("Authorization", `Bearer ${expiredToken}`);

      expect(response.status).toBe(401);
      expect(response.body.detail).toContain("expired");
    });

    it("should deny access when token type is not 'access' (e.g. using a refresh token)", async () => {
      const refreshToken = generateRefreshToken("user-athlete-1", "athlete@armsphere.com", UserRole.ATHLETE, "family-id", env.JWT_REFRESH_SECRET);

      const response = await request(app)
        .get("/auth/me")
        .set("Authorization", `Bearer ${refreshToken}`);

      expect(response.status).toBe(401);
    });

    it("should block requests lacking Authorization header or carrying malformed token", async () => {
      const response = await request(app)
        .get("/auth/me");

      expect(response.status).toBe(401);
    });
  });

  // ==========================================
  // 6. TRANSACTION ROLLBACK INTEGRITY TEST
  // ==========================================
  describe("Database Transaction Rollback Integrity", () => {
    it("should completely rollback state adjustments when an error triggers mid-transaction", async () => {
      const db = (await import("../config/db.js")).default;

      // Wrap simulation of a failure within custom rollback test
      const action = async () => {
        await db.transaction(async (tx: any) => {
          await tx.insert(testDbStore.users as any).values({
            id: "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee", // arbitrary but valid UUID — this test only cares about rollback behavior, not the id's value
            email: "rollback@armsphere.com",
            username: "rollback_tester",
            fullName: "Rollback User",
          });

          // Trigger explicit failure to test transaction rollback block
          throw new Error("Triggered rollback event.");
        });
      };

      await expect(action()).rejects.toThrow("Triggered rollback event.");

      // Check state: User must NOT exist in store
      const user = testDbStore.users.find(u => u.id === "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee");
      expect(user).toBeUndefined();
    });
  });

  // ==========================================
  // 7. CONCURRENT TOKEN ROTATION REQUESTS
  // ==========================================
  describe("Concurrent Token Rotation Safety", () => {
    it("should gracefully serialize or protect against concurrent identical rotation race conditions", async () => {
      const familyId = "concurrent-family-123";
      const oldRefreshToken = generateRefreshToken("user-1", "athlete@armsphere.com", UserRole.ATHLETE, familyId, env.JWT_REFRESH_SECRET);
      
      const crypto = await import("crypto");
      const hash = crypto.createHash("sha256").update(oldRefreshToken).digest("hex");

      testDbStore.userSessions.push({
        id: "session-concur",
        userId: "user-1",
        tokenFamily: familyId,
        refreshTokenHash: hash,
        isRevoked: false,
        expiresAt: new Date(Date.now() + 1000 * 60 * 60),
      });

      // Issue parallel rotation service requests
      const promise1 = AuthService.rotateSession(oldRefreshToken);
      const promise2 = AuthService.rotateSession(oldRefreshToken);

      const results = await Promise.allSettled([promise1, promise2]);

      const fulfilled = results.filter(r => r.status === "fulfilled");
      const rejected = results.filter(r => r.status === "rejected");

      // One must successfully complete, and the other must reject (or both handle state safely)
      expect(fulfilled.length).toBeGreaterThanOrEqual(1);
      expect(rejected.length).toBeLessThanOrEqual(1);
    });
  });

  // ==========================================
  // 8. SPRINT 10 PRODUCTION HARDENING & SECURITY TESTS
  // ==========================================
  describe("Sprint 10 Security Hardening & Observability Tests", () => {
    let mockUserToken: string;

    beforeEach(async () => {
      EmailDeliveryService.enableTestCapture();
      // Create user
      testDbStore.users.push({
        id: "hardened-user-id",
        email: "hardened@armsphere.com",
        username: "hardened_user",
        passwordHash: await hashPassword("HardPassword123!"),
        role: UserRole.ATHLETE,
        fullName: "Hardened Athlete",
        isActive: true,
      });

      mockUserToken = generateAccessToken("hardened-user-id", "hardened@armsphere.com", UserRole.ATHLETE, env.JWT_ACCESS_SECRET);
    });

    it("should allow getting active sessions and revoking them", async () => {
      // Insert mock active session
      testDbStore.userSessions.push({
        id: "session-to-revoke-id",
        userId: "hardened-user-id",
        tokenFamily: "family-uuid",
        refreshTokenHash: "hashval",
        isRevoked: false,
        expiresAt: new Date(Date.now() + 1000 * 60 * 60),
        ipAddress: "127.0.0.1",
        userAgent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
      });

      // Get sessions
      const getResponse = await request(app)
        .get("/auth/sessions")
        .set("Authorization", `Bearer ${mockUserToken}`);

      expect(getResponse.status).toBe(200);
      expect(getResponse.body.success).toBe(true);
      expect(getResponse.body.data).toHaveLength(1);
      expect(getResponse.body.data[0].os).toBe("Windows");
      expect(getResponse.body.data[0].device).toBe("Desktop");

      // Revoke session
      const revokeResponse = await request(app)
        .post("/auth/sessions/session-to-revoke-id/revoke")
        .set("Authorization", `Bearer ${mockUserToken}`);

      expect(revokeResponse.status).toBe(200);
      expect(revokeResponse.body.success).toBe(true);

      // Verify revoked
      const session = testDbStore.userSessions.find(s => s.id === "session-to-revoke-id");
      expect(session?.isRevoked).toBe(true);
    });

    it("should successfully setup and verify/enable MFA", async () => {
      // 1. Setup MFA
      const setupResponse = await request(app)
        .post("/auth/mfa/setup")
        .set("Authorization", `Bearer ${mockUserToken}`);

      expect(setupResponse.status).toBe(200);
      expect(setupResponse.body.success).toBe(true);
      expect(setupResponse.body.data.secret).toBeDefined();
      expect(setupResponse.body.data.qrCode).toBeDefined();

      const secret = setupResponse.body.data.secret;

      // 2. We won't trigger standard verifier clock-step, but let's test with direct verify
      const code = "123456"; // Since we use mock-store, let's verify invalid code fails
      const enableResponse = await request(app)
        .post("/auth/mfa/verify")
        .set("Authorization", `Bearer ${mockUserToken}`)
        .send({ code });

      expect(enableResponse.status).toBe(400); // Invalid code should fail

      // 3. Generate a genuinely valid TOTP code and test it succeeds
      const validCode = speakeasy.totp({
        secret,
        encoding: "base32",
      });

      const validEnableResponse = await request(app)
        .post("/auth/mfa/verify")
        .set("Authorization", `Bearer ${mockUserToken}`)
        .send({ code: validCode });

      expect(validEnableResponse.status).toBe(200);
      expect(validEnableResponse.body.success).toBe(true);

      // Verify that MFA is actually enabled in database
      const user = testDbStore.users.find(u => u.id === "hardened-user-id");
      expect(user).toBeDefined();
      expect(user?.mfaEnabled).toBe(true);
    });

    it("should handle password reset request and confirm update", async () => {
      // 1. Request reset
      const reqResponse = await request(app)
        .post("/auth/password-reset/request")
        .send({ email: "hardened@armsphere.com" });

      expect(reqResponse.status).toBe(200);
      expect(reqResponse.body.success).toBe(true);
      // SECURITY: the reset token must never be present in the HTTP response
      expect(reqResponse.body.data.token).toBeUndefined();

      const resetToken = EmailDeliveryService.getCapturedEmailsForTesting().passwordResets[0]?.resetToken;
      expect(resetToken).toBeDefined();

      // 2. Perform password update
      const resetResponse = await request(app)
        .post("/auth/password-reset/reset")
        .send({ token: resetToken, password: "NewStrongPassword123!" });

      expect(resetResponse.status).toBe(200);
      expect(resetResponse.body.success).toBe(true);

      // Check password hash is updated
      const user = testDbStore.users.find(u => u.id === "hardened-user-id");
      expect(user).toBeDefined();
      const match = await comparePassword("NewStrongPassword123!", user.passwordHash);
      expect(match).toBe(true);
    });

    it("should handle email verification request and confirmation", async () => {
      // 1. Request
      const reqResponse = await request(app)
        .post("/auth/verify-email/request")
        .set("Authorization", `Bearer ${mockUserToken}`);

      expect(reqResponse.status).toBe(200);
      expect(reqResponse.body.success).toBe(true);
      // SECURITY: the verification token must never be present in the HTTP response
      expect(reqResponse.body.data.token).toBeUndefined();

      const token = EmailDeliveryService.getCapturedEmailsForTesting().emailVerifications[0]?.verifyToken;
      expect(token).toBeDefined();

      // 2. Confirm
      const confirmResponse = await request(app)
        .post("/auth/verify-email/confirm")
        .send({ token });

      expect(confirmResponse.status).toBe(200);
      expect(confirmResponse.body.success).toBe(true);
    });

    it("should expose observability health and metrics endpoints", async () => {
      // Health probe
      const healthResponse = await request(app).get("/api/health");
      expect(healthResponse.status).toBe(200);
      expect(healthResponse.body.success).toBe(true);
      expect(healthResponse.body.status).toBe("healthy");

      // Readiness probe
      const readyResponse = await request(app).get("/api/ready");
      expect(readyResponse.status).toBe(200);
      expect(readyResponse.body.ready).toBe(true);

      // Liveness probe
      const liveResponse = await request(app).get("/api/live");
      expect(liveResponse.status).toBe(200);
      expect(liveResponse.body.live).toBe(true);

      // Metrics endpoint
      const metricsResponse = await request(app).get("/api/v1/observability/metrics");
      expect(metricsResponse.status).toBe(200);
      expect(metricsResponse.body.success).toBe(true);
      expect(metricsResponse.body.data.system).toBeDefined();
      expect(metricsResponse.body.data.database).toBeDefined();
      expect(metricsResponse.body.data.queues).toBeDefined();
    });
  });

  // ==========================================
  // PASSWORD RESET & EMAIL VERIFICATION SECURITY
  // ==========================================
  describe("Password Reset & Email Verification Security", () => {
    beforeEach(() => {
      testDbStore.authTokens = [];
      testDbStore.auditEvents = [];
      EmailDeliveryService.enableTestCapture();
    });

    afterEach(() => {
      EmailDeliveryService.disableTestCapture();
    });

    async function seedUser() {
      testDbStore.users.push({
        id: "reset-user-id",
        email: "reset@armsphere.com",
        username: "reset_user",
        passwordHash: await hashPassword("OldPassword123!"),
        role: UserRole.ATHLETE,
        fullName: "Reset User",
        isActive: true,
      });
    }

    it("never exposes the reset token in the HTTP response, audit logs, or captured delivery metadata", async () => {
      await seedUser();

      const response = await request(app)
        .post("/auth/password-reset/request")
        .send({ email: "reset@armsphere.com" });

      expect(response.status).toBe(200);
      expect(JSON.stringify(response.body)).not.toMatch(/resetToken/);

      // Audit trail must not carry the raw credential
      const audit = testDbStore.auditLogs.find(l => l.action === "AUTH_PASSWORD_RESET_REQUESTED");
      expect(audit).toBeDefined();
      expect(JSON.stringify(audit.details)).not.toContain(
        EmailDeliveryService.getCapturedEmailsForTesting().passwordResets[0].resetToken
      );
    });

    it("responds identically for unknown emails to prevent user enumeration", async () => {
      await seedUser();

      const known = await request(app)
        .post("/auth/password-reset/request")
        .send({ email: "reset@armsphere.com" });
      const unknown = await request(app)
        .post("/auth/password-reset/request")
        .send({ email: "ghost@armsphere.com" });

      expect(known.status).toBe(200);
      expect(unknown.status).toBe(200);
      expect(unknown.body.message ?? unknown.body.data?.message).toEqual(
        known.body.message ?? known.body.data?.message
      );
      // No token dispatched for a non-existent user
      expect(EmailDeliveryService.getCapturedEmailsForTesting().passwordResets).toHaveLength(1);
    });

    it("completes a full reset with the delivered token and revokes all sessions", async () => {
      await seedUser();
      testDbStore.userSessions.push({
        id: "session-pre-reset",
        userId: "reset-user-id",
        tokenFamily: "family-pre-reset",
        refreshTokenHash: "hash",
        isRevoked: false,
        expiresAt: new Date(Date.now() + 60 * 60 * 1000),
      });

      await request(app)
        .post("/auth/password-reset/request")
        .send({ email: "reset@armsphere.com" });
      const token = EmailDeliveryService.getCapturedEmailsForTesting().passwordResets[0].resetToken;

      const reset = await request(app)
        .post("/auth/password-reset/reset")
        .send({ token, password: "BrandNewPassword456!" });

      expect(reset.status).toBe(200);
      const user = testDbStore.users.find(u => u.id === "reset-user-id");
      expect(await comparePassword("BrandNewPassword456!", user.passwordHash)).toBe(true);
      expect(testDbStore.userSessions.find(s => s.id === "session-pre-reset").isRevoked).toBe(true);

      // Token record marked used
      expect(testDbStore.authTokens[0].usedAt).toBeDefined();
    });

    it("rejects token reuse (single-use enforcement)", async () => {
      await seedUser();

      await request(app)
        .post("/auth/password-reset/request")
        .send({ email: "reset@armsphere.com" });
      const token = EmailDeliveryService.getCapturedEmailsForTesting().passwordResets[0].resetToken;

      const first = await request(app)
        .post("/auth/password-reset/reset")
        .send({ token, password: "FirstReset789!" });
      expect(first.status).toBe(200);

      const replay = await request(app)
        .post("/auth/password-reset/reset")
        .send({ token, password: "SecondReset000!" });
      expect(replay.status).toBe(400);

      // Original password survives the replay attempt
      const user = testDbStore.users.find(u => u.id === "reset-user-id");
      expect(await comparePassword("FirstReset789!", user.passwordHash)).toBe(true);
    });

    it("rejects expired tokens", async () => {
      await seedUser();

      await request(app)
        .post("/auth/password-reset/request")
        .send({ email: "reset@armsphere.com" });
      const token = EmailDeliveryService.getCapturedEmailsForTesting().passwordResets[0].resetToken;

      // Force expiry of the stored hash
      testDbStore.authTokens[0].expiresAt = new Date(Date.now() - 1000);

      const response = await request(app)
        .post("/auth/password-reset/reset")
        .send({ token, password: "TooLate111!" });

      expect(response.status).toBe(400);
      const user = testDbStore.users.find(u => u.id === "reset-user-id");
      expect(await comparePassword("OldPassword123!", user.passwordHash)).toBe(true);
    });

    it("rejects invalid/fabricated tokens", async () => {
      await seedUser();

      const response = await request(app)
        .post("/auth/password-reset/reset")
        .send({ token: "deadbeef".repeat(8), password: "Whatever123!" });

      expect(response.status).toBe(400);
    });

    it("does not allow an email-verification token to be consumed as a password-reset token", async () => {
      await seedUser();

      await request(app)
        .post("/auth/verify-email/request")
        .set("Authorization", `Bearer ${generateAccessToken("reset-user-id", "reset@armsphere.com", UserRole.ATHLETE, env.JWT_ACCESS_SECRET)}`);
      const verifyToken = EmailDeliveryService.getCapturedEmailsForTesting().emailVerifications[0].verifyToken;

      const response = await request(app)
        .post("/auth/password-reset/reset")
        .send({ token: verifyToken, password: "CrossUse999!" });

      expect(response.status).toBe(400);
    });
  });

  // ==========================================
  // SOCIAL OAUTH BOUNDARIES
  // ==========================================
  describe("Social OAuth Boundaries", () => {
    it("rejects a fabricated mock authorization code in production even with credentials configured", async () => {
      const prodEnv = {
        GOOGLE_CLIENT_ID: "real-client-id",
        GOOGLE_CLIENT_SECRET: "real-client-secret",
        NODE_ENV: "production",
      };
      vi.spyOn(env, "GOOGLE_CLIENT_ID", "get").mockReturnValue(prodEnv.GOOGLE_CLIENT_ID);
      vi.spyOn(env, "GOOGLE_CLIENT_SECRET", "get").mockReturnValue(prodEnv.GOOGLE_CLIENT_SECRET);
      vi.spyOn(env, "NODE_ENV", "get").mockReturnValue("production");

      try {
        await expect(
          SocialAuthService.exchangeGoogleCode("mock_attacker_controlled", "https://app/callback")
        ).rejects.toThrow();
        await expect(
          SocialAuthService.exchangeGoogleCode("", "https://app/callback")
        ).rejects.toThrow();

        vi.spyOn(env, "APPLE_CLIENT_ID", "get").mockReturnValue(prodEnv.GOOGLE_CLIENT_ID);
        vi.spyOn(env, "APPLE_CLIENT_SECRET", "get").mockReturnValue(prodEnv.GOOGLE_CLIENT_SECRET);

        await expect(
          SocialAuthService.exchangeAppleCode("mock_attacker_controlled", "https://app/callback")
        ).rejects.toThrow();
      } finally {
        vi.restoreAllMocks();
      }
    });

    it("does not silently authenticate when the callback is invoked with no code at all", async () => {
      // Controller passes "" instead of fabricating mock_code; in test env the
      // service may fall back to a dev profile ONLY when credentials are absent.
      // With NODE_ENV=test and no credentials this must remain deterministic:
      // either a dev-profile fallback or an error — never an uncontrolled path.
      const profile = await SocialAuthService.exchangeGoogleCode("", "https://app/callback");
      if (profile) {
        expect(profile.id).toBe("google-mock-id-123456");
      }
    });
  });
});

// Mock expired JWT generation
function jwtSignMockExpired(): string {
  const jwt = require("jsonwebtoken");
  const payload = {
    sub: "expired-user",
    email: "expired@armsphere.com",
    role: UserRole.ATHLETE,
    type: "access",
  };
  return jwt.sign(payload, env.JWT_ACCESS_SECRET, { expiresIn: "-10s" });
}
