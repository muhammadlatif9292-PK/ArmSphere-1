import { Request, Response, NextFunction } from "express";
import { z } from "zod";
import { SparringInviteService } from "../services/sparringInvite.js";
import { BadRequestError } from "@armsphere/core";

const createSparringInviteSchema = z.object({
  senderTeamId: z.string().uuid("senderTeamId must be a valid UUID"),
  recipientTeamId: z.string().uuid("recipientTeamId must be a valid UUID"),
  scheduledDate: z.string().datetime().optional(),
  location: z.string().max(255).optional(),
  message: z.string().max(2000).optional(),
});

const respondSparringInviteSchema = z.object({
  action: z.enum(["ACCEPT", "DECLINE"], {
    errorMap: () => ({ message: "Action must be either ACCEPT or DECLINE" }),
  }),
});

export class SparringInviteController {
  /**
   * Create a new sparring invite
   */
  static async createInvite(req: Request, res: Response, next: NextFunction) {
    try {
      const parsed = createSparringInviteSchema.safeParse(req.body);
      if (!parsed.success) {
        throw new BadRequestError(
          parsed.error.errors.map((e) => `${e.path.join(".")}: ${e.message}`).join(", ")
        );
      }

      const invite = await SparringInviteService.createInvite(req.user!.id, parsed.data);

      res.status(201).json({
        success: true,
        data: invite,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * List sent / received sparring invites
   */
  static async listInvites(req: Request, res: Response, next: NextFunction) {
    try {
      const { teamId, direction, status } = req.query;

      const invites = await SparringInviteService.listInvites(req.user!.id, {
        teamId: typeof teamId === "string" ? teamId : undefined,
        direction: direction === "sent" || direction === "received" ? direction : undefined,
        status: typeof status === "string" ? status : undefined,
      });

      res.status(200).json({
        success: true,
        data: invites,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Get single invite details
   */
  static async getInviteById(req: Request, res: Response, next: NextFunction) {
    try {
      const { id } = req.params;
      const invite = await SparringInviteService.getInviteById(req.user!.id, id);

      res.status(200).json({
        success: true,
        data: invite,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Respond to an invite (ACCEPT / DECLINE)
   */
  static async respondInvite(req: Request, res: Response, next: NextFunction) {
    try {
      const { id } = req.params;
      const parsed = respondSparringInviteSchema.safeParse(req.body);
      if (!parsed.success) {
        throw new BadRequestError(
          parsed.error.errors.map((e) => `${e.path.join(".")}: ${e.message}`).join(", ")
        );
      }

      const updated = await SparringInviteService.respondInvite(
        req.user!.id,
        id,
        parsed.data.action
      );

      res.status(200).json({
        success: true,
        data: updated,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Cancel an invite (Sender only)
   */
  static async cancelInvite(req: Request, res: Response, next: NextFunction) {
    try {
      const { id } = req.params;
      const cancelled = await SparringInviteService.cancelInvite(req.user!.id, id);

      res.status(200).json({
        success: true,
        data: cancelled,
      });
    } catch (error) {
      next(error);
    }
  }
}
