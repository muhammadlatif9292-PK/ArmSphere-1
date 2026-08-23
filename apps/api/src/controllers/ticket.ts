import { Request, Response, NextFunction } from "express";
import { z } from "zod";
import { db } from "../config/db.js";
import { ticketTypes, tickets, events } from "@armsphere/db-schema";
import { eq, and, not, sql } from "drizzle-orm";
import { NotFoundError, BadRequestError, ForbiddenError } from "@armsphere/core";
import { getStripe } from "../services/stripe.js";

const createTicketTypeSchema = z.object({
  name: z.string().min(2, "Name is required"),
  priceCents: z.number().int().positive("Price must be a positive integer"),
  quantityAvailable: z.number().int().positive("Quantity must be a positive integer"),
});

const editTicketTypeSchema = z.object({
  priceCents: z.number().int().positive("Price must be a positive integer").optional(),
  quantityAvailable: z.number().int().positive("Quantity must be a positive integer").optional(),
});

export class TicketController {
  // Create a ticket tier (Organizer/Admin)
  static async createTicketType(req: Request, res: Response, next: NextFunction) {
    try {
      const eventId = req.params.id;
      const body = createTicketTypeSchema.parse(req.body);

      // Verify event exists
      const [event] = await db
        .select()
        .from(events)
        .where(eq(events.id, eventId))
        .limit(1);

      if (!event) {
        throw new NotFoundError("Event not found");
      }

      const [newType] = await db
        .insert(ticketTypes)
        .values({
          eventId,
          name: body.name,
          priceCents: body.priceCents,
          quantityAvailable: body.quantityAvailable,
          quantitySold: 0,
        })
        .returning();

      return res.status(201).json({
        success: true,
        data: newType,
      });
    } catch (error) {
      next(error);
    }
  }

  // Edit price/quantity of a tier (Organizer/Admin)
  static async editTicketType(req: Request, res: Response, next: NextFunction) {
    try {
      const ticketTypeId = req.params.id;
      const body = editTicketTypeSchema.parse(req.body);

      // Verify tier exists
      const [existingType] = await db
        .select()
        .from(ticketTypes)
        .where(eq(ticketTypes.id, ticketTypeId))
        .limit(1);

      if (!existingType) {
        throw new NotFoundError("Ticket type tier not found");
      }

      const updateData: Record<string, any> = {
        updatedAt: new Date(),
      };
      if (body.priceCents !== undefined) {
        updateData.priceCents = body.priceCents;
      }
      if (body.quantityAvailable !== undefined) {
        // Validation: ensure we don't set quantity lower than already sold
        if (body.quantityAvailable < (existingType.quantitySold ?? 0)) {
          throw new BadRequestError(
            `Cannot set capacity (${body.quantityAvailable}) lower than tickets already sold (${existingType.quantitySold ?? 0})`
          );
        }
        updateData.quantityAvailable = body.quantityAvailable;
      }

      const [updatedType] = await db
        .update(ticketTypes)
        .set(updateData)
        .where(eq(ticketTypes.id, ticketTypeId))
        .returning();

      return res.status(200).json({
        success: true,
        data: updatedType,
      });
    } catch (error) {
      next(error);
    }
  }

  // Release pending tickets older than 15 minutes and return their slots to the tier inventory
  static async releaseExpiredTickets() {
    try {
      const fifteenMinutesAgo = new Date(Date.now() - 15 * 60 * 1000);
      const expiredTickets = await db
        .select()
        .from(tickets)
        .where(
          and(
            eq(tickets.status, "PENDING"),
            sql`${tickets.createdAt} < ${fifteenMinutesAgo}`
          )
        );

      for (const tkt of expiredTickets) {
        await db.transaction(async (tx) => {
          const [latest] = await tx
            .select()
            .from(tickets)
            .where(eq(tickets.id, tkt.id))
            .limit(1);

          if (latest && latest.status === "PENDING") {
            await tx
              .update(tickets)
              .set({ status: "REFUNDED", updatedAt: new Date() })
              .where(eq(tickets.id, tkt.id));

            await tx
              .update(ticketTypes)
              .set({
                quantitySold: sql`${ticketTypes.quantitySold} - 1`,
                updatedAt: new Date(),
              })
              .where(eq(ticketTypes.id, tkt.ticketTypeId as string));
          }
        });
      }
    } catch (err) {
      console.error("Failed to release expired tickets:", err);
    }
  }

  // List available tiers for an event (Public)
  static async listTicketTypes(req: Request, res: Response, next: NextFunction) {
    try {
      const eventId = req.params.id;

      // Housekeeping: release any expired pending tickets first
      await TicketController.releaseExpiredTickets();

      // Verify event exists
      const [event] = await db
        .select()
        .from(events)
        .where(eq(events.id, eventId))
        .limit(1);

      if (!event) {
        throw new NotFoundError("Event not found");
      }

      const tiers = await db
        .select()
        .from(ticketTypes)
        .where(eq(ticketTypes.eventId, eventId));

      const processedTiers = tiers.map((tier) => ({
        ...tier,
        remainingQuantity: Math.max(0, tier.quantityAvailable - (tier.quantitySold ?? 0)),
      }));

      return res.status(200).json({
        success: true,
        data: processedTiers,
      });
    } catch (error) {
      next(error);
    }
  }

  // Purchase: POST /ticket-types/:id/purchase
  static async purchaseTicket(req: Request, res: Response, next: NextFunction) {
    try {
      const ticketTypeId = req.params.id;
      const purchaserUserId = req.user?.id;

      if (!purchaserUserId) {
        throw new BadRequestError("User authentication is required");
      }

      // Housekeeping: release any expired pending tickets first
      await TicketController.releaseExpiredTickets();

      // Atomic claim within transaction
      const result = await db.transaction(async (tx) => {
        // Attempt to atomically claim a slot by incrementing quantitySold only if less than quantityAvailable
        const [updatedTier] = await tx
          .update(ticketTypes)
          .set({
            quantitySold: sql`${ticketTypes.quantitySold} + 1`,
            updatedAt: new Date(),
          })
          .where(
            and(
              eq(ticketTypes.id, ticketTypeId),
              sql`${ticketTypes.quantitySold} < ${ticketTypes.quantityAvailable}`
            )
          )
          .returning();

        if (!updatedTier) {
          // Check if tier exists to raise correct error
          const [tier] = await tx
            .select()
            .from(ticketTypes)
            .where(eq(ticketTypes.id, ticketTypeId))
            .limit(1);

          if (!tier) {
            throw new NotFoundError("Ticket tier not found");
          }
          throw new BadRequestError("This ticket tier is sold out");
        }

        // Generate confirmation code
        const confirmationCode = "TKT-" + Math.random().toString(36).substring(2, 11).toUpperCase();

        // Insert PENDING ticket row
        const [newTicket] = await tx
          .insert(tickets)
          .values({
            ticketTypeId,
            purchaserUserId,
            status: "PENDING",
            confirmationCode,
          })
          .returning();

        return { tier: updatedTier, ticket: newTicket };
      });

      // Get the associated event to retrieve organizer information for payout routing
      const [associatedEvent] = await db
        .select()
        .from(events)
        .where(eq(events.id, result.tier.eventId))
        .limit(1);

      if (!associatedEvent) {
        throw new NotFoundError("Associated event not found");
      }

      let paymentIntent;
      try {
        // Create Stripe PaymentIntent with organizer metadata to route ticket payouts
        const stripe = getStripe();
        paymentIntent = await stripe.paymentIntents.create({
          amount: result.tier.priceCents,
          currency: "cad",
          metadata: {
            ticketId: result.ticket.id,
            ticketTypeId: result.tier.id,
            purchaserUserId,
            type: "ticket_purchase",
            eventId: associatedEvent.id,
            organizerId: associatedEvent.organizerId || "",
          },
        });
      } catch (stripeError) {
        // Stripe failed, ROLLBACK slot claim and remove pending ticket row
        await db.transaction(async (tx) => {
          await tx
            .delete(tickets)
            .where(eq(tickets.id, result.ticket.id));

          await tx
            .update(ticketTypes)
            .set({
              quantitySold: sql`${ticketTypes.quantitySold} - 1`,
              updatedAt: new Date(),
            })
            .where(eq(ticketTypes.id, ticketTypeId));
        });
        throw stripeError;
      }

      // Update ticket with stripePaymentIntentId
      const [finalTicket] = await db
        .update(tickets)
        .set({
          stripePaymentIntentId: paymentIntent.id,
          updatedAt: new Date(),
        })
        .where(eq(tickets.id, result.ticket.id))
        .returning();

      return res.status(201).json({
        success: true,
        data: {
          ticket: finalTicket,
          clientSecret: paymentIntent.client_secret,
        },
      });
    } catch (error) {
      next(error);
    }
  }

  // GET /tickets/mine: User's purchased tickets
  static async getMyTickets(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = req.user?.id;
      if (!userId) {
        throw new BadRequestError("User authentication is required");
      }

      const userTickets = await db
        .select()
        .from(tickets)
        .where(eq(tickets.purchaserUserId, userId));

      const ticketTypesList = await db.select().from(ticketTypes);
      const eventsList = await db.select().from(events);

      const ticketTypesMap = new Map(ticketTypesList.map(t => [t.id, t]));
      const eventsMap = new Map(eventsList.map(e => [e.id, e]));

      const enrichedTickets = userTickets.map(ticket => {
        const tier = ticketTypesMap.get(ticket.ticketTypeId as string);
        const event = tier ? eventsMap.get(tier.eventId as string) : null;
        return {
          ...ticket,
          ticketType: tier ? {
            id: tier.id,
            name: tier.name,
            priceCents: tier.priceCents,
            quantityAvailable: tier.quantityAvailable,
            quantitySold: tier.quantitySold,
          } : null,
          event: event ? {
            id: event.id,
            name: event.name,
            city: event.city,
            province: event.province,
            venue: event.venue,
            startDate: event.startDate,
            endDate: event.endDate,
          } : null,
        };
      });

      return res.status(200).json({
        success: true,
        data: enrichedTickets,
      });
    } catch (error) {
      next(error);
    }
  }

  // Refund a ticket (Organizer/Admin)
  static async refundTicket(req: Request, res: Response, next: NextFunction) {
    try {
      const ticketId = req.params.id;
      const actorId = req.user?.id;
      const actorRole = req.user?.role;

      if (!actorId) {
        throw new BadRequestError("User authentication is required");
      }

      // Fetch the ticket, its tier, and the associated event
      const [ticket] = await db
        .select()
        .from(tickets)
        .where(eq(tickets.id, ticketId))
        .limit(1);

      if (!ticket) {
        throw new NotFoundError("Ticket not found");
      }

      const [tier] = await db
        .select()
        .from(ticketTypes)
        .where(eq(ticketTypes.id, ticket.ticketTypeId as string))
        .limit(1);

      if (!tier) {
        throw new NotFoundError("Associated ticket tier not found");
      }

      const [event] = await db
        .select()
        .from(events)
        .where(eq(events.id, tier.eventId as string))
        .limit(1);

      if (!event) {
        throw new NotFoundError("Associated event not found");
      }

      // Check RBAC: only the event's organizer, system admins, or directors can refund tickets
      const isOrganizer = event.organizerId && actorId === event.organizerId;
      const isAdminOrDirector = [
        "SYSTEM_ADMIN",
        "NATIONAL_DIRECTOR",
        "PROVINCIAL_DIRECTOR"
      ].includes(actorRole || "");

      if (!isOrganizer && !isAdminOrDirector) {
        throw new ForbiddenError("Only the event's organizer, a director, or an admin can refund tickets.");
      }

      // Can only refund paid tickets
      if (ticket.status !== "PAID") {
        throw new BadRequestError(`Cannot refund a ticket in '${ticket.status}' status. Only PAID tickets can be refunded.`);
      }

      // Proceed with Stripe Refund if there is a payment intent ID
      if (ticket.stripePaymentIntentId) {
        try {
          const stripe = getStripe();
          await stripe.refunds.create({
            payment_intent: ticket.stripePaymentIntentId,
          });
        } catch (stripeError: any) {
          throw new BadRequestError(`Stripe refund failed: ${stripeError.message}`);
        }
      }

      // Update database status and restore slot atomically
      await db.transaction(async (tx) => {
        await tx
          .update(tickets)
          .set({
            status: "REFUNDED",
            updatedAt: new Date(),
          })
          .where(eq(tickets.id, ticketId));

        await tx
          .update(ticketTypes)
          .set({
            quantitySold: sql`${ticketTypes.quantitySold} - 1`,
            updatedAt: new Date(),
          })
          .where(eq(ticketTypes.id, ticket.ticketTypeId as string));
      });

      return res.status(200).json({
        success: true,
        message: "Ticket has been successfully refunded and slot restored to inventory.",
        data: {
          ticketId,
          status: "REFUNDED",
        },
      });
    } catch (error) {
      next(error);
    }
  }
}
