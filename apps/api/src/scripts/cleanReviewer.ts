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
import { eq, inArray, like } from "drizzle-orm";

export async function cleanReviewer() {
  console.log("================================================================================");
  console.log("       ARMSPHERE STORE REVIEWER FIXTURE DECOMMISSIONING & CLEANUP");
  console.log("================================================================================");

  try {
    const reviewerEmail = "reviewer@armsphere.com";
    const refereeEmail = "referee.test@armsphere.com";
    const opponentEmail = "sparring.partner@armsphere.com";
    const eventName = "ArmSphere National Premier Cup 2026";

    // 1. Locate accounts if present
    const testUsers = await db
      .select()
      .from(users)
      .where(inArray(users.email, [reviewerEmail, refereeEmail, opponentEmail]));

    const testUserIds = testUsers.map((u) => u.id);
    console.log(`[STEP 1] Found ${testUsers.length} test accounts to clean: ${testUsers.map((u) => u.email).join(", ") || "none"}`);

    // 2. Locate profiles
    let testProfileIds: string[] = [];
    if (testUserIds.length > 0) {
      const profiles = await db
        .select()
        .from(athleteProfiles)
        .where(inArray(athleteProfiles.userId, testUserIds));
      testProfileIds = profiles.map((p) => p.id);
      console.log(`[STEP 2] Found ${profiles.length} test athlete profiles to clean.`);
    }

    // 3. Clean ELO Ledger and Matches
    console.log("[STEP 3] Cleaning test match history & ELO ledger records...");
    const testMatches = await db
      .select()
      .from(matches)
      .where(like(matches.idempotencyKey, "seed-reviewer-match-%"));

    if (testMatches.length > 0) {
      const matchIds = testMatches.map((m) => m.id);
      for (const mId of matchIds) {
        await db.delete(eloLedger).where(eq(eloLedger.matchId, mId));
      }
      console.log(`  ✓ Removed ${matchIds.length} test match ELO ledger entries.`);

      await db.delete(matches).where(inArray(matches.id, matchIds));
      console.log(`  ✓ Removed ${matchIds.length} test match records.`);
    } else {
      console.log("  ✓ No test matches found.");
    }

    // 4. Clean Tournament Event, Bracket, Registrations
    console.log(`[STEP 4] Cleaning demo tournament '${eventName}'...`);
    const demoEvents = await db.select().from(events).where(eq(events.name, eventName));
    if (demoEvents.length > 0) {
      const eventIds = demoEvents.map((e) => e.id);
      for (const eId of eventIds) {
        await db.delete(eventRegistrations).where(eq(eventRegistrations.eventId, eId));
        await db.delete(brackets).where(eq(brackets.eventId, eId));
      }
      await db.delete(events).where(inArray(events.id, eventIds));
      console.log(`  ✓ Removed demo event, brackets, and registrations.`);
    } else {
      console.log("  ✓ No demo tournament found.");
    }

    // 5. Clean Athlete Verifications & Profiles
    if (testProfileIds.length > 0 || testUserIds.length > 0) {
      console.log("[STEP 5] Cleaning athlete profiles & verifications...");
      for (const uId of testUserIds) {
        await db.delete(athleteVerifications).where(eq(athleteVerifications.athleteId, uId));
        await db.delete(athleteProfiles).where(eq(athleteProfiles.userId, uId));
      }
      console.log(`  ✓ Removed test athlete profiles and verifications.`);
    }

    // 6. Delete Test Users
    if (testUserIds.length > 0) {
      console.log("[STEP 6] Removing test user accounts...");
      await db.delete(users).where(inArray(users.id, testUserIds));
      console.log(`  ✓ Successfully deleted ${testUserIds.length} test users.`);
    }

    console.log("\n================================================================================");
    console.log("        STORE REVIEWER DECOMMISSIONING COMPLETE — DATABASE CLEAN");
    console.log("================================================================================\n");

  } catch (error) {
    console.error("Error executing cleanReviewer:", error);
    throw error;
  }
}

// Allow direct execution
if (process.argv[1]?.endsWith("cleanReviewer.ts") || process.argv[1]?.endsWith("cleanReviewer.js")) {
  cleanReviewer()
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
