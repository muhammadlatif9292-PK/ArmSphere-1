import { Request, Response, NextFunction } from "express";
import { z } from "zod";
import { SupportService } from "../services/support.js";
import { BadRequestError } from "@armsphere/core";

const createTicketSchema = z.object({
  subject: z.string().min(1, "Subject is required").max(255),
  description: z.string().min(1, "Description is required"),
  category: z.string().optional(),
  priority: z.string().optional(),
});

const assignTicketSchema = z.object({
  agentId: z.string().uuid("Invalid agent user ID").nullable(),
});

const updateStatusSchema = z.object({
  status: z.string().min(1, "Status is required"),
  resolutionNotes: z.string().optional(),
});

const addMessageSchema = z.object({
  message: z.string().min(1, "Message content is required"),
  isInternal: z.boolean().optional(),
});

export class SupportController {
  static async createTicket(req: Request, res: Response, next: NextFunction) {
    try {
      const parseResult = createTicketSchema.safeParse(req.body);
      if (!parseResult.success) {
        throw new BadRequestError(parseResult.error.issues[0].message);
      }

      const userId = (req as any).user.id;
      const ticket = await SupportService.createTicket(userId, parseResult.data);
      res.status(201).json({ success: true, data: ticket });
    } catch (error) {
      next(error);
    }
  }

  static async listTickets(req: Request, res: Response, next: NextFunction) {
    try {
      const user = (req as any).user;
      const { status, category, assignedAgentId, myTicketsOnly } = req.query;

      const tickets = await SupportService.listTickets(user.id, user.role, {
        status: status ? String(status) : undefined,
        category: category ? String(category) : undefined,
        assignedAgentId: assignedAgentId ? String(assignedAgentId) : undefined,
        myTicketsOnly: myTicketsOnly === "true",
      });

      res.status(200).json({ success: true, data: tickets });
    } catch (error) {
      next(error);
    }
  }

  static async getTicket(req: Request, res: Response, next: NextFunction) {
    try {
      const user = (req as any).user;
      const ticketId = req.params.id;

      const ticket = await SupportService.getTicket(user.id, user.role, ticketId);
      res.status(200).json({ success: true, data: ticket });
    } catch (error) {
      next(error);
    }
  }

  static async assignTicket(req: Request, res: Response, next: NextFunction) {
    try {
      const parseResult = assignTicketSchema.safeParse(req.body);
      if (!parseResult.success) {
        throw new BadRequestError(parseResult.error.issues[0].message);
      }

      const user = (req as any).user;
      const ticketId = req.params.id;

      const ticket = await SupportService.assignTicket(
        user.id,
        user.role,
        ticketId,
        parseResult.data.agentId
      );

      res.status(200).json({ success: true, data: ticket });
    } catch (error) {
      next(error);
    }
  }

  static async updateTicketStatus(req: Request, res: Response, next: NextFunction) {
    try {
      const parseResult = updateStatusSchema.safeParse(req.body);
      if (!parseResult.success) {
        throw new BadRequestError(parseResult.error.issues[0].message);
      }

      const user = (req as any).user;
      const ticketId = req.params.id;

      const ticket = await SupportService.updateTicketStatus(
        user.id,
        user.role,
        ticketId,
        parseResult.data.status,
        parseResult.data.resolutionNotes
      );

      res.status(200).json({ success: true, data: ticket });
    } catch (error) {
      next(error);
    }
  }

  static async addTicketMessage(req: Request, res: Response, next: NextFunction) {
    try {
      const parseResult = addMessageSchema.safeParse(req.body);
      if (!parseResult.success) {
        throw new BadRequestError(parseResult.error.issues[0].message);
      }

      const user = (req as any).user;
      const ticketId = req.params.id;

      const message = await SupportService.addMessage(
        user.id,
        user.role,
        ticketId,
        parseResult.data.message,
        parseResult.data.isInternal
      );

      res.status(201).json({ success: true, data: message });
    } catch (error) {
      next(error);
    }
  }
}
