import { describe, it, expect, beforeEach } from "vitest";
import request from "supertest";
import { testDbStore } from "./setup.js";
import { app } from "../app.js";
import { UserRole } from "@armsphere/types";
import { generateAccessToken } from "@armsphere/cryptography";
import env from "../config/env.js";
import {
  fuzzCoordinates,
  generateLocationFuzzSeed,
  haversineDistanceMeters,
} from "../services/locationPrivacy.js";

describe("Spatial Radar, Location Privacy Engine & Coordinates API Suite", () => {
  const athlete1Id = "11111111-1111-4111-8111-111111111111";
  const athlete2Id = "22222222-2222-4222-8222-222222222222";
  const athlete3Id = "33333333-3333-4333-8333-333333333333";
  const operatorId = "44444444-4444-4444-8444-444444444444";
  const adminId = "55555555-5555-4555-8555-555555555555";

  let athlete1Token: string;
  let athlete2Token: string;
  let athlete3Token: string;
  let operatorToken: string;
  let adminToken: string;

  beforeEach(() => {
    const users = [
      {
        id: athlete1Id,
        email: "area@armsphere.com",
        username: "area_puller",
        role: UserRole.ATHLETE,
        fullName: "Area Puller",
        isActive: true,
      },
      {
        id: athlete2Id,
        email: "travel@armsphere.com",
        username: "travel_puller",
        role: UserRole.ATHLETE,
        fullName: "Travel Puller",
        isActive: true,
      },
      {
        id: athlete3Id,
        email: "ghost@armsphere.com",
        username: "ghost_puller",
        role: UserRole.ATHLETE,
        fullName: "Ghost Puller",
        isActive: true,
      },
      {
        id: operatorId,
        email: "operator@armsphere.com",
        username: "tourney_op",
        role: UserRole.TOURNAMENT_OPERATOR,
        fullName: "Tournament Operator",
        isActive: true,
      },
      {
        id: adminId,
        email: "admin@armsphere.com",
        username: "sys_admin",
        role: UserRole.SYSTEM_ADMIN,
        fullName: "System Admin",
        isActive: true,
      },
    ];

    testDbStore.users.push(...users);

    athlete1Token = `Bearer ${generateAccessToken(athlete1Id, users[0].email, UserRole.ATHLETE, env.JWT_ACCESS_SECRET)}`;
    athlete2Token = `Bearer ${generateAccessToken(athlete2Id, users[1].email, UserRole.ATHLETE, env.JWT_ACCESS_SECRET)}`;
    athlete3Token = `Bearer ${generateAccessToken(athlete3Id, users[2].email, UserRole.ATHLETE, env.JWT_ACCESS_SECRET)}`;
    operatorToken = `Bearer ${generateAccessToken(operatorId, users[3].email, UserRole.TOURNAMENT_OPERATOR, env.JWT_ACCESS_SECRET)}`;
    adminToken = `Bearer ${generateAccessToken(adminId, users[4].email, UserRole.SYSTEM_ADMIN, env.JWT_ACCESS_SECRET)}`;
  });

  describe("Location Privacy Fuzzing Unit Guarantees", () => {
    it("should deterministically offset coordinates between 500m and 1500m", () => {
      const exactLat = 31.5204;
      const exactLng = 74.3587;
      const seed = generateLocationFuzzSeed(athlete1Id);

      const first = fuzzCoordinates(exactLat, exactLng, seed);
      const second = fuzzCoordinates(exactLat, exactLng, seed);

      expect(first).toEqual(second);
      expect(first.latitude).not.toBe(exactLat);
      expect(first.longitude).not.toBe(exactLng);

      const dist = haversineDistanceMeters(exactLat, exactLng, first.latitude, first.longitude);
      expect(dist).toBeGreaterThanOrEqual(495);
      expect(dist).toBeLessThanOrEqual(1505);
    });
  });

  describe("Spatial Coordinate Persistence on Existing Endpoints", () => {
    it("should persist coordinates and privacy rules on athlete profiles, clubs, events, venues, and informal events", async () => {
      // 1. Athlete profile create with AREA visibility
      const createAthleteRes = await request(app)
        .post("/athletes")
        .set("Authorization", athlete1Token)
        .send({
          displayName: "Lahore Hook King",
          province: "Punjab",
          city: "Lahore",
          handedness: "RIGHT",
          dominantArm: "RIGHT",
          dateOfBirth: "1996-05-10T00:00:00.000Z",
          gender: "MALE",
          weightClass: "85kg",
          latitude: 31.5204,
          longitude: 74.3587,
          locationVisibility: "AREA",
        });

      expect(createAthleteRes.status).toBe(201);
      expect(createAthleteRes.body.data.latitude).toBe(31.5204);
      expect(createAthleteRes.body.data.longitude).toBe(74.3587);
      expect(createAthleteRes.body.data.locationVisibility).toBe("AREA");
      // Never expose fuzz seed
      expect(createAthleteRes.body.data.locationFuzzSeed).toBeUndefined();

      // Another viewer fetching this profile gets fuzzed coordinates (never exact)
      const publicReadRes = await request(app)
        .get(`/athletes/${createAthleteRes.body.data.id}`)
        .set("Authorization", athlete2Token);

      expect(publicReadRes.status).toBe(200);
      expect(publicReadRes.body.data.locationFuzzSeed).toBeUndefined();
      expect(publicReadRes.body.data.latitude).not.toBe(31.5204);
      expect(publicReadRes.body.data.longitude).not.toBe(74.3587);
      const dist = haversineDistanceMeters(
        31.5204,
        74.3587,
        publicReadRes.body.data.latitude,
        publicReadRes.body.data.longitude
      );
      expect(dist).toBeGreaterThanOrEqual(495);
      expect(dist).toBeLessThanOrEqual(1505);

      // Owner fetching /athletes/me still gets their exact coordinates
      const selfReadRes = await request(app)
        .get("/athletes/me")
        .set("Authorization", athlete1Token);
      expect(selfReadRes.status).toBe(200);
      expect(selfReadRes.body.data.latitude).toBe(31.5204);
      expect(selfReadRes.body.data.longitude).toBe(74.3587);

      // 2. Club with coordinates (RBAC-protected endpoint)
      const clubRes = await request(app)
        .post("/athletes/clubs")
        .set("Authorization", adminToken)
        .send({
          name: "Iron Grip Lahore",
          city: "Lahore",
          province: "Punjab",
          latitude: 31.5112,
          longitude: 74.3421,
        });
      expect(clubRes.status).toBe(201);
      expect(clubRes.body.data.latitude).toBe(31.5112);
      expect(clubRes.body.data.longitude).toBe(74.3421);

      // 3. Venue partner with coordinates
      const venueRes = await request(app)
        .post("/venues")
        .set("Authorization", athlete1Token)
        .send({
          name: "Nishtar Arm Club",
          city: "Lahore",
          province: "Punjab",
          address: "Nishtar Park Sports Complex, Lahore",
          latitude: 31.5126,
          longitude: 74.3338,
        });
      expect(venueRes.status).toBe(201);
      expect(venueRes.body.data.latitude).toBe(31.5126);
      expect(venueRes.body.data.longitude).toBe(74.3338);

      // 4. Tournament event with coordinates
      const now = Date.now();
      const eventRes = await request(app)
        .post("/tournaments/events")
        .set("Authorization", operatorToken)
        .send({
          name: "Punjab Open Championship",
          registrationStart: new Date(now + 1000 * 60 * 60).toISOString(),
          registrationEnd: new Date(now + 1000 * 60 * 60 * 24).toISOString(),
          startDate: new Date(now + 1000 * 60 * 60 * 48).toISOString(),
          endDate: new Date(now + 1000 * 60 * 60 * 56).toISOString(),
          province: "Punjab",
          city: "Lahore",
          venue: "Gaddafi Arena",
          capacity: 128,
          status: "PUBLISHED",
          latitude: 31.5138,
          longitude: 74.3332,
        });
      expect(eventRes.status).toBe(201);
      expect(eventRes.body.latitude).toBe(31.5138);
      expect(eventRes.body.longitude).toBe(74.3332);

      // 5. Informal sparring meetup with coordinates
      const informalRes = await request(app)
        .post("/informal-events")
        .set("Authorization", athlete1Token)
        .send({
          title: "Sunday Strap Table Practice",
          description: "Two tables available with chalk",
          city: "Lahore",
          province: "Punjab",
          scheduledAt: new Date(now + 1000 * 60 * 60 * 72).toISOString(),
          latitude: 31.531,
          longitude: 74.351,
        });
      expect(informalRes.status).toBe(201);
      expect(informalRes.body.data.latitude).toBe(31.531);
      expect(informalRes.body.data.longitude).toBe(74.351);
    });
  });

  describe("GET /api/radar/nearby & Beacon Lifecycle", () => {
    it("should enforce authentication on radar endpoints", async () => {
      const nearbyRes = await request(app).get(
        "/api/radar/nearby?north=32&south=31&east=75&west=74"
      );
      expect(nearbyRes.status).toBe(401);

      const beaconRes = await request(app).post("/api/radar/beacons").send({
        beaconType: "SPARRING",
        title: "Open Table",
        latitude: 31.52,
        longitude: 74.35,
      });
      expect(beaconRes.status).toBe(401);
    });

    it("should return exact public events/venues, fuzzed AREA athletes, hide TRAVEL_ONLY home base, and completely hide GHOST users", async () => {
      const now = Date.now();

      // Seed 3 athletes in Lahore with AREA, TRAVEL_ONLY, GHOST
      await request(app).post("/athletes").set("Authorization", athlete1Token).send({
        displayName: "Area Athlete",
        province: "Punjab",
        city: "Lahore",
        handedness: "RIGHT",
        dominantArm: "RIGHT",
        dateOfBirth: "1995-01-01T00:00:00.000Z",
        gender: "MALE",
        weightClass: "85kg",
        latitude: 31.5204,
        longitude: 74.3587,
        locationVisibility: "AREA",
      });

      await request(app).post("/athletes").set("Authorization", athlete2Token).send({
        displayName: "Travel Athlete",
        province: "Punjab",
        city: "Lahore",
        handedness: "LEFT",
        dominantArm: "LEFT",
        dateOfBirth: "1994-01-01T00:00:00.000Z",
        gender: "MALE",
        weightClass: "95kg",
        latitude: 31.525,
        longitude: 74.36,
        locationVisibility: "TRAVEL_ONLY",
      });

      await request(app).post("/athletes").set("Authorization", athlete3Token).send({
        displayName: "Ghost Athlete",
        province: "Punjab",
        city: "Lahore",
        handedness: "RIGHT",
        dominantArm: "RIGHT",
        dateOfBirth: "1993-01-01T00:00:00.000Z",
        gender: "MALE",
        weightClass: "105kg",
        latitude: 31.522,
        longitude: 74.355,
        locationVisibility: "GHOST",
      });

      // Published event (should appear exact) + Draft event (should NOT appear)
      await request(app).post("/tournaments/events").set("Authorization", operatorToken).send({
        name: "Lahore Published Cup",
        registrationStart: new Date(now + 3600_000).toISOString(),
        registrationEnd: new Date(now + 86400_000).toISOString(),
        startDate: new Date(now + 172800_000).toISOString(),
        endDate: new Date(now + 200000_000).toISOString(),
        province: "Punjab",
        city: "Lahore",
        venue: "Alhamra Hall",
        capacity: 64,
        status: "PUBLISHED",
        latitude: 31.5546,
        longitude: 74.3312,
      });

      await request(app).post("/tournaments/events").set("Authorization", operatorToken).send({
        name: "Hidden Draft Cup",
        registrationStart: new Date(now + 3600_000).toISOString(),
        registrationEnd: new Date(now + 86400_000).toISOString(),
        startDate: new Date(now + 172800_000).toISOString(),
        endDate: new Date(now + 200000_000).toISOString(),
        province: "Punjab",
        city: "Lahore",
        venue: "Secret Venue",
        capacity: 32,
        status: "DRAFT",
        latitude: 31.55,
        longitude: 74.33,
      });

      // Venue partner (exact)
      await request(app).post("/venues").set("Authorization", athlete1Token).send({
        name: "Model Town Iron Gym",
        city: "Lahore",
        province: "Punjab",
        address: "Block C Model Town, Lahore",
        latitude: 31.4839,
        longitude: 74.3258,
      });

      // Out-of-bounds venue in Karachi (should NOT appear in Lahore bbox)
      await request(app).post("/venues").set("Authorization", athlete1Token).send({
        name: "Karachi Coastal Table",
        city: "Karachi",
        province: "Sindh",
        address: "Clifton Block 4, Karachi",
        latitude: 24.8138,
        longitude: 67.0303,
      });

      // TRAVEL_ONLY athlete drops an active beacon (SHOULD appear)
      const travelBeaconRes = await request(app)
        .post("/api/radar/beacons")
        .set("Authorization", athlete2Token)
        .send({
          beaconType: "TRAVELING",
          title: "Visiting Lahore — Ready to Pull 95kg Left",
          latitude: 31.54,
          longitude: 74.345,
          weightClass: "95kg",
          armPreference: "LEFT",
          durationHours: 12,
        });
      expect(travelBeaconRes.status).toBe(201);

      // GHOST athlete drops a beacon (must STILL be suppressed by GHOST mode)
      await request(app)
        .post("/api/radar/beacons")
        .set("Authorization", athlete3Token)
        .send({
          beaconType: "SPARRING",
          title: "Ghost Beacon Should Stay Hidden",
          latitude: 31.535,
          longitude: 74.348,
          durationHours: 6,
        });

      // Expired beacon inserted directly into store (must NOT appear)
      testDbStore.radarBeacons.push({
        id: "99999999-9999-4999-8999-999999999999",
        userId: athlete1Id,
        beaconType: "SPARRING",
        title: "Expired Beacon",
        latitude: 31.52,
        longitude: 74.35,
        expiresAt: new Date(now - 60_000),
        createdAt: new Date(now - 3600_000),
      });

      // Query Lahore bounding box
      const nearbyRes = await request(app)
        .get("/api/radar/nearby")
        .set("Authorization", athlete1Token)
        .query({
          north: 31.7,
          south: 31.4,
          east: 74.5,
          west: 74.2,
        });

      expect(nearbyRes.status).toBe(200);
      const data = nearbyRes.body.data;

      // Published event exact; DRAFT excluded
      expect(data.events).toHaveLength(1);
      expect(data.events[0].title).toBe("Lahore Published Cup");
      expect(data.events[0].latitude).toBe(31.5546);
      expect(data.events[0].longitude).toBe(74.3312);
      expect(data.events[0].isFuzzed).toBe(false);

      // Lahore venue exact; Karachi venue excluded
      expect(data.venues).toHaveLength(1);
      expect(data.venues[0].title).toBe("Model Town Iron Gym");
      expect(data.venues[0].latitude).toBe(31.4839);
      expect(data.venues[0].longitude).toBe(74.3258);

      // Only AREA athlete appears as home-base pin, and coordinates are fuzzed
      expect(data.athletes).toHaveLength(1);
      expect(data.athletes[0].title).toBe("Area Athlete");
      expect(data.athletes[0].isFuzzed).toBe(true);
      expect(data.athletes[0].latitude).not.toBe(31.5204);
      expect(data.athletes[0].longitude).not.toBe(74.3587);

      // Only TRAVEL_ONLY active beacon appears (GHOST & expired beacons suppressed)
      expect(data.beacons).toHaveLength(1);
      expect(data.beacons[0].title).toBe("Visiting Lahore — Ready to Pull 95kg Left");
      expect(data.beacons[0].latitude).toBe(31.54);
      expect(data.beacons[0].longitude).toBe(74.345);

      // Filter by pinType=EVENT returns only events
      const eventsOnlyRes = await request(app)
        .get("/api/radar/nearby")
        .set("Authorization", athlete1Token)
        .query({
          north: 31.7,
          south: 31.4,
          east: 74.5,
          west: 74.2,
          pinType: "EVENT",
        });
      expect(eventsOnlyRes.status).toBe(200);
      expect(eventsOnlyRes.body.data.pins).toHaveLength(1);
      expect(eventsOnlyRes.body.data.pins[0].pinType).toBe("EVENT");

      // Ownership enforcement on DELETE /api/radar/beacons/:id
      const beaconId = travelBeaconRes.body.data.id;
      const forbiddenDelete = await request(app)
        .delete(`/api/radar/beacons/${beaconId}`)
        .set("Authorization", athlete1Token);
      expect(forbiddenDelete.status).toBe(403);

      const ownerDelete = await request(app)
        .delete(`/api/radar/beacons/${beaconId}`)
        .set("Authorization", athlete2Token);
      expect(ownerDelete.status).toBe(200);
      expect(ownerDelete.body.data.success).toBe(true);
    });

    it("should accept 14-day (336h) traveling puller beacons and reject durations over 14 days", async () => {
      const valid14d = await request(app)
        .post("/api/radar/beacons")
        .set("Authorization", athlete2Token)
        .send({
          beaconType: "TRAVELING",
          title: "Visiting Islamabad — 2 Week Training Camp",
          latitude: 33.6844,
          longitude: 73.0479,
          weightClass: "95kg",
          armPreference: "BOTH",
          durationHours: 336,
        });
      expect(valid14d.status).toBe(201);
      expect(valid14d.body.data.beaconType).toBe("TRAVELING");

      const tooLong = await request(app)
        .post("/api/radar/beacons")
        .set("Authorization", athlete2Token)
        .send({
          beaconType: "TRAVELING",
          title: "Too Long Beacon",
          latitude: 33.6844,
          longitude: 73.0479,
          durationHours: 500,
        });
      expect(tooLong.status).toBe(400);
    });
  });
});
