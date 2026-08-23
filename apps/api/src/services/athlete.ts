import { eq, and, like, or, SQL, desc, notInArray } from "drizzle-orm";
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
  blockedUsers
} from "@armsphere/db-schema";
import { 
  NotFoundError, 
  BadRequestError, 
  ForbiddenError, 
  ConflictError, 
  logger 
} from "@armsphere/core";

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

    return profile;
  }

  /**
   * Retrieve complete athlete profile aggregated with verification status, biometrics, measurements, and social links
   */
  static async getProfileByUserId(userId: string, viewerUserId?: string) {
    const [profile] = await db
      .select()
      .from(athleteProfiles)
      .where(and(eq(athleteProfiles.userId, userId), eq(athleteProfiles.isDeleted, false)))
      .limit(1);

    if (!profile) {
      throw new NotFoundError("Athlete profile not found");
    }

    if (viewerUserId && viewerUserId !== userId) {
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

    // Resolve club details
    let club = null;
    if (profile.clubId) {
      const [clubRecord] = await db
        .select()
        .from(athleteClubs)
        .where(eq(athleteClubs.id, profile.clubId))
        .limit(1);
      club = clubRecord || null;
    }

    // Resolve verification status
    const [verification] = await db
      .select()
      .from(athleteVerifications)
      .where(eq(athleteVerifications.athleteId, userId))
      .limit(1);

    // Resolve biometrics
    const [biometrics] = await db
      .select()
      .from(athleteBiometrics)
      .where(eq(athleteBiometrics.athleteId, userId))
      .limit(1);

    // Resolve measurements
    const [measurements] = await db
      .select()
      .from(athleteMeasurements)
      .where(eq(athleteMeasurements.athleteId, userId))
      .limit(1);

    // Resolve social links
    const [socials] = await db
      .select()
      .from(athleteSocialLinks)
      .where(eq(athleteSocialLinks.athleteId, userId))
      .limit(1);

    return {
      ...profile,
      club,
      verificationStatus: verification?.status || "UNVERIFIED",
      rejectionReason: verification?.rejectionReason || null,
      biometrics: biometrics || null,
      measurements: measurements || null,
      socialLinks: socials || null,
    };
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
    // 1. Ownership & Role check: Only profile owner or an Admin/Director can update it
    if (userId !== targetUserId && !["system_admin", "national_director", "provincial_director"].includes(role.toLowerCase())) {
      throw new ForbiddenError("You are not authorized to update this profile");
    }

    // 2. Retrieve existing profile
    const [existingProfile] = await db
      .select()
      .from(athleteProfiles)
      .where(and(eq(athleteProfiles.userId, targetUserId), eq(athleteProfiles.isDeleted, false)))
      .limit(1);

    if (!existingProfile) {
      throw new NotFoundError("Athlete profile not found");
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

    updatePayload.updatedAt = new Date();

    // 4. Update the database record
    const [updatedProfile] = await db
      .update(athleteProfiles)
      .set(updatePayload)
      .where(eq(athleteProfiles.userId, targetUserId))
      .returning();

    // Update measurements as well if profile physicals are modified
    if (input.height !== undefined || input.weight !== undefined || input.reach !== undefined) {
      const [existingMeasurement] = await db
        .select()
        .from(athleteMeasurements)
        .where(eq(athleteMeasurements.athleteId, targetUserId))
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
          .where(eq(athleteMeasurements.athleteId, targetUserId));
      }
    }

    // 5. Track History
    await db.insert(athleteProfileHistory).values({
      athleteId: targetUserId,
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

    return updatedProfile;
  }

  /**
   * Update profile visibility and searchability preferences
   */
  static async updateVisibility(
    userId: string,
    input: { profileVisibility?: string; isSearchable?: boolean },
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
      details: { profileId: existingProfile.id, profileVisibility: input.profileVisibility, isSearchable: input.isSearchable },
      ipAddress,
      userAgent,
    });

    return updatedProfile;
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
      queryConditions.push(like(athleteProfiles.displayName, `%${filters.displayName}%`));
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

    return results;
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
    // Verify athlete profile exists
    const [profile] = await db
      .select()
      .from(athleteProfiles)
      .where(eq(athleteProfiles.userId, athleteId))
      .limit(1);

    if (!profile) {
      throw new NotFoundError("Athlete profile not found");
    }

    // Ensure verification record exists
    await this.ensureVerificationRecord(athleteId);

    // Update status
    const [updatedVerification] = await db
      .update(athleteVerifications)
      .set({
        status,
        reviewerId,
        rejectionReason: status === "REJECTED" ? rejectionReason || "Incomplete documentation" : null,
        updatedAt: new Date(),
      })
      .where(eq(athleteVerifications.athleteId, athleteId))
      .returning();

    // Audit trail
    await db.insert(auditLogs).values({
      userId: reviewerId,
      action: `ATHLETE_VERIFICATION_${status}`,
      details: { athleteId, reviewerId, rejectionReason },
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
  static async createClub(name: string, city: string, province: string) {
    const [club] = await db
      .insert(athleteClubs)
      .values({
        name,
        city,
        province,
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
}
