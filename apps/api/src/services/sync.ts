import { eq, and, or, gt } from "drizzle-orm";
import { db } from "../config/db.js";
import { pendingActions, auditLogs, users, athleteProfiles, matches, syncTombstones } from "@armsphere/db-schema";
import { SyncStatus } from "@armsphere/types";
import { ConflictError, BadRequestError, NotFoundError, logger } from "@armsphere/core";
import { processedJobsTracker } from "./scheduledJobs.js";

export class SyncService {
  /**
   * Registers a new pending offline action for replay orchestration.
   * Leverages idempotency key to prevent replay attacks and duplicate submissions.
   */
  static async queueAction(
    userId: string,
    idempotencyKey: string,
    actionType: string,
    payload: any,
    context?: { ipAddress?: string; userAgent?: string }
  ) {
    // 1. Idempotency & Replay Protection Check
    const [existing] = await db
      .select()
      .from(pendingActions)
      .where(eq(pendingActions.idempotencyKey, idempotencyKey))
      .limit(1);

    if (existing) {
      logger.warn(
        { idempotencyKey, actionType, userId },
        "Deduplicated registration: Action carrying this idempotency key is already registered."
      );
      // Return existing action result safely to client
      return existing;
    }

    // 2. Insert PENDING action
    const [newAction] = await db
      .insert(pendingActions)
      .values({
        userId,
        idempotencyKey,
        actionType,
        payload,
        status: SyncStatus.PENDING,
      })
      .returning();

    // 3. Log submission audit
    await db.insert(auditLogs).values({
      userId,
      action: "OFFLINE_SYNC_QUEUE",
      details: { actionId: newAction.id, actionType, idempotencyKey },
      ipAddress: context?.ipAddress,
      userAgent: context?.userAgent,
    });

    // 4. Process pending action directly
    const result = await SyncService.processActionById(newAction.id);
    processedJobsTracker.offlineSyncCompleted.push({ pendingActionId: newAction.id, result });

    return newAction;
  }

  /**
   * Processes a single queued offline pending action.
   * Includes conflict detection hook and WebSocket status notification.
   */
  static async processActionById(actionId: string): Promise<any> {
    const [action] = await db
      .select()
      .from(pendingActions)
      .where(eq(pendingActions.id, actionId))
      .limit(1);

    if (!action) {
      throw new NotFoundError("Queued offline action record was not found.");
    }

    // Guard: ignore if already processed
    if (action.status === SyncStatus.COMPLETED) {
      return { status: "ALREADY_COMPLETED" };
    }

    logger.info({ actionId, actionType: action.actionType }, "Executing offline action processing");

    // Mark as PROCESSING in DB
    await db
      .update(pendingActions)
      .set({ status: SyncStatus.PROCESSING, updatedAt: new Date() })
      .where(eq(pendingActions.id, actionId));

    try {
      // Run action business handler (conflict detection / hooks)
      const executionResult = await this.executeBusinessLogic(action);

      // Mark as COMPLETED in DB
      await db
        .update(pendingActions)
        .set({ status: SyncStatus.COMPLETED, updatedAt: new Date() })
        .where(eq(pendingActions.id, actionId));

      return executionResult;
    } catch (error: any) {
      logger.error({ actionId, error: error.message }, "Offline action replay execution failed.");

      // Mark as FAILED in DB with detailed error payload
      await db
        .update(pendingActions)
        .set({
          status: SyncStatus.FAILED,
          errorReason: error.message || "Unknown error occurred.",
          updatedAt: new Date(),
        })
        .where(eq(pendingActions.id, actionId));

      throw error;
    }
  }

  /**
   * Evaluates the specific action types, validating data constraints and checking state versioning.
   */
  private static async executeBusinessLogic(action: any): Promise<any> {
    const { actionType, payload, userId } = action;

    switch (actionType) {
      case "SUBMIT_MATCH": {
        // E.g., Referees uploading offline match data.
        // Mocking a match business insertion logic:
        logger.info({ payload }, "Persisting synchronized match data from offline queue");
        return { matchId: payload.matchId, outcome: "MATCH_SAVED" };
      }

      case "UPDATE_PROFILE": {
        // Athletes synchronizing offline profile edits.
        // CONFLICT DETECTION check:
        // Compare request modified date with current user record updated timestamp in db.
        const [userRecord] = await db
          .select()
          .from(users)
          .where(eq(users.id, userId))
          .limit(1);

        if (!userRecord) {
          throw new NotFoundError("Profile user context is missing.");
        }

        const clientLastUpdated = payload.clientLastUpdated ? new Date(payload.clientLastUpdated) : null;
        
        // If server profile record is newer than the client offline modification date, a merge conflict has occurred!
        if (clientLastUpdated && userRecord.updatedAt && userRecord.updatedAt > clientLastUpdated) {
          logger.warn(
            { userId, serverUpdated: userRecord.updatedAt, clientUpdated: clientLastUpdated },
            "Synchronization Conflict: Server contains a newer profile update. Conflict resolution triggered!"
          );
          throw new ConflictError(
            "Conflict detected: The server contains a newer profile revision. Please resolve local state."
          );
        }

        // Apply profile update
        await db
          .update(users)
          .set({
            fullName: payload.fullName || userRecord.fullName,
            updatedAt: new Date(),
          })
          .where(eq(users.id, userId));

        return { userId, fullName: payload.fullName, status: "PROFILE_SYNCED" };
      }

      default:
        throw new BadRequestError(`Unsupported offline sync action type: [${actionType}]`);
    }
  }

  /**
   * Gets list of offline sync logs for this user
   */
  static async getActionsHistory(userId: string) {
    return db
      .select()
      .from(pendingActions)
      .where(eq(pendingActions.userId, userId))
      .orderBy(pendingActions.createdAt);
  }

  /**
   * Differential (pull) sync: returns everything the authenticated athlete's own
   * certified/in-progress record set that has changed since `since`, plus any
   * tombstones for hard-deleted records owned by them. Server-authoritative by
   * design (Section 5): the phone caches this, it never writes it directly.
   *
   * `since` is a previous call's returned `serverTime` cursor (or omitted/epoch
   * for a first full sync). The response's own `serverTime` becomes the client's
   * next cursor — using the server's clock, not the client's, avoids clock-skew
   * gaps or duplicate re-fetches.
   */
  static async getDelta(userId: string, since?: string) {
    const sinceDate = since ? new Date(since) : new Date(0);
    if (isNaN(sinceDate.getTime())) {
      throw new BadRequestError("Invalid 'since' cursor: must be a valid ISO 8601 timestamp.");
    }
    const serverTime = new Date();

    const [profile] = await db
      .select()
      .from(athleteProfiles)
      .where(and(eq(athleteProfiles.userId, userId), gt(athleteProfiles.updatedAt, sinceDate)))
      .limit(1);

    // Resolve the athlete's own profile id regardless of whether the profile row
    // itself changed since `since` — we still need it to find their changed matches.
    const ownProfile = profile || (await db.select().from(athleteProfiles).where(eq(athleteProfiles.userId, userId)).limit(1))[0];

    let matchHistory: any[] = [];
    if (ownProfile) {
      matchHistory = await db
        .select()
        .from(matches)
        .where(
          and(
            or(eq(matches.challengerId, ownProfile.id), eq(matches.opponentId, ownProfile.id)),
            gt(matches.updatedAt, sinceDate)
          )
        );
    }

    const tombstones = await db
      .select()
      .from(syncTombstones)
      .where(and(eq(syncTombstones.ownerUserId, userId), gt(syncTombstones.deletedAt, sinceDate)));

    return {
      since: sinceDate.toISOString(),
      serverTime: serverTime.toISOString(),
      profile: profile || null,
      matches: matchHistory,
      deletions: tombstones.map((t) => ({ table: t.tableName, recordId: t.recordId, deletedAt: t.deletedAt })),
    };
  }
}
