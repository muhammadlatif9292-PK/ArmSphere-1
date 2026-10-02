import { eq, and, desc, asc, inArray } from "drizzle-orm";
import { db } from "../config/db.js";
import {
  supportTickets,
  supportTicketMessages,
  users,
  athleteProfiles,
} from "@armsphere/db-schema";
import {
  BadRequestError,
  NotFoundError,
  ForbiddenError,
  logger,
} from "@armsphere/core";
import {
  UserRole,
  SupportTicketStatus,
  SupportTicketPriority,
  SupportTicketCategory,
} from "@armsphere/types";
import { auditLedgerService } from "./auditLedger.js";

export interface CreateSupportTicketInput {
  subject: string;
  description: string;
  category?: string;
  priority?: string;
}

export interface ListSupportTicketsFilters {
  status?: string;
  category?: string;
  assignedAgentId?: string;
  myTicketsOnly?: boolean;
}

export class SupportService {
  /**
   * Create a new customer support ticket
   */
  static async createTicket(userId: string, input: CreateSupportTicketInput) {
    if (!input.subject || input.subject.trim().length === 0) {
      throw new BadRequestError("Ticket subject is required.");
    }
    if (!input.description || input.description.trim().length === 0) {
      throw new BadRequestError("Ticket description is required.");
    }

    const [user] = await db.select().from(users).where(eq(users.id, userId)).limit(1);
    if (!user) {
      throw new NotFoundError("Requester user not found.");
    }

    const category = input.category || SupportTicketCategory.GENERAL;
    const priority = input.priority || SupportTicketPriority.NORMAL;

    const [ticket] = await db
      .insert(supportTickets)
      .values({
        userId,
        subject: input.subject.trim(),
        description: input.description.trim(),
        category,
        priority,
        status: SupportTicketStatus.OPEN,
      })
      .returning();

    logger.info({ ticketId: ticket.id, userId, category }, "Created customer support ticket");

    await auditLedgerService.logEvent({
      actorId: userId,
      entityType: "SUPPORT_TICKET",
      entityId: ticket.id,
      action: "SUPPORT_TICKET_CREATED",
      payload: {
        subject: ticket.subject,
        category: ticket.category,
        priority: ticket.priority,
      },
    });

    return ticket;
  }

  /**
   * List tickets scoped by caller role and filters
   */
  static async listTickets(actorId: string, role: string, filters: ListSupportTicketsFilters = {}) {
    const isStaff = role === UserRole.SUPPORT_AGENT || role === UserRole.SYSTEM_ADMIN;

    // Athlete/regular user can ONLY see their own tickets
    const targetUserId = isStaff ? (filters.myTicketsOnly ? actorId : undefined) : actorId;

    let allTickets = await db.select().from(supportTickets);

    // Filter in-memory or by query
    let filtered = allTickets;

    if (targetUserId) {
      filtered = filtered.filter((t) => t.userId === targetUserId);
    }

    if (isStaff && filters.assignedAgentId) {
      filtered = filtered.filter((t) => t.assignedAgentId === filters.assignedAgentId);
    }

    if (filters.status) {
      filtered = filtered.filter((t) => t.status === filters.status);
    }

    if (filters.category) {
      filtered = filtered.filter((t) => t.category === filters.category);
    }

    // Sort by createdAt descending
    filtered.sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime());

    // Enrich with requester and assignedAgent details
    const allUsers = await db.select().from(users);
    const userMap = new Map(allUsers.map((u) => [u.id, u]));

    const enriched = filtered.map((t) => {
      const requester = userMap.get(t.userId);
      const agent = t.assignedAgentId ? userMap.get(t.assignedAgentId) : null;
      return {
        ...t,
        requester: requester
          ? {
              id: requester.id,
              fullName: requester.fullName,
              username: requester.username,
              email: requester.email,
              role: requester.role,
            }
          : null,
        assignedAgent: agent
          ? {
              id: agent.id,
              fullName: agent.fullName,
              username: agent.username,
              role: agent.role,
            }
          : null,
      };
    });

    return enriched;
  }

  /**
   * Get single ticket with authorized message visibility
   */
  static async getTicket(actorId: string, role: string, ticketId: string) {
    const [ticket] = await db
      .select()
      .from(supportTickets)
      .where(eq(supportTickets.id, ticketId))
      .limit(1);

    if (!ticket) {
      throw new NotFoundError("Support ticket not found.");
    }

    const isStaff = role === UserRole.SUPPORT_AGENT || role === UserRole.SYSTEM_ADMIN;

    if (!isStaff && ticket.userId !== actorId) {
      throw new ForbiddenError("You are not authorized to view this support ticket.");
    }

    // Fetch messages
    const allMessages = await db
      .select()
      .from(supportTicketMessages)
      .where(eq(supportTicketMessages.ticketId, ticketId));

    // Sort ascending by time
    allMessages.sort((a, b) => new Date(a.createdAt).getTime() - new Date(b.createdAt).getTime());

    // Filter out internal notes for non-staff
    const visibleMessages = isStaff ? allMessages : allMessages.filter((m) => !m.isInternal);

    // Enrich messages and ticket
    const allUsers = await db.select().from(users);
    const userMap = new Map(allUsers.map((u) => [u.id, u]));

    const requester = userMap.get(ticket.userId);
    const agent = ticket.assignedAgentId ? userMap.get(ticket.assignedAgentId) : null;
    const resolver = ticket.resolvedById ? userMap.get(ticket.resolvedById) : null;

    const enrichedMessages = visibleMessages.map((m) => {
      const sender = userMap.get(m.senderId);
      return {
        ...m,
        sender: sender
          ? {
              id: sender.id,
              fullName: sender.fullName,
              username: sender.username,
              role: sender.role,
            }
          : null,
      };
    });

    return {
      ...ticket,
      requester: requester
        ? {
            id: requester.id,
            fullName: requester.fullName,
            username: requester.username,
            email: requester.email,
            role: requester.role,
          }
        : null,
      assignedAgent: agent
        ? {
            id: agent.id,
            fullName: agent.fullName,
            username: agent.username,
            role: agent.role,
          }
        : null,
      resolver: resolver
        ? {
            id: resolver.id,
            fullName: resolver.fullName,
            username: resolver.username,
          }
        : null,
      messages: enrichedMessages,
    };
  }

  /**
   * Assign ticket to a support agent or system admin
   */
  static async assignTicket(actorId: string, role: string, ticketId: string, agentId: string | null) {
    const isStaff = role === UserRole.SUPPORT_AGENT || role === UserRole.SYSTEM_ADMIN;
    if (!isStaff) {
      throw new ForbiddenError("Only support agents and administrators can assign tickets.");
    }

    const [ticket] = await db
      .select()
      .from(supportTickets)
      .where(eq(supportTickets.id, ticketId))
      .limit(1);

    if (!ticket) {
      throw new NotFoundError("Support ticket not found.");
    }

    if (agentId !== null) {
      const [agentUser] = await db.select().from(users).where(eq(users.id, agentId)).limit(1);
      if (!agentUser) {
        throw new NotFoundError("Target agent user not found.");
      }
      if (agentUser.role !== UserRole.SUPPORT_AGENT && agentUser.role !== UserRole.SYSTEM_ADMIN) {
        throw new BadRequestError("Tickets can only be assigned to support agents or administrators.");
      }
    }

    const newStatus =
      ticket.status === SupportTicketStatus.OPEN && agentId !== null
        ? SupportTicketStatus.IN_PROGRESS
        : ticket.status;

    const [updatedTicket] = await db
      .update(supportTickets)
      .set({
        assignedAgentId: agentId,
        status: newStatus,
        updatedAt: new Date(),
      })
      .where(eq(supportTickets.id, ticketId))
      .returning();

    logger.info({ ticketId, assignedAgentId: agentId, actorId }, "Assigned support ticket");

    await auditLedgerService.logEvent({
      actorId,
      entityType: "SUPPORT_TICKET",
      entityId: ticketId,
      action: "SUPPORT_TICKET_ASSIGNED",
      payload: {
        previousAgentId: ticket.assignedAgentId,
        newAgentId: agentId,
        previousStatus: ticket.status,
        newStatus,
      },
    });

    return updatedTicket;
  }

  /**
   * Update status of support ticket (resolve, close, reopen, in-progress)
   */
  static async updateTicketStatus(
    actorId: string,
    role: string,
    ticketId: string,
    newStatus: string,
    resolutionNotes?: string
  ) {
    const [ticket] = await db
      .select()
      .from(supportTickets)
      .where(eq(supportTickets.id, ticketId))
      .limit(1);

    if (!ticket) {
      throw new NotFoundError("Support ticket not found.");
    }

    const validStatuses = [
      SupportTicketStatus.PENDING,
      SupportTicketStatus.OPEN,
      SupportTicketStatus.IN_PROGRESS,
      SupportTicketStatus.RESOLVED,
      SupportTicketStatus.CLOSED,
    ];

    if (!validStatuses.includes(newStatus as any)) {
      throw new BadRequestError(`Invalid support ticket status: ${newStatus}`);
    }

    const isStaff = role === UserRole.SUPPORT_AGENT || role === UserRole.SYSTEM_ADMIN;

    if (!isStaff) {
      // Requesters can only close their own ticket
      if (ticket.userId !== actorId) {
        throw new ForbiddenError("Unauthorized to update this support ticket.");
      }
      if (newStatus !== SupportTicketStatus.CLOSED) {
        throw new ForbiddenError("Requesters can only mark their own support tickets as CLOSED.");
      }
    }

    const isResolving =
      newStatus === SupportTicketStatus.RESOLVED || newStatus === SupportTicketStatus.CLOSED;

    const [updatedTicket] = await db
      .update(supportTickets)
      .set({
        status: newStatus,
        resolutionNotes: resolutionNotes || ticket.resolutionNotes,
        resolvedAt: isResolving ? new Date() : null,
        resolvedById: isResolving ? actorId : null,
        updatedAt: new Date(),
      })
      .where(eq(supportTickets.id, ticketId))
      .returning();

    logger.info({ ticketId, newStatus, actorId }, "Updated support ticket status");

    await auditLedgerService.logEvent({
      actorId,
      entityType: "SUPPORT_TICKET",
      entityId: ticketId,
      action: "SUPPORT_TICKET_STATUS_UPDATED",
      payload: {
        previousStatus: ticket.status,
        newStatus,
        resolutionNotes,
      },
    });

    return updatedTicket;
  }

  /**
   * Post message or internal staff note to a support ticket
   */
  static async addMessage(
    actorId: string,
    role: string,
    ticketId: string,
    messageContent: string,
    isInternal: boolean = false
  ) {
    if (!messageContent || messageContent.trim().length === 0) {
      throw new BadRequestError("Message content cannot be empty.");
    }

    const [ticket] = await db
      .select()
      .from(supportTickets)
      .where(eq(supportTickets.id, ticketId))
      .limit(1);

    if (!ticket) {
      throw new NotFoundError("Support ticket not found.");
    }

    const isStaff = role === UserRole.SUPPORT_AGENT || role === UserRole.SYSTEM_ADMIN;

    if (!isStaff && ticket.userId !== actorId) {
      throw new ForbiddenError("Unauthorized to reply to this support ticket.");
    }

    // Non-staff can never create internal notes
    const effectiveIsInternal = isStaff ? Boolean(isInternal) : false;

    const [message] = await db
      .insert(supportTicketMessages)
      .values({
        ticketId,
        senderId: actorId,
        message: messageContent.trim(),
        isInternal: effectiveIsInternal,
      })
      .returning();

    // Touch ticket updatedAt
    await db
      .update(supportTickets)
      .set({ updatedAt: new Date() })
      .where(eq(supportTickets.id, ticketId));

    logger.info({ ticketId, messageId: message.id, isInternal: effectiveIsInternal }, "Added ticket message");

    return message;
  }
}
