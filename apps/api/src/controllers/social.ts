import { Request, Response, NextFunction } from "express";
import { SocialService } from "../services/social.js";
import { z } from "zod";
import { BadRequestError } from "@armsphere/core";
import { db } from "../config/db.js";
import { athleteProfiles } from "@armsphere/db-schema";
import { eq, and } from "drizzle-orm";

// Validation Schemas
const followSchema = z.object({
  followingId: z.string().uuid("Invalid athlete ID to follow"),
});

const createTeamSchema = z.object({
  name: z.string().min(2, "Team name must be at least 2 characters"),
  description: z.string().optional(),
  foundedAt: z.string().optional(), // ISO string or date
  clubId: z.string().uuid("Invalid club ID format").optional(),
});

const addMemberSchema = z.object({
  athleteId: z.string().uuid("Invalid athlete ID format"),
  role: z.enum(["MEMBER", "CAPTAIN"]).default("MEMBER"),
});

const paginationSchema = z.object({
  limit: z.coerce.number().int().positive().default(50),
  offset: z.coerce.number().int().nonnegative().default(0),
});

export class SocialController {
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
   * Follow another athlete
   */
  static async follow(req: Request, res: Response, next: NextFunction) {
    try {
      const validated = followSchema.parse(req.body);
      const userId = req.user!.id;

      // Get the follower's athlete profile ID
      const followerId = await SocialController.getAthleteProfileIdForUser(userId);

      const followRecord = await SocialService.followAthlete(followerId, validated.followingId);

      res.status(201).json({
        success: true,
        data: followRecord,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Unfollow another athlete
   */
  static async unfollow(req: Request, res: Response, next: NextFunction) {
    try {
      const followingId = req.params.followingId;
      const userId = req.user!.id;

      // Get the follower's athlete profile ID
      const followerId = await SocialController.getAthleteProfileIdForUser(userId);

      const unfollowRecord = await SocialService.unfollowAthlete(followerId, followingId);

      res.status(200).json({
        success: true,
        data: unfollowRecord,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Get list of followers of an athlete (paginated)
   */
  static async getFollowers(req: Request, res: Response, next: NextFunction) {
    try {
      const athleteId = req.params.athleteId;
      const { limit, offset } = paginationSchema.parse(req.query);

      const followers = await SocialService.getFollowers(athleteId, limit, offset);

      res.status(200).json({
        success: true,
        data: followers,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Get list of athletes followed by an athlete (paginated)
   */
  static async getFollowing(req: Request, res: Response, next: NextFunction) {
    try {
      const athleteId = req.params.athleteId;
      const { limit, offset } = paginationSchema.parse(req.query);

      const following = await SocialService.getFollowing(athleteId, limit, offset);

      res.status(200).json({
        success: true,
        data: following,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Create a new team
   */
  static async createTeam(req: Request, res: Response, next: NextFunction) {
    try {
      const validated = createTeamSchema.parse(req.body);
      const userId = req.user!.id;
      const athleteId = await SocialController.getAthleteProfileIdForUser(userId);

      const team = await SocialService.createTeam(validated as any, athleteId);

      res.status(201).json({
        success: true,
        data: team,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Add member to a team
   */
  static async addTeamMember(req: Request, res: Response, next: NextFunction) {
    try {
      const teamId = req.params.teamId;
      const validated = addMemberSchema.parse(req.body);

      let callerAthleteId: string | undefined = undefined;
      try {
        callerAthleteId = await SocialController.getAthleteProfileIdForUser(req.user!.id);
      } catch (e) {
        // Ignore if user doesn't have an athlete profile (e.g. they are an admin)
      }

      const callingUser = {
        id: req.user!.id,
        role: req.user!.role,
        athleteId: callerAthleteId,
      };

      const membership = await SocialService.addTeamMember(
        teamId, 
        validated.athleteId, 
        validated.role,
        callingUser
      );

      res.status(201).json({
        success: true,
        data: membership,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Remove member from a team
   */
  static async removeTeamMember(req: Request, res: Response, next: NextFunction) {
    try {
      const { teamId, athleteId } = req.params;

      let callerAthleteId: string | undefined = undefined;
      try {
        callerAthleteId = await SocialController.getAthleteProfileIdForUser(req.user!.id);
      } catch (e) {
        // Ignore if user doesn't have an athlete profile (e.g. they are an admin)
      }

      const callingUser = {
        id: req.user!.id,
        role: req.user!.role,
        athleteId: callerAthleteId,
      };

      const removed = await SocialService.removeTeamMember(teamId, athleteId, callingUser);

      res.status(200).json({
        success: true,
        data: removed,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Get team details with club and joined members
   */
  static async getTeam(req: Request, res: Response, next: NextFunction) {
    try {
      const teamId = req.params.teamId;

      const team = await SocialService.getTeam(teamId);

      res.status(200).json({
        success: true,
        data: team,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Get all teams the calling user belongs to
   */
  static async getMyTeams(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = req.user!.id;
      const athleteId = await SocialController.getAthleteProfileIdForUser(userId);

      const teamsList = await SocialService.getMyTeams(athleteId);

      res.status(200).json({
        success: true,
        data: teamsList,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Check if caller is following a target athlete
   */
  static async getFollowStatus(req: Request, res: Response, next: NextFunction) {
    try {
      const followingId = req.params.followingId;
      const userId = req.user!.id;

      // Get the follower's athlete profile ID
      const followerId = await SocialController.getAthleteProfileIdForUser(userId);

      const isFollowing = await SocialService.isFollowing(followerId, followingId);

      res.status(200).json({
        success: true,
        data: {
          isFollowing,
        },
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Block another athlete
   */
  static async block(req: Request, res: Response, next: NextFunction) {
    try {
      const blockedId = req.params.athleteId;
      const userId = req.user!.id;

      const blockerId = await SocialController.getAthleteProfileIdForUser(userId);
      const blockRecord = await SocialService.blockAthlete(blockerId, blockedId);

      res.status(201).json({
        success: true,
        data: blockRecord,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Unblock another athlete
   */
  static async unblock(req: Request, res: Response, next: NextFunction) {
    try {
      const blockedId = req.params.athleteId;
      const userId = req.user!.id;

      const blockerId = await SocialController.getAthleteProfileIdForUser(userId);
      const unblockRecord = await SocialService.unblockAthlete(blockerId, blockedId);

      res.status(200).json({
        success: true,
        data: unblockRecord,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Get blocked users list (paginated)
   */
  static async getBlocked(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = req.user!.id;
      const blockerId = await SocialController.getAthleteProfileIdForUser(userId);
      const { limit, offset } = paginationSchema.parse(req.query);

      const blockedUsersList = await SocialService.getBlockedUsers(blockerId, limit, offset);

      res.status(200).json({
        success: true,
        data: blockedUsersList,
      });
    } catch (error) {
      next(error);
    }
  }
}
