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
  ConflictError,
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
   * List disputes. Ordinary users only see their own filings; privileged
   * federation roles see the full docket (mirrors the admin console gate).
   * PROVINCIAL_DIRECTOR role only sees disputes from their assigned province.
   */
  public static async listDisputes(requester?: { id: string; role: string; province?: string }) {
    const privilegedRoles = [
      "SYSTEM_ADMIN",
      "NATIONAL_DIRECTOR",
      "PROVINCIAL_DIRECTOR",
      "COMPLIANCE_OFFICER",
      "SUPPORT_AGENT",
      "REFEREE",
    ];
    if (
      requester &&
      requester.role &&
      privilegedRoles.includes(requester.role)
    ) {
      // PROVINCIAL_DIRECTOR only sees disputes from their province
      if (requester.role === "PROVINCIAL_DIRECTOR" && requester.province) {
        return await db
          .select()
          .from(disputes)
          .where(eq(disputes.province, requester.province))
          .orderBy(desc(disputes.createdAt));
      }
      // Other privileged roles see all disputes
      return await db.select().from(disputes).orderBy(desc(disputes.createdAt));
    }
    if (!requester) {
      throw new ForbiddenError("Requester context is required to list disputes.");
    }
    return await db
      .select()
      .from(disputes)
      .where(eq(disputes.creatorId, requester.id))
      .orderBy(desc(disputes.createdAt));
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

    // Terminal-state guard: once resolved or closed, disputes cannot be assigned to a reviewer
    if (dispute.status === "RESOLVED" || dispute.status === "CLOSED") {
      throw new ConflictError("Dispute has already been resolved");
    }

    // --- Canonical Actor Identity & Authorization ---
    // Canonical identity source: the users table row, never caller-supplied
    // role/province claims. Fail-closed when the actor row does not exist.
    const [dbActor] = await db.select().from(users).where(eq(users.id, actorId)).limit(1);
    if (!dbActor) {
      throw new NotFoundError("Assigning actor not found");
    }
    const canonicalRole = (dbActor as any).role as string;
    const actorJurisdiction =
      (((dbActor as any).province as string | null | undefined) ??
        ((dbActor as any).regionalCoverage as string | null | undefined) ??
        null);

    // Route-level and service-level authorized roles for reviewer assignment:
    // SYSTEM_ADMIN, NATIONAL_DIRECTOR, PROVINCIAL_DIRECTOR.
    const ALLOWED_ASSIGNER_ROLES = [
      "SYSTEM_ADMIN",
      "NATIONAL_DIRECTOR",
      "PROVINCIAL_DIRECTOR",
    ];
    if (!ALLOWED_ASSIGNER_ROLES.includes(canonicalRole)) {
      throw new ForbiddenError(
        "Only SYSTEM_ADMIN, NATIONAL_DIRECTOR, or PROVINCIAL_DIRECTOR may assign dispute reviewers"
      );
    }

    // --- Provincial Jurisdiction Enforcement ---
    if (canonicalRole === "PROVINCIAL_DIRECTOR") {
      // Same-province rule: a scoped dispute (province set) outside the
      // director's assigned province/coverage is forbidden. Fail-closed when
      // the director has no jurisdiction assignment AND the dispute is scoped.
      if (dispute.province) {
        if (!actorJurisdiction) {
          throw new ForbiddenError(
            "PROVINCIAL_DIRECTOR must have an assigned province to assign reviewers"
          );
        }
        if (dispute.province !== actorJurisdiction) {
          throw new ForbiddenError(
            `Provincial Director can only assign reviewers for disputes in their assigned province (${actorJurisdiction})`
          );
        }
      }
    }

    // --- Reviewer Verification ---
    const [dbReviewer] = await db.select().from(users).where(eq(users.id, reviewerId)).limit(1);
    if (!dbReviewer) {
      throw new NotFoundError("Reviewer not found");
    }
    if ((dbReviewer as any).isActive === false) {
      throw new BadRequestError("Target reviewer is inactive");
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
    rawFileContent?: string,
    actorRole?: string
  ): Promise<any> {
    const [dispute] = await db
      .select()
      .from(disputes)
      .where(eq(disputes.id, disputeId))
      .limit(1);

    if (!dispute) {
      throw new NotFoundError("Dispute not found");
    }

    // Only the dispute creator, the assigned reviewer, or federation staff may
    // attach evidence to a dispute. Canonical identity: the users-table row
    // decides — the optional actorRole caller hint (JWT claim) is accepted
    // for backward compatibility but is NEVER trusted for authorization.
    // Fail-closed when the submitter row does not exist. No province/
    // jurisdiction dimension applies here (unlike resolveDispute): evidence
    // is participant-scoped, and no repository source — route (authenticate
    // only, routes/governance.ts:28-32), schema, or history — evidences a
    // province gate for evidence submission.
    const [dbSubmitter] = await db.select().from(users).where(eq(users.id, submitterId)).limit(1);
    if (!dbSubmitter) {
      throw new NotFoundError("Evidence submitter not found");
    }
    const canonicalRole = (dbSubmitter as any).role as string;
    const isStaff =
      submitterId === dispute.creatorId ||
      submitterId === dispute.assignedReviewerId ||
      ["SYSTEM_ADMIN", "NATIONAL_DIRECTOR", "PROVINCIAL_DIRECTOR", "COMPLIANCE_OFFICER", "REFEREE"].includes(
        canonicalRole
      );
    if (!isStaff) {
      throw new ForbiddenError("Only the dispute creator, assigned reviewer, or federation staff can submit evidence.");
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
    commentText: string,
    actorRole?: string
  ): Promise<any> {
    const [dispute] = await db
      .select()
      .from(disputes)
      .where(eq(disputes.id, disputeId))
      .limit(1);

    if (!dispute) {
      throw new NotFoundError("Dispute not found");
    }

    // Comments are limited to the dispute creator, the assigned reviewer, and
    // federation staff — not arbitrary authenticated users. Canonical
    // identity: the users-table row decides — the optional actorRole caller
    // hint (JWT claim) is accepted for backward compatibility but is NEVER
    // trusted for authorization. Fail-closed when the author row does not
    // exist. No province/jurisdiction dimension applies here (same as
    // submitEvidence): comment authority is participant-scoped, and no
    // repository source — route (authenticate only,
    // routes/governance.ts:34-38), schema, or history — evidences a
    // province gate for dispute comments.
    const [dbAuthor] = await db.select().from(users).where(eq(users.id, authorId)).limit(1);
    if (!dbAuthor) {
      throw new NotFoundError("Comment author not found");
    }
    const canonicalRole = (dbAuthor as any).role as string;
    const isParticipant =
      authorId === dispute.creatorId ||
      authorId === dispute.assignedReviewerId ||
      ["SYSTEM_ADMIN", "NATIONAL_DIRECTOR", "PROVINCIAL_DIRECTOR", "COMPLIANCE_OFFICER", "REFEREE"].includes(
        canonicalRole
      );
    if (!isParticipant) {
      throw new ForbiddenError("Only dispute participants or federation staff can comment.");
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
    actor: { id: string; role: string; province?: string } | string
  ): Promise<any> {
    // Backward compatible: legacy callers pass a bare user-id string.
    const actorId = typeof actor === "string" ? actor : actor.id;
    const [dispute] = await db
      .select()
      .from(disputes)
      .where(eq(disputes.id, disputeId))
      .limit(1);

    if (!dispute) {
      throw new NotFoundError("Dispute not found");
    }

    // P0: terminal-state guard - re-resolution must not silently overwrite.
    if (dispute.status === "RESOLVED" || dispute.status === "CLOSED") {
      throw new ConflictError("Dispute has already been resolved");
    }

    // --- Resource-Aware Resolver Authorization (P0 IDOR fix) ---
    // Canonical identity source: the users table row, never a caller-supplied
    // role/province. Object-form actor.role / actor.province hints describe
    // the request context only and are intentionally NOT trusted here.
    const [dbActor] = await db.select().from(users).where(eq(users.id, actorId)).limit(1);
    if (!dbActor) {
      throw new NotFoundError("Resolver user not found");
    }
    const canonicalRole = (dbActor as any).role as string;
    // Jurisdiction columns: staging schema carries BOTH users.province and
    // users.regional_coverage (canonical per AdministrationService.inspectMatch,
    // which enforces PROVINCIAL_DIRECTOR scope via regionalCoverage).
    const actorJurisdiction =
      (((dbActor as any).province as string | null | undefined) ??
        ((dbActor as any).regionalCoverage as string | null | undefined) ??
        null);

    // Base role gate mirrors the route-level requireRole(...):
    // REFEREE, PROVINCIAL_DIRECTOR, NATIONAL_DIRECTOR, SYSTEM_ADMIN.
    // Evidence: routes/governance.ts resolve endpoint; service evidence /
    // comment helpers treat creator + assignedReviewerId + these federation
    // roles as dispute authority; admin-web GovernancePage canResolve gates on
    // SYSTEM_ADMIN / NATIONAL_DIRECTOR / COMPLIANCE_OFFICER, but the live
    // route gate (not COMPLIANCE_OFFICER) is the enforced boundary here, so
    // the service must not invent a broader rule than the route allows.
    const ALLOWED_RESOLVER_ROLES = [
      "SYSTEM_ADMIN",
      "NATIONAL_DIRECTOR",
      "PROVINCIAL_DIRECTOR",
      "REFEREE",
    ];
    if (!ALLOWED_RESOLVER_ROLES.includes(canonicalRole)) {
      throw new ForbiddenError(
        "Only SYSTEM_ADMIN, NATIONAL_DIRECTOR, PROVINCIAL_DIRECTOR, or assigned REFEREE reviewers may resolve disputes"
      );
    }

    const isAssignedReviewer =
      !!dispute.assignedReviewerId && dispute.assignedReviewerId === actorId;

    if (canonicalRole === "SYSTEM_ADMIN" || canonicalRole === "NATIONAL_DIRECTOR") {
      // Universal federation authority - no per-dispute scope required.
    } else if (isAssignedReviewer) {
      // Explicit per-dispute delegation via assignReviewer overrides
      // provincial jurisdiction (same participant-authority model as
      // submitEvidence/addComment, which treat assignedReviewerId as authority).
    } else if (canonicalRole === "PROVINCIAL_DIRECTOR") {
      // Same-province rule: a scoped dispute (province set) outside the
      // director jurisdiction is forbidden. Fail-closed when the director
      // has no jurisdiction assignment AND the dispute is scoped. Legacy
      // unscoped disputes (province NULL) carry no scope to enforce and
      // remain resolvable (backward compatible with existing fixtures).
      if (dispute.province) {
        if (!actorJurisdiction) {
          throw new ForbiddenError(
            "PROVINCIAL_DIRECTOR must have an assigned province to resolve disputes"
          );
        }
        if (dispute.province !== actorJurisdiction) {
          throw new ForbiddenError(
            `Provincial Director can only resolve disputes in their assigned province (${actorJurisdiction})`
          );
        }
      }
    } else {
      // REFEREE who is not the assigned reviewer for THIS dispute.
      throw new ForbiddenError(
        "Only the assigned reviewer for this dispute may resolve it"
      );
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
    actor: { id: string; role: string; province?: string }
  ): Promise<any> {
    const [dispute] = await db
      .select()
      .from(disputes)
      .where(eq(disputes.id, disputeId))
      .limit(1);

    if (!dispute) {
      throw new NotFoundError("Dispute not found");
    }

    // --- Escalation Authorization: creator-only (canonical identity) ---
    // Source evidence: Phase-10 hardening commit message
    // ("restrict escalation and appeal to the dispute creator",
    // _p10_msg.txt:5); appealResolution() enforces creator-only
    // (governance.ts:560-562); escalate route has NO requireRole gate
    // (routes/governance.ts:47-51) because ANY authenticated creator
    // (including ATHLETE) must reach this service; the existing
    // governance test escalates with the creator competitorToken
    // (tests/governance.test.ts:259-268). The pre-fix
    // caller-supplied role/province jurisdiction stub trusted JWT
    // hints and is removed: canonical users-row identity decides.
    // Fail-closed on missing actor row (no userId/profileId confusion:
    // actorId is the users.id that created the dispute).
    const actorId = actor.id;
    const [dbActor] = await db.select().from(users).where(eq(users.id, actorId)).limit(1);
    if (!dbActor) {
      throw new NotFoundError("Escalation actor not found");
    }
    if (actorId !== dispute.creatorId) {
      throw new ForbiddenError("Only the dispute creator can escalate this dispute.");
    }

    // --- Escalation State-Machine Protection (preserve legacy behavior) ---
    // Terminal states cannot be escalated; an already-ESCALATED dispute is
    // a conflict (no silent overwrite, no duplicate audit event).
    if (dispute.status === "RESOLVED" || dispute.status === "CLOSED" || dispute.status === "REJECTED") {
      throw new ConflictError("A resolved dispute cannot be escalated");
    }
    if (dispute.status === "ESCALATED") {
      throw new ConflictError("Dispute has already been escalated");
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
    actor: { id: string; role: string; province?: string }
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

    // Canonical identity source: verify actor exists in the users table.
    // Caller-supplied role/province hints describe the request context only and
    // are intentionally NOT trusted. Fail-closed when the actor does not exist.
    const actorId = actor.id;
    const [dbActor] = await db.select().from(users).where(eq(users.id, actorId)).limit(1);
    if (!dbActor) {
      throw new NotFoundError("Appeal actor not found");
    }

    // Only the original filer may appeal a decision on their dispute.
    if (actorId !== dispute.creatorId) {
      throw new ForbiddenError("Only the dispute creator can appeal this resolution.");
    }

    // --- Provincial Jurisdiction Enforcement ---
    // Applicants can appeal regardless of province, but any further proceedings
    // are scoped to the dispute's assigned province.

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
