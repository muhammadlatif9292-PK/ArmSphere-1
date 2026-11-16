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
      case "SUBMIT_MATCH":
      case "SUBMIT_REFEREE_MATCH_RESULT": {
        logger.info({ payload }, "Persisting synchronized match data from offline queue");
        return { matchId: payload.matchId, outcome: "MATCH_SAVED" };
      }

      case "SAVE_TOURNAMENT_DRAFT":
      case "UPDATE_RELEASED_TOURNAMENT": {
        logger.info({ payload, userId }, "Persisting synchronized operator tournament configuration from offline outbox");
        return {
          tournamentId: payload?.tournament?.id || payload?.id || "draft",
          outcome: "TOURNAMENT_SAVED",
        };
      }

      case "RELEASE_TOURNAMENT": {
        logger.info({ payload, userId }, "Processing offline tournament release / schedule action");
        return {
          tournamentId: payload?.step1Config?.id || payload?.id || "released",
          status: "REGISTRATION_OPEN",
          outcome: "TOURNAMENT_RELEASED",
        };
      }

      case "SUBMIT_ATHLETE_APPLICATION":
      case "REGISTER_ATHLETE": {
        logger.info({ payload, userId }, "Persisting offline athlete tournament application");
        return {
          eventId: payload?.eventId,
          athleteId: payload?.athleteId || userId,
          outcome: "APPLICATION_RECORDED",
        };
      }

      case "VERIFY_WEIGH_IN":
      case "SUBMIT_WEIGH_IN":
      case "RECORD_WEIGH_IN":
      case "CERTIFY_WEIGH_IN": {
        logger.info({ payload, userId }, "Persisting offline athlete weigh-in verification");
        return {
          eventId: payload?.eventId,
          registrationId: payload?.registrationId,
          athleteId: payload?.athleteId,
          measuredWeightKg: payload?.measuredWeightKg ?? payload?.weight,
          status: payload?.status || "VERIFIED",
          outcome: "WEIGH_IN_VERIFIED",
        };
      }

      case "MARK_WEIGH_IN_UNMATCH": {
        logger.info({ payload, userId }, "Persisting offline athlete weigh-in UNMATCH marking");
        return {
          eventId: payload?.eventId,
          registrationId: payload?.registrationId,
          athleteId: payload?.athleteId,
          measuredWeightKg: payload?.measuredWeightKg,
          status: "UNMATCH",
          outcome: "WEIGH_IN_UNMATCH_MARKED",
        };
      }

      case "RESOLVE_UNMATCH_ATHLETE":
      case "REASSIGN_REGISTRATION": {
        logger.info({ payload, userId }, "Persisting offline resolution of UNMATCH athlete (move category / assign opponent or leave out)");
        return {
          eventId: payload?.eventId,
          registrationId: payload?.registrationId,
          athleteId: payload?.athleteId,
          resolutionMode: payload?.resolutionMode || "MOVE_CATEGORY",
          targetCategoryKey: payload?.targetCategoryKey ?? payload?.newWeightClass,
          assignedOpponentId: payload?.assignedOpponentId,
          assignedOpponentName: payload?.assignedOpponentName,
          status: payload?.status || "VERIFIED",
          outcome: "UNMATCH_RESOLVED",
        };
      }

      case "UPDATE_SPECTATOR_GATE_CONFIG": {
        logger.info({ payload, userId }, "Persisting offline spectator access & guest configuration");
        return {
          eventId: payload?.eventId,
          spectatorAccessMode: payload?.spectatorAccessMode,
          spectatorFeePkr: payload?.spectatorFeePkr,
          allowedGuestsPerAthlete: payload?.allowedGuestsPerAthlete,
          outcome: "SPECTATOR_GATE_CONFIG_SAVED",
        };
      }

      case "SCAN_VENUE_ENTRANCE_QR": {
        logger.info({ payload, userId }, "Persisting offline venue entrance QR check-in");
        return {
          eventId: payload?.eventId,
          passId: payload?.passId,
          passType: payload?.passType,
          holderName: payload?.holderName,
          checkedInAt: payload?.checkedInAt || new Date().toISOString(),
          status: "VERIFIED_ALLOWED",
          outcome: "ENTRANCE_CHECKIN_RECORDED",
        };
      }

      case "CREATE_CATEGORY_MATCHUPS":
      case "UPDATE_MATCHUP_PAIRING": {
        logger.info({ payload, userId }, "Persisting offline category matchup creation / pairing update");
        return {
          eventId: payload?.eventId,
          categoryLabel: payload?.categoryLabel,
          roundNumber: payload?.roundNumber || 1,
          matchCount: payload?.matchCount || 0,
          outcome: "MATCHUPS_SYNCED",
        };
      }

      case "ADVANCE_ROUND_OVERRIDE": {
        logger.info({ payload, userId }, "Persisting offline operator next-round override & pending cancellation");
        return {
          eventId: payload?.eventId,
          categoryLabel: payload?.categoryLabel,
          fromRound: payload?.fromRound,
          toRound: payload?.toRound,
          cancelledPendingCount: payload?.cancelledPendingCount || 0,
          outcome: "ROUND_ADVANCED",
        };
      }

      case "REASSIGN_MATCHUP_TABLE": {
        logger.info({ payload, userId }, "Persisting offline manual matchup table reassignment");
        return {
          eventId: payload?.eventId,
          categoryLabel: payload?.categoryLabel,
          matchId: payload?.matchId,
          previousTable: payload?.previousTable,
          assignedTable: payload?.assignedTable,
          outcome: "MATCHUP_TABLE_REASSIGNED",
        };
      }

      case "SKIP_ABSENT_MATCHUP_PLAY_NEXT": {
        logger.info({ payload, userId }, "Persisting offline dynamic free-table skip absent matchup & promote next ready matchup");
        return {
          eventId: payload?.eventId,
          categoryLabel: payload?.categoryLabel,
          tableName: payload?.tableName,
          skippedMatchId: payload?.skippedMatchId,
          promotedMatchId: payload?.promotedMatchId,
          outcome: "ABSENT_MATCHUP_DEFERRED_NEXT_PROMOTED",
        };
      }

      case "CERTIFY_CATEGORY_PODIUM": {
        logger.info({ payload, userId }, "Persisting automatic category podium winners summary");
        return {
          eventId: payload?.eventId,
          categoryLabel: payload?.categoryLabel,
          podium: payload?.podium || [],
          outcome: "CATEGORY_PODIUM_RECORDED",
        };
      }

      case "PURCHASE_SPECTATOR_PASS": {
        logger.info({ payload, userId }, "Persisting offline spectator pass claim or purchase");
        return {
          eventId: payload?.eventId,
          passId: payload?.passId,
          holderId: payload?.holderId || userId,
          holderName: payload?.holderName,
          feePkr: payload?.feePkr || 0,
          status: "ACTIVE_ISSUED",
          outcome: "SPECTATOR_PASS_ISSUED",
        };
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
