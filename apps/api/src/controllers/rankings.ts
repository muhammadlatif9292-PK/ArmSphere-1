import { Request, Response, NextFunction } from "express";
import { RankingsService } from "../services/rankings.js";
import { z } from "zod";
import { BadRequestError } from "@armsphere/core";

const leaderboardQuerySchema = z.object({
  arm: z.enum(["LEFT", "RIGHT"]).default("RIGHT"),
  division: z.enum(["JUNIOR", "SENIOR", "FEMALE"]).optional(),
  weightClass: z.string().optional(),
  country: z.string().optional(),
  province: z.string().optional(),
  clubId: z.string().uuid("Club ID must be a valid UUID").optional(),
  search: z.string().optional(),
  limit: z.preprocess((val) => (val ? parseInt(val as string, 10) : 20), z.number().min(1).max(100)).default(20),
  cursor: z.string().optional(),
});

const triggerSnapshotSchema = z.object({
  snapshotType: z.enum(["DAILY", "WEEKLY", "SEASONAL"]),
  arm: z.enum(["LEFT", "RIGHT"]),
  division: z.enum(["JUNIOR", "SENIOR", "FEMALE"]),
  weightClass: z.string().optional(),
});

export class RankingsController {
  /**
   * Retrieves paginated high-performance leaderboards
   */
  static async getLeaderboard(req: Request, res: Response, next: NextFunction) {
    try {
      const filter = leaderboardQuerySchema.parse(req.query);
      const result = await RankingsService.getLeaderboard(filter as any);

      res.status(200).json({
        success: true,
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Admin-only endpoint to trigger a ranking snapshot
   */
  static async triggerSnapshot(req: Request, res: Response, next: NextFunction) {
    try {
      const validated = triggerSnapshotSchema.parse(req.body);
      const result = await RankingsService.generateRankingSnapshot(
        validated.snapshotType,
        validated.arm,
        validated.division,
        validated.weightClass
      );

      res.status(201).json({
        success: true,
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }
}
