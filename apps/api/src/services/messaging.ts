import { eq, and, desc, asc, not, isNull, sql, or, inArray } from "drizzle-orm";
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
      .where(or(eq(athleteProfiles.userId, userAId), eq(athleteProfiles.id, userAId)))
      .limit(1);

    const [profileB] = await db
      .select({ id: athleteProfiles.id })
      .from(athleteProfiles)
      .where(or(eq(athleteProfiles.userId, userBId), eq(athleteProfiles.id, userBId)))
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

    let resolvedParticipantId = participantId;
    const [directUser] = await db
      .select({ id: users.id })
      .from(users)
      .where(eq(users.id, participantId))
      .limit(1);
    if (!directUser) {
      const [athleteProfile] = await db
        .select({ userId: athleteProfiles.userId })
        .from(athleteProfiles)
        .where(eq(athleteProfiles.id, participantId))
        .limit(1);
      if (athleteProfile?.userId) {
        resolvedParticipantId = athleteProfile.userId;
      }
    }
    participantId = resolvedParticipantId;

    if (type === "DIRECT") {
      const isBlocked = await MessagingService.checkBlockByUsers(creatorId, participantId);
      if (isBlocked) {
        throw new ForbiddenError("Cannot start conversation: This user is blocked or has blocked you.");
      }
    }

    const directPairKey =
      type === "DIRECT" ? [creatorId, participantId].sort().join(":") : null;

    // For DIRECT, check if conversation already exists between these two users
    if (type === "DIRECT") {
      const existingCPs = await db
        .select()
        .from(conversationParticipants)
        .where(eq(conversationParticipants.userId, creatorId));

      const candidateConvIds = existingCPs.map((cp) => cp.conversationId);
      if (candidateConvIds.length > 0) {
        const [matchingOtherParts, candidateConvs] = await Promise.all([
          db
            .select()
            .from(conversationParticipants)
            .where(
              and(
                inArray(conversationParticipants.conversationId, candidateConvIds),
                eq(conversationParticipants.userId, participantId)
              )
            ),
          db
            .select()
            .from(conversations)
            .where(
              and(
                inArray(conversations.id, candidateConvIds),
                eq(conversations.type, "DIRECT")
              )
            ),
        ]);

        const matchingConvIdSet = new Set(
          matchingOtherParts.map((p) => p.conversationId)
        );
        const matchedConvs = candidateConvs
          .filter((c) => matchingConvIdSet.has(c.id))
          .sort(
            (a, b) =>
              new Date(b.updatedAt || b.createdAt).getTime() -
              new Date(a.updatedAt || a.createdAt).getTime()
          );

        if (matchedConvs.length > 0) {
          return { conversation: matchedConvs[0], isNew: false };
        }
      }
    }

    // Provision new conversation with canonical directPairKey metadata
    const [newConv] = await db
      .insert(conversations)
      .values({
        type,
        metadata: directPairKey ? { directPairKey } : {},
      })
      .returning();

    // Attach participants
    const participantRows =
      creatorId === participantId
        ? [{ conversationId: newConv.id, userId: creatorId, lastReadAt: new Date() }]
        : [
            { conversationId: newConv.id, userId: creatorId, lastReadAt: new Date() },
            { conversationId: newConv.id, userId: participantId, lastReadAt: new Date(0) },
          ];
    await db.insert(conversationParticipants).values(participantRows);

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

    // Guard empty/whitespace-only content so no empty row can ever be
    // inserted, regardless of which caller path reaches the service.
    if (!params.content || params.content.trim().length === 0) {
      throw new BadRequestError("Message content must not be empty.");
    }

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
      throw new ForbiddenError("User is not a participant of this conversation");
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
    if (!newContent || typeof newContent !== "string" || !newContent.trim()) {
      throw new BadRequestError("Message content cannot be empty");
    }

    const [msg] = await db
      .select()
      .from(messages)
      .where(eq(messages.id, messageId));

    if (!msg) {
      throw new NotFoundError("Message not found");
    }

    if (msg.senderId !== userId) {
      throw new ForbiddenError("Only the original sender can edit this message");
    }

    if (msg.isDeleted) {
      throw new BadRequestError("Cannot edit a deleted message");
    }

    const [updated] = await db
      .update(messages)
      .set({
        content: newContent.trim(),
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
      throw new ForbiddenError("Only the original sender can delete this message");
    }

    if (msg.isDeleted) {
      throw new BadRequestError("Cannot delete an already deleted message");
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
    const [conv] = await db
      .select({ id: conversations.id })
      .from(conversations)
      .where(eq(conversations.id, conversationId))
      .limit(1);

    if (!conv) {
      throw new NotFoundError("Conversation not found");
    }

    // Verify participation
    const [part] = await db
      .select()
      .from(conversationParticipants)
      .where(and(
        eq(conversationParticipants.conversationId, conversationId),
        eq(conversationParticipants.userId, userId)
      ));

    if (!part) {
      throw new ForbiddenError("User is not a participant of this conversation");
    }

    return { userId, conversationId, isTyping: Boolean(isTyping) };
  }

  /**
   * Broadcast presence status
   */
  static async setPresence(userId: string, isOnline: boolean) {
    return { userId, isOnline: Boolean(isOnline) };
  }

  /**
   * Read mark receipt update
   */
  static async markConversationAsRead(userId: string, conversationId: string) {
    const [conv] = await db
      .select({ id: conversations.id })
      .from(conversations)
      .where(eq(conversations.id, conversationId))
      .limit(1);

    if (!conv) {
      throw new NotFoundError("Conversation not found");
    }

    const [part] = await db
      .select()
      .from(conversationParticipants)
      .where(and(
        eq(conversationParticipants.conversationId, conversationId),
        eq(conversationParticipants.userId, userId)
      ));

    if (!part) {
      throw new ForbiddenError("User is not a participant of this conversation");
    }

    await db
      .update(conversationParticipants)
      .set({ lastReadAt: new Date() })
      .where(and(
        eq(conversationParticipants.conversationId, conversationId),
        eq(conversationParticipants.userId, userId)
      ));

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

    if (userPartList.length === 0) return [];

    const convIds = Array.from(new Set(userPartList.map((p) => p.conversationId)));

    // Batched queries in parallel — eliminates 6x N+1 per-thread round trips
    const [convRows, allPartRows, allMsgRows] = await Promise.all([
      db.select().from(conversations).where(inArray(conversations.id, convIds)),
      db
        .select()
        .from(conversationParticipants)
        .where(inArray(conversationParticipants.conversationId, convIds)),
      db
        .select()
        .from(messages)
        .where(inArray(messages.conversationId, convIds))
        .orderBy(desc(messages.createdAt)),
    ]);

    const otherUserIds = Array.from(
      new Set(
        allPartRows
          .filter((p) => p.userId !== userId)
          .map((p) => p.userId)
      )
    );

    const [otherUsers, otherProfiles] =
      otherUserIds.length > 0
        ? await Promise.all([
            db.select().from(users).where(inArray(users.id, otherUserIds)),
            db
              .select()
              .from(athleteProfiles)
              .where(inArray(athleteProfiles.userId, otherUserIds)),
          ])
        : [[], []];

    const convMap = new Map(convRows.map((c) => [c.id, c]));
    const userMap = new Map(otherUsers.map((u) => [u.id, u]));
    const profileMap = new Map(otherProfiles.map((p) => [p.userId, p]));

    const otherPartsByConv = new Map<string, typeof allPartRows>();
    for (const p of allPartRows) {
      if (p.userId === userId) continue;
      const arr = otherPartsByConv.get(p.conversationId) || [];
      arr.push(p);
      otherPartsByConv.set(p.conversationId, arr);
    }

    const msgsByConv = new Map<string, typeof allMsgRows>();
    for (const m of allMsgRows) {
      const arr = msgsByConv.get(m.conversationId) || [];
      arr.push(m);
      msgsByConv.set(m.conversationId, arr);
    }

    const rawList = [];

    for (const part of userPartList) {
      const conv = convMap.get(part.conversationId);
      if (!conv) continue;

      const otherParts = otherPartsByConv.get(conv.id) || [];
      let otherParticipantProfile = null;
      let otherUserId: string | null = null;
      if (otherParts.length > 0) {
        otherUserId = otherParts[0].userId;
        const otherUser = userMap.get(otherUserId);
        if (otherUser) {
          const profile = profileMap.get(otherUserId);
          otherParticipantProfile = {
            id: otherUserId,
            displayName: profile?.displayName || otherUser.fullName,
            profilePhoto: profile?.profilePhoto || null,
          };
        }
      }

      const convMsgs = msgsByConv.get(conv.id) || [];
      const lastMsg = convMsgs.length > 0 ? convMsgs[0] : null;
      const lastRead = part.lastReadAt ? new Date(part.lastReadAt) : new Date(0);
      const unreadCount = convMsgs.filter(
        (m) => new Date(m.createdAt) > lastRead && m.senderId !== userId
      ).length;

      const directPairKey =
        conv.type === "DIRECT" && otherUserId
          ? [userId, otherUserId].sort().join(":")
          : null;

      rawList.push({
        id: conv.id,
        type: conv.type,
        metadata: conv.metadata,
        createdAt: conv.createdAt,
        updatedAt: conv.updatedAt,
        otherParticipant: otherParticipantProfile,
        lastMessage: lastMsg
          ? {
              id: lastMsg.id,
              senderId: lastMsg.senderId,
              content: lastMsg.content,
              createdAt: lastMsg.createdAt,
            }
          : null,
        unreadCount,
        lastActiveAt: lastMsg
          ? new Date(lastMsg.createdAt)
          : new Date(conv.updatedAt || conv.createdAt),
        _directPairKey: directPairKey,
      });
    }

    rawList.sort((a, b) => b.lastActiveAt.getTime() - a.lastActiveAt.getTime());

    // Deduplicate any legacy duplicate DIRECT conversations for the same participant pair,
    // keeping the most recently active thread and rolling up unread counts.
    const seenDirectPairs = new Map<string, (typeof rawList)[number]>();
    const deduped: typeof rawList = [];

    for (const item of rawList) {
      if (item._directPairKey) {
        const existing = seenDirectPairs.get(item._directPairKey);
        if (existing) {
          existing.unreadCount += item.unreadCount;
          continue;
        }
        seenDirectPairs.set(item._directPairKey, item);
      }
      deduped.push(item);
    }

    return deduped.map(({ lastActiveAt, _directPairKey, ...rest }) => rest);
  }

  /**
   * Calculate unread message counts for a user
   */
  static async getUnreadCounts(userId: string) {
    const userPartList = await db
      .select()
      .from(conversationParticipants)
      .where(eq(conversationParticipants.userId, userId));

    if (userPartList.length === 0) {
      return { totalUnread: 0, conversationCounts: {} as Record<string, number> };
    }

    const convIds = Array.from(new Set(userPartList.map((p) => p.conversationId)));
    const allMsgs = await db
      .select()
      .from(messages)
      .where(inArray(messages.conversationId, convIds));

    const lastReadByConv = new Map(
      userPartList.map((p) => [
        p.conversationId,
        p.lastReadAt ? new Date(p.lastReadAt) : new Date(0),
      ])
    );

    let totalUnread = 0;
    const conversationCounts: Record<string, number> = {};
    for (const cid of convIds) {
      conversationCounts[cid] = 0;
    }

    for (const m of allMsgs) {
      if (m.senderId === userId) continue;
      const lastRead = lastReadByConv.get(m.conversationId) || new Date(0);
      if (new Date(m.createdAt) > lastRead) {
        conversationCounts[m.conversationId] =
          (conversationCounts[m.conversationId] || 0) + 1;
        totalUnread += 1;
      }
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
      throw new ForbiddenError("User is not authorized to read these conversation logs");
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
