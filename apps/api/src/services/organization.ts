import { db } from "../config/db.js";
import { organizations, auditLogs, events } from "@armsphere/db-schema";
import { eq, isNull } from "drizzle-orm";
import { hashPassword, comparePassword, generateAccessToken } from "@armsphere/cryptography";
import { BadRequestError, NotFoundError, UnauthorizedError } from "@armsphere/core";
import crypto from "crypto";

export class OrganizationService {
  /**
   * Public list of approved organizations for selection.
   * NEVER returns accessCodeHash.
   */
  static async listApprovedOrganizations() {
    await this.seedCanonicalOrganizationsIfEmpty();
    const rows = await db
      .select({
        id: organizations.id,
        name: organizations.name,
        slug: organizations.slug,
        province: organizations.province,
        city: organizations.city,
        country: organizations.country,
        logoUrl: organizations.logoUrl,
        sanctioningBody: organizations.sanctioningBody,
        status: organizations.status,
        isOnboarded: organizations.isOnboarded,
        presidentName: organizations.presidentName,
        foundationDate: organizations.foundationDate,
        createdAt: organizations.createdAt,
      })
      .from(organizations)
      .where(eq(organizations.status, "APPROVED"));
    return rows;
  }

  /**
   * Verifies pre-shared access code and issues scoped 24h operational token.
   */
  static async verifyAccessCode(organizationId: string, plainCode: string) {
    if (!organizationId || !plainCode) {
      throw new BadRequestError("Organization ID and Access Code are required.");
    }

    const [org] = await db
      .select()
      .from(organizations)
      .where(eq(organizations.id, organizationId))
      .limit(1);

    if (!org || org.status !== "APPROVED") {
      throw new NotFoundError("Organization not found or not approved.");
    }

    const isMatch = await comparePassword(plainCode.trim(), org.accessCodeHash);
    if (!isMatch) {
      throw new UnauthorizedError("Invalid organization access code.");
    }

    // Generate 24-hour tournament operational token for floor staff tablets
    const token = generateAccessToken(
      {
        sub: org.id,
        orgId: org.id,
        orgName: org.name,
        role: "ORGANIZATION_OPERATOR",
      },
      undefined,
      "ORGANIZATION_OPERATOR"
    );

    const { accessCodeHash, ...safeOrg } = org;
    return {
      token,
      organization: safeOrg,
    };
  }

  /**
   * First-time onboarding completion.
   */
  static async completeOnboarding(
    organizationId: string,
    data: {
      presidentName: string;
      foundationDate: Date;
      province: string;
      city: string;
      contactEmail?: string;
      contactPhone?: string;
      logoUrl?: string;
    }
  ) {
    const [updated] = await db
      .update(organizations)
      .set({
        presidentName: data.presidentName.trim(),
        foundationDate: data.foundationDate,
        province: data.province.trim(),
        city: data.city.trim(),
        contactEmail: data.contactEmail?.trim(),
        contactPhone: data.contactPhone?.trim(),
        logoUrl: data.logoUrl?.trim(),
        isOnboarded: true,
        updatedAt: new Date(),
      })
      .where(eq(organizations.id, organizationId))
      .returning();

    if (!updated) {
      throw new NotFoundError("Organization not found.");
    }

    const { accessCodeHash, ...safeOrg } = updated;
    return safeOrg;
  }

  /**
   * Admin creation with secure code generation and hashing.
   */
  static async adminCreateOrganization(data: {
    name: string;
    province: string;
    city?: string;
    accessCode?: string;
    adminUserId?: string;
  }) {
    const slug = data.name.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/(^-|-$)/g, "");
    const plainCode =
      data.accessCode?.trim() ||
      `${slug.slice(0, 4).toUpperCase()}-${new Date().getFullYear()}-${crypto.randomBytes(2).toString("hex").toUpperCase()}`;
    const codeHash = await hashPassword(plainCode);

    const [created] = await db
      .insert(organizations)
      .values({
        name: data.name.trim(),
        slug,
        province: data.province.trim(),
        city: data.city?.trim() || "",
        accessCodeHash: codeHash,
        status: "APPROVED",
        isOnboarded: false,
      })
      .returning();

    if (data.adminUserId) {
      await db.insert(auditLogs).values({
        userId: data.adminUserId,
        action: "ADMIN_PROVISION_ORGANIZATION",
        details: { organizationId: created.id, name: created.name },
      });
    }

    const { accessCodeHash, ...safeOrg } = created;
    return { organization: safeOrg, plainAccessCode: plainCode };
  }

  /**
   * Admin code rotation.
   */
  static async adminRotateCode(organizationId: string, newCode?: string, adminUserId?: string) {
    const plainCode =
      newCode?.trim() ||
      `ROT-${new Date().getFullYear()}-${crypto.randomBytes(3).toString("hex").toUpperCase()}`;
    const codeHash = await hashPassword(plainCode);

    const [updated] = await db
      .update(organizations)
      .set({ accessCodeHash: codeHash, updatedAt: new Date() })
      .where(eq(organizations.id, organizationId))
      .returning();

    if (!updated) {
      throw new NotFoundError("Organization not found.");
    }

    if (adminUserId) {
      await db.insert(auditLogs).values({
        userId: adminUserId,
        action: "ORGANIZATION_CODE_ROTATED",
        details: { organizationId },
      });
    }

    return { plainAccessCode: plainCode };
  }

  /**
   * Ensures canonical federations exist with pre-seeded access codes,
   * and backfills legacy tournaments (where organizationId is null) to PAFF.
   */
  static async seedCanonicalOrganizationsIfEmpty() {
    const existing = await db.select({ id: organizations.id }).from(organizations).limit(1);
    if (existing.length === 0) {
      const canonicals = [
        {
          name: "Pakistan Armwrestling Federation (PAFF)",
          slug: "paff",
          code: "PAFF-2026-X89K",
          province: "Islamabad",
          city: "Islamabad",
          presidentName: "Qaiser Khan",
          sanctioningBody: "WAF / IFA Recognized National Federation",
        },
        {
          name: "East vs West Armwrestling",
          slug: "east-vs-west",
          code: "EVW-2026-GOLD",
          province: "International",
          city: "Istanbul",
          presidentName: "Engin Terzi",
          sanctioningBody: "World Elite Armwrestling Promotion",
        },
        {
          name: "Punjab Armwrestling Federation",
          slug: "punjab-armwrestling",
          code: "PUNJAB-2026-ARM",
          province: "Punjab",
          city: "Lahore",
          presidentName: "Mian Usman",
          sanctioningBody: "PAFF Provincial Affiliate",
        },
        {
          name: "KPK Armwrestling Federation",
          slug: "kpk-armwrestling",
          code: "KPK-2026-ARM",
          province: "KPK",
          city: "Peshawar",
          presidentName: "Fazal Wahab",
          sanctioningBody: "PAFF Provincial Affiliate",
        },
      ];

      for (const item of canonicals) {
        const hash = await hashPassword(item.code);
        await db.insert(organizations).values({
          name: item.name,
          slug: item.slug,
          accessCodeHash: hash,
          province: item.province,
          city: item.city,
          presidentName: item.presidentName,
          sanctioningBody: item.sanctioningBody,
          status: "APPROVED",
          isOnboarded: true,
        }).onConflictDoNothing();
      }
    }

    // Backfill any legacy tournaments with null organizationId to PAFF
    try {
      const [paffOrg] = await db
        .select({ id: organizations.id })
        .from(organizations)
        .where(eq(organizations.slug, "paff"))
        .limit(1);
      if (paffOrg) {
        await db
          .update(events)
          .set({ organizationId: paffOrg.id })
          .where(isNull(events.organizationId));
      }
    } catch (_) {}
  }
}
