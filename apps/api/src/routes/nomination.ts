import { Router } from "express";
import { NominationController } from "../controllers/nomination.js";
import { authenticate, requireRole } from "../middlewares/auth.js";
import { UserRole } from "@armsphere/types";
import { rateLimiter } from "../middlewares/security.js";

export const nominationRouter = Router();

// Submit a new nomination (any authenticated user, rate-limited)
nominationRouter.post("/", authenticate, rateLimiter(60 * 1000, 5), NominationController.createNomination);

// Get own submitted nominations (any authenticated user)
nominationRouter.get("/mine", authenticate, NominationController.getOwnNominations);

// List all nominations (admin roles only)
nominationRouter.get(
  "/",
  authenticate,
  requireRole(UserRole.SYSTEM_ADMIN, UserRole.NATIONAL_DIRECTOR, UserRole.PROVINCIAL_DIRECTOR),
  NominationController.getNominations
);

// Update status (admin roles only)
nominationRouter.patch(
  "/:id/status",
  authenticate,
  requireRole(UserRole.SYSTEM_ADMIN, UserRole.NATIONAL_DIRECTOR, UserRole.PROVINCIAL_DIRECTOR),
  NominationController.updateNominationStatus
);

export default nominationRouter;
