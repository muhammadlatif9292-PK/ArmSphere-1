import { Request, Response, NextFunction } from "express";
import { TournamentService } from "../services/tournament.js";
import { z } from "zod";
import { ForbiddenError, NotFoundError } from "@armsphere/core";
import { UserRole } from "@armsphere/types";

const createEventSchema = z.object({
  name: z.string().min(3, "Event name must be at least 3 characters"),
  startDate: z.string().transform((val) => new Date(val)),
  endDate: z.string().transform((val) => new Date(val)),
  registrationStart: z.string().transform((val) => new Date(val)),
  registrationEnd: z.string().transform((val) => new Date(val)),
  province: z.string().min(2, "Province is required"),
  city: z.string().min(2, "City is required"),
  venue: z.string().min(3, "Venue is required"),
  capacity: z.number().int().positive("Capacity must be positive"),
  registrationFeeCents: z.number().int().nonnegative().optional(),
  paymentMethod: z.enum(["STRIPE", "MANUAL_QR"]).optional(),
  paymentQrImageUrl: z.string().nullable().optional(),
  organizerId: z.string().uuid().optional(),
});

const editEventSchema = z.object({
  name: z.string().min(3).optional(),
  startDate: z.string().transform((val) => new Date(val)).optional(),
  endDate: z.string().transform((val) => new Date(val)).optional(),
  registrationStart: z.string().transform((val) => new Date(val)).optional(),
  registrationEnd: z.string().transform((val) => new Date(val)).optional(),
  province: z.string().min(2).optional(),
  city: z.string().min(2).optional(),
  venue: z.string().min(3).optional(),
  capacity: z.number().int().positive().optional(),
  registrationFeeCents: z.number().int().nonnegative().optional(),
  paymentMethod: z.enum(["STRIPE", "MANUAL_QR"]).optional(),
  paymentQrImageUrl: z.string().nullable().optional(),
  organizerId: z.string().uuid().optional(),
});

const registerAthleteSchema = z.object({
  eventId: z.string().uuid("Event ID must be a valid UUID"),
  athleteId: z.string().uuid("Athlete ID must be a valid UUID"),
  division: z.string().min(2, "Division is required"),
  weightClass: z.string().min(2, "Weight class is required"),
  arm: z.enum(["LEFT", "RIGHT", "BOTH"]),
  notes: z.string().optional()
});

const recordWeighInSchema = z.object({
  registrationId: z.string().uuid("Registration ID must be a valid UUID"),
  weight: z.number().positive("Weight must be positive")
});

const reassignSchema = z.object({
  registrationId: z.string().uuid("Registration ID must be valid"),
  newDivision: z.string().min(2, "New division is required"),
  newWeightClass: z.string().min(2, "New weight class is required")
});

const createBracketSchema = z.object({
  eventId: z.string().uuid(),
  name: z.string().min(3),
  format: z.enum(["SINGLE_ELIMINATION", "DOUBLE_ELIMINATION", "ROUND_ROBIN", "SUPERMATCH", "GROUP_KNOCKOUT"]),
  division: z.string().min(2),
  weightClass: z.string().min(2),
  arm: z.enum(["LEFT", "RIGHT"])
});

const overrideSeedSchema = z.object({
  bracketId: z.string().uuid(),
  athleteId: z.string().uuid(),
  newPosition: z.number().int().positive()
});

const createTableSchema = z.object({
  name: z.string().min(2)
});

const assignRefereeSchema = z.object({
  matchId: z.string().uuid("Match ID must be a valid UUID"),
  refereeId: z.string().uuid("Referee ID must be a valid UUID")
});

const callMatchSchema = z.object({
  matchId: z.string(),
  tableId: z.string()
});

const submitResultSchema = z.object({
  matchId: z.string(),
  winnerId: z.string(),
  scoreLine: z.string().min(3)
});

export class TournamentController {
  // Event Management
  static async listEvents(req: Request, res: Response, next: NextFunction) {
    try {
      const { status, timeframe } = req.query;
      const parsedTimeframe = timeframe === "upcoming" || timeframe === "past" ? timeframe : undefined;
      const eventsList = await TournamentService.listEvents({
        status: status?.toString(),
        timeframe: parsedTimeframe
      });
      res.json(eventsList);
    } catch (error) {
      next(error);
    }
  }

  static async getEvent(req: Request, res: Response, next: NextFunction) {
    try {
      const { id } = req.params;
      const event = await TournamentService.getEvent(id);
      res.json(event);
    } catch (error) {
      next(error);
    }
  }

  static async createEvent(req: Request, res: Response, next: NextFunction) {
    try {
      const validated = createEventSchema.parse(req.body);
      const organizerId = validated.organizerId || req.user!.id;
      const event = await TournamentService.createEvent({
        ...validated,
        organizerId
      } as any);
      res.status(201).json(event);
    } catch (error) {
      next(error);
    }
  }

  static async editEvent(req: Request, res: Response, next: NextFunction) {
    try {
      const { id } = req.params;
      const validated = editEventSchema.parse(req.body);
      const event = await TournamentService.editEvent(id, validated);
      res.json(event);
    } catch (error) {
      next(error);
    }
  }

  static async cancelEvent(req: Request, res: Response, next: NextFunction) {
    try {
      const { id } = req.params;
      const event = await TournamentService.cancelEvent(id);
      res.json(event);
    } catch (error) {
      next(error);
    }
  }

  static async publishEvent(req: Request, res: Response, next: NextFunction) {
    try {
      const { id } = req.params;
      const event = await TournamentService.publishEvent(id);
      res.json(event);
    } catch (error) {
      next(error);
    }
  }

  // Athlete Registration
  static async registerAthlete(req: Request, res: Response, next: NextFunction) {
    try {
      const validated = registerAthleteSchema.parse(req.body);
      const registration = await TournamentService.registerAthlete(
        validated.eventId,
        validated.athleteId,
        {
          division: validated.division,
          weightClass: validated.weightClass,
          arm: validated.arm,
          notes: validated.notes
        }
      );
      res.status(201).json(registration);
    } catch (error) {
      next(error);
    }
  }

  static async approveRegistration(req: Request, res: Response, next: NextFunction) {
    try {
      const { id } = req.params;
      const registration = await TournamentService.approveRegistration(id, req.user!.id);
      res.json(registration);
    } catch (error) {
      next(error);
    }
  }

  // Weigh-In System
  static async recordWeighIn(req: Request, res: Response, next: NextFunction) {
    try {
      const validated = recordWeighInSchema.parse(req.body);
      const weighIn = await TournamentService.recordWeighIn(
        validated.registrationId,
        validated.weight,
        req.user!.id
      );
      res.status(201).json(weighIn);
    } catch (error) {
      next(error);
    }
  }

  static async reassignRegistration(req: Request, res: Response, next: NextFunction) {
    try {
      const validated = reassignSchema.parse(req.body);
      const registration = await TournamentService.reassignRegistration(
        validated.registrationId,
        validated.newDivision,
        validated.newWeightClass,
        req.user!.id
      );
      res.json(registration);
    } catch (error) {
      next(error);
    }
  }

  static async certifyWeighIn(req: Request, res: Response, next: NextFunction) {
    try {
      const { id } = req.params;
      const result = await TournamentService.certifyWeighIn(id, req.user!.id);
      res.json(result);
    } catch (error) {
      next(error);
    }
  }

  // Seeding Engine & Brackets
  static async createBracket(req: Request, res: Response, next: NextFunction) {
    try {
      const validated = createBracketSchema.parse(req.body);
      const bracket = await TournamentService.createBracket(
        validated.eventId,
        validated.name,
        validated.format,
        validated.division,
        validated.weightClass,
        validated.arm
      );
      res.status(201).json(bracket);
    } catch (error) {
      next(error);
    }
  }

  static async generateSeeds(req: Request, res: Response, next: NextFunction) {
    try {
      const { id } = req.params;
      const seeds = await TournamentService.generateSeeds(id);
      res.json(seeds);
    } catch (error) {
      next(error);
    }
  }

  static async overrideSeed(req: Request, res: Response, next: NextFunction) {
    try {
      const validated = overrideSeedSchema.parse(req.body);
      const result = await TournamentService.overrideSeed(
        validated.bracketId,
        validated.athleteId,
        validated.newPosition
      );
      res.json(result);
    } catch (error) {
      next(error);
    }
  }

  static async lockSeeds(req: Request, res: Response, next: NextFunction) {
    try {
      const { id } = req.params;
      const result = await TournamentService.lockSeeds(id);
      res.json(result);
    } catch (error) {
      next(error);
    }
  }

  static async generateBracketMatches(req: Request, res: Response, next: NextFunction) {
    try {
      const { id } = req.params;
      const result = await TournamentService.generateBracketMatches(id);
      res.json(result);
    } catch (error) {
      next(error);
    }
  }

  // Match Queue & Table Management
  static async createTable(req: Request, res: Response, next: NextFunction) {
    try {
      const validated = createTableSchema.parse(req.body);
      const table = await TournamentService.createTable(validated.name);
      res.status(201).json(table);
    } catch (error) {
      next(error);
    }
  }

  static async assignReferee(req: Request, res: Response, next: NextFunction) {
    try {
      const validated = assignRefereeSchema.parse(req.body);
      const updated = await TournamentService.assignReferee(validated.matchId, validated.refereeId);
      res.json(updated);
    } catch (error) {
      next(error);
    }
  }

  static async callMatchToTable(req: Request, res: Response, next: NextFunction) {
    try {
      const validated = callMatchSchema.parse(req.body);
      const updated = await TournamentService.callMatchToTable(validated.matchId, validated.tableId, req.user!.id);
      res.json(updated);
    } catch (error) {
      next(error);
    }
  }

  static async submitMatchResult(req: Request, res: Response, next: NextFunction) {
    try {
      const validated = submitResultSchema.parse(req.body);
      const updated = await TournamentService.submitMatchResult(
        validated.matchId,
        validated.winnerId,
        validated.scoreLine,
        req.user!.id
      );
      res.json(updated);
    } catch (error) {
      next(error);
    }
  }

  // Reports
  static async getEventStats(req: Request, res: Response, next: NextFunction) {
    try {
      const { id } = req.params;
      const stats = await TournamentService.getEventStats(id);
      res.json(stats);
    } catch (error) {
      next(error);
    }
  }

  static async getParticipationMetrics(req: Request, res: Response, next: NextFunction) {
    try {
      const metrics = await TournamentService.getParticipationMetrics();
      res.json(metrics);
    } catch (error) {
      next(error);
    }
  }

  static async getMedalTable(req: Request, res: Response, next: NextFunction) {
    try {
      const { id } = req.params;
      const medals = await TournamentService.getMedalTable(id);
      res.json(medals);
    } catch (error) {
      next(error);
    }
  }

  static async getClubStandings(req: Request, res: Response, next: NextFunction) {
    try {
      const { id } = req.params;
      const standings = await TournamentService.getClubStandings(id);
      res.json(standings);
    } catch (error) {
      next(error);
    }
  }

  static async getBracket(req: Request, res: Response, next: NextFunction) {
    try {
      const { id } = req.params;
      const bracket = await TournamentService.getBracket(id);
      res.json(bracket);
    } catch (error) {
      next(error);
    }
  }

  static async listBrackets(req: Request, res: Response, next: NextFunction) {
    try {
      const list = await TournamentService.listBrackets();
      res.json(list);
    } catch (error) {
      next(error);
    }
  }

  static async patchEvent(req: Request, res: Response, next: NextFunction) {
    try {
      const { id } = req.params;
      const event = await TournamentService.getEvent(id);
      if (!event) {
        throw new NotFoundError("Tournament event not found.");
      }

      const isOrganizer = event.organizerId && req.user!.id === event.organizerId;
      const isAdmin = req.user!.role === UserRole.SYSTEM_ADMIN || req.user!.role === UserRole.NATIONAL_DIRECTOR;

      if (!isOrganizer && !isAdmin) {
        throw new ForbiddenError("Only the event's organizer or an admin can modify this event.");
      }

      const validated = editEventSchema.partial().parse(req.body);
      const updatedEvent = await TournamentService.editEvent(id, validated as any);
      res.json(updatedEvent);
    } catch (error) {
      next(error);
    }
  }

  static async confirmManualPayment(req: Request, res: Response, next: NextFunction) {
    try {
      const { id } = req.params;
      const actorId = req.user!.id;
      const actorRole = req.user!.role;

      const updatedReg = await TournamentService.confirmManualPayment(id, actorId, actorRole);
      res.json(updatedReg);
    } catch (error) {
      next(error);
    }
  }

  static async getEventRegistrations(req: Request, res: Response, next: NextFunction) {
    try {
      const { id } = req.params;
      const event = await TournamentService.getEvent(id);
      if (!event) {
        throw new NotFoundError("Tournament event not found.");
      }

      const isOrganizer = event.organizerId && req.user!.id === event.organizerId;
      const isAdminOrDirector = req.user!.role === UserRole.SYSTEM_ADMIN || req.user!.role === UserRole.NATIONAL_DIRECTOR || req.user!.role === UserRole.PROVINCIAL_DIRECTOR;

      if (!isOrganizer && !isAdminOrDirector) {
        throw new ForbiddenError("Only the event's organizer, a director, or an admin can view registrations.");
      }

      const list = await TournamentService.getEventRegistrations(id);
      res.json(list);
    } catch (error) {
      next(error);
    }
  }
}
