import express, { Request, Response, NextFunction } from "express";
import cors from "cors";
import path from "path";
import fs from "fs";
import { requestIdMiddleware, errorHandler } from "@armsphere/core";
import { securityHeaders, rateLimiter, csrfProtection, sanitizeInput } from "./middlewares/security.js";
import { authRouter } from "./routes/auth.js";
import { syncRouter } from "./routes/sync.js";
import { athleteRouter } from "./routes/athlete.js";
import { socialRouter } from "./routes/social.js";
import { communityRouter } from "./routes/community.js";
import { matchRouter } from "./routes/match.js";
import { rankingsRouter } from "./routes/rankings.js";
import { analyticsRouter } from "./routes/analytics.js";
import { championshipRouter } from "./routes/championship.js";
import { tournamentRouter } from "./routes/tournament.js";
import { governanceRouter } from "./routes/governance.js";
import { communicationRouter } from "./routes/communication.js";
import { adminRouter } from "./routes/admin.js";
import { observabilityRouter, healthHandler, readyHandler, liveHandler } from "./routes/observability.js";
import { securityRouter } from "./routes/security.js";
import { docsRouter } from "./routes/docs.js";
import { paymentRouter } from "./routes/payment.js";
import { venueRouter } from "./routes/venue.js";
import { nominationRouter } from "./routes/nomination.js";
import { refereeCertificationRouter } from "./routes/refereeCertification.js";
import { informalEventRouter } from "./routes/informalEvent.js";
import { ticketRouter } from "./routes/ticket.js";
import { internalRouter } from "./routes/internal.js";

export const app = express();

// Disable standard x-powered-by header for security hardening
app.disable("x-powered-by");

// Apply security headers & Content Security Policy (CSP)
app.use(securityHeaders);

// Lightweight zero-dependency cookie parsing middleware
app.use((req: Request, res: Response, next: NextFunction) => {
  const cookieHeader = req.headers.cookie;
  (req as any).cookies = {};
  
  if (cookieHeader) {
    cookieHeader.split(";").forEach((cookie) => {
      const equalIndex = cookie.indexOf("=");
      if (equalIndex > -1) {
        const key = cookie.substring(0, equalIndex).trim();
        const value = cookie.substring(equalIndex + 1).trim();
        (req as any).cookies[key] = decodeURIComponent(value);
      }
    });
  }
  next();
});

app.use(
  cors({
    origin: true,
    credentials: true,
  })
);

app.use(
  express.json({
    limit: "15mb",
    verify: (req: any, res, buf) => {
      req.rawBody = buf;
    }
  })
);
app.use(requestIdMiddleware);

// Apply rate limiting (e.g. max 150 requests per minute per IP), CSRF validation & XSS sanitization
app.use(rateLimiter(60 * 1000, 150));
app.use(csrfProtection);
app.use(sanitizeInput);

// Health, Readiness, and Liveness APIs
app.get("/health", (req: Request, res: Response) => {
  res.status(200).send("OK");
});
app.use("/api/v1", docsRouter);
app.use("/api/v1/observability", observabilityRouter);
app.get("/api/health", healthHandler);
app.get("/api/ready", readyHandler);
app.get("/api/live", liveHandler);

// Auth Route Bindings
app.use("/auth", authRouter);
app.use("/api/v1/auth", authRouter);
app.use("/api/v1/security", securityRouter);
app.use("/sync", syncRouter);
app.use("/api/v1/sync", syncRouter);
app.use("/athletes", athleteRouter);
app.use("/api/v1/athletes", athleteRouter);
app.use("/social", socialRouter);
app.use("/api/v1/social", socialRouter);
app.use("/community", communityRouter);
app.use("/api/v1/community", communityRouter);
app.use("/matches", matchRouter);
app.use("/api/v1/matches", matchRouter);
app.use("/rankings", rankingsRouter);
app.use("/api/v1/rankings", rankingsRouter);
app.use("/api/v1/analytics", analyticsRouter);
app.use("/analytics", analyticsRouter);
app.use("/championships", championshipRouter);
app.use("/api/v1/championships", championshipRouter);
app.use("/tournaments", tournamentRouter);
app.use("/api/v1/tournaments", tournamentRouter);
app.use("/governance", governanceRouter);
app.use("/api/governance", governanceRouter);
app.use("/api/v1/governance", governanceRouter);
app.use("/communication", communicationRouter);
app.use("/api/v1/notifications", communicationRouter);
app.use("/payments", paymentRouter);
app.use("/api/v1/payments", paymentRouter);
app.use("/venues", venueRouter);
app.use("/api/v1/venues", venueRouter);
app.use("/nominations", nominationRouter);
app.use("/api/v1/nominations", nominationRouter);
app.use("/referees", refereeCertificationRouter);
app.use("/api/v1/referees", refereeCertificationRouter);
app.use("/informal-events", informalEventRouter);
app.use("/api/v1/informal-events", informalEventRouter);
app.use("/admin", adminRouter);
app.use("/api/v1/admin", adminRouter);
app.use("/internal", internalRouter);
app.use("/api/v1/internal", internalRouter);
app.use("/", ticketRouter);

const candidateDistPaths = [
  path.resolve(process.cwd(), "dist"),
  path.resolve(process.cwd(), "../../dist"),
  path.resolve(process.cwd(), "../admin-web/dist"),
  path.resolve(process.cwd(), "apps/admin-web/dist"),
  path.resolve(process.cwd(), "apps/api/dist"),
  path.resolve(process.cwd(), "."),
];
const distPath = candidateDistPaths.find((p) => fs.existsSync(path.join(p, "index.html"))) || candidateDistPaths[0];

app.use(express.static(distPath));

app.get("*", (req: Request, res: Response, next: NextFunction) => {
  // If requesting api routes, bypass static fallback
  if (req.path.startsWith("/api") || req.path.startsWith("/auth") || req.path.startsWith("/sync")) {
    return next();
  }
  const indexPath = path.join(distPath, "index.html");
  if (fs.existsSync(indexPath)) {
    res.sendFile(indexPath);
  } else {
    next();
  }
});

// RFC-7807 Global Error Interceptor
app.use(errorHandler);

export default app;
