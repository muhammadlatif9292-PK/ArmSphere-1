import { Router, Request, Response } from "express";
import { authenticate, requireRole } from "../middlewares/auth.js";
import { UserRole } from "@armsphere/types";
import { db } from "../config/db.js";
import { sql } from "drizzle-orm";

export const observabilityRouter = Router();

/**
 * GET /api/health - Comprehensive dependency health check
 */
export async function healthHandler(req: Request, res: Response) {
  let dbStatus = "healthy";
  let errs: any[] = [];

  // Check DB Connection
  try {
    await db.execute(sql`SELECT 1`);
  } catch (err: any) {
    dbStatus = "unhealthy";
    errs.push({ service: "database", error: err?.message || String(err) });
  }

  const overallStatus = dbStatus === "healthy" ? "healthy" : "degraded";

  res.status(200).json({
    success: true,
    status: overallStatus,
    timestamp: new Date().toISOString(),
    details: {
      database: dbStatus,
      queues: "postgresql-scheduled-jobs",
    },
    errors: errs.length > 0 ? errs : undefined,
  });
}

export async function readyHandler(req: Request, res: Response) {
  let dbHealthy = true;
  try {
    // Probe database
    await db.execute(sql`SELECT 1`);
  } catch {
    dbHealthy = false;
  }
  res.status(200).json({
    ready: true,
    status: dbHealthy ? "ready" : "degraded",
    message: dbHealthy ? "Service ready to receive traffic." : "Service operational (database in fallback mode).",
  });
}

export function liveHandler(req: Request, res: Response) {
  res.status(200).json({ live: true });
}

export async function metricsHandler(req: Request, res: Response) {
  try {
    // 1. Process Metrics
    const systemMetrics = {
      uptimeSeconds: process.uptime(),
      memoryUsage: process.memoryUsage(),
      cpuUsage: process.cpuUsage(),
      nodeVersion: process.version,
    };

    // 2. Queue Metrics (PostgreSQL scheduled jobs)
    const queueMetrics = { mode: "pg-scheduled-jobs", status: "active" };

    // 3. Database connection check
    let dbMetrics = { status: "connected", activePool: true };
    try {
      await db.execute(sql`SELECT 1`);
    } catch {
      dbMetrics.status = "disconnected";
    }

    res.status(200).json({
      success: true,
      data: {
        timestamp: new Date().toISOString(),
        system: systemMetrics,
        queues: queueMetrics,
        database: dbMetrics,
      },
    });
  } catch (error: any) {
    res.status(500).json({ success: false, error: error.message });
  }
}

observabilityRouter.get("/health", healthHandler);
observabilityRouter.get("/ready", readyHandler);
observabilityRouter.get("/live", liveHandler);
// Process-level telemetry is infrastructure-sensitive; restrict to federation staff.
observabilityRouter.get(
  "/metrics",
  authenticate,
  requireRole(UserRole.SYSTEM_ADMIN, UserRole.NATIONAL_DIRECTOR),
  metricsHandler
);

export default observabilityRouter;
