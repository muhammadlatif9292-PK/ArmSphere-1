import { eq, and, ilike, or, SQL, desc, notInArray, inArray, sql } from "drizzle-orm";
import { db } from "../config/db.js";
import { 
  users, 
  athleteProfiles, 
  athleteClubs, 
  athleteVerifications, 
  athleteDocuments, 
  athleteBiometrics, 
  athleteMeasurements, 
  athleteSocialLinks, 
  athleteProfileHistory,
  auditLogs,
  blockedUsers,
  tournamentMatches,
  matches,
  championshipTitles
} from "@armsphere/db-schema";
import { 
  NotFoundError, 
  BadRequestError, 
  ForbiddenError, 
  ConflictError, 
  logger 
} from "@armsphere/core";
import { UserRole } from "@armsphere/types";
import {
  generateLocationFuzzSeed,
  normalizeLocationVisibility,
  sanitizeAthleteLocationForViewer,
} from "./locationPrivacy.js";

export interface CreateProfileInput {
  displayName: string;
  biography?: string;
  province: string;
  city: string;
  clubId?: string;
  handedness: string;
  dominantArm: string;
  dateOfBirth: string; // ISO string
  gender: string;
  weightClass: string;
  height?: number;
  weight?: number;
  reach?: number;
  profilePhoto?: string;
  latitude?: number | null;
  longitude?: number | null;
  locationVisibility?: string;
}

export interface UpdateProfileInput {
  displayName?: string;
  biography?: string;
  province?: string;
  city?: string;
  clubId?: string | null;
  handedness?: string;
  dominantArm?: string;
  dateOfBirth?: string;
  gender?: string;
  weightClass?: string;
  height?: number;
  weight?: number;
  reach?: number;
  profilePhoto?: string;
  profileVisibility?: string;
  isSearchable?: boolean;
  latitude?: number | null;
  longitude?: number | null;
  locationVisibility?: string;
}

export class AthleteService {
  /**
   * Helper to ensure athlete_verification record exists with default UNVERIFIED status
   */
  private static async ensureVerificationRecord(athleteId: string) {
    const [existing] = await db
      .select()
      .from(athleteVerifications)
      .where(eq(athleteVerifications.athleteId, athleteId))
      .limit(1);

    if (!existing) {
      await db.insert(athleteVerifications).values({
        athleteId,
        status: "UNVERIFIED",
      });
    }
  }

  /**
   * Create standard athlete profile
   */
  static async createProfile(userId: string, input: CreateProfileInput, ipAddress?: string, userAgent?: string) {
    // 1. Verify user exists
    const [user] = await db
      .select()
      .from(users)
      .where(eq(users.id, userId))
      .limit(1);

    if (!user) {
      throw new NotFoundError("User account not found");
    }

    // 2. Ensure profile doesn't already exist
    const [existing] = await db
      .select()
      .from(athleteProfiles)
      .where(eq(athleteProfiles.userId, userId))
      .limit(1);

    if (existing) {
      throw new ConflictError("Athlete profile already exists for this user. Use PATCH instead.");
    }

    // 3. Insert profile
    const [profile] = await db
      .insert(athleteProfiles)
      .values({
        userId,
        displayName: input.displayName,
        biography: input.biography,
        province: input.province,
        city: input.city,
        clubId: input.clubId || null,
        handedness: input.handedness,
        dominantArm: input.dominantArm,
        dateOfBirth: new Date(input.dateOfBirth),
        gender: input.gender,
        weightClass: input.weightClass,
        height: input.height || null,
        weight: input.weight || null,
        reach: input.reach || null,
        profilePhoto: input.profilePhoto || null,
        latitude: input.latitude ?? null,
        longitude: input.longitude ?? null,
        locationVisibility: normalizeLocationVisibility(input.locationVisibility),
        locationFuzzSeed: generateLocationFuzzSeed(userId),
      })
      .returning();

    // 4. Initialize supporting structures
    await this.ensureVerificationRecord(userId);

    // Initial Biometrics entry
    await db.insert(athleteBiometrics).values({
      athleteId: userId,
    });

    // Initial Measurements entry
    await db.insert(athleteMeasurements).values({
      athleteId: userId,
      height: input.height || null,
      weight: input.weight || null,
      reach: input.reach || null,
    });

    // Initial Social Links entry
    await db.insert(athleteSocialLinks).values({
      athleteId: userId,
    });

    // 5. Audit Logging
    await db.insert(auditLogs).values({
      userId,
      action: "ATHLETE_PROFILE_CREATE",
      details: { profileId: profile.id, displayName: profile.displayName },
      ipAddress,
      userAgent,
    });

    // 6. Push history record
    await db.insert(athleteProfileHistory).values({
      athleteId: userId,
      changedBy: userId,
      oldData: null,
      newData: profile,
    });

    return sanitizeAthleteLocationForViewer(profile, userId);
  }

  /**
   * Retrieve complete athlete profile aggregated with verification status, biometrics, measurements, and social links
   *
   * Accepts either an auth user id (self flows) or an athlete profile id
   * (search / leaderboard / social list rows carry profile ids) so that
   * profile navigation works from every surface.
   */
  static async getProfileByUserId(userIdOrProfileId: string, viewerUserId?: string, viewerRole?: string) {
    let [profile] = await db
      .select()
      .from(athleteProfiles)
      .where(and(eq(athleteProfiles.userId, userIdOrProfileId), eq(athleteProfiles.isDeleted, false)))
      .limit(1);

    const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
    if (!profile && UUID_RE.test(userIdOrProfileId)) {
      [profile] = await db
        .select()
        .from(athleteProfiles)
        .where(and(eq(athleteProfiles.id, userIdOrProfileId), eq(athleteProfiles.isDeleted, false)))
        .limit(1);
    }

    if (!profile) {
      throw new NotFoundError("Athlete profile not found");
    }

    // Supporting tables are keyed by the owner's auth user id
    const ownerUserId = profile.userId;

    if (viewerUserId && viewerUserId !== ownerUserId) {
      if (profile.profileVisibility === "GYM_ONLY") {
        // Fetch viewer's profile to check their clubId
        const [viewerProfile] = await db
          .select()
          .from(athleteProfiles)
          .where(eq(athleteProfiles.userId, viewerUserId))
          .limit(1);

        if (!viewerProfile || !profile.clubId || viewerProfile.clubId !== profile.clubId) {
          throw new ForbiddenError("You cannot view this profile because it is set to Gym-only visibility.");
        }
      }
    }

    const candidateIds = Array.from(new Set([profile.id, profile.userId].filter(Boolean)));

    // Fetch all supporting tables + match history in parallel instead of 8 sequential round trips
    const [
      clubRows,
      verificationRows,
      biometricsRows,
      measurementsRows,
      socialsRows,
      verifiedMatches,
      completedTourneyMatches,
      activeTitles,
    ] = await Promise.all([
      profile.clubId
        ? db
            .select()
            .from(athleteClubs)
            .where(eq(athleteClubs.id, profile.clubId))
            .limit(1)
            .catch(() => [])
        : Promise.resolve([]),
      db
        .select()
        .from(athleteVerifications)
        .where(eq(athleteVerifications.athleteId, ownerUserId))
        .limit(1)
        .catch(() => []),
      db
        .select()
        .from(athleteBiometrics)
        .where(eq(athleteBiometrics.athleteId, ownerUserId))
        .limit(1)
        .catch(() => []),
      db
        .select()
        .from(athleteMeasurements)
        .where(eq(athleteMeasurements.athleteId, ownerUserId))
        .limit(1)
        .catch(() => []),
      db
        .select()
        .from(athleteSocialLinks)
        .where(eq(athleteSocialLinks.athleteId, ownerUserId))
        .limit(1)
        .catch(() => []),
      db
        .select()
        .from(matches)
        .where(
          and(
            or(
              inArray(matches.challengerId, candidateIds),
              inArray(matches.opponentId, candidateIds)
            ),
            inArray(matches.status, ["VERIFIED", "COMPLETED"])
          )
        )
        .catch(() => []),
      db
        .select()
        .from(tournamentMatches)
        .where(
          and(
            or(
              inArray(tournamentMatches.athleteAId, candidateIds),
              inArray(tournamentMatches.athleteBId, candidateIds)
            ),
            inArray(tournamentMatches.status, ["COMPLETED", "VERIFIED"])
          )
        )
        .catch(() => []),
      db
        .select()
        .from(championshipTitles)
        .where(eq(championshipTitles.activeChampionId, profile.id))
        .catch(() => []),
    ]);

    const club = clubRows[0] || null;
    const verification = verificationRows[0] || null;
    const biometrics = biometricsRows[0] || null;
    const measurements = measurementsRows[0] || null;
    const socials = socialsRows[0] || null;

    let wins = 0;
    let losses = 0;
    let rightArmWins = 0;
    let rightArmLosses = 0;
    let leftArmWins = 0;
    let leftArmLosses = 0;
    const seenMatchIds = new Set<string>();

    for (const m of verifiedMatches as any[]) {
      seenMatchIds.add(m.id);
      const arm = ((m as any).arm || "RIGHT").toString().toUpperCase();
      const isWinner = m.winnerId ? candidateIds.includes(m.winnerId) : false;
      if (isWinner) {
        wins++;
        if (arm === "LEFT") leftArmWins++;
        else rightArmWins++;
      } else if (m.winnerId) {
        losses++;
        if (arm === "LEFT") leftArmLosses++;
        else rightArmLosses++;
      }
    }

    for (const tm of completedTourneyMatches as any[]) {
      if (seenMatchIds.has(tm.id)) continue;
      seenMatchIds.add(tm.id);
      const arm = ((tm as any).arm || "RIGHT").toString().toUpperCase();
      const isWinner = tm.winnerId ? candidateIds.includes(tm.winnerId) : false;
      if (isWinner) {
        wins++;
        if (arm === "LEFT") leftArmWins++;
        else rightArmWins++;
      } else if (tm.winnerId) {
        losses++;
        if (arm === "LEFT") leftArmLosses++;
        else rightArmLosses++;
      }
    }

    const titlesCount = (activeTitles as any[]).length;

    const totalRight = rightArmWins + rightArmLosses;
    const totalLeft = leftArmWins + leftArmLosses;
    const totalAll = wins + losses;
    const winRateRight = totalRight > 0 ? Math.round((rightArmWins / totalRight) * 1000) / 10 : 0;
    const winRateLeft = totalLeft > 0 ? Math.round((leftArmWins / totalLeft) * 1000) / 10 : 0;
    const winRate = totalAll > 0 ? Math.round((wins / totalAll) * 1000) / 10 : 0;

    const isOwner = viewerUserId === ownerUserId;
    const isPrivileged = !!(viewerRole && ["SYSTEM_ADMIN", "NATIONAL_DIRECTOR", "PROVINCIAL_DIRECTOR"].includes(viewerRole.toUpperCase()));

    const safeProfile = sanitizeAthleteLocationForViewer(profile, viewerUserId);
    if (!isOwner) {
      delete (safeProfile as any).stripeCustomerId;
    }

    return {
      ...safeProfile,
      wins,
      losses,
      rightArmWins,
      rightArmLosses,
      leftArmWins,
      leftArmLosses,
      winRateRight,
      winRateLeft,
      winRate,
      titlesCount,
      club,
      verificationStatus: verification?.status || "UNVERIFIED",
      rejectionReason: (isOwner || isPrivileged) ? (verification?.rejectionReason || null) : null,
      biometrics: biometrics || null,
      measurements: measurements || null,
      socialLinks: socials || null,
    };
  }

  /**
   * Resolve an identifier that may be an auth userId or an athlete profileId to the canonical userId
   */
  static async resolveUserId(athleteIdOrUserId: string): Promise<string> {
    const [profile] = await db
      .select({ userId: athleteProfiles.userId })
      .from(athleteProfiles)
      .where(
        and(
          or(eq(athleteProfiles.id, athleteIdOrUserId), eq(athleteProfiles.userId, athleteIdOrUserId)),
          eq(athleteProfiles.isDeleted, false)
        )
      )
      .limit(1);
    return profile?.userId ?? athleteIdOrUserId;
  }

  /**
   * Update profile with historical audit trail and conflict resolution support
   */
  static async updateProfile(
    userId: string,
    targetUserId: string,
    input: UpdateProfileInput,
    role: string,
    ipAddress?: string,
    userAgent?: string
  ) {
    // :id may be an auth user id (legacy/self flows) or an athlete profile id
    // (search / leaderboard / social rows carry profile ids). Resolve to the
    // owner's auth user id first so owner edits via profileId succeed.
    const resolvedUserId = await this.resolveUserId(targetUserId);

    // 1. Ownership & Role check: Only profile owner or an Admin/Director can update it
    if (userId !== resolvedUserId && !["system_admin", "national_director", "provincial_director"].includes(role.toLowerCase())) {
      throw new ForbiddenError("You are not authorized to update this profile");
    }

    // 2. Retrieve existing profile
    const [existingProfile] = await db
      .select()
      .from(athleteProfiles)
      .where(and(eq(athleteProfiles.userId, resolvedUserId), eq(athleteProfiles.isDeleted, false)))
      .limit(1);

    if (!existingProfile) {
      throw new NotFoundError("Athlete profile not found");
    }

    // For PROVINCIAL_DIRECTOR updating another user's profile, enforce provincial jurisdiction
    if (userId !== resolvedUserId && role.toLowerCase() === "provincial_director") {
      const [actor] = await db.select().from(users).where(eq(users.id, userId)).limit(1);
      const actorProvince = (actor as any)?.province || (actor as any)?.regionalCoverage;
      if (!actorProvince || existingProfile.province.trim().toUpperCase() !== actorProvince.trim().toUpperCase()) {
        throw new ForbiddenError("You can only update athlete profiles within your provincial jurisdiction.");
      }
    }

    // 3. Compile update data
    const updatePayload: any = {};
    if (input.displayName !== undefined) updatePayload.displayName = input.displayName;
    if (input.biography !== undefined) updatePayload.biography = input.biography;
    if (input.province !== undefined) updatePayload.province = input.province;
    if (input.city !== undefined) updatePayload.city = input.city;
    if (input.clubId !== undefined) updatePayload.clubId = input.clubId;
    if (input.handedness !== undefined) updatePayload.handedness = input.handedness;
    if (input.dominantArm !== undefined) updatePayload.dominantArm = input.dominantArm;
    if (input.dateOfBirth !== undefined) updatePayload.dateOfBirth = new Date(input.dateOfBirth);
    if (input.gender !== undefined) updatePayload.gender = input.gender;
    if (input.weightClass !== undefined) updatePayload.weightClass = input.weightClass;
    if (input.height !== undefined) updatePayload.height = input.height;
    if (input.weight !== undefined) updatePayload.weight = input.weight;
    if (input.reach !== undefined) updatePayload.reach = input.reach;
    if (input.profilePhoto !== undefined) updatePayload.profilePhoto = input.profilePhoto;
    if (input.profileVisibility !== undefined) updatePayload.profileVisibility = input.profileVisibility;
    if (input.isSearchable !== undefined) updatePayload.isSearchable = input.isSearchable;
    if (input.latitude !== undefined) updatePayload.latitude = input.latitude;
    if (input.longitude !== undefined) updatePayload.longitude = input.longitude;
    if (input.locationVisibility !== undefined) {
      updatePayload.locationVisibility = normalizeLocationVisibility(input.locationVisibility);
    }
    if (!existingProfile.locationFuzzSeed) {
      updatePayload.locationFuzzSeed = generateLocationFuzzSeed(resolvedUserId);
    }

    updatePayload.updatedAt = new Date();

    // 4. Update the database record
    const [updatedProfile] = await db
      .update(athleteProfiles)
      .set(updatePayload)
      .where(eq(athleteProfiles.userId, resolvedUserId))
      .returning();

    // Update measurements as well if profile physicals are modified
    if (input.height !== undefined || input.weight !== undefined || input.reach !== undefined) {
      const [existingMeasurement] = await db
        .select()
        .from(athleteMeasurements)
        .where(eq(athleteMeasurements.athleteId, resolvedUserId))
        .limit(1);

      if (existingMeasurement) {
        await db
          .update(athleteMeasurements)
          .set({
            height: input.height !== undefined ? input.height : existingMeasurement.height,
            weight: input.weight !== undefined ? input.weight : existingMeasurement.weight,
            reach: input.reach !== undefined ? input.reach : existingMeasurement.reach,
            updatedAt: new Date(),
          })
          .where(eq(athleteMeasurements.athleteId, resolvedUserId));
      }
    }

    // 5. Track History
    await db.insert(athleteProfileHistory).values({
      athleteId: resolvedUserId,
      changedBy: userId,
      oldData: existingProfile,
      newData: updatedProfile,
    });

    // 6. Audit Logging
    await db.insert(auditLogs).values({
      userId,
      action: "ATHLETE_PROFILE_UPDATE",
      details: { profileId: updatedProfile.id, updatedFields: Object.keys(updatePayload) },
      ipAddress,
      userAgent,
    });

    return sanitizeAthleteLocationForViewer(updatedProfile, userId);
  }

  /**
   * Update profile visibility and searchability preferences
   */
  static async updateVisibility(
    userId: string,
    input: { profileVisibility?: string; isSearchable?: boolean; locationVisibility?: string },
    ipAddress?: string,
    userAgent?: string
  ) {
    const [existingProfile] = await db
      .select()
      .from(athleteProfiles)
      .where(and(eq(athleteProfiles.userId, userId), eq(athleteProfiles.isDeleted, false)))
      .limit(1);

    if (!existingProfile) {
      throw new NotFoundError("Athlete profile not found");
    }

    const updatePayload: any = {};
    if (input.profileVisibility !== undefined) {
      updatePayload.profileVisibility = input.profileVisibility;
    }
    if (input.isSearchable !== undefined) {
      updatePayload.isSearchable = input.isSearchable;
    }
    if (input.locationVisibility !== undefined) {
      updatePayload.locationVisibility = normalizeLocationVisibility(input.locationVisibility);
    }
    if (!existingProfile.locationFuzzSeed) {
      updatePayload.locationFuzzSeed = generateLocationFuzzSeed(userId);
    }

    updatePayload.updatedAt = new Date();

    const [updatedProfile] = await db
      .update(athleteProfiles)
      .set(updatePayload)
      .where(eq(athleteProfiles.userId, userId))
      .returning();

    // Track History
    await db.insert(athleteProfileHistory).values({
      athleteId: userId,
      changedBy: userId,
      oldData: existingProfile,
      newData: updatedProfile,
    });

    // Audit Logging
    await db.insert(auditLogs).values({
      userId,
      action: "ATHLETE_PROFILE_VISIBILITY_UPDATE",
      details: {
        profileId: existingProfile.id,
        profileVisibility: input.profileVisibility,
        isSearchable: input.isSearchable,
        locationVisibility: updatePayload.locationVisibility,
      },
      ipAddress,
      userAgent,
    });

    return sanitizeAthleteLocationForViewer(updatedProfile, userId);
  }

  /**
   * Advanced High-Performance search over athletes
   */
  static async searchAthletes(filters: {
    displayName?: string;
    province?: string;
    clubId?: string;
    weightClass?: string;
    gender?: string;
    verificationStatus?: string;
    limit?: number;
    offset?: number;
    viewerUserId?: string;
  }) {
    const limit = filters.limit || 50;
    const offset = filters.offset || 0;

    // Join with verification table to allow status filtering
    let queryConditions: SQL[] = [eq(athleteProfiles.isDeleted, false)];

    if (filters.viewerUserId) {
      queryConditions.push(
        or(
          eq(athleteProfiles.isSearchable, true),
          eq(athleteProfiles.userId, filters.viewerUserId)
        ) as SQL
      );
    } else {
      queryConditions.push(eq(athleteProfiles.isSearchable, true));
    }

    if (filters.viewerUserId) {
      const [viewerProfile] = await db
        .select({ id: athleteProfiles.id })
        .from(athleteProfiles)
        .where(eq(athleteProfiles.userId, filters.viewerUserId))
        .limit(1);

      if (viewerProfile) {
        const blockedRelations = await db
          .select({
            blockedId: blockedUsers.blockedId,
            blockerId: blockedUsers.blockerId
          })
          .from(blockedUsers)
          .where(
            or(
              eq(blockedUsers.blockerId, viewerProfile.id),
              eq(blockedUsers.blockedId, viewerProfile.id)
            )
          );

        const excludedIds = blockedRelations.map(r => 
          r.blockerId === viewerProfile.id ? r.blockedId : r.blockerId
        );

        if (excludedIds.length > 0) {
          queryConditions.push(notInArray(athleteProfiles.id, excludedIds));
        }
      }
    }

    if (filters.displayName) {
      queryConditions.push(ilike(athleteProfiles.displayName, `%${filters.displayName.trim()}%`));
    }
    if (filters.province) {
      queryConditions.push(eq(athleteProfiles.province, filters.province));
    }
    if (filters.clubId) {
      queryConditions.push(eq(athleteProfiles.clubId, filters.clubId));
    }
    if (filters.weightClass) {
      queryConditions.push(eq(athleteProfiles.weightClass, filters.weightClass));
    }
    if (filters.gender) {
      queryConditions.push(eq(athleteProfiles.gender, filters.gender));
    }
    if (filters.verificationStatus) {
      queryConditions.push(eq(athleteVerifications.status, filters.verificationStatus));
    }

    // Build the query
    const results = await db
      .select({
        id: athleteProfiles.id,
        userId: athleteProfiles.userId,
        displayName: athleteProfiles.displayName,
        province: athleteProfiles.province,
        city: athleteProfiles.city,
        clubId: athleteProfiles.clubId,
        handedness: athleteProfiles.handedness,
        dominantArm: athleteProfiles.dominantArm,
        gender: athleteProfiles.gender,
        weightClass: athleteProfiles.weightClass,
        profilePhoto: athleteProfiles.profilePhoto,
        leftArmElo: athleteProfiles.leftArmElo,
        rightArmElo: athleteProfiles.rightArmElo,
        latitude: athleteProfiles.latitude,
        longitude: athleteProfiles.longitude,
        locationVisibility: athleteProfiles.locationVisibility,
        locationFuzzSeed: athleteProfiles.locationFuzzSeed,
        verificationStatus: athleteVerifications.status,
      })
      .from(athleteProfiles)
      .leftJoin(
        athleteVerifications,
        eq(athleteProfiles.userId, athleteVerifications.athleteId)
      )
      .where(and(...queryConditions))
      .limit(limit)
      .offset(offset)
      .orderBy(desc(athleteProfiles.createdAt));

    return results.map((r) => sanitizeAthleteLocationForViewer(r, filters.viewerUserId));
  }

  /**
   * Submit documents for manual federation review
   */
  static async submitForVerification(userId: string, documentType: string, fileKey: string, bucketName: string, sha256Hash: string) {
    // Save document details
    const [doc] = await db
      .insert(athleteDocuments)
      .values({
        athleteId: userId,
        documentType,
        fileKey,
        bucketName,
        sha256Hash,
      })
      .returning();

    // Transition verification status to PENDING
    await this.ensureVerificationRecord(userId);
    await db
      .update(athleteVerifications)
      .set({
        status: "PENDING",
        rejectionReason: null,
        updatedAt: new Date(),
      })
      .where(eq(athleteVerifications.athleteId, userId));

    // Audit logs entry
    await db.insert(auditLogs).values({
      userId,
      action: "ATHLETE_VERIFICATION_SUBMIT",
      details: { documentId: doc.id, documentType, fileKey },
    });

    return { success: true, status: "PENDING", documentId: doc.id };
  }

  /**
   * Federation manual review of athlete verification documents
   */
  static async reviewVerification(
    reviewerId: string,
    athleteId: string,
    status: "VERIFIED" | "REJECTED" | "SUSPENDED",
    rejectionReason?: string,
    ipAddress?: string,
    userAgent?: string
  ) {
    // 1. Verify reviewer exists
    const [reviewer] = await db.select().from(users).where(eq(users.id, reviewerId)).limit(1);
    if (!reviewer) {
      throw new NotFoundError("Reviewer user not found");
    }

    // 2. Resolve athlete profile by either userId or profileId
    let [profile] = await db
      .select()
      .from(athleteProfiles)
      .where(and(eq(athleteProfiles.userId, athleteId), eq(athleteProfiles.isDeleted, false)))
      .limit(1);

    if (!profile) {
      [profile] = await db
        .select()
        .from(athleteProfiles)
        .where(and(eq(athleteProfiles.id, athleteId), eq(athleteProfiles.isDeleted, false)))
        .limit(1);
    }

    if (!profile) {
      throw new NotFoundError("Athlete profile not found");
    }

    // 3. For PROVINCIAL_DIRECTOR, enforce provincial jurisdiction
    if (reviewer.role === UserRole.PROVINCIAL_DIRECTOR) {
      const reviewerProvince = (reviewer as any).province || (reviewer as any).regionalCoverage;
      if (!reviewerProvince || profile.province.trim().toUpperCase() !== reviewerProvince.trim().toUpperCase()) {
        throw new ForbiddenError("You can only review profiles within your provincial jurisdiction.");
      }
    }

    const targetUserId = profile.userId;

    // 4. Ensure verification record exists
    await this.ensureVerificationRecord(targetUserId);

    // 5. Update status
    const [updatedVerification] = await db
      .update(athleteVerifications)
      .set({
        status,
        reviewerId,
        rejectionReason: status === "REJECTED" ? rejectionReason || "Incomplete documentation" : null,
        updatedAt: new Date(),
      })
      .where(eq(athleteVerifications.athleteId, targetUserId))
      .returning();

    // 6. Audit trail
    await db.insert(auditLogs).values({
      userId: reviewerId,
      action: `ATHLETE_VERIFICATION_${status}`,
      details: { athleteId: targetUserId, profileId: profile.id, reviewerId, rejectionReason },
      ipAddress,
      userAgent,
    });

    return updatedVerification;
  }

  /**
   * Biometrics updates
   */
  static async updateBiometrics(userId: string, data: any) {
    const [existing] = await db
      .select()
      .from(athleteBiometrics)
      .where(eq(athleteBiometrics.athleteId, userId))
      .limit(1);

    if (!existing) {
      const [inserted] = await db
        .insert(athleteBiometrics)
        .values({
          athleteId: userId,
          ...data,
        })
        .returning();
      return inserted;
    }

    const [updated] = await db
      .update(athleteBiometrics)
      .set({
        ...data,
        updatedAt: new Date(),
      })
      .where(eq(athleteBiometrics.athleteId, userId))
      .returning();

    return updated;
  }

  /**
   * Create an athlete club
   */
  static async createClub(
    name: string,
    city: string,
    province: string,
    latitude?: number,
    longitude?: number
  ) {
    const [club] = await db
      .insert(athleteClubs)
      .values({
        name,
        city,
        province,
        latitude: latitude ?? null,
        longitude: longitude ?? null,
      })
      .returning();

    return club;
  }

  /**
   * Get all active clubs
   */
  static async getClubs() {
    return db
      .select()
      .from(athleteClubs)
      .where(eq(athleteClubs.isDeleted, false));
  }

  /**
   * Compare two athletes head-to-head with Tale of the Tape and win expectancy
   */
  static async compareAthletes(athlete1Id: string, athlete2Id: string) {
    if (!athlete1Id || !athlete2Id) {
      throw new BadRequestError("Both athlete1Id and athlete2Id are required for comparison");
    }

    const [athlete1, athlete2] = await Promise.all([
      AthleteService.getProfileByUserId(athlete1Id),
      AthleteService.getProfileByUserId(athlete2Id),
    ]);

    if (!athlete1 || !athlete2) {
      throw new NotFoundError("One or both athletes could not be found");
    }

    const a1Ids = Array.from(new Set([athlete1.id, athlete1.userId].filter(Boolean)));
    const a2Ids = Array.from(new Set([athlete2.id, athlete2.userId].filter(Boolean)));

    // Query both H2H sources concurrently
    const [tourneyH2H, sanctionedH2H] = await Promise.all([
      db
        .select()
        .from(tournamentMatches)
        .where(
          and(
            sql`(${tournamentMatches.athleteAId} = ${athlete1.id} AND ${tournamentMatches.athleteBId} = ${athlete2.id}) OR (${tournamentMatches.athleteAId} = ${athlete2.id} AND ${tournamentMatches.athleteBId} = ${athlete1.id})`,
            inArray(tournamentMatches.status, ["COMPLETED", "VERIFIED"])
          )
        )
        .catch(() => [] as any[]),
      db
        .select()
        .from(matches)
        .where(
          and(
            or(
              and(inArray(matches.challengerId, a1Ids), inArray(matches.opponentId, a2Ids)),
              and(inArray(matches.challengerId, a2Ids), inArray(matches.opponentId, a1Ids))
            ),
            inArray(matches.status, ["VERIFIED", "COMPLETED"])
          )
        )
        .catch(() => [] as any[]),
    ]);

    const seenIds = new Set<string>();
    const combinedH2H: any[] = [];
    for (const m of tourneyH2H) {
      if (m?.id) seenIds.add(m.id);
      combinedH2H.push({
        id: m.id,
        winnerId: m.winnerId,
        arm: (m.arm || "RIGHT").toUpperCase(),
        scoreLine: m.scoreLine || `${m.athleteAScore ?? 0}-${m.athleteBScore ?? 0}`,
        round: m.round ?? 1,
        bracketType: m.bracketType || "TOURNAMENT",
        date: m.updatedAt || m.createdAt,
      });
    }
    for (const m of sanctionedH2H) {
      if (m?.id && seenIds.has(m.id)) continue;
      if (m?.id) seenIds.add(m.id);
      combinedH2H.push({
        id: m.id,
        winnerId: m.winnerId,
        arm: ((m as any).arm || "RIGHT").toString().toUpperCase(),
        scoreLine: `${(m as any).challengerScore ?? 0}-${(m as any).opponentScore ?? 0}`,
        round: 1,
        bracketType: "SANCTIONED_BOUT",
        date: m.updatedAt || m.createdAt,
      });
    }

    let athlete1Wins = 0;
    let athlete2Wins = 0;
    let rightArmAthlete1Wins = 0;
    let rightArmAthlete2Wins = 0;
    let leftArmAthlete1Wins = 0;
    let leftArmAthlete2Wins = 0;

    for (const m of combinedH2H) {
      const arm = (m.arm || "RIGHT").toUpperCase();
      if (m.winnerId && a1Ids.includes(m.winnerId)) {
        athlete1Wins++;
        if (arm === "LEFT") leftArmAthlete1Wins++;
        else rightArmAthlete1Wins++;
      } else if (m.winnerId && a2Ids.includes(m.winnerId)) {
        athlete2Wins++;
        if (arm === "LEFT") leftArmAthlete2Wins++;
        else rightArmAthlete2Wins++;
      }
    }

    // Reuse already-computed per-arm and overall win/loss rates from getProfileByUserId
    const extractArmWinRates = (profile: any) => {
      const rightWins = Number(profile.rightArmWins ?? 0);
      const rightLosses = Number(profile.rightArmLosses ?? 0);
      const leftWins = Number(profile.leftArmWins ?? 0);
      const leftLosses = Number(profile.leftArmLosses ?? 0);
      const rightTotal = rightWins + rightLosses;
      const leftTotal = leftWins + leftLosses;
      const totalWins = rightWins + leftWins || Number(profile.wins ?? 0);
      const totalLosses = rightLosses + leftLosses || Number(profile.losses ?? 0);
      const totalAll = totalWins + totalLosses;
      const winRate =
        totalAll > 0 ? Math.round((totalWins / totalAll) * 1000) / 10 : 0;
      const winRateRight =
        rightTotal > 0 ? Math.round((rightWins / rightTotal) * 1000) / 10 : 0;
      const winRateLeft =
        leftTotal > 0 ? Math.round((leftWins / leftTotal) * 1000) / 10 : 0;
      return {
        winRateRight,
        winRateLeft,
        winRate,
        rightWins,
        rightLosses,
        leftWins,
        leftLosses,
        totalWins,
        totalLosses,
      };
    };

    const a1Rates = extractArmWinRates(athlete1);
    const a2Rates = extractArmWinRates(athlete2);

    const a1RightElo = (athlete1 as any).rightArmElo ?? (athlete1 as any).eloRating ?? 1000;
    const a1LeftElo = (athlete1 as any).leftArmElo ?? (athlete1 as any).eloRating ?? 1000;
    const a2RightElo = (athlete2 as any).rightArmElo ?? (athlete2 as any).eloRating ?? 1000;
    const a2LeftElo = (athlete2 as any).leftArmElo ?? (athlete2 as any).eloRating ?? 1000;

    const exponent = (a2RightElo - a1RightElo) / 400;
    const athlete1Prob = 1 / (1 + Math.pow(10, exponent));
    const athlete2Prob = 1 - athlete1Prob;

    return {
      athlete1: {
        id: athlete1.id,
        userId: athlete1.userId,
        displayName: athlete1.displayName,
        avatarUrl: athlete1.profilePhoto,
        province: athlete1.province,
        clubName: athlete1.club?.name || "Independent",
        weightKg: athlete1.weight,
        heightCm: athlete1.height,
        reachCm: athlete1.reach,
        dominantArm: athlete1.dominantArm,
        eloRating: a1RightElo,
        rightArmElo: a1RightElo,
        leftArmElo: a1LeftElo,
        winRateRight: a1Rates.winRateRight,
        winRateLeft: a1Rates.winRateLeft,
        winRate: a1Rates.winRate,
        wins: a1Rates.totalWins,
        losses: a1Rates.totalLosses,
        rightArmWins: a1Rates.rightWins,
        rightArmLosses: a1Rates.rightLosses,
        leftArmWins: a1Rates.leftWins,
        leftArmLosses: a1Rates.leftLosses,
        weightClass: athlete1.weightClass,
        measurements: athlete1.measurements,
        biometrics: athlete1.biometrics,
      },
      athlete2: {
        id: athlete2.id,
        userId: athlete2.userId,
        displayName: athlete2.displayName,
        avatarUrl: athlete2.profilePhoto,
        province: athlete2.province,
        clubName: athlete2.club?.name || "Independent",
        weightKg: athlete2.weight,
        heightCm: athlete2.height,
        reachCm: athlete2.reach,
        dominantArm: athlete2.dominantArm,
        eloRating: a2RightElo,
        rightArmElo: a2RightElo,
        leftArmElo: a2LeftElo,
        winRateRight: a2Rates.winRateRight,
        winRateLeft: a2Rates.winRateLeft,
        winRate: a2Rates.winRate,
        wins: a2Rates.totalWins,
        losses: a2Rates.totalLosses,
        rightArmWins: a2Rates.rightWins,
        rightArmLosses: a2Rates.rightLosses,
        leftArmWins: a2Rates.leftWins,
        leftArmLosses: a2Rates.leftLosses,
        weightClass: athlete2.weightClass,
        measurements: athlete2.measurements,
        biometrics: athlete2.biometrics,
      },
      headToHead: {
        totalEncounters: combinedH2H.length,
        athlete1Wins,
        athlete2Wins,
        rightArmAthlete1Wins,
        rightArmAthlete2Wins,
        leftArmAthlete1Wins,
        leftArmAthlete2Wins,
        matches: combinedH2H,
      },
      winProbability: {
        athlete1: Math.round(athlete1Prob * 100),
        athlete2: Math.round(athlete2Prob * 100),
      },
    };
  }
}
