import speakeasy from "speakeasy";
import qrcode from "qrcode";
import crypto from "crypto";
import { eq } from "drizzle-orm";
import { db } from "../config/db.js";
import { users } from "@armsphere/db-schema";
import { BadRequestError, NotFoundError } from "@armsphere/core";
import { auditLedgerService } from "./auditLedger.js";

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
    for (let i = 0; i < 8; i++) {
      recoveryCodes.push(crypto.randomBytes(5).toString("hex").toUpperCase());
    }

    // 4. Store secret & recovery codes in DB
    await db
      .update(users)
      .set({
        mfaSecret: secret.base32,
        mfaRecoveryCodes: JSON.stringify(recoveryCodes),
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
   * Recovers MFA access using a backup recovery code.
   */
  static async recoverMFA(email: string, recoveryCode: string) {
    const [user] = await db
      .select()
      .from(users)
      .where(eq(users.email, email.toLowerCase().trim()))
      .limit(1);

    if (!user) {
      throw new NotFoundError("User not found.");
    }

    const userAny = user as any;

    if (!userAny.mfaEnabled || !userAny.mfaRecoveryCodes) {
      throw new BadRequestError("MFA is not enabled or recovery codes are not generated.");
    }

    let codes: string[] = [];
    try {
      codes = JSON.parse(userAny.mfaRecoveryCodes);
    } catch {
      throw new BadRequestError("Recovery codes are corrupted.");
    }

    const codeIndex = codes.indexOf(recoveryCode.trim().toUpperCase());
    if (codeIndex === -1) {
      throw new BadRequestError("Invalid MFA backup recovery code.");
    }

    // Remove the used recovery code
    codes.splice(codeIndex, 1);

    await db
      .update(users)
      .set({
        mfaRecoveryCodes: JSON.stringify(codes),
        updatedAt: new Date(),
      } as any)
      .where(eq(users.id, user.id));

    await auditLedgerService.logEvent({
      actorId: user.id,
      entityType: "USER",
      entityId: user.id,
      action: "AUTH_MFA_RECOVERY_USED",
      payload: { email: user.email, remainingCodes: codes.length },
    });

    return {
      success: true,
      userId: user.id,
      email: user.email,
      role: user.role,
      message: "MFA bypassed successfully using backup recovery code.",
    };
  }
}
export default MFAService;
