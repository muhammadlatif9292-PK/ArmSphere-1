import { eq, and, desc, isNull, or, gt, lte, inArray } from "drizzle-orm";
import { db } from "../config/db.js";
import { refereeCertifications, users, notifications } from "@armsphere/db-schema";
import { NotFoundError, BadRequestError, ForbiddenError, logger } from "@armsphere/core";

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

  /**
   * Process expired referee certifications:
   * 1. Finds all ACTIVE certifications with expiresAt <= now.
   * 2. Sets their status to "EXPIRED" and updatedAt to now.
   * 3. Dispatches notifications to affected referees.
   *
   * Note on province: The `referee_certifications` table does not contain a `province`
   * column. When filtering or grouping by province (e.g. for provincial directors),
   * join through `users` table where `users.province` is stored.
   */
  static async processExpiredCertifications(now: Date = new Date()): Promise<{ expiredCount: number; expiredIds: string[] }> {
    const expiredCerts = await db
      .select({
        id: refereeCertifications.id,
        userId: refereeCertifications.userId,
        certificationLevel: refereeCertifications.certificationLevel,
        expiresAt: refereeCertifications.expiresAt,
      })
      .from(refereeCertifications)
      .where(
        and(
          eq(refereeCertifications.status, "ACTIVE"),
          lte(refereeCertifications.expiresAt, now)
        )
      );

    if (expiredCerts.length === 0) {
      return { expiredCount: 0, expiredIds: [] };
    }

    const expiredIds = expiredCerts.map((c) => c.id);

    await db
      .update(refereeCertifications)
      .set({
        status: "EXPIRED",
        updatedAt: now,
      })
      .where(
        and(
          inArray(refereeCertifications.id, expiredIds),
          eq(refereeCertifications.status, "ACTIVE")
        )
      );

    const { NotificationService } = await import("./notification.js");
    for (const cert of expiredCerts) {
      try {
        const dedupeGroupId = `cert-expiry-${cert.id}`;
        const existingNotification = await db
          .select({ id: notifications.id })
          .from(notifications)
          .where(
            and(
              eq(notifications.userId, cert.userId),
              eq(notifications.groupId, dedupeGroupId)
            )
          )
          .limit(1);

        if (existingNotification.length > 0) {
          continue;
        }

        await NotificationService.createNotification({
          userId: cert.userId,
          title: "Referee Certification Expired",
          content: `Your ${cert.certificationLevel} referee certification expired on ${cert.expiresAt ? new Date(cert.expiresAt).toLocaleDateString() : "today"}. Please complete recertification to continue officiating.`,
          priority: "HIGH",
          category: "SYSTEM",
          groupId: dedupeGroupId,
          metadata: {
            certificationId: cert.id,
            certificationLevel: cert.certificationLevel,
            expiredAt: cert.expiresAt,
          },
        });
      } catch (notifyErr) {
        logger.error({ notifyErr, certId: cert.id }, "Failed to send certification expiry notification");
      }
    }

    logger.info({ count: expiredIds.length }, "Successfully transitioned expired referee certifications to EXPIRED");
    return { expiredCount: expiredIds.length, expiredIds };
  }

  /**
   * List certifications by province with proper users table join.
   * Resolves the schema invariant that `referee_certifications` has no province column;
   * province is stored on the canonical `users` table.
   */
  static async listCertificationsByProvince(
    actorUserId: string,
    targetProvince: string
  ) {
    const [actorUser] = await db
      .select()
      .from(users)
      .where(eq(users.id, actorUserId))
      .limit(1);

    if (!actorUser) {
      throw new NotFoundError("Actor user not found");
    }

    const actorRole = (actorUser.role || "").toLowerCase();
    const isAdmin = ["system_admin", "national_director"].includes(actorRole);
    const isProvincialDirector = actorRole === "provincial_director";

    if (!isAdmin && !isProvincialDirector) {
      throw new ForbiddenError("You are not authorized to view certifications by province");
    }

    if (isProvincialDirector) {
      const actorProvince = actorUser.province || (actorUser as any).regionalCoverage;
      if (!actorProvince || actorProvince.trim().toLowerCase() !== targetProvince.trim().toLowerCase()) {
        throw new ForbiddenError(
          `Provincial directors can only view certifications for their own province (${actorProvince || "none"})`
        );
      }
    }

    // Find users belonging to the requested province
    const provinceUsers = await db
      .select({
        id: users.id,
        fullName: users.fullName,
        email: users.email,
        province: users.province,
      })
      .from(users)
      .where(eq(users.province, targetProvince));

    if (provinceUsers.length === 0) {
      return [];
    }

    const userMap = new Map(provinceUsers.map((u) => [u.id, u]));
    const userIds = provinceUsers.map((u) => u.id);

    const certs = await db
      .select()
      .from(refereeCertifications)
      .where(inArray(refereeCertifications.userId, userIds))
      .orderBy(desc(refereeCertifications.issuedAt));

    return certs
      .filter((c) => userMap.has(c.userId))
      .map((c) => ({
        ...c,
        userFullName: userMap.get(c.userId)?.fullName,
        userEmail: userMap.get(c.userId)?.email,
        userProvince: userMap.get(c.userId)?.province,
      }));
  }
}
