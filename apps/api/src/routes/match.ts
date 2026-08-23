import { Router } from "express";
import { MatchController } from "../controllers/match.js";
import { authenticate, requireRole } from "../middlewares/auth.js";
import { UserRole } from "@armsphere/types";

export const matchRouter = Router();

// Ingest and retrieve match details
matchRouter.post(
  "/",
  authenticate,
  requireRole(UserRole.REFEREE, UserRole.PROVINCIAL_DIRECTOR, UserRole.NATIONAL_DIRECTOR, UserRole.SYSTEM_ADMIN),
  MatchController.submitMatch
);
matchRouter.get("/recent", authenticate, MatchController.getRecentMatches);
matchRouter.get("/:id", authenticate, MatchController.getMatch);

// Verification and rating calculation
matchRouter.post(
  "/:id/verify", 
  authenticate, 
  requireRole(UserRole.REFEREE, UserRole.PROVINCIAL_DIRECTOR, UserRole.NATIONAL_DIRECTOR, UserRole.SYSTEM_ADMIN), 
  MatchController.verifyMatch
);

// Dispute arbitration and manual reviews
matchRouter.post("/:id/dispute", authenticate, MatchController.disputeMatch);

// SRE / Admin corrective voiding actions (reverses rating adjustments)
matchRouter.post(
  "/:id/void", 
  authenticate, 
  requireRole(UserRole.PROVINCIAL_DIRECTOR, UserRole.NATIONAL_DIRECTOR, UserRole.SYSTEM_ADMIN), 
  MatchController.voidMatch
);

export default matchRouter;
