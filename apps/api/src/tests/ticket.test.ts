import { describe, it, expect, beforeEach, vi } from "vitest";
import request from "supertest";
import { testDbStore } from "./setup.js";
import { app } from "../app.js";
import { generateAccessToken } from "@armsphere/cryptography";
import { UserRole } from "@armsphere/types";
import env from "../config/env.js";

function authHeader(role: UserRole = UserRole.ATHLETE, userId = "user-athlete") {
  const token = generateAccessToken(userId, "user@armsphere.com", role, env.JWT_ACCESS_SECRET);
  return `Bearer ${token}`;
}

const UUID_EVENT = "e1111111-1111-1111-1111-999999999999";
const TICKET_TYPE_ID = "t1111111-1111-1111-1111-111111111111";

describe("Spectator Ticketing Service Test Suite", () => {
  beforeEach(() => {
    // Reset ticket tables for clean isolation
    testDbStore.ticketTypes = [];
    testDbStore.tickets = [];
    testDbStore.processedStripeEvents = [];
    testDbStore.events = [];
    testDbStore.users = [];

    // Seed mock event
    testDbStore.events = [
      {
        id: UUID_EVENT,
        name: "Spectator Armwrestling Showdown",
        startDate: new Date(),
        endDate: new Date(),
        registrationStart: new Date(),
        registrationEnd: new Date(),
        province: "Ontario",
        city: "Toronto",
        venue: "Ryerson Arena",
        capacity: 100,
        registrationFeeCents: 5000,
        status: "PUBLISHED",
      },
    ];

    // Seed mock ticket tier
    testDbStore.ticketTypes = [
      {
        id: TICKET_TYPE_ID,
        eventId: UUID_EVENT,
        name: "General Admission",
        priceCents: 1500, // $15
        quantityAvailable: 50,
        quantitySold: 0,
        createdAt: new Date(),
        updatedAt: new Date(),
      },
    ];
  });

  describe("Ticket Type Management (RBAC & CRUD)", () => {
    it("should reject ticket type creation if user is not organizer or admin", async () => {
      const res = await request(app)
        .post(`/events/${UUID_EVENT}/ticket-types`)
        .set("Authorization", authHeader(UserRole.ATHLETE))
        .send({
          name: "VIP Ring side",
          priceCents: 5000,
          quantityAvailable: 10,
        });

      expect(res.status).toBe(403);
    });

    it("should allow ticket type creation if user is provincial director (organizer)", async () => {
      const res = await request(app)
        .post(`/events/${UUID_EVENT}/ticket-types`)
        .set("Authorization", authHeader(UserRole.PROVINCIAL_DIRECTOR))
        .send({
          name: "VIP Ringside",
          priceCents: 5000,
          quantityAvailable: 10,
        });

      expect(res.status).toBe(201);
      expect(res.body.success).toBe(true);
      expect(res.body.data.name).toBe("VIP Ringside");

      // Verify stored in DB
      const stored = testDbStore.ticketTypes.find(t => t.name === "VIP Ringside");
      expect(stored).toBeDefined();
      expect(stored.priceCents).toBe(5000);
    });

    it("should reject editing ticket type if user is not organizer or admin", async () => {
      const res = await request(app)
        .patch(`/ticket-types/${TICKET_TYPE_ID}`)
        .set("Authorization", authHeader(UserRole.ATHLETE))
        .send({
          priceCents: 2000,
        });

      expect(res.status).toBe(403);
    });

    it("should allow editing ticket type if user is system admin", async () => {
      const res = await request(app)
        .patch(`/ticket-types/${TICKET_TYPE_ID}`)
        .set("Authorization", authHeader(UserRole.SYSTEM_ADMIN))
        .send({
          priceCents: 2200,
          quantityAvailable: 100,
        });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.priceCents).toBe(2200);
      expect(res.body.data.quantityAvailable).toBe(100);

      const stored = testDbStore.ticketTypes.find(t => t.id === TICKET_TYPE_ID);
      expect(stored.priceCents).toBe(2200);
      expect(stored.quantityAvailable).toBe(100);
    });
  });

  describe("Public Ticketing Listing", () => {
    it("should list ticket types for an event without any auth headers", async () => {
      const res = await request(app)
        .get(`/events/${UUID_EVENT}/ticket-types`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.length).toBe(1);
      expect(res.body.data[0].name).toBe("General Admission");
      expect(res.body.data[0].remainingQuantity).toBe(50);
    });
  });

  describe("Ticket Purchase Flow", () => {
    it("should create a PENDING ticket and Stripe PaymentIntent on purchase", async () => {
      const res = await request(app)
        .post(`/ticket-types/${TICKET_TYPE_ID}/purchase`)
        .set("Authorization", authHeader(UserRole.ATHLETE, "purchaser-123"));

      expect(res.status).toBe(201);
      expect(res.body.success).toBe(true);
      expect(res.body.data.ticket).toBeDefined();
      expect(res.body.data.ticket.status).toBe("PENDING");
      expect(res.body.data.ticket.purchaserUserId).toBe("purchaser-123");
      expect(res.body.data.clientSecret).toBeDefined();

      // Verify ticket saved in test DB store
      const storedTicket = testDbStore.tickets.find(t => t.purchaserUserId === "purchaser-123");
      expect(storedTicket).toBeDefined();
      expect(storedTicket.status).toBe("PENDING");
      expect(storedTicket.stripePaymentIntentId).toBeDefined();
    });

    it("should reject purchase if the ticket tier is sold out", async () => {
      // Mark the tier as sold out
      const tier = testDbStore.ticketTypes.find(t => t.id === TICKET_TYPE_ID);
      tier.quantitySold = 50;

      const res = await request(app)
        .post(`/ticket-types/${TICKET_TYPE_ID}/purchase`)
        .set("Authorization", authHeader(UserRole.ATHLETE, "purchaser-456"));

      expect(res.status).toBe(400);
      expect(res.body.detail).toContain("sold out");

      // Verify no ticket was saved for this user
      const storedTicket = testDbStore.tickets.find(t => t.purchaserUserId === "purchaser-456");
      expect(storedTicket).toBeUndefined();
    });
  });

  describe("Stripe Webhook Processing", () => {
    it("should transition ticket status to PAID and increment quantitySold on payment success", async () => {
      // 1. Create a PENDING ticket
      const purchaseRes = await request(app)
        .post(`/ticket-types/${TICKET_TYPE_ID}/purchase`)
        .set("Authorization", authHeader(UserRole.ATHLETE, "purchaser-789"));

      const ticket = purchaseRes.body.data.ticket;
      const paymentIntentId = ticket.stripePaymentIntentId;
      expect(paymentIntentId).toBeDefined();

      // Ensure quantitySold is 1 (reserved at purchase-creation time)
      const tierBefore = testDbStore.ticketTypes.find(t => t.id === TICKET_TYPE_ID);
      expect(tierBefore.quantitySold).toBe(1);

      // 2. Simulate Stripe Webhook payload
      const webhookPayload = {
        id: paymentIntentId, // mock Stripe event ID same as PI ID for convenience
        type: "payment_intent.succeeded",
        data: {
          object: {
            id: paymentIntentId,
            amount: 1500,
            currency: "cad",
            metadata: {
              ticketId: ticket.id,
              ticketTypeId: TICKET_TYPE_ID,
              type: "ticket_purchase",
            },
          },
        },
      };

      const webhookRes = await request(app)
        .post("/payments/webhook")
        .set("stripe-signature", "mock-signature-here")
        .send(webhookPayload);

      expect(webhookRes.status).toBe(200);

      // Verify ticket status transitioned to PAID
      const storedTicket = testDbStore.tickets.find(t => t.id === ticket.id);
      expect(storedTicket.status).toBe("PAID");

      // Verify quantitySold was incremented
      const tierAfter = testDbStore.ticketTypes.find(t => t.id === TICKET_TYPE_ID);
      expect(tierAfter.quantitySold).toBe(1);
    });
  });

  describe("Concurrency and Failure Recovery", () => {
    it("should handle simultaneous purchase attempts atomically and allow exactly one to succeed", async () => {
      // Set capacity of TICKET_TYPE_ID to 1 remaining slot
      const tier = testDbStore.ticketTypes.find(t => t.id === TICKET_TYPE_ID);
      tier.quantityAvailable = 1;
      tier.quantitySold = 0;

      // Spin up 5 concurrent purchase requests
      const promises = Array.from({ length: 5 }).map((_, idx) => {
        return request(app)
          .post(`/ticket-types/${TICKET_TYPE_ID}/purchase`)
          .set("Authorization", authHeader(UserRole.ATHLETE, `concur-buyer-${idx}`))
          .send();
      });

      const responses = await Promise.all(promises);

      const succeeded = responses.filter(r => r.status === 201);
      const failed = responses.filter(r => r.status === 400);

      expect(succeeded.length).toBe(1);
      expect(failed.length).toBe(4);

      // Verify DB reflects exactly 1 slot sold and exactly 1 ticket created
      const tierAfter = testDbStore.ticketTypes.find(t => t.id === TICKET_TYPE_ID);
      expect(tierAfter.quantitySold).toBe(1);

      const savedTickets = testDbStore.tickets.filter(t => t.ticketTypeId === TICKET_TYPE_ID);
      expect(savedTickets.length).toBe(1);
      expect(savedTickets[0].status).toBe("PENDING");
    });

    it("should release slot and delete ticket row if Stripe call fails", async () => {
      const tier = testDbStore.ticketTypes.find(t => t.id === TICKET_TYPE_ID);
      tier.quantityAvailable = 10;
      tier.quantitySold = 0;

      // Mock stripe error
      const { getStripe } = await import("../services/stripe.js");
      const stripe = getStripe();
      const createSpy = vi.spyOn(stripe.paymentIntents, "create").mockRejectedValueOnce(
        new Error("Stripe mock error")
      );

      const res = await request(app)
        .post(`/ticket-types/${TICKET_TYPE_ID}/purchase`)
        .set("Authorization", authHeader(UserRole.ATHLETE, "stripe-fail-buyer"))
        .send();

      expect(res.status).toBe(500);

      // Verify database slot was released and no ticket row remains
      const tierAfter = testDbStore.ticketTypes.find(t => t.id === TICKET_TYPE_ID);
      expect(tierAfter.quantitySold).toBe(0);

      const savedTicket = testDbStore.tickets.find(t => t.purchaserUserId === "stripe-fail-buyer");
      expect(savedTicket).toBeUndefined();

      createSpy.mockRestore();
    });

    it("should release expired pending tickets and restore their slot to inventory", async () => {
      // Seed a ticket that was created 20 minutes ago in PENDING status
      const tier = testDbStore.ticketTypes.find(t => t.id === TICKET_TYPE_ID);
      tier.quantityAvailable = 10;
      tier.quantitySold = 1;

      const expiredTicketId = "expired-ticket-uuid";
      testDbStore.tickets.push({
        id: expiredTicketId,
        ticketTypeId: TICKET_TYPE_ID,
        purchaserUserId: "expired-buyer",
        status: "PENDING",
        confirmationCode: "TKT-EXPIRED",
        createdAt: new Date(Date.now() - 20 * 60 * 1000), // 20 mins ago
        updatedAt: new Date(Date.now() - 20 * 60 * 1000),
      } as any);

      // Call public listing, which triggers house-keeping `releaseExpiredTickets`
      const res = await request(app)
        .get(`/events/${UUID_EVENT}/ticket-types`);

      expect(res.status).toBe(200);

      // Verify ticket status transitioned to REFUNDED
      const storedTicket = testDbStore.tickets.find(t => t.id === expiredTicketId);
      expect(storedTicket.status).toBe("REFUNDED");

      // Verify slot was released
      const tierAfter = testDbStore.ticketTypes.find(t => t.id === TICKET_TYPE_ID);
      expect(tierAfter.quantitySold).toBe(0);
    });
  });

  describe("Ticket Refund & Payout Routing", () => {
    it("should include eventId and organizerId in the Stripe PaymentIntent metadata", async () => {
      // Set an organizer on the event
      const event = testDbStore.events.find(e => e.id === UUID_EVENT);
      event.organizerId = "organizer-user-123";

      const res = await request(app)
        .post(`/ticket-types/${TICKET_TYPE_ID}/purchase`)
        .set("Authorization", authHeader(UserRole.ATHLETE, "purchaser-111"));

      expect(res.status).toBe(201);
      expect(res.body.success).toBe(true);

      // Fetch the created ticket and verify the Stripe call included correct metadata
      const storedTicket = testDbStore.tickets.find(t => t.purchaserUserId === "purchaser-111");
      expect(storedTicket).toBeDefined();

      const { getStripe } = await import("../services/stripe.js");
      const stripe = getStripe();
      const createSpy = vi.spyOn(stripe.paymentIntents, "create");
      
      // Let's run a second purchase to observe the spy parameters
      await request(app)
        .post(`/ticket-types/${TICKET_TYPE_ID}/purchase`)
        .set("Authorization", authHeader(UserRole.ATHLETE, "purchaser-222"));

      expect(createSpy).toHaveBeenCalled();
      const mostRecentCallArgs = createSpy.mock.calls[createSpy.mock.calls.length - 1][0];
      expect(mostRecentCallArgs.metadata).toBeDefined();
      expect(mostRecentCallArgs.metadata!.eventId).toBe(UUID_EVENT);
      expect(mostRecentCallArgs.metadata!.organizerId).toBe("organizer-user-123");

      createSpy.mockRestore();
    });

    it("should allow the organizer or system admin to refund a PAID ticket and restore slots", async () => {
      const event = testDbStore.events.find(e => e.id === UUID_EVENT);
      event.organizerId = "organizer-user-123";

      const ticketId = "paid-ticket-uuid";
      testDbStore.tickets.push({
        id: ticketId,
        ticketTypeId: TICKET_TYPE_ID,
        purchaserUserId: "buyer-123",
        status: "PAID",
        stripePaymentIntentId: "pi_paid_mock",
        confirmationCode: "TKT-PAID-123",
        createdAt: new Date(),
        updatedAt: new Date(),
      } as any);

      const tier = testDbStore.ticketTypes.find(t => t.id === TICKET_TYPE_ID);
      tier.quantitySold = 1;

      // Try refunding as an unauthorized user (random athlete)
      const unauthRes = await request(app)
        .post(`/tickets/${ticketId}/refund`)
        .set("Authorization", authHeader(UserRole.ATHLETE, "random-user"));
      
      expect(unauthRes.status).toBe(403);

      // Refund as organizer
      const authRes = await request(app)
        .post(`/tickets/${ticketId}/refund`)
        .set("Authorization", authHeader(UserRole.PROVINCIAL_DIRECTOR, "organizer-user-123"));

      expect(authRes.status).toBe(200);
      expect(authRes.body.success).toBe(true);

      // Verify db state updated
      const storedTicket = testDbStore.tickets.find(t => t.id === ticketId);
      expect(storedTicket.status).toBe("REFUNDED");
      
      const updatedTier = testDbStore.ticketTypes.find(t => t.id === TICKET_TYPE_ID);
      expect(updatedTier.quantitySold).toBe(0);
    });

    it("should reject refund if the ticket status is not PAID", async () => {
      const ticketId = "pending-ticket-uuid";
      testDbStore.tickets.push({
        id: ticketId,
        ticketTypeId: TICKET_TYPE_ID,
        purchaserUserId: "buyer-123",
        status: "PENDING",
        stripePaymentIntentId: "pi_pending_mock",
        confirmationCode: "TKT-PEND-123",
        createdAt: new Date(),
        updatedAt: new Date(),
      } as any);

      const res = await request(app)
        .post(`/tickets/${ticketId}/refund`)
        .set("Authorization", authHeader(UserRole.SYSTEM_ADMIN));

      expect(res.status).toBe(400);
      expect(res.body.detail).toContain("Only PAID tickets can be refunded");
    });
  });
});
