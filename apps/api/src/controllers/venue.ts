import { Request, Response, NextFunction } from "express";
import { VenueService } from "../services/venue.js";
import { z } from "zod";

// Validation Schemas
const createVenueSchema = z.object({
  name: z.string().min(2, "Venue name must be at least 2 characters"),
  city: z.string().min(1, "City is required"),
  province: z.string().min(1, "Province is required"),
  address: z.string().min(5, "Address must be at least 5 characters"),
  contactInfo: z.string().optional(),
  description: z.string().optional(),
  logoUrl: z.string().optional(),
});

const updateVenueSchema = createVenueSchema.partial();

const getVenuesQuerySchema = z.object({
  city: z.string().optional(),
  province: z.string().optional(),
  limit: z.preprocess((val) => (val ? parseInt(val as string, 10) : 20), z.number().min(1).max(100)).default(20),
  offset: z.preprocess((val) => (val ? parseInt(val as string, 10) : 0), z.number().min(0)).default(0),
});

export class VenueController {
  /**
   * Submit a new venue
   */
  static async createVenue(req: Request, res: Response, next: NextFunction) {
    try {
      const validated = createVenueSchema.parse(req.body);
      const userId = req.user!.id;

      const venue = await VenueService.createVenue(userId, validated as any);

      res.status(201).json({
        success: true,
        data: venue,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * List venues (public, filterable, paginated)
   */
  static async getVenues(req: Request, res: Response, next: NextFunction) {
    try {
      const filters = getVenuesQuerySchema.parse(req.query);
      const venues = await VenueService.getVenues(filters as any);

      res.status(200).json({
        success: true,
        data: venues,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Retrieve venue by ID
   */
  static async getVenueById(req: Request, res: Response, next: NextFunction) {
    try {
      const { id } = req.params;
      const venue = await VenueService.getVenueById(id);

      res.status(200).json({
        success: true,
        data: venue,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Edit venue (owner or admin only)
   */
  static async updateVenue(req: Request, res: Response, next: NextFunction) {
    try {
      const { id } = req.params;
      const validated = updateVenueSchema.parse(req.body);
      const actorUserId = req.user!.id;
      const actorRole = req.user!.role;

      const updated = await VenueService.updateVenue(actorUserId, id, validated, actorRole);

      res.status(200).json({
        success: true,
        data: updated,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Verify venue (admin roles only)
   */
  static async verifyVenue(req: Request, res: Response, next: NextFunction) {
    try {
      const { id } = req.params;
      const actorUserId = req.user!.id;
      const actorRole = req.user!.role;

      const verified = await VenueService.verifyVenue(actorUserId, id, actorRole);

      res.status(200).json({
        success: true,
        data: verified,
      });
    } catch (error) {
      next(error);
    }
  }
}
