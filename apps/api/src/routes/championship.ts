import { Router } from "express";
import { ChampionshipController } from "../controllers/championship.js";
import { authenticate, requireRole } from "../middlewares/auth.js";
import { UserRole } from "@armsphere/types";

export const championshipRouter = Router();

championshipRouter.post(
  "/titles",
  authenticate,
  requireRole(UserRole.NATIONAL_DIRECTOR, UserRole.SYSTEM_ADMIN),
  ChampionshipController.createTitle
);

championshipRouter.post(
  "/challenges",
  authenticate,
  ChampionshipController.submitChallenge
);

championshipRouter.post(
  "/challenges/:challengeId/accept",
  authenticate,
  ChampionshipController.acceptChallenge
);

championshipRouter.post(
  "/challenges/:challengeId/decline",
  authenticate,
  ChampionshipController.declineChallenge
);

championshipRouter.post(
  "/defend",
  authenticate,
  requireRole(UserRole.REFEREE, UserRole.PROVINCIAL_DIRECTOR, UserRole.NATIONAL_DIRECTOR, UserRole.SYSTEM_ADMIN),
  ChampionshipController.defendTitle
);

championshipRouter.post(
  "/vacate",
  authenticate,
  requireRole(UserRole.NATIONAL_DIRECTOR, UserRole.SYSTEM_ADMIN),
  ChampionshipController.vacateTitle
);

championshipRouter.get(
  "/titles",
  authenticate,
  ChampionshipController.getActiveTitles
);

championshipRouter.get(
  "/challenges",
  authenticate,
  ChampionshipController.getChallenges
);

championshipRouter.get(
  "/titles/:titleId/lineage",
  authenticate,
  ChampionshipController.getLineageHistory
);

championshipRouter.post(
  "/prestige/recompute",
  authenticate,
  requireRole(UserRole.SYSTEM_ADMIN),
  ChampionshipController.recomputePrestige
);

export default championshipRouter;
