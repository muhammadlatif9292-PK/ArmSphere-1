import { Request, Response, NextFunction } from "express";
import { verifyToken } from "@armsphere/cryptography";
import { UnauthorizedError, ForbiddenError } from "@armsphere/core";
import { UserRole } from "@armsphere/types";
import env from "../config/env.js";
import { SecretRotationService } from "../services/secretRotation.js";

/**
 * Middleware to authenticate requests via Bearer JWT Access Tokens.
 */
export function authenticate(req: Request, res: Response, next: NextFunction) {
  const authHeader = req.headers.authorization;
  
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return next(new UnauthorizedError("Bearer token is missing or malformed in authorization headers."));
  }

  const token = authHeader.substring(7);

  try {
    let decoded: any = null;
    let lastError: any = null;

    // Try all access tokens in the rotation chain
    for (const secret of SecretRotationService.getAccessSecretsChain()) {
      try {
        decoded = verifyToken(token, secret);
        break; // Successfully decoded
      } catch (error) {
        lastError = error;
      }
    }

    if (!decoded) {
      req.log.warn({ error: lastError?.message }, "Authentication failed for incoming request");
      return next(new UnauthorizedError("The provided authorization token is expired or invalid."));
    }
    
    if (decoded.type !== "access") {
      return next(new UnauthorizedError("Invalid token type. Only access tokens are permitted for this resource."));
    }

    req.user = {
      id: decoded.sub,
      email: decoded.email,
      role: decoded.role,
    };

    next();
  } catch (error: any) {
    req.log.warn({ error: error.message }, "Authentication failed for incoming request");
    return next(new UnauthorizedError("The provided authorization token is expired or invalid."));
  }
}

/**
 * Middleware to enforce strict Role-Based Access Control.
 */
export function requireRole(...allowedRoles: UserRole[]) {
  return (req: Request, res: Response, next: NextFunction) => {
    if (!req.user) {
      return next(new UnauthorizedError());
    }

    const hasRole = allowedRoles.includes(req.user.role as UserRole);
    if (!hasRole) {
      req.log.warn(
        { userId: req.user.id, userRole: req.user.role, requiredRoles: allowedRoles },
        "Unauthorized role access attempt detected"
      );
      return next(
        new ForbiddenError(
          `Access denied. Role privilege required: [${allowedRoles.join(", ")}]. Current: ${req.user.role}`
        )
      );
    }

    next();
  };
}

/**
 * Middleware to enforce that Multi-Factor Authentication has been successfully completed
 * (unless the request presents a valid, active Device Trust cookie/token).
 */
export function requireMFA(req: Request, res: Response, next: NextFunction) {
  if (!req.user) {
    return next(new UnauthorizedError("Authentication is required."));
  }

  // 1. Device Trust check ("Remember this device" bypass)
  const deviceTrustToken = (req as any).cookies?.["deviceTrustToken"] || req.headers["x-device-trust-token"];
  if (deviceTrustToken) {
    try {
      // Decode the trusted device JWT and ensure it matches the user
      const decodedDevice = verifyToken(deviceTrustToken as string, env.JWT_ACCESS_SECRET) as any;
      if (decodedDevice && decodedDevice.sub === req.user.id && decodedDevice.type === "device_trust") {
        req.log.info({ userId: req.user.id }, "MFA bypassed via verified Device Trust Token");
        return next();
      }
    } catch {
      // Ignore and proceed to standard MFA check
    }
  }

  // 2. Fetch JWT and inspect if MFA has been verified
  const authHeader = req.headers.authorization;
  if (!authHeader) {
    return next(new UnauthorizedError("Bearer token is missing."));
  }
  const token = authHeader.substring(7);

  try {
    let decoded: any = null;
    for (const secret of SecretRotationService.getAccessSecretsChain()) {
      try {
        decoded = verifyToken(token, secret);
        break;
      } catch {}
    }

    // If user has MFA enabled and decoded token says not verified, reject.
    if (decoded && decoded.mfaRequired && !decoded.mfaVerified) {
      return next(
        new ForbiddenError("Access denied. Multi-Factor Authentication (MFA) verification is required for this resource.")
      );
    }

    next();
  } catch {
    return next(new UnauthorizedError("MFA token verification failed."));
  }
}

/**
 * Middleware to optionally authenticate requests. If a valid token is provided, req.user is set.
 * If no token is provided, or token is invalid, it proceeds without throwing an error (req.user remains undefined).
 */
export function optionalAuthenticate(req: Request, res: Response, next: NextFunction) {
  const authHeader = req.headers.authorization;
  
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return next();
  }

  const token = authHeader.substring(7);

  try {
    let decoded: any = null;

    // Try all access tokens in the rotation chain
    for (const secret of SecretRotationService.getAccessSecretsChain()) {
      try {
        decoded = verifyToken(token, secret);
        break; // Successfully decoded
      } catch {}
    }

    if (decoded && decoded.type === "access") {
      req.user = {
        id: decoded.sub,
        email: decoded.email,
        role: decoded.role,
      };
    }
    
    next();
  } catch {
    next();
  }
}

