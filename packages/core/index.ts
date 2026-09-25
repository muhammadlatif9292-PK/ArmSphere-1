import { Request, Response, NextFunction } from "express";

export class CustomError extends Error {
  public status: number;
  constructor(message: string, status: number) {
    super(message);
    this.status = status;
    this.name = this.constructor.name;
  }
}

export class BadRequestError extends CustomError {
  constructor(message = "Bad Request") {
    super(message, 400);
  }
}

export class UnauthorizedError extends CustomError {
  constructor(message = "Unauthorized") {
    super(message, 401);
  }
}

export class ForbiddenError extends CustomError {
  constructor(message = "Forbidden") {
    super(message, 403);
  }
}

export class NotFoundError extends CustomError {
  constructor(message = "Not Found") {
    super(message, 404);
  }
}

export class ConflictError extends CustomError {
  constructor(message = "Conflict") {
    super(message, 409);
  }
}

export const logger = {
  info: (msg: any, ...args: any[]) => console.log(`[INFO]`, msg, ...args),
  error: (msg: any, ...args: any[]) => console.error(`[ERROR]`, msg, ...args),
  warn: (msg: any, ...args: any[]) => console.warn(`[WARN]`, msg, ...args),
  debug: (msg: any, ...args: any[]) => console.debug(`[DEBUG]`, msg, ...args),
};

export function requestIdMiddleware(req: any, res: Response, next: NextFunction) {
  req.id = req.headers["x-request-id"] || `req-${Math.random().toString(36).substr(2, 9)}`;
  req.log = {
    info: (msg: any, ...args: any[]) => logger.info(msg, ...args),
    warn: (msg: any, ...args: any[]) => logger.warn(msg, ...args),
    error: (msg: any, ...args: any[]) => logger.error(msg, ...args),
    debug: (msg: any, ...args: any[]) => logger.debug(msg, ...args),
  };
  next();
}

const HTTP_STATUS_TITLES: Record<number, string> = {
  400: "Bad Request",
  401: "Unauthorized",
  403: "Forbidden",
  404: "Not Found",
  409: "Conflict",
  422: "Unprocessable Entity",
  429: "Too Many Requests",
  500: "Internal Server Error",
};

export function errorHandler(err: any, req: Request, res: Response, next: NextFunction) {
  // Zod validation errors carry an `issues` array; surface them as a field->message map.
  const isZodError = Array.isArray(err?.issues);

  if (isZodError) {
    const errors: Record<string, string> = {};
    for (const issue of err.issues) {
      const key = Array.isArray(issue.path) && issue.path.length > 0 ? issue.path.join(".") : "_";
      if (!(key in errors)) {
        errors[key] = issue.message;
      }
    }
    const status = 400;
    const errorList = Object.entries(errors).map(([field, msg]) => field === "_" ? msg : `${field}: ${msg}`);
    const detail = errorList.length > 0 ? errorList.join("; ") : "The request payload failed validation.";
    logger.error(`${req.method} ${req.path} failed: Validation Failed - ${detail}`, err);
    return res.status(status).json({
      success: false,
      title: "Validation Failed",
      detail,
      status,
      errors,
      invalidParams: errors,
      requestId: (req as any).id,
    });
  }

  // Handle Postgres / database malformed UUID errors as 400 Bad Request
  const isMalformedUuid =
    err?.code === "22P02" ||
    (typeof err?.message === "string" && err.message.toLowerCase().includes("invalid input syntax for type uuid"));

  if (isMalformedUuid) {
    const status = 400;
    logger.error(`${req.method} ${req.path} failed: Malformed UUID Identifier`, err);
    return res.status(status).json({
      success: false,
      title: "Bad Request",
      detail: "Invalid UUID format in request identifier.",
      status,
      requestId: (req as any).id,
    });
  }

  const status = err.status || 500;
  let message = err.message || "Internal Server Error";
  const title = HTTP_STATUS_TITLES[status] || "Internal Server Error";

  // In production or staging, sanitize 5xx messages and never expose raw stack or query traces
  const isProdOrStaging = process.env.NODE_ENV === "production" || process.env.NODE_ENV === "staging";
  if (status >= 500 && isProdOrStaging) {
    message = "An internal server error occurred.";
  }

  logger.error(`${req.method} ${req.path} failed: ${message}`, err);

  res.status(status).json({
    success: false,
    title,
    detail: message,
    status,
    requestId: (req as any).id,
  });
}
