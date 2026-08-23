import { Request, Response, NextFunction } from "express";
import { AnalyticsService } from "../services/analytics.js";

export class AnalyticsController {
  /**
   * Retrieves high-level overview metrics of the arm wrestling ecosystem
   */
  static async getOverview(req: Request, res: Response, next: NextFunction) {
    try {
      const overview = await AnalyticsService.getOverview();
      res.status(200).json({
        success: true,
        data: overview,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Retrieves ELO ratings distribution histogram data
   */
  static async getEloDistribution(req: Request, res: Response, next: NextFunction) {
    try {
      const distribution = await AnalyticsService.getEloDistribution();
      res.status(200).json({
        success: true,
        data: distribution,
      });
    } catch (error) {
      next(error);
    }
  }
}
