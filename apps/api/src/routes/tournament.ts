import { Router } from "express";
import { TournamentController } from "../controllers/tournament.js";
import { authenticate, requireRole } from "../middlewares/auth.js";
import { UserRole } from "@armsphere/types";
import { rateLimiter } from "../middlewares/security.js";

export const tournamentRouter = Router();

// --- Event Management ---
tournamentRouter.get(
  "/events",
  authenticate,
  TournamentController.listEvents
);

tournamentRouter.get(
  "/events/:id",
  authenticate,
  TournamentController.getEvent
);

tournamentRouter.post(
  "/events",
  authenticate,
  requireRole(UserRole.PROVINCIAL_DIRECTOR, UserRole.NATIONAL_DIRECTOR, UserRole.SYSTEM_ADMIN),
  TournamentController.createEvent
);

tournamentRouter.put(
  "/events/:id",
  authenticate,
  requireRole(UserRole.PROVINCIAL_DIRECTOR, UserRole.NATIONAL_DIRECTOR, UserRole.SYSTEM_ADMIN),
  TournamentController.editEvent
);

tournamentRouter.patch(
  "/events/:id",
  authenticate,
  TournamentController.patchEvent
);

tournamentRouter.get(
  "/events/:id/registrations",
  authenticate,
  TournamentController.getEventRegistrations
);

tournamentRouter.post(
  "/events/:id/cancel",
  authenticate,
  requireRole(UserRole.PROVINCIAL_DIRECTOR, UserRole.NATIONAL_DIRECTOR, UserRole.SYSTEM_ADMIN),
  TournamentController.cancelEvent
);

tournamentRouter.post(
  "/events/:id/publish",
  authenticate,
  requireRole(UserRole.PROVINCIAL_DIRECTOR, UserRole.NATIONAL_DIRECTOR, UserRole.SYSTEM_ADMIN),
  TournamentController.publishEvent
);

// --- Athlete Registration ---
tournamentRouter.post(
  "/registrations",
  authenticate,
  rateLimiter(60 * 1000, 5),
  TournamentController.registerAthlete
);

tournamentRouter.post(
  "/registrations/:id/approve",
  authenticate,
  requireRole(UserRole.PROVINCIAL_DIRECTOR, UserRole.NATIONAL_DIRECTOR, UserRole.SYSTEM_ADMIN),
  TournamentController.approveRegistration
);

tournamentRouter.post(
  "/registrations/:id/confirm-manual-payment",
  authenticate,
  TournamentController.confirmManualPayment
);

// --- Weigh-In System ---
tournamentRouter.post(
  "/weighins",
  authenticate,
  requireRole(UserRole.REFEREE, UserRole.PROVINCIAL_DIRECTOR, UserRole.NATIONAL_DIRECTOR, UserRole.SYSTEM_ADMIN),
  TournamentController.recordWeighIn
);

tournamentRouter.post(
  "/registrations/reassign",
  authenticate,
  requireRole(UserRole.REFEREE, UserRole.PROVINCIAL_DIRECTOR, UserRole.NATIONAL_DIRECTOR, UserRole.SYSTEM_ADMIN),
  TournamentController.reassignRegistration
);

tournamentRouter.post(
  "/registrations/:id/certify",
  authenticate,
  requireRole(UserRole.REFEREE, UserRole.PROVINCIAL_DIRECTOR, UserRole.NATIONAL_DIRECTOR, UserRole.SYSTEM_ADMIN),
  TournamentController.certifyWeighIn
);

// --- Seeding & Brackets ---
tournamentRouter.post(
  "/brackets",
  authenticate,
  requireRole(UserRole.PROVINCIAL_DIRECTOR, UserRole.NATIONAL_DIRECTOR, UserRole.SYSTEM_ADMIN),
  TournamentController.createBracket
);

tournamentRouter.get(
  "/brackets",
  authenticate,
  TournamentController.listBrackets
);

tournamentRouter.get(
  "/brackets/:id",
  authenticate,
  TournamentController.getBracket
);

tournamentRouter.post(
  "/brackets/:id/seeds",
  authenticate,
  requireRole(UserRole.PROVINCIAL_DIRECTOR, UserRole.NATIONAL_DIRECTOR, UserRole.SYSTEM_ADMIN),
  TournamentController.generateSeeds
);

tournamentRouter.post(
  "/brackets/seeds/override",
  authenticate,
  requireRole(UserRole.PROVINCIAL_DIRECTOR, UserRole.NATIONAL_DIRECTOR, UserRole.SYSTEM_ADMIN),
  TournamentController.overrideSeed
);

tournamentRouter.post(
  "/brackets/:id/seeds/lock",
  authenticate,
  requireRole(UserRole.PROVINCIAL_DIRECTOR, UserRole.NATIONAL_DIRECTOR, UserRole.SYSTEM_ADMIN),
  TournamentController.lockSeeds
);

tournamentRouter.post(
  "/brackets/:id/generate",
  authenticate,
  requireRole(UserRole.PROVINCIAL_DIRECTOR, UserRole.NATIONAL_DIRECTOR, UserRole.SYSTEM_ADMIN),
  TournamentController.generateBracketMatches
);

// --- Table & Referee Match Management ---
tournamentRouter.post(
  "/tables",
  authenticate,
  requireRole(UserRole.PROVINCIAL_DIRECTOR, UserRole.NATIONAL_DIRECTOR, UserRole.SYSTEM_ADMIN),
  TournamentController.createTable
);

tournamentRouter.post(
  "/matches/referee",
  authenticate,
  requireRole(UserRole.PROVINCIAL_DIRECTOR, UserRole.NATIONAL_DIRECTOR, UserRole.SYSTEM_ADMIN),
  TournamentController.assignReferee
);

tournamentRouter.post(
  "/matches/call",
  authenticate,
  requireRole(UserRole.REFEREE, UserRole.PROVINCIAL_DIRECTOR, UserRole.NATIONAL_DIRECTOR, UserRole.SYSTEM_ADMIN),
  TournamentController.callMatchToTable
);

tournamentRouter.post(
  "/matches/result",
  authenticate,
  requireRole(UserRole.REFEREE, UserRole.PROVINCIAL_DIRECTOR, UserRole.NATIONAL_DIRECTOR, UserRole.SYSTEM_ADMIN),
  TournamentController.submitMatchResult
);

// --- Metrics & Reports ---
tournamentRouter.get(
  "/events/:id/stats",
  authenticate,
  TournamentController.getEventStats
);

tournamentRouter.get(
  "/metrics/participation",
  authenticate,
  TournamentController.getParticipationMetrics
);

tournamentRouter.get(
  "/events/:id/medals",
  authenticate,
  TournamentController.getMedalTable
);

tournamentRouter.get(
  "/events/:id/club-standings",
  authenticate,
  TournamentController.getClubStandings
);
