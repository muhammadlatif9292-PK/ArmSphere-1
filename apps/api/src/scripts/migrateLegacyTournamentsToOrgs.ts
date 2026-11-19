import { eq, isNull } from "drizzle-orm";
import { db } from "../config/db.js";
import { events, organizations } from "@armsphere/db-schema";
import { OrganizationService } from "../services/organization.js";
import { logger } from "@armsphere/core";

/**
 * Legacy Tournament Backfill Migration Script
 *
 * Links existing tournaments (`events`) that have a null `organizationId`
 * to the canonical "Pakistan Armwrestling Federation (PAFF)" organization record
 * so that all pre-existing tournaments immediately appear inside the Organization Deck.
 */
export async function migrateLegacyTournamentsToOrgs() {
  logger.info("Starting legacy tournament to organization backfill migration...");

  // Ensure canonical organizations exist (including PAFF)
  await OrganizationService.listApprovedOrganizations();

  const [paffOrg] = await db
    .select()
    .from(organizations)
    .where(eq(organizations.slug, "paff"))
    .limit(1);

  if (!paffOrg) {
    throw new Error("Canonical PAFF organization (slug: 'paff') could not be resolved.");
  }

  const legacyEvents = await db
    .select({ id: events.id, name: events.name })
    .from(events)
    .where(isNull(events.organizationId));

  if (legacyEvents.length === 0) {
    logger.info("No legacy tournaments with null organizationId found. Backfill complete.");
    return { updatedCount: 0, organizationId: paffOrg.id, organizationName: paffOrg.name };
  }

  await db
    .update(events)
    .set({
      organizationId: paffOrg.id,
      updatedAt: new Date(),
    })
    .where(isNull(events.organizationId));

  logger.info(
    { updatedCount: legacyEvents.length, organizationId: paffOrg.id, organizationName: paffOrg.name },
    "Successfully backfilled legacy tournaments to PAFF organization"
  );

  return {
    updatedCount: legacyEvents.length,
    organizationId: paffOrg.id,
    organizationName: paffOrg.name,
  };
}

// Execute when run directly from CLI
const isDirectExecution =
  typeof process !== "undefined" &&
  Array.isArray(process.argv) &&
  process.argv[1] &&
  process.argv[1].includes("migrateLegacyTournamentsToOrgs");

if (isDirectExecution) {
  migrateLegacyTournamentsToOrgs()
    .then((res) => {
      console.log("Migration finished:", res);
      process.exit(0);
    })
    .catch((err) => {
      console.error("Migration failed:", err);
      process.exit(1);
    });
}
