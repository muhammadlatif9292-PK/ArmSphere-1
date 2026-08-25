import { Request, Response, NextFunction } from "express";
import crypto from "crypto";
import { logger } from "@armsphere/core";

// --- 1. Rate Limiting Middleware ---
const memoryLimiterStore = new Map<string, { count: number; resetTime: number }>();

export function rateLimiter(windowMs: number = 60 * 1000, maxRequests: number = 100) {
  return async (req: Request, res: Response, next: NextFunction) => {
    if (process.env.NODE_ENV === "test" || process.env.VITEST === "true") {
      return next();
    }
    const ip = req.ip || req.socket.remoteAddress || "unknown-ip";
    const key = `ratelimit:${ip}:${req.path}`;

    try {
      const now = Date.now();
      const record = memoryLimiterStore.get(key);

      if (!record || now > record.resetTime) {
        memoryLimiterStore.set(key, { count: 1, resetTime: now + windowMs });
      } else {
        record.count++;
        if (record.count > maxRequests) {
          return res.status(429).json({
            success: false,
            error: "Too Many Requests",
            message: "API rate limit exceeded. Please try again later.",
          });
        }
      }
      next();
    } catch (err) {
      logger.warn({ err }, "Rate limiter encountered an issue, bypassing for resilience.");
      next();
    }
  };
}

// --- 3. Internal secret comparison (constant-time) ---
export function safeSecretCompare(a?: string, b?: string): boolean {
  if (!a || !b) return false;
  const bufA = Buffer.from(a);
  const bufB = Buffer.from(b);
  if (bufA.length !== bufB.length) {
    // Still burn a comparison to keep timing uniform for wrong-length guesses.
    crypto.timingSafeEqual(bufA, bufA);
    return false;
  }
  return crypto.timingSafeEqual(bufA, bufB);
}

// --- 4. Helmet-equivalent Security Headers & CSP ---
// Derived strictly from audited application requirements:
//  - API hosts the admin SPA + Swagger UI (scripts/styles/images all same-origin bundles)
//  - Admin SPA loads Google Fonts CSS + font binaries
//  - Moderation preview embeds YouTube/TikTok/Facebook iframes (frame-src)
//  - User-generated media URLs are rendered as <img> (any https host)
//  - SPA talks to same-origin API (or https://api.armsphere.com per OpenAPI servers)
//  - No WebSockets, Workers, blob: resources, plugins, or third-party scripts exist
const API_CSP = [
  "default-src 'self'",
  "script-src 'self'",
  "style-src 'self' 'unsafe-inline' https://fonts.googleapis.com",
  "font-src 'self' https://fonts.gstatic.com data:",
  "img-src 'self' data: https:",
  "connect-src 'self' https://api.armsphere.com",
  "frame-src https://www.youtube.com https://www.tiktok.com https://www.facebook.com",
  "frame-ancestors 'none'",
  "object-src 'none'",
  "base-uri 'self'"
].join("; ");

export function securityHeaders(req: Request, res: Response, next: NextFunction) {
  res.setHeader("Content-Security-Policy", API_CSP);
  // Content Type Sniffing protection
  res.setHeader("X-Content-Type-Options", "nosniff");
  // HSTS (HTTP Strict Transport Security)
  res.setHeader("Strict-Transport-Security", "max-age=15552000; includeSubDomains; preload");
  // Referrer Policy
  res.setHeader("Referrer-Policy", "strict-origin-when-cross-origin");
  // Permissions Policy
  res.setHeader("Permissions-Policy", "camera=(), microphone=(), geolocation=()");
  // Remove X-Powered-By
  res.removeHeader("X-Powered-By");

  next();
}

// --- 3. Double-Submit Cookie CSRF Protection ---
// Securely generates and validates CSRF tokens
export function csrfProtection(req: Request, res: Response, next: NextFunction) {
  // Bypass CSRF checks in test environment for API integration testing convenience
  // Unless explicitly forced via a test header for unit-testing the middleware
  const forceCsrf = req.headers?.["x-test-force-csrf"] === "true";
  if ((process.env.NODE_ENV === "test" || process.env.VITEST === "true") && !forceCsrf) {
    return next();
  }

  // Exempt payments webhook from CSRF checks
  if (req.path === "/payments/webhook") {
    return next();
  }

  // Exempt identity-establishing auth endpoints. They accept explicit body
  // credentials and never rely on ambient cookie sessions, so double-submit
  // CSRF does not apply; native clients hold neither cookies nor a Bearer
  // token before their first login. These routes are guarded by rate limiting.
  const credentialEndpoint =
    /^\/auth\/(register|login|refresh|mfa\/verify|mfa\/recovery|password-reset\/request|password-reset\/reset|verify-email\/confirm)$/;
  if (credentialEndpoint.test(req.path.replace(/^\/api\/v1/, ""))) {
    return next();
  }

  // Safe HTTP methods do not require CSRF validation
  const safeMethods = ["GET", "HEAD", "OPTIONS"];
  if (safeMethods.includes(req.method)) {
    // Generate and attach CSRF cookie if missing
    let csrfToken = (req as any).cookies?.["_csrf"];
    if (!csrfToken) {
      csrfToken = crypto.randomBytes(24).toString("hex");
      res.cookie("_csrf", csrfToken, {
        httpOnly: false, // Accessible by JS client for Header inclusion
        secure: process.env.NODE_ENV === "production",
        sameSite: "lax",
        maxAge: 24 * 60 * 60 * 1000, // 1 day
      });
    }
    return next();
  }

  // Exempt clients that authorize via Bearer JWT since CSRF applies strictly to browser Cookie-based auto-auth
  const authHeader = req.headers.authorization;
  if (authHeader && authHeader.startsWith("Bearer ")) {
    return next();
  }

  const cookieToken = (req as any).cookies?.["_csrf"];
  const headerToken = req.headers["x-csrf-token"] || req.body?._csrf || req.query?._csrf;

  if (!cookieToken || !headerToken || cookieToken !== headerToken) {
    return res.status(403).json({
      success: false,
      error: "CSRF Validation Failed",
      message: "The CSRF protection token was missing, expired, or mismatching.",
    });
  }

  next();
}

// --- 4. Input Sanitization ---
// Recursively sanitizes request data of dangerous script entities
export function sanitizeInput(req: Request, res: Response, next: NextFunction) {
  const sanitize = (val: any): any => {
    if (typeof val === "string") {
      return val
        .replace(/<script[^>]*>([\s\S]*?)<\/script>/gi, "") // strip out full script tags
        .replace(/<\/?[^>]+(>|$)/g, "") // strip all HTML tags
        .trim();
    }
    if (val && typeof val === "object") {
      if (Array.isArray(val)) {
        return val.map(sanitize);
      }
      const cleaned: any = {};
      for (const key in val) {
        if (Object.prototype.hasOwnProperty.call(val, key)) {
          cleaned[key] = sanitize(val[key]);
        }
      }
      return cleaned;
    }
    return val;
  };

  req.body = sanitize(req.body);
  req.query = sanitize(req.query);
  req.params = sanitize(req.params);

  next();
}

// --- 5. File Upload Sanitizer / Policy ---
export function validateUploadPolicy(allowedExtensions: string[] = ["jpg", "jpeg", "png", "pdf"], maxSizeBytes: number = 10 * 1024 * 1024) {
  return (req: Request, res: Response, next: NextFunction) => {
    // If request contains file properties (e.g. from multer/multipart), validate them
    const files = (req as any).files || ((req as any).file ? [(req as any).file] : []);
    
    for (const file of files) {
      if (file.size > maxSizeBytes) {
        return res.status(400).json({
          success: false,
          error: "Payload Too Large",
          message: `File size exceeds max limit of ${maxSizeBytes / (1024 * 1024)}MB.`,
        });
      }

      const originalName = file.originalname || "";
      const ext = originalName.split(".").pop()?.toLowerCase() || "";
      if (!allowedExtensions.includes(ext)) {
        return res.status(400).json({
          success: false,
          error: "Unsupported File Format",
          message: `Only file extensions [${allowedExtensions.join(", ")}] are permitted.`,
        });
      }

      // MIME validation
      const safeMimeTypes = ["image/jpeg", "image/png", "application/pdf"];
      if (file.mimetype && !safeMimeTypes.includes(file.mimetype)) {
        return res.status(400).json({
          success: false,
          error: "Malicious Content Detected",
          message: "MIME-type check failed. Malicious uploaded content is prohibited.",
        });
      }
    }

    next();
  };
}
