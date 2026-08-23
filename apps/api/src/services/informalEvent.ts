import { eq, and, gte, lte, SQL, desc } from "drizzle-orm";
import { db } from "../config/db.js";
import { informalEvents, informalEventParticipants, users, athleteProfiles } from "@armsphere/db-schema";
import { NotFoundError, BadRequestError, ForbiddenError } from "@armsphere/core";

export interface CreateInformalEventInput {
  title: string;
  description: string;
  city: string;
  province?: string;
  scheduledAt: string; // ISO string
  maxParticipants?: number;
  isPublic?: boolean;
}

export class InformalEventService {
  /**
   * Create a new informal event. Creator automatically becomes the first participant.
   */
  static async createEvent(userId: string, input: CreateInformalEventInput) {
    // Verify user exists
    const [user] = await db
      .select()
      .from(users)
      .where(eq(users.id, userId))
      .limit(1);

    if (!user) {
      throw new NotFoundError("User account not found");
    }

    if (!input.title || input.title.trim().length === 0) {
      throw new BadRequestError("Title is required");
    }
    if (!input.description || input.description.trim().length === 0) {
      throw new BadRequestError("Description is required");
    }
    if (!input.city || input.city.trim().length === 0) {
      throw new BadRequestError("City is required");
    }
    if (!input.scheduledAt) {
      throw new BadRequestError("Scheduled date and time is required");
    }

    const scheduledDate = new Date(input.scheduledAt);
    if (isNaN(scheduledDate.getTime())) {
      throw new BadRequestError("Invalid scheduled date format");
    }

    if (scheduledDate <= new Date()) {
      throw new BadRequestError("Scheduled time must be in the future");
    }

    if (input.maxParticipants !== undefined && input.maxParticipants !== null) {
      if (input.maxParticipants < 1) {
        throw new BadRequestError("Max participants must be at least 1");
      }
    }

    // Insert informal event inside a transaction so we guarantee the creator is added
    return await db.transaction(async (tx) => {
      const [event] = await tx
        .insert(informalEvents)
        .values({
          createdByUserId: userId,
          title: input.title.trim(),
          description: input.description.trim(),
          city: input.city.trim(),
          province: input.province?.trim() || null,
          scheduledAt: scheduledDate,
          maxParticipants: input.maxParticipants || null,
          isPublic: input.isPublic !== undefined ? input.isPublic : true,
        })
        .returning();

      // Add creator as participant
      await tx.insert(informalEventParticipants).values({
        informalEventId: event.id,
        userId: userId,
      });

      return {
        ...event,
        participantCount: 1,
      };
    });
  }

  /**
   * Get a paginated list of informal events, filterable by city, date range, upcoming by default.
   */
  static async getEvents(options: {
    city?: string;
    startDate?: string;
    endDate?: string;
    upcomingOnly?: boolean;
    limit: number;
    offset: number;
  }) {
    const { city, startDate, endDate, upcomingOnly = true, limit, offset } = options;
    const conditions: SQL[] = [];

    // Filter by public events by default
    conditions.push(eq(informalEvents.isPublic, true));

    if (city) {
      conditions.push(eq(informalEvents.city, city));
    }

    const now = new Date();
    if (startDate) {
      const start = new Date(startDate);
      if (!isNaN(start.getTime())) {
        conditions.push(gte(informalEvents.scheduledAt, start));
      }
    } else if (upcomingOnly) {
      conditions.push(gte(informalEvents.scheduledAt, now));
    }

    if (endDate) {
      const end = new Date(endDate);
      if (!isNaN(end.getTime())) {
        conditions.push(lte(informalEvents.scheduledAt, end));
      }
    }

    const whereClause = conditions.length > 0 ? and(...conditions) : undefined;

    const eventsList = await db
      .select()
      .from(informalEvents)
      .where(whereClause)
      .orderBy(desc(informalEvents.scheduledAt))
      .limit(limit)
      .offset(offset);

    // Fetch participant counts for each event
    const enrichedEvents = await Promise.all(
      eventsList.map(async (event) => {
        const participants = await db
          .select()
          .from(informalEventParticipants)
          .where(eq(informalEventParticipants.informalEventId, event.id));

        return {
          ...event,
          participantCount: participants.length,
        };
      })
    );

    return enrichedEvents;
  }

  /**
   * Get detail view of an informal event including the list of participants.
   */
  static async getEventById(id: string) {
    const [event] = await db
      .select()
      .from(informalEvents)
      .where(eq(informalEvents.id, id))
      .limit(1);

    if (!event) {
      throw new NotFoundError("Informal event not found");
    }

    // Get list of participants (names/avatars only)
    const participants = await db
      .select({
        id: users.id,
        fullName: users.fullName,
        username: users.username,
        profilePhoto: athleteProfiles.profilePhoto,
      })
      .from(informalEventParticipants)
      .innerJoin(users, eq(informalEventParticipants.userId, users.id))
      .leftJoin(athleteProfiles, eq(users.id, athleteProfiles.userId))
      .where(eq(informalEventParticipants.informalEventId, id));

    return {
      ...event,
      participants,
      participantCount: participants.length,
    };
  }

  /**
   * Join an informal event. Verifies capacity, past dates, and duplicates.
   */
  static async joinEvent(userId: string, eventId: string) {
    const [event] = await db
      .select()
      .from(informalEvents)
      .where(eq(informalEvents.id, eventId))
      .limit(1);

    if (!event) {
      throw new NotFoundError("Informal event not found");
    }

    // Reject joining if the event is already in the past
    if (new Date(event.scheduledAt) <= new Date()) {
      throw new BadRequestError("Cannot join an event that has already occurred");
    }

    // Check duplicate joins
    const [alreadyJoined] = await db
      .select()
      .from(informalEventParticipants)
      .where(
        and(
          eq(informalEventParticipants.informalEventId, eventId),
          eq(informalEventParticipants.userId, userId)
        )
      )
      .limit(1);

    if (alreadyJoined) {
      throw new BadRequestError("You have already joined this event");
    }

    // Check capacity
    if (event.maxParticipants !== null) {
      const participants = await db
        .select()
        .from(informalEventParticipants)
        .where(eq(informalEventParticipants.informalEventId, eventId));

      if (participants.length >= event.maxParticipants) {
        throw new BadRequestError("This event has reached its maximum participant limit");
      }
    }

    // Join event
    const [participant] = await db
      .insert(informalEventParticipants)
      .values({
        informalEventId: eventId,
        userId: userId,
      })
      .returning();

    return participant;
  }

  /**
   * Leave an informal event. Creator is prevented from leaving.
   */
  static async leaveEvent(userId: string, eventId: string) {
    const [event] = await db
      .select()
      .from(informalEvents)
      .where(eq(informalEvents.id, eventId))
      .limit(1);

    if (!event) {
      throw new NotFoundError("Informal event not found");
    }

    // Creator cannot leave their own event
    if (event.createdByUserId === userId) {
      throw new BadRequestError("Creator cannot leave their own event (they'd need to cancel it instead)");
    }

    const [participant] = await db
      .select()
      .from(informalEventParticipants)
      .where(
        and(
          eq(informalEventParticipants.informalEventId, eventId),
          eq(informalEventParticipants.userId, userId)
        )
      )
      .limit(1);

    if (!participant) {
      throw new BadRequestError("You are not registered as a participant of this event");
    }

    // Leave event
    await db
      .delete(informalEventParticipants)
      .where(
        and(
          eq(informalEventParticipants.informalEventId, eventId),
          eq(informalEventParticipants.userId, userId)
        )
      );

    return { success: true };
  }

  /**
   * Delete/cancel an event (creator or admin only).
   */
  static async deleteEvent(userId: string, eventId: string, role: string) {
    const [event] = await db
      .select()
      .from(informalEvents)
      .where(eq(informalEvents.id, eventId))
      .limit(1);

    if (!event) {
      throw new NotFoundError("Informal event not found");
    }

    const isCreator = event.createdByUserId === userId;
    const isAdmin = ["system_admin", "national_director", "provincial_director"].includes(
      role.toLowerCase()
    );

    if (!isCreator && !isAdmin) {
      throw new ForbiddenError("You are not authorized to delete this event");
    }

    await db.delete(informalEvents).where(eq(informalEvents.id, eventId));

    return { success: true };
  }
}
