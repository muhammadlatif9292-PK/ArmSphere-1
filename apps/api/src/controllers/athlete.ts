import { Request, Response, NextFunction } from "express";
import { AthleteService } from "../services/athlete.js";
import { StorageService } from "../services/storage.js";
import { env } from "../config/env.js";
import { MatchService } from "../services/match.js";
import { MessagingService } from "../services/messaging.js";
import { z } from "zod";
import { BadRequestError, ForbiddenError } from "@armsphere/core";

// Validation Schemas
const createProfileSchema = z.object({
  displayName: z.string().min(2, "Display name must be at least 2 characters"),
  biography: z.string().optional(),
  province: z.string().min(1, "Province is required"),
  city: z.string().min(1, "City is required"),
  clubId: z.string().uuid().optional(),
  handedness: z.enum(["LEFT", "RIGHT", "AMBIDEXTROUS"]),
  dominantArm: z.enum(["LEFT", "RIGHT"]),
  dateOfBirth: z.string().datetime("Invalid date format for Date of Birth"),
  gender: z.string().min(1, "Gender is required"),
  weightClass: z.string().min(1, "Weight class is required"),
  height: z.number().positive().optional(),
  weight: z.number().positive().optional(),
  reach: z.number().positive().optional(),
  profilePhoto: z.string().optional(),
});

const updateProfileSchema = createProfileSchema.partial();

const updateVisibilitySchema = z.object({
  profileVisibility: z.enum(["PUBLIC", "GYM_ONLY"]).optional(),
  isSearchable: z.boolean().optional(),
});

const searchFilterSchema = z.object({
  displayName: z.string().optional(),
  province: z.string().optional(),
  clubId: z.string().uuid().optional(),
  weightClass: z.string().optional(),
  gender: z.string().optional(),
  verificationStatus: z.string().optional(),
  limit: z.coerce.number().int().positive().default(50),
  offset: z.coerce.number().int().nonnegative().default(0),
});

const directUploadSchema = z.object({
  fileType: z.enum(["AVATAR", "DOCUMENT"]),
  fileName: z.string().min(1, "File name is required"),
  mimeType: z.string().min(1, "MIME type is required"),
  base64Data: z.string().min(1, "Base64 payload is required"),
});

const presignedUrlRequestSchema = z.object({
  fileType: z.enum(["AVATAR", "DOCUMENT"]),
  fileName: z.string().min(1, "File name is required"),
  mimeType: z.string().min(1, "MIME type is required"),
  size: z.number().int().positive(),
});

const verificationSubmissionSchema = z.object({
  documentType: z.string().min(1, "Document type is required"), // e.g. "CNIC", "SELFIE"
  fileKey: z.string().min(1, "File key is required"),
  bucketName: z.string().min(1, "Bucket name is required"),
  sha256Hash: z.string().length(64, "SHA-256 hash must be exactly 64 characters"),
});

const verificationReviewSchema = z.object({
  athleteId: z.string().uuid("Invalid athlete ID"),
  status: z.enum(["VERIFIED", "REJECTED", "SUSPENDED"]),
  rejectionReason: z.string().optional(),
});

const biometricsUpdateSchema = z.object({
  handLength: z.number().positive().optional(),
  handWidth: z.number().positive().optional(),
  palmLength: z.number().positive().optional(),
  armSpan: z.number().positive().optional(),
  forearmCircumference: z.number().positive().optional(),
  bicepCircumference: z.number().positive().optional(),
});

const createClubSchema = z.object({
  name: z.string().min(2, "Club name must be at least 2 characters"),
  city: z.string().min(1, "City is required"),
  province: z.string().min(1, "Province is required"),
});

const getAthleteMatchesQuerySchema = z.object({
  limit: z.preprocess((val) => (val ? parseInt(val as string, 10) : 20), z.number().min(1).max(100)).default(20),
  offset: z.preprocess((val) => (val ? parseInt(val as string, 10) : 0), z.number().min(0)).default(0),
});

export class AthleteController {
  /**
   * Create standard athlete profile
   */
  static async createProfile(req: Request, res: Response, next: NextFunction) {
    try {
      const validated = createProfileSchema.parse(req.body);
      const userId = req.user!.id;

      const profile = await AthleteService.createProfile(userId, validated as any, req.ip, req.headers["user-agent"]);

      if (profile && profile.profilePhoto) {
        profile.profilePhoto = await StorageService.generatePresignedDownloadUrl(
          env.B2_BUCKET_ATHLETE_AVATARS,
          profile.profilePhoto
        );
      }

      res.status(201).json({
        success: true,
        data: profile,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Retrieve profile of currently logged-in user
   */
  static async getMe(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = req.user!.id;
      const profile = await AthleteService.getProfileByUserId(userId);

      if (profile && profile.profilePhoto) {
        profile.profilePhoto = await StorageService.generatePresignedDownloadUrl(
          env.B2_BUCKET_ATHLETE_AVATARS,
          profile.profilePhoto
        );
      }

      res.status(200).json({
        success: true,
        data: profile,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Retrieve athlete profile by profile ID or User ID
   */
  static async getProfile(req: Request, res: Response, next: NextFunction) {
    try {
      const id = req.params.id;
      const callerUserId = req.user!.id;

      if (callerUserId !== id) {
        const isBlocked = await MessagingService.checkBlockByUsers(callerUserId, id);
        if (isBlocked) {
          throw new ForbiddenError("You cannot view this profile because this user is blocked or has blocked you.");
        }
      }

      const profile = await AthleteService.getProfileByUserId(id, callerUserId);

      if (profile && profile.profilePhoto) {
        profile.profilePhoto = await StorageService.generatePresignedDownloadUrl(
          env.B2_BUCKET_ATHLETE_AVATARS,
          profile.profilePhoto
        );
      }

      res.status(200).json({
        success: true,
        data: profile,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Update profile details (with strict ownership boundaries)
   */
  static async updateProfile(req: Request, res: Response, next: NextFunction) {
    try {
      const validated = updateProfileSchema.parse(req.body);
      const targetUserId = req.params.id;
      const actorUserId = req.user!.id;
      const actorRole = req.user!.role;

      const updated = await AthleteService.updateProfile(
        actorUserId,
        targetUserId,
        validated,
        actorRole,
        req.ip,
        req.headers["user-agent"]
      );

      if (updated && updated.profilePhoto) {
        updated.profilePhoto = await StorageService.generatePresignedDownloadUrl(
          env.B2_BUCKET_ATHLETE_AVATARS,
          updated.profilePhoto
        );
      }

      res.status(200).json({
        success: true,
        data: updated,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Update profile visibility and searchability settings
   */
  static async updateVisibility(req: Request, res: Response, next: NextFunction) {
    try {
      const validated = updateVisibilitySchema.parse(req.body);
      const userId = req.user!.id;

      const updated = await AthleteService.updateVisibility(
        userId,
        validated,
        req.ip,
        req.headers["user-agent"]
      );

      if (updated && updated.profilePhoto) {
        updated.profilePhoto = await StorageService.generatePresignedDownloadUrl(
          env.B2_BUCKET_ATHLETE_AVATARS,
          updated.profilePhoto
        );
      }

      res.status(200).json({
        success: true,
        data: updated,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * High-performance search & filter over athletes
   */
  static async searchAthletes(req: Request, res: Response, next: NextFunction) {
    try {
      const filters = searchFilterSchema.parse(req.query);
      const results = await AthleteService.searchAthletes({
        ...filters,
        viewerUserId: req.user?.id
      });

      const mappedResults = await Promise.all(
        results.map(async (item) => {
          if (item.profilePhoto) {
            item.profilePhoto = await StorageService.generatePresignedDownloadUrl(
              env.B2_BUCKET_ATHLETE_AVATARS,
              item.profilePhoto
            );
          }
          return item;
        })
      );

      res.status(200).json({
        success: true,
        data: mappedResults,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Handle direct secure file uploads (with base64 payload)
   */
  static async directUpload(req: Request, res: Response, next: NextFunction) {
    try {
      const validated = directUploadSchema.parse(req.body);
      
      // Convert base64 back to raw buffer
      const buffer = Buffer.from(validated.base64Data, "base64");

      const result = await StorageService.processAndUploadDirect(
        validated.fileType,
        validated.fileName,
        validated.mimeType,
        buffer
      );

      res.status(200).json({
        success: true,
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Request a presigned PUT URL for client-direct uploads
   */
  static async getPresignedUploadUrl(req: Request, res: Response, next: NextFunction) {
    try {
      const validated = presignedUrlRequestSchema.parse(req.body);

      const result = await StorageService.generatePresignedUploadUrl(
        validated.fileType,
        validated.fileName,
        validated.mimeType,
        validated.size
      );

      res.status(200).json({
        success: true,
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Submit document for verification Manual federation review
   */
  static async submitForVerification(req: Request, res: Response, next: NextFunction) {
    try {
      const validated = verificationSubmissionSchema.parse(req.body);
      const userId = req.user!.id;

      const result = await AthleteService.submitForVerification(
        userId,
        validated.documentType,
        validated.fileKey,
        validated.bucketName,
        validated.sha256Hash
      );

      res.status(200).json({
        success: true,
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Federation Admin review of athlete verification documentation
   */
  static async reviewVerification(req: Request, res: Response, next: NextFunction) {
    try {
      const validated = verificationReviewSchema.parse(req.body);
      const reviewerId = req.user!.id;

      const result = await AthleteService.reviewVerification(
        reviewerId,
        validated.athleteId,
        validated.status,
        validated.rejectionReason,
        req.ip,
        req.headers["user-agent"]
      );

      res.status(200).json({
        success: true,
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Update Biometrics
   */
  static async updateBiometrics(req: Request, res: Response, next: NextFunction) {
    try {
      const validated = biometricsUpdateSchema.parse(req.body);
      const userId = req.user!.id;

      const result = await AthleteService.updateBiometrics(userId, validated);

      res.status(200).json({
        success: true,
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Create an athletic club affiliation
   */
  static async createClub(req: Request, res: Response, next: NextFunction) {
    try {
      const validated = createClubSchema.parse(req.body);
      const club = await AthleteService.createClub(validated.name, validated.city, validated.province);

      res.status(201).json({
        success: true,
        data: club,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * List all athletic club affiliations
   */
  static async getClubs(req: Request, res: Response, next: NextFunction) {
    try {
      const clubs = await AthleteService.getClubs();

      res.status(200).json({
        success: true,
        data: clubs,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Retrieve paginated matches of an athlete
   */
  static async getAthleteMatches(req: Request, res: Response, next: NextFunction) {
    try {
      const { id } = req.params;
      const { limit, offset } = getAthleteMatchesQuerySchema.parse(req.query);
      const matchesList = await MatchService.getAthleteMatches(id, { limit, offset });

      res.status(200).json({
        success: true,
        data: matchesList,
      });
    } catch (error) {
      next(error);
    }
  }
}
