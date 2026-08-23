import { describe, it, expect, beforeEach, vi } from "vitest";
import request from "supertest";
import { testDbStore } from "./setup.js";
import { app } from "../app.js";
import { RankingsService } from "../services/rankings.js";
import { ChampionshipService } from "../services/championship.js";
import { generateAccessToken } from "@armsphere/cryptography";
import { UserRole } from "@armsphere/types";
import { processedJobsTracker, resetJobTrackers, runDueScheduledJobs, scheduleJob, SCHEDULED_JOB_TYPES } from "../services/scheduledJobs.js";
import env from "../config/env.js";

// Helper to construct authorization header
function authHeader(role: UserRole = UserRole.ATHLETE, userId = "user-123") {
  const token = generateAccessToken(userId, "test@armsphere.com", role, env.JWT_ACCESS_SECRET);
  return `Bearer ${token}`;
}

describe("Sprint 4: Rankings, Leaderboards & Championship Systems", () => {
  let athleteAId: string;
  let athleteBId: string;
  let athleteCId: string;
  let directorId: string;

  beforeEach(() => {
    resetJobTrackers();

    // Seed mock database store
    athleteAId = "00000000-0000-0000-0000-000000000001";
    athleteBId = "00000000-0000-0000-0000-000000000002";
    athleteCId = "00000000-0000-0000-0000-000000000003";
    directorId = "00000000-0000-0000-0000-000000000004";

    testDbStore.users = [
      { id: "user-a", role: UserRole.ATHLETE },
      { id: "user-b", role: UserRole.ATHLETE },
      { id: "user-c", role: UserRole.ATHLETE },
      { id: "user-director", role: UserRole.NATIONAL_DIRECTOR },
    ];

    testDbStore.athleteProfiles = [
      {
        id: athleteAId,
        userId: "user-a",
        displayName: "John Doe",
        leftArmElo: 1200,
        rightArmElo: 1250,
        province: "Ontario",
        country: "Canada",
        clubId: "club-x",
        isDeleted: false,
      },
      {
        id: athleteBId,
        userId: "user-b",
        displayName: "Jane Smith",
        leftArmElo: 1100,
        rightArmElo: 1150,
        province: "Quebec",
        country: "Canada",
        clubId: "club-y",
        isDeleted: false,
      },
      {
        id: athleteCId,
        userId: "user-c",
        displayName: "Bob Johnson",
        leftArmElo: 1000,
        rightArmElo: 1050,
        province: "Ontario",
        country: "Canada",
        clubId: "club-x",
        isDeleted: false,
      },
    ];

    testDbStore.championshipTitles = [];
    testDbStore.beltLineage = [];
    testDbStore.championshipChallenges = [];
    testDbStore.prestigeMetrics = [];
    testDbStore.rankingSnapshots = [];
  });

  describe("1. Leaderboards & Caching Engine", () => {
    it("should fetch sorted rankings via REST endpoint", async () => {
      const response = await request(app)
        .get("/rankings/leaderboard")
        .query({ arm: "RIGHT", limit: 5 })
        .set("Authorization", authHeader());

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data.items).toHaveLength(3);

      // Verify ELO descending sorting: A (1250) > B (1150) > C (1050)
      const items = response.body.data.items;
      expect(items[0].athleteId).toBe(athleteAId);
      expect(items[1].athleteId).toBe(athleteBId);
      expect(items[2].athleteId).toBe(athleteCId);
    });

    it("should filter leaderboards by location and search term", async () => {
      const response = await request(app)
        .get("/rankings/leaderboard")
        .query({ arm: "LEFT", province: "Ontario" })
        .set("Authorization", authHeader());

      expect(response.status).toBe(200);
      // Only John Doe (athlete A) and Bob Johnson (athlete C) are in Ontario
      expect(response.body.data.items).toHaveLength(2);
      expect(response.body.data.items.map((i: any) => i.athleteId)).not.toContain(athleteBId);
    });

    it("should support cursor-based pagination", async () => {
      // Fetch page 1 (limit 1)
      const page1 = await request(app)
        .get("/rankings/leaderboard")
        .query({ arm: "RIGHT", limit: 1 })
        .set("Authorization", authHeader());

      expect(page1.status).toBe(200);
      expect(page1.body.data.items).toHaveLength(1);
      expect(page1.body.data.items[0].athleteId).toBe(athleteAId);
      expect(page1.body.data.nextCursor).toBeDefined();

      // Fetch page 2 using cursor
      const page2 = await request(app)
        .get("/rankings/leaderboard")
        .query({ arm: "RIGHT", limit: 1, cursor: page1.body.data.nextCursor })
        .set("Authorization", authHeader());

      expect(page2.status).toBe(200);
      expect(page2.body.data.items).toHaveLength(1);
      expect(page2.body.data.items[0].athleteId).toBe(athleteBId);
    });
  });

  describe("2. Historical Ranking Snapshots", () => {
    it("should compute daily snapshots and correctly record rank movements (UP, DOWN, NEW, UNCHANGED)", async () => {
      // 1. Initial snapshot (all athletes are NEW)
      await RankingsService.generateRankingSnapshot("DAILY", "RIGHT", "SENIOR");
      
      const snaps = testDbStore.rankingSnapshots;
      expect(snaps).toHaveLength(3);
      snaps.forEach((s) => {
        expect(s.rankMovement).toBe("NEW");
      });

      const initialDate = snaps[0].snapshotDate;

      // 2. Change ELOs to trigger movement
      // Swap Jane (B) and John (A) positions
      testDbStore.athleteProfiles[0].rightArmElo = 1100; // John
      testDbStore.athleteProfiles[1].rightArmElo = 1300; // Jane (now rank 1)

      // Generate second snapshot
      await RankingsService.generateRankingSnapshot("DAILY", "RIGHT", "SENIOR");

      // We should have 6 snaps total now (3 from first, 3 from second)
      const newSnaps = testDbStore.rankingSnapshots.filter((s) => s.snapshotDate !== initialDate);
      expect(newSnaps).toHaveLength(3);

      const janeSnap = newSnaps.find((s) => s.athleteId === athleteBId);
      const johnSnap = newSnaps.find((s) => s.athleteId === athleteAId);
      const bobSnap = newSnaps.find((s) => s.athleteId === athleteCId);

      // Jane went from rank 2 to rank 1 (UP)
      expect(janeSnap?.rank).toBe(1);
      expect(janeSnap?.rankMovement).toBe("UP");

      // John went from rank 1 to rank 2 (DOWN)
      expect(johnSnap?.rank).toBe(2);
      expect(johnSnap?.rankMovement).toBe("DOWN");

      // Bob stayed at rank 3 (UNCHANGED)
      expect(bobSnap?.rank).toBe(3);
      expect(bobSnap?.rankMovement).toBe("UNCHANGED");
    });
  });

  describe("3. Championship Titles & Belt Lineage System", () => {
    it("should define a title and allow athletes to submit challenges", async () => {
      const titleRes = await request(app)
        .post("/championships/titles")
        .send({
          name: "National Heavyweight Championship",
          arm: "RIGHT",
          division: "SENIOR",
          weightClass: "95kg",
        })
        .set("Authorization", authHeader(UserRole.NATIONAL_DIRECTOR));

      expect(titleRes.status).toBe(201);
      const titleId = titleRes.body.data.id;

      // Challenger submissions
      const challengeRes = await request(app)
        .post("/championships/challenges")
        .send({
          titleId,
          challengerId: athleteBId,
        })
        .set("Authorization", authHeader());

      expect(challengeRes.status).toBe(201);
      expect(challengeRes.body.data.status).toBe("PENDING");

      // Accept challenge
      const acceptRes = await request(app)
        .post(`/championships/challenges/${challengeRes.body.data.id}/accept`)
        .set("Authorization", authHeader());

      expect(acceptRes.status).toBe(200);
      expect(acceptRes.body.data.status).toBe("ACCEPTED");
    });

    it("should retrieve active championship titles and challenges", async () => {
      // Seed some titles and challenges
      const title1Id = "11111111-1111-1111-1111-111111111111";
      const title2Id = "22222222-2222-2222-2222-222222222222";

      testDbStore.championshipTitles = [
        {
          id: title1Id,
          name: "National Welterweight",
          arm: "RIGHT",
          division: "SENIOR",
          weightClass: "75kg",
          activeChampionId: athleteAId, // active title
          createdAt: new Date(),
          updatedAt: new Date(),
        },
        {
          id: title2Id,
          name: "National Lightweight",
          arm: "LEFT",
          division: "SENIOR",
          weightClass: "65kg",
          activeChampionId: null, // vacant/non-active title
          createdAt: new Date(),
          updatedAt: new Date(),
        },
      ];

      testDbStore.championshipChallenges = [
        {
          id: "challenge-1",
          titleId: title1Id,
          challengerId: athleteBId,
          status: "PENDING",
          createdAt: new Date("2026-01-02T00:00:00Z"),
          updatedAt: new Date("2026-01-02T00:00:00Z"),
        },
        {
          id: "challenge-2",
          titleId: title1Id,
          challengerId: athleteCId,
          status: "ACCEPTED",
          createdAt: new Date("2026-01-01T00:00:00Z"),
          updatedAt: new Date("2026-01-01T00:00:00Z"),
        },
      ];

      // Query active titles (GET /championships/titles)
      const getTitlesRes = await request(app)
        .get("/championships/titles")
        .set("Authorization", authHeader());

      expect(getTitlesRes.status).toBe(200);
      expect(getTitlesRes.body.success).toBe(true);
      expect(getTitlesRes.body.data).toBeInstanceOf(Array);
      // It should only return active titles (where activeChampionId is not null)
      expect(getTitlesRes.body.data).toHaveLength(1);
      expect(getTitlesRes.body.data[0].id).toBe(title1Id);
      expect(getTitlesRes.body.data[0].activeChampion.id).toBe(athleteAId);

      // Query all challenges (GET /championships/challenges)
      const getChallengesRes = await request(app)
        .get("/championships/challenges")
        .set("Authorization", authHeader());

      expect(getChallengesRes.status).toBe(200);
      expect(getChallengesRes.body.success).toBe(true);
      expect(getChallengesRes.body.data).toBeInstanceOf(Array);
      expect(getChallengesRes.body.data).toHaveLength(2);
      expect(getChallengesRes.body.data[0].title.id).toBe(title1Id);
      expect(getChallengesRes.body.data[0].challenger.id).toBe(athleteBId);

      // Query filtered challenges (GET /championships/challenges?status=ACCEPTED)
      const getFilteredRes = await request(app)
        .get("/championships/challenges")
        .query({ status: "ACCEPTED" })
        .set("Authorization", authHeader());

      expect(getFilteredRes.status).toBe(200);
      expect(getFilteredRes.body.success).toBe(true);
      expect(getFilteredRes.body.data).toBeInstanceOf(Array);
      expect(getFilteredRes.body.data).toHaveLength(1);
      expect(getFilteredRes.body.data[0].status).toBe("ACCEPTED");
      expect(getFilteredRes.body.data[0].challenger.id).toBe(athleteCId);
    });

    it("should handle succession, defenses, title vacancy, stripping, and lineage tracking", async () => {
      // 1. Create a title definition
      const title = await ChampionshipService.createTitle("Provincial Title", "RIGHT", "SENIOR", "OPEN") as any;
      expect(title.activeChampionId).toBeNull();

      // Apply succession (vacant title crowns top ELO successor: John Doe (A) ELO 1250)
      await ChampionshipService.applyAutomaticSuccession(title.id);
      
      const [updatedTitle] = testDbStore.championshipTitles;
      expect(updatedTitle.activeChampionId).toBe(athleteAId);

      // Check lineage record created
      const lineage = testDbStore.beltLineage;
      expect(lineage).toHaveLength(1);
      expect(lineage[0].athleteId).toBe(athleteAId);
      expect(lineage[0].reason).toBe("SUCCESSION");

      // 2. Successful Defense by John (A)
      await ChampionshipService.defendTitle(title.id, athleteAId, "match-defense-uuid");
      expect(testDbStore.beltLineage[0].defensesCount).toBe(1);

      // 3. Loss to Challenger Jane (B)
      await ChampionshipService.defendTitle(title.id, athleteBId, "match-loss-uuid");
      
      // Old reign should be terminated (vacatedAt is set)
      const formerReign = testDbStore.beltLineage.find((l) => l.athleteId === athleteAId);
      expect(formerReign?.vacatedAt).toBeDefined();
      expect(formerReign?.reason).toBe("LOST");

      // New reign for Jane is established
      const newReign = testDbStore.beltLineage.find((l) => l.athleteId === athleteBId && !l.vacatedAt);
      expect(newReign).toBeDefined();
      expect(newReign?.reason).toBe("DEFENSE");

      // Lineage list API returns days calculations
      const lineageHistory = await ChampionshipService.getLineageHistory(title.id);
      expect(lineageHistory).toHaveLength(2);
      expect(lineageHistory[0].reignDays).toBeGreaterThanOrEqual(0);

      // 4. Strip title (Vacate) - triggers automatic succession to top rated (athleteAId)
      await ChampionshipService.vacateTitle(title.id, "STRIPPED");
      expect(testDbStore.championshipTitles[0].activeChampionId).toBe(athleteAId);
    });
  });

  describe("4. Prestige Engine (PFP)", () => {
    it("should compute Pound-For-Pound ratings and dominance metrics correctly", async () => {
      // Initial calculation
      await ChampionshipService.recomputePrestigeScores();

      const metrics = testDbStore.prestigeMetrics;
      expect(metrics).toHaveLength(3);

      // John Doe (A) should be rank 1 due to highest avg ELO (1225)
      const pfp1 = metrics.find((m) => m.athleteId === athleteAId);
      expect(pfp1?.pfpRank).toBe(1);
      expect(pfp1?.prestigeScore).toBeGreaterThan(0);
    });
  });

  describe("5. Background Jobs (PostgreSQL Scheduled Jobs)", () => {
    it("should process registered scheduled jobs and audit successfully", async () => {
      await scheduleJob(SCHEDULED_JOB_TYPES.TITLE_INTEGRITY_AUDIT, new Date(), {});
      await runDueScheduledJobs();

      expect(processedJobsTracker.titleIntegrityAudited).toHaveLength(1);
    });
  });
});
