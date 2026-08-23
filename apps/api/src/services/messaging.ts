import { eq, and, desc, asc, not, isNull, sql } from "drizzle-orm";
import { db } from "../config/db.js";
import { 
  conversations, 
  conversationParticipants, 
  messages, 
  users,
  athleteProfiles,
  blockedUsers
} from "@armsphere/db-schema";
import { BadRequestError, NotFoundError, ForbiddenError, logger } from "@armsphere/core";

export class MessagingService {
  // Helper to check if two userIds have an active block between them
  static async checkBlockByUsers(userAId: string, userBId: string): Promise<boolean> {
    const [profileA] = await db
      .select({ id: athleteProfiles.id })
      .from(athleteProfiles)
      .where(eq(athleteProfiles.userId, userAId))
      .limit(1);

    const [profileB] = await db
      .select({ id: athleteProfiles.id })
      .from(athleteProfiles)
      .where(eq(athleteProfiles.userId, userBId))
      .limit(1);

    if (profileA && profileB) {
      const [blockRecord] = await db
        .select({ id: blockedUsers.id })
        .from(blockedUsers)
        .where(
          and(
            eq(blockedUsers.blockerId, profileA.id),
            eq(blockedUsers.blockedId, profileB.id)
          )
        )
        .limit(1);

      if (blockRecord) return true;

      const [blockRecord2] = await db
        .select({ id: blockedUsers.id })
        .from(blockedUsers)
        .where(
          and(
            eq(blockedUsers.blockerId, profileB.id),
            eq(blockedUsers.blockedId, profileA.id)
          )
        )
        .limit(1);

      if (blockRecord2) return true;
    }

    return false;
  }

  /**
   * Create or fetch a 1-to-1 or custom conversation
   */
  static async getOrCreateConversation(creatorId: string, participantId: string, type: "DIRECT" | "FEDERATION" | "SYSTEM" = "DIRECT") {
    logger.info({ creatorId, participantId, type }, "Initializing conversation between participants");

    if (type === "DIRECT") {
      const isBlocked = await MessagingService.checkBlockByUsers(creatorId, participantId);
      if (isBlocked) {
        throw new ForbiddenError("Cannot start conversation: This user is blocked or has blocked you.");
      }
    }

    // For DIRECT, check if conversation already exists between these two users
    if (type === "DIRECT") {
      const existingCPs = await db
        .select()
        .from(conversationParticipants)
        .where(eq(conversationParticipants.userId, creatorId));

      for (const cp of existingCPs) {
        // Find if the same conversation contains the other participant
        const [otherPart] = await db
          .select()
          .from(conversationParticipants)
          .where(and(
            eq(conversationParticipants.conversationId, cp.conversationId),
            eq(conversationParticipants.userId, participantId)
          ));

        if (otherPart) {
          const [conv] = await db
            .select()
            .from(conversations)
            .where(and(eq(conversations.id, cp.conversationId), eq(conversations.type, "DIRECT")));

          if (conv) {
            return { conversation: conv, isNew: false };
          }
        }
      }
    }

    // Provision new conversation
    const [newConv] = await db
      .insert(conversations)
      .values({
        type,
        metadata: {},
      })
      .returning();

    // Attach participants
    await db.insert(conversationParticipants).values([
      { conversationId: newConv.id, userId: creatorId, lastReadAt: new Date() },
      { conversationId: newConv.id, userId: participantId, lastReadAt: new Date(0) }
    ]);

    return { conversation: newConv, isNew: true };
  }

  /**
   * Post message into a conversation
   */
  static async sendMessage(params: {
    conversationId: string;
    senderId: string;
    content: string;
    attachments?: Array<{ url: string; filename: string; size: number; mimeType: string }>;
  }) {
    logger.info(params, "Posting message to conversation");

    const [conv] = await db
      .select()
      .from(conversations)
      .where(eq(conversations.id, params.conversationId));

    if (!conv) {
      throw new NotFoundError("Conversation not found");
    }

    // Verify sender is a participant
    const [part] = await db
      .select()
      .from(conversationParticipants)
      .where(and(
        eq(conversationParticipants.conversationId, params.conversationId),
        eq(conversationParticipants.userId, params.senderId)
      ));

    if (!part) {
      throw new BadRequestError("User is not a participant of this conversation");
    }

    // Check if there are any blocks between the sender and other participants in this conversation
    const otherParticipants = await db
      .select({ userId: conversationParticipants.userId })
      .from(conversationParticipants)
      .where(and(
        eq(conversationParticipants.conversationId, params.conversationId),
        not(eq(conversationParticipants.userId, params.senderId))
      ));

    for (const other of otherParticipants) {
      const isBlocked = await MessagingService.checkBlockByUsers(params.senderId, other.userId);
      if (isBlocked) {
        throw new ForbiddenError("Cannot send message: This user is blocked or has blocked you.");
      }
    }

    // Calculate sequential sequence number
    const msgList = await db
      .select()
      .from(messages)
      .where(eq(messages.conversationId, params.conversationId));
    
    const nextSequence = msgList.length + 1;

    // Save message record
    const [msg] = await db
      .insert(messages)
      .values({
        conversationId: params.conversationId,
        senderId: params.senderId,
        content: params.content,
        attachments: params.attachments || [],
        isEdited: false,
        isDeleted: false,
        sequence: nextSequence,
      })
      .returning();

    // Trigger timestamp updates on parent conversation
    await db
      .update(conversations)
      .set({ updatedAt: new Date() })
      .where(eq(conversations.id, params.conversationId));

    // Update lastReadAt for sender
    await db
      .update(conversationParticipants)
      .set({ lastReadAt: new Date() })
      .where(and(
        eq(conversationParticipants.conversationId, params.conversationId),
        eq(conversationParticipants.userId, params.senderId)
      ));

    return msg;
  }

  /**
   * Edit a message
   */
  static async editMessage(userId: string, messageId: string, newContent: string) {
    const [msg] = await db
      .select()
      .from(messages)
      .where(eq(messages.id, messageId));

    if (!msg) {
      throw new NotFoundError("Message not found");
    }

    if (msg.senderId !== userId) {
      throw new BadRequestError("Only the original sender can edit this message");
    }

    if (msg.isDeleted) {
      throw new BadRequestError("Cannot edit a deleted message");
    }

    const [updated] = await db
      .update(messages)
      .set({
        content: newContent,
        isEdited: true,
        updatedAt: new Date(),
      })
      .where(eq(messages.id, messageId))
      .returning();

    return updated;
  }

  /**
   * Soft-delete a message
   */
  static async deleteMessage(userId: string, messageId: string) {
    const [msg] = await db
      .select()
      .from(messages)
      .where(eq(messages.id, messageId));

    if (!msg) {
      throw new NotFoundError("Message not found");
    }

    if (msg.senderId !== userId) {
      throw new BadRequestError("Only the original sender can delete this message");
    }

    const [updated] = await db
      .update(messages)
      .set({
        content: "This message was deleted",
        isDeleted: true,
        attachments: [],
        updatedAt: new Date(),
      })
      .where(eq(messages.id, messageId))
      .returning();

    return updated;
  }

  /**
   * Broadcast typing state
   */
  static async setTypingIndicator(userId: string, conversationId: string, isTyping: boolean) {
    // Verify participation
    const [part] = await db
      .select()
      .from(conversationParticipants)
      .where(and(
        eq(conversationParticipants.conversationId, conversationId),
        eq(conversationParticipants.userId, userId)
      ));

    if (!part) {
      throw new BadRequestError("User not a participant");
    }

    return { userId, conversationId, isTyping };
  }

  /**
   * Broadcast presence status
   */
  static async setPresence(userId: string, isOnline: boolean) {
    return { userId, isOnline };
  }

  /**
   * Read mark receipt update
   */
  static async markConversationAsRead(userId: string, conversationId: string) {
    const [updated] = await db
      .update(conversationParticipants)
      .set({ lastReadAt: new Date() })
      .where(and(
        eq(conversationParticipants.conversationId, conversationId),
        eq(conversationParticipants.userId, userId)
      ))
      .returning();

    if (!updated) {
      throw new NotFoundError("Participant registration not found");
    }

    return { success: true };
  }

  /**
   * Retrieve all conversations a user is a participant in, most recently active first
   */
  static async getConversations(userId: string) {
    const userPartList = await db
      .select()
      .from(conversationParticipants)
      .where(eq(conversationParticipants.userId, userId));

    const conversationList = [];

    for (const part of userPartList) {
      const conversationId = part.conversationId;

      const [conv] = await db
        .select()
        .from(conversations)
        .where(eq(conversations.id, conversationId));

      if (!conv) continue;

      const otherParts = await db
        .select()
        .from(conversationParticipants)
        .where(and(
          eq(conversationParticipants.conversationId, conversationId),
          not(eq(conversationParticipants.userId, userId))
        ));

      let otherParticipantProfile = null;
      if (otherParts.length > 0) {
        const otherUserId = otherParts[0].userId;

        const [otherUser] = await db
          .select()
          .from(users)
          .where(eq(users.id, otherUserId));

        if (otherUser) {
          const [profile] = await db
            .select()
            .from(athleteProfiles)
            .where(eq(athleteProfiles.userId, otherUserId));

          otherParticipantProfile = {
            id: otherUserId,
            displayName: profile?.displayName || otherUser.fullName,
            profilePhoto: profile?.profilePhoto || null,
          };
        }
      }

      const [lastMsg] = await db
        .select()
        .from(messages)
        .where(eq(messages.conversationId, conversationId))
        .orderBy(desc(messages.createdAt))
        .limit(1);

      const lastRead = part.lastReadAt ? new Date(part.lastReadAt) : new Date(0);
      const allMsgs = await db
        .select()
        .from(messages)
        .where(eq(messages.conversationId, conversationId));

      const unreadCount = allMsgs.filter((m) => {
        return new Date(m.createdAt) > lastRead && m.senderId !== userId;
      }).length;

      conversationList.push({
        id: conv.id,
        type: conv.type,
        metadata: conv.metadata,
        createdAt: conv.createdAt,
        updatedAt: conv.updatedAt,
        otherParticipant: otherParticipantProfile,
        lastMessage: lastMsg ? {
          id: lastMsg.id,
          senderId: lastMsg.senderId,
          content: lastMsg.content,
          createdAt: lastMsg.createdAt,
        } : null,
        unreadCount,
        lastActiveAt: lastMsg ? new Date(lastMsg.createdAt) : new Date(conv.updatedAt || conv.createdAt),
      });
    }

    conversationList.sort((a, b) => b.lastActiveAt.getTime() - a.lastActiveAt.getTime());

    return conversationList.map(({ lastActiveAt, ...rest }) => rest);
  }

  /**
   * Calculate unread message counts for a user
   */
  static async getUnreadCounts(userId: string) {
    const userPartList = await db
      .select()
      .from(conversationParticipants)
      .where(eq(conversationParticipants.userId, userId));

    let totalUnread = 0;
    const conversationCounts: Record<string, number> = {};

    for (const part of userPartList) {
      const lastRead = part.lastReadAt ? new Date(part.lastReadAt) : new Date(0);

      // Select messages since last read
      const allMsgs = await db
        .select()
        .from(messages)
        .where(eq(messages.conversationId, part.conversationId));

      const unreadCount = allMsgs.filter((m) => {
        return new Date(m.createdAt) > lastRead && m.senderId !== userId;
      }).length;

      conversationCounts[part.conversationId] = unreadCount;
      totalUnread += unreadCount;
    }

    return {
      totalUnread,
      conversationCounts,
    };
  }

  /**
   * Retrieve messages in conversation with cursor pagination
   */
  static async getConversationMessages(userId: string, conversationId: string, limit = 50, offset = 0) {
    // Verify participant
    const [part] = await db
      .select()
      .from(conversationParticipants)
      .where(and(
        eq(conversationParticipants.conversationId, conversationId),
        eq(conversationParticipants.userId, userId)
      ));

    if (!part) {
      throw new BadRequestError("User is not authorized to read these conversation logs");
    }

    const list = await db
      .select()
      .from(messages)
      .where(eq(messages.conversationId, conversationId))
      .orderBy(asc(messages.sequence));

    const paginated = list.slice(offset, offset + limit);
    return paginated;
  }

  /**
   * Scheduled job cleanup implementation
   */
  static async cleanupOldMessages(olderThanDays: number) {
    logger.info({ olderThanDays }, "Running messagelog sweep and soft deletion archive rules");
    const cutoff = new Date();
    cutoff.setDate(cutoff.getDate() - olderThanDays);

    const oldMessages = await db
      .select()
      .from(messages)
      .where(sql`${messages.createdAt} < ${cutoff}`);

    let archiveCount = 0;
    for (const m of oldMessages) {
      if (!m.isDeleted) {
        await db
          .update(messages)
          .set({
            content: "This message was archived by system policies",
            isDeleted: true,
            attachments: [],
            updatedAt: new Date(),
          })
          .where(eq(messages.id, m.id));
        archiveCount++;
      }
    }

    return archiveCount;
  }
}
