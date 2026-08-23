import { Router } from "express";
import { TicketController } from "../controllers/ticket.js";
import { authenticate, requireRole } from "../middlewares/auth.js";
import { UserRole } from "@armsphere/types";

export const ticketRouter = Router();

// 1. Organizer / Admin Operations
ticketRouter.post(
  "/events/:id/ticket-types",
  authenticate,
  requireRole(UserRole.PROVINCIAL_DIRECTOR, UserRole.NATIONAL_DIRECTOR, UserRole.SYSTEM_ADMIN),
  TicketController.createTicketType
);

ticketRouter.patch(
  "/ticket-types/:id",
  authenticate,
  requireRole(UserRole.PROVINCIAL_DIRECTOR, UserRole.NATIONAL_DIRECTOR, UserRole.SYSTEM_ADMIN),
  TicketController.editTicketType
);

ticketRouter.post(
  "/tickets/:id/refund",
  authenticate,
  TicketController.refundTicket
);

// 2. Public Operations
ticketRouter.get(
  "/events/:id/ticket-types",
  TicketController.listTicketTypes
);

// 3. Purchase Operations
ticketRouter.post(
  "/ticket-types/:id/purchase",
  authenticate,
  TicketController.purchaseTicket
);

// 4. My Tickets Operations
ticketRouter.get(
  "/tickets/mine",
  authenticate,
  TicketController.getMyTickets
);
