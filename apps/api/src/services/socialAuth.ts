import { eq } from "drizzle-orm";
import { db } from "../config/db.js";
import { users, userSessions } from "@armsphere/db-schema";
import { generateAccessToken, generateRefreshToken } from "@armsphere/cryptography";
import { v4 as uuidv4 } from "uuid";
import crypto from "crypto";
import { BadRequestError, logger } from "@armsphere/core";
import env from "../config/env.js";
import { auditLedgerService } from "./auditLedger.js";

// Helper for token hashing
function sha256(content: string): string {
  return crypto.createHash("sha256").update(content).digest("hex");
}

export interface SocialProfile {
  id: string;
  email: string;
  name: string;
  provider: "google" | "apple";
}

export class SocialAuthService {
  /**
   * Generates Google OAuth redirect URL.
   */
  static getGoogleAuthUrl(state: string, redirectUri: string): string {
    const clientId = env.GOOGLE_CLIENT_ID || "MOCK_GOOGLE_CLIENT_ID";
    const scope = encodeURIComponent("openid email profile");
    return `https://accounts.google.com/o/oauth2/v2/auth?client_id=${clientId}&redirect_uri=${encodeURIComponent(
      redirectUri
    )}&response_type=code&scope=${scope}&state=${state}&prompt=select_account`;
  }

  /**
   * Generates Apple OAuth redirect URL.
   */
  static getAppleAuthUrl(state: string, redirectUri: string): string {
    const clientId = env.APPLE_CLIENT_ID || "MOCK_APPLE_CLIENT_ID";
    const scope = encodeURIComponent("name email");
    return `https://appleid.apple.com/auth/authorize?client_id=${clientId}&redirect_uri=${encodeURIComponent(
      redirectUri
    )}&response_type=code&scope=${scope}&response_mode=form_post&state=${state}`;
  }

  /**
   * Exchanges authorization code for Google profile information.
   * Mock profiles exist ONLY for non-production developer convenience.
   * SECURITY: in production a missing/mock code is always rejected.
   */
  static async exchangeGoogleCode(code: string, redirectUri: string): Promise<SocialProfile> {
    const hasCredentials = !!(env.GOOGLE_CLIENT_ID && env.GOOGLE_CLIENT_SECRET);

    if ((!hasCredentials || !code || code.startsWith("mock_")) && env.NODE_ENV !== "production") {
      logger.warn("Google OAuth credentials missing or mock code provided. Using simulated profile (non-production only).");
      return {
        id: "google-mock-id-123456",
        email: "mock.google.athlete@armsphere.com",
        name: "Mock Google Athlete",
        provider: "google",
      };
    }

    if (!code || code.startsWith("mock_")) {
      throw new BadRequestError("A valid Google authorization code is required.");
    }

    try {
      const tokenResponse = await fetch("https://oauth2.googleapis.com/token", {
        method: "POST",
        headers: { "Content-Type": "application/x-www-form-urlencoded" },
        body: new URLSearchParams({
          code,
          client_id: env.GOOGLE_CLIENT_ID,
          client_secret: env.GOOGLE_CLIENT_SECRET,
          redirect_uri: redirectUri,
          grant_type: "authorization_code",
        }).toString(),
      });

      const tokenData: any = await tokenResponse.json();
      if (!tokenData.id_token) {
        throw new BadRequestError("Failed to retrieve id_token from Google OAuth callback.");
      }

      // Safely decode ID token JWT payload without external library
      const base64Url = tokenData.id_token.split(".")[1];
      const base64 = base64Url.replace(/-/g, "+").replace(/_/g, "/");
      const decodedPayload = JSON.parse(Buffer.from(base64, "base64").toString("utf-8"));

      return {
        id: decodedPayload.sub,
        email: decodedPayload.email,
        name: decodedPayload.name || decodedPayload.given_name || "Google User",
        provider: "google",
      };
    } catch (error: any) {
      logger.error({ error: error.message }, "Google OAuth token exchange failed");
      throw new BadRequestError(`Google auth exchange failed: ${error.message}`);
    }
  }

  /**
   * Exchanges authorization code for Apple profile information.
   * Mock profiles exist ONLY for non-production developer convenience.
   * SECURITY: in production a missing/mock code is always rejected.
   */
  static async exchangeAppleCode(code: string, redirectUri: string): Promise<SocialProfile> {
    const hasCredentials = !!(env.APPLE_CLIENT_ID && env.APPLE_CLIENT_SECRET);

    if ((!hasCredentials || !code || code.startsWith("mock_")) && env.NODE_ENV !== "production") {
      logger.warn("Apple OAuth credentials missing or mock code provided. Using simulated profile (non-production only).");
      return {
        id: "apple-mock-id-987654",
        email: "mock.apple.athlete@armsphere.com",
        name: "Mock Apple Athlete",
        provider: "apple",
      };
    }

    if (!code || code.startsWith("mock_")) {
      throw new BadRequestError("A valid Apple authorization code is required.");
    }

    try {
      const tokenResponse = await fetch("https://appleid.apple.com/auth/token", {
        method: "POST",
        headers: { "Content-Type": "application/x-www-form-urlencoded" },
        body: new URLSearchParams({
          code,
          client_id: env.APPLE_CLIENT_ID,
          client_secret: env.APPLE_CLIENT_SECRET,
          redirect_uri: redirectUri,
          grant_type: "authorization_code",
        }).toString(),
      });

      const tokenData: any = await tokenResponse.json();
      if (!tokenData.id_token) {
        throw new BadRequestError("Failed to retrieve id_token from Apple OAuth callback.");
      }

      // Safely decode ID token JWT payload
      const base64Url = tokenData.id_token.split(".")[1];
      const base64 = base64Url.replace(/-/g, "+").replace(/_/g, "/");
      const decodedPayload = JSON.parse(Buffer.from(base64, "base64").toString("utf-8"));

      return {
        id: decodedPayload.sub,
        email: decodedPayload.email,
        name: "Apple User", // Apple only sends user name on first auth
        provider: "apple",
      };
    } catch (error: any) {
      logger.error({ error: error.message }, "Apple OAuth token exchange failed");
      throw new BadRequestError(`Apple auth exchange failed: ${error.message}`);
    }
  }

  /**
   * Implements account linking and merge logic for a social profile.
   */
  static async authenticateSocialProfile(profile: SocialProfile, context?: { ipAddress?: string; userAgent?: string }) {
    const emailLower = profile.email.toLowerCase().trim();

    // 1. Look for user by social ID
    let user;
    if (profile.provider === "google") {
      const [u] = await db.select().from(users).where(eq((users as any).googleId, profile.id)).limit(1);
      user = u;
    } else {
      const [u] = await db.select().from(users).where(eq((users as any).appleId, profile.id)).limit(1);
      user = u;
    }

    // 2. Existing account merge logic: Check if user exists by email but not linked yet
    if (!user) {
      const [existingUserByEmail] = await db.select().from(users).where(eq(users.email, emailLower)).limit(1);

      if (existingUserByEmail) {
        // Link the existing account to this social login
        const updateData: any = { updatedAt: new Date() };
        if (profile.provider === "google") {
          updateData.googleId = profile.id;
        } else {
          updateData.appleId = profile.id;
        }

        const [updatedUser] = await db
          .update(users)
          .set(updateData)
          .where(eq(users.id, existingUserByEmail.id))
          .returning();

        user = updatedUser;

        await auditLedgerService.logEvent({
          actorId: user.id,
          entityType: "USER",
          entityId: user.id,
          action: "AUTH_SOCIAL_ACCOUNT_LINKED",
          payload: { provider: profile.provider, email: emailLower },
        });

        logger.info({ userId: user.id, provider: profile.provider }, "Successfully linked and merged social identity to existing account.");
      } else {
        // 3. Create a brand new account for this social profile
        const username = `${profile.provider}_${crypto.randomBytes(4).toString("hex")}`;
        const randomPasswordHash = `SOCIAL_AUTH_ONLY_${crypto.randomBytes(16).toString("hex")}`;

        const insertData: any = {
          email: emailLower,
          username,
          fullName: profile.name,
          passwordHash: randomPasswordHash,
          role: "ATHLETE",
          isActive: true,
        };

        if (profile.provider === "google") {
          insertData.googleId = profile.id;
        } else {
          insertData.appleId = profile.id;
        }

        const [newUser] = await db.insert(users).values(insertData).returning();
        user = newUser;

        await auditLedgerService.logEvent({
          actorId: user.id,
          entityType: "USER",
          entityId: user.id,
          action: "AUTH_SOCIAL_REGISTERED",
          payload: { provider: profile.provider, email: emailLower },
        });

        logger.info({ userId: user.id, provider: profile.provider }, "Created brand new social login account.");
      }
    } else {
      // Social login for already linked account
      await auditLedgerService.logEvent({
        actorId: user.id,
        entityType: "USER",
        entityId: user.id,
        action: "AUTH_SOCIAL_LOGIN",
        payload: { provider: profile.provider, email: emailLower },
      });
    }

    if (!user.isActive) {
      throw new BadRequestError("Your user account has been disabled. Please contact support.");
    }

    // 4. Issue standard tokens
    const tokenFamily = uuidv4();
    const accessToken = generateAccessToken(user.id, user.email, user.role as any, env.JWT_ACCESS_SECRET);
    const refreshToken = generateRefreshToken(user.id, user.email, user.role as any, tokenFamily, env.JWT_REFRESH_SECRET);

    const refreshTokenHash = sha256(refreshToken);
    const expiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000); // 30 days

    await db.insert(userSessions).values({
      userId: user.id,
      tokenFamily,
      refreshTokenHash,
      isRevoked: false,
      expiresAt,
      ipAddress: context?.ipAddress || "unknown-ip",
      userAgent: context?.userAgent || "unknown-ua",
    });

    const { passwordHash, ...userResponse } = user;
    return {
      user: userResponse,
      accessToken,
      refreshToken,
    };
  }

  /**
   * Prepares deep link redirect payload for Flutter/mobile clients.
   * Format: armsphere://auth/callback?accessToken=...&refreshToken=...
   */
  static getMobileDeepLink(accessToken: string, refreshToken: string): string {
    return `armsphere://auth/callback?accessToken=${encodeURIComponent(accessToken)}&refreshToken=${encodeURIComponent(refreshToken)}`;
  }
}
