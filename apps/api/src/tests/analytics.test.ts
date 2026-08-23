import { describe, it, expect, beforeEach } from "vitest";
import request from "supertest";
import { testDbStore } from "./setup.js";
import { app } from "../app.js";
import { UserRole } from "@armsphere/types";
import { generateAccessToken } from "@armsphere/cryptography";
import env from "../config/env.js";

describe("Analytics API & Service Suite", () => {
  let athleteUser: any;
  let athleteToken: string;
  const athleteId = "00000000-0000-0000-0000-000000000001";
  const opponentId = "00000000-0000-0000-0000-000000000002";

  beforeEach(() => {
    // Seed user
    athleteUser = {
      id: "user-athlete-123",
      email: "athlete_analytics@armsphere.com",
      username: "athlete_analytics",
      role: UserRole.ATHLETE,
      fullName: "Athlete Analytics",
      isActive: true,
    };
    testDbStore.users = [athleteUser];

    // Generate JWT Auth Token
    athleteToken = generateAccessToken(
      athleteUser.id,
      athleteUser.email,
      UserRole.ATHLETE,
      env.JWT_ACCESS_SECRET
    );

    // Seed Athlete Profiles
    testDbStore.athleteProfiles = [
      {
        id: athleteId,
        userId: "user-athlete-123",
        displayName: "Athlete One",
        leftArmElo: 1100,
        rightArmElo: 1250,
        isDeleted: false,
      },
      {
        id: opponentId,
        userId: "user-opponent-456",
        displayName: "Athlete Two",
        leftArmElo: 1500,
        rightArmElo: 1800,
        isDeleted: false,
      },
      {
        id: "deleted-athlete-id",
        userId: "user-deleted-789",
        displayName: "Deleted Athlete",
        leftArmElo: 2300,
        rightArmElo: 2300,
        isDeleted: true,
      },
    ];

    // Seed Matches
    testDbStore.matches = [
      {
        id: "match-uuid-1",
        challengerId: athleteId,
        opponentId,
        arm: "LEFT",
        winnerId: opponentId,
        status: "VERIFIED",
        scoreLine: "3-0",
        createdAt: new Date("2026-07-01T12:00:00Z"),
      },
      {
        id: "match-uuid-2",
        challengerId: athleteId,
        opponentId,
        arm: "RIGHT",
        winnerId: athleteId,
        status: "VERIFIED",
        scoreLine: "3-1",
        createdAt: new Date("2026-07-01T15:00:00Z"),
      },
      {
        id: "match-uuid-3",
        challengerId: athleteId,
        opponentId,
        arm: "RIGHT",
        winnerId: opponentId,
        status: "VERIFIED",
        scoreLine: "3-2",
        createdAt: new Date("2026-07-02T10:00:00Z"),
      },
    ];

    // Seed Disputes
    testDbStore.disputes = [
      {
        id: "dispute-uuid-1",
        matchId: "match-uuid-3",
        creatorId: athleteUser.id,
        title: "False start in round 2",
        description: "The competitor loaded early before referee's command.",
        status: "OPEN",
      },
    ];
  });

  it("should fail when unauthenticated", async () => {
    const res = await request(app).get("/api/v1/analytics/overview");
    expect(res.status).toBe(401);
  });

  it("should calculate correct overview metrics including match volume, active athletes, and dispute rates", async () => {
    const res = await request(app)
      .get("/api/v1/analytics/overview")
      .set("Authorization", `Bearer ${athleteToken}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);

    const data = res.body.data;
    expect(data.totalMatches).toBe(3);
    expect(data.totalDisputes).toBe(1);
    expect(data.disputeRatePercentage).toBe(33.33); // 1 dispute / 3 matches * 100
    expect(data.activeAthleteCount).toBe(2); // excluding deleted-athlete-id

    // Verify match volume over time grouping
    expect(data.matchVolumeOverTime).toHaveLength(2);
    expect(data.matchVolumeOverTime[0]).toEqual({
      date: "2026-07-01",
      count: 2,
    });
    expect(data.matchVolumeOverTime[1]).toEqual({
      date: "2026-07-02",
      count: 1,
    });
  });

  it("should compute accurate ELO distribution bins for both LEFT and RIGHT arms independently", async () => {
    const res = await request(app)
      .get("/api/v1/analytics/elo-distribution")
      .set("Authorization", `Bearer ${athleteToken}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);

    const distribution = res.body.data;
    // Bins defined: 1000-1199, 1200-1399, 1400-1599, 1600-1799, 1800-1999, 2000-2199, 2200+
    expect(distribution).toHaveLength(7);

    // Let's check "1000-1199" range
    // Athlete 1 leftArmElo = 1100 -> in 1000-1199
    // Athlete 2 leftArmElo = 1500 -> in 1400-1599
    // Athlete 1 rightArmElo = 1250 -> in 1200-1399
    // Athlete 2 rightArmElo = 1800 -> in 1800-1999
    const range1000to1199 = distribution.find((d: any) => d.range === "1000-1199");
    expect(range1000to1199).toBeDefined();
    expect(range1000to1199.leftArmCount).toBe(1);
    expect(range1000to1199.rightArmCount).toBe(0);

    const range1200to1399 = distribution.find((d: any) => d.range === "1200-1399");
    expect(range1200to1399).toBeDefined();
    expect(range1200to1399.leftArmCount).toBe(0);
    expect(range1200to1399.rightArmCount).toBe(1);

    const range1400to1599 = distribution.find((d: any) => d.range === "1400-1599");
    expect(range1400to1599).toBeDefined();
    expect(range1400to1599.leftArmCount).toBe(1);
    expect(range1400to1599.rightArmCount).toBe(0);

    const range1800to1999 = distribution.find((d: any) => d.range === "1800-1999");
    expect(range1800to1999).toBeDefined();
    expect(range1800to1999.leftArmCount).toBe(0);
    expect(range1800to1999.rightArmCount).toBe(1);

    // Deleted athletes should be fully excluded
    const range2200plus = distribution.find((d: any) => d.range === "2200+");
    expect(range2200plus.leftArmCount).toBe(0);
    expect(range2200plus.rightArmCount).toBe(0);
  });

  it("should also serve overview at the root-mounted /analytics path (matches admin-web's actual base URL)", async () => {
    const res = await request(app)
      .get("/analytics/overview")
      .set("Authorization", `Bearer ${athleteToken}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.totalMatches).toBe(3);
  });

  it("should also serve elo-distribution at the root-mounted /analytics path", async () => {
    const res = await request(app)
      .get("/analytics/elo-distribution")
      .set("Authorization", `Bearer ${athleteToken}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(Array.isArray(res.body.data)).toBe(true);
  });
});
