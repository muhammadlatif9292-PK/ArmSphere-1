import { Request, Response, NextFunction } from "express";
import { CommunityService } from "../services/community.js";
import { StorageService } from "../services/storage.js";
import { z } from "zod";
import { BadRequestError } from "@armsphere/core";
import { db } from "../config/db.js";
import { athleteProfiles } from "@armsphere/db-schema";
import { eq, and } from "drizzle-orm";

// Validation Schemas
const submitLinkSchema = z.object({
  externalUrl: z.string().url("Invalid external URL"),
  category: z.string().optional().nullable(),
  caption: z.string().optional().nullable(),
  matchId: z.string().uuid("Invalid match ID").optional().nullable(),
  exerciseType: z.string().optional().nullable(),
  weightKg: z.coerce.number().optional().nullable(),
  reps: z.coerce.number().int().optional().nullable(),
});

const moderateLinkSchema = z.object({
  decision: z.enum(["APPROVED", "REJECTED"]),
});

const feedQuerySchema = z.object({
  limit: z.coerce.number().int().positive().default(20),
  cursor: z.string().optional(),
  category: z.string().optional(),
});

const createCommentSchema = z.object({
  body: z.string().min(1, "Comment body must not be empty"),
});

export class CommunityController {
  /**
   * Helper to resolve the active athlete profile ID for a given user ID
   */
  private static async getAthleteProfileIdForUser(userId: string): Promise<string> {
    const [profile] = await db
      .select({ id: athleteProfiles.id })
      .from(athleteProfiles)
      .where(and(eq(athleteProfiles.userId, userId), eq(athleteProfiles.isDeleted, false)))
      .limit(1);

    if (!profile) {
      throw new BadRequestError("An active athlete profile is required to perform this action");
    }
    return profile.id;
  }

  /**
   * Submit a community video link
   */
  static async submitLink(req: Request, res: Response, next: NextFunction) {
    try {
      const athleteId = await CommunityController.getAthleteProfileIdForUser(req.user!.id);
      const validated = submitLinkSchema.parse(req.body);

      const post = await CommunityService.submitLink(
        athleteId,
        validated.externalUrl,
        validated.category,
        validated.caption,
        validated.matchId,
        validated.exerciseType,
        validated.weightKg,
        validated.reps
      );

      res.status(201).json({
        success: true,
        data: post,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Moderate a link submission
   */
  static async moderateLinkSubmission(req: Request, res: Response, next: NextFunction) {
    try {
      const { id: postId } = req.params;
      const validated = moderateLinkSchema.parse(req.body);
      const moderatorId = req.user!.id;

      const updated = await CommunityService.moderateLinkSubmission(
        postId,
        moderatorId,
        validated.decision
      );

      res.status(200).json({
        success: true,
        data: updated,
        message: `Post ${validated.decision.toLowerCase()} successfully`,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Get pending community link submissions for moderation
   */
  static async getPendingSubmissions(req: Request, res: Response, next: NextFunction) {
    try {
      const limit = req.query.limit ? parseInt(req.query.limit as string, 10) : undefined;
      const cursor = req.query.cursor as string | undefined;

      const submissions = await CommunityService.getPendingSubmissions({ limit, cursor });

      res.status(200).json({
        success: true,
        data: submissions,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Get community feed (paginated)
   */
  static async getFeed(req: Request, res: Response, next: NextFunction) {
    try {
      const validated = feedQuerySchema.parse(req.query);
      const athleteId = await CommunityController.getAthleteProfileIdForUser(req.user!.id);

      const feed = await CommunityService.getFeed({
        limit: validated.limit,
        cursor: validated.cursor,
        category: validated.category,
        viewerAthleteId: athleteId,
      });

      res.status(200).json({
        success: true,
        data: feed,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Delete a post
   */
  static async deletePost(req: Request, res: Response, next: NextFunction) {
    try {
      const athleteId = await CommunityController.getAthleteProfileIdForUser(req.user!.id);
      const { id: postId } = req.params;

      const post = await CommunityService.deletePost(athleteId, postId);

      res.status(200).json({
        success: true,
        data: post,
        message: "Post deleted successfully",
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Like a post
   */
  static async likePost(req: Request, res: Response, next: NextFunction) {
    try {
      const athleteId = await CommunityController.getAthleteProfileIdForUser(req.user!.id);
      const { id: postId } = req.params;

      const like = await CommunityService.likePost(athleteId, postId);

      res.status(201).json({
        success: true,
        data: like,
        message: "Post liked successfully",
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Unlike a post
   */
  static async unlikePost(req: Request, res: Response, next: NextFunction) {
    try {
      const athleteId = await CommunityController.getAthleteProfileIdForUser(req.user!.id);
      const { id: postId } = req.params;

      const like = await CommunityService.unlikePost(athleteId, postId);

      res.status(200).json({
        success: true,
        data: like,
        message: "Post unliked successfully",
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Add a comment to a post
   */
  static async addComment(req: Request, res: Response, next: NextFunction) {
    try {
      const athleteId = await CommunityController.getAthleteProfileIdForUser(req.user!.id);
      const { id: postId } = req.params;
      const validated = createCommentSchema.parse(req.body);

      const comment = await CommunityService.addComment(athleteId, postId, validated.body);

      res.status(201).json({
        success: true,
        data: comment,
        message: "Comment added successfully",
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Get comments of a post
   */
  static async getComments(req: Request, res: Response, next: NextFunction) {
    try {
      const { id: postId } = req.params;

      const comments = await CommunityService.getComments(postId);

      res.status(200).json({
        success: true,
        data: comments,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Get an athlete's training log (GYM posts with exercise data)
   */
  static async getTrainingLog(req: Request, res: Response, next: NextFunction) {
    try {
      const { id: athleteId } = req.params;
      const exerciseType = req.query.exerciseType as string | undefined;

      const log = await CommunityService.getTrainingLog(athleteId, exerciseType);

      res.status(200).json({
        success: true,
        data: log,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Get an athlete's training log personal records (PRs)
   */
  static async getTrainingLogPRs(req: Request, res: Response, next: NextFunction) {
    try {
      const { id: athleteId } = req.params;

      const prs = await CommunityService.getTrainingLogPRs(athleteId);

      res.status(200).json({
        success: true,
        data: prs,
      });
    } catch (error) {
      next(error);
    }
  }

}
