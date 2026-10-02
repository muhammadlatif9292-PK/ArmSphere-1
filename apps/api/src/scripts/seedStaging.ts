import dotenv from "dotenv";
dotenv.config();
if (process.env.NODE_ENV === "staging" || process.env.APP_ENV === "staging") {
  dotenv.config({ path: ".env.staging" });
  dotenv.config({ path: "../../.env.staging" });
}

import { db, pool } from "../config/db.js";
import {
  users,
  athleteProfiles,
  events,
  brackets,
  bracketSeeds,
  eventRegistrations,
  matchTables,
  refereeCertifications,
  userRoleGrants,
} from "@armsphere/db-schema";
import { hashPassword } from "@armsphere/cryptography";
import { UserRole } from "@armsphere/types";
import { assertIsolatedStagingDatabase } from "../config/databaseGuard.js";
import crypto from "crypto";
import { eq } from "drizzle-orm";

export async function seedStaging() {
  console.log("================================================================================");
  console.log("          ARMSPHERE ISOLATED STAGING FIXTURE INITIALIZATION");
  console.log("================================================================================");

  // 1. HARD SAFETY INVARIANT CHECK
  assertIsolatedStagingDatabase("seedStaging fixture provisioning");

  const defaultPassword = process.env.STAGING_DEFAULT_PASSWORD || "StagingSecretPass2026!";
  const passwordHash = await hashPassword(defaultPassword);

  try {
    console.log("\n[STEP 1] Provisioning Staging Staff & Role Accounts...");
    const adminId = "00000000-0000-4000-8000-000000000001";
    const directorId = "00000000-0000-4000-8000-000000000002";
    const refereeId = "00000000-0000-4000-8000-000000000003";
    const athlete1UserId = "00000000-0000-4000-8000-000000000004";
    const athlete2UserId = "00000000-0000-4000-8000-000000000005";

    const stagingUsers = [
      {
        id: adminId,
        email: "admin@armsphere.staging",
        username: "staging_admin",
        passwordHash,
        role: UserRole.SYSTEM_ADMIN,
        fullName: "Staging System Administrator",
        isActive: true,
      },
      {
        id: directorId,
        email: "punjab.director@armsphere.staging",
        username: "staging_director_punjab",
        passwordHash,
        role: UserRole.PROVINCIAL_DIRECTOR,
        regionalCoverage: "Punjab",
        fullName: "Punjab Staging Director",
        isActive: true,
      },
      {
        id: refereeId,
        email: "referee.official@armsphere.staging",
        username: "staging_referee",
        passwordHash,
        role: UserRole.REFEREE,
        fullName: "Staging Senior Referee",
        isActive: true,
      },
      {
        id: athlete1UserId,
        email: "athlete.alpha@armsphere.staging",
        username: "athlete_alpha_staging",
        passwordHash,
        role: UserRole.ATHLETE,
        regionalCoverage: "Punjab",
        fullName: "Alpha Staging Contender",
        isActive: true,
      },
      {
        id: athlete2UserId,
        email: "athlete.beta@armsphere.staging",
        username: "athlete_beta_staging",
        passwordHash,
        role: UserRole.ATHLETE,
        regionalCoverage: "Punjab",
        fullName: "Beta Staging Contender",
        isActive: true,
      },
    ];

    for (const u of stagingUsers) {
      await db
        .insert(users)
        .values(u)
        .onConflictDoUpdate({
          target: users.id,
          set: {
            role: u.role,
            regionalCoverage: u.regionalCoverage,
            passwordHash: u.passwordHash,
            fullName: u.fullName,
            isActive: u.isActive,
          },
        });
      console.log(`  ✓ Provisioned staging account: ${u.email} (${u.role})`);

      // Ensure explicit canonical active grant in userRoleGrants table
      await db.delete(userRoleGrants).where(eq(userRoleGrants.userId, u.id));
      await db.insert(userRoleGrants).values({
        id: crypto.randomUUID(),
        userId: u.id,
        role: u.role,
        status: "ACTIVE",
        scope: u.regionalCoverage || null,
        grantedAt: new Date(),
      });
    }

    // Provision active national referee certification for the referee
    await db.insert(refereeCertifications).values({
      id: "00000000-0000-4000-f000-000000000001",
      userId: refereeId,
      certificationLevel: "NATIONAL",
      status: "ACTIVE",
      issuedAt: new Date(Date.now() - 86400000 * 30),
      expiresAt: new Date(Date.now() + 86400000 * 365),
      issuingBody: "Pakistan Armwrestling Federation",
    }).onConflictDoNothing();
    console.log("  ✓ Provisioned active National Referee Certification for referee.");

    console.log("\n[STEP 2] Provisioning Athlete Profiles & Staging Baseline Stats...");
    const profile1Id = "00000000-0000-4000-9000-000000000001";
    const profile2Id = "00000000-0000-4000-9000-000000000002";

    const stagingProfiles = [
      {
        id: profile1Id,
        userId: athlete1UserId,
        displayName: "Alpha Staging Contender",
        province: "Punjab",
        city: "Lahore",
        handedness: "RIGHT",
        dominantArm: "RIGHT",
        dateOfBirth: new Date("1998-05-15"),
        gender: "MALE",
        weightClass: "75kg",
        height: 180,
        weight: 75.0,
        reach: 182,
        leftArmElo: 1100,
        rightArmElo: 1200,
        isSearchable: true,
      },
      {
        id: profile2Id,
        userId: athlete2UserId,
        displayName: "Beta Staging Contender",
        province: "Punjab",
        city: "Rawalpindi",
        handedness: "RIGHT",
        dominantArm: "RIGHT",
        dateOfBirth: new Date("1999-08-20"),
        gender: "MALE",
        weightClass: "75kg",
        height: 178,
        weight: 74.5,
        reach: 179,
        leftArmElo: 1080,
        rightArmElo: 1180,
        isSearchable: true,
      },
    ];

    for (const p of stagingProfiles) {
      await db.insert(athleteProfiles).values(p).onConflictDoNothing();
      console.log(`  ✓ Provisioned athlete profile: ${p.displayName} (ELO: ${p.rightArmElo})`);
    }

    console.log("\n[STEP 3] Provisioning Staging Tournament Event & Arena Tables...");
    const eventId = "00000000-0000-4000-a000-000000000001";
    const bracketId = "00000000-0000-4000-b000-000000000001";
    const tableId = "00000000-0000-4000-c000-000000000001";

    const now = new Date();
    const startDate = new Date(now.getTime() + 86400000);
    const endDate = new Date(now.getTime() + 86400000 * 3);
    const regStart = new Date(now.getTime() - 86400000 * 7);
    const regEnd = new Date(now.getTime() + 86400000);

    await db.insert(events).values({
      id: eventId,
      name: "ArmSphere Staging Invitational 2026",
      startDate,
      endDate,
      registrationStart: regStart,
      registrationEnd: regEnd,
      province: "Punjab",
      city: "Lahore",
      venue: "Staging Sports Complex, Lahore",
      capacity: 100,
      registrationFeeCents: 1500,
      status: "PUBLISHED",
      organizerId: directorId,
    }).onConflictDoNothing();

    await db.insert(brackets).values({
      id: bracketId,
      eventId,
      name: "Senior Men Right 75kg (Staging)",
      format: "DOUBLE_ELIMINATION",
      division: "SENIOR",
      weightClass: "75kg",
      arm: "RIGHT",
      status: "ACTIVE",
    }).onConflictDoNothing();

    await db.insert(matchTables).values({
      id: tableId,
      eventId,
      name: "Table 1 (Arena Stage)",
      status: "AVAILABLE",
    }).onConflictDoNothing();

    console.log("  ✓ Provisioned Staging Event, Double-Elimination Bracket, and Arena Table.");

    console.log("\n[STEP 4] Provisioning Staging Event Registrations & Bracket Seeds...");
    await db.insert(eventRegistrations).values([
      {
        id: "00000000-0000-4000-d000-000000000001",
        eventId,
        athleteId: profile1Id,
        division: "SENIOR",
        weightClass: "75kg",
        arm: "RIGHT",
        status: "APPROVED",
        paymentConfirmedByOrganizer: true,
      },
      {
        id: "00000000-0000-4000-d000-000000000002",
        eventId,
        athleteId: profile2Id,
        division: "SENIOR",
        weightClass: "75kg",
        arm: "RIGHT",
        status: "APPROVED",
        paymentConfirmedByOrganizer: true,
      },
    ]).onConflictDoNothing();

    await db.insert(bracketSeeds).values([
      {
        id: "00000000-0000-4000-e000-000000000001",
        bracketId,
        athleteId: profile1Id,
        seedPosition: 1,
      },
      {
        id: "00000000-0000-4000-e000-000000000002",
        bracketId,
        athleteId: profile2Id,
        seedPosition: 2,
      },
    ]).onConflictDoNothing();

    console.log("  ✓ Provisioned Approved Registrations and Bracket Seeds 1 & 2.");

    console.log("\n================================================================================");
    console.log("       STAGING FIXTURE INITIALIZATION COMPLETED SUCCESSFULLY");
    console.log("================================================================================");
    console.log("  - Zero production records touched or modified.");
    console.log("  - All staging fixtures isolated with '@armsphere.staging' domain.");
    console.log("  - Staging event and bracket ready for live queue/operations tests.");
    console.log("================================================================================\n");
  } catch (error) {
    console.error("Error executing seedStaging:", error);
    throw error;
  }
}

if (process.argv[1]?.endsWith("seedStaging.ts") || process.argv[1]?.endsWith("seedStaging.js")) {
  seedStaging()
    .then(async () => {
      await pool.end();
      process.exit(0);
    })
    .catch(async (err) => {
      console.error(err);
      await pool.end();
      process.exit(1);
    });
}
