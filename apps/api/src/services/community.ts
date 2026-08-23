import { eq, and, desc, asc, lt, sql, or, notInArray, gte, isNotNull } from "drizzle-orm";
import { db } from "../config/db.js";
import { 
  communityPosts, 
  postLikes, 
  postComments, 
  athleteProfiles,
  matches,
  users,
  blockedUsers
} from "@armsphere/db-schema";
import { 
  NotFoundError, 
  BadRequestError, 
  ConflictError, 
  ForbiddenError 
} from "@armsphere/core";

export interface SubmitLinkPayload {
  externalUrl: string;
  category?: string | null;
  caption?: string | null;
  matchId?: string | null;
}

function detectPlatform(url: string): "YOUTUBE" | "TIKTOK" | "FACEBOOK" {
  const lower = url.toLowerCase();
  if (lower.includes("youtube.com") || lower.includes("youtu.be")) {
    return "YOUTUBE";
  }
  if (lower.includes("tiktok.com")) {
    return "TIKTOK";
  }
  if (lower.includes("facebook.com") || lower.includes("fb.watch")) {
    return "FACEBOOK";
  }
  throw new BadRequestError("Unsupported platform. Only YouTube, TikTok, and Facebook links are allowed.");
}

export class CommunityService {
  /**
   * Submit a community post video link
   */
  static async submitLink(
    athleteId: string,
    externalUrl: string,
    category?: string | null,
    caption?: string | null,
    matchId?: string | null,
    exerciseType?: string | null,
    weightKg?: number | null,
    reps?: number | null
  ) {
    // 1. Verify athlete profile exists and is active
    const [profile] = await db
      .select()
      .from(athleteProfiles)
      .where(and(eq(athleteProfiles.id, athleteId), eq(athleteProfiles.isDeleted, false)))
      .limit(1);

    if (!profile) {
      throw new NotFoundError("Athlete profile not found");
    }

    // 2. Verify platform from URL
    const platform = detectPlatform(externalUrl);

    // 3. Verify matchId if provided
    if (matchId) {
      const [match] = await db
        .select()
        .from(matches)
        .where(eq(matches.id, matchId))
        .limit(1);

      if (!match) {
        throw new NotFoundError("Associated match not found");
      }
    }

    // 4. Validate category if provided
    if (category && !["HIGHLIGHTS", "TUTORIALS", "GYM"].includes(category.toUpperCase())) {
      throw new BadRequestError("Invalid category. Allowed categories are HIGHLIGHTS, TUTORIALS, or GYM.");
    }

    // 5. Exercise/GYM Validation & Daily Limit Enforcements
    if (category?.toUpperCase() !== "GYM") {
      if (exerciseType || weightKg !== undefined && weightKg !== null || reps !== undefined && reps !== null) {
        throw new BadRequestError("Exercise fields are only allowed for posts in the GYM category.");
      }
    } else {
      if (!exerciseType) {
        throw new BadRequestError("exerciseType is required for GYM category posts.");
      }
      const VALID_EXERCISES = ['WRIST_CURL', 'HAMMER_CURL', 'PRESSOUT', 'CUPPING', 'TOPROLL', 'SIDE_PRESSURE', 'OTHER'];
      if (!VALID_EXERCISES.includes(exerciseType.toUpperCase())) {
        throw new BadRequestError(`Invalid exerciseType. Must be one of: ${VALID_EXERCISES.join(", ")}`);
      }
      if (weightKg !== undefined && weightKg !== null && weightKg < 0) {
        throw new BadRequestError("weightKg cannot be negative.");
      }
      if (reps !== undefined && reps !== null && reps < 0) {
        throw new BadRequestError("reps cannot be negative.");
      }

      // Enforce rolling 24-hour limit of 2 posts for GYM posts
      const oneDayAgo = new Date(Date.now() - 24 * 60 * 60 * 1000);
      const recentGymPosts = await db
        .select()
        .from(communityPosts)
        .where(
          and(
            eq(communityPosts.athleteId, athleteId),
            eq(communityPosts.category, "GYM"),
            eq(communityPosts.isDeleted, false),
            gte(communityPosts.createdAt, oneDayAgo)
          )
        );

      if (recentGymPosts && recentGymPosts.length >= 2) {
        throw new BadRequestError("Daily training post limit exceeded. You can only log up to 2 training posts per day.");
      }
    }

    // 6. Create post
    const [post] = await db
      .insert(communityPosts)
      .values({
        athleteId,
        externalUrl,
        platform,
        category: category ? (category.toUpperCase() as any) : null,
        caption: caption || null,
        matchId: matchId || null,
        exerciseType: exerciseType ? exerciseType.toUpperCase() : null,
        weightKg: weightKg !== undefined && weightKg !== null ? String(weightKg) : null,
        reps: reps || null,
        moderationStatus: "PENDING",
        isDeleted: false,
      })
      .returning();

    return post;
  }

  /**
   * Moderate a community link submission
   */
  static async moderateLinkSubmission(
    postId: string,
    moderatorId: string,
    decision: "APPROVED" | "REJECTED"
  ) {
    // 1. Verify moderator exists and check role
    const [moderator] = await db
      .select()
      .from(users)
      .where(eq(users.id, moderatorId))
      .limit(1);

    if (!moderator) {
      throw new NotFoundError("Moderator not found");
    }

    const allowedRoles = ["SYSTEM_ADMIN", "NATIONAL_DIRECTOR", "PROVINCIAL_DIRECTOR"];
    if (!allowedRoles.includes(moderator.role.toUpperCase())) {
      throw new ForbiddenError("Only admin-tier roles can moderate link submissions.");
    }

    // 2. Check if post exists and is not deleted
    const [post] = await db
      .select()
      .from(communityPosts)
      .where(and(eq(communityPosts.id, postId), eq(communityPosts.isDeleted, false)))
      .limit(1);

    if (!post) {
      throw new NotFoundError("Community post not found");
    }

    // 3. Update moderation status
    const [updated] = await db
      .update(communityPosts)
      .set({
        moderationStatus: decision,
        moderatedBy: moderatorId,
        moderatedAt: new Date(),
        updatedAt: new Date()
      })
      .where(eq(communityPosts.id, postId))
      .returning();

    return updated;
  }

  /**
   * Retrieve community feed with cursor-based pagination (only APPROVED posts)
   */
  static async getFeed(options: { limit?: number; cursor?: string; viewerAthleteId?: string; category?: string }) {
    const limit = options.limit || 20;
    const cursor = options.cursor;
    const viewerAthleteId = options.viewerAthleteId || "";
    const category = options.category;

    const conditions = [
      eq(communityPosts.isDeleted, false),
      eq(communityPosts.moderationStatus, "APPROVED")
    ];

    if (viewerAthleteId) {
      const blockedRelations = await db
        .select({
          blockedId: blockedUsers.blockedId,
          blockerId: blockedUsers.blockerId
        })
        .from(blockedUsers)
        .where(
          or(
            eq(blockedUsers.blockerId, viewerAthleteId),
            eq(blockedUsers.blockedId, viewerAthleteId)
          )
        );

      const excludedIds = blockedRelations.map(r => 
        r.blockerId === viewerAthleteId ? r.blockedId : r.blockerId
      );

      if (excludedIds.length > 0) {
        conditions.push(notInArray(communityPosts.athleteId, excludedIds));
      }
    }

    if (category) {
      conditions.push(eq(communityPosts.category, category.toUpperCase()));
    }

    if (cursor) {
      const cursorDate = new Date(cursor);
      if (!isNaN(cursorDate.getTime())) {
        conditions.push(lt(communityPosts.createdAt, cursorDate));
      }
    }

    const results = await db
      .select({
        id: communityPosts.id,
        athleteId: communityPosts.athleteId,
        externalUrl: communityPosts.externalUrl,
        platform: communityPosts.platform,
        category: communityPosts.category,
        caption: communityPosts.caption,
        matchId: communityPosts.matchId,
        moderationStatus: communityPosts.moderationStatus,
        createdAt: communityPosts.createdAt,
        updatedAt: communityPosts.updatedAt,
        athlete: {
          id: athleteProfiles.id,
          displayName: athleteProfiles.displayName,
          profilePhoto: athleteProfiles.profilePhoto,
        },
        likedByViewer: sql<boolean>`CASE WHEN ${postLikes.athleteId} IS NOT NULL THEN true ELSE false END`,
      })
      .from(communityPosts)
      .innerJoin(
        athleteProfiles,
        eq(communityPosts.athleteId, athleteProfiles.id)
      )
      .leftJoin(
        postLikes,
        and(
          eq(communityPosts.id, postLikes.postId),
          eq(postLikes.athleteId, viewerAthleteId)
        )
      )
      .where(and(...conditions))
      .orderBy(desc(communityPosts.createdAt))
      .limit(limit);

    return results;
  }

  /**
   * Retrieve pending community post submissions for moderators
   */
  static async getPendingSubmissions(options: { limit?: number; cursor?: string } = {}) {
    const limit = options.limit || 50;
    const cursor = options.cursor;

    const conditions = [
      eq(communityPosts.isDeleted, false),
      eq(communityPosts.moderationStatus, "PENDING")
    ];

    if (cursor) {
      const cursorDate = new Date(cursor);
      if (!isNaN(cursorDate.getTime())) {
        conditions.push(lt(communityPosts.createdAt, cursorDate));
      }
    }

    const results = await db
      .select({
        id: communityPosts.id,
        athleteId: communityPosts.athleteId,
        externalUrl: communityPosts.externalUrl,
        platform: communityPosts.platform,
        category: communityPosts.category,
        caption: communityPosts.caption,
        matchId: communityPosts.matchId,
        moderationStatus: communityPosts.moderationStatus,
        createdAt: communityPosts.createdAt,
        updatedAt: communityPosts.updatedAt,
        athlete: {
          id: athleteProfiles.id,
          displayName: athleteProfiles.displayName,
          profilePhoto: athleteProfiles.profilePhoto,
        },
      })
      .from(communityPosts)
      .innerJoin(
        athleteProfiles,
        eq(communityPosts.athleteId, athleteProfiles.id)
      )
      .where(and(...conditions))
      .orderBy(desc(communityPosts.createdAt))
      .limit(limit);

    return results;
  }

  /**
   * Delete a community post (soft delete, creator only)
   */
  static async deletePost(athleteId: string, postId: string) {
    const [post] = await db
      .select()
      .from(communityPosts)
      .where(and(eq(communityPosts.id, postId), eq(communityPosts.isDeleted, false)))
      .limit(1);

    if (!post) {
      throw new NotFoundError("Community post not found");
    }

    if (post.athleteId !== athleteId) {
      throw new ForbiddenError("You are not authorized to delete this post");
    }

    const [updated] = await db
      .update(communityPosts)
      .set({ isDeleted: true, updatedAt: new Date() })
      .where(eq(communityPosts.id, postId))
      .returning();

    return updated;
  }

  /**
   * Like a post (with duplicate prevention)
   */
  static async likePost(athleteId: string, postId: string) {
    // 1. Check if post exists and is active
    const [post] = await db
      .select()
      .from(communityPosts)
      .where(and(eq(communityPosts.id, postId), eq(communityPosts.isDeleted, false)))
      .limit(1);

    if (!post) {
      throw new NotFoundError("Community post not found");
    }

    // 2. Check if already liked
    const [existing] = await db
      .select()
      .from(postLikes)
      .where(and(eq(postLikes.postId, postId), eq(postLikes.athleteId, athleteId)))
      .limit(1);

    if (existing) {
      throw new ConflictError("You have already liked this post");
    }

    try {
      const [like] = await db
        .insert(postLikes)
        .values({
          postId,
          athleteId,
        })
        .returning();

      return like;
    } catch (err: any) {
      if (
        err &&
        (err.code === "23505" ||
          (err.message &&
            (err.message.toLowerCase().includes("unique") ||
              err.message.toLowerCase().includes("duplicate"))))
      ) {
        throw new ConflictError("You have already liked this post");
      }
      throw err;
    }
  }

  /**
   * Unlike a post
   */
  static async unlikePost(athleteId: string, postId: string) {
    // Check if post exists and is active
    const [post] = await db
      .select()
      .from(communityPosts)
      .where(and(eq(communityPosts.id, postId), eq(communityPosts.isDeleted, false)))
      .limit(1);

    if (!post) {
      throw new NotFoundError("Community post not found");
    }

    const deleted = await db
      .delete(postLikes)
      .where(and(eq(postLikes.postId, postId), eq(postLikes.athleteId, athleteId)))
      .returning();

    if (deleted.length === 0) {
      throw new NotFoundError("Like record not found");
    }

    return deleted[0];
  }

  /**
   * Add a comment to a post
   */
  static async addComment(athleteId: string, postId: string, body: string) {
    if (!body || body.trim().length === 0) {
      throw new BadRequestError("Comment body cannot be empty");
    }

    // 1. Check if post exists and is active
    const [post] = await db
      .select()
      .from(communityPosts)
      .where(and(eq(communityPosts.id, postId), eq(communityPosts.isDeleted, false)))
      .limit(1);

    if (!post) {
      throw new NotFoundError("Community post not found");
    }

    // 2. Verify commenting athlete exists and is active
    const [athlete] = await db
      .select()
      .from(athleteProfiles)
      .where(and(eq(athleteProfiles.id, athleteId), eq(athleteProfiles.isDeleted, false)))
      .limit(1);

    if (!athlete) {
      throw new NotFoundError("Athlete profile not found");
    }

    // 3. Insert comment
    const [comment] = await db
      .insert(postComments)
      .values({
        postId,
        athleteId,
        body,
        isDeleted: false,
      })
      .returning();

    return comment;
  }

  /**
   * Get non-deleted comments of a post in chronological order with athlete info
   */
  static async getComments(postId: string) {
    // Check if post exists and is active
    const [post] = await db
      .select()
      .from(communityPosts)
      .where(and(eq(communityPosts.id, postId), eq(communityPosts.isDeleted, false)))
      .limit(1);

    if (!post) {
      throw new NotFoundError("Community post not found");
    }

    const list = await db
      .select({
        id: postComments.id,
        postId: postComments.postId,
        athleteId: postComments.athleteId,
        body: postComments.body,
        createdAt: postComments.createdAt,
        athlete: {
          id: athleteProfiles.id,
          displayName: athleteProfiles.displayName,
          profilePhoto: athleteProfiles.profilePhoto,
        }
      })
      .from(postComments)
      .innerJoin(
        athleteProfiles,
        eq(postComments.athleteId, athleteProfiles.id)
      )
      .where(and(eq(postComments.postId, postId), eq(postComments.isDeleted, false)))
      .orderBy(asc(postComments.createdAt));

    return list;
  }

  /**
   * Fetch an athlete's GYM category posts (training log) filterable by exerciseType
   */
  static async getTrainingLog(athleteId: string, exerciseType?: string) {
    // 1. Verify athlete profile exists and is active
    const [profile] = await db
      .select()
      .from(athleteProfiles)
      .where(and(eq(athleteProfiles.id, athleteId), eq(athleteProfiles.isDeleted, false)))
      .limit(1);

    if (!profile) {
      throw new NotFoundError("Athlete profile not found");
    }

    const conditions = [
      eq(communityPosts.athleteId, athleteId),
      eq(communityPosts.category, "GYM"),
      eq(communityPosts.isDeleted, false),
      eq(communityPosts.moderationStatus, "APPROVED"),
    ];

    if (exerciseType) {
      conditions.push(eq(communityPosts.exerciseType, exerciseType.toUpperCase()));
    }

    return await db
      .select({
        id: communityPosts.id,
        athleteId: communityPosts.athleteId,
        externalUrl: communityPosts.externalUrl,
        platform: communityPosts.platform,
        category: communityPosts.category,
        caption: communityPosts.caption,
        matchId: communityPosts.matchId,
        exerciseType: communityPosts.exerciseType,
        weightKg: communityPosts.weightKg,
        reps: communityPosts.reps,
        moderationStatus: communityPosts.moderationStatus,
        createdAt: communityPosts.createdAt,
        updatedAt: communityPosts.updatedAt,
      })
      .from(communityPosts)
      .where(and(...conditions))
      .orderBy(desc(communityPosts.createdAt));
  }

  /**
   * Fetch an athlete's personal records (PRs) computed from post history
   */
  static async getTrainingLogPRs(athleteId: string) {
    // 1. Verify athlete profile exists and is active
    const [profile] = await db
      .select()
      .from(athleteProfiles)
      .where(and(eq(athleteProfiles.id, athleteId), eq(athleteProfiles.isDeleted, false)))
      .limit(1);

    if (!profile) {
      throw new NotFoundError("Athlete profile not found");
    }

    const posts = await db
      .select({
        exerciseType: communityPosts.exerciseType,
        weightKg: communityPosts.weightKg,
        createdAt: communityPosts.createdAt,
      })
      .from(communityPosts)
      .where(
        and(
          eq(communityPosts.athleteId, athleteId),
          eq(communityPosts.category, "GYM"),
          eq(communityPosts.isDeleted, false),
          eq(communityPosts.moderationStatus, "APPROVED"),
          isNotNull(communityPosts.weightKg)
        )
      );

    const prMap: Record<string, { exerciseType: string; weightKg: number; createdAt: Date }> = {};

    for (const post of posts) {
      const type = post.exerciseType;
      if (!type) continue;
      const weight = Number(post.weightKg);
      if (isNaN(weight) || post.weightKg === null) continue;

      const existing = prMap[type];
      if (!existing || weight > existing.weightKg) {
        prMap[type] = {
          exerciseType: type,
          weightKg: weight,
          createdAt: post.createdAt,
        };
      } else if (weight === existing.weightKg) {
        if (new Date(post.createdAt) < new Date(existing.createdAt)) {
          prMap[type].createdAt = post.createdAt;
        }
      }
    }

    return Object.values(prMap);
  }
}
