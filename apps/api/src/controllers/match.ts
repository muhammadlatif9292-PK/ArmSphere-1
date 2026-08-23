import { Request, Response, NextFunction } from "express";
import { MatchService, CreateMatchInput } from "../services/match.js";
import { z } from "zod";
import { BadRequestError, ForbiddenError } from "@armsphere/core";

// Validation Schemas
const submitMatchSchema = z.object({
  challengerId: z.string().uuid("Challenger ID must be a valid UUID"),
  opponentId: z.string().uuid("Opponent ID must be a valid UUID"),
  arm: z.enum(["LEFT", "RIGHT", "left", "right"]),
  winnerId: z.string().uuid("Winner ID must be a valid UUID"),
  scoreLine: z.string().min(3, "Score line must be at least 3 characters"),
  evidenceUrl: z.string().url("Evidence URL must be a valid URL").optional(),
});

const disputeMatchSchema = z.object({
  reason: z.string().min(5, "Reason for dispute must be at least 5 characters"),
});

const voidMatchSchema = z.object({
  reason: z.string().min(5, "Reason for voiding must be at least 5 characters"),
});

const getRecentMatchesQuerySchema = z.object({
  limit: z.preprocess((val) => (val ? parseInt(val as string, 10) : 20), z.number().min(1).max(100)).default(20),
  offset: z.preprocess((val) => (val ? parseInt(val as string, 10) : 0), z.number().min(0)).default(0),
});


export class MatchController {
  /**
   * Post a new competitive match outcome (submitted by an authorized official: referee, provincial/national director, or system admin — not by match participants themselves)
   */
  static async submitMatch(req: Request, res: Response, next: NextFunction) {
    try {
      const validated = submitMatchSchema.parse(req.body) as CreateMatchInput;
      const refereeId = req.user!.id;
      const idempotencyKey = req.headers["x-idempotency-key"] as string | undefined;

      const match = await MatchService.createMatch(refereeId, validated, idempotencyKey);

      res.status(202).json({
        success: true,
        matchId: match.id,
        status: match.status,
        data: match,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Retrieve details of a specific match by ID
   */
  static async getMatch(req: Request, res: Response, next: NextFunction) {
    try {
      const matchId = req.params.id;
      const match = await MatchService.getMatchById(matchId);

      res.status(200).json({
        success: true,
        data: match,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Verify and close a pending match, updating athlete ELO scores
   */
  static async verifyMatch(req: Request, res: Response, next: NextFunction) {
    try {
      const matchId = req.params.id;
      const reviewerId = req.user!.id;

      const result = await MatchService.verifyMatch(matchId, reviewerId);

      res.status(200).json({
        success: true,
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Initiate federation dispute for a match
   */
  static async disputeMatch(req: Request, res: Response, next: NextFunction) {
    try {
      const matchId = req.params.id;
      const validated = disputeMatchSchema.parse(req.body);
      const actorId = req.user!.id;

      const updated = await MatchService.disputeMatch(matchId, actorId, validated.reason);

      res.status(200).json({
        success: true,
        data: updated,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Admin-only voiding operation that reverses rating adjustments
   */
  static async voidMatch(req: Request, res: Response, next: NextFunction) {
    try {
      const matchId = req.params.id;
      const validated = voidMatchSchema.parse(req.body);
      const actorId = req.user!.id;

      const updated = await MatchService.voidMatch(matchId, actorId, validated.reason);

      res.status(200).json({
        success: true,
        data: updated,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Retrieve paginated recent completed matches
   */
  static async getRecentMatches(req: Request, res: Response, next: NextFunction) {
    try {
      const { limit, offset } = getRecentMatchesQuerySchema.parse(req.query);
      const matchesList = await MatchService.getRecentMatches({ limit, offset });

      res.status(200).json({
        success: true,
        data: matchesList,
      });
    } catch (error) {
      next(error);
    }
  }
}

