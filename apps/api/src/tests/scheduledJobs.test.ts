import { describe, it, expect, beforeEach } from "vitest";
import supertest from "supertest";
import { testDbStore } from "./setup.js";
import { app } from "../app.js";
import { 
  scheduleJob, 
  runDueScheduledJobs, 
  recoverStaleScheduledJobs,
  SCHEDULED_JOB_TYPES,
  processedJobsTracker,
  resetJobTrackers 
} from "../services/scheduledJobs.js";
import { createTestUserFixture } from "./factories.js";
import { UserRole } from "@armsphere/types";
import { generateAccessToken } from "@armsphere/cryptography";
import { env } from "../config/env.js";

describe("Postgres-Backed Scheduled Jobs System Tests", () => {
  let adminToken: string;

  beforeEach(async () => {
    resetJobTrackers();
    testDbStore.scheduledJobs = [];

    const adminUser = createTestUserFixture({ role: UserRole.SYSTEM_ADMIN });
    testDbStore.users.push(adminUser);
    adminToken = generateAccessToken(adminUser.id, adminUser.email, UserRole.SYSTEM_ADMIN, env.JWT_ACCESS_SECRET);
  });

  it("should schedule jobs into the scheduled_jobs table with pending status", async () => {
    const job = await scheduleJob(
      SCHEDULED_JOB_TYPES.PRESTIGE_RECALCULATION,
      new Date(),
      { titleId: "title-1" }
    );

    expect(job).toBeDefined();
    expect(job.jobType).toBe(SCHEDULED_JOB_TYPES.PRESTIGE_RECALCULATION);
    expect(job.status).toBe("pending");
    expect(job.payload).toEqual({ titleId: "title-1" });
    expect(testDbStore.scheduledJobs.length).toBe(1);
  });

  it("should run all 8 due scheduled jobs, mark completed, and create recurring jobs", async () => {
    const pastDate = new Date(Date.now() - 10000); // 10 seconds ago

    // Schedule all 8 jobs
    await scheduleJob(SCHEDULED_JOB_TYPES.PRESTIGE_RECALCULATION, pastDate, { id: 1 });
    await scheduleJob(SCHEDULED_JOB_TYPES.TITLE_INTEGRITY_AUDIT, pastDate, { id: 2 });
    await scheduleJob(SCHEDULED_JOB_TYPES.ELO_RECALCULATION_NEW, pastDate, { startingTimestamp: 1000 });
    await scheduleJob(SCHEDULED_JOB_TYPES.AUDIT_INTEGRITY_SCAN, pastDate, { id: 4 });
    await scheduleJob(SCHEDULED_JOB_TYPES.SANCTION_EXPIRY, pastDate, { id: 5 });
    await scheduleJob(SCHEDULED_JOB_TYPES.MESSAGE_CLEANUP, pastDate, { olderThanDays: 30 });
    await scheduleJob(SCHEDULED_JOB_TYPES.ANNOUNCEMENT_SCHEDULER, pastDate, { id: 7 });
    await scheduleJob(SCHEDULED_JOB_TYPES.PUSH_RETRY, pastDate, { userId: "user-1", title: "Test", content: "Body", attemptCount: 1 });

    expect(testDbStore.scheduledJobs.length).toBe(8);

    const runResult = await runDueScheduledJobs();

    expect(runResult.executedCount).toBe(8);
    expect(runResult.results.filter((r) => r.status === "completed").length).toBe(8);

    // Check that trackers received execution outputs
    expect(processedJobsTracker.prestigeRecalculated.length).toBe(1);
    expect(processedJobsTracker.titleIntegrityAudited.length).toBe(1);
    expect(processedJobsTracker.historicalRecalcs.length).toBe(1);
    expect(processedJobsTracker.auditScans.length).toBe(1);
    expect(processedJobsTracker.sanctionExpiries.length).toBe(1);
    expect(processedJobsTracker.messageCleanups.length).toBe(1);
    expect(processedJobsTracker.scheduledAnnouncements.length).toBe(1);
    expect(processedJobsTracker.pushRetries.length).toBe(1);

    // Check that recurring jobs were re-scheduled for future execution
    // 5 recurring jobs (PRESTIGE_RECALCULATION, TITLE_INTEGRITY_AUDIT, AUDIT_INTEGRITY_SCAN, SANCTION_EXPIRY, MESSAGE_CLEANUP, ANNOUNCEMENT_SCHEDULER = 6 recurring)
    const newPendingJobs = testDbStore.scheduledJobs.filter((j) => j.status === "pending");
    expect(newPendingJobs.length).toBeGreaterThanOrEqual(6);
  });

  it("should expose admin API route POST /admin/scheduled-jobs/run to invoke runDueScheduledJobs", async () => {
    const pastDate = new Date(Date.now() - 5000);
    await scheduleJob(SCHEDULED_JOB_TYPES.ANNOUNCEMENT_SCHEDULER, pastDate, { trigger: "admin" });

    const response = await supertest(app)
      .post("/admin/scheduled-jobs/run")
      .set("Authorization", `Bearer ${adminToken}`)
      .send();

    expect(response.status).toBe(200);
    expect(response.body.success).toBe(true);
    expect(response.body.data.executedCount).toBe(1);
  });

  it("should enforce X-Cron-Secret header on internal route POST /internal/scheduled-jobs/run", async () => {
    const pastDate = new Date(Date.now() - 5000);
    await scheduleJob(SCHEDULED_JOB_TYPES.ANNOUNCEMENT_SCHEDULER, pastDate, { trigger: "internal" });

    // 1. Unauthenticated / missing header -> 401
    const unauthRes = await supertest(app)
      .post("/internal/scheduled-jobs/run")
      .send();
    expect(unauthRes.status).toBe(401);

    // 2. Invalid secret -> 401
    const invalidRes = await supertest(app)
      .post("/internal/scheduled-jobs/run")
      .set("X-Cron-Secret", "wrong_secret")
      .send();
    expect(invalidRes.status).toBe(401);

    // 3. Valid X-Cron-Secret -> 200
    const validRes = await supertest(app)
      .post("/internal/scheduled-jobs/run")
      .set("X-Cron-Secret", env.CRON_SECRET)
      .send();

    expect(validRes.status).toBe(200);
    expect(validRes.body.success).toBe(true);
    expect(validRes.body.data.executedCount).toBe(1);
  });

  it("should recover stale jobs stuck in 'running' state back to 'pending'", async () => {
    const staleTime = new Date(Date.now() - 15 * 60 * 1000); // 15 minutes ago

    // Directly push a job stuck in running state with an old updatedAt
    testDbStore.scheduledJobs.push({
      id: "stale-job-uuid-1",
      jobType: SCHEDULED_JOB_TYPES.ANNOUNCEMENT_SCHEDULER,
      payload: { trigger: "stale" },
      status: "running",
      scheduledFor: staleTime,
      updatedAt: staleTime,
      createdAt: staleTime,
    });

    const recoveredCount = await recoverStaleScheduledJobs();
    expect(recoveredCount).toBe(1);

    const recoveredJob = testDbStore.scheduledJobs.find((j) => j.id === "stale-job-uuid-1");
    expect(recoveredJob?.status).toBe("pending");
    expect(recoveredJob?.lastError).toContain("recovered");
  });
});
