import { Request, Response, NextFunction } from "express";
import { AdministrationService } from "../services/administration.js";
import { z } from "zod";
import { BadRequestError } from "@armsphere/core";

// Zod schemas for admin operations
const reviewProfileSchema = z.object({
  status: z.enum(["VERIFIED", "REJECTED"]),
  reason: z.string().optional(),
});

const suspendAthleteSchema = z.object({
  reason: z.string().min(5, "Suspension reason must be provided"),
  durationDays: z.number().int().positive().optional(),
});

const blacklistAthleteSchema = z.object({
  reason: z.string().min(5, "Blacklist reason must be provided"),
});

const manualCorrectionSchema = z.object({
  displayName: z.string().optional(),
  weightClass: z.string().optional(),
  leftArmElo: z.number().int().optional(),
  rightArmElo: z.number().int().optional(),
  province: z.string().optional(),
  city: z.string().optional(),
});

const updateRefereeLicenseSchema = z.object({
  certification: z.string().min(1, "Certification required"),
  status: z.string().min(1, "Status required"),
});

const assignRegionSchema = z.object({
  region: z.string().min(1, "Region required"),
});

const scoreCorrectionSchema = z.object({
  winnerId: z.string().uuid("Invalid winner ID format"),
  scoreLine: z.string().min(3, "Invalid score line (e.g. 3-0)"),
});

const voidMatchSchema = z.object({
  reason: z.string().min(5, "Voiding reason must be provided"),
});

const manageWeighInSchema = z.object({
  registrationId: z.string().uuid("Invalid registration ID format"),
  weight: z.number().positive("Weight must be positive"),
  status: z.enum(["PASSED", "FAILED"]),
});

const titleOperationSchema = z.object({
  action: z.enum(["ASSIGN", "VACATE", "RECALCULATE"]),
  athleteId: z.string().uuid().optional(),
});

const resolveDisputeSchema = z.object({
  resolutionDetails: z.string().min(5, "Resolution details must be provided"),
  decision: z.enum(["RESOLVED", "REJECTED"]),
});

const triggerWorkerSchema = z.object({
  workerName: z.enum(["dashboard.refresh", "observability.snapshot", "audit.integrity.scan", "export.generator"]),
});

const exportReportSchema = z.object({
  format: z.enum(["csv", "xlsx", "pdf"]),
  reportType: z.enum(["athletes", "referees", "matches", "financial", "governance"]),
});

export class AdministrationController {
  static async getDashboardStats(req: any, res: any, next: NextFunction) {
    try {
      const stats = await AdministrationService.getDashboardStats();
      res.status(200).json(stats);
    } catch (err) {
      next(err);
    }
  }

  static async getAthletes(req: any, res: any, next: NextFunction) {
    try {
      const filters = {
        search: req.query.search ? String(req.query.search) : undefined,
        status: req.query.status ? String(req.query.status) : undefined,
        province: req.query.province ? String(req.query.province) : undefined,
      };
      const list = await AdministrationService.getAthletes(filters);
      res.status(200).json({ success: true, data: list });
    } catch (err) {
      next(err);
    }
  }

  static async reviewProfile(req: any, res: any, next: NextFunction) {
    try {
      const validated = reviewProfileSchema.parse(req.body);
      const reviewerId = req.user.id;
      const result = await AdministrationService.reviewProfile(req.params.id, reviewerId, validated.status, validated.reason);
      res.status(200).json({ success: true, data: result });
    } catch (err) {
      next(err);
    }
  }

  static async suspendAthlete(req: any, res: any, next: NextFunction) {
    try {
      const validated = suspendAthleteSchema.parse(req.body);
      const reviewerId = req.user.id;
      const result = await AdministrationService.suspendAthlete(req.params.id, reviewerId, validated.reason, validated.durationDays);
      res.status(200).json({ success: true, data: result });
    } catch (err) {
      next(err);
    }
  }

  static async blacklistAthlete(req: any, res: any, next: NextFunction) {
    try {
      const validated = blacklistAthleteSchema.parse(req.body);
      const reviewerId = req.user.id;
      const result = await AdministrationService.blacklistAthlete(req.params.id, reviewerId, validated.reason);
      res.status(200).json({ success: true, data: result });
    } catch (err) {
      next(err);
    }
  }

  static async recoverAthlete(req: any, res: any, next: NextFunction) {
    try {
      const reviewerId = req.user.id;
      const result = await AdministrationService.recoverAthlete(req.params.id, reviewerId);
      res.status(200).json({ success: true, data: result });
    } catch (err) {
      next(err);
    }
  }

  static async manualCorrection(req: any, res: any, next: NextFunction) {
    try {
      const validated = manualCorrectionSchema.parse(req.body);
      const reviewerId = req.user.id;
      const result = await AdministrationService.manualCorrection(req.params.id, validated, reviewerId);
      res.status(200).json({ success: true, data: result });
    } catch (err) {
      next(err);
    }
  }

  static async getReferees(req: any, res: any, next: NextFunction) {
    try {
      const list = await AdministrationService.getReferees();
      res.status(200).json({ success: true, data: list });
    } catch (err) {
      next(err);
    }
  }

  static async updateRefereeLicense(req: any, res: any, next: NextFunction) {
    try {
      const validated = updateRefereeLicenseSchema.parse(req.body);
      const reviewerId = req.user.id;
      const result = await AdministrationService.updateRefereeLicense(req.params.id, validated.certification, validated.status, reviewerId);
      res.status(200).json({ success: true, data: result });
    } catch (err) {
      next(err);
    }
  }

  static async handleRefereeSuspension(req: any, res: any, next: NextFunction) {
    try {
      const validated = blacklistAthleteSchema.parse(req.body); // re-use reason validation
      const reviewerId = req.user.id;
      const result = await AdministrationService.handleRefereeSuspension(req.params.id, reviewerId, validated.reason);
      res.status(200).json({ success: true, data: result });
    } catch (err) {
      next(err);
    }
  }

  static async assignRefereeRegion(req: any, res: any, next: NextFunction) {
    try {
      const validated = assignRegionSchema.parse(req.body);
      const reviewerId = req.user.id;
      const result = await AdministrationService.assignRefereeRegion(req.params.id, validated.region, reviewerId);
      res.status(200).json({ success: true, data: result });
    } catch (err) {
      next(err);
    }
  }

  static async getMatches(req: any, res: any, next: NextFunction) {
    try {
      const list = await AdministrationService.getMatches();
      res.status(200).json({ success: true, data: list });
    } catch (err) {
      next(err);
    }
  }

  static async inspectMatch(req: any, res: any, next: NextFunction) {
    try {
      const data = await AdministrationService.inspectMatch(req.params.id);
      res.status(200).json({ success: true, data });
    } catch (err) {
      next(err);
    }
  }

  static async scoreCorrection(req: any, res: any, next: NextFunction) {
    try {
      const validated = scoreCorrectionSchema.parse(req.body);
      const reviewerId = req.user.id;
      const result = await AdministrationService.scoreCorrection(req.params.id, validated.winnerId, validated.scoreLine, reviewerId);
      res.status(200).json({ success: true, data: result });
    } catch (err) {
      next(err);
    }
  }

  static async voidMatch(req: any, res: any, next: NextFunction) {
    try {
      const validated = voidMatchSchema.parse(req.body);
      const reviewerId = req.user.id;
      const result = await AdministrationService.voidMatch(req.params.id, validated.reason, reviewerId);
      res.status(200).json({ success: true, data: result });
    } catch (err) {
      next(err);
    }
  }

  static async getEvents(req: any, res: any, next: NextFunction) {
    try {
      const data = await AdministrationService.getEvents();
      res.status(200).json({ success: true, data });
    } catch (err) {
      next(err);
    }
  }

  static async manageWeighIn(req: any, res: any, next: NextFunction) {
    try {
      const validated = manageWeighInSchema.parse(req.body);
      const reviewerId = req.user.id;
      const result = await AdministrationService.manageWeighIn(validated.registrationId, validated.weight, validated.status, reviewerId);
      res.status(200).json({ success: true, data: result });
    } catch (err) {
      next(err);
    }
  }

  static async manageChampionshipTitle(req: any, res: any, next: NextFunction) {
    try {
      const validated = titleOperationSchema.parse(req.body);
      const reviewerId = req.user.id;
      const result = await AdministrationService.manageChampionshipTitle(
        validated.action, 
        req.params.id, 
        { athleteId: validated.athleteId }, 
        reviewerId
      );
      res.status(200).json({ success: true, data: result });
    } catch (err) {
      next(err);
    }
  }

  static async getDisputesTimeline(req: any, res: any, next: NextFunction) {
    try {
      const list = await AdministrationService.getDisputesTimeline();
      res.status(200).json({ success: true, data: list });
    } catch (err) {
      next(err);
    }
  }

  static async resolveDisputeCase(req: any, res: any, next: NextFunction) {
    try {
      const validated = resolveDisputeSchema.parse(req.body);
      const reviewerId = req.user.id;
      const result = await AdministrationService.resolveDisputeCase(req.params.id, validated.resolutionDetails, validated.decision, reviewerId);
      res.status(200).json({ success: true, data: result });
    } catch (err) {
      next(err);
    }
  }

  static async getAuditEvents(req: any, res: any, next: NextFunction) {
    try {
      const list = await AdministrationService.getAuditEvents();
      res.status(200).json({ success: true, data: list });
    } catch (err) {
      next(err);
    }
  }

  static async verifyImmutableAuditLedger(req: any, res: any, next: NextFunction) {
    try {
      const result = await AdministrationService.verifyImmutableAuditLedger();
      res.status(200).json({ success: true, data: result });
    } catch (err) {
      next(err);
    }
  }

  static async triggerWorkerJob(req: any, res: any, next: NextFunction) {
    try {
      const validated = triggerWorkerSchema.parse(req.body);
      const result = await AdministrationService.triggerWorkerJob(validated.workerName);
      res.status(200).json({ success: true, data: result });
    } catch (err) {
      next(err);
    }
  }

  static async runScheduledJobs(req: any, res: any, next: NextFunction) {
    try {
      const result = await AdministrationService.runScheduledJobs();
      res.status(200).json({ success: true, data: result });
    } catch (err) {
      next(err);
    }
  }

  static async exportReport(req: any, res: any, next: NextFunction) {
    try {
      const validated = exportReportSchema.parse(req.body);
      
      // Simulate direct file generation
      res.setHeader("Content-Type", validated.format === "csv" ? "text/csv" : "application/octet-stream");
      res.setHeader("Content-Disposition", `attachment; filename="federation_report_${validated.reportType}.${validated.format}"`);
      
      const content = `Federation Report,Type: ${validated.reportType},Format: ${validated.format}\nGeneratedAt,${new Date().toISOString()}\nStatus,CONFIDENTIAL\n`;
      res.status(200).send(content);
    } catch (err) {
      next(err);
    }
  }
}
