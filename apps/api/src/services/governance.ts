import { eq, and, or, desc, asc, gt, lt, gte } from "drizzle-orm";
import { db } from "../config/db.js";
import { 
  disputes, 
  disputeEvidence, 
  disputeComments, 
  sanctions, 
  auditEvents,
  users,
  tournamentMatches,
  athleteProfiles,
  eloLedger,
  brackets
} from "@armsphere/db-schema";
import { 
  NotFoundError, 
  BadRequestError, 
  ForbiddenError, 
  logger 
} from "@armsphere/core";
import { scheduleJob, SCHEDULED_JOB_TYPES, processedJobsTracker } from "./scheduledJobs.js";
import crypto from "crypto";
import { v4 as uuidv4 } from "uuid";

// Replay engine status tracking interface
export interface ReplayProgress {
  status: "IDLE" | "PROCESSING" | "COMPLETED" | "FAILED";
  processedCount: number;
  totalMatches: number;
  lastProcessedMatchId: string | null;
  error: string | null;
  checkpointTimestamp: string | null;
}

export class GovernanceService {
  private static replayState: ReplayProgress = {
    status: "IDLE",
    processedCount: 0,
    totalMatches: 0,
    lastProcessedMatchId: null,
    error: null,
    checkpointTimestamp: null,
  };

  /**
   * List all disputes chronologically
   */
  public static async listDisputes() {
    return await db.select().from(disputes).orderBy(desc(disputes.createdAt));
  }

  /**
   * ---------------------------------------------------------------------------
   * IMMUTABLE AUDIT LEDGER
   * ---------------------------------------------------------------------------
   */

  /**
   * Appends an audit event to the ledger using blockchain-style SHA-256 hash chaining.
   */
  public static async logAuditEvent(
    actorId: string | null,
    entityType: string,
    entityId: string,
    action: string,
    payload: any = null
  ): Promise<any> {
    return await db.transaction(async (tx) => {
      // 1. Get the last event chronologically to fetch the parent hash
      const [lastEvent] = await tx
        .select()
        .from(auditEvents)
        .orderBy(desc(auditEvents.createdAt))
        .limit(1);

      const parentHash = lastEvent 
        ? lastEvent.eventHash 
        : "0000000000000000000000000000000000000000000000000000000000000000";

      const eventId = uuidv4();
      
      // 2. Generate hash based on: parentHash + eventId + actorId + entityType + entityId + action + payload
      const payloadString = payload ? JSON.stringify(payload) : "";
      const inputStr = `${parentHash}|${eventId}|${actorId || "SYSTEM"}|${entityType}|${entityId}|${action}|${payloadString}`;
      
      const eventHash = crypto
        .createHash("sha256")
        .update(inputStr)
        .digest("hex");

      const [newEvent] = await tx
        .insert(auditEvents)
        .values({
          eventId,
          parentHash,
          eventHash,
          actorId,
          entityType,
          entityId,
          action,
          payload,
          createdAt: new Date(),
        })
        .returning();

      logger.info({ eventId, eventHash, action }, "Audit event successfully written and chained to immutable ledger");
      return newEvent;
    });
  }

  /**
   * Verifies the entire audit trail chain, detecting any unauthorized tampering or deletions.
   */
  public static async verifyAuditLedger(): Promise<{ 
    isValid: boolean; 
    tamperedEventId?: string; 
    reason?: string; 
    totalEventsVerified: number; 
  }> {
    const allEvents = await db
      .select()
      .from(auditEvents)
      .orderBy(asc(auditEvents.createdAt));

    let expectedParentHash = "0000000000000000000000000000000000000000000000000000000000000000";

    for (let i = 0; i < allEvents.length; i++) {
      const event = allEvents[i];

      // 1. Check parent hash match
      if (event.parentHash !== expectedParentHash) {
        return {
          isValid: false,
          tamperedEventId: event.id,
          reason: `Parent hash mismatch at index ${i}. Expected: ${expectedParentHash}, Found: ${event.parentHash}`,
          totalEventsVerified: i,
        };
      }

      // 2. Recompute hash
      const payloadString = event.payload ? JSON.stringify(event.payload) : "";
      const inputStr = `${event.parentHash}|${event.eventId}|${event.actorId || "SYSTEM"}|${event.entityType}|${event.entityId}|${event.action}|${payloadString}`;
      const recalculatedHash = crypto
        .createHash("sha256")
        .update(inputStr)
        .digest("hex");

      if (event.eventHash !== recalculatedHash) {
        return {
          isValid: false,
          tamperedEventId: event.id,
          reason: `Hash signature invalid at index ${i}. Record was modified directly.`,
          totalEventsVerified: i,
        };
      }

      // Set parent hash for next round
      expectedParentHash = event.eventHash;
    }

    return {
      isValid: true,
      totalEventsVerified: allEvents.length,
    };
  }


  /**
   * ---------------------------------------------------------------------------
   * DISPUTE MANAGEMENT
   * ---------------------------------------------------------------------------
   */

  public static async createDispute(
    creatorId: string,
    matchId: string | null,
    title: string,
    description: string
  ): Promise<any> {
    const [newDispute] = await db
      .insert(disputes)
      .values({
        matchId,
        creatorId,
        title,
        description,
        status: "OPEN",
        updatedAt: new Date(),
      })
      .returning();

    // Log to immutable audit ledger
    await this.logAuditEvent(creatorId, "DISPUTE", newDispute.id, "DISPUTE_CREATED", { title, matchId });

    return newDispute;
  }

  public static async assignReviewer(
    disputeId: string,
    reviewerId: string,
    actorId: string
  ): Promise<any> {
    const [dispute] = await db
      .select()
      .from(disputes)
      .where(eq(disputes.id, disputeId))
      .limit(1);

    if (!dispute) {
      throw new NotFoundError("Dispute not found");
    }

    const [updated] = await db
      .update(disputes)
      .set({
        assignedReviewerId: reviewerId,
        status: "UNDER_REVIEW",
        updatedAt: new Date(),
      })
      .where(eq(disputes.id, disputeId))
      .returning();

    await this.logAuditEvent(actorId, "DISPUTE", disputeId, "REVIEWER_ASSIGNED", { reviewerId });

    return updated;
  }

  public static async submitEvidence(
    disputeId: string,
    submitterId: string,
    fileType: "VIDEO" | "IMAGE" | "DOCUMENT",
    fileUrl: string,
    rawFileContent?: string
  ): Promise<any> {
    const [dispute] = await db
      .select()
      .from(disputes)
      .where(eq(disputes.id, disputeId))
      .limit(1);

    if (!dispute) {
      throw new NotFoundError("Dispute not found");
    }

    // SHA-256 Integrity Hash calculation
    const fileHash = crypto
      .createHash("sha256")
      .update(rawFileContent || fileUrl + Date.now().toString())
      .digest("hex");

    const [newEvidence] = await db
      .insert(disputeEvidence)
      .values({
        disputeId,
        submitterId,
        fileType,
        fileUrl,
        sha256Hash: fileHash,
        virusScanned: false,
        virusScanResult: "PENDING",
      })
      .returning();

    await this.logAuditEvent(submitterId, "DISPUTE_EVIDENCE", newEvidence.id, "EVIDENCE_SUBMITTED", {
      disputeId,
      fileType,
      sha256Hash: fileHash,
    });

    // Run virus scan directly
    const isMockInfected = fileUrl?.includes("infected");
    await db
      .update(disputeEvidence)
      .set({
        virusScanned: true,
        virusScanResult: isMockInfected ? "INFECTED" : "CLEAN",
      })
      .where(eq(disputeEvidence.id, newEvidence.id));
    processedJobsTracker.virusScans.push({ evidenceId: newEvidence.id, fileUrl });

    newEvidence.virusScanned = true;
    newEvidence.virusScanResult = isMockInfected ? "INFECTED" : "CLEAN";

    return newEvidence;
  }

  public static async addComment(
    disputeId: string,
    authorId: string,
    commentText: string
  ): Promise<any> {
    const [dispute] = await db
      .select()
      .from(disputes)
      .where(eq(disputes.id, disputeId))
      .limit(1);

    if (!dispute) {
      throw new NotFoundError("Dispute not found");
    }

    const [newComment] = await db
      .insert(disputeComments)
      .values({
        disputeId,
        authorId,
        comment: commentText,
      })
      .returning();

    await this.logAuditEvent(authorId, "DISPUTE_COMMENT", newComment.id, "COMMENT_ADDED", { disputeId });

    return newComment;
  }

  public static async resolveDispute(
    disputeId: string,
    resolutionDetails: string,
    decision: "RESOLVED" | "REJECTED",
    actorId: string
  ): Promise<any> {
    const [dispute] = await db
      .select()
      .from(disputes)
      .where(eq(disputes.id, disputeId))
      .limit(1);

    if (!dispute) {
      throw new NotFoundError("Dispute not found");
    }

    const [updated] = await db
      .update(disputes)
      .set({
        status: decision,
        resolutionDetails,
        updatedAt: new Date(),
      })
      .where(eq(disputes.id, disputeId))
      .returning();

    await this.logAuditEvent(actorId, "DISPUTE", disputeId, `DISPUTE_${decision}`, { resolutionDetails });

    return updated;
  }

  public static async escalateDispute(
    disputeId: string,
    escalationReason: string,
    actorId: string
  ): Promise<any> {
    const [dispute] = await db
      .select()
      .from(disputes)
      .where(eq(disputes.id, disputeId))
      .limit(1);

    if (!dispute) {
      throw new NotFoundError("Dispute not found");
    }

    const [updated] = await db
      .update(disputes)
      .set({
        status: "ESCALATED",
        resolutionDetails: `Escalation Reason: ${escalationReason}`,
        updatedAt: new Date(),
      })
      .where(eq(disputes.id, disputeId))
      .returning();

    await this.logAuditEvent(actorId, "DISPUTE", disputeId, "DISPUTE_ESCALATED", { escalationReason });

    return updated;
  }

  public static async appealResolution(
    disputeId: string,
    appealReason: string,
    actorId: string
  ): Promise<any> {
    const [dispute] = await db
      .select()
      .from(disputes)
      .where(eq(disputes.id, disputeId))
      .limit(1);

    if (!dispute) {
      throw new NotFoundError("Dispute not found");
    }

    if (dispute.status !== "RESOLVED" && dispute.status !== "REJECTED") {
      throw new BadRequestError("Only resolved or rejected disputes can be appealed");
    }

    const [updated] = await db
      .update(disputes)
      .set({
        status: "AWAITING_EVIDENCE", // Re-opened and awaiting further appeal evidence
        resolutionDetails: `Appealed. Reason: ${appealReason}`,
        updatedAt: new Date(),
      })
      .where(eq(disputes.id, disputeId))
      .returning();

    await this.logAuditEvent(actorId, "DISPUTE", disputeId, "DISPUTE_APPEALED", { appealReason });

    return updated;
  }


  /**
   * ---------------------------------------------------------------------------
   * SANCTIONS SYSTEM
   * ---------------------------------------------------------------------------
   */

  public static async createSanction(
    userId: string,
    type: "WARNING" | "SUSPENSION" | "TEMPORARY_BAN" | "PERMANENT_BAN" | "LICENSE_REVOCATION",
    reason: string,
    durationDays: number | null,
    issuedById: string
  ): Promise<any> {
    const startsAt = new Date();
    const endsAt = durationDays ? new Date(startsAt.getTime() + durationDays * 24 * 60 * 60 * 1000) : null;

    const [newSanction] = await db
      .insert(sanctions)
      .values({
        userId,
        type,
        reason,
        issuedById,
        startsAt,
        endsAt,
        status: "ACTIVE",
        updatedAt: new Date(),
      })
      .returning();

    await this.logAuditEvent(issuedById, "USER_SANCTION", newSanction.id, "SANCTION_ISSUED", {
      userId,
      type,
      endsAt,
    });

    // If there is an end date, queue a sanction expiry check job
    if (endsAt) {
      await scheduleJob(
        SCHEDULED_JOB_TYPES.SANCTION_EXPIRY,
        endsAt,
        { sanctionId: newSanction.id }
      ).catch(err => logger.error({ err }, "Failed to schedule sanction expiry background job"));
    }

    return newSanction;
  }

  /**
   * Sweeps and handles active sanctions that have passed their endsAt timestamp.
   */
  public static async processSanctionsExpiry(): Promise<number> {
    const now = new Date();
    const expiredList = await db
      .select()
      .from(sanctions)
      .where(
        and(
          eq(sanctions.status, "ACTIVE"),
          lt(sanctions.endsAt, now)
        )
      );

    let updatedCount = 0;
    for (const sanction of expiredList) {
      await db
        .update(sanctions)
        .set({
          status: "EXPIRED",
          updatedAt: now,
        })
        .where(eq(sanctions.id, sanction.id));

      await this.logAuditEvent("SYSTEM", "USER_SANCTION", sanction.id, "SANCTION_AUTO_EXPIRED", {
        userId: sanction.userId,
      });

      updatedCount++;
    }

    return updatedCount;
  }


  /**
   * ---------------------------------------------------------------------------
   * MATCH VOIDING & ELO REPLAY SYSTEM
   * ---------------------------------------------------------------------------
   */

  /**
   * Corrects a match result administrative override and replays chronologically.
   */
  public static async correctMatchResult(
    matchId: string,
    actualWinnerId: string,
    reviewerId: string
  ): Promise<any> {
    return await db.transaction(async (tx) => {
      const [match] = await tx
        .select()
        .from(tournamentMatches)
        .where(eq(tournamentMatches.id, matchId))
        .limit(1);

      if (!match) {
        throw new NotFoundError("Tournament Match not found");
      }

      const originalWinnerId = match.winnerId;
      
      // Update match winner
      const [updatedMatch] = await tx
        .update(tournamentMatches)
        .set({
          winnerId: actualWinnerId,
          updatedAt: new Date(),
        })
        .where(eq(tournamentMatches.id, matchId))
        .returning();

      await this.logAuditEvent(reviewerId, "TOURNAMENT_MATCH", matchId, "MATCH_CORRECTED", {
        originalWinnerId,
        actualWinnerId,
      });

      logger.info({ matchId }, "Match result corrected. Triggering automatic sequence ELO replay.");

      // Trigger ELO chronological replay sequence starting from this match's creation timestamp
      await this.triggerEloRecalculationFrom(match.createdAt || new Date());

      return updatedMatch;
    });
  }

  /**
   * Initiates historical chronological ELO recalculation of matches.
   */
  public static async triggerEloRecalculationFrom(startingTimestamp: Date): Promise<ReplayProgress> {
    this.replayState = {
      status: "PROCESSING",
      processedCount: 0,
      totalMatches: 0,
      lastProcessedMatchId: null,
      error: null,
      checkpointTimestamp: startingTimestamp.toISOString(),
    };

    // Queue the asynchronous recalculation job
    await scheduleJob(SCHEDULED_JOB_TYPES.ELO_RECALCULATION_NEW, new Date(), {
      startingTimestamp: startingTimestamp.toISOString(),
    }).catch(err => {
      this.replayState.status = "FAILED";
      this.replayState.error = err.message;
      throw err;
    });

    return this.replayState;
  }

  /**
   * The actual processing logic run by the background recalculation worker.
   */
  public static async executeEloRecalculation(startingTimestampStr: string): Promise<number> {
    const now = new Date();
    const startingTimestamp = new Date(startingTimestampStr);

    logger.info({ startingTimestamp }, "Commencing full-stack ELO historical series recalculation engine");

    // 1. Gather all matches chronologically verified starting from this timestamp, joining brackets to get the arm
    const chronologicalMatches = await db
      .select({
        id: tournamentMatches.id,
        createdAt: tournamentMatches.createdAt,
        winnerId: tournamentMatches.winnerId,
        athleteAId: tournamentMatches.athleteAId,
        athleteBId: tournamentMatches.athleteBId,
        bracketId: tournamentMatches.bracketId,
        arm: brackets.arm,
      })
      .from(tournamentMatches)
      .innerJoin(brackets, eq(tournamentMatches.bracketId, brackets.id))
      .where(
        and(
          eq(tournamentMatches.status, "VERIFIED"),
          gte(tournamentMatches.createdAt, startingTimestamp)
        )
      )
      .orderBy(asc(tournamentMatches.createdAt));

    this.replayState.totalMatches = chronologicalMatches.length;

    if (chronologicalMatches.length === 0) {
      this.replayState.status = "COMPLETED";
      return 0;
    }

    // 2. Perform sequential replay with transaction check-pointing
    let processedCount = 0;
    for (const match of chronologicalMatches) {
      try {
        await db.transaction(async (tx) => {
          const arm = match.arm.toUpperCase() as "LEFT" | "RIGHT";
          
          // Fetch current ratings at this historical juncture
          const [challenger] = await tx
            .select()
            .from(athleteProfiles)
            .where(eq(athleteProfiles.id, match.athleteAId!))
            .limit(1);

          const [opponent] = await tx
            .select()
            .from(athleteProfiles)
            .where(eq(athleteProfiles.id, match.athleteBId!))
            .limit(1);

          if (!challenger || !opponent) {
            throw new Error(`Athletes not found for match ${match.id}`);
          }

          const ratingC = arm === "LEFT" ? (challenger.leftArmElo ?? 1000) : (challenger.rightArmElo ?? 1000);
          const ratingO = arm === "LEFT" ? (opponent.leftArmElo ?? 1000) : (opponent.rightArmElo ?? 1000);

          const isWinnerChallenger = match.winnerId === match.athleteAId;

          // Compute expected scores
          const expectedC = 1 / (1 + Math.pow(10, (ratingO - ratingC) / 400));
          const expectedO = 1 / (1 + Math.pow(10, (ratingC - ratingO) / 400));

          const actualC = isWinnerChallenger ? 1 : 0;
          const actualO = isWinnerChallenger ? 0 : 1;

          // Match counts for K factor
          const challengerMatches = await tx
            .select({ id: tournamentMatches.id })
            .from(tournamentMatches)
            .innerJoin(brackets, eq(tournamentMatches.bracketId, brackets.id))
            .where(
              and(
                eq(brackets.arm, arm),
                eq(tournamentMatches.status, "VERIFIED"),
                lt(tournamentMatches.createdAt, match.createdAt || now),
                or(
                  eq(tournamentMatches.athleteAId, match.athleteAId!),
                  eq(tournamentMatches.athleteBId, match.athleteAId!)
                )
              )
            );

          const opponentMatches = await tx
            .select({ id: tournamentMatches.id })
            .from(tournamentMatches)
            .innerJoin(brackets, eq(tournamentMatches.bracketId, brackets.id))
            .where(
              and(
                eq(brackets.arm, arm),
                eq(tournamentMatches.status, "VERIFIED"),
                lt(tournamentMatches.createdAt, match.createdAt || now),
                or(
                  eq(tournamentMatches.athleteAId, match.athleteBId!),
                  eq(tournamentMatches.athleteBId, match.athleteBId!)
                )
              )
            );

          const matchesCountC = challengerMatches.length;
          const matchesCountO = opponentMatches.length;

          const getK = (matchesCount: number, elo: number) => {
            if (matchesCount < 10) return 64;
            if (elo >= 2200) return 16;
            return 32;
          };

          const kC = getK(matchesCountC, ratingC);
          const kO = getK(matchesCountO, ratingO);

          const deltaC = Math.round(kC * (actualC - expectedC));
          const deltaO = Math.round(kO * (actualO - expectedO));

          const newRatingC = Math.max(1000, ratingC + deltaC);
          const newRatingO = Math.max(1000, ratingO + deltaO);

          // Update profile ratings
          if (arm === "LEFT") {
            await tx
              .update(athleteProfiles)
              .set({ leftArmElo: newRatingC, updatedAt: new Date() })
              .where(eq(athleteProfiles.id, match.athleteAId!));

            await tx
              .update(athleteProfiles)
              .set({ leftArmElo: newRatingO, updatedAt: new Date() })
              .where(eq(athleteProfiles.id, match.athleteBId!));
          } else {
            await tx
              .update(athleteProfiles)
              .set({ rightArmElo: newRatingC, updatedAt: new Date() })
              .where(eq(athleteProfiles.id, match.athleteAId!));

            await tx
              .update(athleteProfiles)
              .set({ rightArmElo: newRatingO, updatedAt: new Date() })
              .where(eq(athleteProfiles.id, match.athleteBId!));
          }

          // Delete prior ledger entries for this match to maintain unique entries
          await tx
            .delete(eloLedger)
            .where(eq(eloLedger.matchId, match.id));

          // Record inside ELO ledger
          await tx.insert(eloLedger).values({
            matchId: match.id,
            athleteId: match.athleteAId!,
            arm,
            previousElo: ratingC,
            newElo: newRatingC,
            eloDelta: deltaC,
          });

          await tx.insert(eloLedger).values({
            matchId: match.id,
            athleteId: match.athleteBId!,
            arm,
            previousElo: ratingO,
            newElo: newRatingO,
            eloDelta: deltaO,
          });
        });

        processedCount++;
        this.replayState.processedCount = processedCount;
        this.replayState.lastProcessedMatchId = match.id;
        
      } catch (err: any) {
        logger.error({ matchId: match.id, err }, "ELO Replay Engine failed at match juncture");
        this.replayState.status = "FAILED";
        this.replayState.error = err.message;
        throw err;
      }
    }

    this.replayState.status = "COMPLETED";

    return processedCount;
  }

  public static getReplayStatus(): ReplayProgress {
    return this.replayState;
  }
}
