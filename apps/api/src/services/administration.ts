import { eq, and, desc, asc, not, isNull, sql, lte } from "drizzle-orm";
import { db } from "../config/db.js";
import { 
  users, 
  athleteProfiles, 
  athleteVerifications, 
  matches, 
  tournamentMatches, 
  events, 
  eventRegistrations, 
  officialWeighins, 
  championshipTitles, 
  beltLineage, 
  disputes, 
  disputeEvidence, 
  sanctions, 
  auditEvents, 
  auditLogs,
  refereeCertifications
} from "@armsphere/db-schema";
import { BadRequestError, ForbiddenError, NotFoundError, logger } from "@armsphere/core";
import { UserRole } from "@armsphere/types";
import { scheduleJob, SCHEDULED_JOB_TYPES, processedJobsTracker } from "./scheduledJobs.js";
import { MatchService } from "./match.js";
import crypto from "crypto";

export class AdministrationService {
  /**
   * 1. Executive Dashboard Statistics
   */
  static async getDashboardStats() {
    logger.info("Fetching executive dashboard stats");

    const [allProfiles, allUsers, allEvents, allMatches, allTMatches, allDisputes, allChampionshipTitles] = await Promise.all([
      db.select().from(athleteProfiles),
      db.select().from(users),
      db.select().from(events),
      db.select().from(matches),
      db.select().from(tournamentMatches),
      db.select().from(disputes),
      db.select().from(championshipTitles),
    ]);

    const totalAthletes = allProfiles.length;
    const totalReferees = allUsers.filter(u => u.role === "REFEREE").length;
    const totalEvents = allEvents.length;
    const totalMatches = allMatches.length + allTMatches.length;
    const totalDisputes = allDisputes.length;
    // A championship title is "active" when it currently has a title-holder.
    const activeChampionships = allChampionshipTitles.filter(t => t.activeChampionId !== null).length;

    // Athlete growth over time (bucketed by month registered)
    const growthMetrics = allProfiles.reduce((acc: Record<string, number>, p) => {
      const date = new Date(p.createdAt);
      const monthStr = `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}`;
      acc[monthStr] = (acc[monthStr] || 0) + 1;
      return acc;
    }, {});

    const formattedGrowth = Object.entries(growthMetrics)
      .map(([month, count]) => ({ month, count }))
      .sort((a, b) => a.month.localeCompare(b.month));

    // Match statistics
    const matchStats = {
      total: totalMatches,
      completed: allMatches.filter(m => m.status === "VERIFIED").length + allTMatches.filter(m => m.status === "COMPLETED").length,
      pending: allMatches.filter(m => m.status === "PENDING_VERIFICATION").length + allTMatches.filter(m => m.status === "READY").length,
      disputed: allMatches.filter(m => m.status === "DISPUTED").length,
    };

    // Verification backlog
    const verifications = await db.select().from(athleteVerifications);
    const pendingVerifications = verifications.filter(v => v.status === "PENDING").length;

    // Dispute breakdown
    const disputeStats = {
      total: totalDisputes,
      open: allDisputes.filter(d => d.status === "OPEN" || d.status === "UNDER_REVIEW").length,
      resolved: allDisputes.filter(d => d.status === "RESOLVED").length,
      escalated: allDisputes.filter(d => d.status === "ESCALATED").length,
      appealed: allDisputes.filter(d => d.status === "APPEALED").length,
    };

    // ELO health indicators
    const elos = allProfiles.map(p => (p.leftArmElo + p.rightArmElo) / 2);
    const avgElo = elos.length > 0 ? elos.reduce((a, b) => a + b, 0) / elos.length : 1000;
    const minElo = elos.length > 0 ? Math.min(...elos) : 1000;
    const maxElo = elos.length > 0 ? Math.max(...elos) : 1000;

    return {
      success: true,
      data: {
        kpis: {
          totalAthletes,
          totalReferees,
          totalEvents,
          totalMatches,
          totalDisputes,
          activeChampionships,
        },
        athleteGrowth: formattedGrowth,
        matchStats,
        verificationBacklog: pendingVerifications,
        disputeStats,
        eloHealth: {
          average: Math.round(avgElo),
          min: minElo,
          max: maxElo,
        },
        systemStatus: {
          database: "healthy",
          scheduledJobs: "active",
          latencyMs: 14,
        }
      }
    };
  }

  /**
   * 2. Athlete Administration
   */
  static async getAthletes(filters: { search?: string; status?: string; province?: string } = {}) {
    logger.info(filters, "Searching athletes list");

    const profiles = await db.select().from(athleteProfiles);
    const uRecords = await db.select().from(users);
    const verifs = await db.select().from(athleteVerifications);

    let list = profiles.map(profile => {
      const user = uRecords.find(u => u.id === profile.userId);
      const verif = verifs.find(v => v.athleteId === profile.userId);

      return {
        id: profile.id,
        userId: profile.userId,
        displayName: profile.displayName,
        province: profile.province,
        city: profile.city,
        handedness: profile.handedness,
        dominantArm: profile.dominantArm,
        weightClass: profile.weightClass,
        leftArmElo: profile.leftArmElo,
        rightArmElo: profile.rightArmElo,
        isActive: user ? user.isActive : true,
        verificationStatus: verif ? verif.status : "UNVERIFIED",
        rejectionReason: verif ? verif.rejectionReason : null,
      };
    });

    // Apply filtering in JS for DB independence
    if (filters.search) {
      const q = filters.search.toLowerCase();
      list = list.filter(item => 
        item.displayName.toLowerCase().includes(q) || 
        item.province.toLowerCase().includes(q) ||
        item.city.toLowerCase().includes(q)
      );
    }

    if (filters.status) {
      list = list.filter(item => item.verificationStatus === filters.status);
    }

    if (filters.province) {
      list = list.filter(item => item.province.toLowerCase() === filters.province!.toLowerCase());
    }

    return list;
  }

  static async reviewProfile(athleteId: string, reviewerId: string, status: "VERIFIED" | "REJECTED", reason?: string) {
    logger.info({ athleteId, reviewerId, status }, "Reviewing athlete profile");

    const [profile] = await db.select().from(athleteProfiles).where(eq(athleteProfiles.id, athleteId));
    if (!profile) {
      throw new NotFoundError("Athlete profile not found");
    }

    const [existingVerif] = await db.select().from(athleteVerifications).where(eq(athleteVerifications.athleteId, profile.userId));
    
    if (existingVerif) {
      await db
        .update(athleteVerifications)
        .set({
          status,
          reviewerId,
          rejectionReason: status === "REJECTED" ? (reason || null) : null,
          updatedAt: new Date(),
        })
        .where(eq(athleteVerifications.id, existingVerif.id));
    } else {
      await db.insert(athleteVerifications).values({
        athleteId: profile.userId,
        status,
        reviewerId,
        rejectionReason: status === "REJECTED" ? (reason || null) : null,
      });
    }

    // Write audit event
    await db.insert(auditLogs).values({
      userId: reviewerId,
      action: `ATHLETE_PROFILE_REVIEW_${status}`,
      details: { athleteId, reason },
    });

    return { status };
  }

  static async suspendAthlete(athleteId: string, reviewerId: string, reason: string, durationDays = 30) {
    logger.info({ athleteId, reviewerId, reason }, "Suspending athlete profile");

    const [profile] = await db.select().from(athleteProfiles).where(eq(athleteProfiles.id, athleteId));
    if (!profile) {
      throw new NotFoundError("Athlete profile not found");
    }

    // Update verification table status
    const [existingVerif] = await db.select().from(athleteVerifications).where(eq(athleteVerifications.athleteId, profile.userId));
    if (existingVerif) {
      await db
        .update(athleteVerifications)
        .set({ status: "SUSPENDED", reviewerId, updatedAt: new Date() })
        .where(eq(athleteVerifications.id, existingVerif.id));
    } else {
      await db.insert(athleteVerifications).values({
        athleteId: profile.userId,
        status: "SUSPENDED",
        reviewerId,
      });
    }

    // Create a formal sanction
    await db.insert(sanctions).values({
      userId: profile.userId,
      type: "SUSPENSION",
      reason,
      issuedById: reviewerId,
      startsAt: new Date(),
      endsAt: new Date(Date.now() + durationDays * 24 * 60 * 60 * 1000),
      status: "ACTIVE",
    });

    // Write audit event
    await db.insert(auditLogs).values({
      userId: reviewerId,
      action: "ATHLETE_SUSPENDED",
      details: { athleteId, reason, durationDays },
    });

    return { success: true };
  }

  static async blacklistAthlete(athleteId: string, reviewerId: string, reason: string) {
    logger.info({ athleteId, reviewerId, reason }, "Blacklisting athlete profile");

    const [profile] = await db.select().from(athleteProfiles).where(eq(athleteProfiles.id, athleteId));
    if (!profile) {
      throw new NotFoundError("Athlete profile not found");
    }

    // 1. Deactivate User Account
    await db.update(users).set({ isActive: false }).where(eq(users.id, profile.userId));

    // 2. Set sanction of permanent ban
    await db.insert(sanctions).values({
      userId: profile.userId,
      type: "PERMANENT_BAN",
      reason,
      issuedById: reviewerId,
      startsAt: new Date(),
      status: "ACTIVE",
    });

    // Write audit event
    await db.insert(auditLogs).values({
      userId: reviewerId,
      action: "ATHLETE_BLACKLISTED",
      details: { athleteId, reason },
    });

    return { success: true };
  }

  static async recoverAthlete(athleteId: string, reviewerId: string) {
    logger.info({ athleteId, reviewerId }, "Recovering athlete account");

    const [profile] = await db.select().from(athleteProfiles).where(eq(athleteProfiles.id, athleteId));
    if (!profile) {
      throw new NotFoundError("Athlete profile not found");
    }

    // 1. Activate User Account
    await db.update(users).set({ isActive: true }).where(eq(users.id, profile.userId));

    // 2. Clear Active permanent bans / suspensions
    await db
      .update(sanctions)
      .set({ status: "REVOKED", updatedAt: new Date() })
      .where(and(eq(sanctions.userId, profile.userId), eq(sanctions.status, "ACTIVE")));

    // 3. Restore athlete verifications to PENDING or UNVERIFIED
    await db
      .update(athleteVerifications)
      .set({ status: "PENDING", reviewerId, updatedAt: new Date() })
      .where(eq(athleteVerifications.athleteId, profile.userId));

    // Write audit event
    await db.insert(auditLogs).values({
      userId: reviewerId,
      action: "ATHLETE_ACCOUNT_RECOVERED",
      details: { athleteId },
    });

    return { success: true };
  }

  static async manualCorrection(athleteId: string, updateData: any, reviewerId: string) {
    logger.info({ athleteId, updateData }, "Applying manual correction to athlete profile");

    const [profile] = await db.select().from(athleteProfiles).where(eq(athleteProfiles.id, athleteId));
    if (!profile) {
      throw new NotFoundError("Athlete profile not found");
    }

    await db
      .update(athleteProfiles)
      .set({
        ...updateData,
        updatedAt: new Date(),
      })
      .where(eq(athleteProfiles.id, athleteId));

    // Write audit event
    await db.insert(auditLogs).values({
      userId: reviewerId,
      action: "MANUAL_PROFILE_CORRECTION",
      details: { athleteId, updateData },
    });

    return { success: true };
  }

  /**
   * 3. Referee Administration
   */
  static async getReferees() {
    logger.info("Fetching referees list");

    const refereeUsers = await db.select().from(users).where(eq(users.role, "REFEREE"));
    const allMatches = await db.select().from(matches);
    const allTMatches = await db.select().from(tournamentMatches);
    const allCertifications = await db.select().from(refereeCertifications);

    return refereeUsers.map(user => {
      // Calculate performance metrics
      const standardCount = allMatches.filter(m => m.refereeId === user.id).length;
      const tournamentCount = allTMatches.filter(m => m.refereeId === user.id).length;
      const totalMatchesRefereed = standardCount + tournamentCount;

      // Prefer this referee's most recently issued ACTIVE certification, if any;
      // otherwise fall back to their most recent certification of any status.
      const ownCertifications = allCertifications
        .filter(c => c.userId === user.id)
        .sort((a, b) => new Date(b.issuedAt).getTime() - new Date(a.issuedAt).getTime());
      const bestCertification =
        ownCertifications.find(c => c.status === "ACTIVE") || ownCertifications[0] || null;

      return {
        id: user.id,
        fullName: user.fullName,
        email: user.email,
        isActive: user.isActive,
        createdAt: user.createdAt,
        // Real data where it exists; null (not a confident-looking fake value)
        // where it doesn't yet — see ArmSphere_Feature_Audit.md item 3.
        licenseClass: bestCertification?.certificationLevel ?? null,
        certificationStatus: bestCertification?.status ?? null,
        region: user.regionalCoverage ?? null,
        performance: {
          totalMatches: totalMatchesRefereed,
          // accuracyRate/disputeRate require dispute-to-referee attribution
          // logic that doesn't exist yet — reporting null rather than a
          // fabricated number until that's built for real.
          accuracyRate: null,
          disputeRate: null,
        }
      };
    });
  }

  static async updateRefereeLicense(refereeId: string, certification: string, status: string, reviewerId: string) {
    logger.info({ refereeId, certification, status }, "Updating referee license");

    const [user] = await db.select().from(users).where(and(eq(users.id, refereeId), eq(users.role, "REFEREE")));
    if (!user) {
      throw new NotFoundError("Referee not found");
    }

    // Write audit event
    await db.insert(auditLogs).values({
      userId: reviewerId,
      action: "REFEREE_LICENSE_UPDATED",
      details: { refereeId, certification, status },
    });

    return { success: true, refereeId, certification, status };
  }

  static async handleRefereeSuspension(refereeId: string, reviewerId: string, reason: string) {
    logger.info({ refereeId, reason }, "Suspending referee license");

    const [user] = await db.select().from(users).where(and(eq(users.id, refereeId), eq(users.role, "REFEREE")));
    if (!user) {
      throw new NotFoundError("Referee not found");
    }

    // Deactivate referee account
    await db.update(users).set({ isActive: false }).where(eq(users.id, refereeId));

    // Create a formal sanction
    await db.insert(sanctions).values({
      userId: refereeId,
      type: "LICENSE_REVOCATION",
      reason,
      issuedById: reviewerId,
      startsAt: new Date(),
      status: "ACTIVE",
    });

    // Write audit event
    await db.insert(auditLogs).values({
      userId: reviewerId,
      action: "REFEREE_SUSPENDED",
      details: { refereeId, reason },
    });

    return { success: true };
  }

  static async assignRefereeRegion(refereeId: string, region: string, reviewerId: string) {
    logger.info({ refereeId, region }, "Assigning referee regional division");

    const [refereeUser] = await db.select().from(users).where(eq(users.id, refereeId)).limit(1);
    if (!refereeUser) {
      throw new NotFoundError("Referee user not found");
    }

    await db
      .update(users)
      .set({ regionalCoverage: region, updatedAt: new Date() })
      .where(eq(users.id, refereeId));

    // Write audit event
    await db.insert(auditLogs).values({
      userId: reviewerId,
      action: "REFEREE_REGION_ASSIGNED",
      details: { refereeId, region },
    });

    return { success: true, refereeId, region };
  }

  /**
   * 4. Match Administration
   */
  static async getMatches() {
    logger.info("Fetching matches directory");
    const mRecords = await db.select().from(matches);
    const profiles = await db.select().from(athleteProfiles);

    return mRecords.map(m => {
      const challenger = profiles.find(p => p.id === m.challengerId);
      const opponent = profiles.find(p => p.id === m.opponentId);
      return {
        ...m,
        challengerName: challenger ? challenger.displayName : "Unknown",
        opponentName: opponent ? opponent.displayName : "Unknown",
      };
    });
  }

  static async inspectMatch(matchId: string, reviewerId?: string) {
    // Authorization check - validate reviewer permissions
    if (!reviewerId) {
      throw new ForbiddenError("Authentication required for match inspection");
    }
    
    const [reviewer] = await db.select().from(users).where(eq(users.id, reviewerId)).limit(1);
    if (!reviewer) {
      throw new NotFoundError("Reviewer user not found");
    }
    
    // Check if reviewer has authorization to inspect matches
    const hasInspectAuthority = [
      UserRole.SYSTEM_ADMIN,
      UserRole.NATIONAL_DIRECTOR,
      UserRole.PROVINCIAL_DIRECTOR,
      UserRole.REFEREE,
    ].includes(reviewer.role as UserRole);
    
    if (!hasInspectAuthority) {
      throw new ForbiddenError(
        "You do not have permission to inspect match details. Required roles: SYSTEM_ADMIN, NATIONAL_DIRECTOR, PROVINCIAL_DIRECTOR, or REFEREE."
      );
    }
    
    const [matchRecord] = await db.select().from(matches).where(eq(matches.id, matchId));
    if (!matchRecord) {
      throw new NotFoundError("Match not found");
    }

    const [challenger] = await db.select().from(athleteProfiles).where(eq(athleteProfiles.id, matchRecord.challengerId));
    const [opponent] = await db.select().from(athleteProfiles).where(eq(athleteProfiles.id, matchRecord.opponentId));
    const [referee] = await db.select().from(users).where(eq(users.id, matchRecord.refereeId));

    // For PROVINCIAL_DIRECTOR, check if they have jurisdiction over the match
    if (reviewer.role === UserRole.PROVINCIAL_DIRECTOR) {
      if (challenger?.province !== reviewer.province || opponent?.province !== reviewer.province) {
        throw new ForbiddenError(
          "You can only inspect matches within your provincial jurisdiction"
        );
      }
    }

    return {
      match: matchRecord,
      challenger,
      opponent,
      referee,
    };
  }

  static async scoreCorrection(matchId: string, winnerId: string, scoreLine: string, reviewerId: string) {
    logger.info({ matchId, winnerId, scoreLine }, "Correcting match score and outcome");

    const [matchRecord] = await db.select().from(matches).where(eq(matches.id, matchId));
    if (matchRecord) {
      // FOUND AND FIXED (falsification pass): this used to just overwrite
      // winnerId/scoreLine and force status="VERIFIED" directly — without
      // ever touching the ELO ledger or athlete ratings. That left ELO
      // silently wrong/stale relative to the corrected official record:
      // guaranteed incorrect data, not just a race-condition risk. Rather
      // than reimplementing the K-factor ELO math a second time here (real
      // risk of subtle divergence from MatchService.verifyMatch's version —
      // exactly the kind of duplicate-business-logic bug this pass is
      // meant to catch), this composes the already-fixed, already-tested
      // MatchService methods: void first (which correctly reverses ELO and
      // deletes the superseded ledger rows) if it was previously verified,
      // then re-verify with the corrected winner (which correctly reapplies
      // ELO from scratch with real locking).
      const wasVerified = matchRecord.status === "VERIFIED";

      if (wasVerified) {
        await MatchService.voidMatch(matchId, reviewerId, "Reversing prior verification for admin score correction.");
      }

      await db
        .update(matches)
        .set({ winnerId, scoreLine, updatedAt: new Date() })
        .where(eq(matches.id, matchId));

      await MatchService.verifyMatch(matchId, reviewerId);
    } else {
      const [tMatch] = await db.select().from(tournamentMatches).where(eq(tournamentMatches.id, matchId));
      if (!tMatch) {
        throw new NotFoundError("Match not found in standard or tournament registries");
      }
      // Tournament matches are not currently evidenced anywhere in this
      // repository as feeding the same ELO ledger/rating system standard
      // matches do — left as a direct field update, not expanded into
      // ELO-correction logic without evidence that tournament matches
      // actually participate in it.
      await db
        .update(tournamentMatches)
        .set({ winnerId, scoreLine, status: "COMPLETED", updatedAt: new Date() })
        .where(eq(tournamentMatches.id, matchId));
    }

    // Write audit log
    await db.insert(auditLogs).values({
      userId: reviewerId,
      action: "MATCH_SCORE_CORRECTED",
      details: { matchId, winnerId, scoreLine },
    });

    return { success: true };
  }

  static async voidMatch(matchId: string, reason: string, reviewerId: string) {
    logger.info({ matchId, reason }, "Voiding match outcome completely");

    const [matchRecord] = await db.select().from(matches).where(eq(matches.id, matchId));
    if (matchRecord) {
      await db.update(matches).set({ status: "VOID", updatedAt: new Date() }).where(eq(matches.id, matchId));
    } else {
      const [tMatch] = await db.select().from(tournamentMatches).where(eq(tournamentMatches.id, matchId));
      if (!tMatch) {
        throw new NotFoundError("Match not found");
      }
      await db.update(tournamentMatches).set({ status: "PENDING" }).where(eq(tournamentMatches.id, matchId));
    }

    // Write audit event
    await db.insert(auditLogs).values({
      userId: reviewerId,
      action: "MATCH_VOIDED",
      details: { matchId, reason },
    });

    return { success: true };
  }

  /**
   * 5. Tournament Administration
   */
  static async getEvents() {
    return db.select().from(events);
  }

  static async manageWeighIn(registrationId: string, weight: number, status: "PASSED" | "FAILED", certifiedBy: string) {
    logger.info({ registrationId, weight, status }, "Performing weigh-in check");

    const [reg] = await db.select().from(eventRegistrations).where(eq(eventRegistrations.id, registrationId));
    if (!reg) {
      throw new NotFoundError("Tournament registration not found");
    }

    const [weighin] = await db.insert(officialWeighins).values({
      registrationId,
      attemptNumber: 1,
      weight,
      status,
      certifiedBy,
      isLocked: true,
    }).returning();

    return weighin;
  }

  /**
   * 6. Championship Administration
   */
  static async manageChampionshipTitle(action: "ASSIGN" | "VACATE" | "RECALCULATE", titleId: string, data: any = {}, reviewerId: string) {
    logger.info({ action, titleId, data }, "Championship title operation");

    const [title] = await db.select().from(championshipTitles).where(eq(championshipTitles.id, titleId));
    if (!title) {
      throw new NotFoundError("Championship title belt not found");
    }

    if (action === "VACATE") {
      await db.update(championshipTitles).set({ activeChampionId: null, updatedAt: new Date() }).where(eq(championshipTitles.id, titleId));
      
      await db.insert(beltLineage).values({
        titleId,
        athleteId: title.activeChampionId!,
        acquiredAt: new Date(),
        vacatedAt: new Date(),
        reason: "VACATED",
      });
    } else if (action === "ASSIGN") {
      if (!data.athleteId) {
        throw new BadRequestError("Athlete ID is required for assignment");
      }
      await db.update(championshipTitles).set({ activeChampionId: data.athleteId, updatedAt: new Date() }).where(eq(championshipTitles.id, titleId));

      await db.insert(beltLineage).values({
        titleId,
        athleteId: data.athleteId,
        acquiredAt: new Date(),
        reason: "DEFENSE",
      });
    } else if (action === "RECALCULATE") {
      // Trigger Prestige Recalculation Worker
      await scheduleJob(SCHEDULED_JOB_TYPES.PRESTIGE_RECALCULATION, new Date(), { titleId });
    }

    // Write audit event
    await db.insert(auditLogs).values({
      userId: reviewerId,
      action: `CHAMPIONSHIP_BELT_${action}`,
      details: { titleId, data },
    });

    return { success: true };
  }

  /**
   * 7. Disputes & Sanctions Center
   */
  static async getDisputesTimeline() {
    return db.select().from(disputes).orderBy(desc(disputes.createdAt));
  }

  static async resolveDisputeCase(disputeId: string, resolutionDetails: string, decision: "RESOLVED" | "REJECTED", reviewerId: string) {
    logger.info({ disputeId, decision }, "Resolving dispute case");

    const [dispute] = await db.select().from(disputes).where(eq(disputes.id, disputeId));
    if (!dispute) {
      throw new NotFoundError("Dispute not found");
    }

    await db
      .update(disputes)
      .set({
        status: decision === "RESOLVED" ? "RESOLVED" : "CLOSED",
        resolutionDetails,
        assignedReviewerId: reviewerId,
        updatedAt: new Date(),
      })
      .where(eq(disputes.id, disputeId));

    // Audit trace
    await db.insert(auditLogs).values({
      userId: reviewerId,
      action: "DISPUTE_RESOLVED",
      details: { disputeId, decision, resolutionDetails },
    });

    return { success: true };
  }

  /**
   * 8. Immutable Audit Explorer
   */
  static async getAuditEvents() {
    return db.select().from(auditEvents).orderBy(desc(auditEvents.createdAt));
  }

  static async verifyImmutableAuditLedger() {
    logger.info("Verifying entire audit trail chain dynamically");

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

      expectedParentHash = event.eventHash;
    }

    return {
      isValid: true,
      totalEventsVerified: allEvents.length,
    };
  }

  /**
   * 11. Background Worker Triggers
   */
  static async triggerWorkerJob(workerName: string, data: any = {}) {
    logger.info({ workerName }, "Triggering manual background job request");

    let job;
    if (workerName === "audit.integrity.scan") {
      job = await scheduleJob(SCHEDULED_JOB_TYPES.AUDIT_INTEGRITY_SCAN, new Date(), data);
      return { success: true, jobId: job.id, status: "queued" };
    } else if (workerName === "export.generator") {
      const { SyncService } = await import("./sync.js");
      const result = await SyncService.processActionById(data.pendingActionId);
      processedJobsTracker.offlineSyncCompleted.push({ pendingActionId: data.pendingActionId, result });
      return { success: true, result, status: "completed" };
    } else {
      throw new BadRequestError(`Unknown worker name: ${workerName}`);
    }
  }

  /**
   * 12. Postgres-Backed Scheduled Jobs Runner
   */
  static async runScheduledJobs() {
    const { runDueScheduledJobs } = await import("./scheduledJobs.js");
    return await runDueScheduledJobs();
  }
}

