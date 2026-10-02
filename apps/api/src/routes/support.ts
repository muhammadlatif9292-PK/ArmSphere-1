import { Router } from "express";
import { SupportController } from "../controllers/support.js";
import { authenticate, requireRole } from "../middlewares/auth.js";
import { UserRole } from "@armsphere/types";

export const supportRouter = Router();

// 1. Create ticket (any authenticated user)
supportRouter.post(
  "/tickets",
  authenticate,
  SupportController.createTicket
);

// 2. List tickets (role-scoped: athletes see own tickets; staff sees all or filtered)
supportRouter.get(
  "/tickets",
  authenticate,
  SupportController.listTickets
);

// 3. Get single ticket with timeline
supportRouter.get(
  "/tickets/:id",
  authenticate,
  SupportController.getTicket
);

// 4. Assign ticket (SUPPORT_AGENT or SYSTEM_ADMIN)
supportRouter.post(
  "/tickets/:id/assign",
  authenticate,
  requireRole(UserRole.SUPPORT_AGENT, UserRole.SYSTEM_ADMIN),
  SupportController.assignTicket
);

// 5. Update ticket status
supportRouter.patch(
  "/tickets/:id/status",
  authenticate,
  SupportController.updateTicketStatus
);

// 6. Post reply / internal note
supportRouter.post(
  "/tickets/:id/messages",
  authenticate,
  SupportController.addTicketMessage
);
