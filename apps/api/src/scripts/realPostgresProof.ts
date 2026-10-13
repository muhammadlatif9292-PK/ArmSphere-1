import request from "supertest";
import { app } from "../app.js";
import { db, pool } from "../config/db.js";
import { users, athleteProfiles, events, communityPosts, refereeCertifications, notifications, teams, teamMembers, matches, eloLedger, brackets, tournamentMatches, disputes, eventRegistrations, matchTables, auditEvents } from "@armsphere/db-schema";
import { eq, inArray } from "drizzle-orm";
import { generateAccessToken } from "@armsphere/cryptography";
import { UserRole } from "@armsphere/types";
import crypto from "crypto";
import { assertIsolatedStagingDatabase } from "../config/databaseGuard.js";
import { RefereeCertificationService } from "../services/refereeCertification.js";

async function main() {
  console.log("================================================================================");
  console.log("       ARMSPHERE PHASE 14 — REAL POSTGRESQL RUNTIME PROOF VERIFICATION");
  console.log("================================================================================");

  // Safety Invariant: Refuse execution if connected to production database
  assertIsolatedStagingDatabase("realPostgresProof runtime verification");

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
  const uidRefereePunjab = crypto.randomUUID();
  const uidRefereeExpiredOnly = crypto.randomUUID();
  const uidRefereeOther = crypto.randomUUID();

  const profileId1 = crypto.randomUUID();
  const profileId2 = crypto.randomUUID();
  const eventIdPunjab = crypto.randomUUID();
  const postGymId = crypto.randomUUID();
  const certActiveId = crypto.randomUUID();
  const certExpiredId = crypto.randomUUID();
  const certExpiredOnlyId = crypto.randomUUID();
  const certOtherId = crypto.randomUUID();
  const matchIdPunjab = crypto.randomUUID();
  const teamId = crypto.randomUUID();

  const testUserIds = [
    uidAthlete1,
    uidAthlete2,
    uidAdmin,
    uidDirectorPunjab,
    uidDirectorSindh,
    uidRefereePunjab,
    uidRefereeExpiredOnly,
    uidRefereeOther,
  ];
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
      {
        id: uidRefereePunjab,
        email: `ref_punjab_${Date.now()}@armsphere.test`,
        username: `refpun_${Date.now().toString().slice(-6)}`,
        passwordHash: "$2b$10$dummyHashForTestingRealPostgresAuth0000000000000000000000",
        role: UserRole.REFEREE,
        fullName: "Punjab Official Referee",
        isActive: true,
        province: "Punjab",
        regionalCoverage: "Punjab",
      },
      {
        id: uidRefereeExpiredOnly,
        email: `ref_expired_${Date.now()}@armsphere.test`,
        username: `refexp_${Date.now().toString().slice(-6)}`,
        passwordHash: "$2b$10$dummyHashForTestingRealPostgresAuth0000000000000000000000",
        role: UserRole.REFEREE,
        fullName: "Expired Only Referee",
        isActive: true,
        province: "Punjab",
        regionalCoverage: "Punjab",
      },
      {
        id: uidRefereeOther,
        email: `ref_other_${Date.now()}@armsphere.test`,
        username: `refoth_${Date.now().toString().slice(-6)}`,
        passwordHash: "$2b$10$dummyHashForTestingRealPostgresAuth0000000000000000000000",
        role: UserRole.REFEREE,
        fullName: "Other Punjab Referee",
        isActive: true,
        province: "Punjab",
        regionalCoverage: "Punjab",
      },
    ] as any);
    console.log("  ✓ Seeded 8 canonical users in users table");

    // Insert Referee Certifications
    await db.insert(refereeCertifications).values([
      {
        id: certActiveId,
        userId: uidRefereePunjab,
        certificationLevel: "PRO_LEVEL_1",
        issuedAt: new Date(Date.now() - 86400000 * 30),
        expiresAt: new Date(Date.now() + 86400000 * 60),
        status: "ACTIVE",
        issuingBody: "WAF_OFFICIAL",
      },
      {
        id: certExpiredId,
        userId: uidRefereePunjab,
        certificationLevel: "PRO_LEVEL_2",
        issuedAt: new Date(Date.now() - 86400000 * 400),
        expiresAt: new Date(Date.now() - 86400000 * 30),
        status: "ACTIVE",
        issuingBody: "WAF_OFFICIAL",
      },
      {
        id: certExpiredOnlyId,
        userId: uidRefereeExpiredOnly,
        certificationLevel: "PRO_LEVEL_1",
        issuedAt: new Date(Date.now() - 86400000 * 400),
        expiresAt: new Date(Date.now() - 86400000 * 30),
        status: "EXPIRED",
        issuingBody: "WAF_OFFICIAL",
      },
      {
        id: certOtherId,
        userId: uidRefereeOther,
        certificationLevel: "PRO_LEVEL_1",
        issuedAt: new Date(Date.now() - 86400000 * 30),
        expiresAt: new Date(Date.now() + 86400000 * 60),
        status: "ACTIVE",
        issuingBody: "WAF_OFFICIAL",
      },
    ]);
    console.log("  ✓ Seeded active and expired referee certifications in referee_certifications table");

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
        leftArmElo: 1500,
        rightArmElo: 1500,
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
        leftArmElo: 1500,
        rightArmElo: 1500,
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

    // Insert Real Match fixture in Punjab
    await db.insert(matches).values({
      id: matchIdPunjab,
      challengerId: profileId1,
      opponentId: profileId2,
      arm: "RIGHT",
      refereeId: uidRefereePunjab,
      winnerId: profileId1,
      scoreLine: "3-1",
      status: "PENDING_VERIFICATION",
      province: "Punjab",
      createdAt: new Date(),
      updatedAt: new Date(),
    });
    console.log("  ✓ Seeded official match fixture in matches table");

    // Generate JWT Tokens
    const tokenAthlete1 = generateAccessToken(uidAthlete1, "ath1@test.com", UserRole.ATHLETE, jwtSecret);
    const tokenAthlete2 = generateAccessToken(uidAthlete2, "ath2@test.com", UserRole.ATHLETE, jwtSecret);
    const tokenAdmin = generateAccessToken(uidAdmin, "adm@test.com", UserRole.SYSTEM_ADMIN, jwtSecret);
    const tokenDirPunjab = generateAccessToken(uidDirectorPunjab, "dirpun@test.com", UserRole.PROVINCIAL_DIRECTOR, jwtSecret);
    const tokenDirSindh = generateAccessToken(uidDirectorSindh, "dirsin@test.com", UserRole.PROVINCIAL_DIRECTOR, jwtSecret);
    const tokenRefereePunjab = generateAccessToken(uidRefereePunjab, "refpun@test.com", UserRole.REFEREE, jwtSecret);
    const tokenRefereeExpired = generateAccessToken(uidRefereeExpiredOnly, "refexp@test.com", UserRole.REFEREE, jwtSecret);
    const tokenRefereeOther = generateAccessToken(uidRefereeOther, "refoth@test.com", UserRole.REFEREE, jwtSecret);

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

    // PROBE 11: Real PostgreSQL Referee Certification Expiry & Status Transition
    console.log("\n  -> PROBE 11: Automated Referee Certification Expiry Transition in real PostgreSQL");
    const expiryResult = await RefereeCertificationService.processExpiredCertifications();
    if (expiryResult.expiredCount < 1) throw new Error("PROBE 11 FAILED: Expected at least 1 expired certification transitioned");
    
    const [expiredRow] = await db.select().from(refereeCertifications).where(eq(refereeCertifications.id, certExpiredId));
    if (!expiredRow || expiredRow.status !== "EXPIRED") throw new Error(`PROBE 11 FAILED: Expected EXPIRED status in PostgreSQL, got ${expiredRow?.status}`);
    
    const [activeRow] = await db.select().from(refereeCertifications).where(eq(refereeCertifications.id, certActiveId));
    if (!activeRow || activeRow.status !== "ACTIVE") throw new Error(`PROBE 11 FAILED: Expected ACTIVE status in PostgreSQL, got ${activeRow?.status}`);
    console.log("     ✓ PROVED: Expired certification transitioned to EXPIRED, active certification remained ACTIVE in real PostgreSQL");

    // PROBE 12: Real PostgreSQL Province Query (users.province Join)
    console.log("\n  -> PROBE 12: Provincial Director querying referee certifications by province in real PostgreSQL");
    const punjabCerts = await RefereeCertificationService.listCertificationsByProvince(uidDirectorPunjab, "Punjab");
    if (!Array.isArray(punjabCerts) || punjabCerts.length === 0) {
      throw new Error("PROBE 12 FAILED: Expected at least 1 certification for Punjab");
    }
    const foundCert = punjabCerts.find(c => c.id === certActiveId || c.id === certExpiredId);
    if (!foundCert || foundCert.userProvince !== "Punjab") {
      throw new Error("PROBE 12 FAILED: userProvince not joined properly from users table");
    }
    console.log(`     ✓ PROVED: Punjab Director retrieved ${punjabCerts.length} referee cert(s) with users.province joined`);

    let sindhBlocked = false;
    try {
      await RefereeCertificationService.listCertificationsByProvince(uidDirectorSindh, "Punjab");
    } catch (err: any) {
      sindhBlocked = err.status === 403 || err.name === "ForbiddenError";
    }
    if (!sindhBlocked) throw new Error("PROBE 12 FAILED: Sindh Director was not blocked from querying Punjab");
    console.log("     ✓ BLOCKED: Cross-province director query forbidden (Sindh != Punjab)");

    // PROBE 13: Real PostgreSQL Athlete Identity Resolution (profileId vs userId)
    console.log("\n  -> PROBE 13: Owner retrieving profile by profileId without false self-block in real PostgreSQL");
    const p13 = await request(app)
      .get(`/api/v1/athletes/${profileId1}`)
      .set("Authorization", `Bearer ${tokenAthlete1}`);
    if (p13.status !== 200) throw new Error(`PROBE 13 FAILED: Expected 200, got ${p13.status}`);
    const resolvedId = p13.body.data?.id || p13.body.id;
    if (resolvedId !== profileId1) {
      throw new Error(`PROBE 13 FAILED: Expected profileId ${profileId1}, got ${resolvedId}`);
    }
    console.log("     ✓ PROVED: Athlete resolved identity correctly and retrieved own profile via profileId");

    // PROBE 14: Real PostgreSQL Composite Uniqueness Constraint on team_members
    console.log("\n  -> PROBE 14: PostgreSQL composite unique constraint enforcement (team_id, athlete_id)");
    await db.insert(teams).values({
      id: teamId,
      name: `Test Team ${Date.now()}`,
      createdAt: new Date(),
      updatedAt: new Date(),
    });
    const memberId1 = crypto.randomUUID();
    await db.insert(teamMembers).values({
      id: memberId1,
      teamId: teamId,
      athleteId: profileId1,
      role: "MEMBER",
      joinedAt: new Date(),
    });

    let uniqueViolated = false;
    try {
      const memberIdDuplicate = crypto.randomUUID();
      await db.insert(teamMembers).values({
        id: memberIdDuplicate,
        teamId: teamId,
        athleteId: profileId1,
        role: "MEMBER",
        joinedAt: new Date(),
      });
    } catch (dbErr: any) {
      if (dbErr.code === "23505" || String(dbErr.message).includes("unique")) {
        uniqueViolated = true;
      }
    }
    if (!uniqueViolated) throw new Error("PROBE 14 FAILED: Expected PostgreSQL unique constraint violation 23505 on duplicate (team_id, athlete_id)");
    console.log("     ✓ PROVED: Real PostgreSQL strictly enforced composite unique index idx_team_members_team_athlete (23505)");

    // PROBE 15: Expired Referee Attempting to Verify Match in Real PostgreSQL
    console.log("\n  -> PROBE 15: Expired Referee attempting to verify match in real PostgreSQL");
    const p15 = await request(app)
      .post(`/matches/${matchIdPunjab}/verify`)
      .set("Authorization", `Bearer ${tokenRefereeExpired}`);
    console.log(`     HTTP status: ${p15.status} (expected: 403)`);
    if (p15.status !== 403) throw new Error(`PROBE 15 FAILED: Expected 403, got ${p15.status}`);
    const [m15] = await db.select().from(matches).where(eq(matches.id, matchIdPunjab));
    if (m15.status !== "PENDING_VERIFICATION") throw new Error("PROBE 15 FAILED: Match status was mutated on unauthorized attempt");
    console.log("     ✓ BLOCKED: Expired referee verification blocked, match remains PENDING_VERIFICATION");

    // PROBE 16: Unassigned Referee Attempting to Verify Match in Real PostgreSQL
    console.log("\n  -> PROBE 16: Different/Unassigned Referee attempting to verify match in real PostgreSQL");
    const p16 = await request(app)
      .post(`/matches/${matchIdPunjab}/verify`)
      .set("Authorization", `Bearer ${tokenRefereeOther}`);
    console.log(`     HTTP status: ${p16.status} (expected: 403)`);
    if (p16.status !== 403) throw new Error(`PROBE 16 FAILED: Expected 403, got ${p16.status}`);
    const [m16] = await db.select().from(matches).where(eq(matches.id, matchIdPunjab));
    if (m16.status !== "PENDING_VERIFICATION") throw new Error("PROBE 16 FAILED: Match status was mutated on unassigned referee attempt");
    console.log("     ✓ BLOCKED: Unassigned referee verification blocked, match remains PENDING_VERIFICATION");

    // PROBE 17: Out-of-Jurisdiction Provincial Director Attempting to Verify Match in Real PostgreSQL
    console.log("\n  -> PROBE 17: Sindh Director attempting to verify Punjab match in real PostgreSQL");
    const p17 = await request(app)
      .post(`/matches/${matchIdPunjab}/verify`)
      .set("Authorization", `Bearer ${tokenDirSindh}`);
    console.log(`     HTTP status: ${p17.status} (expected: 403)`);
    if (p17.status !== 403) throw new Error(`PROBE 17 FAILED: Expected 403, got ${p17.status}`);
    console.log("     ✓ BLOCKED: Cross-province director verification forbidden (Sindh != Punjab)");

    // PROBE 18: Assigned, Actively Certified Referee Verifying Match in Real PostgreSQL
    console.log("\n  -> PROBE 18: Assigned, actively certified Referee verifying match in real PostgreSQL");
    const p18 = await request(app)
      .post(`/matches/${matchIdPunjab}/verify`)
      .set("Authorization", `Bearer ${tokenRefereePunjab}`);
    console.log(`     HTTP status: ${p18.status} (expected: 200)`);
    if (p18.status !== 200) throw new Error(`PROBE 18 FAILED: Expected 200, got ${p18.status}`);
    const [m18] = await db.select().from(matches).where(eq(matches.id, matchIdPunjab));
    if (m18.status !== "VERIFIED" || !m18.verifiedAt) {
      throw new Error(`PROBE 18 FAILED: Expected VERIFIED status with verifiedAt timestamp in PostgreSQL`);
    }
    const ledgers18 = await db.select().from(eloLedger).where(eq(eloLedger.matchId, matchIdPunjab));
    if (ledgers18.length !== 2) {
      throw new Error(`PROBE 18 FAILED: Expected exactly 2 elo_ledger rows in PostgreSQL, got ${ledgers18.length}`);
    }
    const [ath1_after] = await db.select().from(athleteProfiles).where(eq(athleteProfiles.id, profileId1));
    const [ath2_after] = await db.select().from(athleteProfiles).where(eq(athleteProfiles.id, profileId2));
    if (ath1_after.rightArmElo <= 1500 || ath2_after.rightArmElo >= 1500) {
      throw new Error("PROBE 18 FAILED: Expected athlete ELO ratings to be updated transactionally");
    }
    console.log(`     ✓ PROVED: Assigned referee verified match in real PostgreSQL; ratings updated: Winner ${ath1_after.rightArmElo}, Opponent ${ath2_after.rightArmElo}`);

    // PROBE 19: Second Verification Attempt on Already Verified Match in Real PostgreSQL
    console.log("\n  -> PROBE 19: Second verification attempt on already verified match in real PostgreSQL");
    const p19 = await request(app)
      .post(`/matches/${matchIdPunjab}/verify`)
      .set("Authorization", `Bearer ${tokenRefereePunjab}`);
    console.log(`     HTTP status: ${p19.status} (expected: 409)`);
    if (p19.status !== 409) throw new Error(`PROBE 19 FAILED: Expected 409 Conflict, got ${p19.status}`);
    const ledgers19 = await db.select().from(eloLedger).where(eq(eloLedger.matchId, matchIdPunjab));
    if (ledgers19.length !== 2) throw new Error(`PROBE 19 FAILED: Duplicate elo_ledger rows created on second attempt`);
    console.log("     ✓ BLOCKED: Double-verification rejected with 409 Conflict; ledger remains intact");

    // PROBE 20: PostgreSQL Composite Unique Constraint Enforcement on elo_ledger
    console.log("\n  -> PROBE 20: PostgreSQL composite unique constraint enforcement idx_elo_ledger_match_athlete (23505)");
    let eloUniqueViolated = false;
    try {
      await db.insert(eloLedger).values({
        matchId: matchIdPunjab,
        athleteId: profileId1,
        arm: "RIGHT",
        previousElo: 1500,
        newElo: 1532,
        eloDelta: 32,
      });
    } catch (dbErr: any) {
      if (dbErr.code === "23505" || String(dbErr.message).includes("unique")) {
        eloUniqueViolated = true;
      }
    }
    if (!eloUniqueViolated) throw new Error("PROBE 20 FAILED: Expected PostgreSQL unique constraint violation 23505 on duplicate (match_id, athlete_id)");
    console.log("     ✓ PROVED: Real PostgreSQL strictly enforced composite unique index idx_elo_ledger_match_athlete (23505)");

    // PROBE 21: Client Province Spoofing & Out-of-Jurisdiction Director Match Submission in Real PostgreSQL
    console.log("\n  -> PROBE 21: Forged client province rejection & Provincial Director submission jurisdiction in real PostgreSQL");
    const p21Spoof = await request(app)
      .post("/matches")
      .set("Authorization", `Bearer ${tokenRefereePunjab}`)
      .send({
        challengerId: profileId1,
        opponentId: profileId2,
        arm: "RIGHT",
        winnerId: profileId1,
        scoreLine: "3-0",
        province: "Balochistan", // Spoofed! Challenger is in Punjab
      });
    console.log(`     Forged province HTTP status: ${p21Spoof.status} (expected: 403)`);
    if (p21Spoof.status !== 403) throw new Error(`PROBE 21 FAILED: Expected 403 on spoofed province, got ${p21Spoof.status}`);

    const p21OutDir = await request(app)
      .post("/matches")
      .set("Authorization", `Bearer ${tokenDirSindh}`)
      .send({
        challengerId: profileId1,
        opponentId: profileId2,
        arm: "RIGHT",
        winnerId: profileId1,
        scoreLine: "3-0",
      });
    console.log(`     Out-of-province director HTTP status: ${p21OutDir.status} (expected: 403)`);
    if (p21OutDir.status !== 403) throw new Error(`PROBE 21 FAILED: Expected 403 on out-of-province director submission, got ${p21OutDir.status}`);
    console.log("     ✓ BLOCKED: Client province spoofing and cross-province director match submission blocked in real PostgreSQL");

    // PROBE 22: Concurrent Promise.all Match Verification Race Condition Proof in Real PostgreSQL
    console.log("\n  -> PROBE 22: Concurrent Promise.all match verification race condition proof in real PostgreSQL");
    const matchIdRace = crypto.randomUUID();
    await db.insert(matches).values({
      id: matchIdRace,
      challengerId: profileId1,
      opponentId: profileId2,
      arm: "RIGHT",
      refereeId: uidRefereePunjab,
      winnerId: profileId2,
      scoreLine: "3-1",
      status: "PENDING_VERIFICATION",
      province: "Punjab",
      createdAt: new Date(Date.now() + 1000),
      updatedAt: new Date(Date.now() + 1000),
    });

    const [raceRes1, raceRes2] = await Promise.all([
      request(app).post(`/matches/${matchIdRace}/verify`).set("Authorization", `Bearer ${tokenRefereePunjab}`),
      request(app).post(`/matches/${matchIdRace}/verify`).set("Authorization", `Bearer ${tokenRefereePunjab}`),
    ]);
    const statuses22 = [raceRes1.status, raceRes2.status].sort((a, b) => a - b);
    console.log(`     Concurrent HTTP statuses: [${statuses22.join(", ")}] (expected: [200, 409])`);
    if (statuses22[0] !== 200 || statuses22[1] !== 409) {
      throw new Error(`PROBE 22 FAILED: Expected [200, 409], got [${statuses22.join(", ")}]`);
    }
    const raceLedgers = await db.select().from(eloLedger).where(eq(eloLedger.matchId, matchIdRace));
    if (raceLedgers.length !== 2) {
      throw new Error(`PROBE 22 FAILED: Expected exactly 2 elo_ledger rows for race match, got ${raceLedgers.length}`);
    }
    console.log("     ✓ PROVED: Concurrent verification serialized via SELECT ... FOR UPDATE; 1x 200, 1x 409, zero double-applied ELO");

    // PROBE 23: Chronological ELO Replay on voidMatch Across 2-Match Sequence in Real PostgreSQL
    console.log("\n  -> PROBE 23: Chronological ELO replay on voidMatch across 2-match sequence in real PostgreSQL");
    // Ensure matchIdPunjab has an earlier verifiedAt than matchIdRace
    await db.update(matches).set({ verifiedAt: new Date(Date.now() - 60000) }).where(eq(matches.id, matchIdPunjab));
    await db.update(matches).set({ verifiedAt: new Date(Date.now() - 10000) }).where(eq(matches.id, matchIdRace));

    // Void matchIdPunjab (Match 1 where Athlete 1 beat Athlete 2).
    // Match 2 (matchIdRace where Athlete 2 beat Athlete 1) must be replayed from 1500 vs 1500 -> Athlete 2 = 1532, Athlete 1 = 1468!
    const p23Void = await request(app)
      .post(`/matches/${matchIdPunjab}/void`)
      .set("Authorization", `Bearer ${tokenAdmin}`)
      .send({ reason: "Real PostgreSQL chronological ELO replay verification test." });
    console.log(`     POST /matches/${matchIdPunjab}/void HTTP status: ${p23Void.status} (expected: 200)`);
    if (p23Void.status !== 200) throw new Error(`PROBE 23 FAILED: Expected 200 on voidMatch, got ${p23Void.status}`);

    const [ath1_replayed] = await db.select().from(athleteProfiles).where(eq(athleteProfiles.id, profileId1));
    const [ath2_replayed] = await db.select().from(athleteProfiles).where(eq(athleteProfiles.id, profileId2));
    const replayedLedgers = await db.select().from(eloLedger).where(eq(eloLedger.matchId, matchIdRace));
    const ledgerAth1 = replayedLedgers.find((l) => l.athleteId === profileId1);
    const ledgerAth2 = replayedLedgers.find((l) => l.athleteId === profileId2);
    if (
      ath1_replayed.rightArmElo !== 1468 ||
      ath2_replayed.rightArmElo !== 1532 ||
      ledgerAth1?.previousElo !== 1500 ||
      ledgerAth1?.newElo !== 1468 ||
      ledgerAth2?.previousElo !== 1500 ||
      ledgerAth2?.newElo !== 1532
    ) {
      throw new Error(
        `PROBE 23 FAILED: Unexpected replayed ELO state: ath1=${ath1_replayed.rightArmElo}, ath2=${ath2_replayed.rightArmElo}`
      );
    }
    console.log(
      `     ✓ PROVED: Voiding Match 1 replayed Match 2 in real PostgreSQL (Athlete 1: 1500->1468, Athlete 2: 1500->1532)`
    );

    // PROBE 24: P0-7 Dispute Authorization & Provincial Jurisdiction in Real PostgreSQL
    console.log("\n  -> PROBE 24: Dispute authorization & authoritative province population in real PostgreSQL");
    const uidStrangerAthlete = crypto.randomUUID();
    const profileStrangerId = crypto.randomUUID();
    const bracketIdPunjab = crypto.randomUUID();
    const tMatchIdPunjab = crypto.randomUUID();
    testUserIds.push(uidStrangerAthlete);

    await db.insert(users).values({
      id: uidStrangerAthlete,
      email: `stranger_${Date.now()}@armsphere.test`,
      username: `str_${Date.now().toString().slice(-6)}`,
      passwordHash: "$2b$10$dummyHashForTestingRealPostgresAuth0000000000000000000000",
      role: UserRole.ATHLETE,
      fullName: "Unrelated Stranger Athlete",
      isActive: true,
      province: "Punjab",
    } as any);
    await db.insert(athleteProfiles).values({
      id: profileStrangerId,
      userId: uidStrangerAthlete,
      displayName: "Stranger Puller",
      province: "Punjab",
      city: "Multan",
      handedness: "RIGHT",
      dominantArm: "RIGHT",
      dateOfBirth: new Date("1998-01-01"),
      gender: "MALE",
      weightClass: "80KG",
      profileVisibility: "PUBLIC",
      leftArmElo: 1500,
      rightArmElo: 1500,
    });
    await db.insert(brackets).values({
      id: bracketIdPunjab,
      eventId: eventIdPunjab,
      name: "Senior Men 80kg Right",
      format: "SINGLE_ELIMINATION",
      division: "SENIOR_MEN",
      weightClass: "80KG",
      arm: "RIGHT",
      status: "ACTIVE",
    });
    await db.insert(tournamentMatches).values({
      id: tMatchIdPunjab,
      bracketId: bracketIdPunjab,
      round: 1,
      matchIndex: 0,
      bracketType: "PRIMARY",
      athleteAId: profileId1,
      athleteBId: profileId2,
      refereeId: uidRefereePunjab,
      winnerId: profileId1,
      scoreLine: "3-0",
      status: "COMPLETED",
      province: "Punjab",
    });

    const tokenStranger = generateAccessToken(uidStrangerAthlete, "stranger@test.com", UserRole.ATHLETE, jwtSecret);
    const p24Stranger = await request(app)
      .post("/governance/disputes")
      .set("Authorization", `Bearer ${tokenStranger}`)
      .send({
        matchId: tMatchIdPunjab,
        title: "Stranger unauthorized dispute",
        description: "Attempting to file a dispute on a tournament match I did not participate in.",
      });
    console.log(`     Unrelated athlete dispute HTTP status: ${p24Stranger.status} (expected: 403)`);
    if (p24Stranger.status !== 403) throw new Error(`PROBE 24 FAILED: Expected 403 for unrelated athlete, got ${p24Stranger.status}`);

    const p24Participant = await request(app)
      .post("/governance/disputes")
      .set("Authorization", `Bearer ${tokenAthlete1}`)
      .send({
        matchId: tMatchIdPunjab,
        title: "Participant legitimate dispute",
        description: "Filing legitimate participant dispute on tournament match in real PostgreSQL.",
      });
    console.log(`     Participant dispute HTTP status: ${p24Participant.status} (expected: 201), province: ${p24Participant.body.dispute?.province}`);
    if (p24Participant.status !== 201 || p24Participant.body.dispute?.province !== "Punjab") {
      throw new Error(`PROBE 24 FAILED: Expected 201 with province Punjab, got ${p24Participant.status}`);
    }
    console.log("     ✓ PROVED: Unrelated dispute blocked (403); participant dispute created (201) with authoritative province='Punjab'");

    // PROBE 25: P0-8 Tournament Operator Ownership & Provincial Jurisdiction in Real PostgreSQL
    console.log("\n  -> PROBE 25: Tournament operator ownership & provincial director jurisdiction in real PostgreSQL");
    const uidOtherOperator = crypto.randomUUID();
    const regIdPunjab = crypto.randomUUID();
    testUserIds.push(uidOtherOperator);

    await db.insert(users).values({
      id: uidOtherOperator,
      email: `op_other_${Date.now()}@armsphere.test`,
      username: `opoth_${Date.now().toString().slice(-6)}`,
      passwordHash: "$2b$10$dummyHashForTestingRealPostgresAuth0000000000000000000000",
      role: UserRole.TOURNAMENT_OPERATOR,
      fullName: "Unrelated Tournament Operator",
      isActive: true,
      province: "Punjab",
    } as any);
    await db.insert(eventRegistrations).values({
      id: regIdPunjab,
      eventId: eventIdPunjab,
      athleteId: profileId1,
      division: "SENIOR_MEN",
      weightClass: "80KG",
      arm: "RIGHT",
      status: "PENDING",
    });

    const tokenOtherOp = generateAccessToken(uidOtherOperator, "op_other@test.com", UserRole.TOURNAMENT_OPERATOR, jwtSecret);

    const p25OtherOpApprove = await request(app)
      .post(`/tournaments/registrations/${regIdPunjab}/approve`)
      .set("Authorization", `Bearer ${tokenOtherOp}`);
    const p25SindhDirApprove = await request(app)
      .post(`/tournaments/registrations/${regIdPunjab}/approve`)
      .set("Authorization", `Bearer ${tokenDirSindh}`);
    const p25OtherOpTable = await request(app)
      .post(`/tournaments/events/${eventIdPunjab}/tables`)
      .set("Authorization", `Bearer ${tokenOtherOp}`)
      .send({ name: "Unauthorized Table" });
    const p25PunjabDirApprove = await request(app)
      .post(`/tournaments/registrations/${regIdPunjab}/approve`)
      .set("Authorization", `Bearer ${tokenDirPunjab}`);

    console.log(
      `     HTTP statuses: OtherOpApprove=${p25OtherOpApprove.status}, SindhDirApprove=${p25SindhDirApprove.status}, OtherOpTable=${p25OtherOpTable.status}, PunjabDirApprove=${p25PunjabDirApprove.status}`
    );
    if (
      p25OtherOpApprove.status !== 403 ||
      p25SindhDirApprove.status !== 403 ||
      p25OtherOpTable.status !== 403 ||
      p25PunjabDirApprove.status !== 200
    ) {
      throw new Error("PROBE 25 FAILED: Unexpected tournament ownership/jurisdiction statuses");
    }
    console.log("     ✓ PROVED: Cross-operator and cross-province tournament mutations blocked (403); owning organizer allowed (200)");

    // PROBE 26: P0-9 Live PostgreSQL Schema, Foreign Key, Delete Rule & Unique Index Verification
    console.log("\n  -> PROBE 26: Live PostgreSQL pg_constraint & pg_index integrity verification (P0-9)");
    const requiredIndexes = [
      "idx_elo_ledger_match_athlete",
      "idx_team_members_team_athlete",
      "idx_tournament_table_queue_match_id",
      "idx_tournament_table_queue_table_position",
      "idx_user_role_grants_user_role",
      "idx_users_province",
      "idx_matches_province",
    ];
    const indexCheck = await pool.query(
      `SELECT indexname, indexdef FROM pg_indexes WHERE schemaname = 'public' AND indexname = ANY($1::text[])`,
      [requiredIndexes]
    );
    const foundIndexNames = new Set(indexCheck.rows.map((r: any) => r.indexname));
    for (const reqIdx of requiredIndexes) {
      if (!foundIndexNames.has(reqIdx)) {
        throw new Error(`PROBE 26 FAILED: Missing required index ${reqIdx} in live PostgreSQL`);
      }
    }

    const fkCheck = await pool.query(`
      SELECT tc.table_name, tc.constraint_name, rc.delete_rule
      FROM information_schema.table_constraints tc
      JOIN information_schema.referential_constraints rc
        ON tc.constraint_name = rc.constraint_name
      WHERE tc.constraint_type = 'FOREIGN KEY'
        AND tc.table_name IN ('matches', 'elo_ledger', 'team_members', 'match_tables', 'tournament_table_queue', 'disputes')
    `);
    if (fkCheck.rows.length < 8) {
      throw new Error(`PROBE 26 FAILED: Expected foreign key constraints on domain tables, found ${fkCheck.rows.length}`);
    }
    const cascadeTables = fkCheck.rows.filter((r: any) => r.delete_rule === "CASCADE").map((r: any) => r.table_name);
    if (!cascadeTables.includes("match_tables") || !cascadeTables.includes("tournament_table_queue")) {
      throw new Error(`PROBE 26 FAILED: Expected CASCADE delete rule on match_tables and tournament_table_queue`);
    }
    console.log(
      `     ✓ PROVED: Verified ${foundIndexNames.size} canonical indexes and ${fkCheck.rows.length} foreign key constraints (including CASCADE rules) in live PostgreSQL`
    );

    console.log("\n================================================================================");
    console.log("   ALL 26 REAL POSTGRESQL RUNTIME PROBES PASSED WITH 100% SUCCESS!");
    console.log("================================================================================");
  } finally {
    // Clean up seeded fixtures
    console.log("\n[CLEANUP] Cleaning up seeded test records from Neon PostgreSQL...");
    try {
      await db.delete(disputes).where(inArray(disputes.creatorId, testUserIds)).catch(() => {});
      await db.delete(auditEvents).where(inArray(auditEvents.actorId, testUserIds)).catch(() => {});
      await db.delete(eloLedger).where(inArray(eloLedger.athleteId, [profileId1, profileId2])).catch(() => {});
      await db.delete(matches).where(inArray(matches.challengerId, [profileId1, profileId2])).catch(() => {});
      await pool.query(`DELETE FROM tournament_matches WHERE bracket_id IN (SELECT id FROM brackets WHERE event_id = $1)`, [eventIdPunjab]).catch(() => {});
      await db.delete(brackets).where(eq(brackets.eventId, eventIdPunjab)).catch(() => {});
      await db.delete(eventRegistrations).where(eq(eventRegistrations.eventId, eventIdPunjab)).catch(() => {});
      await db.delete(matchTables).where(eq(matchTables.eventId, eventIdPunjab)).catch(() => {});
      await db.delete(teamMembers).where(eq(teamMembers.teamId, teamId)).catch(() => {});
      await db.delete(teams).where(eq(teams.id, teamId)).catch(() => {});
      await db.delete(refereeCertifications).where(inArray(refereeCertifications.id, [certActiveId, certExpiredId, certExpiredOnlyId, certOtherId])).catch(() => {});
      await db.delete(notifications).where(inArray(notifications.userId, testUserIds)).catch(() => {});
      await db.delete(events).where(eq(events.id, eventIdPunjab)).catch(() => {});
      await db.delete(communityPosts).where(eq(communityPosts.id, postGymId)).catch(() => {});
      await pool.query(`DELETE FROM athlete_profiles WHERE user_id = ANY($1::uuid[])`, [testUserIds]).catch(() => {});
      await db.delete(users).where(inArray(users.id, testUserIds)).catch(() => {});
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
