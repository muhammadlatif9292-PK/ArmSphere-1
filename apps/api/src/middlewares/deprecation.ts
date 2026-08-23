import { Request, Response, NextFunction } from "express";

/**
 * Middleware to inject API Deprecation and Sunset headers.
 * Helps transition client apps smoothly from v1 to future v2 endpoints.
 */
export function deprecateEndpoint(options: {
  deprecatedAt: Date;
  sunsetAt: Date;
  successorUrl: string;
}) {
  return (req: Request, res: Response, next: NextFunction) => {
    // 1. Deprecation Header (RFC draft-ietf-httpapi-deprecation-header)
    res.setHeader("Deprecation", options.deprecatedAt.toUTCString());

    // 2. Sunset Header (RFC 8594)
    res.setHeader("Sunset", options.sunsetAt.toUTCString());

    // 3. Link Header pointing to successor version
    res.setHeader("Link", `<${options.successorUrl}>; rel="successor-version"`);

    next();
  };
}
