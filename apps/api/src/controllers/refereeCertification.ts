import { Request, Response, NextFunction } from "express";
import { RefereeCertificationService } from "../services/refereeCertification.js";
import { z } from "zod";

const issueCertificationSchema = z.object({
  certificationLevel: z.string().min(1, "Certification level is required"),
  issuedAt: z.string().datetime({ message: "Issued at must be a valid ISO datetime string" }),
  expiresAt: z.string().datetime({ message: "Expires at must be a valid ISO datetime string" }).optional(),
  issuingBody: z.string().min(1, "Issuing body is required"),
});

export class RefereeCertificationController {
  /**
   * Issue a new referee certification
   */
  static async issueCertification(req: Request, res: Response, next: NextFunction) {
    try {
      const validated = issueCertificationSchema.parse(req.body);
      const { userId } = req.params;
      const actorRole = req.user!.role;

      const certification = await RefereeCertificationService.issueCertification(
        actorRole,
        userId,
        validated as any
      );

      res.status(201).json({
        success: true,
        data: certification,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * List certifications of a referee
   */
  static async listCertifications(req: Request, res: Response, next: NextFunction) {
    try {
      const { userId } = req.params;
      const actorUserId = req.user!.id;
      const actorRole = req.user!.role;

      const certifications = await RefereeCertificationService.listCertifications(
        actorUserId,
        actorRole,
        userId
      );

      res.status(200).json({
        success: true,
        data: certifications,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Revoke a referee certification
   */
  static async revokeCertification(req: Request, res: Response, next: NextFunction) {
    try {
      const { id } = req.params;
      const actorRole = req.user!.role;

      const certification = await RefereeCertificationService.revokeCertification(
        actorRole,
        id
      );

      res.status(200).json({
        success: true,
        data: certification,
      });
    } catch (error) {
      next(error);
    }
  }
}
