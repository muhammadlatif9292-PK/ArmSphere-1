import { Router } from "express";
import { AuthController } from "../controllers/auth.js";
import { authenticate, optionalAuthenticate } from "../middlewares/auth.js";

export const authRouter = Router();

authRouter.post("/register", AuthController.register);
authRouter.post("/login", AuthController.login);
authRouter.post("/refresh", AuthController.refresh);
authRouter.post("/logout", AuthController.logout);
authRouter.get("/me", authenticate, AuthController.me);

// --- Session & Device Management ---
authRouter.get("/sessions", authenticate, AuthController.getSessions);
authRouter.post("/sessions/revoke-others", authenticate, AuthController.revokeOtherSessions);
authRouter.post("/sessions/:id/revoke", authenticate, AuthController.revokeSession);

// --- Multi-Factor Authentication ---
authRouter.post("/mfa/setup", authenticate, AuthController.setupMFA);
authRouter.post("/mfa/verify", optionalAuthenticate, AuthController.verifyMFA); // Authenticated (to enable) or Public (to login)
authRouter.post("/mfa/disable", authenticate, AuthController.disableMFA);
authRouter.post("/mfa/recovery", AuthController.recoveryMFA);

// --- Social Authentication (OAuth2) ---
authRouter.get("/google", AuthController.googleLogin);
authRouter.get("/google/callback", AuthController.googleCallback);
authRouter.get("/apple", AuthController.appleLogin);
authRouter.get("/apple/callback", AuthController.appleCallback);
authRouter.post("/apple/callback", AuthController.appleCallback);

// --- Password Reset Flow ---
authRouter.post("/password-reset/request", AuthController.requestPasswordReset);
authRouter.post("/password-reset/reset", AuthController.resetPassword);

// --- Email Verification Flow ---
authRouter.post("/verify-email/request", authenticate, AuthController.requestEmailVerification);
authRouter.post("/verify-email/confirm", AuthController.verifyEmail);

export default authRouter;
