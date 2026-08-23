import { eq, and, desc, isNull, or, gt } from "drizzle-orm";
import { db } from "../config/db.js";
import { refereeCertifications, users } from "@armsphere/db-schema";
import { NotFoundError, BadRequestError, ForbiddenError } from "@armsphere/core";

export interface IssueCertificationInput {
  certificationLevel: string;
  issuedAt: string;
  expiresAt?: string;
  issuingBody: string;
}

export class RefereeCertificationService {
  /**
   * Check if user has an active, unexpired certification
   */
  static async hasActiveCertification(userId: string): Promise<boolean> {
    const activeCerts = await db
      .select()
      .from(refereeCertifications)
      .where(
        and(
          eq(refereeCertifications.userId, userId),
          eq(refereeCertifications.status, "ACTIVE"),
          or(
            isNull(refereeCertifications.expiresAt),
            gt(refereeCertifications.expiresAt, new Date())
          )
        )
      )
      .limit(1);

    return activeCerts.length > 0;
  }

  /**
   * Enforce that a referee must have an active certification.
   * Other roles bypass this check.
   */
  static async assertActiveCertification(userId: string): Promise<void> {
    const [user] = await db
      .select()
      .from(users)
      .where(eq(users.id, userId))
      .limit(1);

    if (!user) {
      throw new NotFoundError("User not found");
    }

    if (user.role === "REFEREE") {
      const hasActive = await this.hasActiveCertification(userId);
      if (!hasActive) {
        throw new ForbiddenError(
          "Referee does not hold an active referee certification or certification has expired/been revoked."
        );
      }
    }
  }

  /**
   * Issue a certification to a user (admin roles only)
   */
  static async issueCertification(
    actorRole: string,
    targetUserId: string,
    input: IssueCertificationInput
  ) {
    const isAdmin = ["system_admin", "national_director", "provincial_director"].includes(
      actorRole.toLowerCase()
    );

    if (!isAdmin) {
      throw new ForbiddenError("You are not authorized to issue certifications");
    }

    const [targetUser] = await db
      .select()
      .from(users)
      .where(eq(users.id, targetUserId))
      .limit(1);

    if (!targetUser) {
      throw new NotFoundError("Target user not found");
    }

    if (!input.certificationLevel || input.certificationLevel.trim().length === 0) {
      throw new BadRequestError("Certification level is required");
    }
    if (!input.issuedAt || input.issuedAt.trim().length === 0) {
      throw new BadRequestError("Issued at date is required");
    }
    if (!input.issuingBody || input.issuingBody.trim().length === 0) {
      throw new BadRequestError("Issuing body is required");
    }

    const issuedDate = new Date(input.issuedAt);
    if (isNaN(issuedDate.getTime())) {
      throw new BadRequestError("Invalid issuedAt date format");
    }

    let expiresDate: Date | null = null;
    if (input.expiresAt) {
      expiresDate = new Date(input.expiresAt);
      if (isNaN(expiresDate.getTime())) {
        throw new BadRequestError("Invalid expiresAt date format");
      }
    }

    const [certification] = await db
      .insert(refereeCertifications)
      .values({
        userId: targetUserId,
        certificationLevel: input.certificationLevel.trim(),
        issuedAt: issuedDate,
        expiresAt: expiresDate,
        issuingBody: input.issuingBody.trim(),
        status: "ACTIVE",
      })
      .returning();

    return certification;
  }

  /**
   * List certifications of a specific referee (own user or admin view)
   */
  static async listCertifications(actorUserId: string, actorRole: string, targetUserId: string) {
    const isAdmin = ["system_admin", "national_director", "provincial_director"].includes(
      actorRole.toLowerCase()
    );

    const isOwnUser = actorUserId === targetUserId;

    if (!isAdmin && !isOwnUser) {
      throw new ForbiddenError("You are not authorized to view these certifications");
    }

    return await db
      .select()
      .from(refereeCertifications)
      .where(eq(refereeCertifications.userId, targetUserId))
      .orderBy(desc(refereeCertifications.issuedAt));
  }

  /**
   * Revoke a certification (admin only)
   */
  static async revokeCertification(actorRole: string, id: string) {
    const isAdmin = ["system_admin", "national_director", "provincial_director"].includes(
      actorRole.toLowerCase()
    );

    if (!isAdmin) {
      throw new ForbiddenError("You are not authorized to revoke certifications");
    }

    const [existing] = await db
      .select()
      .from(refereeCertifications)
      .where(eq(refereeCertifications.id, id))
      .limit(1);

    if (!existing) {
      throw new NotFoundError("Referee certification not found");
    }

    const [updated] = await db
      .update(refereeCertifications)
      .set({
        status: "REVOKED",
        updatedAt: new Date(),
      })
      .where(eq(refereeCertifications.id, id))
      .returning();

    return updated;
  }
}
