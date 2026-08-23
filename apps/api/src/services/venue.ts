import { eq, and, like, or, SQL, desc } from "drizzle-orm";
import { db } from "../config/db.js";
import { venuePartners, users } from "@armsphere/db-schema";
import { NotFoundError, BadRequestError, ForbiddenError } from "@armsphere/core";

export interface CreateVenueInput {
  name: string;
  city: string;
  province: string;
  address: string;
  contactInfo?: string;
  description?: string;
  logoUrl?: string;
}

export interface UpdateVenueInput {
  name?: string;
  city?: string;
  province?: string;
  address?: string;
  contactInfo?: string;
  description?: string;
  logoUrl?: string;
}

export class VenueService {
  /**
   * Submit a new venue
   */
  static async createVenue(userId: string, input: CreateVenueInput) {
    // Verify user exists
    const [user] = await db
      .select()
      .from(users)
      .where(eq(users.id, userId))
      .limit(1);

    if (!user) {
      throw new NotFoundError("User account not found");
    }

    const [venue] = await db
      .insert(venuePartners)
      .values({
        name: input.name,
        city: input.city,
        province: input.province,
        address: input.address,
        contactInfo: input.contactInfo || null,
        description: input.description || null,
        logoUrl: input.logoUrl || null,
        ownerUserId: userId,
        isVerified: false,
      })
      .returning();

    return venue;
  }

  /**
   * List venues with optional filtering by city and province
   */
  static async getVenues(options: { city?: string; province?: string; limit: number; offset: number }) {
    const { city, province, limit, offset } = options;
    const conditions: SQL[] = [];

    if (city) {
      conditions.push(eq(venuePartners.city, city));
    }
    if (province) {
      conditions.push(eq(venuePartners.province, province));
    }

    const whereClause = conditions.length > 0 ? and(...conditions) : undefined;

    return await db
      .select()
      .from(venuePartners)
      .where(whereClause)
      .orderBy(desc(venuePartners.createdAt))
      .limit(limit)
      .offset(offset);
  }

  /**
   * Retrieve venue details by ID
   */
  static async getVenueById(id: string) {
    const [venue] = await db
      .select()
      .from(venuePartners)
      .where(eq(venuePartners.id, id))
      .limit(1);

    if (!venue) {
      throw new NotFoundError("Venue partner not found");
    }

    return venue;
  }

  /**
   * Edit venue (owner or admin roles only)
   */
  static async updateVenue(
    actorUserId: string,
    targetVenueId: string,
    input: UpdateVenueInput,
    role: string
  ) {
    // 1. Retrieve existing venue
    const [existingVenue] = await db
      .select()
      .from(venuePartners)
      .where(eq(venuePartners.id, targetVenueId))
      .limit(1);

    if (!existingVenue) {
      throw new NotFoundError("Venue partner not found");
    }

    // 2. Ownership & Role check: Only the owner or an Admin/Director can update it
    const isOwner = existingVenue.ownerUserId === actorUserId;
    const isAdmin = ["system_admin", "national_director", "provincial_director"].includes(role.toLowerCase());

    if (!isOwner && !isAdmin) {
      throw new ForbiddenError("You are not authorized to update this venue");
    }

    // 3. Compile update data
    const updatePayload: any = {};
    if (input.name !== undefined) updatePayload.name = input.name;
    if (input.city !== undefined) updatePayload.city = input.city;
    if (input.province !== undefined) updatePayload.province = input.province;
    if (input.address !== undefined) updatePayload.address = input.address;
    if (input.contactInfo !== undefined) updatePayload.contactInfo = input.contactInfo;
    if (input.description !== undefined) updatePayload.description = input.description;
    if (input.logoUrl !== undefined) updatePayload.logoUrl = input.logoUrl;

    updatePayload.updatedAt = new Date();

    const [updatedVenue] = await db
      .update(venuePartners)
      .set(updatePayload)
      .where(eq(venuePartners.id, targetVenueId))
      .returning();

    return updatedVenue;
  }

  /**
   * Verify venue (Admin roles only)
   */
  static async verifyVenue(actorUserId: string, targetVenueId: string, role: string) {
    const isAdmin = ["system_admin", "national_director", "provincial_director"].includes(role.toLowerCase());
    if (!isAdmin) {
      throw new ForbiddenError("You are not authorized to perform admin verification actions");
    }

    const [existingVenue] = await db
      .select()
      .from(venuePartners)
      .where(eq(venuePartners.id, targetVenueId))
      .limit(1);

    if (!existingVenue) {
      throw new NotFoundError("Venue partner not found");
    }

    const [updatedVenue] = await db
      .update(venuePartners)
      .set({
        isVerified: true,
        updatedAt: new Date(),
      })
      .where(eq(venuePartners.id, targetVenueId))
      .returning();

    return updatedVenue;
  }
}
