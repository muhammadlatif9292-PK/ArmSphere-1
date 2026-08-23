import { eq, and, desc, SQL } from "drizzle-orm";
import { db } from "../config/db.js";
import { talentNominations, users } from "@armsphere/db-schema";
import { NotFoundError, BadRequestError, ForbiddenError } from "@armsphere/core";

export interface CreateNominationInput {
  nomineeName: string;
  nomineeContact?: string;
  city: string;
  province: string;
  notes?: string;
}

export class NominationService {
  /**
   * Submit a new talent nomination
   */
  static async createNomination(userId: string, input: CreateNominationInput) {
    // Verify user exists
    const [user] = await db
      .select()
      .from(users)
      .where(eq(users.id, userId))
      .limit(1);

    if (!user) {
      throw new NotFoundError("User account not found");
    }

    if (!input.nomineeName || input.nomineeName.trim().length === 0) {
      throw new BadRequestError("Nominee name is required");
    }
    if (!input.city || input.city.trim().length === 0) {
      throw new BadRequestError("City is required");
    }
    if (!input.province || input.province.trim().length === 0) {
      throw new BadRequestError("Province is required");
    }

    const [nomination] = await db
      .insert(talentNominations)
      .values({
        nominatedByUserId: userId,
        nomineeName: input.nomineeName.trim(),
        nomineeContact: input.nomineeContact?.trim() || null,
        city: input.city.trim(),
        province: input.province.trim(),
        notes: input.notes?.trim() || null,
        status: "PENDING",
      })
      .returning();

    return nomination;
  }

  /**
   * List all nominations (admin roles only)
   */
  static async getNominations(options: {
    status?: string;
    city?: string;
    province?: string;
    limit: number;
    offset: number;
  }) {
    const { status, city, province, limit, offset } = options;
    const conditions: SQL[] = [];

    if (status) {
      conditions.push(eq(talentNominations.status, status));
    }
    if (city) {
      conditions.push(eq(talentNominations.city, city));
    }
    if (province) {
      conditions.push(eq(talentNominations.province, province));
    }

    const whereClause = conditions.length > 0 ? and(...conditions) : undefined;

    return await db
      .select()
      .from(talentNominations)
      .where(whereClause)
      .orderBy(desc(talentNominations.createdAt))
      .limit(limit)
      .offset(offset);
  }

  /**
   * Get own submitted nominations
   */
  static async getOwnNominations(userId: string) {
    return await db
      .select()
      .from(talentNominations)
      .where(eq(talentNominations.nominatedByUserId, userId))
      .orderBy(desc(talentNominations.createdAt));
  }

  /**
   * Update nomination status (admin only)
   */
  static async updateNominationStatus(
    actorUserId: string,
    nominationId: string,
    newStatus: string,
    role: string
  ) {
    const isAdmin = ["system_admin", "national_director", "provincial_director"].includes(
      role.toLowerCase()
    );

    if (!isAdmin) {
      throw new ForbiddenError("You are not authorized to update nomination status");
    }

    const allowedStatuses = ["PENDING", "CONTACTED", "REGISTERED", "DECLINED"];
    const normalizedStatus = newStatus.toUpperCase();

    if (!allowedStatuses.includes(normalizedStatus)) {
      throw new BadRequestError(
        `Invalid status. Must be one of: ${allowedStatuses.join(", ")}`
      );
    }

    const [existing] = await db
      .select()
      .from(talentNominations)
      .where(eq(talentNominations.id, nominationId))
      .limit(1);

    if (!existing) {
      throw new NotFoundError("Talent nomination not found");
    }

    const [updated] = await db
      .update(talentNominations)
      .set({
        status: normalizedStatus,
      })
      .where(eq(talentNominations.id, nominationId))
      .returning();

    return updated;
  }
}
