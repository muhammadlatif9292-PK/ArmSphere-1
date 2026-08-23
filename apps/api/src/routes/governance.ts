import { Router } from "express";
import { GovernanceController } from "../controllers/governance.js";
import { authenticate, requireRole } from "../middlewares/auth.js";
import { UserRole } from "@armsphere/types";

export const governanceRouter = Router();

// --- Dispute Management Endpoints ---
governanceRouter.get(
  "/disputes",
  authenticate,
  GovernanceController.listDisputes
);

governanceRouter.post(
  "/disputes", 
  authenticate, 
  GovernanceController.createDispute
);

governanceRouter.post(
  "/disputes/:id/assign", 
  authenticate, 
  requireRole(UserRole.PROVINCIAL_DIRECTOR, UserRole.NATIONAL_DIRECTOR, UserRole.SYSTEM_ADMIN),
  GovernanceController.assignReviewer
);

governanceRouter.post(
  "/disputes/:id/evidence", 
  authenticate, 
  GovernanceController.submitEvidence
);

governanceRouter.post(
  "/disputes/:id/comments", 
  authenticate, 
  GovernanceController.addComment
);

governanceRouter.post(
  "/disputes/:id/resolve", 
  authenticate, 
  requireRole(UserRole.REFEREE, UserRole.PROVINCIAL_DIRECTOR, UserRole.NATIONAL_DIRECTOR, UserRole.SYSTEM_ADMIN),
  GovernanceController.resolveDispute
);

governanceRouter.post(
  "/disputes/:id/escalate", 
  authenticate, 
  GovernanceController.escalateDispute
);

governanceRouter.post(
  "/disputes/:id/appeal", 
  authenticate, 
  GovernanceController.appealResolution
);

// --- Sanctions Endpoints ---
governanceRouter.post(
  "/sanctions", 
  authenticate, 
  requireRole(UserRole.NATIONAL_DIRECTOR, UserRole.SYSTEM_ADMIN),
  GovernanceController.createSanction
);

governanceRouter.post(
  "/sanctions/sweep", 
  authenticate, 
  requireRole(UserRole.NATIONAL_DIRECTOR, UserRole.SYSTEM_ADMIN),
  GovernanceController.sweepSanctions
);

// --- Immutable Audit Ledger Endpoints ---
governanceRouter.get(
  "/audit/verify", 
  authenticate, 
  requireRole(UserRole.SYSTEM_ADMIN),
  GovernanceController.verifyAuditLedger
);

// --- Match Correction Endpoints ---
governanceRouter.post(
  "/matches/:id/correct", 
  authenticate, 
  requireRole(UserRole.NATIONAL_DIRECTOR, UserRole.SYSTEM_ADMIN),
  GovernanceController.correctMatchResult
);

// --- ELO Replay Engine Endpoints ---
governanceRouter.post(
  "/replay", 
  authenticate, 
  requireRole(UserRole.SYSTEM_ADMIN),
  GovernanceController.triggerEloRecalculation
);

governanceRouter.get(
  "/replay/status", 
  authenticate, 
  requireRole(UserRole.SYSTEM_ADMIN),
  GovernanceController.getReplayStatus
);

export default governanceRouter;
