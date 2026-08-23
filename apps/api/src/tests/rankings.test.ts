import { describe, it, expect, beforeEach, vi } from "vitest";
import { testDbStore } from "./setup.js";
import { RankingsService } from "../services/rankings.js";
import { MatchService } from "../services/match.js";
import { UserRole } from "@armsphere/types";

describe("Rankings & ELO System Unit/Integration Tests", () => {
  beforeEach(() => {
    // Reset test database store tables
    testDbStore.users = [];
    testDbStore.athleteProfiles = [];
    testDbStore.matches = [];
    testDbStore.eloLedger = [];
    testDbStore.rankingSnapshots = [];
    testDbStore.auditLogs = [];
  });

  describe("1. Leaderboard listings & Caching", () => {
    beforeEach(() => {
      testDbStore.athleteProfiles = [
        {
          id: "00000000-0000-0000-0000-000000000001",
          userId: "user-1",
          displayName: "Alice Mercer",
          leftArmElo: 1600,
          rightArmElo: 1300,
          province: "ON",
          clubId: "club-alpha",
          isDeleted: false,
          status: "VERIFIED",
        },
        {
          id: "00000000-0000-0000-0000-000000000002",
          userId: "user-2",
          displayName: "Bob Stone",
          leftArmElo: 1450,
          rightArmElo: 1550,
          province: "BC",
          clubId: "club-beta",
          isDeleted: false,
          status: "VERIFIED",
        },
        {
          id: "00000000-0000-0000-0000-000000000003",
          userId: "user-3",
          displayName: "Charlie Davis",
          leftArmElo: 1000,
          rightArmElo: 1700,
          province: "ON",
          clubId: "club-alpha",
          isDeleted: false,
          status: "VERIFIED",
        },
      ];
    });

    it("should return leaderboard results from database and cache them for subsequent requests", async () => {
      const result1 = await RankingsService.getLeaderboard({ arm: "LEFT", limit: 2 });

      expect(result1.items.length).toBe(2);
      expect(result1.items[0].athleteId).toBe("00000000-0000-0000-0000-000000000001"); // Alice
      expect(result1.items[0].eloRating).toBe(1600);
      expect(result1.items[1].athleteId).toBe("00000000-0000-0000-0000-000000000002"); // Bob
      expect(result1.items[1].eloRating).toBe(1450);

      // Subsequent call should return cached result
      const result2 = await RankingsService.getLeaderboard({ arm: "LEFT", limit: 2 });
      expect(result2).toEqual(result1);
    });

    it("should filter leaderboard listings by search text, province, and club ID", async () => {
      const result = await RankingsService.getLeaderboard({
        arm: "LEFT",
        province: "ON",
        clubId: "club-alpha",
        search: "Alice",
      });

      expect(result.items.length).toBe(1);
      expect(result.items[0].athleteId).toBe("00000000-0000-0000-0000-000000000001");
      expect(result.items[0].displayName).toBe("Alice Mercer");
    });

    it("should support cursor-based pagination across multiple pages", async () => {
      // 1. Fetch page 1 with limit = 1 for RIGHT arm
      // RIGHT arm ELO: Charlie (1700), Bob (1550), Alice (1300)
      const page1 = await RankingsService.getLeaderboard({ arm: "RIGHT", limit: 1 });
      expect(page1.items.length).toBe(1);
      expect(page1.items[0].athleteId).toBe("00000000-0000-0000-0000-000000000003"); // Charlie (1700)
      expect(page1.nextCursor).toBe("1700_00000000-0000-0000-0000-000000000003");

      // 2. Fetch page 2 using cursor
      const page2 = await RankingsService.getLeaderboard({
        arm: "RIGHT",
        limit: 1,
        cursor: page1.nextCursor,
      });
      expect(page2.items.length).toBe(1);
      expect(page2.items[0].athleteId).toBe("00000000-0000-0000-0000-000000000002"); // Bob (1550)
      expect(page2.nextCursor).toBe("1550_00000000-0000-0000-0000-000000000002");
    });
  });

  describe("2. Historical Snapshot Generation", () => {
    beforeEach(() => {
      testDbStore.athleteProfiles = [
        {
          id: "00000000-0000-0000-0000-000000000001",
          userId: "user-1",
          displayName: "Alice Mercer",
          leftArmElo: 1600,
          rightArmElo: 1300,
          province: "ON",
          clubId: "club-alpha",
          isDeleted: false,
          status: "VERIFIED",
        },
        {
          id: "00000000-0000-0000-0000-000000000002",
          userId: "user-2",
          displayName: "Bob Stone",
          leftArmElo: 1450,
          rightArmElo: 1550,
          province: "BC",
          clubId: "club-beta",
          isDeleted: false,
          status: "VERIFIED",
        },
      ];
    });

    it("should generate a primary snapshot and record rankMovement as NEW", async () => {
      const result = await RankingsService.generateRankingSnapshot("DAILY", "LEFT", "SENIOR");
      expect(result.success).toBe(true);
      expect(result.count).toBe(2);

      expect(testDbStore.rankingSnapshots.length).toBe(2);
      const snapshotAlice = testDbStore.rankingSnapshots.find((s) => s.athleteId === "00000000-0000-0000-0000-000000000001");
      const snapshotBob = testDbStore.rankingSnapshots.find((s) => s.athleteId === "00000000-0000-0000-0000-000000000002");

      expect(snapshotAlice).toBeDefined();
      expect(snapshotAlice.rank).toBe(1); // Alice (1600) is #1
      expect(snapshotAlice.rankMovement).toBe("NEW");

      expect(snapshotBob).toBeDefined();
      expect(snapshotBob.rank).toBe(2); // Bob (1450) is #2
      expect(snapshotBob.rankMovement).toBe("NEW");
    });

    it("should compute accurate rank movement UP, DOWN, or UNCHANGED relative to the prior snapshot", async () => {
      // 1. Generate first snapshot (historical baseline date)
      const date1 = new Date("2026-07-01");
      const baselineAlice = {
        athleteId: "00000000-0000-0000-0000-000000000001",
        snapshotType: "DAILY" as const,
        arm: "LEFT" as const,
        division: "SENIOR" as const,
        weightClass: "OPEN",
        eloRating: 1600,
        rank: 1,
        previousRank: null,
        rankMovement: "NEW" as const,
        snapshotDate: date1,
      };
      const baselineBob = {
        athleteId: "00000000-0000-0000-0000-000000000002",
        snapshotType: "DAILY" as const,
        arm: "LEFT" as const,
        division: "SENIOR" as const,
        weightClass: "OPEN",
        eloRating: 1450,
        rank: 2,
        previousRank: null,
        rankMovement: "NEW" as const,
        snapshotDate: date1,
      };
      testDbStore.rankingSnapshots = [baselineAlice, baselineBob];

      // 2. Bob overtakes Alice in ELO ratings
      const aliceProfile = testDbStore.athleteProfiles.find((p) => p.id === "00000000-0000-0000-0000-000000000001");
      const bobProfile = testDbStore.athleteProfiles.find((p) => p.id === "00000000-0000-0000-0000-000000000002");
      aliceProfile.leftArmElo = 1500;
      bobProfile.leftArmElo = 1700; // Bob is now #1, Alice is #2

      // 3. Generate a new snapshot and analyze movement
      const result = await RankingsService.generateRankingSnapshot("DAILY", "LEFT", "SENIOR");
      expect(result.success).toBe(true);

      const latestSnapshots = testDbStore.rankingSnapshots.filter((s) => s.snapshotDate !== date1);
      expect(latestSnapshots.length).toBe(2);

      const snapAlice = latestSnapshots.find((s) => s.athleteId === "00000000-0000-0000-0000-000000000001");
      const snapBob = latestSnapshots.find((s) => s.athleteId === "00000000-0000-0000-0000-000000000002");

      expect(snapBob.rank).toBe(1);
      expect(snapBob.previousRank).toBe(2);
      expect(snapBob.rankMovement).toBe("UP"); // Moved from #2 to #1

      expect(snapAlice.rank).toBe(2);
      expect(snapAlice.previousRank).toBe(1);
      expect(snapAlice.rankMovement).toBe("DOWN"); // Moved from #1 to #2
    });
  });

  describe("3. ELO Engine Mathematics & Floor Checks", () => {
    let challenger: any;
    let opponent: any;
    let referee: any;

    beforeEach(() => {
      referee = {
        id: "00000000-0000-0000-0000-00000000000r",
        role: UserRole.REFEREE,
        username: "ref_jack",
        isActive: true,
      };
      testDbStore.users = [referee];

      testDbStore.refereeCertifications = [
        {
          id: "cert-ref-jack",
          userId: "00000000-0000-0000-0000-00000000000r",
          certificationLevel: "PRO_LEVEL_2",
          issuedAt: new Date(),
          expiresAt: new Date(Date.now() + 86400000 * 365),
          status: "ACTIVE",
          issuingBody: "WAF_OFFICIAL",
        }
      ];

      challenger = {
        id: "00000000-0000-0000-0000-00000000000c",
        userId: "user-c",
        displayName: "Challenger Claw",
        leftArmElo: 1500,
        rightArmElo: 1500,
        status: "VERIFIED",
        isDeleted: false,
      };

      opponent = {
        id: "00000000-0000-0000-0000-00000000000o",
        userId: "user-o",
        displayName: "Opponent Over-The-Top",
        leftArmElo: 1500,
        rightArmElo: 1500,
        status: "VERIFIED",
        isDeleted: false,
      };

      testDbStore.athleteProfiles = [challenger, opponent];
    });

    it("should compute correct win/loss ELO deltas and satisfy zero-sum conservation when no floor is hit", async () => {
      // Setup a match where challenger wins on RIGHT arm
      const match = {
        id: "match-elo-1",
        refereeId: "00000000-0000-0000-0000-00000000000r", // must match the reviewerId used to verify below
        challengerId: "00000000-0000-0000-0000-00000000000c",
        opponentId: "00000000-0000-0000-0000-00000000000o",
        arm: "RIGHT",
        winnerId: "00000000-0000-0000-0000-00000000000c",
        scoreLine: "3-0",
        status: "PENDING_VERIFICATION",
      };
      testDbStore.matches = [match];

      // Verify match to trigger ELO updates
      await MatchService.verifyMatch("match-elo-1", "00000000-0000-0000-0000-00000000000r");

      const updatedChallenger = testDbStore.athleteProfiles.find((p) => p.id === "00000000-0000-0000-0000-00000000000c");
      const updatedOpponent = testDbStore.athleteProfiles.find((p) => p.id === "00000000-0000-0000-0000-00000000000o");

      // Verify zero-sum conservation: deltaC + deltaO = 0
      const deltaC = updatedChallenger.rightArmElo - 1500;
      const deltaO = updatedOpponent.rightArmElo - 1500;

      expect(deltaC).toBeGreaterThan(0);
      expect(deltaO).toBeLessThan(0);
      expect(deltaC + deltaO).toBe(0); // Zero-sum conservation strictly holds!

      // Detailed ELO math check with K = 64 (both have <10 matches)
      // Expected challenger score = 1 / (1 + 10^((1500-1500)/400)) = 0.5
      // Expected opponent score = 0.5
      // actualC = 1, actualO = 0
      // deltaC = Math.round(64 * (1 - 0.5)) = 32
      // deltaO = Math.round(64 * (0 - 0.5)) = -32
      expect(updatedChallenger.rightArmElo).toBe(1532);
      expect(updatedOpponent.rightArmElo).toBe(1468);
    });

    it("should strictly enforce a min 1000 ELO rating floor and handle non-zero sum correctly during floor hits", async () => {
      // Set opponent ELO near the floor (1015 ELO)
      const lowEloOpponent = testDbStore.athleteProfiles.find((p) => p.id === "00000000-0000-0000-0000-00000000000o");
      lowEloOpponent.rightArmElo = 1015;

      const match = {
        id: "match-elo-floor",
        refereeId: "00000000-0000-0000-0000-00000000000r", // must match the reviewerId used to verify below
        challengerId: "00000000-0000-0000-0000-00000000000c",
        opponentId: "00000000-0000-0000-0000-00000000000o",
        arm: "RIGHT",
        winnerId: "00000000-0000-0000-0000-00000000000c", // Challenger (1500) wins against Opponent (1015)
        scoreLine: "3-0",
        status: "PENDING_VERIFICATION",
      };
      testDbStore.matches = [match];

      await MatchService.verifyMatch("match-elo-floor", "00000000-0000-0000-0000-00000000000r");

      const updatedChallenger = testDbStore.athleteProfiles.find((p) => p.id === "00000000-0000-0000-0000-00000000000c");
      const updatedOpponent = testDbStore.athleteProfiles.find((p) => p.id === "00000000-0000-0000-0000-00000000000o");

      // Opponent expected rating change:
      // Expected opponent score = 1 / (1 + 10^((1500 - 1015)/400)) = 1 / (1 + 10^1.2125) = 1 / 17.31 = 0.0577
      // deltaO = Math.round(64 * (0 - 0.0577)) = Math.round(-3.7) = -4
      // New rating without floor = 1015 - 4 = 1011. This doesn't hit floor.

      // Let's set opponent ELO to EXACTLY 1000 so deltaO is negative and they would go below 1000
      updatedOpponent.rightArmElo = 1000;
      const match2 = {
        id: "match-elo-floor-strict",
        refereeId: "00000000-0000-0000-0000-00000000000r", // must match the reviewerId used to verify below
        challengerId: "00000000-0000-0000-0000-00000000000c",
        opponentId: "00000000-0000-0000-0000-00000000000o",
        arm: "RIGHT",
        winnerId: "00000000-0000-0000-0000-00000000000c",
        scoreLine: "3-0",
        status: "PENDING_VERIFICATION",
      };
      testDbStore.matches.push(match2);

      await MatchService.verifyMatch("match-elo-floor-strict", "00000000-0000-0000-0000-00000000000r");

      const finalChallenger = testDbStore.athleteProfiles.find((p) => p.id === "00000000-0000-0000-0000-00000000000c");
      const finalOpponent = testDbStore.athleteProfiles.find((p) => p.id === "00000000-0000-0000-0000-00000000000o");

      // Opponent rating must remain at exactly 1000
      expect(finalOpponent.rightArmElo).toBe(1000);

      // Challenger rating should still rise correctly
      expect(finalChallenger.rightArmElo).toBeGreaterThan(1500);
    });

    it("should apply varying K-factors based on match volume and high-ELO bracket standards correctly", async () => {
      // 1. Mock 12 verified matches for challenger in RIGHT arm to test K = 32 transition (standard)
      const verifiedMatches = Array.from({ length: 12 }).map((_, i) => ({
        id: `match-seed-${i}`,
        challengerId: "00000000-0000-0000-0000-00000000000c",
        opponentId: "00000000-0000-0000-0000-00000000dummy",
        arm: "RIGHT",
        winnerId: "00000000-0000-0000-0000-00000000000c",
        status: "VERIFIED",
      }));
      testDbStore.matches.push(...verifiedMatches);

      const match = {
        id: "match-elo-k32",
        refereeId: "00000000-0000-0000-0000-00000000000r", // must match the reviewerId used to verify below
        challengerId: "00000000-0000-0000-0000-00000000000c",
        opponentId: "00000000-0000-0000-0000-00000000000o",
        arm: "RIGHT",
        winnerId: "00000000-0000-0000-0000-00000000000c",
        scoreLine: "3-0",
        status: "PENDING_VERIFICATION",
      };
      testDbStore.matches.push(match);

      await MatchService.verifyMatch("match-elo-k32", "00000000-0000-0000-0000-00000000000r");

      const finalChallenger = testDbStore.athleteProfiles.find((p) => p.id === "00000000-0000-0000-0000-00000000000c");
      // Challenger expected ELO change with K = 32 (due to >10 matches)
      // ratingC = 1500, ratingO = 1500
      // expectedC = 0.5, actualC = 1
      // deltaC = Math.round(32 * (1 - 0.5)) = 16
      // New rating = 1500 + 16 = 1516
      expect(finalChallenger.rightArmElo).toBe(1516);
    });
  });
});
