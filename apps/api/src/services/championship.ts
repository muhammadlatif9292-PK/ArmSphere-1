import { eq, and, desc, asc, not, isNull } from "drizzle-orm";
import { db } from "../config/db.js";
import { 
  championshipTitles, 
  beltLineage, 
  championshipChallenges, 
  prestigeMetrics, 
  athleteProfiles,
  matches
} from "@armsphere/db-schema";
import { BadRequestError, NotFoundError, logger } from "@armsphere/core";
import { RefereeCertificationService } from "./refereeCertification.js";

export class ChampionshipService {
  /**
   * Defines and provisions a new Championship Title
   */
  static async createTitle(name: string, arm: "LEFT" | "RIGHT", division: "JUNIOR" | "SENIOR" | "FEMALE", weightClass: string) {
    logger.info({ name, arm, division, weightClass }, "Creating new championship title definition");

    const [newTitle] = await db
      .insert(championshipTitles)
      .values({
        name,
        arm,
        division,
        weightClass,
        activeChampionId: null,
      })
      .returning();

    logger.info({ titleId: newTitle.id, name }, "Created new title");

    return newTitle;
  }

  /**
   * Challenge active champion to a Title Bout
   */
  static async submitChallenge(titleId: string, challengerId: string) {
    const [title] = await db
      .select()
      .from(championshipTitles)
      .where(eq(championshipTitles.id, titleId))
      .limit(1);

    if (!title) {
      throw new NotFoundError("Championship Title not found");
    }

    if (title.activeChampionId === challengerId) {
      throw new BadRequestError("Active champion cannot challenge themselves!");
    }

    const [challenger] = await db
      .select()
      .from(athleteProfiles)
      .where(eq(athleteProfiles.id, challengerId))
      .limit(1);

    if (!challenger) {
      throw new NotFoundError("Challenger profile not found");
    }

    const [challenge] = await db
      .insert(championshipChallenges)
      .values({
        titleId,
        challengerId,
        status: "PENDING",
      })
      .returning();

    logger.info({ titleId, challengerId, challengeId: challenge.id }, "New championship challenge submitted");
    return challenge;
  }

  /**
   * Accepts, declines, or completes championship challenges
   */
  static async updateChallengeStatus(challengeId: string, status: "ACCEPTED" | "DECLINED" | "COMPLETED" | "EXPIRED") {
    const [challenge] = await db
      .select()
      .from(championshipChallenges)
      .where(eq(championshipChallenges.id, challengeId))
      .limit(1);

    if (!challenge) {
      throw new NotFoundError("Challenge not found");
    }

    const [updated] = await db
      .update(championshipChallenges)
      .set({ status, updatedAt: new Date() })
      .where(eq(championshipChallenges.id, challengeId))
      .returning();

    logger.info({ challengeId, status }, "Championship challenge status updated");
    return updated;
  }

  /**
   * Process title defenses, lineage propagation, and crowning events
   */
  static async defendTitle(titleId: string, winnerId: string, matchId: string, actorId?: string) {
    if (actorId) {
      await RefereeCertificationService.assertActiveCertification(actorId);
    }
    const [title] = await db
      .select()
      .from(championshipTitles)
      .where(eq(championshipTitles.id, titleId))
      .limit(1);

    if (!title) {
      throw new NotFoundError("Title not found");
    }

    const activeChampId = title.activeChampionId;
    if (!activeChampId) {
      throw new BadRequestError("Cannot defend a vacant title. Use crownChampion instead.");
    }

    const now = new Date();

    if (winnerId === activeChampId) {
      // 1. Champion retained title! Update active lineage defense count
      const [lineageRecord] = await db
        .select()
        .from(beltLineage)
        .where(
          and(
            eq(beltLineage.titleId, titleId),
            eq(beltLineage.athleteId, activeChampId),
            isNull(beltLineage.vacatedAt)
          )
        )
        .orderBy(desc(beltLineage.acquiredAt))
        .limit(1);

      if (lineageRecord) {
        await db
          .update(beltLineage)
          .set({
            defensesCount: lineageRecord.defensesCount + 1,
            updatedAt: now,
          })
          .where(eq(beltLineage.id, lineageRecord.id));
      }

      logger.info({ titleId, activeChampId, matchId }, "Champion successfully defended the title");
    } else {
      // 2. Challenger won! Crown new champion and update lineage records
      await db.transaction(async (tx) => {
        // End former champion reign
        await tx
          .update(beltLineage)
          .set({
            vacatedAt: now,
            reason: "LOST",
            updatedAt: now,
          })
          .where(
            and(
              eq(beltLineage.titleId, titleId),
              eq(beltLineage.athleteId, activeChampId),
              isNull(beltLineage.vacatedAt)
            )
          );

        // Start new champion reign
        await tx.insert(beltLineage).values({
          titleId,
          athleteId: winnerId,
          acquiredAt: now,
          reason: "DEFENSE",
          defensesCount: 0,
        });

        // Update active champion on title
        await tx
          .update(championshipTitles)
          .set({
            activeChampionId: winnerId,
            updatedAt: now,
          })
          .where(eq(championshipTitles.id, titleId));
      });

      logger.info({ titleId, formerChamp: activeChampId, newChamp: winnerId }, "Title transferred to challenger after bout victory");
    }

    // Run prestige score calculations asynchronously
    this.recomputePrestigeScores().catch((err) => {
      logger.error({ err }, "Prestige scores recomputation failed background process");
    });

    return { success: true };
  }

  /**
   * Strip or vacate a title (e.g. for inactivity or policy breaches)
   */
  static async vacateTitle(titleId: string, reason: "STRIPPED" | "VACATED" = "VACATED") {
    const [title] = await db
      .select()
      .from(championshipTitles)
      .where(eq(championshipTitles.id, titleId))
      .limit(1);

    if (!title) {
      throw new NotFoundError("Title not found");
    }

    const activeChampId = title.activeChampionId;
    if (!activeChampId) {
      return { success: true, message: "Title was already vacant" };
    }

    const now = new Date();

    await db.transaction(async (tx) => {
      // End lineage reign
      await tx
        .update(beltLineage)
        .set({
          vacatedAt: now,
          reason,
          updatedAt: now,
        })
        .where(
          and(
            eq(beltLineage.titleId, titleId),
            eq(beltLineage.athleteId, activeChampId),
            isNull(beltLineage.vacatedAt)
          )
        );

      // Set active champion to null
      await tx
        .update(championshipTitles)
        .set({
          activeChampionId: null,
          updatedAt: now,
        })
        .where(eq(championshipTitles.id, titleId));
    });

    logger.warn({ titleId, formerChamp: activeChampId, reason }, "Championship title has been vacated");

    // Automatic Succession Rule: highest rated ELO athlete in that category is crowned!
    await this.applyAutomaticSuccession(titleId);

    return { success: true };
  }

  /**
   * Apply automatic succession logic: highest-rated ELO athlete gets crowned
   */
  static async applyAutomaticSuccession(titleId: string) {
    const [title] = await db
      .select()
      .from(championshipTitles)
      .where(eq(championshipTitles.id, titleId))
      .limit(1);

    if (!title || title.activeChampionId) {
      return;
    }

    const eloField = title.arm === "LEFT" ? athleteProfiles.leftArmElo : athleteProfiles.rightArmElo;

    // Fetch top active athlete profile who isn't deleted
    const [successor] = await db
      .select()
      .from(athleteProfiles)
      .where(eq(athleteProfiles.isDeleted, false))
      .orderBy(desc(eloField), asc(athleteProfiles.id))
      .limit(1);

    if (successor) {
      const now = new Date();
      logger.info({ titleId, successorId: successor.id }, "Applying automatic succession rule to crown highest-rated athlete");

      await db.transaction(async (tx) => {
        await tx
          .update(championshipTitles)
          .set({
            activeChampionId: successor.id,
            updatedAt: now,
          })
          .where(eq(championshipTitles.id, titleId));

        await tx.insert(beltLineage).values({
          titleId,
          athleteId: successor.id,
          acquiredAt: now,
          reason: "SUCCESSION",
          defensesCount: 0,
        });
      });
    }
  }

  /**
   * Mathematical prestige scoring, defense multipliers, PFP ranking engine
   */
  static async recomputePrestigeScores() {
    logger.info("Recalculating Pound-For-Pound prestige scores and dominance metrics...");

    const profiles = await db
      .select()
      .from(athleteProfiles)
      .where(eq(athleteProfiles.isDeleted, false));

    const activeChampionships = await db
      .select()
      .from(championshipTitles)
      .where(not(isNull(championshipTitles.activeChampionId)));

    const titleMap = new Map<string, typeof championshipTitles.$inferSelect[]>();
    activeChampionships.forEach((title) => {
      if (title.activeChampionId) {
        const list = titleMap.get(title.activeChampionId) || [];
        list.push(title);
        titleMap.set(title.activeChampionId, list);
      }
    });

    const prestigeCalculations: any[] = [];

    for (const p of profiles) {
      // 1. Base ELO component
      const avgElo = (p.leftArmElo + p.rightArmElo) / 2;
      const baseEloPrestige = avgElo * 0.15;

      // 2. Title Reigns and defenses
      const heldTitles = titleMap.get(p.id) || [];
      const championshipBonus = heldTitles.length * 250;

      // Calculate total historical defenses
      const activeLineages = await db
        .select()
        .from(beltLineage)
        .where(
          and(
            eq(beltLineage.athleteId, p.id),
            isNull(beltLineage.vacatedAt)
          )
        );
      
      const defenseCount = activeLineages.reduce((sum, current) => sum + current.defensesCount, 0);
      const defenseMultiplierBonus = defenseCount * 75;

      // 3. Dominance metrics and win rates (dummy or historical match counting)
      // Standard dominance calculation: defenses count + ELO ratio
      const dominanceMetric = Math.min(100, (defenseCount * 15) + ((avgElo - 1000) / 10));

      const prestigeScore = baseEloPrestige + championshipBonus + defenseMultiplierBonus;

      prestigeCalculations.push({
        athleteId: p.id,
        prestigeScore,
        dominanceMetric,
      });
    }

    // Sort to assign PFP rank
    prestigeCalculations.sort((a, b) => b.prestigeScore - a.prestigeScore);

    // Save into database
    await db.transaction(async (tx) => {
      for (let i = 0; i < prestigeCalculations.length; i++) {
        const item = prestigeCalculations[i];
        const pfpRank = i + 1;

        // Upsert prestige record
        const [existing] = await tx
          .select()
          .from(prestigeMetrics)
          .where(eq(prestigeMetrics.athleteId, item.athleteId))
          .limit(1);

        if (existing) {
          await tx
            .update(prestigeMetrics)
            .set({
              prestigeScore: item.prestigeScore,
              pfpRank,
              dominanceMetric: item.dominanceMetric,
              updatedAt: new Date(),
            })
            .where(eq(prestigeMetrics.id, existing.id));
        } else {
          await tx.insert(prestigeMetrics).values({
            athleteId: item.athleteId,
            prestigeScore: item.prestigeScore,
            pfpRank,
            dominanceMetric: item.dominanceMetric,
          });
        }
      }
    });

    logger.info({ calculatedProfiles: prestigeCalculations.length }, "Pound-For-Pound rankings recalculation complete");
  }

  /**
   * Retrieves complete lineage history of a Championship Title with calculated reign durations
   */
  static async getLineageHistory(titleId: string) {
    const records = await db
      .select({
        id: beltLineage.id,
        athleteId: beltLineage.athleteId,
        displayName: athleteProfiles.displayName,
        acquiredAt: beltLineage.acquiredAt,
        vacatedAt: beltLineage.vacatedAt,
        reason: beltLineage.reason,
        defensesCount: beltLineage.defensesCount,
      })
      .from(beltLineage)
      .leftJoin(athleteProfiles, eq(beltLineage.athleteId, athleteProfiles.id))
      .where(eq(beltLineage.titleId, titleId))
      .orderBy(desc(beltLineage.acquiredAt));

    return records.map((r) => {
      const start = new Date(r.acquiredAt).getTime();
      const end = r.vacatedAt ? new Date(r.vacatedAt).getTime() : Date.now();
      const reignDays = Math.max(0, Math.floor((end - start) / (1000 * 60 * 60 * 24)));

      return {
        id: r.id,
        athleteId: r.athleteId,
        displayName: r.displayName || "Unknown Athlete",
        acquiredAt: r.acquiredAt,
        vacatedAt: r.vacatedAt,
        reason: r.reason,
        defensesCount: r.defensesCount,
        reignDays,
      };
    });
  }

  /**
   * Retrieves all non-vacated (active) championship titles with their current holder joined
   */
  static async getActiveTitles() {
    return db.query.championshipTitles.findMany({
      where: not(isNull(championshipTitles.activeChampionId)),
      with: {
        activeChampion: true,
      },
    });
  }

  /**
   * Retrieves title challenges, optionally filtered by status
   */
  static async getChallenges(filters?: { status?: string }) {
    const whereClause = filters?.status
      ? eq(championshipChallenges.status, filters.status)
      : undefined;

    return db.query.championshipChallenges.findMany({
      where: whereClause,
      with: {
        title: true,
        challenger: true,
      },
      orderBy: [desc(championshipChallenges.createdAt)],
    });
  }
}
