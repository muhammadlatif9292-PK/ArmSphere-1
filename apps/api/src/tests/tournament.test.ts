import { describe, it, expect, beforeEach, vi } from "vitest";
import request from "supertest";
import { testDbStore } from "./setup.js";
import { app } from "../app.js";
import { generateAccessToken } from "@armsphere/cryptography";
import { UserRole } from "@armsphere/types";
import { processedJobsTracker, resetJobTrackers } from "../services/scheduledJobs.js";
import env from "../config/env.js";

// Helper to construct authorization header
function authHeader(role: UserRole = UserRole.ATHLETE, userId?: string) {
  let defaultUserId = "00000000-0000-0000-0000-000000000099";
  if (role === UserRole.REFEREE) {
    defaultUserId = UUID_REFEREE;
  } else if (role === UserRole.PROVINCIAL_DIRECTOR) {
    defaultUserId = UUID_DIRECTOR;
  }
  const token = generateAccessToken(userId || defaultUserId, "test@armsphere.com", role, env.JWT_ACCESS_SECRET);
  return `Bearer ${token}`;
}

// Strictly valid RFC-compliant UUIDs for testing
const UUID_EVENT_DRAFT = "11111111-1111-1111-1111-111111111111";
const UUID_EVENT_ACTIVE = "11111111-1111-1111-1111-222222222222";
const UUID_EVENT_METRICS = "11111111-1111-1111-1111-333333333333";

const UUID_REG_ACTIVE = "22222222-2222-2222-2222-111111111111";
const UUID_REG_MEMBER2 = "22222222-2222-2222-2222-222222222222";
const UUID_REG_MEMBER3 = "22222222-2222-2222-2222-333333333333";

const UUID_BRACKET = "33333333-3333-3333-3333-111111111111";

const UUID_MATCH_ONE = "44444444-4444-4444-4444-111111111111";
const UUID_MATCH_FINAL = "44444444-4444-4444-4444-222222222222";

const UUID_TABLE = "55555555-5555-5555-5555-111111111111";

const UUID_ATHLETE_A = "00000000-0000-0000-0000-000000000001";
const UUID_ATHLETE_B = "00000000-0000-0000-0000-000000000002";
const UUID_ATHLETE_C = "00000000-0000-0000-0000-000000000003";

const UUID_DIRECTOR = "00000000-0000-0000-0000-000000000004";
const UUID_REFEREE = "00000000-0000-0000-0000-000000000005";

describe("Sprint 5: Tournament & Event Management System Test Suite", () => {
  beforeEach(() => {
    resetJobTrackers();

    // Seed mock user records
    testDbStore.users = [
      { id: "user-a", role: UserRole.ATHLETE },
      { id: "user-b", role: UserRole.ATHLETE },
      { id: "user-c", role: UserRole.ATHLETE },
      { id: UUID_DIRECTOR, role: UserRole.PROVINCIAL_DIRECTOR },
      { id: UUID_REFEREE, role: UserRole.REFEREE },
      { id: "00000000-0000-0000-0000-000000000099", role: UserRole.ATHLETE }
    ];

    // Seed referee certifications
    testDbStore.refereeCertifications = [
      {
        id: "cert-tournament-ref",
        userId: UUID_REFEREE,
        certificationLevel: "PRO_LEVEL_1",
        issuedAt: new Date(),
        expiresAt: new Date(Date.now() + 86400000 * 365),
        status: "ACTIVE",
        issuingBody: "WAF_OFFICIAL",
      }
    ];

    // Seed mock athlete profiles
    testDbStore.athleteProfiles = [
      {
        id: UUID_ATHLETE_A,
        userId: "user-a",
        displayName: "John Doe",
        gender: "MALE",
        leftArmElo: 1200,
        rightArmElo: 1250,
        province: "Ontario",
        clubName: "Ottawa Arms",
        isActive: true
      },
      {
        id: UUID_ATHLETE_B,
        userId: "user-b",
        displayName: "Jane Smith",
        gender: "FEMALE",
        leftArmElo: 1100,
        rightArmElo: 1150,
        province: "Quebec",
        clubName: "Montreal Pullers",
        isActive: true
      },
      {
        id: UUID_ATHLETE_C,
        userId: "user-c",
        displayName: "Bob Johnson",
        gender: "MALE",
        leftArmElo: 1000,
        rightArmElo: 1050,
        province: "Ontario",
        clubName: "Ottawa Arms",
        isActive: true
      }
    ];

    // Clear event-related mock tables
    testDbStore.events = [];
    testDbStore.eventRegistrations = [];
    testDbStore.officialWeighins = [];
    testDbStore.brackets = [];
    testDbStore.bracketSeeds = [];
    testDbStore.tournamentMatches = [];
    testDbStore.matchTables = [];
    testDbStore.auditLogs = [];
  });

  // ==========================================
  // 1. Event Management
  // ==========================================
  describe("Event Management Endpoints", () => {
    it("should successfully create a new multi-day event with correct date boundaries", async () => {
      const payload = {
        name: "Ontario Provincial Championship",
        registrationStart: "2026-07-01T00:00:00Z",
        registrationEnd: "2026-07-15T23:59:59Z",
        startDate: "2026-08-01T08:00:00Z",
        endDate: "2026-08-03T18:00:00Z",
        province: "Ontario",
        city: "Toronto",
        venue: "Metro Toronto Convention Centre",
        capacity: 150
      };

      const response = await request(app)
        .post("/tournaments/events")
        .send(payload)
        .set("Authorization", authHeader(UserRole.PROVINCIAL_DIRECTOR));

      expect(response.status).toBe(201);
      expect(response.body.name).toBe(payload.name);
      expect(response.body.status).toBe("DRAFT");
      expect(response.body.capacity).toBe(150);
    });

    it("should reject event creation if date boundaries are invalid", async () => {
      const payload = {
        name: "Invalid Event Dates",
        registrationStart: "2026-08-01T00:00:00Z",
        registrationEnd: "2026-07-15T23:59:59Z", // End is before start
        startDate: "2026-08-02T08:00:00Z",
        endDate: "2026-08-03T18:00:00Z",
        province: "Ontario",
        city: "Toronto",
        venue: "Metro Toronto Convention Centre",
        capacity: 100
      };

      const response = await request(app)
        .post("/tournaments/events")
        .send(payload)
        .set("Authorization", authHeader(UserRole.PROVINCIAL_DIRECTOR));

      expect(response.status).toBe(400);
    });

    it("should allow editing, publishing, and cancelling an event", async () => {
      // Setup draft event
      testDbStore.events.push({
        id: UUID_EVENT_DRAFT,
        name: "Test Event",
        registrationStart: new Date("2026-07-01"),
        registrationEnd: new Date("2026-07-15"),
        startDate: new Date("2026-08-01"),
        endDate: new Date("2026-08-02"),
        province: "Ontario",
        city: "Toronto",
        venue: "Old Gym",
        capacity: 50,
        status: "DRAFT"
      });

      // Edit Event
      const editResponse = await request(app)
        .put(`/tournaments/events/${UUID_EVENT_DRAFT}`)
        .send({ venue: "New Luxury Arena", capacity: 100 })
        .set("Authorization", authHeader(UserRole.PROVINCIAL_DIRECTOR));

      expect(editResponse.status).toBe(200);
      expect(editResponse.body.venue).toBe("New Luxury Arena");
      expect(editResponse.body.capacity).toBe(100);

      // Publish Event
      const pubResponse = await request(app)
        .post(`/tournaments/events/${UUID_EVENT_DRAFT}/publish`)
        .set("Authorization", authHeader(UserRole.PROVINCIAL_DIRECTOR));

      expect(pubResponse.status).toBe(200);
      expect(pubResponse.body.status).toBe("PUBLISHED");

      // Cancel Event
      const cancelResponse = await request(app)
        .post(`/tournaments/events/${UUID_EVENT_DRAFT}/cancel`)
        .set("Authorization", authHeader(UserRole.PROVINCIAL_DIRECTOR));

      expect(cancelResponse.status).toBe(200);
      expect(cancelResponse.body.status).toBe("CANCELLED");
    });
  });

  // ==========================================
  // 2. Athlete Registration & Eligibility
  // ==========================================
  describe("Athlete Registration", () => {
    beforeEach(() => {
      testDbStore.events.push({
        id: UUID_EVENT_ACTIVE,
        name: "Active Tourney",
        registrationStart: new Date(Date.now() - 1000 * 60 * 60), // open
        registrationEnd: new Date(Date.now() + 1000 * 60 * 60),
        startDate: new Date(Date.now() + 1000 * 60 * 60 * 24),
        endDate: new Date(Date.now() + 1000 * 60 * 60 * 48),
        province: "Ontario",
        city: "Toronto",
        venue: "Stadium",
        capacity: 2, // low capacity for waitlist test
        status: "PUBLISHED"
      });
    });

    it("should successfully register an eligible athlete", async () => {
      const response = await request(app)
        .post("/tournaments/registrations")
        .send({
          eventId: UUID_EVENT_ACTIVE,
          athleteId: UUID_ATHLETE_A,
          division: "SENIOR",
          weightClass: "70KG",
          arm: "RIGHT"
        })
        .set("Authorization", authHeader());

      expect(response.status).toBe(201);
      expect(response.body.status).toBe("PENDING");
      expect(response.body.division).toBe("SENIOR");
    });

    it("should reject registration if division gender mismatch exists", async () => {
      const response = await request(app)
        .post("/tournaments/registrations")
        .send({
          eventId: UUID_EVENT_ACTIVE,
          athleteId: UUID_ATHLETE_A, // Male
          division: "FEMALE", // Female division
          weightClass: "OPEN",
          arm: "BOTH"
        })
        .set("Authorization", authHeader());

      expect(response.status).toBe(400);
      expect(response.body.detail).toContain("gender");
    });

    it("should place registrant on waitlist if event capacity is exceeded", async () => {
      // Fill capacity
      testDbStore.eventRegistrations.push(
        { id: UUID_REG_MEMBER2, eventId: UUID_EVENT_ACTIVE, athleteId: UUID_ATHLETE_A, division: "SENIOR", weightClass: "70KG", arm: "LEFT", status: "APPROVED" },
        { id: UUID_REG_MEMBER3, eventId: UUID_EVENT_ACTIVE, athleteId: UUID_ATHLETE_B, division: "SENIOR", weightClass: "70KG", arm: "LEFT", status: "APPROVED" }
      );

      const response = await request(app)
        .post("/tournaments/registrations")
        .send({
          eventId: UUID_EVENT_ACTIVE,
          athleteId: UUID_ATHLETE_C,
          division: "SENIOR",
          weightClass: "70KG",
          arm: "LEFT"
        })
        .set("Authorization", authHeader());

      expect(response.status).toBe(201);
      expect(response.body.status).toBe("WAITLISTED");
    });
  });

  // ==========================================
  // 3. Weigh-In System
  // ==========================================
  describe("Official Weigh-In System", () => {
    beforeEach(() => {
      testDbStore.eventRegistrations.push({
        id: UUID_REG_ACTIVE,
        eventId: UUID_EVENT_ACTIVE,
        athleteId: UUID_ATHLETE_A,
        division: "SENIOR",
        weightClass: "70KG",
        arm: "RIGHT",
        status: "APPROVED"
      });
    });

    it("should record weigh-in attempt and correctly determine PASSED status", async () => {
      const response = await request(app)
        .post("/tournaments/weighins")
        .send({
          registrationId: UUID_REG_ACTIVE,
          weight: 68.5,
          certifiedBy: UUID_REFEREE
        })
        .set("Authorization", authHeader(UserRole.REFEREE));

      expect(response.status).toBe(201);
      expect(response.body.status).toBe("PASSED");
      expect(response.body.attemptNumber).toBe(1);

      // Verify Audit Log was recorded
      expect(testDbStore.auditLogs).toHaveLength(1);
      expect(testDbStore.auditLogs[0].action).toBe("WEIGH_IN_RECORDED");
    });

    it("should record FAILED status if athlete is overweight", async () => {
      const response = await request(app)
        .post("/tournaments/weighins")
        .send({
          registrationId: UUID_REG_ACTIVE,
          weight: 71.2,
          certifiedBy: UUID_REFEREE
        })
        .set("Authorization", authHeader(UserRole.REFEREE));

      expect(response.status).toBe(201);
      expect(response.body.status).toBe("FAILED");
    });

    it("should lock weigh-in after certification and block subsequent edits", async () => {
      // Setup weighin
      testDbStore.officialWeighins.push({
        id: "w-1",
        registrationId: UUID_REG_ACTIVE,
        attemptNumber: 1,
        weight: 68.5,
        status: "PASSED",
        certifiedBy: UUID_REFEREE,
        isLocked: false
      });

      // Certify / Lock
      const lockResponse = await request(app)
        .post(`/tournaments/registrations/${UUID_REG_ACTIVE}/certify`)
        .set("Authorization", authHeader(UserRole.REFEREE));

      expect(lockResponse.status).toBe(200);

      // Verify record is locked
      expect(testDbStore.officialWeighins[0].isLocked).toBe(true);

      // Try adding another attempt
      const failResponse = await request(app)
        .post("/tournaments/weighins")
        .send({
          registrationId: UUID_REG_ACTIVE,
          weight: 69.0,
          certifiedBy: UUID_REFEREE
        })
        .set("Authorization", authHeader(UserRole.REFEREE));

      expect(failResponse.status).toBe(400);
    });

    it("should allow division reassignment if weigh-in is not locked", async () => {
      const response = await request(app)
        .post("/tournaments/registrations/reassign")
        .send({
          registrationId: UUID_REG_ACTIVE,
          newDivision: "SENIOR",
          newWeightClass: "75KG"
        })
        .set("Authorization", authHeader(UserRole.REFEREE));

      expect(response.status).toBe(200);
      expect(testDbStore.eventRegistrations[0].weightClass).toBe("75KG");
    });
  });

  // ==========================================
  // 4. Seeding Engine & Bracket Building
  // ==========================================
  describe("Seeding Engine & Bracket Generation", () => {
    beforeEach(() => {
      testDbStore.brackets.push({
        id: UUID_BRACKET,
        eventId: UUID_EVENT_ACTIVE,
        name: "Senior Right Arm 70KG",
        format: "SINGLE_ELIMINATION",
        division: "SENIOR",
        weightClass: "70KG",
        arm: "RIGHT",
        status: "DRAFT",
        seedingLocked: false
      });

      // Add registrations
      testDbStore.eventRegistrations.push(
        { id: UUID_REG_MEMBER2, eventId: UUID_EVENT_ACTIVE, athleteId: UUID_ATHLETE_A, division: "SENIOR", weightClass: "70KG", arm: "RIGHT", status: "APPROVED", leftArmElo: 1200, rightArmElo: 1250 },
        { id: UUID_REG_MEMBER3, eventId: UUID_EVENT_ACTIVE, athleteId: UUID_ATHLETE_C, division: "SENIOR", weightClass: "70KG", arm: "RIGHT", status: "APPROVED", leftArmElo: 1000, rightArmElo: 1050 }
      );

      // Add passed weigh-ins
      testDbStore.officialWeighins.push(
        { id: "w-a", registrationId: UUID_REG_MEMBER2, attemptNumber: 1, weight: 69.5, status: "PASSED", certifiedBy: UUID_REFEREE, isLocked: true },
        { id: "w-c", registrationId: UUID_REG_MEMBER3, attemptNumber: 1, weight: 68.0, status: "PASSED", certifiedBy: UUID_REFEREE, isLocked: true }
      );
    });

    it("should correctly generate ELO-based seeding", async () => {
      const response = await request(app)
        .post(`/tournaments/brackets/${UUID_BRACKET}/seeds`)
        .set("Authorization", authHeader(UserRole.PROVINCIAL_DIRECTOR));

      expect(response.status).toBe(200);
      
      // Verification: Athlete A ELO (1250) is greater than Athlete C ELO (1050)
      // Athlete A should be Seed 1, Athlete C should be Seed 2
      expect(testDbStore.bracketSeeds).toHaveLength(2);
      expect(testDbStore.bracketSeeds[0].athleteId).toBe(UUID_ATHLETE_A);
      expect(testDbStore.bracketSeeds[0].seedPosition).toBe(1);
      expect(testDbStore.bracketSeeds[1].athleteId).toBe(UUID_ATHLETE_C);
      expect(testDbStore.bracketSeeds[1].seedPosition).toBe(2);
    });

    it("should support manual seeding overrides", async () => {
      // Insert seeds
      testDbStore.bracketSeeds.push(
        { id: "s-1", bracketId: UUID_BRACKET, athleteId: UUID_ATHLETE_A, seedPosition: 1, isManualOverride: false },
        { id: "s-2", bracketId: UUID_BRACKET, athleteId: UUID_ATHLETE_C, seedPosition: 2, isManualOverride: false }
      );

      const response = await request(app)
        .post("/tournaments/brackets/seeds/override")
        .send({
          bracketId: UUID_BRACKET,
          athleteId: UUID_ATHLETE_C,
          newPosition: 1
        })
        .set("Authorization", authHeader(UserRole.PROVINCIAL_DIRECTOR));

      expect(response.status).toBe(200);
      
      // Seeds should have swapped positions
      expect(testDbStore.bracketSeeds.find((s) => s.athleteId === UUID_ATHLETE_C)?.seedPosition).toBe(1);
      expect(testDbStore.bracketSeeds.find((s) => s.athleteId === UUID_ATHLETE_A)?.seedPosition).toBe(2);
    });

    it("should block match generation unless seeding configuration is locked", async () => {
      const response = await request(app)
        .post(`/tournaments/brackets/${UUID_BRACKET}/generate`)
        .set("Authorization", authHeader(UserRole.PROVINCIAL_DIRECTOR));

      expect(response.status).toBe(400);
      expect(response.body.detail).toContain("lock");
    });

    it("should generate proper bracket structure after seeds are locked", async () => {
      // Seed & Lock
      testDbStore.bracketSeeds.push(
        { id: "s-1", bracketId: UUID_BRACKET, athleteId: UUID_ATHLETE_A, seedPosition: 1, isManualOverride: false },
        { id: "s-2", bracketId: UUID_BRACKET, athleteId: UUID_ATHLETE_C, seedPosition: 2, isManualOverride: false }
      );
      testDbStore.brackets[0].seedingLocked = true;

      const response = await request(app)
        .post(`/tournaments/brackets/${UUID_BRACKET}/generate`)
        .set("Authorization", authHeader(UserRole.PROVINCIAL_DIRECTOR));

      expect(response.status).toBe(200);

      // Verify match structure was created
      expect(testDbStore.tournamentMatches).toHaveLength(1);
      const match = testDbStore.tournamentMatches[0];
      expect(match.athleteAId).toBe(UUID_ATHLETE_A);
      expect(match.athleteBId).toBe(UUID_ATHLETE_C);
      expect(match.status).toBe("READY");
    });

    it("should successfully retrieve bracket structure with athlete names and ELOs", async () => {
      testDbStore.bracketSeeds.push(
        { id: "s-1", bracketId: UUID_BRACKET, athleteId: UUID_ATHLETE_A, seedPosition: 1, isManualOverride: false },
        { id: "s-2", bracketId: UUID_BRACKET, athleteId: UUID_ATHLETE_C, seedPosition: 2, isManualOverride: false }
      );
      testDbStore.brackets[0].seedingLocked = true;

      await request(app)
        .post(`/tournaments/brackets/${UUID_BRACKET}/generate`)
        .set("Authorization", authHeader(UserRole.PROVINCIAL_DIRECTOR));

      const response = await request(app)
        .get(`/tournaments/brackets/${UUID_BRACKET}`)
        .set("Authorization", authHeader(UserRole.ATHLETE));

      expect(response.status).toBe(200);
      expect(response.body.id).toBe(UUID_BRACKET);
      expect(response.body.matches).toHaveLength(1);
      
      const returnedMatch = response.body.matches[0];
      expect(returnedMatch.athleteAId).toBe(UUID_ATHLETE_A);
      
      // Strict assertions on athlete A name
      expect(returnedMatch.athleteAName).not.toBeNull();
      expect(returnedMatch.athleteAName).not.toBeUndefined();
      expect(typeof returnedMatch.athleteAName).toBe("string");
      expect(returnedMatch.athleteAName).toBe("John Doe");

      expect(returnedMatch.athleteBId).toBe(UUID_ATHLETE_C);

      // Strict assertions on athlete B name
      expect(returnedMatch.athleteBName).not.toBeNull();
      expect(returnedMatch.athleteBName).not.toBeUndefined();
      expect(typeof returnedMatch.athleteBName).toBe("string");
      expect(returnedMatch.athleteBName).toBe("Bob Johnson");

      expect(returnedMatch.status).toBe("READY");
    });
  });

  // ==========================================
  // 5. Match Progression & Table Assignment
  // ==========================================
  describe("Match Queue & Table Management", () => {
    beforeEach(() => {
      testDbStore.matchTables.push({
        id: UUID_TABLE,
        name: "Table Alpha",
        status: "IDLE",
        currentMatchId: null
      });

      testDbStore.tournamentMatches.push({
        id: UUID_MATCH_ONE,
        bracketId: UUID_BRACKET,
        round: 1,
        matchIndex: 1,
        bracketType: "PRIMARY",
        athleteAId: UUID_ATHLETE_A,
        athleteBId: UUID_ATHLETE_C,
        status: "READY",
        tableId: null,
        refereeId: null,
        nextMatchId: UUID_MATCH_FINAL,
        nextMatchPlayerPosition: "A"
      });

      testDbStore.tournamentMatches.push({
        id: UUID_MATCH_FINAL,
        bracketId: UUID_BRACKET,
        round: 2,
        matchIndex: 1,
        bracketType: "PRIMARY",
        athleteAId: null,
        athleteBId: null,
        status: "PENDING"
      });
    });

    it("should support table call operations, referee assignment, and match progression", async () => {
      // 1. Assign Referee
      const refResponse = await request(app)
        .post("/tournaments/matches/referee")
        .send({
          matchId: UUID_MATCH_ONE,
          refereeId: UUID_REFEREE
        })
        .set("Authorization", authHeader(UserRole.PROVINCIAL_DIRECTOR));

      expect(refResponse.status).toBe(200);
      expect(testDbStore.tournamentMatches[0].refereeId).toBe(UUID_REFEREE);

      // 2. Call Match to Table
      const callResponse = await request(app)
        .post("/tournaments/matches/call")
        .send({
          matchId: UUID_MATCH_ONE,
          tableId: UUID_TABLE
        })
        .set("Authorization", authHeader(UserRole.REFEREE));

      expect(callResponse.status).toBe(200);
      expect(testDbStore.tournamentMatches[0].status).toBe("CALLED");
      expect(testDbStore.matchTables[0].status).toBe("ACTIVE");
      expect(testDbStore.matchTables[0].currentMatchId).toBe(UUID_MATCH_ONE);

      // 3. Submit Match Result & Advance Winner
      const resultResponse = await request(app)
        .post("/tournaments/matches/result")
        .send({
          matchId: UUID_MATCH_ONE,
          winnerId: UUID_ATHLETE_A,
          scoreLine: "3-0"
        })
        .set("Authorization", authHeader(UserRole.REFEREE));

      expect(resultResponse.status).toBe(200);
      
      // Verify match state
      expect(testDbStore.tournamentMatches[0].status).toBe("COMPLETED");
      expect(testDbStore.tournamentMatches[0].winnerId).toBe(UUID_ATHLETE_A);

      // Verify table is released
      expect(testDbStore.matchTables[0].status).toBe("IDLE");
      expect(testDbStore.matchTables[0].currentMatchId).toBeNull();

      // Verify progression of Athlete A into the finals match
      expect(testDbStore.tournamentMatches[1].athleteAId).toBe(UUID_ATHLETE_A);
    });
  });

  // ==========================================
  // 6. Metrics & Reporting
  // ==========================================
  describe("Metrics & Reporting Endpoints", () => {
    beforeEach(() => {
      testDbStore.events.push({
        id: UUID_EVENT_METRICS,
        name: "Test Event",
        registrationStart: new Date(),
        registrationEnd: new Date(),
        startDate: new Date(),
        endDate: new Date(),
        province: "Ontario",
        city: "Toronto",
        venue: "Arena",
        capacity: 100,
        status: "PUBLISHED"
      });

      testDbStore.eventRegistrations.push(
        { id: UUID_REG_MEMBER2, eventId: UUID_EVENT_METRICS, athleteId: UUID_ATHLETE_A, division: "SENIOR", weightClass: "70KG", arm: "RIGHT", status: "APPROVED" },
        { id: UUID_REG_MEMBER3, eventId: UUID_EVENT_METRICS, athleteId: UUID_ATHLETE_B, division: "FEMALE", weightClass: "OPEN", arm: "BOTH", status: "APPROVED" }
      );
    });

    it("should return accurate statistics for participation metrics and events", async () => {
      const statsResponse = await request(app)
        .get(`/tournaments/events/${UUID_EVENT_METRICS}/stats`)
        .set("Authorization", authHeader());

      expect(statsResponse.status).toBe(200);
      expect(statsResponse.body.totalRegistrations).toBe(2);
      expect(statsResponse.body.approved).toBe(2);

      const partResponse = await request(app)
        .get("/tournaments/metrics/participation")
        .set("Authorization", authHeader());

      expect(partResponse.status).toBe(200);
      expect(partResponse.body.registrationsByDivision.SENIOR).toBe(1);
      expect(partResponse.body.registrationsByDivision.FEMALE).toBe(1);
    });
  });

  describe("Event Queries", () => {
    beforeEach(() => {
      testDbStore.events.push({
        id: "e-999",
        name: "Mock Tournament List Event",
        startDate: new Date("2026-08-01"),
        endDate: new Date("2026-08-05"),
        registrationStart: new Date("2026-07-01"),
        registrationEnd: new Date("2026-07-15"),
        province: "Ontario",
        city: "Toronto",
        venue: "Arena",
        capacity: 100,
        status: "PUBLISHED"
      });
    });

    it("should list events with filters", async () => {
      const response = await request(app)
        .get("/tournaments/events?status=PUBLISHED")
        .set("Authorization", authHeader());

      expect(response.status).toBe(200);
      expect(Array.isArray(response.body)).toBe(true);
      expect(response.body.some((e: any) => e.id === "e-999")).toBe(true);
    });

    it("should retrieve single event details", async () => {
      const response = await request(app)
        .get("/tournaments/events/e-999")
        .set("Authorization", authHeader());

      expect(response.status).toBe(200);
      expect(response.body.name).toBe("Mock Tournament List Event");
    });
  });

  describe("QR-code Manual Payment Confirmation & Event Patch Path", () => {
    const manualEventId = "e-manual-111";
    const manualRegId = "r-manual-222";
    const organizerId = "organizer-id-123";
    const randomOrganizerId = "random-organizer-id-456";
    const athleteUserId = "user-athlete-789";

    beforeEach(() => {
      // Seed user roles in mock store
      testDbStore.users.push(
        { id: organizerId, role: UserRole.PROVINCIAL_DIRECTOR },
        { id: randomOrganizerId, role: UserRole.PROVINCIAL_DIRECTOR },
        { id: athleteUserId, role: UserRole.ATHLETE }
      );

      // Seed mock manual payment event
      testDbStore.events.push({
        id: manualEventId,
        name: "Manual Payment Tournament",
        startDate: new Date("2026-09-01"),
        endDate: new Date("2026-09-02"),
        registrationStart: new Date("2026-08-01"),
        registrationEnd: new Date("2026-08-15"),
        province: "Ontario",
        city: "Ottawa",
        venue: "Community Hall",
        capacity: 100,
        status: "PUBLISHED",
        registrationFeeCents: 5000,
        paymentMethod: "MANUAL_QR",
        paymentQrImageUrl: null,
        organizerId: organizerId,
      });

      // Seed registration awaiting payment
      testDbStore.eventRegistrations.push({
        id: manualRegId,
        eventId: manualEventId,
        athleteId: UUID_ATHLETE_A,
        division: "SENIOR",
        weightClass: "80KG",
        arm: "RIGHT",
        status: "PENDING_PAYMENT",
        paymentConfirmedByOrganizer: false,
        paymentConfirmedAt: null,
      });

      // Clear mock audit log
      testDbStore.auditLogs = [];
      testDbStore.auditEvents = [];
    });

    describe("PATCH /events/:id", () => {
      it("should reject setting paymentQrImageUrl by a non-organizer/non-admin athlete", async () => {
        const res = await request(app)
          .patch(`/tournaments/events/${manualEventId}`)
          .send({ paymentQrImageUrl: "http://storage/qr.png" })
          .set("Authorization", authHeader(UserRole.ATHLETE, athleteUserId));

        expect(res.status).toBe(403);
      });

      it("should reject setting paymentQrImageUrl by a random different organizer", async () => {
        const res = await request(app)
          .patch(`/tournaments/events/${manualEventId}`)
          .send({ paymentQrImageUrl: "http://storage/qr.png" })
          .set("Authorization", authHeader(UserRole.PROVINCIAL_DIRECTOR, randomOrganizerId));

        expect(res.status).toBe(403);
      });

      it("should allow the actual event organizer to set paymentQrImageUrl and paymentMethod", async () => {
        const res = await request(app)
          .patch(`/tournaments/events/${manualEventId}`)
          .send({ paymentQrImageUrl: "http://storage/qr.png" })
          .set("Authorization", authHeader(UserRole.PROVINCIAL_DIRECTOR, organizerId));

        expect(res.status).toBe(200);
        expect(res.body.paymentQrImageUrl).toBe("http://storage/qr.png");
      });

      it("should allow a system admin to set paymentQrImageUrl and paymentMethod", async () => {
        const res = await request(app)
          .patch(`/tournaments/events/${manualEventId}`)
          .send({ paymentQrImageUrl: "http://storage/admin-qr.png" })
          .set("Authorization", authHeader(UserRole.SYSTEM_ADMIN));

        expect(res.status).toBe(200);
        expect(res.body.paymentQrImageUrl).toBe("http://storage/admin-qr.png");
      });
    });

    describe("POST /registrations/:id/confirm-manual-payment", () => {
      it("should reject manual payment confirmation by the athlete themselves", async () => {
        const res = await request(app)
          .post(`/tournaments/registrations/${manualRegId}/confirm-manual-payment`)
          .set("Authorization", authHeader(UserRole.ATHLETE, athleteUserId));

        expect(res.status).toBe(403);
      });

      it("should reject manual payment confirmation by a random different organizer", async () => {
        const res = await request(app)
          .post(`/tournaments/registrations/${manualRegId}/confirm-manual-payment`)
          .set("Authorization", authHeader(UserRole.PROVINCIAL_DIRECTOR, randomOrganizerId));

        expect(res.status).toBe(403);
      });

      it("should allow the actual organizer to confirm manual payment, transitioning status and creating audit log entry", async () => {
        const res = await request(app)
          .post(`/tournaments/registrations/${manualRegId}/confirm-manual-payment`)
          .set("Authorization", authHeader(UserRole.PROVINCIAL_DIRECTOR, organizerId));

        expect(res.status).toBe(200);
        expect(res.body.status).toBe("PENDING");
        expect(res.body.paymentConfirmedByOrganizer).toBe(true);
        expect(res.body.paymentConfirmedAt).toBeDefined();

        // Check registration in the store
        const updatedInStore = testDbStore.eventRegistrations.find(r => r.id === manualRegId);
        expect(updatedInStore?.status).toBe("PENDING");
        expect(updatedInStore?.paymentConfirmedByOrganizer).toBe(true);

        // Check cryptographic audit ledger entry
        const auditEntries = testDbStore.auditEvents;
        expect(auditEntries.length).toBe(1);
        expect(auditEntries[0].action).toBe("MANUAL_PAYMENT_CONFIRMATION");
        expect(auditEntries[0].entityId).toBe(manualRegId);
        expect(auditEntries[0].actorId).toBe(organizerId);
      });

      it("should allow a system admin to confirm manual payment, transitioning status and creating audit log entry", async () => {
        const res = await request(app)
          .post(`/tournaments/registrations/${manualRegId}/confirm-manual-payment`)
          .set("Authorization", authHeader(UserRole.SYSTEM_ADMIN));

        expect(res.status).toBe(200);
        expect(res.body.status).toBe("PENDING");

        // Check cryptographic audit ledger entry
        const auditEntries = testDbStore.auditEvents;
        expect(auditEntries.length).toBe(1);
        expect(auditEntries[0].action).toBe("MANUAL_PAYMENT_CONFIRMATION");
        expect(auditEntries[0].entityId).toBe(manualRegId);
        expect(auditEntries[0].actorId).toBe("00000000-0000-0000-0000-000000000099"); // admin's default id
      });
    });

    describe("Double Elimination Bracket Generation and Progression Engine", () => {
      beforeEach(() => {
        testDbStore.brackets = [];
        testDbStore.bracketSeeds = [];
        testDbStore.tournamentMatches = [];
      });

      // Real match IDs are now genuine UUIDs (generated via crypto.randomUUID()),
      // not predictable strings, since they're inserted into a Postgres `uuid`
      // column — a non-UUID string would be rejected by a real database even
      // though this in-memory mock wouldn't have caught that. Look matches up
      // by their structural identity instead.
      const BRACKET_TYPE_BY_PREFIX: Record<string, string> = { wb: "PRIMARY", lb: "LOSERS", gf: "GRAND_FINAL" };
      const findMatch = (bracketId: string, prefix: "wb" | "lb" | "gf", round: number, matchIndex: number) =>
        testDbStore.tournamentMatches.find(
          (m) =>
            m.bracketId === bracketId &&
            m.bracketType === BRACKET_TYPE_BY_PREFIX[prefix] &&
            m.round === round &&
            m.matchIndex === matchIndex
        );

      it("should generate proper 4-player double elimination structure with Winners, Losers, and Grand Final matches", async () => {
        // Seed Bracket
        const bracketId = "de-bracket-4";
        testDbStore.brackets.push({
          id: bracketId,
          eventId: "event-1",
          name: "DE 4-Player Bracket",
          format: "DOUBLE_ELIMINATION",
          status: "DRAFT",
          seedingLocked: true,
          createdAt: new Date(),
          updatedAt: new Date(),
        });

        // Seed 4 Athletes
        testDbStore.bracketSeeds.push(
          { id: "s-1", bracketId, athleteId: "ath-1", seedPosition: 1, isManualOverride: false },
          { id: "s-2", bracketId, athleteId: "ath-2", seedPosition: 2, isManualOverride: false },
          { id: "s-3", bracketId, athleteId: "ath-3", seedPosition: 3, isManualOverride: false },
          { id: "s-4", bracketId, athleteId: "ath-4", seedPosition: 4, isManualOverride: false }
        );

        const response = await request(app)
          .post(`/tournaments/brackets/${bracketId}/generate`)
          .set("Authorization", authHeader(UserRole.PROVINCIAL_DIRECTOR));

        expect(response.status).toBe(200);

        // For N=4:
        // WB Round 1: 2 matches (wb-de-bracket-4-1-1 and wb-de-bracket-4-1-2)
        // WB Round 2: 1 match (wb-de-bracket-4-2-1)
        // LB Round 1: 1 match (lb-de-bracket-4-1-1)
        // LB Round 2: 1 match (lb-de-bracket-4-2-1)
        // GF Round 1: 1 match (gf-de-bracket-4-1-1)
        // GF Round 2: 1 match (gf-de-bracket-4-2-1)
        // Total = 2 + 1 + 1 + 1 + 2 = 7 matches
        expect(testDbStore.tournamentMatches).toHaveLength(7);

        const wb1_1 = findMatch(bracketId, "wb", 1, 1);
        const wb1_2 = findMatch(bracketId, "wb", 1, 2);
        expect(wb1_1).toBeDefined();
        expect(wb1_2).toBeDefined();

        expect(wb1_1.athleteAId).toBe("ath-1");
        expect(wb1_1.athleteBId).toBe("ath-4");
        expect(wb1_1.status).toBe("READY");

        expect(wb1_2.athleteAId).toBe("ath-2");
        expect(wb1_2.athleteBId).toBe("ath-3");
        expect(wb1_2.status).toBe("READY");
      });

      it("should handle odd participant count (3 athletes) and propagate byes correctly in 4-player double elimination", async () => {
        const bracketId = "de-bracket-bye";
        testDbStore.brackets.push({
          id: bracketId,
          eventId: "event-1",
          name: "DE 3-Player Bracket",
          format: "DOUBLE_ELIMINATION",
          status: "DRAFT",
          seedingLocked: true,
          createdAt: new Date(),
          updatedAt: new Date(),
        });

        // 3 athletes, so position 4 is null (BYE)
        testDbStore.bracketSeeds.push(
          { id: "s-1", bracketId, athleteId: "ath-1", seedPosition: 1, isManualOverride: false },
          { id: "s-2", bracketId, athleteId: "ath-2", seedPosition: 2, isManualOverride: false },
          { id: "s-3", bracketId, athleteId: "ath-3", seedPosition: 3, isManualOverride: false }
        );

        const response = await request(app)
          .post(`/tournaments/brackets/${bracketId}/generate`)
          .set("Authorization", authHeader(UserRole.PROVINCIAL_DIRECTOR));

        expect(response.status).toBe(200);

        // wb-1-1 is ath-1 vs BYE (athleteBId is null). So status is BYE, winnerId is ath-1.
        const wb1_1 = findMatch(bracketId, "wb", 1, 1);
        expect(wb1_1.status).toBe("BYE");
        expect(wb1_1.winnerId).toBe("ath-1");

        // The bye winner should have been propagated to wb-2-1 athleteAId!
        const wb2_1 = findMatch(bracketId, "wb", 2, 1);
        expect(wb2_1.athleteAId).toBe("ath-1");

        // Since wb-1-1 was a BYE, no loser drops to losers bracket. So lb-1-1 (which is WB R1 losers)
        // has no athleteAId. Since only 1 loser exists (from wb-1-2), lb-1-1 has only 1 participant,
        // so it should automatically be resolved as a BYE for that loser, propagating them to lb-2-1!
        const lb1_1 = findMatch(bracketId, "lb", 1, 1);
        expect(lb1_1.status).toBe("BYE");
      });

      it("should progress winner to nextWinners and loser to losers bracket, then progress winners through grand final", async () => {
        const bracketId = "de-bracket-prog";
        testDbStore.brackets.push({
          id: bracketId,
          eventId: "event-1",
          name: "DE Progression",
          format: "DOUBLE_ELIMINATION",
          status: "DRAFT",
          seedingLocked: true,
          createdAt: new Date(),
          updatedAt: new Date(),
        });

        testDbStore.bracketSeeds.push(
          { id: "s-1", bracketId, athleteId: "ath-1", seedPosition: 1, isManualOverride: false },
          { id: "s-2", bracketId, athleteId: "ath-2", seedPosition: 2, isManualOverride: false },
          { id: "s-3", bracketId, athleteId: "ath-3", seedPosition: 3, isManualOverride: false },
          { id: "s-4", bracketId, athleteId: "ath-4", seedPosition: 4, isManualOverride: false }
        );

        await request(app)
          .post(`/tournaments/brackets/${bracketId}/generate`)
          .set("Authorization", authHeader(UserRole.PROVINCIAL_DIRECTOR));

        // Submit WB R1-1: ath-1 beats ath-4
        let res = await request(app)
          .post("/tournaments/matches/result")
          .set("Authorization", authHeader(UserRole.PROVINCIAL_DIRECTOR))
          .send({ matchId: findMatch(bracketId, "wb", 1, 1)!.id, winnerId: "ath-1", scoreLine: "3-0" });
        if (res.status !== 200) {
          console.error("DEBUG SUBMIT ERROR:", JSON.stringify(res.body, null, 2));
        }
        expect(res.status).toBe(200);

        // Submit WB R1-2: ath-2 beats ath-3
        res = await request(app)
          .post("/tournaments/matches/result")
          .set("Authorization", authHeader(UserRole.PROVINCIAL_DIRECTOR))
          .send({ matchId: findMatch(bracketId, "wb", 1, 2)!.id, winnerId: "ath-2", scoreLine: "3-1" });
        expect(res.status).toBe(200);

        // Verify Winners Final (wb-2-1) is READY with ath-1 vs ath-2
        const wb2_1 = findMatch(bracketId, "wb", 2, 1);
        expect(wb2_1.status).toBe("READY");
        expect(wb2_1.athleteAId).toBe("ath-1");
        expect(wb2_1.athleteBId).toBe("ath-2");

        // Verify Losers Round 1 (lb-1-1) has the two losers (ath-4 vs ath-3) and is READY
        const lb1_1 = findMatch(bracketId, "lb", 1, 1);
        expect(lb1_1.status).toBe("READY");
        expect(lb1_1.athleteAId).toBe("ath-4");
        expect(lb1_1.athleteBId).toBe("ath-3");

        // Play Losers Round 1: ath-3 beats ath-4
        res = await request(app)
          .post("/tournaments/matches/result")
          .set("Authorization", authHeader(UserRole.PROVINCIAL_DIRECTOR))
          .send({ matchId: findMatch(bracketId, "lb", 1, 1)!.id, winnerId: "ath-3", scoreLine: "3-2" });
        expect(res.status).toBe(200);

        // Play Winners Final: ath-1 beats ath-2 (ath-1 goes to GF-1, ath-2 drops to LB R2)
        res = await request(app)
          .post("/tournaments/matches/result")
          .set("Authorization", authHeader(UserRole.PROVINCIAL_DIRECTOR))
          .send({ matchId: findMatch(bracketId, "wb", 2, 1)!.id, winnerId: "ath-1", scoreLine: "3-0" });
        expect(res.status).toBe(200);

        // Verify Losers Final (lb-2-1) has ath-3 (winner of lb-1-1) vs ath-2 (loser of Winners Final)
        const lb2_1 = findMatch(bracketId, "lb", 2, 1);
        expect(lb2_1.status).toBe("READY");
        expect(lb2_1.athleteAId).toBe("ath-3");
        expect(lb2_1.athleteBId).toBe("ath-2");

        // Play Losers Final: ath-2 beats ath-3
        res = await request(app)
          .post("/tournaments/matches/result")
          .set("Authorization", authHeader(UserRole.PROVINCIAL_DIRECTOR))
          .send({ matchId: findMatch(bracketId, "lb", 2, 1)!.id, winnerId: "ath-2", scoreLine: "3-1" });
        expect(res.status).toBe(200);

        // Verify Grand Final (gf-1-1) has ath-1 (Winners Winner) vs ath-2 (Losers Winner)
        const gf1_1 = findMatch(bracketId, "gf", 1, 1);
        expect(gf1_1.status).toBe("READY");
        expect(gf1_1.athleteAId).toBe("ath-1");
        expect(gf1_1.athleteBId).toBe("ath-2");

        // Play Grand Final: Loser's Winner ath-2 wins! This triggers a rematch (bracket reset)
        res = await request(app)
          .post("/tournaments/matches/result")
          .set("Authorization", authHeader(UserRole.PROVINCIAL_DIRECTOR))
          .send({ matchId: findMatch(bracketId, "gf", 1, 1)!.id, winnerId: "ath-2", scoreLine: "3-2" });
        expect(res.status).toBe(200);

        // Verify Grand Final Round 2 is now READY with both athletes
        const gf2_1 = findMatch(bracketId, "gf", 2, 1);
        expect(gf2_1.status).toBe("READY");
        expect(gf2_1.athleteAId).toBe("ath-1");
        expect(gf2_1.athleteBId).toBe("ath-2");

        // Play GF Round 2: ath-1 wins and becomes ultimate champion!
        res = await request(app)
          .post("/tournaments/matches/result")
          .set("Authorization", authHeader(UserRole.PROVINCIAL_DIRECTOR))
          .send({ matchId: findMatch(bracketId, "gf", 2, 1)!.id, winnerId: "ath-1", scoreLine: "3-1" });
        expect(res.status).toBe(200);

        // Bracket status should be COMPLETED
        const updatedBracket = testDbStore.brackets.find(b => b.id === bracketId);
        expect(updatedBracket?.status).toBe("COMPLETED");
      });

      it("should generate proper 8-player double elimination structure and process full progression", async () => {
        const bracketId = "de-bracket-8";
        testDbStore.brackets.push({
          id: bracketId,
          eventId: "event-1",
          name: "DE 8-Player Bracket",
          format: "DOUBLE_ELIMINATION",
          status: "DRAFT",
          seedingLocked: true,
          createdAt: new Date(),
          updatedAt: new Date(),
        });

        // Seed 8 Athletes
        testDbStore.bracketSeeds.push(
          { id: "s-1", bracketId, athleteId: "ath-1", seedPosition: 1, isManualOverride: false },
          { id: "s-2", bracketId, athleteId: "ath-2", seedPosition: 2, isManualOverride: false },
          { id: "s-3", bracketId, athleteId: "ath-3", seedPosition: 3, isManualOverride: false },
          { id: "s-4", bracketId, athleteId: "ath-4", seedPosition: 4, isManualOverride: false },
          { id: "s-5", bracketId, athleteId: "ath-5", seedPosition: 5, isManualOverride: false },
          { id: "s-6", bracketId, athleteId: "ath-6", seedPosition: 6, isManualOverride: false },
          { id: "s-7", bracketId, athleteId: "ath-7", seedPosition: 7, isManualOverride: false },
          { id: "s-8", bracketId, athleteId: "ath-8", seedPosition: 8, isManualOverride: false }
        );

        const response = await request(app)
          .post(`/tournaments/brackets/${bracketId}/generate`)
          .set("Authorization", authHeader(UserRole.PROVINCIAL_DIRECTOR));

        expect(response.status).toBe(200);

        // 8-Player DE bracket contains exactly 15 matches
        expect(testDbStore.tournamentMatches).toHaveLength(15);

        // Play WB Round 1:
        // wb-1-1: ath-1 beats ath-8 (ath-8 drops to lb-1-1 A)
        let res = await request(app)
          .post("/tournaments/matches/result")
          .set("Authorization", authHeader(UserRole.PROVINCIAL_DIRECTOR))
          .send({ matchId: findMatch(bracketId, "wb", 1, 1)!.id, winnerId: "ath-1", scoreLine: "3-0" });
        expect(res.status).toBe(200);

        // wb-1-2: ath-2 beats ath-7 (ath-7 drops to lb-1-1 B)
        res = await request(app)
          .post("/tournaments/matches/result")
          .set("Authorization", authHeader(UserRole.PROVINCIAL_DIRECTOR))
          .send({ matchId: findMatch(bracketId, "wb", 1, 2)!.id, winnerId: "ath-2", scoreLine: "3-1" });
        expect(res.status).toBe(200);

        // wb-1-3: ath-3 beats ath-6 (ath-6 drops to lb-1-2 A)
        res = await request(app)
          .post("/tournaments/matches/result")
          .set("Authorization", authHeader(UserRole.PROVINCIAL_DIRECTOR))
          .send({ matchId: findMatch(bracketId, "wb", 1, 3)!.id, winnerId: "ath-3", scoreLine: "3-1" });
        expect(res.status).toBe(200);

        // wb-1-4: ath-4 beats ath-5 (ath-5 drops to lb-1-2 B)
        res = await request(app)
          .post("/tournaments/matches/result")
          .set("Authorization", authHeader(UserRole.PROVINCIAL_DIRECTOR))
          .send({ matchId: findMatch(bracketId, "wb", 1, 4)!.id, winnerId: "ath-4", scoreLine: "3-2" });
        expect(res.status).toBe(200);

        // Verify LB Round 1 matches are READY and populated with the correct losers
        const lb1_1 = findMatch(bracketId, "lb", 1, 1);
        const lb1_2 = findMatch(bracketId, "lb", 1, 2);
        expect(lb1_1?.status).toBe("READY");
        expect(lb1_1?.athleteAId).toBe("ath-8");
        expect(lb1_1?.athleteBId).toBe("ath-7");
        expect(lb1_2?.status).toBe("READY");
        expect(lb1_2?.athleteAId).toBe("ath-6");
        expect(lb1_2?.athleteBId).toBe("ath-5");

        // Play WB Round 2:
        // wb-2-1: ath-1 beats ath-2 (ath-2 drops to lb-2-1 B)
        res = await request(app)
          .post("/tournaments/matches/result")
          .set("Authorization", authHeader(UserRole.PROVINCIAL_DIRECTOR))
          .send({ matchId: findMatch(bracketId, "wb", 2, 1)!.id, winnerId: "ath-1", scoreLine: "3-0" });
        expect(res.status).toBe(200);

        // wb-2-2: ath-3 beats ath-4 (ath-4 drops to lb-2-2 B)
        res = await request(app)
          .post("/tournaments/matches/result")
          .set("Authorization", authHeader(UserRole.PROVINCIAL_DIRECTOR))
          .send({ matchId: findMatch(bracketId, "wb", 2, 2)!.id, winnerId: "ath-3", scoreLine: "3-1" });
        expect(res.status).toBe(200);

        // Play LB Round 1:
        // lb-1-1: ath-8 beats ath-7 (ath-7 eliminated, ath-8 goes to lb-2-1 A)
        res = await request(app)
          .post("/tournaments/matches/result")
          .set("Authorization", authHeader(UserRole.PROVINCIAL_DIRECTOR))
          .send({ matchId: findMatch(bracketId, "lb", 1, 1)!.id, winnerId: "ath-8", scoreLine: "3-1" });
        expect(res.status).toBe(200);

        // lb-1-2: ath-6 beats ath-5 (ath-5 eliminated, ath-6 goes to lb-2-2 A)
        res = await request(app)
          .post("/tournaments/matches/result")
          .set("Authorization", authHeader(UserRole.PROVINCIAL_DIRECTOR))
          .send({ matchId: findMatch(bracketId, "lb", 1, 2)!.id, winnerId: "ath-6", scoreLine: "3-1" });
        expect(res.status).toBe(200);

        // Verify LB Round 2 matches are READY and populated
        const lb2_1 = findMatch(bracketId, "lb", 2, 1);
        const lb2_2 = findMatch(bracketId, "lb", 2, 2);
        expect(lb2_1?.status).toBe("READY");
        expect(lb2_1?.athleteAId).toBe("ath-8");
        expect(lb2_1?.athleteBId).toBe("ath-2");
        expect(lb2_2?.status).toBe("READY");
        expect(lb2_2?.athleteAId).toBe("ath-6");
        expect(lb2_2?.athleteBId).toBe("ath-4");

        // Play WB Round 3 (Winners Bracket Final):
        // wb-3-1: ath-1 beats ath-3 (ath-1 goes to GF Slot A, ath-3 drops to lb-4-1 B)
        res = await request(app)
          .post("/tournaments/matches/result")
          .set("Authorization", authHeader(UserRole.PROVINCIAL_DIRECTOR))
          .send({ matchId: findMatch(bracketId, "wb", 3, 1)!.id, winnerId: "ath-1", scoreLine: "3-0" });
        expect(res.status).toBe(200);

        // Play LB Round 2:
        // lb-2-1: ath-2 beats ath-8 (ath-8 eliminated, ath-2 goes to lb-3-1 A)
        res = await request(app)
          .post("/tournaments/matches/result")
          .set("Authorization", authHeader(UserRole.PROVINCIAL_DIRECTOR))
          .send({ matchId: findMatch(bracketId, "lb", 2, 1)!.id, winnerId: "ath-2", scoreLine: "3-1" });
        expect(res.status).toBe(200);

        // lb-2-2: ath-4 beats ath-6 (ath-6 eliminated, ath-4 goes to lb-3-1 B)
        res = await request(app)
          .post("/tournaments/matches/result")
          .set("Authorization", authHeader(UserRole.PROVINCIAL_DIRECTOR))
          .send({ matchId: findMatch(bracketId, "lb", 2, 2)!.id, winnerId: "ath-4", scoreLine: "3-2" });
        expect(res.status).toBe(200);

        // Verify LB Round 3 is READY and populated
        const lb3_1 = findMatch(bracketId, "lb", 3, 1);
        expect(lb3_1?.status).toBe("READY");
        expect(lb3_1?.athleteAId).toBe("ath-2");
        expect(lb3_1?.athleteBId).toBe("ath-4");

        // Play LB Round 3:
        // lb-3-1: ath-2 beats ath-4 (ath-4 eliminated, ath-2 goes to lb-4-1 A)
        res = await request(app)
          .post("/tournaments/matches/result")
          .set("Authorization", authHeader(UserRole.PROVINCIAL_DIRECTOR))
          .send({ matchId: findMatch(bracketId, "lb", 3, 1)!.id, winnerId: "ath-2", scoreLine: "3-2" });
        expect(res.status).toBe(200);

        // Verify LB Round 4 (Losers Bracket Final) is READY and populated
        const lb4_1 = findMatch(bracketId, "lb", 4, 1);
        expect(lb4_1?.status).toBe("READY");
        expect(lb4_1?.athleteAId).toBe("ath-2");
        expect(lb4_1?.athleteBId).toBe("ath-3");

        // Play LB Round 4:
        // lb-4-1: ath-2 beats ath-3 (ath-3 eliminated, ath-2 goes to GF Slot B)
        res = await request(app)
          .post("/tournaments/matches/result")
          .set("Authorization", authHeader(UserRole.PROVINCIAL_DIRECTOR))
          .send({ matchId: findMatch(bracketId, "lb", 4, 1)!.id, winnerId: "ath-2", scoreLine: "3-1" });
        expect(res.status).toBe(200);

        // Verify Grand Final Round 1 is READY and populated
        const gf1_1 = findMatch(bracketId, "gf", 1, 1);
        expect(gf1_1?.status).toBe("READY");
        expect(gf1_1?.athleteAId).toBe("ath-1");
        expect(gf1_1?.athleteBId).toBe("ath-2");

        // Play Grand Final Round 1:
        // gf-1-1: ath-2 beats ath-1 (rematch required, both now have exactly 1 loss)
        res = await request(app)
          .post("/tournaments/matches/result")
          .set("Authorization", authHeader(UserRole.PROVINCIAL_DIRECTOR))
          .send({ matchId: findMatch(bracketId, "gf", 1, 1)!.id, winnerId: "ath-2", scoreLine: "3-2" });
        expect(res.status).toBe(200);

        // Verify Grand Final Round 2 is READY and populated with rematch
        const gf2_1 = findMatch(bracketId, "gf", 2, 1);
        expect(gf2_1?.status).toBe("READY");
        expect(gf2_1?.athleteAId).toBe("ath-1");
        expect(gf2_1?.athleteBId).toBe("ath-2");

        // Play Grand Final Round 2:
        // gf-2-1: ath-1 beats ath-2 (ath-1 becomes ultimate champion!)
        res = await request(app)
          .post("/tournaments/matches/result")
          .set("Authorization", authHeader(UserRole.PROVINCIAL_DIRECTOR))
          .send({ matchId: findMatch(bracketId, "gf", 2, 1)!.id, winnerId: "ath-1", scoreLine: "3-1" });
        expect(res.status).toBe(200);

        // Verify tournament state completes successfully
        const finalBracket = testDbStore.brackets.find(b => b.id === bracketId);
        expect(finalBracket?.status).toBe("COMPLETED");
      });
    });
  });

  // ==========================================
  // 7. Actor Identity & Authorization Boundaries
  // ==========================================
  describe("Actor Identity & Authorization Boundaries", () => {
    const UUID_REFEREE_B = "00000000-0000-0000-0000-000000000006";
    const UUID_GHOST_USER = "99999999-9999-9999-9999-999999999999";
    const UUID_ATHLETE_USER = "00000000-0000-0000-0000-000000000008";

    beforeEach(() => {
      testDbStore.users.push(
        { id: UUID_REFEREE_B, role: UserRole.REFEREE },
        { id: UUID_ATHLETE_USER, role: UserRole.ATHLETE }
      );

      testDbStore.refereeCertifications.push(
        {
          id: "cert-ref-b",
          userId: UUID_REFEREE_B,
          certificationLevel: "PRO_LEVEL_1",
          issuedAt: new Date(),
          expiresAt: new Date(Date.now() + 86400000 * 365),
          status: "ACTIVE",
          issuingBody: "WAF_OFFICIAL"
        }
      );

      testDbStore.events.push({
        id: UUID_EVENT_ACTIVE,
        name: "Boundary Tourney",
        registrationStart: new Date(Date.now() - 1000 * 60 * 60),
        registrationEnd: new Date(Date.now() + 1000 * 60 * 60),
        startDate: new Date(Date.now() + 1000 * 60 * 60 * 24),
        endDate: new Date(Date.now() + 1000 * 60 * 60 * 48),
        province: "Ontario",
        city: "Toronto",
        venue: "Stadium",
        capacity: 10,
        status: "PUBLISHED"
      });

      testDbStore.eventRegistrations.push({
        id: UUID_REG_ACTIVE,
        eventId: UUID_EVENT_ACTIVE,
        athleteId: UUID_ATHLETE_A,
        division: "SENIOR",
        weightClass: "70KG",
        arm: "RIGHT",
        status: "PENDING"
      });

      testDbStore.matchTables.push({
        id: UUID_TABLE,
        name: "Table Boundary",
        status: "IDLE",
        currentMatchId: null
      });

      testDbStore.tournamentMatches.push({
        id: UUID_MATCH_ONE,
        bracketId: UUID_BRACKET,
        round: 1,
        matchIndex: 1,
        bracketType: "PRIMARY",
        athleteAId: UUID_ATHLETE_A,
        athleteBId: UUID_ATHLETE_C,
        status: "READY",
        tableId: null,
        refereeId: null,
        nextMatchId: null,
        nextMatchPlayerPosition: null
      });
    });

    it("should attribute registration approval to the JWT identity, not a spoofable body field", async () => {
      const response = await request(app)
        .post(`/tournaments/registrations/${UUID_REG_ACTIVE}/approve`)
        .send({ reviewerId: UUID_REFEREE })
        .set("Authorization", authHeader(UserRole.PROVINCIAL_DIRECTOR, UUID_DIRECTOR));

      expect(response.status).toBe(200);
      expect(response.body.status).toBe("APPROVED");
      expect(response.body.approvedBy).toBe(UUID_DIRECTOR);
      expect(response.body.approvedBy).not.toBe(UUID_REFEREE);
    });

    it("should attribute weigh-in certification to the JWT identity, ignoring client-supplied certifier", async () => {
      const response = await request(app)
        .post("/tournaments/weighins")
        .send({
          registrationId: UUID_REG_ACTIVE,
          weight: 68.5,
          certifiedBy: UUID_REFEREE_B
        })
        .set("Authorization", authHeader(UserRole.REFEREE, UUID_REFEREE));

      expect(response.status).toBe(201);
      expect(testDbStore.officialWeighins[0].certifiedBy).toBe(UUID_REFEREE);
      expect(testDbStore.auditLogs[0].userId).toBe(UUID_REFEREE);

      const auditEntry = testDbStore.auditLogs[0];
      expect(auditEntry.ipAddress).toBeUndefined();
      expect(auditEntry.userAgent).toBeUndefined();
    });

    it("should reject an uncertified referee recording a weigh-in even if the body claims a certified actor", async () => {
      const uncertifiedRef = "00000000-0000-0000-0000-000000000007";
      testDbStore.users.push({ id: uncertifiedRef, role: UserRole.REFEREE });

      const response = await request(app)
        .post("/tournaments/weighins")
        .send({
          registrationId: UUID_REG_ACTIVE,
          weight: 68.5,
          certifiedBy: UUID_REFEREE
        })
        .set("Authorization", authHeader(UserRole.REFEREE, uncertifiedRef));

      expect(response.status).toBe(403);
    });

    it("should reject assigning a non-existent user as match referee", async () => {
      const response = await request(app)
        .post("/tournaments/matches/referee")
        .send({ matchId: UUID_MATCH_ONE, refereeId: UUID_GHOST_USER })
        .set("Authorization", authHeader(UserRole.PROVINCIAL_DIRECTOR, UUID_DIRECTOR));

      expect(response.status).toBe(404);
      expect(testDbStore.tournamentMatches[0].refereeId).toBeNull();
    });

    it("should reject assigning a user without a referee or director role", async () => {
      const response = await request(app)
        .post("/tournaments/matches/referee")
        .send({ matchId: UUID_MATCH_ONE, refereeId: UUID_ATHLETE_USER })
        .set("Authorization", authHeader(UserRole.PROVINCIAL_DIRECTOR, UUID_DIRECTOR));

      expect(response.status).toBe(400);
      expect(testDbStore.tournamentMatches[0].refereeId).toBeNull();
    });

    it("should enforce that only the assigned referee or a director can submit match results", async () => {
      const assignResponse = await request(app)
        .post("/tournaments/matches/referee")
        .send({ matchId: UUID_MATCH_ONE, refereeId: UUID_REFEREE })
        .set("Authorization", authHeader(UserRole.PROVINCIAL_DIRECTOR, UUID_DIRECTOR));
      expect(assignResponse.status).toBe(200);

      const intruderResponse = await request(app)
        .post("/tournaments/matches/result")
        .send({ matchId: UUID_MATCH_ONE, winnerId: UUID_ATHLETE_A, scoreLine: "3-0" })
        .set("Authorization", authHeader(UserRole.REFEREE, UUID_REFEREE_B));
      expect(intruderResponse.status).toBe(403);
      expect(testDbStore.tournamentMatches[0].status).toBe("READY");
      expect(testDbStore.tournamentMatches[0].winnerId).toBeUndefined();

      const assignedResponse = await request(app)
        .post("/tournaments/matches/result")
        .send({ matchId: UUID_MATCH_ONE, winnerId: UUID_ATHLETE_A, scoreLine: "3-0" })
        .set("Authorization", authHeader(UserRole.REFEREE, UUID_REFEREE));
      expect(assignedResponse.status).toBe(200);
      expect(testDbStore.tournamentMatches[0].status).toBe("COMPLETED");
      expect(testDbStore.tournamentMatches[0].winnerId).toBe(UUID_ATHLETE_A);
    });
  });
});
