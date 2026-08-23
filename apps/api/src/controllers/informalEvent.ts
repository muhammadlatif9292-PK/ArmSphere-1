import { Request, Response, NextFunction } from "express";
import { InformalEventService } from "../services/informalEvent.js";
import { z } from "zod";

// Validation Schemas
const createEventSchema = z.object({
  title: z.string().min(1, "Title is required"),
  description: z.string().min(1, "Description is required"),
  city: z.string().min(1, "City is required"),
  province: z.string().optional(),
  scheduledAt: z.string().min(1, "Scheduled date/time is required"),
  maxParticipants: z.preprocess(
    (val) => (val === "" || val === undefined || val === null ? undefined : parseInt(val as string, 10)),
    z.number().min(1).optional()
  ),
  isPublic: z.preprocess(
    (val) => (val === "false" || val === false ? false : true),
    z.boolean().default(true)
  ),
});

const getEventsQuerySchema = z.object({
  city: z.string().optional(),
  startDate: z.string().optional(),
  endDate: z.string().optional(),
  upcomingOnly: z.preprocess(
    (val) => (val === "false" || val === false ? false : true),
    z.boolean().default(true)
  ),
  limit: z.preprocess((val) => (val ? parseInt(val as string, 10) : 20), z.number().min(1).max(100)).default(20),
  offset: z.preprocess((val) => (val ? parseInt(val as string, 10) : 0), z.number().min(0)).default(0),
});

export class InformalEventController {
  /**
   * Create a new informal event
   */
  static async createEvent(req: Request, res: Response, next: NextFunction) {
    try {
      const validated = createEventSchema.parse(req.body);
      const userId = req.user!.id;

      const event = await InformalEventService.createEvent(userId, validated as any);

      res.status(201).json({
        success: true,
        data: event,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * List all informal events (filterable and paginated)
   */
  static async getEvents(req: Request, res: Response, next: NextFunction) {
    try {
      const filters = getEventsQuerySchema.parse(req.query);
      const events = await InformalEventService.getEvents(filters as any);

      res.status(200).json({
        success: true,
        data: events,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Retrieve details for a specific informal event (includes participants list)
   */
  static async getEventById(req: Request, res: Response, next: NextFunction) {
    try {
      const { id } = req.params;
      const event = await InformalEventService.getEventById(id);

      res.status(200).json({
        success: true,
        data: event,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Join an informal event
   */
  static async joinEvent(req: Request, res: Response, next: NextFunction) {
    try {
      const { id } = req.params;
      const userId = req.user!.id;

      const participant = await InformalEventService.joinEvent(userId, id);

      res.status(201).json({
        success: true,
        message: "Successfully joined informal event",
        data: participant,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Leave an informal event
   */
  static async leaveEvent(req: Request, res: Response, next: NextFunction) {
    try {
      const { id } = req.params;
      const userId = req.user!.id;

      await InformalEventService.leaveEvent(userId, id);

      res.status(200).json({
        success: true,
        message: "Successfully left informal event",
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Delete/cancel an informal event
   */
  static async deleteEvent(req: Request, res: Response, next: NextFunction) {
    try {
      const { id } = req.params;
      const userId = req.user!.id;
      const role = req.user!.role;

      await InformalEventService.deleteEvent(userId, id, role);

      res.status(200).json({
        success: true,
        message: "Successfully deleted informal event",
      });
    } catch (error) {
      next(error);
    }
  }
}
