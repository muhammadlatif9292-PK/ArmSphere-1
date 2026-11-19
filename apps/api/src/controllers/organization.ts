import { Request, Response, NextFunction } from "express";
import { OrganizationService } from "../services/organization.js";
import { z } from "zod";

const verifyAccessSchema = z.object({
  organizationId: z.string().uuid("Invalid organization ID format"),
  accessCode: z.string().min(4, "Access code must be at least 4 characters"),
});

const onboardSchema = z.object({
  presidentName: z.string().min(2, "President name is required"),
  foundationDate: z.string().transform((val) => new Date(val)),
  province: z.string().min(2, "Province is required"),
  city: z.string().min(2, "City is required"),
  contactEmail: z.string().email().optional(),
  contactPhone: z.string().min(6).optional(),
  logoUrl: z.string().url().optional(),
});

const adminCreateSchema = z.object({
  name: z.string().min(3, "Organization name must be at least 3 characters"),
  province: z.string().min(2, "Province is required"),
  city: z.string().optional(),
  accessCode: z.string().min(4).optional(),
});

export class OrganizationController {
  static async listApproved(req: Request, res: Response, next: NextFunction) {
    try {
      const orgs = await OrganizationService.listApprovedOrganizations();
      res.json({ success: true, data: orgs });
    } catch (err) {
      next(err);
    }
  }

  static async verifyAccess(req: Request, res: Response, next: NextFunction) {
    try {
      const validated = verifyAccessSchema.parse(req.body);
      const result = await OrganizationService.verifyAccessCode(validated.organizationId, validated.accessCode);
      res.json({ success: true, ...result });
    } catch (err) {
      next(err);
    }
  }

  static async onboard(req: Request, res: Response, next: NextFunction) {
    try {
      const organizationId = req.params.id;
      const validated = onboardSchema.parse(req.body);
      const updated = await OrganizationService.completeOnboarding(organizationId, validated);
      res.json({ success: true, organization: updated });
    } catch (err) {
      next(err);
    }
  }

  static async adminCreate(req: Request, res: Response, next: NextFunction) {
    try {
      const validated = adminCreateSchema.parse(req.body);
      const result = await OrganizationService.adminCreateOrganization({
        ...validated,
        adminUserId: req.user?.id,
      });
      res.status(201).json({ success: true, ...result });
    } catch (err) {
      next(err);
    }
  }

  static async adminRotateCode(req: Request, res: Response, next: NextFunction) {
    try {
      const organizationId = req.params.id;
      const result = await OrganizationService.adminRotateCode(
        organizationId,
        req.body.newCode,
        req.user?.id
      );
      res.json({ success: true, ...result });
    } catch (err) {
      next(err);
    }
  }
}
