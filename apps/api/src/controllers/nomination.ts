import { Request, Response, NextFunction } from "express";
import { NominationService } from "../services/nomination.js";
import { z } from "zod";

// Validation Schemas
const createNominationSchema = z.object({
  nomineeName: z.string().min(1, "Nominee name is required"),
  nomineeContact: z.string().optional(),
  city: z.string().min(1, "City is required"),
  province: z.string().min(1, "Province is required"),
  notes: z.string().optional(),
});

const getNominationsQuerySchema = z.object({
  status: z.string().optional(),
  city: z.string().optional(),
  province: z.string().optional(),
  limit: z.preprocess((val) => (val ? parseInt(val as string, 10) : 20), z.number().min(1).max(100)).default(20),
  offset: z.preprocess((val) => (val ? parseInt(val as string, 10) : 0), z.number().min(0)).default(0),
});

const updateStatusSchema = z.object({
  status: z.string().min(1, "Status is required"),
});

export class NominationController {
  /**
   * Submit a new talent nomination
   */
  static async createNomination(req: Request, res: Response, next: NextFunction) {
    try {
      const validated = createNominationSchema.parse(req.body);
      const userId = req.user!.id;

      const nomination = await NominationService.createNomination(userId, validated as any);

      res.status(201).json({
        success: true,
        data: nomination,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * List all nominations (admin roles only)
   */
  static async getNominations(req: Request, res: Response, next: NextFunction) {
    try {
      const filters = getNominationsQuerySchema.parse(req.query);
      const nominations = await NominationService.getNominations(filters as any);

      res.status(200).json({
        success: true,
        data: nominations,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Get own submitted nominations
   */
  static async getOwnNominations(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = req.user!.id;
      const nominations = await NominationService.getOwnNominations(userId);

      res.status(200).json({
        success: true,
        data: nominations,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Update nomination status (admin only)
   */
  static async updateNominationStatus(req: Request, res: Response, next: NextFunction) {
    try {
      const { id } = req.params;
      const { status } = updateStatusSchema.parse(req.body);
      const actorUserId = req.user!.id;
      const actorRole = req.user!.role;

      const updated = await NominationService.updateNominationStatus(
        actorUserId,
        id,
        status,
        actorRole
      );

      res.status(200).json({
        success: true,
        data: updated,
      });
    } catch (error) {
      next(error);
    }
  }
}
