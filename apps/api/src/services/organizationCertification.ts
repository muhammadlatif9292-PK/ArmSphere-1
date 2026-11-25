import { eq, and, desc, ilike, or, inArray } from "drizzle-orm";
import { db } from "../config/db.js";
import {
  organizations,
  refereeCertifications,
  roleApplications,
  athleteProfiles,
  users,
  auditLogs,
} from "@armsphere/db-schema";
import {
  BadRequestError,
  ConflictError,
  ForbiddenError,
  NotFoundError,
  logger,
} from "@armsphere/core";
import { UserRole } from "@armsphere/types";
import { UserRoleService } from "./userRole.js";

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export interface OrgActor {
  id: string;
  email?: string;
  role: string;
  orgId?: string;
  orgName?: string;
}

export interface ReviewCertificationRequestInput {
  decision: "APPROVE" | "REJECT";
  certificationLevel?: string;
  reviewNotes?: string;
  notes?: string;
  expiresAt?: string | null;
}

export interface GrantCertificationInput {
  athleteId?: string;
  userId?: string;
  certificationLevel: string;
  notes?: string;
  expiresAt?: string | null;
}

export class OrganizationCertificationService {
  /**
   * Strictly verifies that the authenticated actor is authorized to manage
   * referee certifications for the target organization.
   */
  private static async assertCanManageOrganization(actor: OrgActor, orgId: string) {
    if (!UUID_RE.test(orgId)) {
      throw new BadRequestError("Invalid organization ID format.");
    }

    const [org] = await db
      .select()
      .from(organizations)
      .where(eq(organizations.id, orgId))
      .limit(1);

    if (!org) {
      throw new NotFoundError("Organization not found.");
    }

    const actorRoleUpper = (actor.role || "").toUpperCase();
    const isAdminRole = ["SYSTEM_ADMIN", "NATIONAL_DIRECTOR"].includes(actorRoleUpper);

    let isAuthorized = false;
    let issuedByUserId: string | null = null;

    // 1. Organization-scoped operational token issued by /organizations/verify-access
    if (actor.orgId && actor.orgId === orgId) {
      isAuthorized = true;
      issuedByUserId = null; // Org JWT sub is organizations.id, not users.id
    } else if (actorRoleUpper === "TOURNAMENT_OPERATOR" && actor.id === orgId) {
      isAuthorized = true;
      issuedByUserId = null;
    } else if (isAdminRole) {
      // Server-authoritative DB role check for admin bypass
      const hasAdminGrant = await UserRoleService.hasActiveRole(
        actor.id,
        [UserRole.SYSTEM_ADMIN, UserRole.NATIONAL_DIRECTOR],
        actor.role
      );
      if (hasAdminGrant) {
        isAuthorized = true;
        const [adminUser] = await db
          .select({ id: users.id })
          .from(users)
          .where(eq(users.id, actor.id))
          .limit(1);
        issuedByUserId = adminUser?.id ?? null;
      }
    }

    if (!isAuthorized) {
      throw new ForbiddenError(
        "You are not authorized to manage referee certifications for this organization."
      );
    }

    return { org, issuedByUserId };
  }

  /**
   * GET /organizations/:orgId/certifications/requests
   * Lists incoming and reviewed referee certification requests targeted at orgId.
   */
  static async listRequests(actor: OrgActor, orgId: string, statusFilter?: string) {
    const { org } = await this.assertCanManageOrganization(actor, orgId);

    const conditions = [
      eq(roleApplications.targetOrganizationId, orgId),
      eq(roleApplications.role, UserRole.REFEREE),
    ];

    if (statusFilter && statusFilter.toUpperCase() !== "ALL") {
      conditions.push(eq(roleApplications.status, statusFilter.toUpperCase()));
    }

    const rows = await db
      .select({
        id: roleApplications.id,
        userId: roleApplications.userId,
        athleteId: roleApplications.athleteId,
        targetOrganizationId: roleApplications.targetOrganizationId,
        role: roleApplications.role,
        status: roleApplications.status,
        experienceDetails: roleApplications.experienceDetails,
        certificationNumber: roleApplications.certificationNumber,
        reviewNotes: roleApplications.reviewNotes,
        reviewedAt: roleApplications.reviewedAt,
        createdAt: roleApplications.createdAt,
        updatedAt: roleApplications.updatedAt,
        userFullName: users.fullName,
        userEmail: users.email,
        userProvince: users.province,
        profileId: athleteProfiles.id,
        displayName: athleteProfiles.displayName,
        city: athleteProfiles.city,
        province: athleteProfiles.province,
        weightClass: athleteProfiles.weightClass,
        rightArmElo: athleteProfiles.rightArmElo,
        leftArmElo: athleteProfiles.leftArmElo,
        profilePhoto: athleteProfiles.profilePhoto,
      })
      .from(roleApplications)
      .leftJoin(users, eq(roleApplications.userId, users.id))
      .leftJoin(athleteProfiles, eq(roleApplications.userId, athleteProfiles.userId))
      .where(and(...conditions))
      .orderBy(desc(roleApplications.createdAt));

    return rows.map((r) => ({
      id: r.id,
      userId: r.userId,
      athleteId: r.athleteId || r.profileId || null,
      targetOrganizationId: r.targetOrganizationId,
      targetOrganizationName: org.name,
      role: r.role,
      status: r.status,
      experienceDetails: r.experienceDetails,
      certificationNumber: r.certificationNumber,
      reviewNotes: r.reviewNotes,
      reviewedAt: r.reviewedAt,
      createdAt: r.createdAt,
      updatedAt: r.updatedAt,
      fullName: r.displayName || r.userFullName || "Registered Athlete",
      displayName: r.displayName || r.userFullName || "Registered Athlete",
      email: r.userEmail || null,
      city: r.city || null,
      province: r.province || r.userProvince || null,
      weightClass: r.weightClass || null,
      rightArmElo: r.rightArmElo ?? 1200,
      leftArmElo: r.leftArmElo ?? 1200,
      profilePhoto: r.profilePhoto || null,
    }));
  }

  /**
   * POST /organizations/:orgId/certifications/requests/:requestId/review
   * Approves or declines a referee certification request targeted at orgId.
   */
  static async reviewRequest(
    actor: OrgActor,
    orgId: string,
    requestId: string,
    input: ReviewCertificationRequestInput
  ) {
    const { org, issuedByUserId } = await this.assertCanManageOrganization(actor, orgId);

    if (!UUID_RE.test(requestId)) {
      throw new BadRequestError("Invalid request ID format.");
    }

    const [request] = await db
      .select()
      .from(roleApplications)
      .where(
        and(
          eq(roleApplications.id, requestId),
          eq(roleApplications.targetOrganizationId, orgId),
          eq(roleApplications.role, UserRole.REFEREE)
        )
      )
      .limit(1);

    if (!request) {
      throw new NotFoundError("Referee certification request not found for this organization.");
    }

    if (request.status !== "PENDING") {
      throw new BadRequestError(
        `This request has already been reviewed (status: ${request.status}).`
      );
    }

    const now = new Date();
    const isApprove = input.decision === "APPROVE";
    const nextStatus = isApprove ? "APPROVED" : "REJECTED";
    const reviewNotes = (input.reviewNotes || input.notes || "").trim() || null;

    const [updatedRequest] = await db
      .update(roleApplications)
      .set({
        status: nextStatus,
        reviewerId: issuedByUserId,
        reviewedAt: now,
        reviewNotes,
        updatedAt: now,
      })
      .where(eq(roleApplications.id, requestId))
      .returning();

    let certification: any = null;
    let roleGrant: any = null;

    if (isApprove) {
      const level = (input.certificationLevel || "Regional Official").trim();
      let expiresDate: Date | null = null;
      if (input.expiresAt) {
        expiresDate = new Date(input.expiresAt);
        if (isNaN(expiresDate.getTime())) {
          throw new BadRequestError("Invalid expiration date format.");
        }
      }

      // Resolve athlete profile ID if missing
      let athleteId = request.athleteId || null;
      if (!athleteId) {
        const [profile] = await db
          .select({ id: athleteProfiles.id })
          .from(athleteProfiles)
          .where(eq(athleteProfiles.userId, request.userId))
          .limit(1);
        athleteId = profile?.id ?? null;
      }

      // Avoid duplicating active cert for same org; update if one already exists, else insert
      const [existingActive] = await db
        .select()
        .from(refereeCertifications)
        .where(
          and(
            eq(refereeCertifications.userId, request.userId),
            eq(refereeCertifications.issuingOrganizationId, org.id),
            eq(refereeCertifications.status, "ACTIVE")
          )
        )
        .limit(1);

      if (existingActive) {
        const [updatedCert] = await db
          .update(refereeCertifications)
          .set({
            certificationLevel: level,
            issuingBody: org.name,
            issuedByUserId,
            issuedAt: now,
            expiresAt: expiresDate,
            notes: reviewNotes,
            updatedAt: now,
          })
          .where(eq(refereeCertifications.id, existingActive.id))
          .returning();
        certification = updatedCert;
      } else {
        const [insertedCert] = await db
          .insert(refereeCertifications)
          .values({
            userId: request.userId,
            athleteId,
            issuingOrganizationId: org.id,
            issuedByUserId,
            certificationLevel: level,
            issuedAt: now,
            expiresAt: expiresDate,
            issuingBody: org.name,
            status: "ACTIVE",
            notes: reviewNotes,
          })
          .returning();
        certification = insertedCert;
      }

      roleGrant = await UserRoleService.grantRole(
        request.userId,
        UserRole.REFEREE,
        issuedByUserId || undefined,
        {
          issuingOrganizationId: org.id,
          issuingOrganizationName: org.name,
          certificationId: certification.id,
          certificationLevel: level,
          applicationId: request.id,
          approvedAt: now.toISOString(),
        }
      );

      if (issuedByUserId) {
        await db.insert(auditLogs).values({
          userId: issuedByUserId,
          action: "ORG_REFEREE_CERT_APPROVED",
          details: {
            orgId: org.id,
            orgName: org.name,
            requestId: request.id,
            targetUserId: request.userId,
            certificationId: certification.id,
            certificationLevel: level,
          },
        }).catch(() => {});
      }

      try {
        const { NotificationService } = await import("./notification.js");
        await NotificationService.createNotification({
          userId: request.userId,
          title: `Official Referee Certification Issued`,
          content: `${org.name} approved your referee certification (${level}). You can now officiate events as a certified referee.`,
          priority: "HIGH",
          category: "SYSTEM",
          metadata: {
            organizationId: org.id,
            organizationName: org.name,
            certificationId: certification.id,
            certificationLevel: level,
          },
        });
      } catch (err) {
        logger.warn({ err, requestId }, "Failed to send approval notification");
      }
    } else {
      try {
        const { NotificationService } = await import("./notification.js");
        await NotificationService.createNotification({
          userId: request.userId,
          title: `Referee Certification Request Update`,
          content: `${org.name} declined your referee certification request.${reviewNotes ? ` Note: ${reviewNotes}` : ""}`,
          priority: "MEDIUM",
          category: "SYSTEM",
          metadata: {
            organizationId: org.id,
            organizationName: org.name,
            requestId: request.id,
          },
        });
      } catch (err) {
        logger.warn({ err, requestId }, "Failed to send decline notification");
      }
    }

    return {
      request: {
        ...updatedRequest,
        targetOrganizationName: org.name,
      },
      certification: certification
        ? {
            ...certification,
            issuingOrganizationName: org.name,
          }
        : null,
      roleGrant,
    };
  }

  /**
   * GET /organizations/:orgId/certifications/athletes/search?q=...
   * Real case-insensitive PostgreSQL search across registered ArmSphere athletes.
   */
  static async searchAthletes(actor: OrgActor, orgId: string, query?: string, limit = 25) {
    await this.assertCanManageOrganization(actor, orgId);

    const safeLimit = Math.min(Math.max(limit || 25, 1), 50);
    const trimmed = (query || "").trim();

    const conditions = [
      eq(athleteProfiles.isDeleted, false),
      eq(users.isActive, true),
    ];

    if (trimmed.length > 0) {
      const pattern = `%${trimmed}%`;
      conditions.push(
        or(
          ilike(athleteProfiles.displayName, pattern),
          ilike(users.fullName, pattern),
          ilike(athleteProfiles.city, pattern),
          ilike(athleteProfiles.province, pattern)
        )!
      );
    }

    const rows = await db
      .select({
        athleteId: athleteProfiles.id,
        userId: athleteProfiles.userId,
        displayName: athleteProfiles.displayName,
        fullName: users.fullName,
        city: athleteProfiles.city,
        province: athleteProfiles.province,
        weightClass: athleteProfiles.weightClass,
        rightArmElo: athleteProfiles.rightArmElo,
        leftArmElo: athleteProfiles.leftArmElo,
        profilePhoto: athleteProfiles.profilePhoto,
      })
      .from(athleteProfiles)
      .innerJoin(users, eq(athleteProfiles.userId, users.id))
      .where(and(...conditions))
      .orderBy(desc(athleteProfiles.rightArmElo), desc(athleteProfiles.createdAt))
      .limit(safeLimit);

    if (rows.length === 0) {
      return [];
    }

    const userIds = rows.map((r) => r.userId);
    const existingOrgCerts = await db
      .select({
        id: refereeCertifications.id,
        userId: refereeCertifications.userId,
        certificationLevel: refereeCertifications.certificationLevel,
        status: refereeCertifications.status,
      })
      .from(refereeCertifications)
      .where(
        and(
          eq(refereeCertifications.issuingOrganizationId, orgId),
          eq(refereeCertifications.status, "ACTIVE"),
          inArray(refereeCertifications.userId, userIds)
        )
      );

    const certByUser = new Map(existingOrgCerts.map((c) => [c.userId, c]));

    return rows.map((r) => {
      const activeCert = certByUser.get(r.userId) || null;
      return {
        athleteId: r.athleteId,
        userId: r.userId,
        displayName: r.displayName || r.fullName,
        fullName: r.fullName || r.displayName,
        city: r.city,
        province: r.province,
        weightClass: r.weightClass,
        rightArmElo: r.rightArmElo ?? 1200,
        leftArmElo: r.leftArmElo ?? 1200,
        profilePhoto: r.profilePhoto || null,
        alreadyCertifiedByOrg: !!activeCert,
        activeCertificationId: activeCert?.id ?? null,
        activeCertificationLevel: activeCert?.certificationLevel ?? null,
      };
    });
  }

  /**
   * POST /organizations/:orgId/certifications/grant
   * Directly certifies a searched athlete as an Official Referee issued by orgId.
   */
  static async grantCertification(
    actor: OrgActor,
    orgId: string,
    input: GrantCertificationInput
  ) {
    const { org, issuedByUserId } = await this.assertCanManageOrganization(actor, orgId);

    const level = (input.certificationLevel || "").trim();
    if (!level) {
      throw new BadRequestError("Certification level is required.");
    }

    let targetUserId = input.userId?.trim() || null;
    let targetAthleteId = input.athleteId?.trim() || null;

    if (!targetUserId && !targetAthleteId) {
      throw new BadRequestError("Either athleteId or userId is required.");
    }

    if (targetAthleteId) {
      if (!UUID_RE.test(targetAthleteId)) {
        throw new BadRequestError("Invalid athleteId format.");
      }
      const [profile] = await db
        .select({ id: athleteProfiles.id, userId: athleteProfiles.userId })
        .from(athleteProfiles)
        .where(eq(athleteProfiles.id, targetAthleteId))
        .limit(1);

      if (profile) {
        targetUserId = profile.userId;
        targetAthleteId = profile.id;
      } else if (!targetUserId) {
        // Fallback: caller may have passed users.id in athleteId field
        const [u] = await db
          .select({ id: users.id })
          .from(users)
          .where(eq(users.id, targetAthleteId))
          .limit(1);
        if (u) {
          targetUserId = u.id;
          targetAthleteId = null;
        }
      }
    }

    if (!targetUserId || !UUID_RE.test(targetUserId)) {
      throw new NotFoundError("Target athlete user account not found.");
    }

    const [targetUser] = await db
      .select({ id: users.id, fullName: users.fullName, email: users.email })
      .from(users)
      .where(eq(users.id, targetUserId))
      .limit(1);

    if (!targetUser) {
      throw new NotFoundError("Target user not found.");
    }

    if (!targetAthleteId) {
      const [profile] = await db
        .select({ id: athleteProfiles.id })
        .from(athleteProfiles)
        .where(eq(athleteProfiles.userId, targetUserId))
        .limit(1);
      targetAthleteId = profile?.id ?? null;
    }

    const [existingActive] = await db
      .select({ id: refereeCertifications.id })
      .from(refereeCertifications)
      .where(
        and(
          eq(refereeCertifications.userId, targetUserId),
          eq(refereeCertifications.issuingOrganizationId, org.id),
          eq(refereeCertifications.status, "ACTIVE")
        )
      )
      .limit(1);

    if (existingActive) {
      throw new ConflictError(
        `This athlete already holds an active referee certification issued by ${org.name}.`
      );
    }

    let expiresDate: Date | null = null;
    if (input.expiresAt) {
      expiresDate = new Date(input.expiresAt);
      if (isNaN(expiresDate.getTime())) {
        throw new BadRequestError("Invalid expiration date format.");
      }
    }

    const now = new Date();
    const notes = input.notes?.trim() || null;

    const [certification] = await db
      .insert(refereeCertifications)
      .values({
        userId: targetUserId,
        athleteId: targetAthleteId,
        issuingOrganizationId: org.id,
        issuedByUserId,
        certificationLevel: level,
        issuedAt: now,
        expiresAt: expiresDate,
        issuingBody: org.name,
        status: "ACTIVE",
        notes,
      })
      .returning();

    // Auto-approve any pending referee request from this user to this org so queues stay clean
    await db
      .update(roleApplications)
      .set({
        status: "APPROVED",
        reviewerId: issuedByUserId,
        reviewedAt: now,
        reviewNotes: notes || `Directly certified as ${level} by ${org.name}`,
        updatedAt: now,
      })
      .where(
        and(
          eq(roleApplications.userId, targetUserId),
          eq(roleApplications.targetOrganizationId, org.id),
          eq(roleApplications.role, UserRole.REFEREE),
          eq(roleApplications.status, "PENDING")
        )
      );

    const roleGrant = await UserRoleService.grantRole(
      targetUserId,
      UserRole.REFEREE,
      issuedByUserId || undefined,
      {
        issuingOrganizationId: org.id,
        issuingOrganizationName: org.name,
        certificationId: certification.id,
        certificationLevel: level,
        grantedDirectly: true,
        grantedAt: now.toISOString(),
      }
    );

    if (issuedByUserId) {
      await db.insert(auditLogs).values({
        userId: issuedByUserId,
        action: "ORG_REFEREE_CERT_GRANTED",
        details: {
          orgId: org.id,
          orgName: org.name,
          targetUserId,
          targetAthleteId,
          certificationId: certification.id,
          certificationLevel: level,
        },
      }).catch(() => {});
    }

    try {
      const { NotificationService } = await import("./notification.js");
      await NotificationService.createNotification({
        userId: targetUserId,
        title: `Official Referee Certification Granted`,
        content: `${org.name} certified you as an Official Referee (${level}). Your certification is now active in ArmSphere.`,
        priority: "HIGH",
        category: "SYSTEM",
        metadata: {
          organizationId: org.id,
          organizationName: org.name,
          certificationId: certification.id,
          certificationLevel: level,
        },
      });
    } catch (err) {
      logger.warn({ err, targetUserId }, "Failed to send direct grant notification");
    }

    return {
      certification: {
        ...certification,
        issuingOrganizationName: org.name,
        fullName: targetUser.fullName,
      },
      roleGrant,
    };
  }

  /**
   * GET /organizations/:orgId/certifications
   * Lists all real referee certifications issued by orgId (authenticated org management view).
   */
  static async listCertifications(actor: OrgActor, orgId: string, statusFilter?: string) {
    const { org } = await this.assertCanManageOrganization(actor, orgId);

    const conditions = [eq(refereeCertifications.issuingOrganizationId, orgId)];
    if (statusFilter && statusFilter.toUpperCase() !== "ALL") {
      conditions.push(eq(refereeCertifications.status, statusFilter.toUpperCase()));
    }

    const rows = await db
      .select({
        id: refereeCertifications.id,
        userId: refereeCertifications.userId,
        athleteId: refereeCertifications.athleteId,
        issuingOrganizationId: refereeCertifications.issuingOrganizationId,
        certificationLevel: refereeCertifications.certificationLevel,
        issuedAt: refereeCertifications.issuedAt,
        expiresAt: refereeCertifications.expiresAt,
        issuingBody: refereeCertifications.issuingBody,
        status: refereeCertifications.status,
        notes: refereeCertifications.notes,
        createdAt: refereeCertifications.createdAt,
        updatedAt: refereeCertifications.updatedAt,
        userFullName: users.fullName,
        userEmail: users.email,
        profileId: athleteProfiles.id,
        displayName: athleteProfiles.displayName,
        city: athleteProfiles.city,
        province: athleteProfiles.province,
        profilePhoto: athleteProfiles.profilePhoto,
      })
      .from(refereeCertifications)
      .leftJoin(users, eq(refereeCertifications.userId, users.id))
      .leftJoin(athleteProfiles, eq(refereeCertifications.userId, athleteProfiles.userId))
      .where(and(...conditions))
      .orderBy(desc(refereeCertifications.issuedAt));

    return rows.map((r) => ({
      id: r.id,
      userId: r.userId,
      athleteId: r.athleteId || r.profileId || null,
      issuingOrganizationId: r.issuingOrganizationId,
      issuingOrganizationName: org.name,
      issuingBody: org.name,
      certificationLevel: r.certificationLevel,
      issuedAt: r.issuedAt,
      expiresAt: r.expiresAt,
      status: r.status,
      notes: r.notes,
      createdAt: r.createdAt,
      updatedAt: r.updatedAt,
      fullName: r.displayName || r.userFullName || "Certified Official",
      displayName: r.displayName || r.userFullName || "Certified Official",
      email: r.userEmail || null,
      city: r.city || null,
      province: r.province || null,
      profilePhoto: r.profilePhoto || null,
    }));
  }

  /**
   * PATCH /organizations/:orgId/certifications/:certId/revoke
   * Revokes a certification issued by orgId (strictly scoped to orgId).
   */
  static async revokeCertification(
    actor: OrgActor,
    orgId: string,
    certId: string,
    reason?: string
  ) {
    const { org, issuedByUserId } = await this.assertCanManageOrganization(actor, orgId);

    if (!UUID_RE.test(certId)) {
      throw new BadRequestError("Invalid certification ID format.");
    }

    const [existing] = await db
      .select()
      .from(refereeCertifications)
      .where(
        and(
          eq(refereeCertifications.id, certId),
          eq(refereeCertifications.issuingOrganizationId, org.id)
        )
      )
      .limit(1);

    if (!existing) {
      throw new NotFoundError(
        "Certification not found for this organization."
      );
    }

    if (existing.status === "REVOKED") {
      return {
        ...existing,
        issuingOrganizationName: org.name,
      };
    }

    const now = new Date();
    const cleanedReason = reason?.trim() || null;
    const updatedNotes = cleanedReason
      ? existing.notes
        ? `${existing.notes}\nRevoked: ${cleanedReason}`
        : `Revoked: ${cleanedReason}`
      : existing.notes;

    const [updated] = await db
      .update(refereeCertifications)
      .set({
        status: "REVOKED",
        notes: updatedNotes,
        updatedAt: now,
      })
      .where(
        and(
          eq(refereeCertifications.id, certId),
          eq(refereeCertifications.issuingOrganizationId, org.id)
        )
      )
      .returning();

    if (issuedByUserId) {
      await db.insert(auditLogs).values({
        userId: issuedByUserId,
        action: "ORG_REFEREE_CERT_REVOKED",
        details: {
          orgId: org.id,
          orgName: org.name,
          certificationId: certId,
          targetUserId: existing.userId,
          reason: cleanedReason,
        },
      }).catch(() => {});
    }

    try {
      const { NotificationService } = await import("./notification.js");
      await NotificationService.createNotification({
        userId: existing.userId,
        title: `Referee Certification Revoked`,
        content: `${org.name} has revoked your ${existing.certificationLevel} referee certification.${cleanedReason ? ` Reason: ${cleanedReason}` : ""}`,
        priority: "HIGH",
        category: "SYSTEM",
        metadata: {
          organizationId: org.id,
          organizationName: org.name,
          certificationId: certId,
        },
      });
    } catch (err) {
      logger.warn({ err, certId }, "Failed to send revocation notification");
    }

    return {
      ...updated,
      issuingOrganizationName: org.name,
    };
  }

  /**
   * Public read-only list of ACTIVE certified officials for Organization Profile screens.
   * Exposes only non-sensitive public fields (no emails, no private review notes).
   */
  static async listPublicOfficials(orgIdOrSlug: string) {
    let org: any = null;
    if (UUID_RE.test(orgIdOrSlug)) {
      const [found] = await db
        .select({ id: organizations.id, name: organizations.name })
        .from(organizations)
        .where(eq(organizations.id, orgIdOrSlug))
        .limit(1);
      org = found || null;
    } else {
      const [found] = await db
        .select({ id: organizations.id, name: organizations.name })
        .from(organizations)
        .where(eq(organizations.slug, orgIdOrSlug))
        .limit(1);
      org = found || null;
    }

    if (!org) {
      throw new NotFoundError("Organization not found.");
    }

    const rows = await db
      .select({
        id: refereeCertifications.id,
        userId: refereeCertifications.userId,
        athleteId: refereeCertifications.athleteId,
        issuingOrganizationId: refereeCertifications.issuingOrganizationId,
        certificationLevel: refereeCertifications.certificationLevel,
        issuedAt: refereeCertifications.issuedAt,
        status: refereeCertifications.status,
        userFullName: users.fullName,
        profileId: athleteProfiles.id,
        displayName: athleteProfiles.displayName,
        city: athleteProfiles.city,
        province: athleteProfiles.province,
        profilePhoto: athleteProfiles.profilePhoto,
      })
      .from(refereeCertifications)
      .leftJoin(users, eq(refereeCertifications.userId, users.id))
      .leftJoin(athleteProfiles, eq(refereeCertifications.userId, athleteProfiles.userId))
      .where(
        and(
          eq(refereeCertifications.issuingOrganizationId, org.id),
          eq(refereeCertifications.status, "ACTIVE")
        )
      )
      .orderBy(desc(refereeCertifications.issuedAt));

    return rows.map((r) => ({
      id: r.id,
      userId: r.userId,
      athleteId: r.athleteId || r.profileId || null,
      issuingOrganizationId: r.issuingOrganizationId,
      issuingOrganizationName: org.name,
      certificationLevel: r.certificationLevel,
      issuedAt: r.issuedAt,
      status: r.status,
      fullName: r.displayName || r.userFullName || "Certified Official",
      displayName: r.displayName || r.userFullName || "Certified Official",
      city: r.city || null,
      province: r.province || null,
      profilePhoto: r.profilePhoto || null,
    }));
  }
}
