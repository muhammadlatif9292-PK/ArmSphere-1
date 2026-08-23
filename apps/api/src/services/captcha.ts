import { logger } from "@armsphere/core";
import env from "../config/env.js";

export class CaptchaService {
  /**
   * Verifies a CAPTCHA token using Cloudflare Turnstile siteverify API.
   * The bypass paths below (missing secret key, mock success tokens) exist for
   * frictionless local development and automated testing only — they are
   * hard-gated to non-production environments so the endpoint can never
   * silently fail open in production.
   */
  static async verifyToken(token: string, ip?: string): Promise<boolean> {
    const secretKey = env.CAPTCHA_SECRET_KEY;
    const isProduction = env.NODE_ENV === "production";

    if (!secretKey) {
      if (isProduction) {
        logger.error("CAPTCHA_SECRET_KEY is not configured in production. Failing closed.");
        return false;
      }
      logger.warn("CAPTCHA_SECRET_KEY is not configured. Automatically bypassing CAPTCHA verification (Non-prod safety fallback).");
      return true;
    }

    if (!isProduction && (token === "MOCK_SUCCESS_TOKEN" || token === "mock_token")) {
      return true;
    }

    try {
      const response = await fetch("https://challenges.cloudflare.com/turnstile/v0/siteverify", {
        method: "POST",
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: new URLSearchParams({
          secret: secretKey,
          response: token,
          remoteip: ip || "",
        }).toString(),
      });

      const data: any = await response.json();
      
      if (!data.success) {
        logger.warn({ data, ip }, "CAPTCHA verification failed");
        return false;
      }

      return true;
    } catch (error) {
      logger.error({ error }, "Error calling CAPTCHA verification API");
      // Fallback to false in case of API issues to maintain secure posture
      return false;
    }
  }
}
