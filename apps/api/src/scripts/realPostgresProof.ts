import request from "supertest";
import { app } from "../app.js";
import { db, pool } from "../config/db.js";
import { users, athleteProfiles, events, communityPosts } from "@armsphere/db-schema";
import { eq, inArray } from "drizzle-orm";
import { generateAccessToken } from "@armsphere/cryptography";
import { UserRole } from "@armsphere/types";
import crypto from "crypto";

async function main() {
  console.log("================================================================================");
  console.log("       ARMSPHERE PHASE 14 — REAL POSTGRESQL RUNTIME PROOF VERIFICATION");
  console.log("================================================================================");

  // 1. Verify Real Database Connection
  console.log("\n[STEP 1] Probing Real PostgreSQL Engine...");
  const rawInfo = await pool.query("SELECT version(), current_database(), current_user, now()");
  console.log("✓ Connected to PostgreSQL Engine successfully!");
  console.log("  Version  :", rawInfo.rows[0].version.split(",")[0]);
  console.log("  Database :", rawInfo.rows[0].current_database);
  console.log("  User     :", rawInfo.rows[0].current_user);
  console.log("  Timestamp:", rawInfo.rows[0].now);

  // 2. Probe /api/health and /api/ready
  console.log("\n[STEP 2] Probing API Health & Readiness against live database...");
  const healthRes = await request(app).get("/api/health");
  console.log("  GET /api/health status:", healthRes.status, JSON.stringify(healthRes.body));
  if (healthRes.body.status !== "healthy" || healthRes.body.details?.database !== "healthy") {
    throw new Error(`Health check failed: expected healthy database, got ${JSON.stringify(healthRes.body)}`);
  }
  console.log("  ✓ /api/health reports database HEALTHY");

  const readyRes = await request(app).get("/api/ready");
  console.log("  GET /api/ready status :", readyRes.status, JSON.stringify(readyRes.body));
  if (readyRes.body.status !== "ready") {
    throw new Error(`Readiness check failed: expected ready, got ${JSON.stringify(readyRes.body)}`);
  }
  console.log("  ✓ /api/ready reports service READY");

  // 3. Seed Real PostgreSQL Fixtures
  console.log("\n[STEP 3] Seeding Real Test Fixtures into Neon PostgreSQL...");
  const uidAthlete1 = crypto.randomUUID();
  const uidAthlete2 = crypto.randomUUID();
  const uidAdmin = crypto.randomUUID();
  const uidDirectorPunjab = crypto.randomUUID();
  const uidDirectorSindh = crypto.randomUUID();

  const profileId1 = crypto.randomUUID();
  const profileId2 = crypto.randomUUID();
  const eventIdPunjab = crypto.randomUUID();
  const postGymId = crypto.randomUUID();

  const testUserIds = [uidAthlete1, uidAthlete2, uidAdmin, uidDirectorPunjab, uidDirectorSindh];
  const jwtSecret = process.env.JWT_ACCESS_SECRET || "super_secret_armsphere_access_jwt_key_with_length_greater_than_32";

  try {
    // Insert Users
    await db.insert(users).values([
      {
        id: uidAthlete1,
        email: `athlete1_${Date.now()}@armsphere.test`,
        username: `ath1_${Date.now().toString().slice(-6)}`,
        passwordHash: "$2b$10$dummyHashForTestingRealPostgresAuth0000000000000000000000",
        role: UserRole.ATHLETE,
        fullName: "Punjab Athlete One",
        isActive: true,
        province: "Punjab",
        regionalCoverage: "Punjab",
      },
      {
        id: uidAthlete2,
        email: `athlete2_${Date.now()}@armsphere.test`,
        username: `ath2_${Date.now().toString().slice(-6)}`,
        passwordHash: "$2b$10$dummyHashForTestingRealPostgresAuth0000000000000000000000",
        role: UserRole.ATHLETE,
        fullName: "Sindh Athlete Two",
        isActive: true,
        province: "Sindh",
        regionalCoverage: "Sindh",
      },
      {
        id: uidAdmin,
        email: `admin_${Date.now()}@armsphere.test`,
        username: `adm_${Date.now().toString().slice(-6)}`,
        passwordHash: "$2b$10$dummyHashForTestingRealPostgresAuth0000000000000000000000",
        role: UserRole.SYSTEM_ADMIN,
        fullName: "Global System Admin",
        isActive: true,
      },
      {
        id: uidDirectorPunjab,
        email: `dir_punjab_${Date.now()}@armsphere.test`,
        username: `dirpun_${Date.now().toString().slice(-6)}`,
        passwordHash: "$2b$10$dummyHashForTestingRealPostgresAuth0000000000000000000000",
        role: UserRole.PROVINCIAL_DIRECTOR,
        fullName: "Punjab Provincial Director",
        isActive: true,
        province: "Punjab",
        regionalCoverage: "Punjab",
      },
      {
        id: uidDirectorSindh,
        email: `dir_sindh_${Date.now()}@armsphere.test`,
        username: `dirsin_${Date.now().toString().slice(-6)}`,
        passwordHash: "$2b$10$dummyHashForTestingRealPostgresAuth0000000000000000000000",
        role: UserRole.PROVINCIAL_DIRECTOR,
        fullName: "Sindh Provincial Director",
        isActive: true,
        province: "Sindh",
        regionalCoverage: "Sindh",
      },
    ] as any);
    console.log("  ✓ Seeded 5 canonical users in users table");

    // Insert Athlete Profiles
    await db.insert(athleteProfiles).values([
      {
        id: profileId1,
        userId: uidAthlete1,
        displayName: "Punjab Champ",
        province: "Punjab",
        city: "Lahore",
        handedness: "BOTH",
        dominantArm: "RIGHT",
        dateOfBirth: new Date("1995-05-15"),
        gender: "MALE",
        weightClass: "80KG",
        profileVisibility: "PUBLIC",
      },
      {
        id: profileId2,
        userId: uidAthlete2,
        displayName: "Sindh Warrior",
        province: "Sindh",
        city: "Karachi",
        handedness: "RIGHT",
        dominantArm: "RIGHT",
        dateOfBirth: new Date("1996-08-20"),
        gender: "MALE",
        weightClass: "75KG",
        profileVisibility: "PUBLIC",
      },
    ]);
    console.log("  ✓ Seeded 2 athlete profiles in athlete_profiles table");

    // Insert Gym/Training Post for Athlete 1
    await db.insert(communityPosts).values({
      id: postGymId,
      athleteId: profileId1,
      category: "GYM",
      externalUrl: "https://instagram.com/p/test12345",
      platform: "INSTAGRAM",
      exerciseType: "BICEP_CURL",
      weightKg: "45.00",
      reps: 8,
      moderationStatus: "APPROVED",
      isDeleted: false,
    });
    console.log("  ✓ Seeded training log post in community_posts table");

    // Insert Tournament Event in Punjab organized by Punjab Director
    await db.insert(events).values({
      id: eventIdPunjab,
      name: "Punjab ArmWrestling Championship 2026",
      province: "Punjab",
      city: "Lahore",
      venue: "Gaddafi Stadium Hall",
      status: "DRAFT",
      capacity: 200,
      organizerId: uidDirectorPunjab,
      startDate: new Date(Date.now() + 86400000 * 30),
      endDate: new Date(Date.now() + 86400000 * 32),
      registrationStart: new Date(),
      registrationEnd: new Date(Date.now() + 86400000 * 20),
    });
    console.log("  ✓ Seeded tournament event in events table");

    // Generate JWT Tokens
    const tokenAthlete1 = generateAccessToken(uidAthlete1, "ath1@test.com", UserRole.ATHLETE, jwtSecret);
    const tokenAthlete2 = generateAccessToken(uidAthlete2, "ath2@test.com", UserRole.ATHLETE, jwtSecret);
    const tokenAdmin = generateAccessToken(uidAdmin, "adm@test.com", UserRole.SYSTEM_ADMIN, jwtSecret);
    const tokenDirPunjab = generateAccessToken(uidDirectorPunjab, "dirpun@test.com", UserRole.PROVINCIAL_DIRECTOR, jwtSecret);
    const tokenDirSindh = generateAccessToken(uidDirectorSindh, "dirsin@test.com", UserRole.PROVINCIAL_DIRECTOR, jwtSecret);

    console.log("\n[STEP 4] Executing Live Security Probes on Endpoints...");

    // PROBE 1: Training Log IDOR Check (Intruder Athlete)
    console.log("\n  -> PROBE 1: Intruder Athlete 2 accessing Athlete 1's training log");
    const p1 = await request(app)
      .get(`/api/v1/athletes/${profileId1}/training-log`)
      .set("Authorization", `Bearer ${tokenAthlete2}`);
    console.log(`     HTTP status: ${p1.status} (expected: 403)`);
    if (p1.status !== 403) throw new Error(`PROBE 1 FAILED: Expected 403, got ${p1.status}`);
    console.log("     ✓ BLOCKED: Cross-athlete training-log access forbidden by canonical policy");

    // PROBE 2: Training Log PRs IDOR Check (Intruder Athlete)
    console.log("\n  -> PROBE 2: Intruder Athlete 2 accessing Athlete 1's PR analytics");
    const p2 = await request(app)
      .get(`/api/v1/athletes/${profileId1}/training-log/prs`)
      .set("Authorization", `Bearer ${tokenAthlete2}`);
    console.log(`     HTTP status: ${p2.status} (expected: 403)`);
    if (p2.status !== 403) throw new Error(`PROBE 2 FAILED: Expected 403, got ${p2.status}`);
    console.log("     ✓ BLOCKED: Cross-athlete PR analytics access forbidden by canonical policy");

    // PROBE 3: Owning Athlete Training Log Check
    console.log("\n  -> PROBE 3: Owner Athlete 1 accessing their own training log");
    const p3 = await request(app)
      .get(`/api/v1/athletes/${profileId1}/training-log`)
      .set("Authorization", `Bearer ${tokenAthlete1}`);
    console.log(`     HTTP status: ${p3.status} (expected: 200), logs count: ${Array.isArray(p3.body) ? p3.body.length : (p3.body.logs?.length ?? 0)}`);
    if (p3.status !== 200) throw new Error(`PROBE 3 FAILED: Expected 200, got ${p3.status}`);
    console.log("     ✓ ALLOWED: Profile owner successfully retrieved private training logs");

    // PROBE 4: Owning Athlete PRs Check
    console.log("\n  -> PROBE 4: Owner Athlete 1 accessing their own PR analytics");
    const p4 = await request(app)
      .get(`/api/v1/athletes/${profileId1}/training-log/prs`)
      .set("Authorization", `Bearer ${tokenAthlete1}`);
    console.log(`     HTTP status: ${p4.status} (expected: 200)`);
    if (p4.status !== 200) throw new Error(`PROBE 4 FAILED: Expected 200, got ${p4.status}`);
    console.log("     ✓ ALLOWED: Profile owner successfully retrieved private PR analytics");

    // PROBE 5: System Admin Training Log Access
    console.log("\n  -> PROBE 5: System Admin accessing Athlete 1's training log");
    const p5 = await request(app)
      .get(`/api/v1/athletes/${profileId1}/training-log`)
      .set("Authorization", `Bearer ${tokenAdmin}`);
    console.log(`     HTTP status: ${p5.status} (expected: 200)`);
    if (p5.status !== 200) throw new Error(`PROBE 5 FAILED: Expected 200, got ${p5.status}`);
    console.log("     ✓ ALLOWED: System Admin universally authorized across all athletes");

    // PROBE 6: Same-Province Director Training Log Access
    console.log("\n  -> PROBE 6: Punjab Director accessing Punjab Athlete 1's training log");
    const p6 = await request(app)
      .get(`/api/v1/athletes/${profileId1}/training-log`)
      .set("Authorization", `Bearer ${tokenDirPunjab}`);
    console.log(`     HTTP status: ${p6.status} (expected: 200)`);
    if (p6.status !== 200) throw new Error(`PROBE 6 FAILED: Expected 200, got ${p6.status}`);
    console.log("     ✓ ALLOWED: Provincial Director authorized within matching province jurisdiction");

    // PROBE 7: Cross-Province Director Training Log Access
    console.log("\n  -> PROBE 7: Sindh Director attempting to access Punjab Athlete 1's training log");
    const p7 = await request(app)
      .get(`/api/v1/athletes/${profileId1}/training-log`)
      .set("Authorization", `Bearer ${tokenDirSindh}`);
    console.log(`     HTTP status: ${p7.status} (expected: 403)`);
    if (p7.status !== 403) throw new Error(`PROBE 7 FAILED: Expected 403, got ${p7.status}`);
    console.log("     ✓ BLOCKED: Cross-province director access forbidden (Sindh != Punjab)");

    // PROBE 8: Cross-Province Tournament Event Modification
    console.log("\n  -> PROBE 8: Sindh Director attempting to cancel Punjab Tournament Event");
    const p8 = await request(app)
      .post(`/tournaments/events/${eventIdPunjab}/cancel`)
      .set("Authorization", `Bearer ${tokenDirSindh}`);
    console.log(`     HTTP status: ${p8.status} (expected: 403)`);
    if (p8.status !== 403) throw new Error(`PROBE 8 FAILED: Expected 403, got ${p8.status}`);
    console.log("     ✓ BLOCKED: Cross-province event lifecycle mutation forbidden");

    // PROBE 9: Event Organizer / Same-Province Event Modification
    console.log("\n  -> PROBE 9: Punjab Director (Event Organizer) publishing Punjab Tournament Event");
    const p9 = await request(app)
      .post(`/tournaments/events/${eventIdPunjab}/publish`)
      .set("Authorization", `Bearer ${tokenDirPunjab}`);
    console.log(`     HTTP status: ${p9.status} (expected: 200), event status: ${p9.body.status}`);
    if (p9.status !== 200) throw new Error(`PROBE 9 FAILED: Expected 200, got ${p9.status}`);
    console.log("     ✓ ALLOWED: Authorized event organizer published tournament event");

    // PROBE 10: Private Athlete Field Sanitization
    console.log("\n  -> PROBE 10: Third-party Athlete retrieving Athlete 1's public profile");
    const p10 = await request(app)
      .get(`/api/v1/athletes/${profileId1}`)
      .set("Authorization", `Bearer ${tokenAthlete2}`);
    console.log(`     HTTP status: ${p10.status} (expected: 200)`);
    if (p10.status !== 200) throw new Error(`PROBE 10 FAILED: Expected 200, got ${p10.status}`);
    const bodyStr = JSON.stringify(p10.body);
    if (bodyStr.includes("phone") && p10.body.phone !== undefined && p10.body.phone !== null) {
      throw new Error(`PROBE 10 FAILED: Private phone exposed in third-party profile view`);
    }
    console.log("     ✓ SANITIZED: Private athlete fields excluded from third-party responses");

    console.log("\n================================================================================");
    console.log("   ALL 10 REAL POSTGRESQL RUNTIME PROBES PASSED WITH 100% SUCCESS!");
    console.log("================================================================================");
  } finally {
    // Clean up seeded fixtures
    console.log("\n[CLEANUP] Cleaning up seeded test records from Neon PostgreSQL...");
    try {
      await db.delete(events).where(eq(events.id, eventIdPunjab));
      await db.delete(communityPosts).where(eq(communityPosts.id, postGymId));
      await db.delete(athleteProfiles).where(inArray(athleteProfiles.id, [profileId1, profileId2]));
      await db.delete(users).where(inArray(users.id, testUserIds));
      console.log("✓ Neon PostgreSQL test fixtures successfully cleaned up.");
    } catch (cleanErr) {
      console.error("Cleanup warning:", cleanErr);
    }
    await pool.end();
  }
}

main().catch((err) => {
  console.error("\n❌ FATAL TEST ERROR:", err);
  pool.end().finally(() => process.exit(1));
});
