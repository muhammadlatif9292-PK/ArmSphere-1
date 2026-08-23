import { db } from "../config/db.js";
import env from "../config/env.js";
import { scheduledJobs } from "@armsphere/db-schema";
import { eq, and, lte, sql, inArray } from "drizzle-orm";
import { logger } from "@armsphere/core";

function isDbConnectionError(err: any): boolean {
  if (!err) return false;
  const msg = (err.message || String(err)).toLowerCase();
  const code = (err.code || "").toLowerCase();
  return (
    msg.includes("econnrefused") ||
    msg.includes("connection refused") ||
    msg.includes("connect") ||
    msg.includes("timeout") ||
    code.includes("econnrefused")
  );
}

// Mock/stub storage for processed outcomes to verify during testing
export const processedJobsTracker = {
  offlineSyncCompleted: [] as any[],
  prestigeRecalculated: [] as any[],
  titleIntegrityAudited: [] as any[],
  virusScans: [] as any[],
  historicalRecalcs: [] as any[],
  auditScans: [] as any[],
  sanctionExpiries: [] as any[],
  notificationDispatched: [] as any[],
  messageCleanups: [] as any[],
  scheduledAnnouncements: [] as any[],
  pushNotifications: [] as any[],
  pushRetries: [] as any[],
};

/**
 * Reset trackers for deterministic tests
 */
export function resetJobTrackers() {
  processedJobsTracker.offlineSyncCompleted = [];
  processedJobsTracker.prestigeRecalculated = [];
  processedJobsTracker.titleIntegrityAudited = [];
  processedJobsTracker.virusScans = [];
  processedJobsTracker.historicalRecalcs = [];
  processedJobsTracker.auditScans = [];
  processedJobsTracker.sanctionExpiries = [];
  processedJobsTracker.notificationDispatched = [];
  processedJobsTracker.messageCleanups = [];
  processedJobsTracker.scheduledAnnouncements = [];
  processedJobsTracker.pushNotifications = [];
  processedJobsTracker.pushRetries = [];
}

export const SCHEDULED_JOB_TYPES = {
  PRESTIGE_RECALCULATION: "prestige.recalculation.queue",
  TITLE_INTEGRITY_AUDIT: "title.integrity.audit.queue",
  ELO_RECALCULATION_NEW: "elo.recalculation",
  AUDIT_INTEGRITY_SCAN: "audit.integrity.scan",
  SANCTION_EXPIRY: "sanction.expiry",
  MESSAGE_CLEANUP: "message.cleanup",
  ANNOUNCEMENT_SCHEDULER: "announcement.scheduler",
  PUSH_RETRY: "push.retry.queue",
} as const;

// Default recurring schedules (in milliseconds)
export const RECURRENCE_INTERVALS: Record<string, number | null> = {
  [SCHEDULED_JOB_TYPES.PRESTIGE_RECALCULATION]: 24 * 60 * 60 * 1000, // 24 hours
  [SCHEDULED_JOB_TYPES.TITLE_INTEGRITY_AUDIT]: 24 * 60 * 60 * 1000,  // 24 hours
  [SCHEDULED_JOB_TYPES.ELO_RECALCULATION_NEW]: null,                   // On demand / custom trigger
  [SCHEDULED_JOB_TYPES.AUDIT_INTEGRITY_SCAN]: 24 * 60 * 60 * 1000,   // 24 hours
  [SCHEDULED_JOB_TYPES.SANCTION_EXPIRY]: 60 * 60 * 1000,              // 1 hour
  [SCHEDULED_JOB_TYPES.MESSAGE_CLEANUP]: 24 * 60 * 60 * 1000,         // 24 hours
  [SCHEDULED_JOB_TYPES.ANNOUNCEMENT_SCHEDULER]: 15 * 60 * 1000,       // 15 minutes
  [SCHEDULED_JOB_TYPES.PUSH_RETRY]: null,                              // Handled via backoff logic
};

/**
 * Schedule a job in the postgres scheduled_jobs table
 */
export async function scheduleJob(
  jobType: string,
  scheduledFor: Date = new Date(),
  payload: any = null
) {
  logger.info({ jobType, scheduledFor, payload }, "Inserting scheduled job record into database");
  const [job] = await db
    .insert(scheduledJobs)
    .values({
      jobType,
      payload,
      status: "pending",
      scheduledFor,
    })
    .returning();
  return job;
}

export const STALE_JOB_TIMEOUT_MS = 10 * 60 * 1000; // 10 minutes

/**
 * Identifies jobs stuck in 'running' state exceeding timeout and resets them back to 'pending'.
 * Employs row locking (FOR UPDATE SKIP LOCKED) to guarantee concurrency safety across workers.
 */
export async function recoverStaleScheduledJobs(staleTimeoutMs = STALE_JOB_TIMEOUT_MS): Promise<number> {
  const staleThreshold = new Date(Date.now() - staleTimeoutMs);
  logger.info({ staleThreshold }, "Checking for stale running scheduled jobs to recover...");

  try {
    const recoveredJobs = await db.transaction(async (tx) => {
      const staleResult = await tx.execute(sql`
        SELECT id FROM scheduled_jobs
        WHERE status = 'running' AND updated_at <= ${staleThreshold}
        FOR UPDATE SKIP LOCKED
      `);
      const rows = staleResult.rows || [];
      if (rows.length === 0) return [];

      const ids = rows.map((r: any) => r.id);
      const resetJobs = await tx
        .update(scheduledJobs)
        .set({
          status: "pending",
          updatedAt: new Date(),
          lastError: "Job execution timed out / worker process terminated unexpectedly (recovered)",
        })
        .where(inArray(scheduledJobs.id, ids))
        .returning();

      return resetJobs;
    });

    if (recoveredJobs.length > 0) {
      logger.warn({ count: recoveredJobs.length }, "Recovered stale running scheduled jobs back to pending");
    }
    return recoveredJobs.length;
  } catch (err: any) {
    if (!isDbConnectionError(err)) {
      logger.error({ error: err?.message || err }, "Failed to recover stale scheduled jobs");
    }
    return 0;
  }
}

/**
 * Safely claims and executes all pending jobs whose scheduledFor timestamp is due (<= now).
 * Employs row locking (FOR UPDATE SKIP LOCKED) to guarantee concurrency safety.
 */
export async function runDueScheduledJobs() {
  const now = new Date();
  logger.info("Polling for due postgres scheduled jobs...");

  // Recover any stale running jobs first
  await recoverStaleScheduledJobs();

  // Atomic claim using transaction and FOR UPDATE SKIP LOCKED
  let dueJobs: any[] = [];
  try {
    dueJobs = await db.transaction(async (tx) => {
      const dueIdsResult = await tx.execute(sql`
        SELECT id FROM scheduled_jobs
        WHERE status = 'pending' AND scheduled_for <= ${now}
        FOR UPDATE SKIP LOCKED
        LIMIT 50
      `);
      const rows = dueIdsResult.rows || [];
      if (rows.length === 0) return [];

      const ids = rows.map((r: any) => r.id);
      const claimed = await tx
        .update(scheduledJobs)
        .set({ status: "running", updatedAt: now })
        .where(inArray(scheduledJobs.id, ids))
        .returning();
      return claimed;
    });
  } catch (claimErr: any) {
    if (isDbConnectionError(claimErr)) {
      return { executedCount: 0, results: [] };
    }

    // Fallback simple query if transaction/locking unsupported in memory store
    try {
      dueJobs = await db
        .select()
        .from(scheduledJobs)
        .where(
          and(
            eq(scheduledJobs.status, "pending"),
            lte(scheduledJobs.scheduledFor, now)
          )
        );

      for (const job of dueJobs) {
        await db
          .update(scheduledJobs)
          .set({ status: "running", updatedAt: now })
          .where(eq(scheduledJobs.id, job.id));
      }
    } catch (fallbackErr: any) {
      if (isDbConnectionError(fallbackErr)) {
        return { executedCount: 0, results: [] };
      }
      throw fallbackErr;
    }
  }

  logger.info({ count: dueJobs.length }, "Claimed due scheduled jobs to execute");

  const results: any[] = [];

  for (const job of dueJobs) {
    const payload = (job.payload as Record<string, any>) || {};

    let executionError: any = null;
    let jobOutput: any = null;

    try {
      if (
        job.jobType === SCHEDULED_JOB_TYPES.PRESTIGE_RECALCULATION ||
        job.jobType === "PRESTIGE_RECALCULATION"
      ) {
        const { ChampionshipService } = await import("./championship.js");
        await ChampionshipService.recomputePrestigeScores();
        processedJobsTracker.prestigeRecalculated.push(payload);
        jobOutput = { status: "recalculated" };
      } else if (
        job.jobType === SCHEDULED_JOB_TYPES.TITLE_INTEGRITY_AUDIT ||
        job.jobType === "TITLE_INTEGRITY_AUDIT"
      ) {
        const { ChampionshipService } = await import("./championship.js");
        const { championshipTitles } = await import("@armsphere/db-schema");
        const activeTitles = await db.select().from(championshipTitles);
        for (const title of activeTitles) {
          if (!title.activeChampionId) {
            await ChampionshipService.applyAutomaticSuccession(title.id);
          }
        }
        processedJobsTracker.titleIntegrityAudited.push(payload);
        jobOutput = { status: "audited", checkedTitlesCount: activeTitles.length };
      } else if (
        job.jobType === SCHEDULED_JOB_TYPES.ELO_RECALCULATION_NEW ||
        job.jobType === "ELO_RECALCULATION_NEW"
      ) {
        const { GovernanceService } = await import("./governance.js");
        const startingTimestamp = payload.startingTimestamp;
        const resultCount = await GovernanceService.executeEloRecalculation(startingTimestamp);
        processedJobsTracker.historicalRecalcs.push({ ...payload, resultCount });
        jobOutput = { status: "replayed", processedCount: resultCount };
      } else if (
        job.jobType === SCHEDULED_JOB_TYPES.AUDIT_INTEGRITY_SCAN ||
        job.jobType === "AUDIT_INTEGRITY_SCAN"
      ) {
        const { GovernanceService } = await import("./governance.js");
        const result = await GovernanceService.verifyAuditLedger();
        processedJobsTracker.auditScans.push({ timestamp: new Date().toISOString(), result });
        jobOutput = { status: "verified", isValid: result.isValid };
      } else if (
        job.jobType === SCHEDULED_JOB_TYPES.SANCTION_EXPIRY ||
        job.jobType === "SANCTION_EXPIRY"
      ) {
        const { GovernanceService } = await import("./governance.js");
        const expiredCount = await GovernanceService.processSanctionsExpiry();
        processedJobsTracker.sanctionExpiries.push({ timestamp: new Date().toISOString(), expiredCount });
        jobOutput = { status: "processed", expiredCount };
      } else if (
        job.jobType === SCHEDULED_JOB_TYPES.MESSAGE_CLEANUP ||
        job.jobType === "MESSAGE_CLEANUP"
      ) {
        const { MessagingService } = await import("./messaging.js");
        const deletedCount = await MessagingService.cleanupOldMessages(payload.olderThanDays || 30);
        processedJobsTracker.messageCleanups.push(payload);
        jobOutput = { status: "cleaned", deletedCount };
      } else if (
        job.jobType === SCHEDULED_JOB_TYPES.ANNOUNCEMENT_SCHEDULER ||
        job.jobType === "ANNOUNCEMENT_SCHEDULER"
      ) {
        const { AnnouncementService } = await import("./announcement.js");
        const publishedCount = await AnnouncementService.publishScheduledAnnouncements();
        processedJobsTracker.scheduledAnnouncements.push(payload);
        jobOutput = { status: "published", publishedCount };
      } else if (
        job.jobType === SCHEDULED_JOB_TYPES.PUSH_RETRY ||
        job.jobType === "PUSH_RETRY"
      ) {
        const { PushService } = await import("./push.js");
        const { userId, title, content, metadata } = payload;
        processedJobsTracker.pushRetries.push(payload);
        jobOutput = await PushService.sendToUser(userId, title, content, metadata);
      } else {
        throw new Error(`Unknown job type: ${job.jobType}`);
      }
    } catch (err: any) {
      executionError = err;
      logger.error({ error: err, jobId: job.id, jobType: job.jobType }, "Error executing scheduled job");
    }

    const lastRunAt = new Date();

    if (!executionError) {
      await db
        .update(scheduledJobs)
        .set({
          status: "completed",
          lastRunAt,
          lastError: null,
          updatedAt: lastRunAt,
        })
        .where(eq(scheduledJobs.id, job.id));

      results.push({ id: job.id, jobType: job.jobType, status: "completed", output: jobOutput });

      // If recurring job, insert next occurrence
      const recurrenceMs = RECURRENCE_INTERVALS[job.jobType];
      if (recurrenceMs) {
        const nextScheduledFor = new Date(now.getTime() + recurrenceMs);
        await scheduleJob(job.jobType, nextScheduledFor, job.payload);
      }
    } else {
      const errorMessage = executionError?.message || String(executionError);
      await db
        .update(scheduledJobs)
        .set({
          status: "failed",
          lastRunAt,
          lastError: errorMessage,
          updatedAt: lastRunAt,
        })
        .where(eq(scheduledJobs.id, job.id));

      results.push({ id: job.id, jobType: job.jobType, status: "failed", error: errorMessage });

      if (
        job.jobType === SCHEDULED_JOB_TYPES.PUSH_RETRY ||
        job.jobType === "PUSH_RETRY"
      ) {
        const attemptCount = (payload.attemptCount || 1) + 1;
        if (attemptCount <= 5) {
          const nextRetry = new Date(now.getTime() + 5 * 60 * 1000);
          await scheduleJob(job.jobType, nextRetry, { ...payload, attemptCount });
        }
      } else {
        const recurrenceMs = RECURRENCE_INTERVALS[job.jobType];
        if (recurrenceMs) {
          const nextScheduledFor = new Date(now.getTime() + recurrenceMs);
          await scheduleJob(job.jobType, nextScheduledFor, payload);
        }
      }
    }
  }

  return { executedCount: dueJobs.length, results };
}

let scheduledRunnerInterval: NodeJS.Timeout | null = null;

export async function ensureDefaultScheduledJobsExist() {
  const defaultJobs = [
    SCHEDULED_JOB_TYPES.PRESTIGE_RECALCULATION,
    SCHEDULED_JOB_TYPES.TITLE_INTEGRITY_AUDIT,
    SCHEDULED_JOB_TYPES.AUDIT_INTEGRITY_SCAN,
    SCHEDULED_JOB_TYPES.SANCTION_EXPIRY,
    SCHEDULED_JOB_TYPES.MESSAGE_CLEANUP,
    SCHEDULED_JOB_TYPES.ANNOUNCEMENT_SCHEDULER,
  ];

  for (const jobType of defaultJobs) {
    try {
      const existing = await db
        .select()
        .from(scheduledJobs)
        .where(
          and(
            eq(scheduledJobs.jobType, jobType),
            eq(scheduledJobs.status, "pending")
          )
        );
      if (existing.length === 0) {
        await scheduleJob(jobType, new Date());
      }
    } catch {
      // Ignore initial setup errors during migrations
    }
  }
}

export function startScheduledJobsRunner(intervalMs = 60000) {
  if (scheduledRunnerInterval) return;
  ensureDefaultScheduledJobsExist().catch(() => {});
  scheduledRunnerInterval = setInterval(() => {
    runDueScheduledJobs().catch((err) =>
      logger.error({ err }, "Scheduled jobs background runner cycle error")
    );
  }, intervalMs);
}

export function stopScheduledJobsRunner() {
  if (scheduledRunnerInterval) {
    clearInterval(scheduledRunnerInterval);
    scheduledRunnerInterval = null;
  }
}

