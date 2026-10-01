import speakeasy from "speakeasy";
import qrcode from "qrcode";
import crypto from "crypto";
import { eq } from "drizzle-orm";
import { db } from "../config/db.js";
import { users } from "@armsphere/db-schema";
import { BadRequestError, NotFoundError, UnauthorizedError } from "@armsphere/core";
import { comparePassword } from "@armsphere/cryptography";
import { safeSecretCompare } from "../middlewares/security.js";
import { auditLedgerService } from "./auditLedger.js";

/**
 * Deterministically normalizes and computes the SHA-256 hash of a backup recovery code.
 */
export function hashRecoveryCode(code: string): string {
  const normalized = code.trim().toUpperCase();
  return crypto.createHash("sha256").update(normalized).digest("hex");
}

/**
 * Checks whether a stored recovery code string is already a 64-character SHA-256 hex hash.
 */
export function isHashedRecoveryCode(code: string): boolean {
  return typeof code === "string" && code.length === 64 && /^[0-9a-fA-F]{64}$/.test(code);
}

export class MFAService {
  /**
   * Initiates MFA setup by generating a secret, a QR code, and backup recovery codes.
   */
  static async setupMFA(userId: string) {
    const [user] = await db
      .select()
      .from(users)
      .where(eq(users.id, userId))
      .limit(1);

    if (!user) {
      throw new NotFoundError("User not found.");
    }

    // 1. Generate Speakeasy Base32 Secret
    const secret = speakeasy.generateSecret({
      length: 20,
      name: `ArmSphere:${user.email}`,
      issuer: "ArmSphere",
    });

    const otpauthUrl = secret.otpauth_url;
    if (!otpauthUrl) {
      throw new BadRequestError("Failed to generate OTP authentication URL.");
    }

    // 2. Provision QR Code
    const qrCodeDataUrl = await qrcode.toDataURL(otpauthUrl);

    // 3. Generate 8 secure backup recovery codes
    const recoveryCodes: string[] = [];
    const hashedRecoveryCodes: string[] = [];
    for (let i = 0; i < 8; i++) {
      const code = crypto.randomBytes(5).toString("hex").toUpperCase();
      recoveryCodes.push(code);
      hashedRecoveryCodes.push(hashRecoveryCode(code));
    }

    // 4. Store secret & SHA-256 hashed recovery codes in DB (NEVER plaintext)
    await db
      .update(users)
      .set({
        mfaSecret: secret.base32,
        mfaRecoveryCodes: JSON.stringify(hashedRecoveryCodes),
        mfaEnabled: false,
        updatedAt: new Date(),
      } as any)
      .where(eq(users.id, userId));

    await auditLedgerService.logEvent({
      actorId: userId,
      entityType: "USER",
      entityId: userId,
      action: "AUTH_MFA_SETUP_INITIATED",
      payload: { email: user.email },
    });

    return {
      secret: secret.base32,
      qrCode: qrCodeDataUrl,
      recoveryCodes,
    };
  }

  /**
   * Confirms and activates MFA by validating the first TOTP code.
   */
  static async verifyAndEnableMFA(userId: string, code: string) {
    const [user] = await db
      .select()
      .from(users)
      .where(eq(users.id, userId))
      .limit(1);

    if (!user) {
      throw new NotFoundError("User not found.");
    }

    const userAny = user as any;

    if (!userAny.mfaSecret) {
      throw new BadRequestError("MFA setup was not initiated. Please call setup endpoint first.");
    }

    // Verify TOTP token using Speakeasy
    const verified = speakeasy.totp.verify({
      secret: userAny.mfaSecret,
      encoding: "base32",
      token: code,
      window: 1,
    });

    if (!verified) {
      throw new BadRequestError("Invalid MFA verification code.");
    }

    // Activate MFA
    await db
      .update(users)
      .set({
        mfaEnabled: true,
        updatedAt: new Date(),
      } as any)
      .where(eq(users.id, userId));

    await auditLedgerService.logEvent({
      actorId: userId,
      entityType: "USER",
      entityId: userId,
      action: "AUTH_MFA_ENABLED",
      payload: { enabled: true },
    });

    return {
      success: true,
      message: "Multi-Factor Authentication enabled successfully.",
    };
  }

  /**
   * General TOTP validation for logins.
   */
  static async verifyTOTP(userId: string, code: string): Promise<boolean> {
    const [user] = await db
      .select()
      .from(users)
      .where(eq(users.id, userId))
      .limit(1);

    if (!user) {
      return false;
    }

    const userAny = user as any;

    if (!userAny.mfaSecret || !userAny.mfaEnabled) {
      return false;
    }

    return speakeasy.totp.verify({
      secret: userAny.mfaSecret,
      encoding: "base32",
      token: code,
      window: 1,
    });
  }

  /**
   * Disables MFA requiring a valid TOTP code to confirm.
   */
  static async disableMFA(userId: string, code: string) {
    const [user] = await db
      .select()
      .from(users)
      .where(eq(users.id, userId))
      .limit(1);

    if (!user) {
      throw new NotFoundError("User not found.");
    }

    const userAny = user as any;

    if (!userAny.mfaEnabled || !userAny.mfaSecret) {
      throw new BadRequestError("MFA is not enabled for this account.");
    }

    const verified = speakeasy.totp.verify({
      secret: userAny.mfaSecret,
      encoding: "base32",
      token: code,
      window: 1,
    });

    if (!verified) {
      throw new BadRequestError("Invalid MFA verification code. Unable to disable MFA.");
    }

    await db
      .update(users)
      .set({
        mfaEnabled: false,
        mfaSecret: null,
        mfaRecoveryCodes: null,
        updatedAt: new Date(),
      } as any)
      .where(eq(users.id, userId));

    await auditLedgerService.logEvent({
      actorId: userId,
      entityType: "USER",
      entityId: userId,
      action: "AUTH_MFA_DISABLED",
      payload: { disabled: true },
    });

    return {
      success: true,
      message: "Multi-Factor Authentication disabled successfully.",
    };
  }

  /**
   * Recovers MFA access using primary password and a backup recovery code.
   * Strictly enforces:
   * 1. Primary password verification via comparePassword
   * 2. Atomic consumption of recovery code via constant-time comparison
   * 3. Prevents credential factor enumeration (safe error convention)
   * 4. Does not leak or log plaintext recovery codes
   */
  static async recoverMFA(email: string, passwordPlain: string, recoveryCode: string) {
    const emailLower = email.toLowerCase().trim();

    // 1. Lookup user safely
    const [user] = await db
      .select()
      .from(users)
      .where(eq(users.email, emailLower))
      .limit(1);

    // If user does not exist or is disabled, fail with uniform auth error (no enumeration)
    if (!user || !user.isActive) {
      throw new UnauthorizedError("Invalid email, password, or recovery code provided.");
    }

    // 2. Primary factor: verify primary password
    const passwordMatch = await comparePassword(passwordPlain, user.passwordHash);
    if (!passwordMatch) {
      throw new UnauthorizedError("Invalid email, password, or recovery code provided.");
    }

    // 3. MFA enrollment and recovery codes check
    const userAny = user as any;
    if (!userAny.mfaEnabled || !userAny.mfaRecoveryCodes) {
      throw new UnauthorizedError("Invalid email, password, or recovery code provided.");
    }

    // 4. Verify and atomically consume candidate recovery code
    const normalizedInput = recoveryCode.trim().toUpperCase();
    const candidateHash = hashRecoveryCode(normalizedInput);

    const consumptionResult = await db.transaction(async (tx) => {
      const [lockedUser] = await tx
        .select()
        .from(users)
        .where(eq(users.id, user.id))
        .for("update");

      if (!lockedUser) return null;
      const lockedAny = lockedUser as any;
      if (!lockedAny.mfaRecoveryCodes) return null;

      let storedCodes: string[] = [];
      try {
        storedCodes = JSON.parse(lockedAny.mfaRecoveryCodes);
      } catch {
        return null;
      }

      if (!Array.isArray(storedCodes) || storedCodes.length === 0) {
        return null;
      }

      let matchedIndex = -1;
      for (let i = 0; i < storedCodes.length; i++) {
        const stored = storedCodes[i];
        if (typeof stored !== "string") continue;

        if (isHashedRecoveryCode(stored)) {
          if (safeSecretCompare(candidateHash, stored.toLowerCase())) {
            matchedIndex = i;
            break;
          }
        } else {
          // Backward-compatibility fallback for unmigrated legacy plaintext codes
          if (safeSecretCompare(normalizedInput, stored.trim().toUpperCase())) {
            matchedIndex = i;
            break;
          }
        }
      }

      if (matchedIndex === -1) {
        return null;
      }

      // Atomically remove the consumed code
      storedCodes.splice(matchedIndex, 1);

      // Ensure all remaining codes are stored as hashes (forward migrate on the fly)
      const sanitizedCodes = storedCodes.map((c) => {
        if (isHashedRecoveryCode(c)) {
          return c.toLowerCase();
        }
        return hashRecoveryCode(String(c));
      });

      await tx
        .update(users)
        .set({
          mfaRecoveryCodes: JSON.stringify(sanitizedCodes),
          updatedAt: new Date(),
        } as any)
        .where(eq(users.id, user.id));

      return { remainingCount: sanitizedCodes.length };
    });

    if (!consumptionResult) {
      throw new UnauthorizedError("Invalid email, password, or recovery code provided.");
    }

    await auditLedgerService.logEvent({
      actorId: user.id,
      entityType: "USER",
      entityId: user.id,
      action: "AUTH_MFA_RECOVERY_USED",
      payload: { email: user.email, remainingCodes: consumptionResult.remainingCount },
    });

    return {
      success: true,
      userId: user.id,
      email: user.email,
      role: user.role,
      message: "MFA verified successfully using backup recovery code.",
    };
  }
}
export default MFAService;
