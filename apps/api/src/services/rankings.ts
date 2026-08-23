import { eq, and, or, desc, asc, lt, gte, sql } from "drizzle-orm";
import { db } from "../config/db.js";
import { athleteProfiles, rankingSnapshots } from "@armsphere/db-schema";
import { BadRequestError, NotFoundError, logger } from "@armsphere/core";

export interface LeaderboardFilter {
  arm: "LEFT" | "RIGHT";
  division?: "JUNIOR" | "SENIOR" | "FEMALE";
  weightClass?: string;
  country?: string;
  province?: string;
  clubId?: string;
  search?: string;
  limit?: number;
  cursor?: string; // encoded as "elo_athleteId"
}

export interface LeaderboardResult {
  items: Array<{
    rank: number;
    athleteId: string;
    displayName: string;
    eloRating: number;
    clubId: string | null;
    province: string | null;
    country: string | null;
    division: string;
    weightClass: string;
  }>;
  nextCursor?: string;
}

const leaderboardCache = new Map<string, { value: string; expiresAt: number }>();

export class RankingsService {
  /**
   * Retrieves high-performance cached leaderboard listings
   */
  static async getLeaderboard(filter: LeaderboardFilter): Promise<LeaderboardResult> {
    const {
      arm,
      division = "SENIOR",
      weightClass,
      country,
      province,
      clubId,
      search,
      limit = 20,
      cursor,
    } = filter;

    const cacheKey = `leaderboard:${arm}:${division}:${weightClass || "ALL"}:${country || "ALL"}:${province || "ALL"}:${clubId || "ALL"}:${search || "ALL"}:${limit}:${cursor || "NONE"}`;

    const cached = leaderboardCache.get(cacheKey);
    if (cached && Date.now() < cached.expiresAt) {
      logger.debug({ cacheKey }, "Leaderboard cache hit");
      return JSON.parse(cached.value);
    }

    // Build DB conditions
    const conditions = [];

    // Filter by arm ratings
    // Note: Since ELO is stored on the athleteProfile (leftArmElo and rightArmElo)
    const eloField = arm === "LEFT" ? athleteProfiles.leftArmElo : athleteProfiles.rightArmElo;

    // Standard conditions
    conditions.push(eq(athleteProfiles.isDeleted, false));

    if (province) {
      conditions.push(eq(athleteProfiles.province, province));
    }
    if (clubId) {
      conditions.push(eq(athleteProfiles.clubId, clubId));
    }

    // Search query on display name
    if (search) {
      conditions.push(sql`LOWER(${athleteProfiles.displayName}) LIKE ${`%${search.toLowerCase()}%`}`);
    }

    // Cursor conditions for pagination: eloRating_athleteId (descending ELO, ascending ID)
    if (cursor) {
      const [cursorEloStr, cursorAthleteId] = cursor.split("_");
      const cursorElo = parseInt(cursorEloStr, 10);
      if (!isNaN(cursorElo) && cursorAthleteId) {
        conditions.push(
          or(
            lt(eloField, cursorElo),
            and(
              eq(eloField, cursorElo),
              sql`${athleteProfiles.id} > ${cursorAthleteId}`
            )
          )
        );
      }
    }

    // Execute query with limit + 1 to check for next page
    const records = await db
      .select({
        id: athleteProfiles.id,
        displayName: athleteProfiles.displayName,
        leftArmElo: athleteProfiles.leftArmElo,
        rightArmElo: athleteProfiles.rightArmElo,
        clubId: athleteProfiles.clubId,
        province: athleteProfiles.province,
      })
      .from(athleteProfiles)
      .where(and(...conditions))
      .orderBy(desc(eloField), asc(athleteProfiles.id))
      .limit(limit + 1);

    console.log("LEADERBOARD RECORDS FOUND FOR CURSOR:", cursor, "->", records.map(r => r.id));

    // Calculate ranking offset (or simple relative rank starting from 1 for the view slice)
    // Map database records to result format
    const hasNext = records.length > limit;
    const itemsToReturn = records.slice(0, limit);

    const items = itemsToReturn.map((rec, index) => {
      const eloRating = arm === "LEFT" ? rec.leftArmElo : rec.rightArmElo;
      return {
        rank: index + 1, // Relative rank inside this filtered view
        athleteId: rec.id,
        displayName: rec.displayName,
        eloRating,
        clubId: rec.clubId,
        province: rec.province,
        country: "Canada",
        division,
        weightClass: weightClass || "OPEN",
      };
    });

    let nextCursor: string | undefined;
    if (hasNext && items.length > 0) {
      const lastItem = items[items.length - 1];
      nextCursor = `${lastItem.eloRating}_${lastItem.athleteId}`;
    }

    const result: LeaderboardResult = { items, nextCursor };

    // Store in cache for 5 minutes
    leaderboardCache.set(cacheKey, {
      value: JSON.stringify(result),
      expiresAt: Date.now() + 300 * 1000,
    });

    return result;
  }

  /**
   * Generates a ranking snapshot for historical tracking and movement analysis
   */
  static async generateRankingSnapshot(
    snapshotType: "DAILY" | "WEEKLY" | "SEASONAL",
    arm: "LEFT" | "RIGHT",
    division: "JUNIOR" | "SENIOR" | "FEMALE",
    weightClass = "OPEN"
  ) {
    logger.info({ snapshotType, arm, division, weightClass }, "Commencing ranking snapshot execution");

    const snapshotDate = new Date();
    const eloField = arm === "LEFT" ? athleteProfiles.leftArmElo : athleteProfiles.rightArmElo;

    // Fetch all active profiles
    const profiles = await db
      .select({
        id: athleteProfiles.id,
        leftArmElo: athleteProfiles.leftArmElo,
        rightArmElo: athleteProfiles.rightArmElo,
      })
      .from(athleteProfiles)
      .where(eq(athleteProfiles.isDeleted, false))
      .orderBy(desc(eloField), asc(athleteProfiles.id));

    // Fetch previous snapshots to calculate movement
    const [previousSnapshot] = await db
      .select()
      .from(rankingSnapshots)
      .where(
        and(
          eq(rankingSnapshots.snapshotType, snapshotType),
          eq(rankingSnapshots.arm, arm),
          eq(rankingSnapshots.division, division),
          eq(rankingSnapshots.weightClass, weightClass)
        )
      )
      .orderBy(desc(rankingSnapshots.snapshotDate))
      .limit(1);

    const previousRanksMap = new Map<string, number>();
    if (previousSnapshot) {
      // Find all snapshots of this snapshotDate
      const prevEntries = await db
        .select()
        .from(rankingSnapshots)
        .where(eq(rankingSnapshots.snapshotDate, previousSnapshot.snapshotDate));
      prevEntries.forEach((entry) => {
        previousRanksMap.set(entry.athleteId, entry.rank);
      });
    }

    const snapshotRecords: any[] = [];

    for (let i = 0; i < profiles.length; i++) {
      const p = profiles[i];
      const eloRating = arm === "LEFT" ? p.leftArmElo : p.rightArmElo;
      const rank = i + 1;
      const prevRank = previousRanksMap.get(p.id);

      let rankMovement: "UP" | "DOWN" | "NEW" | "UNCHANGED" = "UNCHANGED";
      if (prevRank === undefined) {
        rankMovement = "NEW";
      } else if (rank < prevRank) {
        rankMovement = "UP";
      } else if (rank > prevRank) {
        rankMovement = "DOWN";
      }

      const record = {
        athleteId: p.id,
        snapshotType,
        arm,
        division,
        weightClass,
        eloRating,
        rank,
        previousRank: prevRank || null,
        rankMovement,
        snapshotDate,
      };

      snapshotRecords.push(record);
    }

    // Batch insert inside a transaction
    if (snapshotRecords.length > 0) {
      await db.transaction(async (tx) => {
        for (const record of snapshotRecords) {
          await tx.insert(rankingSnapshots).values(record);
        }
      });
    }

    logger.info({ snapshotType, arm, recordsCount: snapshotRecords.length }, "Completed ranking snapshot successfully");

    return { success: true, count: snapshotRecords.length };
  }
}
