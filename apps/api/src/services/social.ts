import { eq, and, desc } from "drizzle-orm";
import { db } from "../config/db.js";
import { 
  athleteProfiles, 
  athleteClubs, 
  follows, 
  teams, 
  teamMembers,
  blockedUsers
} from "@armsphere/db-schema";
import { 
  NotFoundError, 
  BadRequestError, 
  ConflictError,
  ForbiddenError
} from "@armsphere/core";
import { UserRole } from "@armsphere/types";

export interface CreateTeamPayload {
  name: string;
  description?: string;
  foundedAt?: string;
  clubId?: string;
}

export class SocialService {
  /**
   * Follow an athlete
   */
  static async followAthlete(followerId: string, followingId: string) {
    if (followerId === followingId) {
      throw new BadRequestError("You cannot follow yourself");
    }

    // Verify follower profile exists and is active
    const [follower] = await db
      .select()
      .from(athleteProfiles)
      .where(and(eq(athleteProfiles.id, followerId), eq(athleteProfiles.isDeleted, false)))
      .limit(1);

    if (!follower) {
      throw new NotFoundError("Follower athlete profile not found");
    }

    // Verify following profile exists and is active
    const [following] = await db
      .select()
      .from(athleteProfiles)
      .where(and(eq(athleteProfiles.id, followingId), eq(athleteProfiles.isDeleted, false)))
      .limit(1);

    if (!following) {
      throw new NotFoundError("Target athlete profile not found");
    }

    // Check if follow record already exists
    const [existing] = await db
      .select()
      .from(follows)
      .where(and(eq(follows.followerId, followerId), eq(follows.followingId, followingId)))
      .limit(1);

    if (existing) {
      throw new ConflictError("You are already following this athlete");
    }

    // Create follow relationship
    try {
      const [followRecord] = await db
        .insert(follows)
        .values({
          followerId,
          followingId,
        })
        .returning();

      return followRecord;
    } catch (err: any) {
      if (
        err &&
        (err.code === "23505" ||
          (err.message &&
            (err.message.toLowerCase().includes("unique") ||
              err.message.toLowerCase().includes("duplicate"))))
      ) {
        throw new ConflictError("You are already following this athlete");
      }
      throw err;
    }
  }

  /**
   * Unfollow an athlete
   */
  static async unfollowAthlete(followerId: string, followingId: string) {
    const deleted = await db
      .delete(follows)
      .where(and(eq(follows.followerId, followerId), eq(follows.followingId, followingId)))
      .returning();

    if (deleted.length === 0) {
      throw new NotFoundError("Follow relationship not found");
    }

    return deleted[0];
  }

  /**
   * Get followers of an athlete (paginated)
   */
  static async getFollowers(athleteId: string, limit = 50, offset = 0) {
    // Verify target athlete exists
    const [profile] = await db
      .select()
      .from(athleteProfiles)
      .where(and(eq(athleteProfiles.id, athleteId), eq(athleteProfiles.isDeleted, false)))
      .limit(1);

    if (!profile) {
      throw new NotFoundError("Athlete profile not found");
    }

    const results = await db
      .select({
        id: athleteProfiles.id,
        userId: athleteProfiles.userId,
        displayName: athleteProfiles.displayName,
        province: athleteProfiles.province,
        city: athleteProfiles.city,
        profilePhoto: athleteProfiles.profilePhoto,
        gender: athleteProfiles.gender,
        weightClass: athleteProfiles.weightClass,
        followedAt: follows.createdAt,
      })
      .from(follows)
      .innerJoin(
        athleteProfiles,
        eq(follows.followerId, athleteProfiles.id)
      )
      .where(and(eq(follows.followingId, athleteId), eq(athleteProfiles.isDeleted, false)))
      .limit(limit)
      .offset(offset)
      .orderBy(desc(follows.createdAt));

    return results;
  }

  /**
   * Get athletes followed by an athlete (paginated)
   */
  static async getFollowing(athleteId: string, limit = 50, offset = 0) {
    // Verify target athlete exists
    const [profile] = await db
      .select()
      .from(athleteProfiles)
      .where(and(eq(athleteProfiles.id, athleteId), eq(athleteProfiles.isDeleted, false)))
      .limit(1);

    if (!profile) {
      throw new NotFoundError("Athlete profile not found");
    }

    const results = await db
      .select({
        id: athleteProfiles.id,
        userId: athleteProfiles.userId,
        displayName: athleteProfiles.displayName,
        province: athleteProfiles.province,
        city: athleteProfiles.city,
        profilePhoto: athleteProfiles.profilePhoto,
        gender: athleteProfiles.gender,
        weightClass: athleteProfiles.weightClass,
        followedAt: follows.createdAt,
      })
      .from(follows)
      .innerJoin(
        athleteProfiles,
        eq(follows.followingId, athleteProfiles.id)
      )
      .where(and(eq(follows.followerId, athleteId), eq(athleteProfiles.isDeleted, false)))
      .limit(limit)
      .offset(offset)
      .orderBy(desc(follows.createdAt));

    return results;
  }

  /**
   * Create a team
   */
  static async createTeam(payload: CreateTeamPayload, creatorAthleteId: string) {
    // Verify clubId if provided
    if (payload.clubId) {
      const [club] = await db
        .select()
        .from(athleteClubs)
        .where(and(eq(athleteClubs.id, payload.clubId), eq(athleteClubs.isDeleted, false)))
        .limit(1);

      if (!club) {
        throw new NotFoundError("Club not found");
      }
    }

    const [team] = await db
      .insert(teams)
      .values({
        name: payload.name,
        description: payload.description || null,
        foundedAt: payload.foundedAt ? new Date(payload.foundedAt) : null,
        clubId: payload.clubId || null,
      })
      .returning();

    // Automatically insert the creator as CAPTAIN
    await db
      .insert(teamMembers)
      .values({
        teamId: team.id,
        athleteId: creatorAthleteId,
        role: "CAPTAIN",
      });

    return team;
  }

  /**
   * Add a member to a team
   */
  static async addTeamMember(
    teamId: string, 
    athleteId: string, 
    role: string,
    callingUser: { id: string; role: string; athleteId?: string }
  ) {
    // Authorization check
    const isAdmin = callingUser.role === UserRole.SYSTEM_ADMIN || callingUser.role === UserRole.NATIONAL_DIRECTOR;
    if (!isAdmin) {
      if (!callingUser.athleteId) {
        throw new ForbiddenError("Access denied. An active athlete profile is required to manage team members.");
      }

      // Check if calling user is a CAPTAIN of this team
      const [captainMembership] = await db
        .select()
        .from(teamMembers)
        .where(
          and(
            eq(teamMembers.teamId, teamId),
            eq(teamMembers.athleteId, callingUser.athleteId),
            eq(teamMembers.role, "CAPTAIN")
          )
        )
        .limit(1);

      if (!captainMembership) {
        throw new ForbiddenError("Access denied. You must be a team captain or administrator to add members.");
      }
    }

    // Validate role
    if (role !== "MEMBER" && role !== "CAPTAIN") {
      throw new BadRequestError("Invalid team member role. Accepted values are MEMBER or CAPTAIN.");
    }

    // Verify team exists
    const [team] = await db
      .select()
      .from(teams)
      .where(eq(teams.id, teamId))
      .limit(1);

    if (!team) {
      throw new NotFoundError("Team not found");
    }

    // Verify athlete profile exists and is active
    const [athlete] = await db
      .select()
      .from(athleteProfiles)
      .where(and(eq(athleteProfiles.id, athleteId), eq(athleteProfiles.isDeleted, false)))
      .limit(1);

    if (!athlete) {
      throw new NotFoundError("Athlete profile not found");
    }

    // Check if already a member
    const [existingMember] = await db
      .select()
      .from(teamMembers)
      .where(and(eq(teamMembers.teamId, teamId), eq(teamMembers.athleteId, athleteId)))
      .limit(1);

    if (existingMember) {
      throw new ConflictError("Athlete is already a member of this team");
    }

    try {
      const [membership] = await db
        .insert(teamMembers)
        .values({
          teamId,
          athleteId,
          role,
        })
        .returning();

      return membership;
    } catch (err: any) {
      if (
        err &&
        (err.code === "23505" ||
          (err.message &&
            (err.message.toLowerCase().includes("unique") ||
              err.message.toLowerCase().includes("duplicate"))))
      ) {
        throw new ConflictError("Athlete is already a member of this team");
      }
      throw err;
    }
  }

  /**
   * Remove a member from a team
   */
  static async removeTeamMember(
    teamId: string, 
    athleteId: string,
    callingUser: { id: string; role: string; athleteId?: string }
  ) {
    // Authorization check
    const isAdmin = callingUser.role === UserRole.SYSTEM_ADMIN || callingUser.role === UserRole.NATIONAL_DIRECTOR;
    if (!isAdmin) {
      if (!callingUser.athleteId) {
        throw new ForbiddenError("Access denied. An active athlete profile is required to manage team members.");
      }

      // Check if calling user is a CAPTAIN of this team
      const [captainMembership] = await db
        .select()
        .from(teamMembers)
        .where(
          and(
            eq(teamMembers.teamId, teamId),
            eq(teamMembers.athleteId, callingUser.athleteId),
            eq(teamMembers.role, "CAPTAIN")
          )
        )
        .limit(1);

      if (!captainMembership) {
        throw new ForbiddenError("Access denied. You must be a team captain or administrator to remove members.");
      }
    }

    const deleted = await db
      .delete(teamMembers)
      .where(and(eq(teamMembers.teamId, teamId), eq(teamMembers.athleteId, athleteId)))
      .returning();

    if (deleted.length === 0) {
      throw new NotFoundError("Team membership record not found");
    }

    return deleted[0];
  }

  /**
   * Retrieve team details with club details and joined members
   */
  static async getTeam(teamId: string) {
    // Verify and select team
    const [team] = await db
      .select()
      .from(teams)
      .where(eq(teams.id, teamId))
      .limit(1);

    if (!team) {
      throw new NotFoundError("Team not found");
    }

    // Fetch club details if clubId is set
    let club = null;
    if (team.clubId) {
      const [clubRecord] = await db
        .select()
        .from(athleteClubs)
        .where(eq(athleteClubs.id, team.clubId))
        .limit(1);
      club = clubRecord || null;
    }

    // Fetch members with athlete details
    const members = await db
      .select({
        athleteId: athleteProfiles.id,
        userId: athleteProfiles.userId,
        displayName: athleteProfiles.displayName,
        province: athleteProfiles.province,
        city: athleteProfiles.city,
        profilePhoto: athleteProfiles.profilePhoto,
        role: teamMembers.role,
        joinedAt: teamMembers.joinedAt,
      })
      .from(teamMembers)
      .innerJoin(
        athleteProfiles,
        eq(teamMembers.athleteId, athleteProfiles.id)
      )
      .where(and(eq(teamMembers.teamId, teamId), eq(athleteProfiles.isDeleted, false)));

    return {
      ...team,
      club,
      members,
    };
  }

  /**
   * Retrieve all teams the calling user belongs to via their membership
   */
  static async getMyTeams(athleteId: string) {
    const memberships = await db
      .select({
        id: teams.id,
        name: teams.name,
        description: teams.description,
        foundedAt: teams.foundedAt,
        clubId: teams.clubId,
        createdAt: teams.createdAt,
        role: teamMembers.role,
        joinedAt: teamMembers.joinedAt,
        clubName: athleteClubs.name,
      })
      .from(teamMembers)
      .innerJoin(teams, eq(teamMembers.teamId, teams.id))
      .leftJoin(athleteClubs, eq(teams.clubId, athleteClubs.id))
      .where(eq(teamMembers.athleteId, athleteId))
      .orderBy(desc(teamMembers.joinedAt));

    return memberships;
  }

  /**
   * Check if a follower is following a target athlete
   */
  static async isFollowing(followerId: string, followingId: string): Promise<boolean> {
    const [record] = await db
      .select({ id: follows.id })
      .from(follows)
      .where(and(eq(follows.followerId, followerId), eq(follows.followingId, followingId)))
      .limit(1);

    return !!record;
  }

  /**
   * Block an athlete
   */
  static async blockAthlete(blockerId: string, blockedId: string) {
    if (blockerId === blockedId) {
      throw new BadRequestError("You cannot block yourself");
    }

    // Verify blocker profile exists and is active
    const [blocker] = await db
      .select()
      .from(athleteProfiles)
      .where(and(eq(athleteProfiles.id, blockerId), eq(athleteProfiles.isDeleted, false)))
      .limit(1);

    if (!blocker) {
      throw new NotFoundError("Blocker profile not found");
    }

    // Verify blocked profile exists and is active
    const [blocked] = await db
      .select()
      .from(athleteProfiles)
      .where(and(eq(athleteProfiles.id, blockedId), eq(athleteProfiles.isDeleted, false)))
      .limit(1);

    if (!blocked) {
      throw new NotFoundError("Target profile to block not found");
    }

    // Check if block record already exists
    const [existing] = await db
      .select()
      .from(blockedUsers)
      .where(and(eq(blockedUsers.blockerId, blockerId), eq(blockedUsers.blockedId, blockedId)))
      .limit(1);

    if (existing) {
      throw new ConflictError("You have already blocked this user");
    }

    // Unfollow automatically in both directions
    await db
      .delete(follows)
      .where(
        and(
          eq(follows.followerId, blockerId),
          eq(follows.followingId, blockedId)
        )
      );
    await db
      .delete(follows)
      .where(
        and(
          eq(follows.followerId, blockedId),
          eq(follows.followingId, blockerId)
        )
      );

    // Create block relationship
    try {
      const [blockRecord] = await db
        .insert(blockedUsers)
        .values({
          blockerId,
          blockedId,
        })
        .returning();

      return blockRecord;
    } catch (err: any) {
      if (
        err &&
        (err.code === "23505" ||
          (err.message &&
            (err.message.toLowerCase().includes("unique") ||
              err.message.toLowerCase().includes("duplicate"))))
      ) {
        throw new ConflictError("You have already blocked this user");
      }
      throw err;
    }
  }

  /**
   * Unblock an athlete
   */
  static async unblockAthlete(blockerId: string, blockedId: string) {
    const deleted = await db
      .delete(blockedUsers)
      .where(and(eq(blockedUsers.blockerId, blockerId), eq(blockedUsers.blockedId, blockedId)))
      .returning();

    if (deleted.length === 0) {
      throw new NotFoundError("Block relationship not found");
    }

    return deleted[0];
  }

  /**
   * Get blocked users of an athlete
   */
  static async getBlockedUsers(blockerId: string, limit = 50, offset = 0) {
    const results = await db
      .select({
        id: athleteProfiles.id,
        userId: athleteProfiles.userId,
        displayName: athleteProfiles.displayName,
        province: athleteProfiles.province,
        city: athleteProfiles.city,
        profilePhoto: athleteProfiles.profilePhoto,
        gender: athleteProfiles.gender,
        weightClass: athleteProfiles.weightClass,
        blockedAt: blockedUsers.createdAt,
      })
      .from(blockedUsers)
      .innerJoin(
        athleteProfiles,
        eq(blockedUsers.blockedId, athleteProfiles.id)
      )
      .where(and(eq(blockedUsers.blockerId, blockerId), eq(athleteProfiles.isDeleted, false)))
      .limit(limit)
      .offset(offset)
      .orderBy(desc(blockedUsers.createdAt));

    return results;
  }

  /**
   * Check if there is an active block between two users in either direction
   */
  static async hasActiveBlock(userAId: string, userBId: string): Promise<boolean> {
    const [record] = await db
      .select({ id: blockedUsers.id })
      .from(blockedUsers)
      .where(
        and(
          eq(blockedUsers.blockerId, userAId),
          eq(blockedUsers.blockedId, userBId)
        )
      )
      .limit(1);

    if (record) return true;

    const [record2] = await db
      .select({ id: blockedUsers.id })
      .from(blockedUsers)
      .where(
        and(
          eq(blockedUsers.blockerId, userBId),
          eq(blockedUsers.blockedId, userAId)
        )
      )
      .limit(1);

    return !!record2;
  }
}
