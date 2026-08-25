import { Router, Request, Response } from "express";
import env from "../config/env.js";
import { runDueScheduledJobs } from "../services/scheduledJobs.js";
import { logger } from "@armsphere/core";
import { safeSecretCompare } from "../middlewares/security.js";

export const internalRouter = Router();

/**
 * Protected internal route for triggering scheduled jobs via infrastructure (e.g., cron triggers).
 * Expects X-Cron-Secret header matching env.CRON_SECRET (constant-time comparison).
 */
internalRouter.post("/scheduled-jobs/run", async (req: Request, res: Response) => {
  const cronSecret = req.headers["x-cron-secret"];
  const provided = Array.isArray(cronSecret) ? cronSecret[0] : cronSecret;

  if (!safeSecretCompare(provided as string | undefined, env.CRON_SECRET)) {
    logger.warn({ ip: req.ip }, "Unauthorized access attempt to internal scheduled-jobs trigger");
    res.status(401).json({ error: "Unauthorized: Invalid or missing X-Cron-Secret header" });
    return;
  }

  try {
    const result = await runDueScheduledJobs();
    res.status(200).json({
      success: true,
      message: "Scheduled jobs execution triggered successfully",
      data: result,
    });
  } catch (error: any) {
    logger.error({ error }, "Error running due scheduled jobs via internal route");
    res.status(500).json({ error: error?.message || "Internal server error running scheduled jobs" });
  }
});

export default internalRouter;
