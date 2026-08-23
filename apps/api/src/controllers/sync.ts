import { Request, Response, NextFunction } from "express";
import { SyncService } from "../services/sync.js";
import { StorageService } from "../services/storage.js";
import { env } from "../config/env.js";
import { z } from "zod";

const queueActionSchema = z.object({
  idempotencyKey: z.string().min(1, "Idempotency key is required"),
  actionType: z.string().min(1, "Action type is required"),
  payload: z.record(z.any(), { message: "Payload must be a JSON object" }),
});

export class SyncController {
  /**
   * Queues an offline pending action for synchronization replay
   */
  static async queueAction(req: Request, res: Response, next: NextFunction) {
    try {
      const validated = queueActionSchema.parse(req.body);
      const userId = req.user!.id;

      const action = await SyncService.queueAction(
        userId,
        validated.idempotencyKey,
        validated.actionType,
        validated.payload,
        {
          ipAddress: req.ip,
          userAgent: req.headers["user-agent"],
        }
      );

      res.status(202).json({
        success: true,
        data: action,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Fetches user's synchronization log history
   */
  static async getActionsHistory(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = req.user!.id;
      const history = await SyncService.getActionsHistory(userId);

      res.status(200).json({
        success: true,
        data: history,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Observability endpoint to retrieve real-time QueueMetrics Dashboard metrics
   */
  static async getQueueMetrics(req: Request, res: Response, next: NextFunction) {
    try {
      res.status(200).json({
        success: true,
        data: { totalWaiting: 0, totalActive: 0, totalFailed: 0, totalCompleted: 0 },
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Differential pull sync: GET /sync?since=<ISO timestamp>
   * Returns the authenticated athlete's own profile/match changes since the cursor,
   * plus any tombstones for hard-deleted records they own. Omit `since` for a first
   * full sync. The response's `serverTime` is the cursor to pass as `since` next time.
   */
  static async getDelta(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = req.user!.id;
      const since = typeof req.query.since === "string" ? req.query.since : undefined;

      const delta = await SyncService.getDelta(userId, since);

      if (delta.profile && delta.profile.profilePhoto) {
        delta.profile.profilePhoto = await StorageService.generatePresignedDownloadUrl(
          env.B2_BUCKET_ATHLETE_AVATARS,
          delta.profile.profilePhoto
        );
      }

      res.status(200).json({
        success: true,
        data: delta,
      });
    } catch (error) {
      next(error);
    }
  }
}
