import { eq, and, desc, gt, isNull } from "drizzle-orm";
import crypto from "crypto";
import { v4 as uuidv4 } from "uuid";
import jwt from "jsonwebtoken";
import { db } from "../config/db.js";
import { users, userSessions, auditLogs, athleteProfiles, authTokens } from "@armsphere/db-schema";
import { hashPassword, comparePassword, generateAccessToken, generateRefreshToken, verifyToken } from "@armsphere/cryptography";
import { BadRequestError, UnauthorizedError, ConflictError, NotFoundError, logger } from "@armsphere/core";
import { UserRole } from "@armsphere/types";
import env from "../config/env.js";
import { MFAService } from "./mfa.js";
import { SessionSecurityService } from "./sessionSecurity.js";
import { auditLedgerService } from "./auditLedger.js";
import { EmailDeliveryService } from "./emailDelivery.js";

// Zero-cost TTL-supported in-memory store for ephemeral auth rate-limiting & lockout caching (background scheduled jobs use PostgreSQL scheduled_jobs)
const inMemoryStore = new Map<string, { value: string; expiresAt?: number }>();

function cacheGet(key: string): string | null {
  const item = inMemoryStore.get(key);
  if (!item) return null;
  if (item.expiresAt && Date.now() > item.expiresAt) {
    inMemoryStore.delete(key);
    return null;
  }
  return item.value;
}

function cacheSet(key: string, value: string, ttlMs?: number) {
  inMemoryStore.set(key, {
    value,
    expiresAt: ttlMs ? Date.now() + ttlMs : undefined,
  });
}

function cacheDel(key: string) {
  inMemoryStore.delete(key);
}

// Fast cryptographic helper for token indexing
function sha256(content: string): string {
  return crypto.createHash("sha256").update(content).digest("hex");
}

// --- User Agent Regex Parser for Device Management ---
function parseUserAgent(uaString: string = ""): { device: string; os: string; browser: string } {
  let device = "Desktop";
  let os = "Unknown OS";
  let browser = "Unknown Browser";

  const lowerUA = uaString.toLowerCase();

  // Parse Device Type
  if (lowerUA.includes("mobi") || lowerUA.includes("iphone") || lowerUA.includes("android")) {
    device = "Mobile";
  } else if (lowerUA.includes("tablet") || lowerUA.includes("ipad")) {
    device = "Tablet";
  }

  // Parse OS
  if (lowerUA.includes("windows")) {
    os = "Windows";
  } else if (lowerUA.includes("macintosh") || lowerUA.includes("mac os")) {
    os = "macOS";
  } else if (lowerUA.includes("iphone") || lowerUA.includes("ipad")) {
    os = "iOS";
  } else if (lowerUA.includes("android")) {
    os = "Android";
  } else if (lowerUA.includes("linux")) {
    os = "Linux";
  }

  // Parse Browser
  if (lowerUA.includes("firefox")) {
    browser = "Firefox";
  } else if (lowerUA.includes("chrome") && !lowerUA.includes("chromium")) {
    browser = "Chrome";
  } else if (lowerUA.includes("safari") && !lowerUA.includes("chrome")) {
    browser = "Safari";
  } else if (lowerUA.includes("edge")) {
    browser = "Edge";
  } else if (lowerUA.includes("opera") || lowerUA.includes("opr")) {
    browser = "Opera";
  }

  return { device, os, browser };
}

// --- Pure TS/Node Cryptographic RFC-6238 TOTP Verifier ---
function base32Decode(base32: string): Buffer {
  const alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567";
  const cleaned = base32.toUpperCase().replace(/=+$/, "");
  let bits = "";
  for (let i = 0; i < cleaned.length; i++) {
    const val = alphabet.indexOf(cleaned[i]);
    if (val === -1) throw new Error("Invalid base32 character");
    bits += val.toString(2).padStart(5, "0");
  }
  const bytes = [];
  for (let i = 0; i < bits.length; i += 8) {
    const chunk = bits.substring(i, i + 8);
    if (chunk.length === 8) {
      bytes.push(parseInt(chunk, 2));
    }
  }
  return Buffer.from(bytes);
}

export function verifyTOTP(secret: string, code: string): boolean {
  try {
    const key = base32Decode(secret);
    const counter = Math.floor(Date.now() / 30000);
    
    // Check current step, previous step, and next step for clock drift tolerance
    for (let i = -1; i <= 1; i++) {
      const step = counter + i;
      const buffer = Buffer.alloc(8);
      
      // Write 64-bit integer
      const high = 0;
      const low = step;
      buffer.writeUInt32BE(high, 0);
      buffer.writeUInt32BE(low, 4);

      const hmac = crypto.createHmac("sha1", key).update(buffer).digest();
      const offset = hmac[hmac.length - 1] & 0xf;
      const codeInt = (
        ((hmac[offset] & 0x7f) << 24) |
        ((hmac[offset + 1] & 0xff) << 16) |
        ((hmac[offset + 2] & 0xff) << 8) |
        (hmac[offset + 3] & 0xff)
      ) % 1000000;
      
      const calculatedCode = codeInt.toString().padStart(6, "0");
      if (calculatedCode === code) {
        return true;
      }
    }
  } catch (err) {
    logger.warn({ err }, "TOTP verification failed internally");
  }
  return false;
}

export class AuthService {
  /**
   * Registers a brand new user.
   */
  static async register(input: {
    email: string;
    username: string;
    passwordPlain: string;
    fullName: string;
    role?: UserRole;
  }, context?: { ipAddress?: string; userAgent?: string }) {
    const emailLower = input.email.toLowerCase().trim();
    const usernameTrim = input.username.trim();

    // Check email uniqueness
    const [existingEmail] = await db
      .select()
      .from(users)
      .where(eq(users.email, emailLower))
      .limit(1);

    if (existingEmail) {
      throw new ConflictError("A user with this email address already exists.");
    }

    // Check username uniqueness
    const [existingUsername] = await db
      .select()
      .from(users)
      .where(eq(users.username, usernameTrim))
      .limit(1);

    if (existingUsername) {
      throw new ConflictError("A user with this username already exists.");
    }

    const hashedPassword = await hashPassword(input.passwordPlain);
    const safeRole = UserRole.ATHLETE;

    // Public registration must never create an elevated role; admin roles are granted only through protected workflows.
    if (input.role && input.role !== UserRole.ATHLETE) {
      logger.warn({ requestedRole: input.role, email: emailLower }, "Ignoring privileged role supplied during public registration.");
    }

    // Insert user
    const [newUser] = await db
      .insert(users)
      .values({
        email: emailLower,
        username: usernameTrim,
        passwordHash: hashedPassword,
        fullName: input.fullName.trim(),
        role: safeRole,
        isActive: true,
      })
      .returning();

    // Log the registration in Audit Logs
    await db.insert(auditLogs).values({
      userId: newUser.id,
      action: "AUTH_REGISTER",
      details: { role: newUser.role, email: newUser.email },
      ipAddress: context?.ipAddress,
      userAgent: context?.userAgent,
    });

    const { passwordHash, ...userResponse } = newUser;
    return userResponse;
  }

  /**
   * Validates credentials, establishes a session, and issues tokens.
   * Includes account lockout, suspicious IP checks, and MFA requirements.
   */
  static async login(
    emailPlain: string,
    passwordPlain: string,
    context?: { ipAddress?: string; userAgent?: string; mfaCode?: string; rememberDevice?: boolean }
  ) {
    const emailLower = emailPlain.toLowerCase().trim();
    const ip = context?.ipAddress || "unknown-ip";
    const userAgent = context?.userAgent || "unknown-ua";

    const lockoutKey = `lockout:${emailLower}`;
    const attemptsKey = `attempts:${emailLower}`;

    // 1. Lockout Protection Check
    const isLocked = cacheGet(lockoutKey);
    if (isLocked) {
      throw new UnauthorizedError("Account is temporarily locked due to too many failed login attempts. Please try again in 15 minutes.");
    }

    // Retrieve user record
    const [user] = await db
      .select()
      .from(users)
      .where(eq(users.email, emailLower))
      .limit(1);

    if (!user) {
      // General response to prevent user enumeration
      throw new UnauthorizedError("Invalid email or password credentials provided.");
    }

    const userAny = user as any;

    if (!user.isActive) {
      throw new UnauthorizedError("Your user account has been disabled. Please contact support.");
    }

    // 2. Password Verification
    const passwordMatch = await comparePassword(passwordPlain, user.passwordHash);
    if (!passwordMatch) {
      // Handle Failed Attempt Counting (5 attempts limit)
      let currentAttempts = 1;
      const rawAttempts = cacheGet(attemptsKey);
      if (rawAttempts) {
        currentAttempts = parseInt(rawAttempts) + 1;
        cacheSet(attemptsKey, currentAttempts.toString(), 15 * 60 * 1000);
      } else {
        cacheSet(attemptsKey, "1", 15 * 60 * 1000); // 15 mins window
      }

      if (currentAttempts >= 5) {
        cacheSet(lockoutKey, "1", 15 * 60 * 1000); // lock for 15 mins
        await db.insert(auditLogs).values({
          userId: user.id,
          action: "ACCOUNT_LOCKOUT_TRIGGERED",
          details: { email: emailLower, reason: "5 consecutive failed login attempts" },
          ipAddress: ip,
          userAgent: userAgent,
        });
        throw new UnauthorizedError("Too many failed attempts. Your account has been temporarily locked for 15 minutes.");
      }

      throw new UnauthorizedError("Invalid email or password credentials provided.");
    }

    // Password verified! Clear failed attempts
    cacheDel(attemptsKey);

    // 3. Evaluate Session Security / Threat Analysis (Impossible Travel, New Devices, etc.)
    const securityAnalysis = await SessionSecurityService.evaluateLoginSession(
      user.id,
      ip,
      userAgent
    );

    // 4. Multi-Factor Authentication (MFA) Guard (DB-backed)
    if (userAny.mfaEnabled) {
      if (!context?.mfaCode) {
        return {
          mfaRequired: true,
          userId: user.id,
          message: "MFA verification code required to complete authentication.",
        };
      }
      
      const verified = await MFAService.verifyTOTP(user.id, context.mfaCode);
      if (!verified) {
        await db.insert(auditLogs).values({
          userId: user.id,
          action: "AUTH_MFA_FAILED",
          details: { ipAddress: ip, error: "Invalid TOTP verification code passed" },
          ipAddress: ip,
          userAgent: userAgent,
        });
        throw new UnauthorizedError("The Multi-Factor authentication code provided is invalid.");
      }
    }

    // Prepare Token Family
    const tokenFamily = uuidv4();

    // 5. Issue Access Token with precise MFA custom claims
    const accessTokenPayload = {
      sub: user.id,
      email: user.email,
      role: user.role as UserRole,
      type: "access" as const,
      mfaRequired: userAny.mfaEnabled,
      mfaVerified: userAny.mfaEnabled ? true : false,
    };
    
    const accessToken = jwt.sign(accessTokenPayload, env.JWT_ACCESS_SECRET, { expiresIn: "15m" });
    const refreshToken = generateRefreshToken(user.id, user.email, user.role as UserRole, tokenFamily, env.JWT_REFRESH_SECRET);

    const refreshTokenHash = sha256(refreshToken);
    const expiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000); // 30 Days

    // Save Session Row
    await db.insert(userSessions).values({
      userId: user.id,
      tokenFamily,
      refreshTokenHash,
      isRevoked: false,
      expiresAt,
      ipAddress: ip,
      userAgent: userAgent,
    });

    // Device Trust Cookie Check / Setup ("Remember this device")
    let deviceTrustToken = null;
    if (context?.rememberDevice) {
      const deviceTrustPayload = {
        sub: user.id,
        email: user.email,
        type: "device_trust" as const,
      };
      deviceTrustToken = jwt.sign(deviceTrustPayload, env.JWT_ACCESS_SECRET, { expiresIn: "30d" });
    }

    // Write Audit Log
    await db.insert(auditLogs).values({
      userId: user.id,
      action: "AUTH_LOGIN",
      details: { tokenFamily, rememberDevice: !!context?.rememberDevice },
      ipAddress: ip,
      userAgent: userAgent,
    });

    const [athleteProfile] = await db
      .select()
      .from(athleteProfiles)
      .where(and(eq(athleteProfiles.userId, user.id), eq(athleteProfiles.isDeleted, false)))
      .limit(1);
    const isOnboarded = !!athleteProfile;

    const { passwordHash, ...userResponse } = user;
    return {
      mfaRequired: false,
      user: {
        ...userResponse,
        isOnboarded,
      },
      accessToken,
      refreshToken,
      deviceTrustToken,
    };
  }

  /**
   * Issues the session for a login whose second factor (TOTP challenge or
   * recovery code) has already been verified upstream. Mirrors the token,
   * session-row, and audit behavior of a successful `login` — without any
   * password check.
   */
  static async completeMfaLogin(
    userId: string,
    context?: { ipAddress?: string; userAgent?: string; rememberDevice?: boolean }
  ) {
    const [user] = await db.select().from(users).where(eq(users.id, userId)).limit(1);
    if (!user) {
      throw new NotFoundError("User not found.");
    }
    if (!user.isActive) {
      throw new UnauthorizedError("Your user account has been disabled. Please contact support.");
    }

    const userAny = user as any;
    const ip = context?.ipAddress || "unknown-ip";
    const userAgent = context?.userAgent || "unknown-ua";

    const tokenFamily = uuidv4();
    const accessToken = jwt.sign(
      {
        sub: user.id,
        email: user.email,
        role: user.role as UserRole,
        type: "access" as const,
        mfaRequired: !!userAny.mfaEnabled,
        mfaVerified: true,
      },
      env.JWT_ACCESS_SECRET,
      { expiresIn: "15m" }
    );
    const refreshToken = generateRefreshToken(user.id, user.email, user.role as UserRole, tokenFamily, env.JWT_REFRESH_SECRET);

    const refreshTokenHash = sha256(refreshToken);
    const expiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000); // 30 Days

    await db.insert(userSessions).values({
      userId: user.id,
      tokenFamily,
      refreshTokenHash,
      isRevoked: false,
      expiresAt,
      ipAddress: ip,
      userAgent: userAgent,
    });

    let deviceTrustToken = null;
    if (context?.rememberDevice) {
      const deviceTrustPayload = {
        sub: user.id,
        email: user.email,
        type: "device_trust" as const,
      };
      deviceTrustToken = jwt.sign(deviceTrustPayload, env.JWT_ACCESS_SECRET, { expiresIn: "30d" });
    }

    await db.insert(auditLogs).values({
      userId: user.id,
      action: "AUTH_LOGIN",
      details: { tokenFamily, mfaCompleted: true },
      ipAddress: ip,
      userAgent: userAgent,
    });

    const [athleteProfile] = await db
      .select()
      .from(athleteProfiles)
      .where(and(eq(athleteProfiles.userId, user.id), eq(athleteProfiles.isDeleted, false)))
      .limit(1);
    const isOnboarded = !!athleteProfile;

    const { passwordHash, ...userResponse } = user;
    return {
      mfaRequired: false,
      user: {
        ...userResponse,
        isOnboarded,
      },
      accessToken,
      refreshToken,
      deviceTrustToken,
    };
  }

  /**
   * Validates and rotates refresh tokens. Detects and mitigates session hijacking attempts.
   */
  static async rotateSession(
    oldRefreshToken: string,
    context?: { ipAddress?: string; userAgent?: string }
  ) {
    let decoded;
    try {
      decoded = verifyToken(oldRefreshToken, env.JWT_REFRESH_SECRET);
    } catch (error) {
      throw new UnauthorizedError("Refresh token is expired, revoked, or invalid.");
    }

    if (decoded.type !== "refresh" || !decoded.family) {
      throw new BadRequestError("Invalid token type provided for rotation.");
    }

    const userId = decoded.sub;
    const tokenFamily = decoded.family;
    const oldTokenHash = sha256(oldRefreshToken);

    // Query session matching the token family
    const existingSessions = await db
      .select()
      .from(userSessions)
      .where(eq(userSessions.tokenFamily, tokenFamily));

    const activeSession = existingSessions.find(s => s.refreshTokenHash === oldTokenHash);

    // REUSE DETECTION (Session hijacking check!)
    if (!activeSession || activeSession.isRevoked) {
      // Token reuse detected! Revoke ALL active sessions for this family immediately to safeguard the user.
      await db
        .update(userSessions)
        .set({ isRevoked: true })
        .where(eq(userSessions.tokenFamily, tokenFamily));

      // Record a critical security alert
      await db.insert(auditLogs).values({
        userId,
        action: "AUTH_TOKEN_REUSE_ALERT",
        details: { tokenFamily, oldTokenHash, warning: "Detected reuse of rotated refresh token. Revoked entire session family." },
        ipAddress: context?.ipAddress,
        userAgent: context?.userAgent,
      });

      throw new UnauthorizedError("Potential security compromise detected. Sessions revoked. Please login again.");
    }

    // Check expiration
    if (activeSession.expiresAt < new Date()) {
      throw new UnauthorizedError("Session has expired. Please login again.");
    }

    // Revoke old session token
    await db
      .update(userSessions)
      .set({ isRevoked: true })
      .where(eq(userSessions.id, activeSession.id));

    // Generate rotated tokens
    const accessToken = generateAccessToken(userId, decoded.email, decoded.role, env.JWT_ACCESS_SECRET);
    const newRefreshToken = generateRefreshToken(userId, decoded.email, decoded.role, tokenFamily, env.JWT_REFRESH_SECRET);

    const newHash = sha256(newRefreshToken);
    const expiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);

    // Save rotated session
    await db.insert(userSessions).values({
      userId,
      tokenFamily,
      refreshTokenHash: newHash,
      isRevoked: false,
      expiresAt,
      ipAddress: context?.ipAddress,
      userAgent: context?.userAgent,
    });

    return {
      accessToken,
      refreshToken: newRefreshToken,
    };
  }

  /**
   * Revokes the current session family (logging out the family tree).
   */
  static async revokeSession(refreshTokenPlain: string, userId: string) {
    try {
      const decoded = verifyToken(refreshTokenPlain, env.JWT_REFRESH_SECRET);
      if (decoded.family) {
        await db
          .update(userSessions)
          .set({ isRevoked: true })
          .where(eq(userSessions.tokenFamily, decoded.family));
      }
    } catch {
      // Silently consume to allow robust stateless failovers
    }
  }

  /**
   * Returns current active user profile.
   */
  static async getUserProfile(userId: string) {
    const [user] = await db
      .select()
      .from(users)
      .where(eq(users.id, userId))
      .limit(1);

    if (!user) {
      throw new NotFoundError("Requested user profile was not found.");
    }

    const [athleteProfile] = await db
      .select()
      .from(athleteProfiles)
      .where(and(eq(athleteProfiles.userId, userId), eq(athleteProfiles.isDeleted, false)))
      .limit(1);
    const isOnboarded = !!athleteProfile;

    const { passwordHash, ...profile } = user;
    return {
      ...profile,
      isOnboarded,
    };
  }

  /**
   * Phase 12 store-readiness: real account deletion path.
   * Deactivates the credential, anonymizes identity fields, soft-deletes the
   * athlete profile, and revokes every session. Audit records are retained
   * without carrying live PII.
   */
  static async deleteAccount(userId: string, context?: { ipAddress?: string; userAgent?: string }) {
    const [user] = await db
      .select()
      .from(users)
      .where(eq(users.id, userId))
      .limit(1);

    if (!user) {
      throw new NotFoundError("Requested user profile was not found.");
    }

    const now = new Date();
    const suffix = userId.replace(/-/g, "").slice(0, 12);

    // Anonymize identity while preserving referential integrity (unique columns).
    await db
      .update(users)
      .set({
        email: `deleted-${suffix}@deleted.armsphere.invalid`,
        username: `deleted_${suffix}`,
        fullName: "Deleted User",
        passwordHash: await hashPassword(crypto.randomBytes(32).toString("hex")),
        isActive: false,
        mfaSecret: null,
        mfaEnabled: false,
        mfaRecoveryCodes: null,
        googleId: null,
        appleId: null,
        updatedAt: now,
      })
      .where(eq(users.id, userId));

    // Soft-delete the athlete profile so historical results stay intact.
    await db
      .update(athleteProfiles)
      .set({
        isDeleted: true,
        deletedAt: now,
        displayName: "Deleted User",
        biography: null,
        profilePhoto: null,
        isSearchable: false,
        profileVisibility: "PRIVATE",
        updatedAt: now,
      })
      .where(eq(athleteProfiles.userId, userId));

    // Kill every active session across all devices.
    await db
      .update(userSessions)
      .set({ isRevoked: true })
      .where(
        and(
          eq(userSessions.userId, userId),
          eq(userSessions.isRevoked, false)
        )
      );

    await db.insert(auditLogs).values({
      userId,
      action: "AUTH_ACCOUNT_DELETED",
      details: { anonymizedIdentifier: suffix },
      ipAddress: context?.ipAddress,
      userAgent: context?.userAgent,
    });

    return { message: "Account permanently deleted." };
  }

  // --- DEVICE & SESSION MANAGEMENT ---

  /**
   * Returns all active non-revoked sessions for the user with parsed client details.
   */
  static async getActiveSessions(userId: string) {
    const active = await db
      .select()
      .from(userSessions)
      .where(
        and(
          eq(userSessions.userId, userId),
          eq(userSessions.isRevoked, false)
        )
      )
      .orderBy(desc(userSessions.createdAt));

    return active.map((session) => {
      const details = parseUserAgent(session.userAgent || "");
      return {
        id: session.id,
        ipAddress: session.ipAddress,
        createdAt: session.createdAt,
        expiresAt: session.expiresAt,
        ...details,
      };
    });
  }

  /**
   * Revokes a specific session by ID.
   */
  static async revokeSessionById(userId: string, sessionId: string) {
    const result = await db
      .update(userSessions)
      .set({ isRevoked: true })
      .where(
        and(
          eq(userSessions.id, sessionId),
          eq(userSessions.userId, userId)
        )
      )
      .returning();

    if (result.length === 0) {
      throw new NotFoundError("Session not found or not owned by user.");
    }

    await db.insert(auditLogs).values({
      userId,
      action: "AUTH_SESSION_REVOKED",
      details: { sessionId },
    });

    return { success: true, message: "Session successfully revoked." };
  }

  /**
   * Revokes all active sessions for this user EXCEPT the specified one.
   */
  static async revokeOtherSessions(userId: string, activeRefreshToken: string) {
    let activeFamily = "";
    try {
      const decoded = verifyToken(activeRefreshToken, env.JWT_REFRESH_SECRET);
      activeFamily = decoded.family || "";
    } catch {
      // Fallback: revoke all if current refresh token is unparseable
    }

    if (activeFamily) {
      // Revoke every active session outside the current family. Rotated-out
      // rows of the current family stay revoked so replay detection keeps
      // working — only the caller's own row is re-activated.
      const [currentSession] = await db
        .select()
        .from(userSessions)
        .where(
          and(
            eq(userSessions.userId, userId),
            eq(userSessions.tokenFamily, activeFamily),
            eq(userSessions.isRevoked, false)
          )
        )
        .limit(1);

      await db
        .update(userSessions)
        .set({ isRevoked: true })
        .where(
          and(
            eq(userSessions.userId, userId),
            eq(userSessions.isRevoked, false)
          )
        );

      if (currentSession) {
        await db
          .update(userSessions)
          .set({ isRevoked: false })
          .where(eq(userSessions.id, currentSession.id));
      }
    } else {
      await db
        .update(userSessions)
        .set({ isRevoked: true })
        .where(
          and(
            eq(userSessions.userId, userId),
            eq(userSessions.isRevoked, false)
          )
        );
    }

    await db.insert(auditLogs).values({
      userId,
      action: "AUTH_OTHER_SESSIONS_REVOKED",
      details: { warning: "Revoked all companion active sessions" },
    });

    return { success: true, message: "All other sessions successfully terminated." };
  }

  // --- MULTI-FACTOR AUTHENTICATION (MFA) ---

  /**
   * Sets up multi-factor auth by generating a secure base32 secret.
   */
  static async setupMFA(userId: string) {
    return MFAService.setupMFA(userId);
  }

  /**
   * Enables MFA by validating a verification code.
   */
  static async enableMFA(userId: string, code: string) {
    return MFAService.verifyAndEnableMFA(userId, code);
  }

  /**
   * Disables multi-factor authentication.
   */
  static async disableMFA(userId: string, code: string) {
    return MFAService.disableMFA(userId, code);
  }

  // --- PASSWORD RESET & EMAIL VERIFICATION ---

  /**
   * Initiates the password reset flow.
   */
  static async requestPasswordReset(email: string) {
    const emailLower = email.toLowerCase().trim();
    const [user] = await db
      .select()
      .from(users)
      .where(eq(users.email, emailLower))
      .limit(1);

    if (!user) {
      // Silent response to block user enumeration
      return { success: true, message: "If the email exists, a password reset link has been dispatched." };
    }

    const token = crypto.randomBytes(32).toString("hex");
    const tokenHash = sha256(token);
    const expiresAt = new Date(Date.now() + 3600 * 1000); // 1 hour

    await db.insert(authTokens).values({
      userId: user.id,
      tokenHash,
      tokenType: "password_reset",
      expiresAt,
    });

    // The raw token leaves the system ONLY via out-of-band email delivery.
    // Never in API responses, audit logs, or application logs.
    await EmailDeliveryService.sendPasswordResetEmail({
      to: user.email,
      resetToken: token,
      expiresAt,
    });

    await db.insert(auditLogs).values({
      userId: user.id,
      action: "AUTH_PASSWORD_RESET_REQUESTED",
      details: { expiresAt },
    });

    return {
      success: true,
      message: "If the email exists, a password reset link has been dispatched.",
    };
  }

  /**
   * Updates password after validation.
   */
  static async resetPassword(token: string, passwordPlain: string) {
    const tokenHash = sha256(token);
    const [record] = await db
      .select()
      .from(authTokens)
      .where(
        and(
          eq(authTokens.tokenHash, tokenHash),
          eq(authTokens.tokenType, "password_reset"),
          isNull(authTokens.usedAt),
          gt(authTokens.expiresAt, new Date())
        )
      )
      .limit(1);

    if (!record) {
      throw new BadRequestError("The password reset token is expired or invalid.");
    }

    const userId = record.userId;
    const hashedPassword = await hashPassword(passwordPlain);

    await db
      .update(users)
      .set({ passwordHash: hashedPassword, updatedAt: new Date() })
      .where(eq(users.id, userId));

    await db
      .update(authTokens)
      .set({ usedAt: new Date() })
      .where(eq(authTokens.id, record.id));

    await db.insert(auditLogs).values({
      userId,
      action: "AUTH_PASSWORD_RESET_SUCCESS",
      details: { status: "UPDATED" },
    });

    // Revoke all sessions for this user for security compliance
    await db
      .update(userSessions)
      .set({ isRevoked: true })
      .where(eq(userSessions.userId, userId));

    return { success: true, message: "Your password was successfully updated. All active sessions have been terminated." };
  }

  /**
   * Request email verification link.
   */
  static async requestEmailVerification(userId: string) {
    const [user] = await db
      .select()
      .from(users)
      .where(eq(users.id, userId))
      .limit(1);

    if (!user) throw new NotFoundError("User not found.");

    const token = crypto.randomBytes(32).toString("hex");
    const tokenHash = sha256(token);
    const expiresAt = new Date(Date.now() + 24 * 3600 * 1000); // 24 hours

    await db.insert(authTokens).values({
      userId: user.id,
      tokenHash,
      tokenType: "email_verification",
      expiresAt,
    });

    // The raw token leaves the system ONLY via out-of-band email delivery.
    await EmailDeliveryService.sendEmailVerificationEmail({
      to: user.email,
      verifyToken: token,
      expiresAt,
    });

    await db.insert(auditLogs).values({
      userId,
      action: "AUTH_EMAIL_VERIFY_REQUESTED",
      details: { expiresAt },
    });

    return {
      success: true,
      message: "Email verification link successfully generated.",
    };
  }

  /**
   * Confirms email verification.
   */
  static async verifyEmail(token: string) {
    const tokenHash = sha256(token);
    const [record] = await db
      .select()
      .from(authTokens)
      .where(
        and(
          eq(authTokens.tokenHash, tokenHash),
          eq(authTokens.tokenType, "email_verification"),
          isNull(authTokens.usedAt),
          gt(authTokens.expiresAt, new Date())
        )
      )
      .limit(1);

    if (!record) {
      throw new BadRequestError("The email verification token is expired or invalid.");
    }

    const userId = record.userId;

    await db
      .update(authTokens)
      .set({ usedAt: new Date() })
      .where(eq(authTokens.id, record.id));

    await db.insert(auditLogs).values({
      userId,
      action: "AUTH_EMAIL_VERIFIED",
      details: { status: "VERIFIED" },
    });

    return { success: true, message: "Your email address has been successfully verified." };
  }
}
