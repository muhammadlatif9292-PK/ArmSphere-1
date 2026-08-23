import { Router } from "express";
import { AdministrationController } from "../controllers/administration.js";
import { authenticate, requireRole } from "../middlewares/auth.js";
import { UserRole } from "@armsphere/types";

export const adminRouter = Router();

// 1. Executive Dashboard (Accessible to all authorized roles)
adminRouter.get(
  "/dashboard/stats",
  authenticate,
  requireRole(
    UserRole.SYSTEM_ADMIN,
    UserRole.NATIONAL_DIRECTOR,
    UserRole.PROVINCIAL_DIRECTOR,
    UserRole.TOURNAMENT_OPERATOR,
    UserRole.COMPLIANCE_OFFICER,
    UserRole.SUPPORT_AGENT
  ),
  AdministrationController.getDashboardStats
);

// 2. Athlete Administration
adminRouter.get(
  "/athletes",
  authenticate,
  requireRole(
    UserRole.SYSTEM_ADMIN,
    UserRole.NATIONAL_DIRECTOR,
    UserRole.PROVINCIAL_DIRECTOR,
    UserRole.TOURNAMENT_OPERATOR,
    UserRole.COMPLIANCE_OFFICER,
    UserRole.SUPPORT_AGENT
  ),
  AdministrationController.getAthletes
);

adminRouter.post(
  "/athletes/:id/review",
  authenticate,
  requireRole(
    UserRole.SYSTEM_ADMIN,
    UserRole.NATIONAL_DIRECTOR,
    UserRole.PROVINCIAL_DIRECTOR,
    UserRole.COMPLIANCE_OFFICER
  ),
  AdministrationController.reviewProfile
);

adminRouter.post(
  "/athletes/:id/suspend",
  authenticate,
  requireRole(UserRole.SYSTEM_ADMIN, UserRole.NATIONAL_DIRECTOR, UserRole.PROVINCIAL_DIRECTOR),
  AdministrationController.suspendAthlete
);

adminRouter.post(
  "/athletes/:id/blacklist",
  authenticate,
  requireRole(UserRole.SYSTEM_ADMIN, UserRole.NATIONAL_DIRECTOR),
  AdministrationController.blacklistAthlete
);

adminRouter.post(
  "/athletes/:id/recover",
  authenticate,
  requireRole(UserRole.SYSTEM_ADMIN, UserRole.NATIONAL_DIRECTOR),
  AdministrationController.recoverAthlete
);

adminRouter.patch(
  "/athletes/:id/correct",
  authenticate,
  requireRole(UserRole.SYSTEM_ADMIN, UserRole.NATIONAL_DIRECTOR),
  AdministrationController.manualCorrection
);

// 3. Referee Administration
adminRouter.get(
  "/referees",
  authenticate,
  requireRole(
    UserRole.SYSTEM_ADMIN,
    UserRole.NATIONAL_DIRECTOR,
    UserRole.PROVINCIAL_DIRECTOR,
    UserRole.COMPLIANCE_OFFICER
  ),
  AdministrationController.getReferees
);

adminRouter.post(
  "/referees/:id/license",
  authenticate,
  requireRole(UserRole.SYSTEM_ADMIN, UserRole.NATIONAL_DIRECTOR),
  AdministrationController.updateRefereeLicense
);

adminRouter.post(
  "/referees/:id/suspend",
  authenticate,
  requireRole(UserRole.SYSTEM_ADMIN, UserRole.NATIONAL_DIRECTOR),
  AdministrationController.handleRefereeSuspension
);

adminRouter.post(
  "/referees/:id/region",
  authenticate,
  requireRole(UserRole.SYSTEM_ADMIN, UserRole.NATIONAL_DIRECTOR, UserRole.PROVINCIAL_DIRECTOR),
  AdministrationController.assignRefereeRegion
);

// 4. Match Administration
adminRouter.get(
  "/matches",
  authenticate,
  requireRole(
    UserRole.SYSTEM_ADMIN,
    UserRole.NATIONAL_DIRECTOR,
    UserRole.PROVINCIAL_DIRECTOR,
    UserRole.TOURNAMENT_OPERATOR,
    UserRole.COMPLIANCE_OFFICER
  ),
  AdministrationController.getMatches
);

adminRouter.get(
  "/matches/:id",
  authenticate,
  requireRole(
    UserRole.SYSTEM_ADMIN,
    UserRole.NATIONAL_DIRECTOR,
    UserRole.PROVINCIAL_DIRECTOR,
    UserRole.COMPLIANCE_OFFICER
  ),
  AdministrationController.inspectMatch
);

adminRouter.post(
  "/matches/:id/correct",
  authenticate,
  requireRole(UserRole.SYSTEM_ADMIN, UserRole.NATIONAL_DIRECTOR),
  AdministrationController.scoreCorrection
);

adminRouter.post(
  "/matches/:id/void",
  authenticate,
  requireRole(UserRole.SYSTEM_ADMIN, UserRole.NATIONAL_DIRECTOR),
  AdministrationController.voidMatch
);

// 5. Tournament Administration
adminRouter.get(
  "/events",
  authenticate,
  requireRole(
    UserRole.SYSTEM_ADMIN,
    UserRole.NATIONAL_DIRECTOR,
    UserRole.PROVINCIAL_DIRECTOR,
    UserRole.TOURNAMENT_OPERATOR
  ),
  AdministrationController.getEvents
);

adminRouter.post(
  "/events/weighin",
  authenticate,
  requireRole(
    UserRole.SYSTEM_ADMIN,
    UserRole.NATIONAL_DIRECTOR,
    UserRole.PROVINCIAL_DIRECTOR,
    UserRole.TOURNAMENT_OPERATOR
  ),
  AdministrationController.manageWeighIn
);

// 6. Championship Administration
adminRouter.post(
  "/championships/titles/:id",
  authenticate,
  requireRole(UserRole.SYSTEM_ADMIN, UserRole.NATIONAL_DIRECTOR),
  AdministrationController.manageChampionshipTitle
);

// 7. Disputes & Sanctions Center
adminRouter.get(
  "/disputes",
  authenticate,
  requireRole(
    UserRole.SYSTEM_ADMIN,
    UserRole.NATIONAL_DIRECTOR,
    UserRole.PROVINCIAL_DIRECTOR,
    UserRole.COMPLIANCE_OFFICER,
    UserRole.SUPPORT_AGENT
  ),
  AdministrationController.getDisputesTimeline
);

adminRouter.post(
  "/disputes/:id/resolve",
  authenticate,
  requireRole(UserRole.SYSTEM_ADMIN, UserRole.NATIONAL_DIRECTOR, UserRole.COMPLIANCE_OFFICER),
  AdministrationController.resolveDisputeCase
);

// 8. Immutable Audit Explorer
adminRouter.get(
  "/audit/events",
  authenticate,
  requireRole(UserRole.SYSTEM_ADMIN, UserRole.COMPLIANCE_OFFICER),
  AdministrationController.getAuditEvents
);

adminRouter.get(
  "/audit/verify",
  authenticate,
  requireRole(UserRole.SYSTEM_ADMIN, UserRole.COMPLIANCE_OFFICER),
  AdministrationController.verifyImmutableAuditLedger
);

// 11. Background Workers
adminRouter.post(
  "/workers/trigger",
  authenticate,
  requireRole(UserRole.SYSTEM_ADMIN),
  AdministrationController.triggerWorkerJob
);

adminRouter.post(
  "/scheduled-jobs/run",
  authenticate,
  requireRole(UserRole.SYSTEM_ADMIN),
  AdministrationController.runScheduledJobs
);

// 12. Reporting / Exports
adminRouter.post(
  "/reports/export",
  authenticate,
  requireRole(
    UserRole.SYSTEM_ADMIN,
    UserRole.NATIONAL_DIRECTOR,
    UserRole.PROVINCIAL_DIRECTOR,
    UserRole.COMPLIANCE_OFFICER
  ),
  AdministrationController.exportReport
);

export default adminRouter;
