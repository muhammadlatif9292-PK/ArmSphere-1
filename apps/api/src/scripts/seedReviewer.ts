import dotenv from "dotenv";
dotenv.config();
if (!process.env.DATABASE_URL) {
  dotenv.config({ path: ".env.neon" });
  dotenv.config({ path: "../../.env.neon" });
}

import { db, pool } from "../config/db.js";
import {
  users,
  athleteProfiles,
  athleteVerifications,
  events,
  brackets,
  eventRegistrations,
  matches,
  eloLedger,
} from "@armsphere/db-schema";
import { eq } from "drizzle-orm";
import { hashPassword } from "@armsphere/cryptography";
import { UserRole } from "@armsphere/types";
import crypto from "crypto";

function resolveSeedPassword(envVarName: string, defaultDevPassword: string, roleLabel: string): string {
  const isProduction = process.env.NODE_ENV === "production";
  if (process.env[envVarName]) {
    return process.env[envVarName]!;
  }
  if (isProduction) {
    const generated = crypto.randomBytes(18).toString("base64url") + "!A1";
    console.log(`  [SECURITY NOTICE] NODE_ENV=production: generated secure random password for ${roleLabel} (${envVarName} not set): ${generated}`);
    return generated;
  }
  return defaultDevPassword;
}

export async function seedReviewer() {
  console.log("================================================================================");
  console.log("      ARMSPHERE STORE REVIEWER & AUDIT TEST FIXTURE PROVISIONING");
  console.log("================================================================================");
  console.log("  SECURITY POSTURE:");
  console.log("  - Review fixtures are assigned low-privilege roles (ATHLETE, REFEREE) only.");
  console.log("  - No system-admin, compliance, or financial-payout privileges are granted.");
  console.log("  - In production, set REVIEWER_PASSWORD / REFEREE_PASSWORD or secure randoms apply.");

  try {
    if (process.env.NODE_ENV === "production" && process.env.ALLOW_STORE_REVIEW_SEED_IN_PRODUCTION !== "true") {
      const errorMsg =
        "SAFETY ABORT: seedReviewer is a store-review test fixture script and cannot run in production without ALLOW_STORE_REVIEW_SEED_IN_PRODUCTION=true.";
      console.error(`\n❌ ${errorMsg}\n`);
      throw new Error(errorMsg);
    }

    // 1. Reviewer Athlete Account
    const reviewerEmail = "reviewer@armsphere.com";
    const reviewerPassword = resolveSeedPassword("REVIEWER_PASSWORD", "ReviewerPass123!", "Reviewer Athlete");
    const reviewerUsername = "reviewer";
    const reviewerFullName = "App Store Reviewer";

    console.log(`\n[STEP 1] Provisioning Store Reviewer Athlete Account (${reviewerEmail})...`);
    const existingReviewer = await db.select().from(users).where(eq(users.email, reviewerEmail)).limit(1);

    let reviewerUserId: string;
    const reviewerPasswordHash = await hashPassword(reviewerPassword);

    if (existingReviewer.length > 0) {
      reviewerUserId = existingReviewer[0].id;
      await db
        .update(users)
        .set({
          passwordHash: reviewerPasswordHash,
          isActive: true,
          role: UserRole.ATHLETE,
          fullName: reviewerFullName,
          updatedAt: new Date(),
        })
        .where(eq(users.id, reviewerUserId));
      console.log(`  ✓ Updated existing reviewer user credentials (ID: ${reviewerUserId})`);
    } else {
      reviewerUserId = crypto.randomUUID();
      await db.insert(users).values({
        id: reviewerUserId,
        email: reviewerEmail,
        username: reviewerUsername,
        passwordHash: reviewerPasswordHash,
        role: UserRole.ATHLETE,
        fullName: reviewerFullName,
        isActive: true,
        createdAt: new Date(),
        updatedAt: new Date(),
      });
      console.log(`  ✓ Created new reviewer user (ID: ${reviewerUserId})`);
    }

    // Upsert Athlete Profile for Reviewer
    const existingProfile = await db
      .select()
      .from(athleteProfiles)
      .where(eq(athleteProfiles.userId, reviewerUserId))
      .limit(1);

    let reviewerProfileId: string;
    if (existingProfile.length > 0) {
      reviewerProfileId = existingProfile[0].id;
      await db
        .update(athleteProfiles)
        .set({
          displayName: reviewerFullName,
          province: "Punjab",
          city: "Lahore",
          handedness: "BOTH",
          dominantArm: "RIGHT",
          dateOfBirth: new Date("1995-05-15"),
          gender: "MALE",
          weightClass: "86kg",
          leftArmElo: 1850,
          rightArmElo: 1850,
          leftArmConfidence: 0.95,
          rightArmConfidence: 0.95,
          profileVisibility: "PUBLIC",
          isSearchable: true,
          updatedAt: new Date(),
        })
        .where(eq(athleteProfiles.id, reviewerProfileId));
      console.log(`  ✓ Updated athlete profile for reviewer (Profile ID: ${reviewerProfileId})`);
    } else {
      reviewerProfileId = crypto.randomUUID();
      await db.insert(athleteProfiles).values({
        id: reviewerProfileId,
        userId: reviewerUserId,
        displayName: reviewerFullName,
        province: "Punjab",
        city: "Lahore",
        handedness: "BOTH",
        dominantArm: "RIGHT",
        dateOfBirth: new Date("1995-05-15"),
        gender: "MALE",
        weightClass: "86kg",
        leftArmElo: 1850,
        rightArmElo: 1850,
        leftArmConfidence: 0.95,
        rightArmConfidence: 0.95,
        profileVisibility: "PUBLIC",
        isSearchable: true,
        createdAt: new Date(),
        updatedAt: new Date(),
      });
      console.log(`  ✓ Created athlete profile for reviewer (Profile ID: ${reviewerProfileId})`);
    }

    // Ensure Reviewer is Verified
    const existingVerification = await db
      .select()
      .from(athleteVerifications)
      .where(eq(athleteVerifications.athleteId, reviewerUserId))
      .limit(1);

    if (existingVerification.length > 0) {
      await db
        .update(athleteVerifications)
        .set({
          status: "VERIFIED",
          updatedAt: new Date(),
        })
        .where(eq(athleteVerifications.athleteId, reviewerUserId));
      console.log(`  ✓ Updated athlete verification status to VERIFIED`);
    } else {
      await db.insert(athleteVerifications).values({
        id: crypto.randomUUID(),
        athleteId: reviewerUserId,
        status: "VERIFIED",
        createdAt: new Date(),
        updatedAt: new Date(),
      });
      console.log(`  ✓ Created athlete verification status as VERIFIED`);
    }

    // 2. Official Referee Test Account
    const refereeEmail = "referee.test@armsphere.com";
    const refereePassword = resolveSeedPassword("REFEREE_PASSWORD", "RefereePass123!", "Official Referee");
    const refereeUsername = "referee_test";
    const refereeFullName = "Official Test Referee";

    console.log(`\n[STEP 2] Provisioning Official Test Referee Account (${refereeEmail})...`);
    const existingReferee = await db.select().from(users).where(eq(users.email, refereeEmail)).limit(1);

    let refereeUserId: string;
    const refereePasswordHash = await hashPassword(refereePassword);

    if (existingReferee.length > 0) {
      refereeUserId = existingReferee[0].id;
      await db
        .update(users)
        .set({
          passwordHash: refereePasswordHash,
          isActive: true,
          role: UserRole.REFEREE,
          fullName: refereeFullName,
          regionalCoverage: "Punjab",
          updatedAt: new Date(),
        })
        .where(eq(users.id, refereeUserId));
      console.log(`  ✓ Updated existing referee user credentials (ID: ${refereeUserId})`);
    } else {
      refereeUserId = crypto.randomUUID();
      await db.insert(users).values({
        id: refereeUserId,
        email: refereeEmail,
        username: refereeUsername,
        passwordHash: refereePasswordHash,
        role: UserRole.REFEREE,
        fullName: refereeFullName,
        regionalCoverage: "Punjab",
        isActive: true,
        createdAt: new Date(),
        updatedAt: new Date(),
      });
      console.log(`  ✓ Created new referee user (ID: ${refereeUserId})`);
    }

    // 3. Sparring Partner Account (Opponent for match history)
    const opponentEmail = "sparring.partner@armsphere.com";
    const opponentPassword = resolveSeedPassword("OPPONENT_PASSWORD", "SparringPass123!", "Sparring Partner");
    const opponentUsername = "sparring_partner";
    const opponentFullName = "Tariq Sparring Partner";

    console.log(`\n[STEP 3] Provisioning Sparring Partner for realistic match records...`);
    const existingOpponent = await db.select().from(users).where(eq(users.email, opponentEmail)).limit(1);

    let opponentUserId: string;
    const opponentPasswordHash = await hashPassword(opponentPassword);

    if (existingOpponent.length > 0) {
      opponentUserId = existingOpponent[0].id;
      await db
        .update(users)
        .set({
          passwordHash: opponentPasswordHash,
          isActive: true,
          role: UserRole.ATHLETE,
          fullName: opponentFullName,
          updatedAt: new Date(),
        })
        .where(eq(users.id, opponentUserId));
    } else {
      opponentUserId = crypto.randomUUID();
      await db.insert(users).values({
        id: opponentUserId,
        email: opponentEmail,
        username: opponentUsername,
        passwordHash: opponentPasswordHash,
        role: UserRole.ATHLETE,
        fullName: opponentFullName,
        isActive: true,
        createdAt: new Date(),
        updatedAt: new Date(),
      });
    }

    const existingOpponentProfile = await db
      .select()
      .from(athleteProfiles)
      .where(eq(athleteProfiles.userId, opponentUserId))
      .limit(1);

    let opponentProfileId: string;
    if (existingOpponentProfile.length > 0) {
      opponentProfileId = existingOpponentProfile[0].id;
    } else {
      opponentProfileId = crypto.randomUUID();
      await db.insert(athleteProfiles).values({
        id: opponentProfileId,
        userId: opponentUserId,
        displayName: opponentFullName,
        province: "Punjab",
        city: "Lahore",
        handedness: "RIGHT",
        dominantArm: "RIGHT",
        dateOfBirth: new Date("1993-02-10"),
        gender: "MALE",
        weightClass: "86kg",
        leftArmElo: 1720,
        rightArmElo: 1740,
        leftArmConfidence: 0.9,
        rightArmConfidence: 0.9,
        profileVisibility: "PUBLIC",
        isSearchable: true,
        createdAt: new Date(),
        updatedAt: new Date(),
      });
    }
    console.log(`  ✓ Opponent profile active (Profile ID: ${opponentProfileId})`);

    // 4. Seed Verified Matches and ELO History for Reviewer
    console.log(`\n[STEP 4] Seeding 3 verified match history records for Reviewer...`);
    const matchSpecs = [
      { arm: "RIGHT", scoreLine: "3-1", reviewerEloPre: 1800, reviewerEloPost: 1820, delta: 20 },
      { arm: "LEFT", scoreLine: "3-0", reviewerEloPre: 1810, reviewerEloPost: 1835, delta: 25 },
      { arm: "RIGHT", scoreLine: "3-2", reviewerEloPre: 1820, reviewerEloPost: 1850, delta: 30 },
    ];

    for (let i = 0; i < matchSpecs.length; i++) {
      const spec = matchSpecs[i];
      const matchKey = `seed-reviewer-match-${i + 1}`;
      const existingMatch = await db.select().from(matches).where(eq(matches.idempotencyKey, matchKey)).limit(1);

      let matchId: string;
      if (existingMatch.length > 0) {
        matchId = existingMatch[0].id;
        console.log(`  ✓ Match ${i + 1} already present (${matchKey})`);
      } else {
        matchId = crypto.randomUUID();
        await db.insert(matches).values({
          id: matchId,
          challengerId: reviewerProfileId,
          opponentId: opponentProfileId,
          arm: spec.arm,
          refereeId: refereeUserId,
          winnerId: reviewerProfileId,
          scoreLine: spec.scoreLine,
          status: "VERIFIED",
          idempotencyKey: matchKey,
          evidenceUrl: "https://armsphere.com/evidence/reviewer-demo.mp4",
          verifiedAt: new Date(),
          createdAt: new Date(Date.now() - (3 - i) * 86400000),
          updatedAt: new Date(),
        });

        // Add ledger record
        await db.insert(eloLedger).values([
          {
            id: crypto.randomUUID(),
            matchId: matchId,
            athleteId: reviewerProfileId,
            arm: spec.arm,
            previousElo: spec.reviewerEloPre,
            newElo: spec.reviewerEloPost,
            eloDelta: spec.delta,
            createdAt: new Date(),
          },
          {
            id: crypto.randomUUID(),
            matchId: matchId,
            athleteId: opponentProfileId,
            arm: spec.arm,
            previousElo: 1750,
            newElo: 1750 - spec.delta,
            eloDelta: -spec.delta,
            createdAt: new Date(),
          },
        ]);
        console.log(`  ✓ Created verified Match ${i + 1} (${spec.arm} arm, score ${spec.scoreLine})`);
      }
    }

    // 5. Seed Championship/Event and Active Tournament Registration
    console.log(`\n[STEP 5] Seeding active championship tournament registration...`);
    const eventName = "ArmSphere National Premier Cup 2026";
    const existingEvent = await db.select().from(events).where(eq(events.name, eventName)).limit(1);

    let eventId: string;
    if (existingEvent.length > 0) {
      eventId = existingEvent[0].id;
      console.log(`  ✓ Event already present (ID: ${eventId})`);
    } else {
      eventId = crypto.randomUUID();
      const now = new Date();
      const nextMonth = new Date(now.getTime() + 30 * 86400000);
      const nextMonthEnd = new Date(now.getTime() + 32 * 86400000);

      await db.insert(events).values({
        id: eventId,
        name: eventName,
        startDate: nextMonth,
        endDate: nextMonthEnd,
        registrationStart: now,
        registrationEnd: nextMonth,
        province: "Punjab",
        city: "Lahore",
        venue: "National Armwrestling Arena, Nishtar Park",
        capacity: 128,
        registrationFeeCents: 0,
        status: "PUBLISHED",
        paymentMethod: "FREE",
        organizerId: refereeUserId,
        createdAt: now,
        updatedAt: now,
      });
      console.log(`  ✓ Created event '${eventName}' (ID: ${eventId})`);
    }

    // Create Bracket for Event if missing
    const existingBracket = await db.select().from(brackets).where(eq(brackets.eventId, eventId)).limit(1);
    let bracketId: string;
    if (existingBracket.length > 0) {
      bracketId = existingBracket[0].id;
    } else {
      bracketId = crypto.randomUUID();
      await db.insert(brackets).values({
        id: bracketId,
        eventId: eventId,
        name: "Senior Men 86kg Right Arm Open",
        format: "DOUBLE_ELIMINATION",
        division: "Senior",
        weightClass: "86kg",
        arm: "RIGHT",
        status: "READY",
        seedingLocked: false,
        createdAt: new Date(),
        updatedAt: new Date(),
      });
      console.log(`  ✓ Created tournament bracket for event`);
    }

    // Register Reviewer for Event
    const existingReg = await db
      .select()
      .from(eventRegistrations)
      .where(eq(eventRegistrations.eventId, eventId))
      .limit(1);

    const reviewerReg = existingReg.find((r) => r.athleteId === reviewerProfileId);
    if (reviewerReg) {
      await db
        .update(eventRegistrations)
        .set({
          status: "APPROVED",
          paymentConfirmedByOrganizer: true,
          paymentConfirmedAt: new Date(),
          updatedAt: new Date(),
        })
        .where(eq(eventRegistrations.id, reviewerReg.id));
      console.log(`  ✓ Updated active tournament registration for reviewer to APPROVED`);
    } else {
      await db.insert(eventRegistrations).values({
        id: crypto.randomUUID(),
        eventId: eventId,
        athleteId: reviewerProfileId,
        division: "Senior",
        weightClass: "86kg",
        arm: "RIGHT",
        status: "APPROVED",
        paymentConfirmedByOrganizer: true,
        paymentConfirmedAt: new Date(),
        notes: "Official App Store Reviewer Pass",
        createdAt: new Date(),
        updatedAt: new Date(),
      });
      console.log(`  ✓ Created active approved tournament registration for reviewer`);
    }

    console.log("\n================================================================================");
    console.log("            STORE REVIEWER FIXTURE PROVISIONING COMPLETE");
    console.log("================================================================================");
    console.log("  ATHLETE REVIEWER CREDENTIALS:");
    console.log(`    Email    : ${reviewerEmail}`);
    console.log(`    Password : ${reviewerPassword}`);
    console.log(`    Role     : ATHLETE (Verified, 1850 ELO, 3 Completed Matches, 1 Active Event)`);
    console.log("\n  REFEREE TEST CREDENTIALS:");
    console.log(`    Email    : ${refereeEmail}`);
    console.log(`    Password : ${refereePassword}`);
    console.log(`    Role     : REFEREE (Punjab Regional Coverage)`);
    console.log("================================================================================\n");

  } catch (error) {
    console.error("Error running seedReviewer:", error);
    throw error;
  }
}

// Allow direct execution
if (process.argv[1]?.endsWith("seedReviewer.ts") || process.argv[1]?.endsWith("seedReviewer.js")) {
  seedReviewer()
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
