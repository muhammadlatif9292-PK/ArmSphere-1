import { Request, Response, NextFunction } from "express";
import { z } from "zod";
import { AuthService } from "../services/auth.js";
import { UserRole } from "@armsphere/types";
import { BadRequestError, UnauthorizedError } from "@armsphere/core";
import { MFAService } from "../services/mfa.js";
import { SocialAuthService } from "../services/socialAuth.js";
import env from "../config/env.js";

// Define strict Zod validation schemas
const RegisterSchema = z.object({
  email: z.string().email({ message: "Invalid email address format." }),
  username: z.string().min(3, { message: "Username must be at least 3 characters long." }).max(50),
  password: z.string().min(8, { message: "Password must be at least 8 characters long." }),
  fullName: z.string().min(2, { message: "Full name must be at least 2 characters long." }),
  role: z.union([
    z.nativeEnum(UserRole),
    z.undefined(),
    z.null(),
  ]).optional().transform(() => UserRole.ATHLETE),
});

const LoginSchema = z.object({
  email: z.string().email({ message: "Invalid email address format." }),
  password: z.string().min(1, { message: "Password is required." }),
  mfaCode: z.string().length(6).optional(),
});

const RefreshSchema = z.object({
  refreshToken: z.string().min(1, { message: "Refresh token is required." }),
});

export class AuthController {
  /**
   * Handles user registration POST /auth/register
   */
  static async register(req: Request, res: Response, next: NextFunction) {
    try {
      const parsed = RegisterSchema.safeParse(req.body);
      if (!parsed.success) {
        throw parsed.error;
      }

      const user = await AuthService.register({
        email: parsed.data.email,
        username: parsed.data.username,
        passwordPlain: parsed.data.password,
        fullName: parsed.data.fullName,
        role: parsed.data.role,
      }, {
        ipAddress: req.ip,
        userAgent: req.headers["user-agent"],
      });

      res.status(201).json({
        success: true,
        data: user,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Handles user login POST /auth/login
   */
  static async login(req: Request, res: Response, next: NextFunction) {
    try {
      const parsed = LoginSchema.safeParse(req.body);
      if (!parsed.success) {
        throw parsed.error;
      }

      const result = await AuthService.login(
        parsed.data.email,
        parsed.data.password,
        {
          ipAddress: req.ip,
          userAgent: req.headers["user-agent"],
          mfaCode: parsed.data.mfaCode,
        }
      );

      if (result.mfaRequired) {
        return res.status(200).json({
          success: true,
          mfaRequired: true,
          data: {
            userId: result.userId,
            message: result.message,
          },
        });
      }

      // Optionally set the refresh token in an HttpOnly secure cookie for enhanced browser security
      res.cookie("refreshToken", result.refreshToken, {
        httpOnly: true,
        secure: process.env.NODE_ENV === "production",
        sameSite: "strict",
        maxAge: 30 * 24 * 60 * 60 * 1000, // 30 Days
      });

      res.status(200).json({
        success: true,
        data: {
          user: result.user,
          accessToken: result.accessToken,
          refreshToken: result.refreshToken, // Included in response for cross-environment ease
        },
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Handles session rotation POST /auth/refresh
   */
  static async refresh(req: Request, res: Response, next: NextFunction) {
    try {
      // Allow receiving token in body or HttpOnly cookie
      const tokenInBody = req.body.refreshToken;
      const tokenInCookie = req.cookies?.refreshToken;
      const token = tokenInBody || tokenInCookie;

      const parsed = RefreshSchema.safeParse({ refreshToken: token });
      if (!parsed.success) {
        throw parsed.error;
      }

      const result = await AuthService.rotateSession(parsed.data.refreshToken, {
        ipAddress: req.ip,
        userAgent: req.headers["user-agent"],
      });

      res.cookie("refreshToken", result.refreshToken, {
        httpOnly: true,
        secure: process.env.NODE_ENV === "production",
        sameSite: "strict",
        maxAge: 30 * 24 * 60 * 60 * 1000,
      });

      res.status(200).json({
        success: true,
        data: {
          accessToken: result.accessToken,
          refreshToken: result.refreshToken,
        },
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Handles session revocation POST /auth/logout
   */
  static async logout(req: Request, res: Response, next: NextFunction) {
    try {
      const token = req.body.refreshToken || req.cookies?.refreshToken;
      if (token) {
        await AuthService.revokeSession(token, req.user?.id || "");
      }

      res.clearCookie("refreshToken");
      res.status(200).json({
        success: true,
        data: { message: "Session successfully terminated." },
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Handles profile lookup GET /auth/me
   */
  static async me(req: Request, res: Response, next: NextFunction) {
    try {
      if (!req.user) {
        throw new BadRequestError("User context not available.");
      }

      const profile = await AuthService.getUserProfile(req.user.id);

      res.status(200).json({
        success: true,
        data: profile,
      });
    } catch (error) {
      next(error);
    }
  }

  // --- DEVICE & SESSION MANAGEMENT ---

  /**
   * Handles account deletion DELETE /auth/me (Phase 12 store readiness).
   */
  static async deleteAccount(req: Request, res: Response, next: NextFunction) {
    try {
      if (!req.user) throw new BadRequestError("User not logged in.");
      const result = await AuthService.deleteAccount(req.user.id, {
        ipAddress: req.ip,
        userAgent: req.get("user-agent") || "",
      });
      res.clearCookie("refreshToken");
      res.status(200).json({
        success: true,
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * GET /auth/sessions - Get active user sessions
   */
  static async getSessions(req: Request, res: Response, next: NextFunction) {
    try {
      if (!req.user) throw new BadRequestError("User not logged in.");
      const sessions = await AuthService.getActiveSessions(req.user.id);
      res.status(200).json({
        success: true,
        data: sessions,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * POST /auth/sessions/:id/revoke - Revoke specific session
   */
  static async revokeSession(req: Request, res: Response, next: NextFunction) {
    try {
      if (!req.user) throw new BadRequestError("User not logged in.");
      const { id } = req.params;
      const result = await AuthService.revokeSessionById(req.user.id, id);
      res.status(200).json({
        success: true,
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * POST /auth/sessions/revoke-others - Revoke all other sessions
   */
  static async revokeOtherSessions(req: Request, res: Response, next: NextFunction) {
    try {
      if (!req.user) throw new BadRequestError("User not logged in.");
      const activeToken = req.body.refreshToken || req.cookies?.refreshToken || "";
      const result = await AuthService.revokeOtherSessions(req.user.id, activeToken);
      res.status(200).json({
        success: true,
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }

  // --- MULTI-FACTOR AUTHENTICATION ---

  /**
   * POST /auth/mfa/setup - Initiate MFA setup
   */
  static async setupMFA(req: Request, res: Response, next: NextFunction) {
    try {
      if (!req.user) throw new BadRequestError("User not logged in.");
      const result = await AuthService.setupMFA(req.user.id);
      res.status(200).json({
        success: true,
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * POST /auth/mfa/verify - Verify TOTP (Enable MFA or complete login challenge)
   */
  static async verifyMFA(req: Request, res: Response, next: NextFunction) {
    try {
      const { code, userId, rememberDevice } = req.body;
      if (!code) throw new BadRequestError("Verification code is required.");

      // Flow 1: If user is logged in (has Bearer token), verify and enable MFA
      if (req.user) {
        const result = await AuthService.enableMFA(req.user.id, code);
        return res.status(200).json({
          success: true,
          data: result,
        });
      }

      // Flow 2: If user is NOT logged in, they are verifying as part of login challenge
      if (!userId) {
        throw new BadRequestError("User ID is required when verifying without active session.");
      }

      // Existence check: rejects unknown challenge identities before TOTP verification.
      await AuthService.getUserProfile(userId);
      const verified = await MFAService.verifyTOTP(userId, code);
      if (!verified) {
        throw new UnauthorizedError("The Multi-Factor authentication code provided is invalid.");
      }

      // Complete authentication directly from the challenge identity. The password
      // factor was already proven when the MFA challenge was issued; calling login
      // with an empty password here always fails and strands MFA-enrolled users.
      const result = await AuthService.completeMfaLogin(userId, {
        ipAddress: req.ip,
        userAgent: req.headers["user-agent"],
        rememberDevice: !!rememberDevice,
      });

      // Optionally set trusted device cookie
      if (result.deviceTrustToken) {
        res.cookie("deviceTrustToken", result.deviceTrustToken, {
          httpOnly: true,
          secure: process.env.NODE_ENV === "production",
          sameSite: "strict",
          maxAge: 30 * 24 * 60 * 60 * 1000, // 30 Days
        });
      }

      res.status(200).json({
        success: true,
        data: {
          user: result.user,
          accessToken: result.accessToken,
          refreshToken: result.refreshToken,
          deviceTrustToken: result.deviceTrustToken,
        },
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * POST /auth/mfa/disable - Disable MFA
   */
  static async disableMFA(req: Request, res: Response, next: NextFunction) {
    try {
      if (!req.user) throw new BadRequestError("User not logged in.");
      const { code } = req.body;
      if (!code) throw new BadRequestError("Verification code is required to disable MFA.");
      const result = await AuthService.disableMFA(req.user.id, code);
      res.status(200).json({
        success: true,
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * POST /auth/mfa/recovery - Recover MFA using a backup code
   */
  static async recoveryMFA(req: Request, res: Response, next: NextFunction) {
    try {
      const { email, recoveryCode } = req.body;
      if (!email || !recoveryCode) {
        throw new BadRequestError("Email and backup recovery code are required.");
      }

      const recoveryResult = await MFAService.recoverMFA(email, recoveryCode);

      // Issue a session directly from the verified recovery identity — never
      // call login with an empty password (it always fails and would strand
      // users after their recovery code has already been consumed).
      const loginResult = await AuthService.completeMfaLogin(recoveryResult.userId, {
        ipAddress: req.ip,
        userAgent: req.headers["user-agent"],
      });

      res.status(200).json({
        success: true,
        data: {
          message: "Account recovered successfully.",
          user: loginResult.user,
          accessToken: loginResult.accessToken,
          refreshToken: loginResult.refreshToken,
        },
      });
    } catch (error) {
      next(error);
    }
  }

  // --- SOCIAL AUTHENTICATION ---

  /**
   * GET /auth/google - Redirect to Google OAuth consent screen
   */
  static async googleLogin(req: Request, res: Response, next: NextFunction) {
    try {
      const state = (req.query.state as string) || crypto.randomUUID();
      const platform = (req.query.platform as string) || "web";
      
      const callbackUrl = `${req.protocol}://${req.get("host")}/api/v1/auth/google/callback?platform=${platform}`;
      const url = SocialAuthService.getGoogleAuthUrl(state, callbackUrl);

      if (req.query.redirect === "true") {
        return res.redirect(url);
      }

      res.status(200).json({
        success: true,
        data: { url },
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * GET /auth/google/callback - Process Google OAuth callback
   */
  static async googleCallback(req: Request, res: Response, next: NextFunction) {
    try {
      const code = (req.query.code as string) || "";
      const platform = (req.query.platform as string) || "web";

      const callbackUrl = `${req.protocol}://${req.get("host")}/api/v1/auth/google/callback?platform=${platform}`;
      const profile = await SocialAuthService.exchangeGoogleCode(code, callbackUrl);

      const result = await SocialAuthService.authenticateSocialProfile(profile, {
        ipAddress: req.ip,
        userAgent: req.headers["user-agent"],
      });

      // Handle mobile client deep-linking
      if (platform === "mobile" || req.query.mobile === "true") {
        const deepLink = SocialAuthService.getMobileDeepLink(result.accessToken, result.refreshToken);
        return res.redirect(deepLink);
      }

      // Handle standard web redirect with tokens
      const redirectUrl = `${env.CORS_ORIGIN}/auth/callback?accessToken=${encodeURIComponent(
        result.accessToken
      )}&refreshToken=${encodeURIComponent(result.refreshToken)}`;

      res.redirect(redirectUrl);
    } catch (error) {
      next(error);
    }
  }

  /**
   * GET /auth/apple - Redirect to Apple OAuth consent screen
   */
  static async appleLogin(req: Request, res: Response, next: NextFunction) {
    try {
      const state = (req.query.state as string) || crypto.randomUUID();
      const platform = (req.query.platform as string) || "web";

      const callbackUrl = `${req.protocol}://${req.get("host")}/api/v1/auth/apple/callback?platform=${platform}`;
      const url = SocialAuthService.getAppleAuthUrl(state, callbackUrl);

      if (req.query.redirect === "true") {
        return res.redirect(url);
      }

      res.status(200).json({
        success: true,
        data: { url },
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * POST/GET /auth/apple/callback - Process Apple OAuth callback
   */
  static async appleCallback(req: Request, res: Response, next: NextFunction) {
    try {
      // Apple callback params can be in body (Form POST) or query
      const code = (req.body?.code as string) || (req.query?.code as string) || "";
      const platform = (req.query?.platform as string) || (req.body?.state as string) || "web";

      const callbackUrl = `${req.protocol}://${req.get("host")}/api/v1/auth/apple/callback?platform=${platform}`;
      const profile = await SocialAuthService.exchangeAppleCode(code, callbackUrl);

      const result = await SocialAuthService.authenticateSocialProfile(profile, {
        ipAddress: req.ip,
        userAgent: req.headers["user-agent"],
      });

      // Handle mobile client deep-linking
      if (platform === "mobile" || req.query?.mobile === "true") {
        const deepLink = SocialAuthService.getMobileDeepLink(result.accessToken, result.refreshToken);
        return res.redirect(deepLink);
      }

      const redirectUrl = `${env.CORS_ORIGIN}/auth/callback?accessToken=${encodeURIComponent(
        result.accessToken
      )}&refreshToken=${encodeURIComponent(result.refreshToken)}`;

      res.redirect(redirectUrl);
    } catch (error) {
      next(error);
    }
  }

  // --- PASSWORD RESET & EMAIL VERIFICATION ---

  /**
   * POST /auth/password-reset/request - Request password reset token
   */
  static async requestPasswordReset(req: Request, res: Response, next: NextFunction) {
    try {
      const { email } = req.body;
      if (!email) throw new BadRequestError("Email address is required.");
      const result = await AuthService.requestPasswordReset(email);
      res.status(200).json({
        success: true,
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * POST /auth/password-reset/reset - Reset password using token
   */
  static async resetPassword(req: Request, res: Response, next: NextFunction) {
    try {
      const { token, password } = req.body;
      if (!token || !password) throw new BadRequestError("Token and new password are required.");
      const result = await AuthService.resetPassword(token, password);
      res.status(200).json({
        success: true,
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * POST /auth/verify-email/request - Request verification link
   */
  static async requestEmailVerification(req: Request, res: Response, next: NextFunction) {
    try {
      if (!req.user) throw new BadRequestError("User not logged in.");
      const result = await AuthService.requestEmailVerification(req.user.id);
      res.status(200).json({
        success: true,
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * POST /auth/verify-email/confirm - Confirm verification using token
   */
  static async verifyEmail(req: Request, res: Response, next: NextFunction) {
    try {
      const { token } = req.body;
      if (!token) throw new BadRequestError("Verification token is required.");
      const result = await AuthService.verifyEmail(token);
      res.status(200).json({
        success: true,
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }
}
