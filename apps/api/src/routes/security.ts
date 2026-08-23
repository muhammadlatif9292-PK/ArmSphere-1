import { Router, Request, Response, NextFunction } from "express";
import { CaptchaService } from "../services/captcha.js";
import { BadRequestError } from "@armsphere/core";

export const securityRouter = Router();

/**
 * POST /api/v1/security/captcha/verify
 * Verifies Turnstile or reCAPTCHA tokens.
 */
securityRouter.post(
  "/captcha/verify",
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { token } = req.body;
      if (!token) {
        throw new BadRequestError("CAPTCHA verification token is required.");
      }

      const isValid = await CaptchaService.verifyToken(token, req.ip);

      res.status(200).json({
        success: isValid,
        data: {
          verified: isValid,
          message: isValid
            ? "CAPTCHA verification succeeded."
            : "CAPTCHA verification failed.",
        },
      });
    } catch (error) {
      next(error);
    }
  }
);

export default securityRouter;
