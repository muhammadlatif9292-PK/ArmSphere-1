import crypto from "crypto";
import { env } from "../config/env.js";

export type LocationVisibilityMode = "AREA" | "TRAVEL_ONLY" | "GHOST";

export const VALID_LOCATION_VISIBILITIES: readonly LocationVisibilityMode[] = [
  "AREA",
  "TRAVEL_ONLY",
  "GHOST",
] as const;

const EARTH_METERS_PER_DEGREE_LAT = 111_320;
const MIN_FUZZ_RADIUS_METERS = 500;
const MAX_FUZZ_RADIUS_METERS = 1500;

/**
 * Generates a deterministic, non-reversible server-side seed for fuzzing an
 * athlete's public home-base coordinates. Because it is keyed with the server
 * secret via HMAC-SHA256, clients cannot predict or invert the offset.
 */
export function generateLocationFuzzSeed(userId: string): string {
  const secret = `${env.JWT_ACCESS_SECRET}:armsphere:location_fuzz:v1`;
  return crypto
    .createHmac("sha256", secret)
    .update(userId)
    .digest("hex");
}

/**
 * Normalizes any visibility string to a valid LocationVisibilityMode (defaulting to AREA).
 */
export function normalizeLocationVisibility(value?: string | null): LocationVisibilityMode {
  const upper = (value ?? "").trim().toUpperCase();
  if (upper === "TRAVEL_ONLY") return "TRAVEL_ONLY";
  if (upper === "GHOST") return "GHOST";
  return "AREA";
}

/**
 * Deterministically offsets (latitude, longitude) by a consistent 0.5–1.5 km
 * displacement derived solely from `seed`. Calling this multiple times for the
 * same athlete and coordinates always yields the exact same fuzzed point so
 * repeated requests cannot triangulate or average out the true location.
 */
export function fuzzCoordinates(
  latitude: number,
  longitude: number,
  seed: string
): { latitude: number; longitude: number } {
  const digest = crypto.createHash("sha256").update(seed).digest();

  // First 4 bytes -> angle in [0, 2*PI)
  const angleInt = digest.readUInt32BE(0);
  const angleRad = (angleInt / 0xffffffff) * 2 * Math.PI;

  // Next 4 bytes -> radius in [500m, 1500m]
  const radiusInt = digest.readUInt32BE(4);
  const radiusMeters =
    MIN_FUZZ_RADIUS_METERS +
    (radiusInt / 0xffffffff) * (MAX_FUZZ_RADIUS_METERS - MIN_FUZZ_RADIUS_METERS);

  const deltaLat = (radiusMeters * Math.cos(angleRad)) / EARTH_METERS_PER_DEGREE_LAT;
  const latRad = (latitude * Math.PI) / 180;
  const cosLat = Math.max(0.1, Math.cos(latRad));
  const deltaLng =
    (radiusMeters * Math.sin(angleRad)) / (EARTH_METERS_PER_DEGREE_LAT * cosLat);

  const fuzzedLat = Math.max(-90, Math.min(90, latitude + deltaLat));
  let fuzzedLng = longitude + deltaLng;
  if (fuzzedLng > 180) fuzzedLng -= 360;
  if (fuzzedLng < -180) fuzzedLng += 360;

  return {
    latitude: Math.round(fuzzedLat * 1e6) / 1e6,
    longitude: Math.round(fuzzedLng * 1e6) / 1e6,
  };
}

/**
 * Haversine distance in meters between two WGS-84 points.
 */
export function haversineDistanceMeters(
  lat1: number,
  lng1: number,
  lat2: number,
  lng2: number
): number {
  const R = 6_371_000;
  const toRad = (deg: number) => (deg * Math.PI) / 180;
  const dLat = toRad(lat2 - lat1);
  const dLng = toRad(lng2 - lng1);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLng / 2) * Math.sin(dLng / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

/**
 * Sanitizes an athlete profile record before returning it in any API response.
 * - Always strips `locationFuzzSeed` (internal secret-derived token).
 * - Owners (`viewerUserId === profile.userId`) receive their exact saved coordinates.
 * - Non-owners strictly obey `locationVisibility`:
 *   - `AREA`        -> returns deterministic 0.5–1.5 km fuzzed coordinates
 *   - `TRAVEL_ONLY` -> strips home-base coordinates (null)
 *   - `GHOST`       -> strips all coordinates (null)
 */
export function sanitizeAthleteLocationForViewer<T extends Record<string, any>>(
  profile: T,
  viewerUserId?: string
): Omit<T, "locationFuzzSeed"> {
  const safe: Record<string, any> = { ...profile };
  const seed: string =
    typeof safe.locationFuzzSeed === "string" && safe.locationFuzzSeed.length > 0
      ? safe.locationFuzzSeed
      : generateLocationFuzzSeed(String(safe.userId || safe.id || "anonymous"));

  delete safe.locationFuzzSeed;

  const isOwner = Boolean(viewerUserId && safe.userId && viewerUserId === safe.userId);
  const visibility = normalizeLocationVisibility(safe.locationVisibility);
  safe.locationVisibility = visibility;

  if (isOwner) {
    return safe as Omit<T, "locationFuzzSeed">;
  }

  if (visibility === "GHOST" || visibility === "TRAVEL_ONLY") {
    safe.latitude = null;
    safe.longitude = null;
    return safe as Omit<T, "locationFuzzSeed">;
  }

  // AREA visibility -> deterministic fuzzing
  if (
    typeof safe.latitude === "number" &&
    typeof safe.longitude === "number" &&
    Number.isFinite(safe.latitude) &&
    Number.isFinite(safe.longitude)
  ) {
    const fuzzed = fuzzCoordinates(safe.latitude, safe.longitude, seed);
    safe.latitude = fuzzed.latitude;
    safe.longitude = fuzzed.longitude;
  } else {
    safe.latitude = null;
    safe.longitude = null;
  }

  return safe as Omit<T, "locationFuzzSeed">;
}
