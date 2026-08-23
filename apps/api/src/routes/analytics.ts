import { Router } from "express";
import { AnalyticsController } from "../controllers/analytics.js";
import { authenticate } from "../middlewares/auth.js";

export const analyticsRouter = Router();

analyticsRouter.get("/overview", authenticate, AnalyticsController.getOverview);
analyticsRouter.get("/elo-distribution", authenticate, AnalyticsController.getEloDistribution);

export default analyticsRouter;
