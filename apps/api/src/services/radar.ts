import { eq, and, gt, isNotNull, ne, inArray } from "drizzle-orm";
import { db } from "../config/db.js";
import {
  athleteProfiles,
  athleteClubs,
  athleteVerifications,
  events,
  venuePartners,
  informalEvents,
  radarBeacons,
  sanctions,
  users,
} from "@armsphere/db-schema";
import { BadRequestError, ForbiddenError, NotFoundError } from "@armsphere/core";
import {
  fuzzCoordinates,
  generateLocationFuzzSeed,
  normalizeLocationVisibility,
} from "./locationPrivacy.js";

export type RadarPinType =
  | "EVENT"
  | "VENUE"
  | "ATHLETE"
  | "BEACON"
  | "CLUB"
  | "INFORMAL_EVENT";

export interface RadarBounds {
  north: number;
  south: number;
  east: number;
  west: number;
}

export interface NearbyRadarQuery {
  bounds: RadarBounds;
  pinType?: RadarPinType | "ALL";
  weightClass?: string;
  armPreference?: string;
  limit?: number;
  viewerUserId: string;
}

export interface CreateBeaconInput {
  beaconType: string;
  title: string;
  latitude: number;
  longitude: number;
  weightClass?: string;
  armPreference?: string;
  expiresAt?: Date;
  durationHours?: number;
}

function isWithinBounds(lat: number, lng: number, bounds: RadarBounds): boolean {
  if (!Number.isFinite(lat) || !Number.isFinite(lng)) return false;
  if (lat < bounds.south || lat > bounds.north) return false;
  if (bounds.west <= bounds.east) {
    return lng >= bounds.west && lng <= bounds.east;
  }
  // Antimeridian crossing
  return lng >= bounds.west || lng <= bounds.east;
}

function matchesFilter(value: string | null | undefined, filter?: string): boolean {
  if (!filter || filter.trim().length === 0) return true;
  if (!value) return false;
  return value.trim().toLowerCase() === filter.trim().toLowerCase();
}

function matchesArmPreference(
  dominantArm: string | null | undefined,
  handedness: string | null | undefined,
  filter?: string
): boolean {
  if (!filter || filter.trim().length === 0) return true;
  const target = filter.trim().toUpperCase();
  if (target === "BOTH" || target === "AMBIDEXTROUS") return true;
  const dom = (dominantArm ?? "").trim().toUpperCase();
  const hand = (handedness ?? "").trim().toUpperCase();
  return dom === target || hand === target || dom === "AMBIDEXTROUS" || hand === "AMBIDEXTROUS";
}

export class RadarService {
  /**
   * Returns all spatial pins within a bounding box, applying strict privacy
   * enforcement on athletes (deterministic 0.5-1.5km fuzzing for AREA, hidden
   * home base for TRAVEL_ONLY, fully hidden for GHOST) while keeping public
   * events, venues, clubs, and informal meetups at exact coordinates.
   */
  static async getNearby(query: NearbyRadarQuery) {
    const { bounds, pinType = "ALL", weightClass, armPreference, limit = 200 } = query;

    if (bounds.north < bounds.south) {
      throw new BadRequestError("Bounding box 'north' must be greater than or equal to 'south'.");
    }

    const want = (t: RadarPinType) => pinType === "ALL" || pinType === t;
    const now = new Date();

    const eventPins: any[] = [];
    const venuePins: any[] = [];
    const clubPins: any[] = [];
    const informalEventPins: any[] = [];
    const athletePins: any[] = [];
    const beaconPins: any[] = [];

    // 1. Published / active tournaments (never DRAFT or CANCELLED, exact un-fuzzed coordinates)
    if (want("EVENT")) {
      const allEvents = await db
        .select()
        .from(events)
        .where(
          and(
            isNotNull(events.latitude),
            isNotNull(events.longitude),
            ne(events.status, "DRAFT"),
            ne(events.status, "CANCELLED")
          )
        );

      for (const evt of allEvents) {
        if (typeof evt.latitude !== "number" || typeof evt.longitude !== "number") continue;
        if (!isWithinBounds(evt.latitude, evt.longitude, bounds)) continue;
        eventPins.push({
          id: evt.id,
          pinType: "EVENT" as const,
          title: evt.name,
          subtitle: `${evt.venue}, ${evt.city}`,
          latitude: evt.latitude,
          longitude: evt.longitude,
          city: evt.city,
          province: evt.province,
          venue: evt.venue,
          status: evt.status,
          startDate: evt.startDate,
          endDate: evt.endDate,
          capacity: evt.capacity,
          isFuzzed: false,
        });
      }
    }

    // 2. Venue partners (exact un-fuzzed coordinates)
    if (want("VENUE")) {
      const allVenues = await db
        .select()
        .from(venuePartners)
        .where(and(isNotNull(venuePartners.latitude), isNotNull(venuePartners.longitude)));

      for (const v of allVenues) {
        if (typeof v.latitude !== "number" || typeof v.longitude !== "number") continue;
        if (!isWithinBounds(v.latitude, v.longitude, bounds)) continue;
        venuePins.push({
          id: v.id,
          pinType: "VENUE" as const,
          title: v.name,
          subtitle: v.address,
          latitude: v.latitude,
          longitude: v.longitude,
          city: v.city,
          province: v.province,
          address: v.address,
          isVerified: v.isVerified,
          logoUrl: v.logoUrl || null,
          isFuzzed: false,
        });
      }
    }

    // 3. Athlete clubs / gyms (exact un-fuzzed coordinates)
    if (want("CLUB")) {
      const allClubs = await db
        .select()
        .from(athleteClubs)
        .where(
          and(
            eq(athleteClubs.isDeleted, false),
            isNotNull(athleteClubs.latitude),
            isNotNull(athleteClubs.longitude)
          )
        );

      for (const c of allClubs) {
        if (typeof c.latitude !== "number" || typeof c.longitude !== "number") continue;
        if (!isWithinBounds(c.latitude, c.longitude, bounds)) continue;
        clubPins.push({
          id: c.id,
          pinType: "CLUB" as const,
          title: c.name,
          subtitle: `${c.city}, ${c.province}`,
          latitude: c.latitude,
          longitude: c.longitude,
          city: c.city,
          province: c.province,
          isFuzzed: false,
        });
      }
    }

    // 4. Upcoming public informal sparring meetups (exact coordinates)
    if (want("INFORMAL_EVENT")) {
      const allInformal = await db
        .select()
        .from(informalEvents)
        .where(
          and(
            eq(informalEvents.isPublic, true),
            gt(informalEvents.scheduledAt, now),
            isNotNull(informalEvents.latitude),
            isNotNull(informalEvents.longitude)
          )
        );

      for (const ie of allInformal) {
        if (typeof ie.latitude !== "number" || typeof ie.longitude !== "number") continue;
        if (!isWithinBounds(ie.latitude, ie.longitude, bounds)) continue;
        informalEventPins.push({
          id: ie.id,
          pinType: "INFORMAL_EVENT" as const,
          title: ie.title,
          subtitle: `${ie.city}${ie.province ? `, ${ie.province}` : ""}`,
          latitude: ie.latitude,
          longitude: ie.longitude,
          city: ie.city,
          province: ie.province || null,
          scheduledAt: ie.scheduledAt,
          maxParticipants: ie.maxParticipants || null,
          isFuzzed: false,
        });
      }
    }

    // Fetch athlete profiles + moderation status once if needed for athlete pins OR beacons
    let allProfiles: any[] = [];
    const excludedUserIds = new Set<string>();
    if (want("ATHLETE") || want("BEACON")) {
      const [profilesRows, verificationRows, userRows, sanctionRows] = await Promise.all([
        db
          .select()
          .from(athleteProfiles)
          .where(eq(athleteProfiles.isDeleted, false)),
        db.select().from(athleteVerifications).catch(() => []),
        db
          .select({ id: users.id, isActive: users.isActive })
          .from(users)
          .catch(() => []),
        db.select().from(sanctions).catch(() => []),
      ]);

      allProfiles = profilesRows;

      for (const u of userRows as any[]) {
        if (u && u.isActive === false) {
          excludedUserIds.add(u.id);
        }
      }
      for (const v of verificationRows as any[]) {
        const status = (v?.status || "").toString().toUpperCase();
        if (status === "REJECTED" || status === "SUSPENDED") {
          if (v.athleteId) excludedUserIds.add(v.athleteId);
        }
      }
      for (const s of sanctionRows as any[]) {
        const sType = (s?.type || "").toString().toUpperCase();
        const isActiveSanction =
          !s?.expiresAt || new Date(s.expiresAt).getTime() > now.getTime();
        if (
          isActiveSanction &&
          (sType === "SUSPENSION" || sType === "PERMANENT_BAN" || sType === "BAN")
        ) {
          if (s.userId) excludedUserIds.add(s.userId);
        }
      }
    }

    const profileByUserId = new Map<string, any>();
    for (const p of allProfiles) {
      profileByUserId.set(p.userId, p);
    }

    // 5. Privacy-filtered, deterministically fuzzed athlete home-base pins
    if (want("ATHLETE")) {
      for (const p of allProfiles) {
        if (excludedUserIds.has(p.userId) || excludedUserIds.has(p.id)) continue;
        if (p.isSearchable === false) continue;
        if (typeof p.latitude !== "number" || typeof p.longitude !== "number") continue;

        const visibility = normalizeLocationVisibility(p.locationVisibility);
        // Only AREA athletes appear as home-base pins on Radar.
        // TRAVEL_ONLY hides home base; GHOST returns no coordinates whatsoever.
        if (visibility !== "AREA") continue;

        if (!matchesFilter(p.weightClass, weightClass)) continue;
        if (!matchesArmPreference(p.dominantArm, p.handedness, armPreference)) continue;

        const seed =
          typeof p.locationFuzzSeed === "string" && p.locationFuzzSeed.length > 0
            ? p.locationFuzzSeed
            : generateLocationFuzzSeed(p.userId);
        const fuzzed = fuzzCoordinates(p.latitude, p.longitude, seed);

        // Evaluate bounding box against FUZZED coordinates so exact position cannot be inferred
        if (!isWithinBounds(fuzzed.latitude, fuzzed.longitude, bounds)) continue;

        athletePins.push({
          id: p.id,
          userId: p.userId,
          pinType: "ATHLETE" as const,
          title: p.displayName,
          subtitle: `${p.weightClass} • ${p.city}, ${p.province}`,
          latitude: fuzzed.latitude,
          longitude: fuzzed.longitude,
          city: p.city,
          province: p.province,
          weightClass: p.weightClass,
          dominantArm: p.dominantArm,
          handedness: p.handedness,
          rightArmElo: p.rightArmElo ?? 1000,
          leftArmElo: p.leftArmElo ?? 1000,
          profilePhoto: p.profilePhoto || null,
          locationVisibility: visibility,
          isFuzzed: true,
        });
      }
    }

    // 6. Active, non-expired temporary radar beacons
    if (want("BEACON")) {
      const activeBeacons = await db
        .select()
        .from(radarBeacons)
        .where(gt(radarBeacons.expiresAt, now));

      for (const b of activeBeacons) {
        if (excludedUserIds.has(b.userId)) continue;
        if (typeof b.latitude !== "number" || typeof b.longitude !== "number") continue;
        if (!isWithinBounds(b.latitude, b.longitude, bounds)) continue;

        const ownerProfile = profileByUserId.get(b.userId);
        // Enforce GHOST privacy mode: GHOST users return no coordinates whatsoever
        if (ownerProfile && normalizeLocationVisibility(ownerProfile.locationVisibility) === "GHOST") {
          continue;
        }

        const effectiveWeight = b.weightClass || ownerProfile?.weightClass || null;
        const effectiveArm = b.armPreference || ownerProfile?.dominantArm || null;

        if (!matchesFilter(effectiveWeight, weightClass)) continue;
        if (!matchesArmPreference(effectiveArm, ownerProfile?.handedness, armPreference)) continue;

        beaconPins.push({
          id: b.id,
          userId: b.userId,
          pinType: "BEACON" as const,
          beaconType: b.beaconType,
          title: b.title,
          subtitle: ownerProfile?.displayName || "Active Puller Beacon",
          latitude: b.latitude,
          longitude: b.longitude,
          weightClass: effectiveWeight,
          armPreference: effectiveArm,
          expiresAt: b.expiresAt,
          createdAt: b.createdAt,
          athleteName: ownerProfile?.displayName || null,
          isFuzzed: false,
        });
      }
    }

    const pins = [
      ...eventPins,
      ...venuePins,
      ...clubPins,
      ...informalEventPins,
      ...beaconPins,
      ...athletePins,
    ].slice(0, limit);

    return {
      bounds,
      counts: {
        total: pins.length,
        events: eventPins.length,
        venues: venuePins.length,
        clubs: clubPins.length,
        informalEvents: informalEventPins.length,
        athletes: athletePins.length,
        beacons: beaconPins.length,
      },
      pins,
      events: eventPins,
      venues: venuePins,
      clubs: clubPins,
      informalEvents: informalEventPins,
      athletes: athletePins,
      beacons: beaconPins,
    };
  }

  /**
   * Drops a temporary radar beacon for the authenticated user.
   */
  static async createBeacon(userId: string, input: CreateBeaconInput) {
    const [user] = await db.select().from(users).where(eq(users.id, userId)).limit(1);
    if (!user) {
      throw new NotFoundError("User account not found.");
    }

    const now = new Date();
    let expiresAt: Date;
    if (typeof input.durationHours === "number" && Number.isFinite(input.durationHours)) {
      const hours = Math.min(336, Math.max(1, input.durationHours));
      expiresAt = new Date(now.getTime() + hours * 60 * 60 * 1000);
    } else if (input.expiresAt) {
      expiresAt = input.expiresAt;
    } else {
      expiresAt = new Date(now.getTime() + 6 * 60 * 60 * 1000);
    }

    if (isNaN(expiresAt.getTime()) || expiresAt <= now) {
      throw new BadRequestError("Beacon expiration timestamp must be in the future.");
    }

    const [created] = await db
      .insert(radarBeacons)
      .values({
        userId,
        beaconType: input.beaconType.trim().toUpperCase(),
        title: input.title.trim(),
        latitude: input.latitude,
        longitude: input.longitude,
        weightClass: input.weightClass?.trim() || null,
        armPreference: input.armPreference?.trim().toUpperCase() || null,
        expiresAt,
      })
      .returning();

    return created;
  }

  /**
   * Deletes an existing radar beacon after enforcing ownership (or admin privilege).
   */
  static async deleteBeacon(beaconId: string, actorUserId: string, actorRole?: string) {
    const [existing] = await db
      .select()
      .from(radarBeacons)
      .where(eq(radarBeacons.id, beaconId))
      .limit(1);

    if (!existing) {
      throw new NotFoundError("Radar beacon not found.");
    }

    const isOwner = existing.userId === actorUserId;
    const isAdmin = Boolean(
      actorRole && ["SYSTEM_ADMIN", "NATIONAL_DIRECTOR"].includes(actorRole.toUpperCase())
    );

    if (!isOwner && !isAdmin) {
      throw new ForbiddenError("You are not authorized to delete this radar beacon.");
    }

    await db.delete(radarBeacons).where(eq(radarBeacons.id, beaconId));
    return { success: true, id: beaconId };
  }
}
