import { Router } from "express";
import { RankingsController } from "../controllers/rankings.js";
import { authenticate, requireRole } from "../middlewares/auth.js";
import { UserRole } from "@armsphere/types";

export const rankingsRouter = Router();

rankingsRouter.get("/leaderboard", authenticate, RankingsController.getLeaderboard);

rankingsRouter.post(
  "/snapshots",
  authenticate,
  requireRole(UserRole.NATIONAL_DIRECTOR, UserRole.SYSTEM_ADMIN),
  RankingsController.triggerSnapshot
);

export default rankingsRouter;
