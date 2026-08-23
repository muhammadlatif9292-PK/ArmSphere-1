import { eq } from "drizzle-orm";
import { db } from "../config/db.js";
import { athleteProfiles, matches, disputes } from "@armsphere/db-schema";

export interface AnalyticsOverview {
  totalMatches: number;
  totalDisputes: number;
  disputeRatePercentage: number;
  activeAthleteCount: number;
  matchVolumeOverTime: Array<{
    date: string;
    count: number;
  }>;
}

export interface EloDistributionItem {
  range: string;
  leftArmCount: number;
  rightArmCount: number;
}

export class AnalyticsService {
  /**
   * Computes high-level analytics overview metrics
   */
  static async getOverview(): Promise<AnalyticsOverview> {
    // Retrieve all matches to construct volume over time and total counts
    const matchesList = await db.select().from(matches);
    const disputesList = await db.select().from(disputes);
    const activeAthletesList = await db
      .select()
      .from(athleteProfiles)
      .where(eq(athleteProfiles.isDeleted, false));

    const totalMatches = matchesList.length;
    const totalDisputes = disputesList.length;
    const activeAthleteCount = activeAthletesList.length;

    // Calculate dispute rate percentage safely
    const disputeRate = totalMatches > 0 ? (totalDisputes / totalMatches) * 100 : 0.0;
    const disputeRatePercentage = Math.round(disputeRate * 100) / 100;

    // Match volume over time grouped by date
    const volumeMap: Record<string, number> = {};
    for (const match of matchesList) {
      if (match.createdAt) {
        const dateStr = new Date(match.createdAt).toISOString().split("T")[0];
        volumeMap[dateStr] = (volumeMap[dateStr] || 0) + 1;
      }
    }

    const matchVolumeOverTime = Object.entries(volumeMap)
      .map(([date, count]) => ({ date, count }))
      .sort((a, b) => a.date.localeCompare(b.date));

    return {
      totalMatches,
      totalDisputes,
      disputeRatePercentage,
      activeAthleteCount,
      matchVolumeOverTime,
    };
  }

  /**
   * Computes the distribution of ELO ratings grouped in histogram bins
   */
  static async getEloDistribution(): Promise<EloDistributionItem[]> {
    const activeAthletesList = await db
      .select()
      .from(athleteProfiles)
      .where(eq(athleteProfiles.isDeleted, false));

    const bins = [
      { label: "1000-1199", min: 1000, max: 1199 },
      { label: "1200-1399", min: 1200, max: 1399 },
      { label: "1400-1599", min: 1400, max: 1599 },
      { label: "1600-1799", min: 1600, max: 1799 },
      { label: "1800-1999", min: 1800, max: 1999 },
      { label: "2000-2199", min: 2000, max: 2199 },
      { label: "2200+", min: 2200, max: 999999 },
    ];

    return bins.map((bin) => {
      const leftArmCount = activeAthletesList.filter(
        (a) => a.leftArmElo >= bin.min && a.leftArmElo <= bin.max
      ).length;

      const rightArmCount = activeAthletesList.filter(
        (a) => a.rightArmElo >= bin.min && a.rightArmElo <= bin.max
      ).length;

      return {
        range: bin.label,
        leftArmCount,
        rightArmCount,
      };
    });
  }
}
