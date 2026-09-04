import { Request, Response, NextFunction } from "express";
import { GovernanceService } from "../services/governance.js";
import { z } from "zod";
import { BadRequestError } from "@armsphere/core";

// Validation Schemas
const createDisputeSchema = z.object({
  matchId: z.string().nullable().optional(),
  title: z.string().min(5, "Title must be at least 5 characters"),
  description: z.string().min(10, "Description must be at least 10 characters"),
});

const assignReviewerSchema = z.object({
  reviewerId: z.string().min(1, "Reviewer ID must be provided"),
});

const submitEvidenceSchema = z.object({
  fileType: z.enum(["VIDEO", "IMAGE", "DOCUMENT"]),
  fileUrl: z.string().url("File URL must be a valid URL"),
  rawFileContent: z.string().optional(),
});

const addCommentSchema = z.object({
  comment: z.string().min(2, "Comment must be at least 2 characters"),
});

const resolveDisputeSchema = z.object({
  resolutionDetails: z.string().min(5, "Resolution details must be at least 5 characters"),
  decision: z.enum(["RESOLVED", "REJECTED"]),
});

const escalateDisputeSchema = z.object({
  escalationReason: z.string().min(5, "Escalation reason must be at least 5 characters"),
});

const appealResolutionSchema = z.object({
  appealReason: z.string().min(5, "Appeal reason must be at least 5 characters"),
});

const createSanctionSchema = z.object({
  userId: z.string().min(1, "User ID must be provided"),
  type: z.enum(["WARNING", "SUSPENSION", "TEMPORARY_BAN", "PERMANENT_BAN", "LICENSE_REVOCATION"]),
  reason: z.string().min(5, "Reason must be at least 5 characters"),
  durationDays: z.number().int().positive().nullable().optional(),
});

const correctMatchResultSchema = z.object({
  actualWinnerId: z.string().min(1, "Actual winner ID must be provided"),
});

const triggerReplaySchema = z.object({
  startingTimestamp: z.string().datetime({ message: "Starting timestamp must be a valid ISO datetime string" }),
});

export class GovernanceController {
  /**
   * List all disputes
   */
  static async listDisputes(req: Request, res: Response, next: NextFunction) {
    try {
      const disputesList = await GovernanceService.listDisputes(req.user!);
      res.status(200).json(disputesList);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Create a new dispute
   */
  static async createDispute(req: Request, res: Response, next: NextFunction) {
    try {
      const validated = createDisputeSchema.parse(req.body);
      const creatorId = req.user!.id;

      const dispute = await GovernanceService.createDispute(
        creatorId,
        validated.matchId || null,
        validated.title,
        validated.description
      );

      res.status(201).json({
        success: true,
        message: "Dispute successfully created",
        dispute,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Assign a reviewer to a dispute
   */
  static async assignReviewer(req: Request, res: Response, next: NextFunction) {
    try {
      const { id } = req.params;
      const validated = assignReviewerSchema.parse(req.body);
      const actorId = req.user!.id;

      const dispute = await GovernanceService.assignReviewer(id, validated.reviewerId, actorId);

      res.status(200).json({
        success: true,
        message: "Reviewer successfully assigned",
        dispute: {
          ...dispute,
          reviewerId: dispute.assignedReviewerId,
        },
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Submit evidence for a dispute
   */
  static async submitEvidence(req: Request, res: Response, next: NextFunction) {
    try {
      const { id } = req.params;
      const validated = submitEvidenceSchema.parse(req.body);
      const submitterId = req.user!.id;

      const evidence = await GovernanceService.submitEvidence(
        id,
        submitterId,
        validated.fileType,
        validated.fileUrl,
        validated.rawFileContent,
        req.user!.role
      );

      res.status(201).json({
        success: true,
        message: "Evidence successfully submitted and queued for virus scanning",
        evidence,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Add a comment to a dispute
   */
  static async addComment(req: Request, res: Response, next: NextFunction) {
    try {
      const { id } = req.params;
      const validated = addCommentSchema.parse(req.body);
      const authorId = req.user!.id;

      const comment = await GovernanceService.addComment(id, authorId, validated.comment, req.user!.role);

      res.status(201).json({
        success: true,
        message: "Comment successfully added",
        comment,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Resolve a dispute
   */
  static async resolveDispute(req: Request, res: Response, next: NextFunction) {
    try {
      const { id } = req.params;
      const validated = resolveDisputeSchema.parse(req.body);
      const actorId = req.user!.id;

      const dispute = await GovernanceService.resolveDispute(
        id,
        validated.resolutionDetails,
        validated.decision,
        {
          id: req.user!.id,
          role: req.user!.role,
          province: req.user!.province,
        }
      );

      res.status(200).json({
        success: true,
        message: `Dispute successfully marked as ${validated.decision}`,
        dispute,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Escalate a dispute to directors/admins
   */
  static async escalateDispute(req: Request, res: Response, next: NextFunction) {
    try {
      const { id } = req.params;
      const validated = escalateDisputeSchema.parse(req.body);
      const actorId = req.user!.id;

      const dispute = await GovernanceService.escalateDispute(id, validated.escalationReason, {
        id: req.user!.id,
        role: req.user!.role,
        province: req.user!.province,
      });

      res.status(200).json({
        success: true,
        message: "Dispute successfully escalated",
        dispute: {
          ...dispute,
          escalationReason: validated.escalationReason,
        },
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Appeal a resolved dispute
   */
  static async appealResolution(req: Request, res: Response, next: NextFunction) {
    try {
      const { id } = req.params;
      const validated = appealResolutionSchema.parse(req.body);
      const actorId = req.user!.id;

      const dispute = await GovernanceService.appealResolution(id, validated.appealReason, {
        id: req.user!.id,
        role: req.user!.role,
        province: req.user!.province,
      });

      res.status(200).json({
        success: true,
        message: "Resolution successfully appealed and reopened",
        dispute: {
          ...dispute,
          appealReason: validated.appealReason,
        },
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Issue a sanction against an athlete or referee
   */
  static async createSanction(req: Request, res: Response, next: NextFunction) {
    try {
      const validated = createSanctionSchema.parse(req.body);
      const issuedById = req.user!.id;

      const sanction = await GovernanceService.createSanction(
        validated.userId,
        validated.type,
        validated.reason,
        validated.durationDays || null,
        issuedById
      );

      res.status(201).json({
        success: true,
        message: "Sanction successfully issued",
        sanction: {
          ...sanction,
          expiresAt: sanction.endsAt,
        },
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Sweep system to expire past sanctions
   */
  static async sweepSanctions(req: Request, res: Response, next: NextFunction) {
    try {
      const expiredCount = await GovernanceService.processSanctionsExpiry();
      res.status(200).json({
        success: true,
        message: "Sanctions sweep completed successfully",
        expiredCount,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Cryptographically verify integrity of the immutable audit ledger
   */
  static async verifyAuditLedger(req: Request, res: Response, next: NextFunction) {
    try {
      const verification = await GovernanceService.verifyAuditLedger();
      res.status(200).json({
        success: true,
        message: verification.isValid ? "Ledger integrity is intact" : "Ledger tampering detected!",
        verification,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Correct match winner and trigger ratings recalculation replay
   */
  static async correctMatchResult(req: Request, res: Response, next: NextFunction) {
    try {
      const { id } = req.params;
      const validated = correctMatchResultSchema.parse(req.body);
      const reviewerId = req.user!.id;

      const updatedMatch = await GovernanceService.correctMatchResult(
        id,
        validated.actualWinnerId,
        reviewerId
      );

      res.status(200).json({
        success: true,
        message: "Match result corrected successfully and sequential ELO recalculation series queued",
        match: updatedMatch,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Trigger historical ELO recalculation series manually
   */
  static async triggerEloRecalculation(req: Request, res: Response, next: NextFunction) {
    try {
      const validated = triggerReplaySchema.parse(req.body);
      const startingTimestamp = new Date(validated.startingTimestamp);

      const progress = await GovernanceService.triggerEloRecalculationFrom(startingTimestamp);

      res.status(202).json({
        success: true,
        message: "Historical ELO series recalculation started successfully",
        progress,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Get historical ELO recalculation series status
   */
  static async getReplayStatus(req: Request, res: Response, next: NextFunction) {
    try {
      const progress = GovernanceService.getReplayStatus();
      res.status(200).json({
        success: true,
        progress,
      });
    } catch (error) {
      next(error);
    }
  }
}
