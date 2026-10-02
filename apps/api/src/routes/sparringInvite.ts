import { Router } from "express";
import { SparringInviteController } from "../controllers/sparringInvite.js";
import { authenticate, requireRole } from "../middlewares/auth.js";
import { UserRole } from "@armsphere/types";

export const sparringInviteRouter = Router();

// Create sparring invite
sparringInviteRouter.post(
  "/",
  authenticate,
  requireRole(UserRole.ORGANIZATION_LEADER, UserRole.ATHLETE, UserRole.SYSTEM_ADMIN),
  SparringInviteController.createInvite
);

// List sparring invites (sent / received)
sparringInviteRouter.get(
  "/",
  authenticate,
  SparringInviteController.listInvites
);

// Get single invite details
sparringInviteRouter.get(
  "/:id",
  authenticate,
  SparringInviteController.getInviteById
);

// Respond to sparring invite (ACCEPT or DECLINE)
sparringInviteRouter.post(
  "/:id/respond",
  authenticate,
  requireRole(UserRole.ORGANIZATION_LEADER, UserRole.ATHLETE, UserRole.SYSTEM_ADMIN),
  SparringInviteController.respondInvite
);

// Cancel sparring invite (Sender only)
sparringInviteRouter.post(
  "/:id/cancel",
  authenticate,
  requireRole(UserRole.ORGANIZATION_LEADER, UserRole.ATHLETE, UserRole.SYSTEM_ADMIN),
  SparringInviteController.cancelInvite
);
