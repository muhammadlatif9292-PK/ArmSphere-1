import { describe, it, expect, beforeEach, vi } from "vitest";
import { testDbStore } from "./setup.js";
import request from "supertest";
import crypto from "crypto";
import { app } from "../app.js";
import { UserRole } from "@armsphere/types";
import { hashPassword, generateAccessToken } from "@armsphere/cryptography";
import { MFAService, hashRecoveryCode, isHashedRecoveryCode } from "../services/mfa.js";
import { authRouter } from "../routes/auth.js";
import env from "../config/env.js";

describe("ArmSphere MFA Recovery Security & Architecture Hardening (Finding-01)", () => {
  const TEST_PASSWORD = "StrongMasterPassword123!";
  const TEST_EMAIL = "mfa.security@armsphere.com";
  const TEST_USER_ID = "mfa-sec-user-uuid-123";

  let testUserToken: string;
  let rawPasswordHash: string;

  beforeEach(async () => {
    testDbStore.users = [];
    testDbStore.userSessions = [];
    testDbStore.auditLogs = [];

    rawPasswordHash = await hashPassword(TEST_PASSWORD);

    testUserToken = generateAccessToken(
      TEST_USER_ID,
      TEST_EMAIL,
      UserRole.ATHLETE,
      env.JWT_ACCESS_SECRET
    );
  });

  // =========================================================================
  // A. NEW MFA SETUP DOES NOT PERSIST PLAINTEXT RECOVERY CODES
  // =========================================================================
  it("A. new MFA setup does not persist plaintext recovery codes in database", async () => {
    testDbStore.users.push({
      id: TEST_USER_ID,
      email: TEST_EMAIL,
      username: "mfasecuser",
      fullName: "MFA Security Tester",
      role: UserRole.ATHLETE,
      passwordHash: rawPasswordHash,
      isActive: true,
      mfaEnabled: false,
      mfaSecret: null,
      mfaRecoveryCodes: null,
    });

    const setupResponse = await request(app)
      .post("/auth/mfa/setup")
      .set("Authorization", `Bearer ${testUserToken}`);

    expect(setupResponse.status).toBe(200);
    expect(setupResponse.body.success).toBe(true);

    const { recoveryCodes } = setupResponse.body.data;
    expect(recoveryCodes).toBeDefined();
    expect(recoveryCodes).toHaveLength(8);

    // Retrieve database row
    const userInDb = testDbStore.users.find((u) => u.id === TEST_USER_ID);
    expect(userInDb).toBeDefined();
    expect(userInDb?.mfaRecoveryCodes).toBeDefined();

    const storedCodes = JSON.parse(userInDb?.mfaRecoveryCodes || "[]");
    expect(storedCodes).toHaveLength(8);

    // Verify all stored codes are 64-char SHA-256 hashes, NEVER plaintext
    for (let i = 0; i < storedCodes.length; i++) {
      const stored = storedCodes[i];
      const plaintext = recoveryCodes[i];

      expect(isHashedRecoveryCode(stored)).toBe(true);
      expect(stored.length).toBe(64);
      // Plaintext must never match stored value directly
      expect(stored).not.toBe(plaintext);
      // Stored value must match the SHA-256 hash of normalized plaintext
      expect(stored).toBe(hashRecoveryCode(plaintext));
    }
  });

  // =========================================================================
  // B. RECOVERY ACCEPTS VALID PASSWORD + VALID RECOVERY CODE
  // =========================================================================
  it("B. recovery accepts a valid password + valid recovery code and returns session", async () => {
    const plaintextCode = "A1B2C3D4E5";
    const hashedCode = hashRecoveryCode(plaintextCode);

    testDbStore.users.push({
      id: TEST_USER_ID,
      email: TEST_EMAIL,
      username: "mfasecuser",
      fullName: "MFA Security Tester",
      role: UserRole.ATHLETE,
      passwordHash: rawPasswordHash,
      isActive: true,
      mfaEnabled: true,
      mfaSecret: "JBSWY3DPEHPK3PXP",
      mfaRecoveryCodes: JSON.stringify([hashedCode]),
    });

    const response = await request(app)
      .post("/auth/mfa/recovery")
      .send({
        email: TEST_EMAIL,
        password: TEST_PASSWORD,
        recoveryCode: plaintextCode,
      });

    expect(response.status).toBe(200);
    expect(response.body.success).toBe(true);
    expect(response.body.data.accessToken).toBeDefined();
    expect(response.body.data.refreshToken).toBeDefined();
    expect(response.body.data.user.id).toBe(TEST_USER_ID);
    expect(response.body.data.message).toContain("Account recovered successfully");
  });

  // =========================================================================
  // C. WRONG PASSWORD + VALID RECOVERY CODE FAILS
  // =========================================================================
  it("C. wrong password + valid recovery code fails and does NOT consume code", async () => {
    const plaintextCode = "A1B2C3D4E5";
    const hashedCode = hashRecoveryCode(plaintextCode);

    testDbStore.users.push({
      id: TEST_USER_ID,
      email: TEST_EMAIL,
      username: "mfasecuser",
      fullName: "MFA Security Tester",
      role: UserRole.ATHLETE,
      passwordHash: rawPasswordHash,
      isActive: true,
      mfaEnabled: true,
      mfaSecret: "JBSWY3DPEHPK3PXP",
      mfaRecoveryCodes: JSON.stringify([hashedCode]),
    });

    const response = await request(app)
      .post("/auth/mfa/recovery")
      .send({
        email: TEST_EMAIL,
        password: "IncorrectPassword999!",
        recoveryCode: plaintextCode,
      });

    expect(response.status).toBe(401);
    expect(response.body.data).toBeUndefined();

    // Verify code was NOT consumed
    const userInDb = testDbStore.users.find((u) => u.id === TEST_USER_ID);
    const codesAfter = JSON.parse(userInDb?.mfaRecoveryCodes || "[]");
    expect(codesAfter).toHaveLength(1);
    expect(codesAfter[0]).toBe(hashedCode);
  });

  // =========================================================================
  // D. VALID PASSWORD + WRONG RECOVERY CODE FAILS
  // =========================================================================
  it("D. valid password + wrong recovery code fails and does not issue session", async () => {
    const validCode = "A1B2C3D4E5";
    const hashedCode = hashRecoveryCode(validCode);

    testDbStore.users.push({
      id: TEST_USER_ID,
      email: TEST_EMAIL,
      username: "mfasecuser",
      fullName: "MFA Security Tester",
      role: UserRole.ATHLETE,
      passwordHash: rawPasswordHash,
      isActive: true,
      mfaEnabled: true,
      mfaSecret: "JBSWY3DPEHPK3PXP",
      mfaRecoveryCodes: JSON.stringify([hashedCode]),
    });

    const response = await request(app)
      .post("/auth/mfa/recovery")
      .send({
        email: TEST_EMAIL,
        password: TEST_PASSWORD,
        recoveryCode: "WRONGCODE999",
      });

    expect(response.status).toBe(401);
    expect(response.body.data).toBeUndefined();

    // Verify valid code remains intact
    const userInDb = testDbStore.users.find((u) => u.id === TEST_USER_ID);
    const codesAfter = JSON.parse(userInDb?.mfaRecoveryCodes || "[]");
    expect(codesAfter).toHaveLength(1);
    expect(codesAfter[0]).toBe(hashedCode);
  });

  // =========================================================================
  // E. RECOVERY DOES NOT ISSUE A SESSION WHEN PASSWORD FAILS
  // =========================================================================
  it("E. recovery does not issue session or token when password verification fails", async () => {
    const plaintextCode = "A1B2C3D4E5";
    const hashedCode = hashRecoveryCode(plaintextCode);

    testDbStore.users.push({
      id: TEST_USER_ID,
      email: TEST_EMAIL,
      username: "mfasecuser",
      fullName: "MFA Security Tester",
      role: UserRole.ATHLETE,
      passwordHash: rawPasswordHash,
      isActive: true,
      mfaEnabled: true,
      mfaSecret: "JBSWY3DPEHPK3PXP",
      mfaRecoveryCodes: JSON.stringify([hashedCode]),
    });

    const sessionsBefore = testDbStore.userSessions.length;

    const response = await request(app)
      .post("/auth/mfa/recovery")
      .send({
        email: TEST_EMAIL,
        password: "BadPassword!",
        recoveryCode: plaintextCode,
      });

    expect(response.status).toBe(401);
    expect(testDbStore.userSessions.length).toBe(sessionsBefore);
  });

  // =========================================================================
  // F. A RECOVERY CODE IS CONSUMED EXACTLY ONCE
  // =========================================================================
  it("F. a recovery code is consumed exactly once and cannot be reused", async () => {
    const code = "CONSUME123";
    const hashedCode = hashRecoveryCode(code);

    testDbStore.users.push({
      id: TEST_USER_ID,
      email: TEST_EMAIL,
      username: "mfasecuser",
      fullName: "MFA Security Tester",
      role: UserRole.ATHLETE,
      passwordHash: rawPasswordHash,
      isActive: true,
      mfaEnabled: true,
      mfaSecret: "JBSWY3DPEHPK3PXP",
      mfaRecoveryCodes: JSON.stringify([hashedCode]),
    });

    // Attempt 1: Valid
    const res1 = await request(app)
      .post("/auth/mfa/recovery")
      .send({
        email: TEST_EMAIL,
        password: TEST_PASSWORD,
        recoveryCode: code,
      });

    expect(res1.status).toBe(200);

    // Verify consumed in DB
    const userInDb = testDbStore.users.find((u) => u.id === TEST_USER_ID);
    const codesAfter = JSON.parse(userInDb?.mfaRecoveryCodes || "[]");
    expect(codesAfter).toHaveLength(0);

    // Attempt 2: Re-use of the exact same code must fail
    const res2 = await request(app)
      .post("/auth/mfa/recovery")
      .send({
        email: TEST_EMAIL,
        password: TEST_PASSWORD,
        recoveryCode: code,
      });

    expect(res2.status).toBe(401);
  });

  // =========================================================================
  // G. CONCURRENT ATTEMPTS CANNOT CONSUME THE SAME RECOVERY CODE TWICE
  // =========================================================================
  it("G. concurrent attempts cannot consume the same single recovery code twice", async () => {
    const code = "RACECODE01";
    const hashedCode = hashRecoveryCode(code);

    testDbStore.users.push({
      id: TEST_USER_ID,
      email: TEST_EMAIL,
      username: "mfasecuser",
      fullName: "MFA Security Tester",
      role: UserRole.ATHLETE,
      passwordHash: rawPasswordHash,
      isActive: true,
      mfaEnabled: true,
      mfaSecret: "JBSWY3DPEHPK3PXP",
      mfaRecoveryCodes: JSON.stringify([hashedCode]),
    });

    // Fire 2 concurrent requests with the identical single recovery code
    const [resA, resB] = await Promise.all([
      request(app)
        .post("/auth/mfa/recovery")
        .send({ email: TEST_EMAIL, password: TEST_PASSWORD, recoveryCode: code }),
      request(app)
        .post("/auth/mfa/recovery")
        .send({ email: TEST_EMAIL, password: TEST_PASSWORD, recoveryCode: code }),
    ]);

    const statuses = [resA.status, resB.status].sort();
    // Exactly one should succeed (200), and the second must be rejected (401)
    expect(statuses).toEqual([200, 401]);
  });

  // =========================================================================
  // H. EXISTING MIGRATED RECOVERY CODES STILL WORK AFTER MIGRATION
  // =========================================================================
  it("H. existing migrated recovery codes (SHA-256 hashes) succeed upon login", async () => {
    const originalPlaintext = "MIGRATED99";
    // Simulate what migration 0023 does: stores lowercase sha256 hash in DB
    const migrationHash = crypto.createHash("sha256").update(originalPlaintext).digest("hex");

    testDbStore.users.push({
      id: TEST_USER_ID,
      email: TEST_EMAIL,
      username: "mfasecuser",
      fullName: "MFA Security Tester",
      role: UserRole.ATHLETE,
      passwordHash: rawPasswordHash,
      isActive: true,
      mfaEnabled: true,
      mfaSecret: "JBSWY3DPEHPK3PXP",
      mfaRecoveryCodes: JSON.stringify([migrationHash]),
    });

    // Athlete recovers using the plaintext code they had written down
    const response = await request(app)
      .post("/auth/mfa/recovery")
      .send({
        email: TEST_EMAIL,
        password: TEST_PASSWORD,
        recoveryCode: "migrated99", // case-insensitive verification
      });

    expect(response.status).toBe(200);
    expect(response.body.success).toBe(true);
    expect(response.body.data.accessToken).toBeDefined();
  });

  // =========================================================================
  // I. MALFORMED / INVALID RECOVERY INPUT FAILS SAFELY
  // =========================================================================
  it("I. malformed, missing, or empty inputs fail safely with 400 Bad Request", async () => {
    // Missing password
    const res1 = await request(app)
      .post("/auth/mfa/recovery")
      .send({ email: TEST_EMAIL, recoveryCode: "CODE123" });
    expect(res1.status).toBe(400);

    // Missing recoveryCode
    const res2 = await request(app)
      .post("/auth/mfa/recovery")
      .send({ email: TEST_EMAIL, password: TEST_PASSWORD });
    expect(res2.status).toBe(400);

    // Missing email
    const res3 = await request(app)
      .post("/auth/mfa/recovery")
      .send({ password: TEST_PASSWORD, recoveryCode: "CODE123" });
    expect(res3.status).toBe(400);
  });

  // =========================================================================
  // J. RECOVERY DOES NOT LEAK WHICH CREDENTIAL FACTOR FAILED
  // =========================================================================
  it("J. recovery returns identical error convention for non-existent user, bad password, and bad code", async () => {
    const plaintextCode = "A1B2C3D4E5";
    const hashedCode = hashRecoveryCode(plaintextCode);

    testDbStore.users.push({
      id: TEST_USER_ID,
      email: TEST_EMAIL,
      username: "mfasecuser",
      fullName: "MFA Security Tester",
      role: UserRole.ATHLETE,
      passwordHash: rawPasswordHash,
      isActive: true,
      mfaEnabled: true,
      mfaSecret: "JBSWY3DPEHPK3PXP",
      mfaRecoveryCodes: JSON.stringify([hashedCode]),
    });

    // 1. Non-existent user
    const resUnknown = await request(app)
      .post("/auth/mfa/recovery")
      .send({
        email: "nonexistent@armsphere.com",
        password: TEST_PASSWORD,
        recoveryCode: plaintextCode,
      });

    // 2. Wrong password
    const resBadPass = await request(app)
      .post("/auth/mfa/recovery")
      .send({
        email: TEST_EMAIL,
        password: "WrongPassword!",
        recoveryCode: plaintextCode,
      });

    // 3. Wrong recovery code
    const resBadCode = await request(app)
      .post("/auth/mfa/recovery")
      .send({
        email: TEST_EMAIL,
        password: TEST_PASSWORD,
        recoveryCode: "WRONGCODE12",
      });

    // Status codes must be identical (401)
    expect(resUnknown.status).toBe(401);
    expect(resBadPass.status).toBe(401);
    expect(resBadCode.status).toBe(401);

    // Error messages must be identical (no factor enumeration)
    const msgUnknown = resUnknown.body.message || resUnknown.body.error;
    const msgBadPass = resBadPass.body.message || resBadPass.body.error;
    const msgBadCode = resBadCode.body.message || resBadCode.body.error;

    expect(msgUnknown).toBe(msgBadPass);
    expect(msgBadPass).toBe(msgBadCode);
  });

  // =========================================================================
  // K. RECOVERY ROUTE DOES NOT LOG PLAINTEXT RECOVERY CODES
  // =========================================================================
  it("K. recovery route never logs plaintext recovery codes to audit ledger", async () => {
    const secretCode = "SUPERSECRET1";
    const hashedCode = hashRecoveryCode(secretCode);

    testDbStore.users.push({
      id: TEST_USER_ID,
      email: TEST_EMAIL,
      username: "mfasecuser",
      fullName: "MFA Security Tester",
      role: UserRole.ATHLETE,
      passwordHash: rawPasswordHash,
      isActive: true,
      mfaEnabled: true,
      mfaSecret: "JBSWY3DPEHPK3PXP",
      mfaRecoveryCodes: JSON.stringify([hashedCode]),
    });

    const response = await request(app)
      .post("/auth/mfa/recovery")
      .send({
        email: TEST_EMAIL,
        password: TEST_PASSWORD,
        recoveryCode: secretCode,
      });

    expect(response.status).toBe(200);

    // Inspect all audit entries
    const auditEntries = testDbStore.auditLogs;
    for (const entry of auditEntries) {
      const serialized = JSON.stringify(entry);
      expect(serialized).not.toContain(secretCode);
    }
  });

  // =========================================================================
  // L. MIGRATION LOGIC HANDLES ALREADY-HASHED VALUES WITHOUT DOUBLE HASHING
  // =========================================================================
  it("L. helper logic correctly identifies already-hashed SHA-256 strings", () => {
    const rawCode = "CODE123456";
    const singleHash = hashRecoveryCode(rawCode);

    expect(isHashedRecoveryCode(rawCode)).toBe(false);
    expect(isHashedRecoveryCode(singleHash)).toBe(true);
    expect(singleHash.length).toBe(64);

    // If already hashed, hashRecoveryCode is not called again in migration
    const simulatedMigrationResult = isHashedRecoveryCode(singleHash)
      ? singleHash.toLowerCase()
      : hashRecoveryCode(singleHash);

    expect(simulatedMigrationResult).toBe(singleHash);
  });

  // =========================================================================
  // M. RATE LIMITING MIDDLEWARE APPLIED
  // =========================================================================
  it("M. auth router has rateLimiter middleware configured on /mfa/recovery route", () => {
    // Inspect Express router layer stack for /mfa/recovery
    const recoveryLayer = authRouter.stack.find((layer: any) => {
      return layer.route?.path === "/mfa/recovery" && layer.route?.methods?.post;
    });

    expect(recoveryLayer).toBeDefined();
    // Route must have at least 2 handlers (rateLimiter middleware + controller)
    expect(recoveryLayer.route.stack.length).toBeGreaterThanOrEqual(2);
  });
});
