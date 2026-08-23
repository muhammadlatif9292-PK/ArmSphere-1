import { Request, Response, NextFunction } from "express";
import { ChampionshipService } from "../services/championship.js";
import { z } from "zod";

const createTitleSchema = z.object({
  name: z.string().min(5, "Title name must be at least 5 characters"),
  arm: z.enum(["LEFT", "RIGHT"]),
  division: z.enum(["JUNIOR", "SENIOR", "FEMALE"]),
  weightClass: z.string().min(2, "Weight class must be specified"),
});

const submitChallengeSchema = z.object({
  titleId: z.string().uuid("Title ID must be a valid UUID"),
  challengerId: z.string().uuid("Challenger ID must be a valid UUID"),
});

const defendTitleSchema = z.object({
  titleId: z.string().uuid("Title ID must be a valid UUID"),
  winnerId: z.string().uuid("Winner ID must be a valid UUID"),
  matchId: z.string().uuid("Match ID must be a valid UUID"),
});

const vacateTitleSchema = z.object({
  titleId: z.string().uuid("Title ID must be a valid UUID"),
  reason: z.enum(["STRIPPED", "VACATED"]).default("VACATED"),
});

export class ChampionshipController {
  /**
   * Admin-only title creation
   */
  static async createTitle(req: Request, res: Response, next: NextFunction) {
    try {
      const validated = createTitleSchema.parse(req.body);
      const title = await ChampionshipService.createTitle(
        validated.name,
        validated.arm,
        validated.division,
        validated.weightClass
      );

      res.status(201).json({
        success: true,
        data: title,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Submit a title challenge
   */
  static async submitChallenge(req: Request, res: Response, next: NextFunction) {
    try {
      const validated = submitChallengeSchema.parse(req.body);
      const challenge = await ChampionshipService.submitChallenge(
        validated.titleId,
        validated.challengerId
      );

      res.status(201).json({
        success: true,
        data: challenge,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Accept a title challenge
   */
  static async acceptChallenge(req: Request, res: Response, next: NextFunction) {
    try {
      const challengeId = req.params.challengeId;
      const updated = await ChampionshipService.updateChallengeStatus(challengeId, "ACCEPTED");

      res.status(200).json({
        success: true,
        data: updated,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Decline a title challenge
   */
  static async declineChallenge(req: Request, res: Response, next: NextFunction) {
    try {
      const challengeId = req.params.challengeId;
      const updated = await ChampionshipService.updateChallengeStatus(challengeId, "DECLINED");

      res.status(200).json({
        success: true,
        data: updated,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Register a title defense match outcome
   */
  static async defendTitle(req: Request, res: Response, next: NextFunction) {
    try {
      const validated = defendTitleSchema.parse(req.body);
      const result = await ChampionshipService.defendTitle(
        validated.titleId,
        validated.winnerId,
        validated.matchId,
        req.user!.id
      );

      res.status(200).json({
        success: true,
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Strips/Vacates championship title
   */
  static async vacateTitle(req: Request, res: Response, next: NextFunction) {
    try {
      const validated = vacateTitleSchema.parse(req.body);
      const result = await ChampionshipService.vacateTitle(validated.titleId, validated.reason);

      res.status(200).json({
        success: true,
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Retrieve belt lineage history
   */
  static async getLineageHistory(req: Request, res: Response, next: NextFunction) {
    try {
      const titleId = req.params.titleId;
      const history = await ChampionshipService.getLineageHistory(titleId);

      res.status(200).json({
        success: true,
        data: history,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Force recalculation of prestige scores and PFP lists
   */
  static async recomputePrestige(req: Request, res: Response, next: NextFunction) {
    try {
      await ChampionshipService.recomputePrestigeScores();

      res.status(200).json({
        success: true,
        message: "Pound-For-Pound ratings successfully recalculated",
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Retrieves all active (non-vacated) championship titles with current holders
   */
  static async getActiveTitles(req: Request, res: Response, next: NextFunction) {
    try {
      const titles = await ChampionshipService.getActiveTitles();

      res.status(200).json({
        success: true,
        data: titles,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Retrieves all championship challenges with optional status filtering
   */
  static async getChallenges(req: Request, res: Response, next: NextFunction) {
    try {
      const status = req.query.status as string | undefined;
      const challenges = await ChampionshipService.getChallenges({ status });

      res.status(200).json({
        success: true,
        data: challenges,
      });
    } catch (error) {
      next(error);
    }
  }
}
