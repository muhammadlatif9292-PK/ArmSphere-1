import { eq, and, or, desc, asc } from "drizzle-orm";
import { alias } from "drizzle-orm/pg-core";
import { db } from "../config/db.js";
import { 
  matches, 
  eloLedger, 
  athleteProfiles, 
  users, 
  auditLogs 
} from "@armsphere/db-schema";
import { 
  NotFoundError, 
  BadRequestError, 
  ForbiddenError, 
  ConflictError, 
  logger 
} from "@armsphere/core";
import { UserRole } from "@armsphere/types";
import { RefereeCertificationService } from "./refereeCertification.js";
import { UserRoleService } from "./userRole.js";

export interface CreateMatchInput {
  challengerId: string;
  opponentId: string;
  arm: "LEFT" | "RIGHT" | "left" | "right";
  winnerId: string;
  scoreLine: string;
  evidenceUrl?: string;
  province?: string;
}

export class MatchService {
  /**
   * Submit/Ingest a new competitive match
   */
  static async createMatch(refereeId: string, input: CreateMatchInput, idempotencyKey?: string) {
    // 1. Convert arm to uppercase for standardization
    const armUpper = input.arm.toUpperCase() as "LEFT" | "RIGHT";
    if (armUpper !== "LEFT" && armUpper !== "RIGHT") {
      throw new BadRequestError("Invalid arm field. Must be 'LEFT' or 'RIGHT'.");
    }

    // 2. Validate challenger and opponent aren't the same
    if (input.challengerId === input.opponentId) {
      throw new BadRequestError("Challenger and Opponent cannot be the same athlete profile.");
    }

    // 3. Validate winner is one of the participants
    if (input.winnerId !== input.challengerId && input.winnerId !== input.opponentId) {
      throw new BadRequestError("Winner must be either the Challenger or the Opponent.");
    }

    // 4. Validate scoreLine format (e.g. "3-0", "3-2")
    const scoreRegex = /^\d+-\d+$/;
    if (!scoreRegex.test(input.scoreLine)) {
      throw new BadRequestError("Score line must be formatted as 'X-Y' (e.g. '3-1').");
    }

    // 5. Idempotency protection check — look up by the dedicated column, not
    // by guessing from business fields + a timestamp (the old check compared
    // createdAt to `new Date()` at query time, which can never match an
    // already-inserted row, so it never actually prevented anything).
    if (idempotencyKey) {
      const [existingMatch] = await db
        .select()
        .from(matches)
        .where(eq(matches.idempotencyKey, idempotencyKey))
        .limit(1);

      if (existingMatch) {
        return existingMatch;
      }
    }

    // 6. Fetch profiles to verify they exist
    const [challengerProfile] = await db
      .select()
      .from(athleteProfiles)
      .where(eq(athleteProfiles.id, input.challengerId))
      .limit(1);

    if (!challengerProfile) {
      throw new NotFoundError("Challenger athlete profile not found");
    }

    const [opponentProfile] = await db
      .select()
      .from(athleteProfiles)
      .where(eq(athleteProfiles.id, input.opponentId))
      .limit(1);

    if (!opponentProfile) {
      throw new NotFoundError("Opponent athlete profile not found");
    }

    // 7. Verify referee is registered and holds an authorized role. Match
    // submission is an official-record-of-truth action (same reasoning as
    // verification, Step D) — not something any authenticated user should
    // be able to do just by knowing another athlete's IDs. The code comment
    // that used to say "submitted by referee or participant" suggested
    // self-reported submission was allowed; per explicit product decision
    // this is now restricted to the same official roles that can verify.
    const [refereeUser] = await db
      .select()
      .from(users)
      .where(eq(users.id, refereeId))
      .limit(1);

    if (!refereeUser) {
      throw new NotFoundError("Referee user profile not found");
    }

    const AUTHORIZED_SUBMITTER_ROLES = [
      UserRole.REFEREE,
      UserRole.PROVINCIAL_DIRECTOR,
      UserRole.NATIONAL_DIRECTOR,
      UserRole.SYSTEM_ADMIN,
    ];
    const hasAuthorizedRole =
      AUTHORIZED_SUBMITTER_ROLES.includes(refereeUser.role as UserRole) ||
      (await UserRoleService.hasActiveRole(refereeId, AUTHORIZED_SUBMITTER_ROLES));
    if (!hasAuthorizedRole) {
      throw new ForbiddenError(
        "Only referees, directors, or system administrators may submit match results."
      );
    }

    // Active certification check: referees submitting official match records must hold active certification
    if (refereeUser.role === UserRole.REFEREE) {
      await RefereeCertificationService.assertActiveCertification(refereeId);
    }

    const actorJurisdiction =
      ((refereeUser as any).province as string | null | undefined) ??
      ((refereeUser as any).regionalCoverage as string | null | undefined) ??
      null;
    const authoritativeProvince =
      challengerProfile.province ??
      opponentProfile.province ??
      actorJurisdiction ??
      null;

    if (input.province && input.province.trim().length > 0) {
      const requestedProvince = input.province.trim();
      if (
        authoritativeProvince &&
        requestedProvince.toLowerCase() !== authoritativeProvince.trim().toLowerCase()
      ) {
        throw new ForbiddenError(
          `Cannot override authoritative match province (${authoritativeProvince}) with client-supplied province (${requestedProvince}).`
        );
      }
      if (
        actorJurisdiction &&
        requestedProvince.toLowerCase() !== actorJurisdiction.trim().toLowerCase()
      ) {
        throw new ForbiddenError(
          `Cannot submit a match for province (${requestedProvince}) outside official jurisdiction (${actorJurisdiction}).`
        );
      }
    }

    if (refereeUser.role === UserRole.PROVINCIAL_DIRECTOR) {
      if (
        !actorJurisdiction ||
        !authoritativeProvince ||
        actorJurisdiction.trim().toLowerCase() !== authoritativeProvince.trim().toLowerCase()
      ) {
        throw new ForbiddenError(
          `Provincial directors can only submit matches within their assigned province (${actorJurisdiction || "unassigned"}).`
        );
      }
    }

    const matchProvince = authoritativeProvince;

    // 8. Insert match record with PENDING_VERIFICATION status by default
    const [match] = await db
      .insert(matches)
      .values({
        challengerId: input.challengerId,
        opponentId: input.opponentId,
        arm: armUpper,
        refereeId,
        winnerId: input.winnerId,
        scoreLine: input.scoreLine,
        status: "PENDING_VERIFICATION",
        evidenceUrl: input.evidenceUrl || null,
        idempotencyKey: idempotencyKey || null,
        province: matchProvince,
      })
      .returning();

    // 9. Write audit log entry
    await db.insert(auditLogs).values({
      userId: refereeId,
      action: "MATCH_SUBMITTED",
      details: { matchId: match.id, challengerId: match.challengerId, opponentId: match.opponentId },
    });

    logger.info({ matchId: match.id }, "Match submitted and ingested successfully");

    return match;
  }

  /**
   * Fetch match by ID
   */
  static async getMatchById(matchId: string) {
    const [match] = await db
      .select()
      .from(matches)
      .where(eq(matches.id, matchId))
      .limit(1);

    if (!match) {
      throw new NotFoundError("Match not found");
    }

    // Field-level API hygiene, not an access-control change (visibility
    // review, Step F): idempotencyKey is an internal request-deduplication
    // implementation detail, not part of the public competitive record.
    // Every other field here is legitimately public — this endpoint stays
    // authenticated-readable for any user, per explicit product policy.
    const { idempotencyKey, ...publicMatch } = match as any;
    return publicMatch;
  }

  /**
   * Verify match and calculate/apply ELO ratings inside an ACID transaction with pessimistic sorting locks
   */
  static async verifyMatch(matchId: string, reviewerId: string) {
    await RefereeCertificationService.assertActiveCertification(reviewerId);

    // Look up the reviewer's real role from the database — not from a JWT
    // claim alone (a stale or forged token shouldn't be implicitly trusted;
    // same defense-in-depth reasoning as Step C's submission check).
    const [reviewerUser] = await db.select().from(users).where(eq(users.id, reviewerId)).limit(1);
    if (!reviewerUser) {
      throw new NotFoundError("Reviewer user not found");
    }

    try {
      return await db.transaction(async (tx) => {
        // 1. Fetch match for update — SELECT ... FOR UPDATE genuinely locks
        // the row for the duration of this transaction. This is the primary
        // defense: a second, concurrent verifyMatch() call on the SAME match
        // blocks here (at the database level) until this transaction commits
        // or rolls back, rather than both proceeding to compute ELO from the
        // same stale snapshot.
        const [match] = await tx
          .select()
          .from(matches)
          .where(eq(matches.id, matchId))
          .for("update")
          .limit(1);

        if (!match) {
          throw new NotFoundError("Match not found");
        }

        // Verification authority policy:
        // - REFEREE may verify only the match assigned to them (the match's
        //   own refereeId — set at submission time).
        // - PROVINCIAL_DIRECTOR may verify only matches within their provincial
        //   jurisdiction (matching users.province or users.regionalCoverage).
        // - NATIONAL_DIRECTOR / SYSTEM_ADMIN retain universal federation authority.
        const AUTHORIZED_VERIFIER_ROLES = [
          UserRole.REFEREE,
          UserRole.PROVINCIAL_DIRECTOR,
          UserRole.NATIONAL_DIRECTOR,
          UserRole.SYSTEM_ADMIN,
        ];
        if (!AUTHORIZED_VERIFIER_ROLES.includes(reviewerUser.role as UserRole)) {
          throw new ForbiddenError("Only referees, directors, or system administrators may verify match outcomes.");
        }

        if (reviewerUser.role === UserRole.REFEREE && match.refereeId !== reviewerId) {
          throw new ForbiddenError(
            "Only the referee assigned to this match may verify it. Directors or system administrators may override."
          );
        }

        if (match.status === "VERIFIED") {
          throw new ConflictError("Match has already been verified.");
        }
        if (match.status === "VOID" || match.status === "VOIDED") {
          throw new ConflictError("Cannot verify a voided match.");
        }

        // 2. Perform pessimistic locking of athlete rows in alphabetical ID
        // order to prevent deadlocks — a real `FOR UPDATE` lock this time, not
        // just a comment claiming one. Without this, two matches verifying
        // concurrently for the same athlete (e.g. as challenger in one match,
        // opponent in another) could both read the same stale ELO value and
        // overwrite each other's update.
        const sortedAthleteIds = [match.challengerId, match.opponentId].sort();
        const athleteLockPromises = sortedAthleteIds.map((id) =>
          tx
            .select()
            .from(athleteProfiles)
            .where(eq(athleteProfiles.id, id))
            .for("update")
            .limit(1)
        );
        const lockedAthletes = await Promise.all(athleteLockPromises);

        const challenger = lockedAthletes.find(([ap]) => ap.id === match.challengerId)?.[0];
        const opponent = lockedAthletes.find(([ap]) => ap.id === match.opponentId)?.[0];

        if (!challenger || !opponent) {
          throw new NotFoundError("Competitor profile not found");
        }

        if (reviewerUser.role === UserRole.PROVINCIAL_DIRECTOR) {
          const actorJurisdiction =
            ((reviewerUser as any).province as string | null | undefined) ??
            ((reviewerUser as any).regionalCoverage as string | null | undefined) ??
            null;
          const matchProvince = challenger.province ?? opponent.province ?? match.province ?? null;
          if (!actorJurisdiction || !matchProvince || actorJurisdiction.trim().toLowerCase() !== matchProvince.trim().toLowerCase()) {
            throw new ForbiddenError(
              `Provincial directors can only verify matches within their assigned province (${actorJurisdiction || "unassigned"}).`
            );
          }
        }

        // 3. Update match status to VERIFIED
        const now = new Date();
        const [updatedMatch] = await tx
          .update(matches)
          .set({
            status: "VERIFIED",
            verifiedAt: now,
            updatedAt: now,
          })
          .where(eq(matches.id, matchId))
          .returning();

        // 4. Calculate ELO updates
        const arm = match.arm.toUpperCase() as "LEFT" | "RIGHT";
        const isWinnerChallenger = match.winnerId === match.challengerId;

        const ratingC = arm === "LEFT" ? challenger.leftArmElo : challenger.rightArmElo;
        const ratingO = arm === "LEFT" ? opponent.leftArmElo : opponent.rightArmElo;

        // Count previous verified matches for each competitor to compute K-factor
        const challengerMatches = await tx
          .select()
          .from(matches)
          .where(
            and(
              eq(matches.arm, arm),
              eq(matches.status, "VERIFIED"),
              or(
                eq(matches.challengerId, match.challengerId),
                eq(matches.opponentId, match.challengerId)
              )
            )
          );
        
        const opponentMatches = await tx
          .select()
          .from(matches)
          .where(
            and(
              eq(matches.arm, arm),
              eq(matches.status, "VERIFIED"),
              or(
                eq(matches.challengerId, match.opponentId),
                eq(matches.opponentId, match.opponentId)
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

        // Expected scores
        const expectedC = 1 / (1 + Math.pow(10, (ratingO - ratingC) / 400));
        const expectedO = 1 / (1 + Math.pow(10, (ratingC - ratingO) / 400));

        const actualC = isWinnerChallenger ? 1 : 0;
        const actualO = isWinnerChallenger ? 0 : 1;

        // Rating deltas
        const deltaC = Math.round(kC * (actualC - expectedC));
        const deltaO = Math.round(kO * (actualO - expectedO));

        const newRatingC = Math.max(1000, ratingC + deltaC);
        const newRatingO = Math.max(1000, ratingO + deltaO);

        // 5. Update athletes
        if (arm === "LEFT") {
          await tx
            .update(athleteProfiles)
            .set({
              leftArmElo: newRatingC,
              updatedAt: now,
            })
            .where(eq(athleteProfiles.id, match.challengerId));

          await tx
            .update(athleteProfiles)
            .set({
              leftArmElo: newRatingO,
              updatedAt: now,
            })
            .where(eq(athleteProfiles.id, match.opponentId));
        } else {
          await tx
            .update(athleteProfiles)
            .set({
              rightArmElo: newRatingC,
              updatedAt: now,
            })
            .where(eq(athleteProfiles.id, match.challengerId));

          await tx
            .update(athleteProfiles)
            .set({
              rightArmElo: newRatingO,
              updatedAt: now,
            })
            .where(eq(athleteProfiles.id, match.opponentId));
        }

        // 6. Record inside the ELO Ledger
        await tx.insert(eloLedger).values({
          matchId,
          athleteId: match.challengerId,
          arm,
          previousElo: ratingC,
          newElo: newRatingC,
          eloDelta: deltaC,
        });

        await tx.insert(eloLedger).values({
          matchId,
          athleteId: match.opponentId,
          arm,
          previousElo: ratingO,
          newElo: newRatingO,
          eloDelta: deltaO,
        });

        // 7. Write audit log
        await tx.insert(auditLogs).values({
          userId: reviewerId,
          action: "MATCH_VERIFIED",
          details: { matchId, deltaC, deltaO, newRatingC, newRatingO },
        });

        logger.info({ matchId }, "Match verified and ratings adjusted successfully inside transaction");

        return {
          match: updatedMatch,
          changes: {
            challenger: { previousElo: ratingC, newElo: newRatingC, eloDelta: deltaC },
            opponent: { previousElo: ratingO, newElo: newRatingO, eloDelta: deltaO },
          }
        };
      });
    } catch (err: any) {
      if (err?.code === "23505" || /unique constraint/i.test(String(err?.message || ""))) {
        throw new ConflictError("Match has already been verified.");
      }
      throw err;
    }
  }

  /**
   * Dispute an ingested match, flagging it for federation arbitration
   */
  static async disputeMatch(matchId: string, actorId: string, reason: string) {
    const [match] = await db
      .select()
      .from(matches)
      .where(eq(matches.id, matchId))
      .limit(1);

    if (!match) {
      throw new NotFoundError("Match not found");
    }

    if (match.status === "DISPUTED") {
      throw new ConflictError("Match is already in dispute.");
    }
    if (match.status === "VOID") {
      throw new ConflictError("Voided matches cannot be disputed.");
    }

    const [actorUser] = await db.select().from(users).where(eq(users.id, actorId)).limit(1);
    if (!actorUser) {
      throw new NotFoundError("Actor user not found");
    }

    const OVERRIDE_ROLES = [UserRole.PROVINCIAL_DIRECTOR, UserRole.NATIONAL_DIRECTOR, UserRole.SYSTEM_ADMIN];
    const isOverrideRole = OVERRIDE_ROLES.includes(actorUser.role as UserRole);
    const isAssignedReferee = match.refereeId === actorId;

    let isParticipant = false;
    if (!isOverrideRole && !isAssignedReferee) {
      const [actorProfile] = await db
        .select()
        .from(athleteProfiles)
        .where(eq(athleteProfiles.userId, actorId))
        .limit(1);
      isParticipant = !!actorProfile && (actorProfile.id === match.challengerId || actorProfile.id === match.opponentId);
    }

    if (!isOverrideRole && !isAssignedReferee && !isParticipant) {
      throw new ForbiddenError(
        "Only a match participant, the assigned referee, or a director/administrator may dispute this match."
      );
    }

    if (isOverrideRole && actorUser.role === UserRole.PROVINCIAL_DIRECTOR) {
      const actorJurisdiction =
        ((actorUser as any).province as string | null | undefined) ??
        ((actorUser as any).regionalCoverage as string | null | undefined) ??
        null;
      const [challenger] = await db
        .select({ province: athleteProfiles.province })
        .from(athleteProfiles)
        .where(eq(athleteProfiles.id, match.challengerId))
        .limit(1);
      const matchProvince = challenger?.province ?? match.province ?? null;
      if (!actorJurisdiction || !matchProvince || actorJurisdiction.trim().toLowerCase() !== matchProvince.trim().toLowerCase()) {
        throw new ForbiddenError(
          `Provincial directors can only dispute matches within their assigned province (${actorJurisdiction || "unassigned"}).`
        );
      }
    }

    const [updatedMatch] = await db
      .update(matches)
      .set({ status: "DISPUTED", updatedAt: new Date() })
      .where(eq(matches.id, matchId))
      .returning();

    await db.insert(auditLogs).values({
      userId: actorId,
      action: "MATCH_DISPUTED",
      details: { matchId, reason, previousStatus: match.status },
    });

    logger.warn({ matchId, actorId }, `Match has been marked as DISPUTED: ${reason}`);

    return updatedMatch;
  }

  /**
   * Void a verified match, rolling back ratings and replaying subsequent updates chronologically (historical series reconstruction)
   */
  static async voidMatch(matchId: string, actorId: string, reason: string) {
    return await db.transaction(async (tx) => {
      // 1. Fetch match for rollback — real row lock, same reasoning as
      // verifyMatch (Step B): a concurrent void/verify/correct on the same
      // match must not interleave with this ELO-reversal transaction.
      const [match] = await tx
        .select()
        .from(matches)
        .where(eq(matches.id, matchId))
        .for("update")
        .limit(1);

      if (!match) {
        throw new NotFoundError("Match not found");
      }

      if (match.status === "VOID") {
        throw new ConflictError("Match is already voided.");
      }

      const [actorUser] = await tx.select().from(users).where(eq(users.id, actorId)).limit(1);
      if (!actorUser) {
        throw new NotFoundError("Actor user not found");
      }

      const VOID_ROLES = [UserRole.PROVINCIAL_DIRECTOR, UserRole.NATIONAL_DIRECTOR, UserRole.SYSTEM_ADMIN];
      if (!VOID_ROLES.includes(actorUser.role as UserRole)) {
        throw new ForbiddenError("Only provincial directors, national directors, or system administrators may void matches.");
      }

      if (actorUser.role === UserRole.PROVINCIAL_DIRECTOR) {
        const actorJurisdiction =
          ((actorUser as any).province as string | null | undefined) ??
          ((actorUser as any).regionalCoverage as string | null | undefined) ??
          null;
        const [challenger] = await tx
          .select({ province: athleteProfiles.province })
          .from(athleteProfiles)
          .where(eq(athleteProfiles.id, match.challengerId))
          .limit(1);
        const matchProvince = challenger?.province ?? match.province ?? null;
        if (!actorJurisdiction || !matchProvince || actorJurisdiction.trim().toLowerCase() !== matchProvince.trim().toLowerCase()) {
          throw new ForbiddenError(
            `Provincial directors can only void matches within their assigned province (${actorJurisdiction || "unassigned"}).`
          );
        }
      }

      const existingMatchLedger = await tx
        .select()
        .from(eloLedger)
        .where(eq(eloLedger.matchId, matchId));
      const wasVerified = match.status === "VERIFIED" || existingMatchLedger.length > 0;

      // 2. Transition status to VOID
      const [voidedMatch] = await tx
        .update(matches)
        .set({ status: "VOID", updatedAt: new Date() })
        .where(eq(matches.id, matchId))
        .returning();

      // Write audit trail
      await tx.insert(auditLogs).values({
        userId: actorId,
        action: "MATCH_VOIDED",
        details: { matchId, reason },
      });

      if (wasVerified) {
        logger.info({ matchId }, "Initiating chronological ELO recalculation series repair");

        const arm = match.arm.toUpperCase() as "LEFT" | "RIGHT";

        // Gather all verified subsequent matches for these competitors chronologically
        const allVerifiedMatches = await tx
          .select()
          .from(matches)
          .where(
            and(
              eq(matches.arm, arm),
              eq(matches.status, "VERIFIED"),
              or(
                eq(matches.challengerId, match.challengerId),
                eq(matches.opponentId, match.challengerId),
                eq(matches.challengerId, match.opponentId),
                eq(matches.opponentId, match.opponentId)
              )
            )
          )
          .orderBy(asc(matches.createdAt));

        const voidedTimestamp = (match.verifiedAt ?? match.createdAt)?.getTime?.() ?? 0;
        const subsequentMatches = allVerifiedMatches.filter((sm) => {
          if (sm.id === matchId) return false;
          const smTime = (sm.verifiedAt ?? sm.createdAt)?.getTime?.() ?? 0;
          return smTime >= voidedTimestamp;
        });

        // Reverse subsequent matches' ledger entries in reverse chronological order first
        for (let i = subsequentMatches.length - 1; i >= 0; i--) {
          const sm = subsequentMatches[i];
          const smEntries = await tx.select().from(eloLedger).where(eq(eloLedger.matchId, sm.id));
          for (const entry of smEntries) {
            const [athlete] = await tx
              .select()
              .from(athleteProfiles)
              .where(eq(athleteProfiles.id, entry.athleteId))
              .for("update")
              .limit(1);
            if (athlete) {
              const restoredElo = entry.previousElo ?? Math.max(1000, (arm === "LEFT" ? athlete.leftArmElo : athlete.rightArmElo) - entry.eloDelta);
              if (arm === "LEFT") {
                await tx.update(athleteProfiles).set({ leftArmElo: Math.max(1000, restoredElo) }).where(eq(athleteProfiles.id, entry.athleteId));
              } else {
                await tx.update(athleteProfiles).set({ rightArmElo: Math.max(1000, restoredElo) }).where(eq(athleteProfiles.id, entry.athleteId));
              }
            }
          }
          await tx.delete(eloLedger).where(eq(eloLedger.matchId, sm.id));
        }

        // Query and reverse the ledger entries associated with the voided match itself
        const ledgerEntries = await tx
          .select()
          .from(eloLedger)
          .where(eq(eloLedger.matchId, matchId));

        for (const entry of ledgerEntries) {
          const [athlete] = await tx
            .select()
            .from(athleteProfiles)
            .where(eq(athleteProfiles.id, entry.athleteId))
            .for("update")
            .limit(1);

          if (athlete) {
            const restoredElo = entry.previousElo ?? Math.max(1000, (arm === "LEFT" ? athlete.leftArmElo : athlete.rightArmElo) - entry.eloDelta);
            if (arm === "LEFT") {
              await tx
                .update(athleteProfiles)
                .set({ leftArmElo: Math.max(1000, restoredElo) })
                .where(eq(athleteProfiles.id, entry.athleteId));
            } else {
              await tx
                .update(athleteProfiles)
                .set({ rightArmElo: Math.max(1000, restoredElo) })
                .where(eq(athleteProfiles.id, entry.athleteId));
            }
          }
        }

        // Delete the rolled back ledger entries for the voided match
        await tx.delete(eloLedger).where(eq(eloLedger.matchId, matchId));

        // Re-calculate and replay the subsequent matches in chronological sequence
        if (subsequentMatches.length > 0) {
          const getK = (matchesCount: number, elo: number) => {
            if (matchesCount < 10) return 64;
            if (elo >= 2200) return 16;
            return 32;
          };

          for (const sm of subsequentMatches) {
            const [smChallenger] = await tx.select().from(athleteProfiles).where(eq(athleteProfiles.id, sm.challengerId)).limit(1);
            const [smOpponent] = await tx.select().from(athleteProfiles).where(eq(athleteProfiles.id, sm.opponentId)).limit(1);
            if (!smChallenger || !smOpponent) continue;

            const ratingC = arm === "LEFT" ? smChallenger.leftArmElo : smChallenger.rightArmElo;
            const ratingO = arm === "LEFT" ? smOpponent.leftArmElo : smOpponent.rightArmElo;

            const smTime = (sm.verifiedAt ?? sm.createdAt)?.getTime?.() ?? 0;
            const priorCountC = allVerifiedMatches.filter(
              (m) =>
                m.id !== matchId &&
                m.id !== sm.id &&
                (m.challengerId === sm.challengerId || m.opponentId === sm.challengerId) &&
                ((m.verifiedAt ?? m.createdAt)?.getTime?.() ?? 0) <= smTime
            ).length + 1;
            const priorCountO = allVerifiedMatches.filter(
              (m) =>
                m.id !== matchId &&
                m.id !== sm.id &&
                (m.challengerId === sm.opponentId || m.opponentId === sm.opponentId) &&
                ((m.verifiedAt ?? m.createdAt)?.getTime?.() ?? 0) <= smTime
            ).length + 1;

            const kC = getK(priorCountC, ratingC);
            const kO = getK(priorCountO, ratingO);

            const expectedC = 1 / (1 + Math.pow(10, (ratingO - ratingC) / 400));
            const expectedO = 1 / (1 + Math.pow(10, (ratingC - ratingO) / 400));

            const isWinnerChallenger = sm.winnerId === sm.challengerId;
            const actualC = isWinnerChallenger ? 1 : 0;
            const actualO = isWinnerChallenger ? 0 : 1;

            const deltaC = Math.round(kC * (actualC - expectedC));
            const deltaO = Math.round(kO * (actualO - expectedO));

            const newRatingC = Math.max(1000, ratingC + deltaC);
            const newRatingO = Math.max(1000, ratingO + deltaO);

            if (arm === "LEFT") {
              await tx.update(athleteProfiles).set({ leftArmElo: newRatingC, updatedAt: new Date() }).where(eq(athleteProfiles.id, sm.challengerId));
              await tx.update(athleteProfiles).set({ leftArmElo: newRatingO, updatedAt: new Date() }).where(eq(athleteProfiles.id, sm.opponentId));
            } else {
              await tx.update(athleteProfiles).set({ rightArmElo: newRatingC, updatedAt: new Date() }).where(eq(athleteProfiles.id, sm.challengerId));
              await tx.update(athleteProfiles).set({ rightArmElo: newRatingO, updatedAt: new Date() }).where(eq(athleteProfiles.id, sm.opponentId));
            }

            await tx.insert(eloLedger).values({
              matchId: sm.id,
              athleteId: sm.challengerId,
              arm,
              previousElo: ratingC,
              newElo: newRatingC,
              eloDelta: deltaC,
            });
            await tx.insert(eloLedger).values({
              matchId: sm.id,
              athleteId: sm.opponentId,
              arm,
              previousElo: ratingO,
              newElo: newRatingO,
              eloDelta: deltaO,
            });
          }

          logger.info({ matchIds: subsequentMatches.map((sm) => sm.id) }, "Historical series voided and replayed successfully");
        }
      }

      return voidedMatch;
    });
  }

  /**
   * Fetch recent verified/completed matches with pagination
   */
  static async getRecentMatches(options: { limit: number; offset: number }) {
    const { limit, offset } = options;
    const challenger = alias(athleteProfiles, "challenger");
    const opponent = alias(athleteProfiles, "opponent");

    return await db
      .select({
        id: matches.id,
        challengerId: matches.challengerId,
        opponentId: matches.opponentId,
        challengerName: challenger.displayName,
        opponentName: opponent.displayName,
        arm: matches.arm,
        refereeId: matches.refereeId,
        winnerId: matches.winnerId,
        scoreLine: matches.scoreLine,
        status: matches.status,
        evidenceUrl: matches.evidenceUrl,
        createdAt: matches.createdAt,
        verifiedAt: matches.verifiedAt,
      })
      .from(matches)
      .leftJoin(challenger, eq(matches.challengerId, challenger.id))
      .leftJoin(opponent, eq(matches.opponentId, opponent.id))
      .where(eq(matches.status, "VERIFIED"))
      .orderBy(desc(matches.verifiedAt))
      .limit(limit)
      .offset(offset);
  }

  /**
   * Fetch paginated match history for a specific athlete
   */
  static async getAthleteMatches(athleteId: string, options: { limit: number; offset: number }) {
    const { limit, offset } = options;

    const [profile] = await db
      .select({ id: athleteProfiles.id })
      .from(athleteProfiles)
      .where(and(or(eq(athleteProfiles.id, athleteId), eq(athleteProfiles.userId, athleteId)), eq(athleteProfiles.isDeleted, false)))
      .limit(1);

    if (!profile) {
      throw new NotFoundError("Athlete profile not found");
    }

    const targetProfileId = profile.id;
    const challenger = alias(athleteProfiles, "challenger");
    const opponent = alias(athleteProfiles, "opponent");

    return await db
      .select({
        id: matches.id,
        challengerId: matches.challengerId,
        opponentId: matches.opponentId,
        challengerName: challenger.displayName,
        opponentName: opponent.displayName,
        arm: matches.arm,
        refereeId: matches.refereeId,
        winnerId: matches.winnerId,
        scoreLine: matches.scoreLine,
        status: matches.status,
        evidenceUrl: matches.evidenceUrl,
        createdAt: matches.createdAt,
        verifiedAt: matches.verifiedAt,
      })
      .from(matches)
      .leftJoin(challenger, eq(matches.challengerId, challenger.id))
      .leftJoin(opponent, eq(matches.opponentId, opponent.id))
      .where(
        and(
          eq(matches.status, "VERIFIED"),
          or(
            eq(matches.challengerId, targetProfileId),
            eq(matches.opponentId, targetProfileId)
          )
        )
      )
      .orderBy(desc(matches.verifiedAt))
      .limit(limit)
      .offset(offset);
  }
}

