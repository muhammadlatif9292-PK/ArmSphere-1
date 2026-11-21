import { Request, Response, NextFunction } from "express";
import { z } from "zod";
import { RadarService, RadarPinType } from "../services/radar.js";

const nearbyQuerySchema = z.object({
  north: z.coerce.number().min(-90).max(90),
  south: z.coerce.number().min(-90).max(90),
  east: z.coerce.number().min(-180).max(180),
  west: z.coerce.number().min(-180).max(180),
  pinType: z
    .enum(["ALL", "EVENT", "VENUE", "ATHLETE", "BEACON", "CLUB", "INFORMAL_EVENT"])
    .optional(),
  type: z
    .enum(["ALL", "EVENT", "VENUE", "ATHLETE", "BEACON", "CLUB", "INFORMAL_EVENT"])
    .optional(),
  weightClass: z.string().max(50).optional(),
  armPreference: z.string().max(20).optional(),
  limit: z.coerce.number().int().min(1).max(500).default(200),
});

const createBeaconSchema = z.object({
  beaconType: z.string().trim().min(2).max(30).default("SPARRING"),
  title: z.string().trim().min(2, "Beacon title must be at least 2 characters").max(255),
  latitude: z.number().min(-90).max(90),
  longitude: z.number().min(-180).max(180),
  weightClass: z.string().trim().max(50).optional(),
  armPreference: z.string().trim().max(20).optional(),
  expiresAt: z
    .string()
    .refine((val) => !isNaN(Date.parse(val)), { message: "Invalid expiresAt timestamp" })
    .transform((val) => new Date(val))
    .optional(),
  durationHours: z.number().min(1).max(336).optional(),
});

const beaconIdParamSchema = z.string().uuid("Invalid radar beacon ID");

export class RadarController {
  /**
   * GET /api/radar/nearby
   */
  static async getNearby(req: Request, res: Response, next: NextFunction) {
    try {
      const parsed = nearbyQuerySchema.parse(req.query);
      const effectivePinType = (parsed.pinType || parsed.type || "ALL") as RadarPinType | "ALL";

      const result = await RadarService.getNearby({
        bounds: {
          north: parsed.north,
          south: parsed.south,
          east: parsed.east,
          west: parsed.west,
        },
        pinType: effectivePinType,
        weightClass: parsed.weightClass,
        armPreference: parsed.armPreference,
        limit: parsed.limit,
        viewerUserId: req.user!.id,
      });

      res.status(200).json({
        success: true,
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * POST /api/radar/beacons
   */
  static async createBeacon(req: Request, res: Response, next: NextFunction) {
    try {
      const validated = createBeaconSchema.parse(req.body);
      const beacon = await RadarService.createBeacon(req.user!.id, validated);

      res.status(201).json({
        success: true,
        data: beacon,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * DELETE /api/radar/beacons/:id
   */
  static async deleteBeacon(req: Request, res: Response, next: NextFunction) {
    try {
      const id = beaconIdParamSchema.parse(req.params.id);
      const result = await RadarService.deleteBeacon(id, req.user!.id, req.user?.role);

      res.status(200).json({
        success: true,
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }
}
