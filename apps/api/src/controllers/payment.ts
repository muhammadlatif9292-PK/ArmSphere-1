import { Request, Response, NextFunction } from "express";
import { getStripe } from "../services/stripe.js";
import { env } from "../config/env.js";
import { db } from "../config/db.js";
import { payments, eventRegistrations, athleteProfiles, processedStripeEvents, ticketTypes, tickets } from "@armsphere/db-schema";
import { eq, and, sql } from "drizzle-orm";
import { logger, NotFoundError, ForbiddenError } from "@armsphere/core";
import Stripe from "stripe";

export class PaymentController {
  static async handleWebhook(req: Request, res: Response, next: NextFunction): Promise<void> {
    const stripe = getStripe();
    const sig = req.headers["stripe-signature"];
    const webhookSecret = env.STRIPE_WEBHOOK_SECRET;

    if (!sig) {
      res.status(400).json({ error: "Missing stripe-signature header" });
      return;
    }

    // Defense in depth: an unset/empty secret turns signature verification into
    // an HMAC keyed with "" — forgeable by anyone. Refuse to process events.
    if (!webhookSecret) {
      logger.error("STRIPE_WEBHOOK_SECRET is not configured; rejecting all webhook deliveries.");
      res.status(503).json({ error: "Webhook processing unavailable" });
      return;
    }

    let event: Stripe.Event;

    try {
      // req.rawBody is a Buffer set by our custom express.json verify middleware
      const rawBody = (req as any).rawBody || Buffer.from("");
      event = stripe.webhooks.constructEvent(rawBody, sig, webhookSecret);
    } catch (err: any) {
      logger.error({ err: err.message }, "Webhook signature verification failed");
      res.status(400).send(`Webhook Error: ${err.message}`);
      return;
    }

    try {
      // Idempotency check: Ensure the event has not been processed yet
      const [existingEvent] = await db
        .select()
        .from(processedStripeEvents)
        .where(eq(processedStripeEvents.id, event.id))
        .limit(1);

      if (existingEvent) {
        logger.info({ eventId: event.id }, "Stripe event already processed. Skipping webhook handling.");
        res.status(200).json({ received: true, duplicate: true });
        return;
      }

      const paymentIntent = event.data.object as Stripe.PaymentIntent;
      const paymentIntentId = paymentIntent.id;

      logger.info({ eventType: event.type, paymentIntentId }, "Received Stripe webhook event");

      if (event.type === "payment_intent.succeeded") {
        const [payment] = await db
          .select()
          .from(payments)
          .where(eq(payments.stripePaymentIntentId, paymentIntentId))
          .limit(1);

        if (payment) {
          await db
            .update(payments)
            .set({ status: "SUCCEEDED", updatedAt: new Date() })
            .where(eq(payments.id, payment.id));

          await db
            .update(eventRegistrations)
            .set({ status: "PENDING", updatedAt: new Date() })
            .where(eq(eventRegistrations.id, payment.eventRegistrationId as string));

          logger.info(
            { paymentIntentId, registrationId: payment.eventRegistrationId },
            "Payment SUCCEEDED. Event registration status transitioned from PENDING_PAYMENT to PENDING"
          );
        } else {
          // Check for tickets
          const [ticket] = await db
            .select()
            .from(tickets)
            .where(eq(tickets.stripePaymentIntentId, paymentIntentId))
            .limit(1);

          if (ticket) {
            await db
              .update(tickets)
              .set({ status: "PAID", updatedAt: new Date() })
              .where(eq(tickets.id, ticket.id));

            logger.info(
              { paymentIntentId, ticketId: ticket.id, ticketTypeId: ticket.ticketTypeId },
              "Ticket payment SUCCEEDED. Ticket status set to PAID."
            );
          } else {
            logger.warn({ paymentIntentId }, "Payment succeeded but no matching payment or ticket record found");
          }
        }
      } else if (event.type === "payment_intent.payment_failed") {
        const [payment] = await db
          .select()
          .from(payments)
          .where(eq(payments.stripePaymentIntentId, paymentIntentId))
          .limit(1);

        if (payment) {
          await db
            .update(payments)
            .set({ status: "FAILED", updatedAt: new Date() })
            .where(eq(payments.id, payment.id));

          // Delete registration to let the athlete retry from scratch
          await db
            .delete(eventRegistrations)
            .where(eq(eventRegistrations.id, payment.eventRegistrationId as string));

          logger.info(
            { paymentIntentId, registrationId: payment.eventRegistrationId },
            "Payment FAILED. Event registration deleted to enable retry"
          );
        } else {
          // Check for tickets
          const [ticket] = await db
            .select()
            .from(tickets)
            .where(eq(tickets.stripePaymentIntentId, paymentIntentId))
            .limit(1);

          if (ticket) {
            await db.transaction(async (tx) => {
              await tx
                .update(tickets)
                .set({ status: "REFUNDED", updatedAt: new Date() })
                .where(eq(tickets.id, ticket.id));

              await tx
                .update(ticketTypes)
                .set({
                  quantitySold: sql`${ticketTypes.quantitySold} - 1`,
                  updatedAt: new Date()
                })
                .where(eq(ticketTypes.id, ticket.ticketTypeId as string));
            });

            logger.info(
              { paymentIntentId, ticketId: ticket.id, ticketTypeId: ticket.ticketTypeId },
              "Ticket payment FAILED. Ticket status set to REFUNDED, and slot returned to inventory."
            );
          } else {
            logger.warn({ paymentIntentId }, "Payment failed but no matching payment or ticket record found");
          }
        }
      }

      // Mark the event processed only AFTER the side effects above succeeded,
      // so a mid-handling failure lets Stripe's redelivery retry the work
      // instead of being swallowed as an already-seen duplicate.
      await db.insert(processedStripeEvents).values({ id: event.id });

      res.status(200).json({ received: true });
    } catch (error) {
      next(error);
    }
  }

  static async getPaymentMethods(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const stripe = getStripe();
      const userId = req.user!.id;
      const email = req.user!.email;

      const [profile] = await db
        .select()
        .from(athleteProfiles)
        .where(and(eq(athleteProfiles.userId, userId), eq(athleteProfiles.isDeleted, false)))
        .limit(1);

      if (!profile) {
        throw new NotFoundError("Athlete profile not found");
      }

      let stripeCustomerId = profile.stripeCustomerId;

      if (!stripeCustomerId) {
        // Create Stripe Customer
        const customer = await stripe.customers.create({
          email: email,
          name: profile.displayName || "Athlete",
        });
        stripeCustomerId = customer.id;

        // Save stripeCustomerId to database
        await db
          .update(athleteProfiles)
          .set({ stripeCustomerId, updatedAt: new Date() })
          .where(eq(athleteProfiles.id, profile.id));
      }

      const paymentMethods = await stripe.paymentMethods.list({
        customer: stripeCustomerId,
        type: "card",
      });

      const formattedMethods = paymentMethods.data.map((pm) => ({
        id: pm.id,
        brand: pm.card?.brand || "unknown",
        last4: pm.card?.last4 || "0000",
        expMonth: pm.card?.exp_month || 0,
        expYear: pm.card?.exp_year || 0,
      }));

      res.status(200).json({ success: true, data: formattedMethods });
    } catch (error) {
      next(error);
    }
  }

  static async deletePaymentMethod(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const stripe = getStripe();
      const userId = req.user!.id;
      const paymentMethodId = req.params.id;

      const [profile] = await db
        .select()
        .from(athleteProfiles)
        .where(and(eq(athleteProfiles.userId, userId), eq(athleteProfiles.isDeleted, false)))
        .limit(1);

      if (!profile) {
        throw new NotFoundError("Athlete profile not found");
      }

      const stripeCustomerId = profile.stripeCustomerId;
      if (!stripeCustomerId) {
        throw new NotFoundError("Stripe customer record not found for this user");
      }

      // Check if the payment method is actually owned by the customer (for security)
      const paymentMethods = await stripe.paymentMethods.list({
        customer: stripeCustomerId,
        type: "card",
      });

      const isOwned = paymentMethods.data.some((pm) => pm.id === paymentMethodId);
      if (!isOwned) {
        throw new ForbiddenError("You do not have permission to detach this payment method");
      }

      await stripe.paymentMethods.detach(paymentMethodId);

      res.status(200).json({ success: true });
    } catch (error) {
      next(error);
    }
  }

  static async createSetupIntent(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const stripe = getStripe();
      const userId = req.user!.id;
      const email = req.user!.email;

      const [profile] = await db
        .select()
        .from(athleteProfiles)
        .where(and(eq(athleteProfiles.userId, userId), eq(athleteProfiles.isDeleted, false)))
        .limit(1);

      if (!profile) {
        throw new NotFoundError("Athlete profile not found");
      }

      let stripeCustomerId = profile.stripeCustomerId;

      if (!stripeCustomerId) {
        // Create Stripe Customer
        const customer = await stripe.customers.create({
          email: email,
          name: profile.displayName || "Athlete",
        });
        stripeCustomerId = customer.id;

        // Save stripeCustomerId to database
        await db
          .update(athleteProfiles)
          .set({ stripeCustomerId, updatedAt: new Date() })
          .where(eq(athleteProfiles.id, profile.id));
      }

      const setupIntent = await stripe.setupIntents.create({
        customer: stripeCustomerId,
        payment_method_types: ["card"],
      });

      res.status(201).json({
        success: true,
        clientSecret: setupIntent.client_secret,
        customerId: stripeCustomerId,
      });
    } catch (error) {
      next(error);
    }
  }
}
