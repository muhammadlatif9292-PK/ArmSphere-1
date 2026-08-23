import { Router } from "express";
import { RefereeCertificationController } from "../controllers/refereeCertification.js";
import { authenticate, requireRole } from "../middlewares/auth.js";
import { UserRole } from "@armsphere/types";

export const refereeCertificationRouter = Router();

// Issue a certification (Admin only)
refereeCertificationRouter.post(
  "/:userId/certifications",
  authenticate,
  requireRole(UserRole.SYSTEM_ADMIN, UserRole.NATIONAL_DIRECTOR, UserRole.PROVINCIAL_DIRECTOR),
  RefereeCertificationController.issueCertification
);

// List referee certifications (own user or admin can view)
refereeCertificationRouter.get(
  "/:userId/certifications",
  authenticate,
  RefereeCertificationController.listCertifications
);

// Revoke a certification (Admin only)
refereeCertificationRouter.patch(
  "/certifications/:id/revoke",
  authenticate,
  requireRole(UserRole.SYSTEM_ADMIN, UserRole.NATIONAL_DIRECTOR, UserRole.PROVINCIAL_DIRECTOR),
  RefereeCertificationController.revokeCertification
);

export default refereeCertificationRouter;
