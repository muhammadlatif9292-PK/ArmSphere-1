import { eq, and, desc, or, inArray } from "drizzle-orm";
import { db } from "../config/db.js";
import {
  sparringInvites,
  teams,
  teamMembers,
  athleteProfiles,
  users,
} from "@armsphere/db-schema";
import {
  BadRequestError,
  NotFoundError,
  ForbiddenError,
  ConflictError,
  logger,
} from "@armsphere/core";
import { UserRole, SparringInviteStatus } from "@armsphere/types";
import { auditLedgerService } from "./auditLedger.js";
import { NotificationService } from "./notification.js";
import { MessagingService } from "./messaging.js";

export interface CreateSparringInviteInput {
  senderTeamId: string;
  recipientTeamId: string;
  scheduledDate?: string;
  location?: string;
  message?: string;
}

export interface ListSparringInvitesFilters {
  teamId?: string;
  direction?: "sent" | "received";
  status?: string;
}

export class SparringInviteService {
  /**
   * Helper to verify if a user has leadership authority over a specific team
   */
  static async verifyTeamLeadership(userId: string, teamId: string): Promise<boolean> {
    const [user] = await db
      .select({ id: users.id, role: users.role })
      .from(users)
      .where(eq(users.id, userId))
      .limit(1);

    if (!user) return false;

    // System Admin has universal administrative authority
    if (user.role === UserRole.SYSTEM_ADMIN) return true;

    // Check if user is associated as a CAPTAIN on this team's roster
    const [profile] = await db
      .select({ id: athleteProfiles.id })
      .from(athleteProfiles)
      .where(eq(athleteProfiles.userId, userId))
      .limit(1);

    if (profile) {
      const [membership] = await db
        .select({ id: teamMembers.id, role: teamMembers.role })
        .from(teamMembers)
        .where(
          and(
            eq(teamMembers.teamId, teamId),
            eq(teamMembers.athleteId, profile.id)
          )
        )
        .limit(1);

      if (membership && (membership.role === "CAPTAIN" || user.role === UserRole.ORGANIZATION_LEADER)) {
        return true;
      }
    }

    return false;
  }

  /**
   * Helper to get all team IDs where user is a captain or member
   */
  static async getUserTeamIds(userId: string): Promise<string[]> {
    const [profile] = await db
      .select({ id: athleteProfiles.id })
      .from(athleteProfiles)
      .where(eq(athleteProfiles.userId, userId))
      .limit(1);

    if (!profile) return [];

    const memberships = await db
      .select({ teamId: teamMembers.teamId })
      .from(teamMembers)
      .where(eq(teamMembers.athleteId, profile.id));

    return memberships.map((m) => m.teamId);
  }

  /**
   * Create a new sparring invitation
   */
  static async createInvite(userId: string, input: CreateSparringInviteInput) {
    logger.info({ userId, input }, "Attempting to create sparring invitation");

    if (!input.senderTeamId || !input.recipientTeamId) {
      throw new BadRequestError("Both sender and recipient organizations are required");
    }

    if (input.senderTeamId === input.recipientTeamId) {
      throw new BadRequestError("Cannot send sparring invitation to your own organization");
    }

    // Verify sender leadership authority
    const isAuthorized = await this.verifyTeamLeadership(userId, input.senderTeamId);
    if (!isAuthorized) {
      throw new ForbiddenError("You are not authorized as a leader or captain of the sending organization");
    }

    // Verify sender team exists
    const [senderTeam] = await db
      .select({ id: teams.id, name: teams.name })
      .from(teams)
      .where(eq(teams.id, input.senderTeamId))
      .limit(1);

    if (!senderTeam) {
      throw new NotFoundError("Sending organization not found");
    }

    // Verify recipient team exists
    const [recipientTeam] = await db
      .select({ id: teams.id, name: teams.name })
      .from(teams)
      .where(eq(teams.id, input.recipientTeamId))
      .limit(1);

    if (!recipientTeam) {
      throw new NotFoundError("Recipient organization not found");
    }

    // Duplicate pending invite check: cannot send another invite while one is already PENDING
    const existingPending = await db
      .select({ id: sparringInvites.id, status: sparringInvites.status })
      .from(sparringInvites)
      .where(
        and(
          eq(sparringInvites.senderTeamId, input.senderTeamId),
          eq(sparringInvites.recipientTeamId, input.recipientTeamId),
          eq(sparringInvites.status, SparringInviteStatus.PENDING)
        )
      )
      .limit(1);

    if (existingPending.length > 0) {
      throw new ConflictError("A pending sparring invitation already exists between these organizations");
    }

    // Insert invite
    const [invite] = await db
      .insert(sparringInvites)
      .values({
        senderTeamId: input.senderTeamId,
        recipientTeamId: input.recipientTeamId,
        creatorId: userId,
        status: SparringInviteStatus.PENDING,
        scheduledDate: input.scheduledDate ? new Date(input.scheduledDate) : null,
        location: input.location ? input.location.trim() : null,
        message: input.message ? input.message.trim() : null,
      })
      .returning();

    // Notify recipient team captains / leaders
    try {
      const recipientCaptains = await db
        .select({
          athleteId: teamMembers.athleteId,
          userId: athleteProfiles.userId,
        })
        .from(teamMembers)
        .leftJoin(athleteProfiles, eq(teamMembers.athleteId, athleteProfiles.id))
        .where(
          and(
            eq(teamMembers.teamId, input.recipientTeamId),
            eq(teamMembers.role, "CAPTAIN")
          )
        );

      for (const captain of recipientCaptains) {
        if (captain.userId) {
          await NotificationService.createNotification({
            userId: captain.userId,
            title: "New Sparring Invitation",
            content: `${senderTeam.name} has invited your squad to a sparring session`,
            priority: "HIGH",
            category: "MATCH",
            metadata: {
              inviteId: invite.id,
              senderTeamId: input.senderTeamId,
              recipientTeamId: input.recipientTeamId,
            },
          });
        }
      }
    } catch (notifyErr) {
      logger.warn({ err: notifyErr }, "Non-fatal error delivering sparring invitation notification");
    }

    // Audit log
    await auditLedgerService.logEvent({
      actorId: userId,
      action: "SPARRING_INVITE_CREATED",
      resourceType: "SPARRING_INVITE",
      resourceId: invite.id,
      details: {
        senderTeamId: input.senderTeamId,
        recipientTeamId: input.recipientTeamId,
        scheduledDate: invite.scheduledDate,
      },
    });

    return {
      ...invite,
      senderTeam,
      recipientTeam,
    };
  }

  /**
   * List sparring invites scoped to user or specific team
   */
  static async listInvites(userId: string, filters: ListSparringInvitesFilters = {}) {
    const [user] = await db
      .select({ id: users.id, role: users.role })
      .from(users)
      .where(eq(users.id, userId))
      .limit(1);

    const isAdmin = user?.role === UserRole.SYSTEM_ADMIN;

    let targetTeamIds: string[] = [];

    if (filters.teamId) {
      // User must be authorized for this team (or admin)
      if (!isAdmin) {
        const userTeams = await this.getUserTeamIds(userId);
        if (!userTeams.includes(filters.teamId)) {
          throw new ForbiddenError("You do not have access to view invitations for this organization");
        }
      }
      targetTeamIds = [filters.teamId];
    } else if (!isAdmin) {
      targetTeamIds = await this.getUserTeamIds(userId);
    }

    let allInvites = await db.select().from(sparringInvites);

    // Filter in-memory or by condition
    let filtered = allInvites;

    if (filters.teamId) {
      const tid = filters.teamId;
      if (filters.direction === "sent") {
        filtered = filtered.filter((i) => i.senderTeamId === tid);
      } else if (filters.direction === "received") {
        filtered = filtered.filter((i) => i.recipientTeamId === tid);
      } else {
        filtered = filtered.filter((i) => i.senderTeamId === tid || i.recipientTeamId === tid);
      }
    } else if (!isAdmin) {
      if (targetTeamIds.length === 0) {
        return [];
      }
      filtered = filtered.filter(
        (i) => targetTeamIds.includes(i.senderTeamId) || targetTeamIds.includes(i.recipientTeamId)
      );
    }

    if (filters.status) {
      filtered = filtered.filter((i) => i.status === filters.status);
    }

    // Enrich with team names
    const allTeams = await db.select({ id: teams.id, name: teams.name }).from(teams);
    const teamMap = new Map(allTeams.map((t) => [t.id, t.name]));

    const enriched = filtered.map((inv) => ({
      ...inv,
      senderTeamName: teamMap.get(inv.senderTeamId) || "Unknown Organization",
      recipientTeamName: teamMap.get(inv.recipientTeamId) || "Unknown Organization",
    }));

    return enriched.sort(
      (a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime()
    );
  }

  /**
   * Get single sparring invite by ID
   */
  static async getInviteById(userId: string, inviteId: string) {
    const [invite] = await db
      .select()
      .from(sparringInvites)
      .where(eq(sparringInvites.id, inviteId))
      .limit(1);

    if (!invite) {
      throw new NotFoundError("Sparring invitation not found");
    }

    const [user] = await db
      .select({ id: users.id, role: users.role })
      .from(users)
      .where(eq(users.id, userId))
      .limit(1);

    const isAdmin = user?.role === UserRole.SYSTEM_ADMIN;

    if (!isAdmin) {
      const userTeams = await this.getUserTeamIds(userId);
      const isSender = userTeams.includes(invite.senderTeamId) || invite.creatorId === userId;
      const isRecipient = userTeams.includes(invite.recipientTeamId);

      if (!isSender && !isRecipient) {
        throw new ForbiddenError("You do not have permission to view this sparring invitation");
      }
    }

    const [senderTeam] = await db
      .select({ id: teams.id, name: teams.name })
      .from(teams)
      .where(eq(teams.id, invite.senderTeamId))
      .limit(1);

    const [recipientTeam] = await db
      .select({ id: teams.id, name: teams.name })
      .from(teams)
      .where(eq(teams.id, invite.recipientTeamId))
      .limit(1);

    return {
      ...invite,
      senderTeam: senderTeam || null,
      recipientTeam: recipientTeam || null,
    };
  }

  /**
   * Respond to sparring invitation (ACCEPT or DECLINE)
   */
  static async respondInvite(userId: string, inviteId: string, action: "ACCEPT" | "DECLINE") {
    logger.info({ userId, inviteId, action }, "Responding to sparring invitation");

    const [invite] = await db
      .select()
      .from(sparringInvites)
      .where(eq(sparringInvites.id, inviteId))
      .limit(1);

    if (!invite) {
      throw new NotFoundError("Sparring invitation not found");
    }

    if (invite.status !== SparringInviteStatus.PENDING) {
      throw new BadRequestError(`Cannot respond to a sparring invitation in ${invite.status} status`);
    }

    // Verify authority for recipient team
    const isAuthorized = await this.verifyTeamLeadership(userId, invite.recipientTeamId);
    if (!isAuthorized) {
      throw new ForbiddenError("Only authorized leaders or captains of the recipient organization can respond to this invite");
    }

    const newStatus =
      action === "ACCEPT" ? SparringInviteStatus.ACCEPTED : SparringInviteStatus.DECLINED;

    const [updated] = await db
      .update(sparringInvites)
      .set({
        status: newStatus,
        responderId: userId,
        respondedAt: new Date(),
        updatedAt: new Date(),
      })
      .where(eq(sparringInvites.id, inviteId))
      .returning();

    let conversationId: string | null = null;

    if (action === "ACCEPT") {
      // Connect to real Direct Messaging infrastructure between both organization leaders
      try {
        const conversation = await MessagingService.getOrCreateConversation(
          invite.creatorId,
          userId,
          "DIRECT"
        );
        conversationId = conversation.id;

        // Post confirmation message in the thread
        await MessagingService.sendMessage(
          userId,
          conversation.id,
          "Sparring invitation accepted! Let's coordinate table availability and athlete roster matchups."
        );
      } catch (chatErr) {
        logger.warn({ err: chatErr }, "Non-fatal error creating conversation for accepted sparring invite");
      }

      // Notify sender leader
      try {
        await NotificationService.createNotification({
          userId: invite.creatorId,
          title: "Sparring Invitation Accepted",
          content: "Your sparring invitation has been accepted!",
          priority: "HIGH",
          category: "MATCH",
          metadata: { inviteId: invite.id, status: newStatus, conversationId },
        });
      } catch (notifyErr) {
        logger.warn({ err: notifyErr }, "Non-fatal error notifying sender of accepted invite");
      }

      // Audit log
      await auditLedgerService.logEvent({
        actorId: userId,
        action: "SPARRING_INVITE_ACCEPTED",
        resourceType: "SPARRING_INVITE",
        resourceId: invite.id,
        details: { responderId: userId, conversationId },
      });
    } else {
      // Notify sender of decline
      try {
        await NotificationService.createNotification({
          userId: invite.creatorId,
          title: "Sparring Invitation Declined",
          content: "Your sparring invitation was declined.",
          priority: "NORMAL",
          category: "MATCH",
          metadata: { inviteId: invite.id, status: newStatus },
        });
      } catch (notifyErr) {
        logger.warn({ err: notifyErr }, "Non-fatal error notifying sender of declined invite");
      }

      // Audit log
      await auditLedgerService.logEvent({
        actorId: userId,
        action: "SPARRING_INVITE_DECLINED",
        resourceType: "SPARRING_INVITE",
        resourceId: invite.id,
        details: { responderId: userId },
      });
    }

    return {
      ...updated,
      conversationId,
    };
  }

  /**
   * Cancel a pending sparring invitation (Sender only)
   */
  static async cancelInvite(userId: string, inviteId: string) {
    logger.info({ userId, inviteId }, "Cancelling sparring invitation");

    const [invite] = await db
      .select()
      .from(sparringInvites)
      .where(eq(sparringInvites.id, inviteId))
      .limit(1);

    if (!invite) {
      throw new NotFoundError("Sparring invitation not found");
    }

    if (invite.status !== SparringInviteStatus.PENDING) {
      throw new BadRequestError(`Cannot cancel a sparring invitation in ${invite.status} status`);
    }

    // Verify sender authority
    const [user] = await db
      .select({ id: users.id, role: users.role })
      .from(users)
      .where(eq(users.id, userId))
      .limit(1);

    const isCreator = invite.creatorId === userId;
    const isSenderLeader = await this.verifyTeamLeadership(userId, invite.senderTeamId);
    const isAdmin = user?.role === UserRole.SYSTEM_ADMIN;

    if (!isCreator && !isSenderLeader && !isAdmin) {
      throw new ForbiddenError("Only authorized leaders of the sending organization can cancel this invite");
    }

    const [updated] = await db
      .update(sparringInvites)
      .set({
        status: SparringInviteStatus.CANCELLED,
        updatedAt: new Date(),
      })
      .where(eq(sparringInvites.id, inviteId))
      .returning();

    // Audit log
    await auditLedgerService.logEvent({
      actorId: userId,
      action: "SPARRING_INVITE_CANCELLED",
      resourceType: "SPARRING_INVITE",
      resourceId: invite.id,
      details: { cancelledBy: userId },
    });

    return updated;
  }
}
