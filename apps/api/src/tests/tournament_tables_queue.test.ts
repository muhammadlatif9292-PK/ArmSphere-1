import { describe, it, expect, beforeEach } from "vitest";
import request from "supertest";
import { testDbStore } from "./setup.js";
import { app } from "../app.js";
import { generateAccessToken } from "@armsphere/cryptography";
import { UserRole } from "@armsphere/types";
import env from "../config/env.js";

// RFC-compliant test UUIDs
const UUID_EVENT_A = "11111111-aaaa-aaaa-aaaa-111111111111";
const UUID_EVENT_B = "22222222-bbbb-bbbb-bbbb-222222222222";

const UUID_BRACKET_A = "33333333-aaaa-aaaa-aaaa-111111111111";
const UUID_BRACKET_B = "33333333-bbbb-bbbb-bbbb-222222222222";

const UUID_TABLE_A1 = "55555555-aaaa-aaaa-aaaa-111111111111";
const UUID_TABLE_A2 = "55555555-aaaa-aaaa-aaaa-222222222222";
const UUID_TABLE_B1 = "55555555-bbbb-bbbb-bbbb-111111111111";

const UUID_MATCH_A1 = "44444444-aaaa-aaaa-aaaa-111111111111";
const UUID_MATCH_A2 = "44444444-aaaa-aaaa-aaaa-222222222222";
const UUID_MATCH_A3 = "44444444-aaaa-aaaa-aaaa-333333333333";
const UUID_MATCH_A_PENDING = "44444444-aaaa-aaaa-aaaa-444444444444";
const UUID_MATCH_B1 = "44444444-bbbb-bbbb-bbbb-111111111111";

const UUID_ATHLETE_1 = "00000000-0000-0000-0000-000000000001";
const UUID_ATHLETE_2 = "00000000-0000-0000-0000-000000000002";
const UUID_ATHLETE_3 = "00000000-0000-0000-0000-000000000003";
const UUID_ATHLETE_4 = "00000000-0000-0000-0000-000000000004";

const UUID_DIRECTOR = "00000000-0000-0000-0000-000000000010";
const UUID_REFEREE = "00000000-0000-0000-0000-000000000020";
const UUID_ATHLETE_USER = "00000000-0000-0000-0000-000000000030";

function authHeader(role: UserRole = UserRole.ATHLETE, userId?: string) {
  let defaultUserId = UUID_ATHLETE_USER;
  if (role === UserRole.REFEREE) {
    defaultUserId = UUID_REFEREE;
  } else if (role === UserRole.PROVINCIAL_DIRECTOR) {
    defaultUserId = UUID_DIRECTOR;
  }
  const token = generateAccessToken(userId || defaultUserId, "test@armsphere.com", role, env.JWT_ACCESS_SECRET);
  return `Bearer ${token}`;
}

describe("Phase 2.2: Live Arena Tables & Queue Operations", () => {
  beforeEach(() => {
    // Seed users
    testDbStore.users = [
      { id: UUID_DIRECTOR, role: UserRole.PROVINCIAL_DIRECTOR, province: "Ontario", regionalCoverage: "Ontario" },
      { id: UUID_REFEREE, role: UserRole.REFEREE },
      { id: UUID_ATHLETE_USER, role: UserRole.ATHLETE }
    ];

    // Seed referee certification
    testDbStore.refereeCertifications = [
      {
        id: "cert-ref-1",
        userId: UUID_REFEREE,
        certificationLevel: "PRO_LEVEL_1",
        issuedAt: new Date(),
        expiresAt: new Date(Date.now() + 86400000 * 365),
        status: "ACTIVE",
        issuingBody: "WAF_OFFICIAL"
      }
    ];

    // Seed athlete profiles
    testDbStore.athleteProfiles = [
      { id: UUID_ATHLETE_1, userId: "u-1", displayName: "Devon Larratt", gender: "MALE" },
      { id: UUID_ATHLETE_2, userId: "u-2", displayName: "Denis Cyplenkov", gender: "MALE" },
      { id: UUID_ATHLETE_3, userId: "u-3", displayName: "John Brzenk", gender: "MALE" },
      { id: UUID_ATHLETE_4, userId: "u-4", displayName: "Levan Saginashvili", gender: "MALE" }
    ];

    // Seed Events
    testDbStore.events = [
      {
        id: UUID_EVENT_A,
        name: "National Armwrestling Championship",
        status: "ACTIVE",
        organizerId: UUID_DIRECTOR
      },
      {
        id: UUID_EVENT_B,
        name: "Provincial Open Qualifier",
        status: "ACTIVE",
        organizerId: UUID_DIRECTOR
      }
    ];

    // Seed Brackets
    testDbStore.brackets = [
      {
        id: UUID_BRACKET_A,
        eventId: UUID_EVENT_A,
        name: "Senior Men 100KG Right",
        format: "DOUBLE_ELIMINATION",
        status: "ACTIVE"
      },
      {
        id: UUID_BRACKET_B,
        eventId: UUID_EVENT_B,
        name: "Senior Men 90KG Left",
        format: "SINGLE_ELIMINATION",
        status: "ACTIVE"
      }
    ];

    // Seed Tables
    testDbStore.matchTables = [
      {
        id: UUID_TABLE_A1,
        eventId: UUID_EVENT_A,
        name: "Table 1 (Alpha)",
        status: "IDLE",
        currentMatchId: null
      },
      {
        id: UUID_TABLE_A2,
        eventId: UUID_EVENT_A,
        name: "Table 2 (Bravo)",
        status: "IDLE",
        currentMatchId: null
      },
      {
        id: UUID_TABLE_B1,
        eventId: UUID_EVENT_B,
        name: "Table 1 (North)",
        status: "IDLE",
        currentMatchId: null
      }
    ];

    // Seed Matches
    testDbStore.tournamentMatches = [
      {
        id: UUID_MATCH_A1,
        bracketId: UUID_BRACKET_A,
        round: 1,
        matchIndex: 1,
        bracketType: "PRIMARY",
        athleteAId: UUID_ATHLETE_1,
        athleteBId: UUID_ATHLETE_2,
        status: "READY",
        tableId: null,
        refereeId: null
      },
      {
        id: UUID_MATCH_A2,
        bracketId: UUID_BRACKET_A,
        round: 1,
        matchIndex: 2,
        bracketType: "PRIMARY",
        athleteAId: UUID_ATHLETE_3,
        athleteBId: UUID_ATHLETE_4,
        status: "READY",
        tableId: null,
        refereeId: null
      },
      {
        id: UUID_MATCH_A3,
        bracketId: UUID_BRACKET_A,
        round: 1,
        matchIndex: 3,
        bracketType: "PRIMARY",
        athleteAId: UUID_ATHLETE_1,
        athleteBId: UUID_ATHLETE_3,
        status: "READY",
        tableId: null,
        refereeId: null
      },
      {
        id: UUID_MATCH_A_PENDING,
        bracketId: UUID_BRACKET_A,
        round: 2,
        matchIndex: 1,
        bracketType: "PRIMARY",
        athleteAId: UUID_ATHLETE_1,
        athleteBId: null,
        status: "PENDING",
        tableId: null,
        refereeId: null
      },
      {
        id: UUID_MATCH_B1,
        bracketId: UUID_BRACKET_B,
        round: 1,
        matchIndex: 1,
        bracketType: "PRIMARY",
        athleteAId: UUID_ATHLETE_2,
        athleteBId: UUID_ATHLETE_4,
        status: "READY",
        tableId: null,
        refereeId: null
      }
    ];

    // Empty queues
    testDbStore.tournamentTableQueue = [];
  });

  // =========================================================================
  // 1. Table Creation & Event Scoping
  // =========================================================================
  describe("1. Table Creation & Event Scoping", () => {
    it("should allow director to create an event-scoped table via POST /tournaments/events/:id/tables", async () => {
      const res = await request(app)
        .post(`/tournaments/events/${UUID_EVENT_A}/tables`)
        .send({ name: "Table 3 (Charlie)" })
        .set("Authorization", authHeader(UserRole.PROVINCIAL_DIRECTOR));

      expect(res.status).toBe(201);
      expect(res.body.name).toBe("Table 3 (Charlie)");
      expect(res.body.eventId).toBe(UUID_EVENT_A);
      expect(res.body.status).toBe("IDLE");
      expect(res.body.currentMatchId == null).toBe(true);
    });

    it("should reject table creation without eventId when using legacy POST /tournaments/tables", async () => {
      const res = await request(app)
        .post("/tournaments/tables")
        .send({ name: "Orphan Table" })
        .set("Authorization", authHeader(UserRole.PROVINCIAL_DIRECTOR));

      expect(res.status).toBe(400);
    });

    it("should reject table creation by unauthorized roles (ATHLETE)", async () => {
      const res = await request(app)
        .post(`/tournaments/events/${UUID_EVENT_A}/tables`)
        .send({ name: "Unauthorized Table" })
        .set("Authorization", authHeader(UserRole.ATHLETE));

      expect(res.status).toBe(403);
    });

    it("should reject unauthenticated requests to table creation", async () => {
      const res = await request(app)
        .post(`/tournaments/events/${UUID_EVENT_A}/tables`)
        .send({ name: "Anonymous Table" });

      expect(res.status).toBe(401);
    });
  });

  // =========================================================================
  // 2. Event Table Listing & Queue Retrieval
  // =========================================================================
  describe("2. Event Table Listing & Queue Retrieval", () => {
    it("should return only tables belonging to the requested event", async () => {
      const res = await request(app)
        .get(`/tournaments/events/${UUID_EVENT_A}/tables`)
        .set("Authorization", authHeader(UserRole.REFEREE));

      expect(res.status).toBe(200);
      expect(res.body).toHaveLength(2);
      expect(res.body.every((t: any) => t.eventId === UUID_EVENT_A)).toBe(true);
      expect(res.body.some((t: any) => t.id === UUID_TABLE_B1)).toBe(false);
    });

    it("should include ordered queues and enriched match details with tables", async () => {
      // Put a match in queue for Table A1
      testDbStore.tournamentTableQueue.push({
        id: "q-1",
        tableId: UUID_TABLE_A1,
        matchId: UUID_MATCH_A1,
        position: 1,
        createdAt: new Date()
      });

      const res = await request(app)
        .get(`/tournaments/events/${UUID_EVENT_A}/tables`)
        .set("Authorization", authHeader(UserRole.REFEREE));

      expect(res.status).toBe(200);
      const table1 = res.body.find((t: any) => t.id === UUID_TABLE_A1);
      expect(table1).toBeDefined();
      expect(table1.queue).toHaveLength(1);
      expect(table1.queue[0].matchId).toBe(UUID_MATCH_A1);
      expect(table1.queue[0].position).toBe(1);
      expect(table1.queue[0].athleteAName).toBe("Devon Larratt");
      expect(table1.queue[0].athleteBName).toBe("Denis Cyplenkov");
    });
  });

  // =========================================================================
  // 3. Match Calling & Atomic Table Ownership
  // =========================================================================
  describe("3. Match Calling & Atomic Table Ownership", () => {
    it("should call a READY match to an IDLE table and promote it cleanly", async () => {
      const res = await request(app)
        .post("/tournaments/matches/call")
        .send({
          matchId: UUID_MATCH_A1,
          tableId: UUID_TABLE_A1
        })
        .set("Authorization", authHeader(UserRole.REFEREE));

      expect(res.status).toBe(200);

      // Verify match state
      const match = testDbStore.tournamentMatches.find((m: any) => m.id === UUID_MATCH_A1);
      expect(match.status).toBe("CALLED");
      expect(match.tableId).toBe(UUID_TABLE_A1);

      // Verify table state
      const table = testDbStore.matchTables.find((t: any) => t.id === UUID_TABLE_A1);
      expect(table.status).toBe("ACTIVE");
      expect(table.currentMatchId).toBe(UUID_MATCH_A1);
    });

    it("should automatically remove the called match from the table queue upon being called", async () => {
      // Pre-queue match A1 on table A1
      testDbStore.tournamentTableQueue.push({
        id: "q-1",
        tableId: UUID_TABLE_A1,
        matchId: UUID_MATCH_A1,
        position: 1,
        createdAt: new Date()
      });

      const res = await request(app)
        .post("/tournaments/matches/call")
        .send({
          matchId: UUID_MATCH_A1,
          tableId: UUID_TABLE_A1
        })
        .set("Authorization", authHeader(UserRole.REFEREE));

      expect(res.status).toBe(200);
      expect(testDbStore.tournamentTableQueue.some((q: any) => q.matchId === UUID_MATCH_A1)).toBe(false);
    });

    it("should reject calling a match to an already occupied ACTIVE table with 409 Conflict", async () => {
      // Make Table A1 active with Match A1
      const tableA1 = testDbStore.matchTables.find((t: any) => t.id === UUID_TABLE_A1);
      tableA1.status = "ACTIVE";
      tableA1.currentMatchId = UUID_MATCH_A1;

      const res = await request(app)
        .post("/tournaments/matches/call")
        .send({
          matchId: UUID_MATCH_A2,
          tableId: UUID_TABLE_A1
        })
        .set("Authorization", authHeader(UserRole.REFEREE));

      expect(res.status).toBe(409);
      expect(res.body.detail || res.body.message || res.body.error).toMatch(/active with another match/i);
    });

    it("should atomically release previous table when a CALLED match is moved to a new table", async () => {
      // Initially call Match A1 to Table A1
      await request(app)
        .post("/tournaments/matches/call")
        .send({ matchId: UUID_MATCH_A1, tableId: UUID_TABLE_A1 })
        .set("Authorization", authHeader(UserRole.REFEREE));

      expect(testDbStore.matchTables.find((t: any) => t.id === UUID_TABLE_A1).status).toBe("ACTIVE");

      // Move Match A1 to Table A2
      const res = await request(app)
        .post("/tournaments/matches/call")
        .send({ matchId: UUID_MATCH_A1, tableId: UUID_TABLE_A2 })
        .set("Authorization", authHeader(UserRole.REFEREE));

      expect(res.status).toBe(200);

      // Old table must be released
      const tableOld = testDbStore.matchTables.find((t: any) => t.id === UUID_TABLE_A1);
      expect(tableOld.status).toBe("IDLE");
      expect(tableOld.currentMatchId).toBeNull();

      // New table must be active
      const tableNew = testDbStore.matchTables.find((t: any) => t.id === UUID_TABLE_A2);
      expect(tableNew.status).toBe("ACTIVE");
      expect(tableNew.currentMatchId).toBe(UUID_MATCH_A1);
    });

    it("should reject cross-event match calling with 400 Bad Request", async () => {
      // Match B1 belongs to Event B, Table A1 belongs to Event A
      const res = await request(app)
        .post("/tournaments/matches/call")
        .send({
          matchId: UUID_MATCH_B1,
          tableId: UUID_TABLE_A1
        })
        .set("Authorization", authHeader(UserRole.REFEREE));

      expect(res.status).toBe(400);
      expect(res.body.detail || res.body.message || res.body.error).toMatch(/different tournament events/i);
    });
  });

  // =========================================================================
  // 4. Safe Match Unassignment
  // =========================================================================
  describe("4. Safe Match Unassignment", () => {
    it("should safely unassign a CALLED match and restore table to IDLE", async () => {
      // Set Match A1 called to Table A1
      await request(app)
        .post("/tournaments/matches/call")
        .send({ matchId: UUID_MATCH_A1, tableId: UUID_TABLE_A1 })
        .set("Authorization", authHeader(UserRole.REFEREE));

      const res = await request(app)
        .post("/tournaments/matches/unassign")
        .send({ matchId: UUID_MATCH_A1 })
        .set("Authorization", authHeader(UserRole.REFEREE));

      expect(res.status).toBe(200);

      // Match status reverts to READY
      const match = testDbStore.tournamentMatches.find((m: any) => m.id === UUID_MATCH_A1);
      expect(match.status).toBe("READY");
      expect(match.tableId).toBeNull();

      // Table is freed
      const table = testDbStore.matchTables.find((t: any) => t.id === UUID_TABLE_A1);
      expect(table.status).toBe("IDLE");
      expect(table.currentMatchId).toBeNull();
    });

    it("should cleanly remove from queue if an unassigned match was queued", async () => {
      testDbStore.tournamentTableQueue.push({
        id: "q-1",
        tableId: UUID_TABLE_A1,
        matchId: UUID_MATCH_A1,
        position: 1,
        createdAt: new Date()
      });

      const res = await request(app)
        .post("/tournaments/matches/unassign")
        .send({ matchId: UUID_MATCH_A1 })
        .set("Authorization", authHeader(UserRole.REFEREE));

      expect(res.status).toBe(200);
      expect(testDbStore.tournamentTableQueue).toHaveLength(0);
    });

    it("should succeed as a safe no-op if the match is already unassigned and READY", async () => {
      const res = await request(app)
        .post("/tournaments/matches/unassign")
        .send({ matchId: UUID_MATCH_A1 })
        .set("Authorization", authHeader(UserRole.REFEREE));

      expect(res.status).toBe(200);
      const match = testDbStore.tournamentMatches.find((m: any) => m.id === UUID_MATCH_A1);
      expect(match.status).toBe("READY");
    });

    it("should reject unassigning a COMPLETED match with 400 Bad Request", async () => {
      const match = testDbStore.tournamentMatches.find((m: any) => m.id === UUID_MATCH_A1);
      match.status = "COMPLETED";
      match.winnerId = UUID_ATHLETE_1;

      const res = await request(app)
        .post("/tournaments/matches/unassign")
        .send({ matchId: UUID_MATCH_A1 })
        .set("Authorization", authHeader(UserRole.REFEREE));

      expect(res.status).toBe(400);
      expect(res.body.detail || res.body.message || res.body.error).toMatch(/completed/i);
    });

    it("should reject unauthorized roles (ATHLETE) from unassigning matches", async () => {
      const res = await request(app)
        .post("/tournaments/matches/unassign")
        .send({ matchId: UUID_MATCH_A1 })
        .set("Authorization", authHeader(UserRole.ATHLETE));

      expect(res.status).toBe(403);
    });
  });

  // =========================================================================
  // 5. Table Queue Management
  // =========================================================================
  describe("5. Table Queue Management", () => {
    it("should append a READY match to the queue when position is omitted", async () => {
      const res = await request(app)
        .post("/tournaments/tables/queue")
        .send({
          tableId: UUID_TABLE_A1,
          matchId: UUID_MATCH_A1
        })
        .set("Authorization", authHeader(UserRole.REFEREE));

      expect(res.status).toBe(201);
      expect(res.body.tableId).toBe(UUID_TABLE_A1);
      expect(res.body.matchId).toBe(UUID_MATCH_A1);
      expect(res.body.position).toBe(1);

      // Add second match
      const res2 = await request(app)
        .post("/tournaments/tables/queue")
        .send({
          tableId: UUID_TABLE_A1,
          matchId: UUID_MATCH_A2
        })
        .set("Authorization", authHeader(UserRole.REFEREE));

      expect(res2.status).toBe(201);
      expect(res2.body.position).toBe(2);
    });

    it("should shift subsequent queue positions when inserting at explicit position", async () => {
      // Pre-populate queue with match A1 at pos 1, match A2 at pos 2
      testDbStore.tournamentTableQueue.push(
        { id: "q-1", tableId: UUID_TABLE_A1, matchId: UUID_MATCH_A1, position: 1, createdAt: new Date() },
        { id: "q-2", tableId: UUID_TABLE_A1, matchId: UUID_MATCH_A2, position: 2, createdAt: new Date() }
      );

      // Insert Match A3 at position 1
      const res = await request(app)
        .post("/tournaments/tables/queue")
        .send({
          tableId: UUID_TABLE_A1,
          matchId: UUID_MATCH_A3,
          position: 1
        })
        .set("Authorization", authHeader(UserRole.REFEREE));

      expect(res.status).toBe(201);
      expect(res.body.position).toBe(1);

      // Check that existing items were shifted
      const q1 = testDbStore.tournamentTableQueue.find((q: any) => q.matchId === UUID_MATCH_A1);
      const q2 = testDbStore.tournamentTableQueue.find((q: any) => q.matchId === UUID_MATCH_A2);
      expect(q1.position).toBe(2);
      expect(q2.position).toBe(3);
    });

    it("should reject queuing an already CALLED match with 409 Conflict", async () => {
      const match = testDbStore.tournamentMatches.find((m: any) => m.id === UUID_MATCH_A1);
      match.status = "CALLED";

      const res = await request(app)
        .post("/tournaments/tables/queue")
        .send({ tableId: UUID_TABLE_A1, matchId: UUID_MATCH_A1 })
        .set("Authorization", authHeader(UserRole.REFEREE));

      expect(res.status).toBe(409);
      expect(res.body.detail || res.body.message || res.body.error).toMatch(/assigned/i);
    });

    it("should reject queuing a match with unassigned competitors (PENDING)", async () => {
      const res = await request(app)
        .post("/tournaments/tables/queue")
        .send({ tableId: UUID_TABLE_A1, matchId: UUID_MATCH_A_PENDING })
        .set("Authorization", authHeader(UserRole.REFEREE));

      expect(res.status).toBe(400);
      expect(res.body.detail || res.body.message || res.body.error).toMatch(/competitors/i);
    });

    it("should reject duplicate queuing of a match that is already queued with 409 Conflict", async () => {
      testDbStore.tournamentTableQueue.push({
        id: "q-1",
        tableId: UUID_TABLE_A1,
        matchId: UUID_MATCH_A1,
        position: 1,
        createdAt: new Date()
      });

      const res = await request(app)
        .post("/tournaments/tables/queue")
        .send({ tableId: UUID_TABLE_A2, matchId: UUID_MATCH_A1 })
        .set("Authorization", authHeader(UserRole.REFEREE));

      expect(res.status).toBe(409);
      expect(res.body.detail || res.body.message || res.body.error).toMatch(/already queued/i);
    });

    it("should reject cross-event queuing with 400 Bad Request", async () => {
      // Match B1 belongs to Event B, Table A1 belongs to Event A
      const res = await request(app)
        .post("/tournaments/tables/queue")
        .send({ tableId: UUID_TABLE_A1, matchId: UUID_MATCH_B1 })
        .set("Authorization", authHeader(UserRole.REFEREE));

      expect(res.status).toBe(400);
      expect(res.body.detail || res.body.message || res.body.error).toMatch(/different tournament events/i);
    });
  });

  // =========================================================================
  // 6. Queue Rebalancing
  // =========================================================================
  describe("6. Queue Rebalancing", () => {
    it("should rebalance a match from Table 1 to Table 2 and maintain contiguous positions", async () => {
      // Table A1 has Match A1 (pos 1), Match A2 (pos 2)
      // Table A2 has Match A3 (pos 1)
      testDbStore.tournamentTableQueue.push(
        { id: "q-1", tableId: UUID_TABLE_A1, matchId: UUID_MATCH_A1, position: 1, createdAt: new Date() },
        { id: "q-2", tableId: UUID_TABLE_A1, matchId: UUID_MATCH_A2, position: 2, createdAt: new Date() },
        { id: "q-3", tableId: UUID_TABLE_A2, matchId: UUID_MATCH_A3, position: 1, createdAt: new Date() }
      );

      // Rebalance Match A1 from Table A1 to Table A2 at position 1
      const res = await request(app)
        .post("/tournaments/tables/queue/rebalance")
        .send({
          matchId: UUID_MATCH_A1,
          targetTableId: UUID_TABLE_A2,
          targetPosition: 1
        })
        .set("Authorization", authHeader(UserRole.REFEREE));

      expect(res.status).toBe(200);

      // Source table (A1) should now have Match A2 re-indexed to position 1
      const qA2 = testDbStore.tournamentTableQueue.find((q: any) => q.matchId === UUID_MATCH_A2);
      expect(qA2.tableId).toBe(UUID_TABLE_A1);
      expect(qA2.position).toBe(1);

      // Target table (A2) should have Match A1 at position 1, and Match A3 shifted to position 2
      const qA1 = testDbStore.tournamentTableQueue.find((q: any) => q.matchId === UUID_MATCH_A1);
      expect(qA1.tableId).toBe(UUID_TABLE_A2);
      expect(qA1.position).toBe(1);

      const qA3 = testDbStore.tournamentTableQueue.find((q: any) => q.matchId === UUID_MATCH_A3);
      expect(qA3.tableId).toBe(UUID_TABLE_A2);
      expect(qA3.position).toBe(2);
    });

    it("should reject cross-event rebalancing with 400 Bad Request", async () => {
      testDbStore.tournamentTableQueue.push({
        id: "q-1",
        tableId: UUID_TABLE_A1,
        matchId: UUID_MATCH_A1,
        position: 1,
        createdAt: new Date()
      });

      // Target Table B1 belongs to Event B
      const res = await request(app)
        .post("/tournaments/tables/queue/rebalance")
        .send({
          matchId: UUID_MATCH_A1,
          targetTableId: UUID_TABLE_B1,
          targetPosition: 1
        })
        .set("Authorization", authHeader(UserRole.REFEREE));

      expect(res.status).toBe(400);
      expect(res.body.detail || res.body.message || res.body.error).toMatch(/different tournament events/i);
    });

    it("should reject rebalancing a match that is not currently queued", async () => {
      const res = await request(app)
        .post("/tournaments/tables/queue/rebalance")
        .send({
          matchId: UUID_MATCH_A1,
          targetTableId: UUID_TABLE_A2,
          targetPosition: 1
        })
        .set("Authorization", authHeader(UserRole.REFEREE));

      expect(res.status).toBe(400);
      expect(res.body.detail || res.body.message || res.body.error).toMatch(/not currently in any queue/i);
    });
  });

  // =========================================================================
  // 7. Match Result & Lifecycle Integration
  // =========================================================================
  describe("7. Match Result & Lifecycle Integration", () => {
    it("should release table and delete queue entry when a match result is submitted", async () => {
      // Assign referee, call match to Table A1
      testDbStore.tournamentMatches.find((m: any) => m.id === UUID_MATCH_A1).refereeId = UUID_REFEREE;

      await request(app)
        .post("/tournaments/matches/call")
        .send({ matchId: UUID_MATCH_A1, tableId: UUID_TABLE_A1 })
        .set("Authorization", authHeader(UserRole.REFEREE));

      // Table A1 is active
      expect(testDbStore.matchTables.find((t: any) => t.id === UUID_TABLE_A1).status).toBe("ACTIVE");

      // Submit result
      const res = await request(app)
        .post("/tournaments/matches/result")
        .send({
          matchId: UUID_MATCH_A1,
          winnerId: UUID_ATHLETE_1,
          scoreLine: "3-0"
        })
        .set("Authorization", authHeader(UserRole.REFEREE));

      expect(res.status).toBe(200);

      // Table should be released back to IDLE
      const table = testDbStore.matchTables.find((t: any) => t.id === UUID_TABLE_A1);
      expect(table.status).toBe("IDLE");
      expect(table.currentMatchId).toBeNull();

      // Queue is empty
      expect(testDbStore.tournamentTableQueue).toHaveLength(0);
    });
  });
});
