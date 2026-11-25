import { Request, Response, NextFunction } from "express";
import { z } from "zod";
import { UnauthorizedError } from "@armsphere/core";
import { OrganizationCertificationService } from "../services/organizationCertification.js";

const ReviewRequestSchema = z.object({
  decision: z
    .string()
    .transform((v) => v.trim().toUpperCase())
    .refine((v) => ["APPROVE", "APPROVED", "REJECT", "REJECTED"].includes(v), {
      message: "Decision must be APPROVE or REJECT.",
    })
    .transform((v) => (v.startsWith("APPROV") ? "APPROVE" : "REJECT") as "APPROVE" | "REJECT"),
  certificationLevel: z.string().trim().min(2).max(100).optional(),
  reviewNotes: z.string().trim().max(1000).optional(),
  notes: z.string().trim().max(1000).optional(),
  expiresAt: z.string().nullable().optional(),
});

const GrantCertificationSchema = z
  .object({
    athleteId: z.string().uuid().optional(),
    userId: z.string().uuid().optional(),
    certificationLevel: z.string().trim().min(2, "Certification level is required.").max(100),
    notes: z.string().trim().max(1000).optional(),
    expiresAt: z.string().nullable().optional(),
  })
  .refine((data) => Boolean(data.athleteId || data.userId), {
    message: "Either athleteId or userId is required.",
  });

const RevokeCertificationSchema = z.object({
  reason: z.string().trim().max(1000).optional(),
});

export class OrganizationCertificationController {
  /**
   * GET /organizations/:orgId/certifications/requests
   */
  static async listRequests(req: Request, res: Response, next: NextFunction) {
    try {
      if (!req.user) throw new UnauthorizedError("Authentication required.");
      const orgId = req.params.orgId as string;
      const status = typeof req.query.status === "string" ? req.query.status : undefined;
      const requests = await OrganizationCertificationService.listRequests(req.user, orgId, status);
      res.status(200).json({
        success: true,
        data: requests,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * POST /organizations/:orgId/certifications/requests/:requestId/review
   */
  static async reviewRequest(req: Request, res: Response, next: NextFunction) {
    try {
      if (!req.user) throw new UnauthorizedError("Authentication required.");
      const orgId = req.params.orgId as string;
      const requestId = req.params.requestId as string;
      const parsed = ReviewRequestSchema.safeParse(req.body);
      if (!parsed.success) {
        throw parsed.error;
      }

      const result = await OrganizationCertificationService.reviewRequest(
        req.user,
        orgId,
        requestId,
        parsed.data
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
   * GET /organizations/:orgId/certifications/athletes/search?q=...
   */
  static async searchAthletes(req: Request, res: Response, next: NextFunction) {
    try {
      if (!req.user) throw new UnauthorizedError("Authentication required.");
      const orgId = req.params.orgId as string;
      const q = typeof req.query.q === "string" ? req.query.q : "";
      const limit =
        typeof req.query.limit === "string" ? parseInt(req.query.limit, 10) || 25 : 25;

      const athletes = await OrganizationCertificationService.searchAthletes(
        req.user,
        orgId,
        q,
        limit
      );

      res.status(200).json({
        success: true,
        data: athletes,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * POST /organizations/:orgId/certifications/grant
   */
  static async grantCertification(req: Request, res: Response, next: NextFunction) {
    try {
      if (!req.user) throw new UnauthorizedError("Authentication required.");
      const orgId = req.params.orgId as string;
      const parsed = GrantCertificationSchema.safeParse(req.body);
      if (!parsed.success) {
        throw parsed.error;
      }

      const result = await OrganizationCertificationService.grantCertification(
        req.user,
        orgId,
        parsed.data
      );

      res.status(201).json({
        success: true,
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * GET /organizations/:orgId/certifications
   */
  static async listCertifications(req: Request, res: Response, next: NextFunction) {
    try {
      if (!req.user) throw new UnauthorizedError("Authentication required.");
      const orgId = req.params.orgId as string;
      const status = typeof req.query.status === "string" ? req.query.status : undefined;
      const certs = await OrganizationCertificationService.listCertifications(
        req.user,
        orgId,
        status
      );

      res.status(200).json({
        success: true,
        data: certs,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * PATCH /organizations/:orgId/certifications/:certId/revoke
   */
  static async revokeCertification(req: Request, res: Response, next: NextFunction) {
    try {
      if (!req.user) throw new UnauthorizedError("Authentication required.");
      const orgId = req.params.orgId as string;
      const certId = req.params.certId as string;
      const parsed = RevokeCertificationSchema.safeParse(req.body || {});
      if (!parsed.success) {
        throw parsed.error;
      }

      const revoked = await OrganizationCertificationService.revokeCertification(
        req.user,
        orgId,
        certId,
        parsed.data.reason
      );

      res.status(200).json({
        success: true,
        data: revoked,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * GET /organizations/:id/officials (public safe list of active certified officials)
   */
  static async listPublicOfficials(req: Request, res: Response, next: NextFunction) {
    try {
      const orgIdOrSlug = req.params.id as string;
      const officials = await OrganizationCertificationService.listPublicOfficials(orgIdOrSlug);
      res.status(200).json({
        success: true,
        data: officials,
      });
    } catch (error) {
      next(error);
    }
  }
}
