import { eq, and, desc, asc, not, isNull, sql, lte } from "drizzle-orm";
import { db } from "../config/db.js";
import { announcements, users } from "@armsphere/db-schema";
import { BadRequestError, NotFoundError, logger } from "@armsphere/core";

export class AnnouncementService {
  /**
   * Provision a new announcement (immediate or scheduled)
   */
  static async createAnnouncement(params: {
    title: string;
    content: string;
    scope: "NATIONAL" | "PROVINCIAL" | "CLUB" | "TOURNAMENT";
    scopeId?: string;
    createdById: string;
    isPinned?: boolean;
    scheduledFor?: Date;
  }) {
    logger.info(params, "Provisioning new announcement entry");

    const [user] = await db
      .select()
      .from(users)
      .where(eq(users.id, params.createdById));

    if (!user) {
      throw new NotFoundError("Creator user not found");
    }

    const isScheduled = !!params.scheduledFor;
    const publishedAt = isScheduled ? null : new Date();

    const [announcement] = await db
      .insert(announcements)
      .values({
        title: params.title,
        content: params.content,
        scope: params.scope,
        scopeId: params.scopeId || null,
        createdById: params.createdById,
        isPinned: params.isPinned || false,
        isArchived: false,
        scheduledFor: params.scheduledFor || null,
        publishedAt,
      })
      .returning();

    // Saved announcement
    return announcement;
  }

  /**
   * Fetch active announcements based on scope filters
   */
  static async getAnnouncements(filters: {
    scope?: "NATIONAL" | "PROVINCIAL" | "CLUB" | "TOURNAMENT";
    scopeId?: string;
    includeArchived?: boolean;
    limit?: number;
    offset?: number;
  }) {
    const limit = filters.limit || 50;
    const offset = filters.offset || 0;

    let conditions = [sql`${announcements.publishedAt} IS NOT NULL`];

    if (filters.scope) {
      conditions.push(eq(announcements.scope, filters.scope));
    }
    if (filters.scopeId) {
      conditions.push(eq(announcements.scopeId, filters.scopeId));
    }
    if (!filters.includeArchived) {
      conditions.push(eq(announcements.isArchived, false));
    }

    const list = await db
      .select()
      .from(announcements)
      .where(and(...conditions))
      .orderBy(desc(announcements.isPinned), desc(announcements.publishedAt));

    const paginated = list.slice(offset, offset + limit);
    return paginated;
  }

  /**
   * Update announcement state (pin, archive, content)
   */
  static async updateAnnouncement(announcementId: string, updates: {
    title?: string;
    content?: string;
    isPinned?: boolean;
    isArchived?: boolean;
  }) {
    const [existing] = await db
      .select()
      .from(announcements)
      .where(eq(announcements.id, announcementId));

    if (!existing) {
      throw new NotFoundError("Announcement not found");
    }

    const [updated] = await db
      .update(announcements)
      .set({
        ...updates,
        updatedAt: new Date(),
      })
      .where(eq(announcements.id, announcementId))
      .returning();

    return updated;
  }

  /**
   * Scheduled job runner publishing implementation
   */
  static async publishScheduledAnnouncements() {
    logger.info("Running announcement scheduler tick check");
    const now = new Date();

    // Query unpublished announcements where scheduledFor <= now
    const scheduledList = await db
      .select()
      .from(announcements)
      .where(and(
        isNull(announcements.publishedAt),
        sql`${announcements.scheduledFor} <= ${now}`
      ));

    let publishedCount = 0;
    for (const ann of scheduledList) {
      const [updated] = await db
        .update(announcements)
        .set({
          publishedAt: new Date(),
          updatedAt: new Date(),
        })
        .where(eq(announcements.id, ann.id))
        .returning();

      publishedCount++;
    }

    return publishedCount;
  }
}
