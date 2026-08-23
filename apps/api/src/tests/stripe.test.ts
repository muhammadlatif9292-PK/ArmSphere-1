import { describe, it, expect, beforeEach, vi } from "vitest";
import request from "supertest";
import { testDbStore } from "./setup.js";
import { app } from "../app.js";
import { generateAccessToken } from "@armsphere/cryptography";
import { UserRole } from "@armsphere/types";
import env from "../config/env.js";

function authHeader(role: UserRole = UserRole.ATHLETE, userId = "user-athlete") {
  const token = generateAccessToken(userId, "athlete@armsphere.com", role, env.JWT_ACCESS_SECRET);
  return `Bearer ${token}`;
}

const UUID_FREE_EVENT = "e1111111-1111-1111-1111-111111111111";
const UUID_PAID_EVENT = "e1111111-1111-1111-1111-222222222222";
const UUID_ATHLETE = "00000000-0000-0000-0000-000000000001";

describe("Stripe Payment & Event Registration Test Suite", () => {
  beforeEach(() => {
    // Reset registrations and payments for clean test isolation
    testDbStore.eventRegistrations = [];
    testDbStore.payments = [];
    testDbStore.processedStripeEvents = [];

    // Seed mock user records
    testDbStore.users = [
      { id: "user-athlete", role: UserRole.ATHLETE }
    ];

    // Seed mock athlete profile
    testDbStore.athleteProfiles = [
      {
        id: UUID_ATHLETE,
        userId: "user-athlete",
        fullName: "Test Athlete",
        gender: "MALE",
        leftArmElo: 1000,
        rightArmElo: 1000,
        province: "Ontario",
        isActive: true
      }
    ];

    // Seed events (one free, one paid)
    const now = new Date();
    const start = new Date(now.getTime() + 24 * 60 * 60 * 1000); // tomorrow
    const end = new Date(now.getTime() + 48 * 60 * 60 * 1000); // next tomorrow

    testDbStore.events = [
      {
        id: UUID_FREE_EVENT,
        name: "Free Tournament",
        startDate: start,
        endDate: end,
        registrationStart: new Date(now.getTime() - 24 * 60 * 60 * 1000), // yesterday
        registrationEnd: start,
        province: "Ontario",
        city: "Toronto",
        venue: "Ryerson",
        capacity: 100,
        registrationFeeCents: null,
        status: "PUBLISHED"
      },
      {
        id: UUID_PAID_EVENT,
        name: "Paid Championship",
        startDate: start,
        endDate: end,
        registrationStart: new Date(now.getTime() - 24 * 60 * 60 * 1000), // yesterday
        registrationEnd: start,
        province: "Ontario",
        city: "Toronto",
        venue: "Ryerson",
        capacity: 100,
        registrationFeeCents: 5000, // $50
        status: "PUBLISHED"
      }
    ];
  });

  it("should register for a free event and transition straight to PENDING without payment", async () => {
    const res = await request(app)
      .post("/tournaments/registrations")
      .set("Authorization", authHeader())
      .send({
        eventId: UUID_FREE_EVENT,
        athleteId: UUID_ATHLETE,
        division: "MENS_OPEN",
        weightClass: "80kg",
        arm: "LEFT",
        notes: "Excited!"
      });

    expect(res.status).toBe(201);
    expect(res.body).toHaveProperty("id");
    expect(res.body.status).toBe("PENDING");
    expect(res.body.clientSecret).toBeUndefined();

    // Verify no payment logs were created
    expect(testDbStore.payments.length).toBe(0);
  });

  it("should register for a paid event, set status to PENDING_PAYMENT, and return clientSecret", async () => {
    const res = await request(app)
      .post("/tournaments/registrations")
      .set("Authorization", authHeader())
      .send({
        eventId: UUID_PAID_EVENT,
        athleteId: UUID_ATHLETE,
        division: "MENS_OPEN",
        weightClass: "80kg",
        arm: "LEFT"
      });

    expect(res.status).toBe(201);
    expect(res.body.status).toBe("PENDING_PAYMENT");
    expect(res.body.clientSecret).toBeDefined();
    expect(res.body.clientSecret).toContain("pi_mock_secret_");

    // Verify payment record is created in PENDING status
    expect(testDbStore.payments.length).toBe(1);
    const payment = testDbStore.payments[0];
    expect(payment.eventRegistrationId).toBe(res.body.id);
    expect(payment.amountCents).toBe(5000);
    expect(payment.currency).toBe("CAD");
    expect(payment.status).toBe("PENDING");
    expect(payment.stripePaymentIntentId).toBeDefined();
  });

  it("should process webhook succeeded event, transition payment to SUCCEEDED and registration to PENDING", async () => {
    // 1. Create a paid registration first
    const regRes = await request(app)
      .post("/tournaments/registrations")
      .set("Authorization", authHeader())
      .send({
        eventId: UUID_PAID_EVENT,
        athleteId: UUID_ATHLETE,
        division: "MENS_OPEN",
        weightClass: "80kg",
        arm: "RIGHT"
      });

    const regId = regRes.body.id;
    const paymentRecord = testDbStore.payments.find(p => p.eventRegistrationId === regId);
    expect(paymentRecord).toBeDefined();

    // 2. Trigger simulated webhook success event
    const webhookPayload = {
      id: paymentRecord.stripePaymentIntentId,
      type: "payment_intent.succeeded",
      amount: 5000,
      currency: "cad",
      metadata: {
        registrationId: regId
      }
    };

    const res = await request(app)
      .post("/payments/webhook")
      .set("stripe-signature", "mock-signature-here")
      .send(webhookPayload);

    expect(res.status).toBe(200);
    expect(res.body.received).toBe(true);

    // 3. Verify database states updated correctly
    const updatedPayment = testDbStore.payments.find(p => p.eventRegistrationId === regId);
    expect(updatedPayment.status).toBe("SUCCEEDED");

    const updatedReg = testDbStore.eventRegistrations.find(r => r.id === regId);
    expect(updatedReg.status).toBe("PENDING");
  });

  it("should process webhook failed event, mark payment FAILED, and delete registration for retry", async () => {
    // 1. Create a paid registration first
    const regRes = await request(app)
      .post("/tournaments/registrations")
      .set("Authorization", authHeader())
      .send({
        eventId: UUID_PAID_EVENT,
        athleteId: UUID_ATHLETE,
        division: "MENS_OPEN",
        weightClass: "80kg",
        arm: "BOTH"
      });

    const regId = regRes.body.id;
    const paymentRecord = testDbStore.payments.find(p => p.eventRegistrationId === regId);
    expect(paymentRecord).toBeDefined();

    // 2. Trigger simulated webhook failure event
    const webhookPayload = {
      id: paymentRecord.stripePaymentIntentId,
      type: "payment_intent.payment_failed",
      amount: 5000,
      currency: "cad",
      metadata: {
        registrationId: regId
      }
    };

    const res = await request(app)
      .post("/payments/webhook")
      .set("stripe-signature", "mock-signature-here")
      .send(webhookPayload);

    expect(res.status).toBe(200);
    expect(res.body.received).toBe(true);

    // 3. Verify database states updated correctly
    const updatedPayment = testDbStore.payments.find(p => p.stripePaymentIntentId === paymentRecord.stripePaymentIntentId);
    expect(updatedPayment.status).toBe("FAILED");

    // Registration record must be deleted to allow retry
    const updatedReg = testDbStore.eventRegistrations.find(r => r.id === regId);
    expect(updatedReg).toBeUndefined();
  });

  it("should waitlist an athlete for a paid event at capacity and create no PaymentIntent", async () => {
    // Set paid event capacity to 0 to simulate at capacity
    const paidEvent = testDbStore.events.find(e => e.id === UUID_PAID_EVENT);
    if (paidEvent) {
      paidEvent.capacity = 0;
    }

    const res = await request(app)
      .post("/tournaments/registrations")
      .set("Authorization", authHeader())
      .send({
        eventId: UUID_PAID_EVENT,
        athleteId: UUID_ATHLETE,
        division: "MENS_OPEN",
        weightClass: "80kg",
        arm: "LEFT"
      });

    expect(res.status).toBe(201);
    expect(res.body.status).toBe("WAITLISTED");
    expect(res.body.clientSecret).toBeUndefined();

    // Verify no payment record was created
    expect(testDbStore.payments.length).toBe(0);
  });

  it("should fail validation and return 400 when webhook is called with an invalid signature, leaving db untouched", async () => {
    // 1. Create a paid registration first
    const regRes = await request(app)
      .post("/tournaments/registrations")
      .set("Authorization", authHeader())
      .send({
        eventId: UUID_PAID_EVENT,
        athleteId: UUID_ATHLETE,
        division: "MENS_OPEN",
        weightClass: "80kg",
        arm: "RIGHT"
      });

    const regId = regRes.body.id;
    const paymentRecord = testDbStore.payments.find(p => p.eventRegistrationId === regId);
    expect(paymentRecord).toBeDefined();

    const originalPaymentStatus = paymentRecord.status; // should be PENDING
    const originalRegStatus = testDbStore.eventRegistrations.find(r => r.id === regId)?.status; // should be PENDING_PAYMENT

    // 2. Trigger simulated webhook success event, but with a WRONG signature
    const webhookPayload = {
      id: paymentRecord.stripePaymentIntentId,
      type: "payment_intent.succeeded",
      amount: 5000,
      currency: "cad",
      metadata: {
        registrationId: regId
      }
    };

    const res = await request(app)
      .post("/payments/webhook")
      .set("stripe-signature", "invalid-signature-here")
      .send(webhookPayload);

    expect(res.status).toBe(400);

    // 3. Verify database states remain unchanged
    const afterPayment = testDbStore.payments.find(p => p.eventRegistrationId === regId);
    expect(afterPayment.status).toBe(originalPaymentStatus);

    const afterReg = testDbStore.eventRegistrations.find(r => r.id === regId);
    expect(afterReg.status).toBe(originalRegStatus);
  });

  it("should prevent duplicate registrations/double-charges on two rapid registration attempts for the same athlete and event", async () => {
    // 1. Send the first registration attempt
    const res1Promise = request(app)
      .post("/tournaments/registrations")
      .set("Authorization", authHeader())
      .send({
        eventId: UUID_PAID_EVENT,
        athleteId: UUID_ATHLETE,
        division: "MENS_OPEN",
        weightClass: "80kg",
        arm: "LEFT"
      });

    // 2. Send the second registration attempt concurrently
    const res2Promise = request(app)
      .post("/tournaments/registrations")
      .set("Authorization", authHeader())
      .send({
        eventId: UUID_PAID_EVENT,
        athleteId: UUID_ATHLETE,
        division: "MENS_OPEN",
        weightClass: "80kg",
        arm: "LEFT"
      });

    const [res1, res2] = await Promise.all([res1Promise, res2Promise]);

    // One of them must succeed, and the other must fail with a 400 bad request error.
    const succeeded = res1.status === 201 ? res1 : res2;
    const failed = res1.status === 201 ? res2 : res1;

    expect(succeeded.status).toBe(201);
    expect(succeeded.body.status).toBe("PENDING_PAYMENT");
    expect(succeeded.body.clientSecret).toBeDefined();

    expect(failed.status).toBe(400);
    expect(failed.body.detail).toContain("already registered in this event");

    // Exactly one registration should be in the store
    const registrations = testDbStore.eventRegistrations.filter(
      r => r.eventId === UUID_PAID_EVENT && r.athleteId === UUID_ATHLETE
    );
    expect(registrations.length).toBe(1);

    // Exactly one PaymentIntent (payment record) should be created
    expect(testDbStore.payments.length).toBe(1);
  });

  it("should ensure the webhook handler is idempotent by event.id and skips duplicate updates/logs", async () => {
    // 1. Create a paid registration first
    const regRes = await request(app)
      .post("/tournaments/registrations")
      .set("Authorization", authHeader())
      .send({
        eventId: UUID_PAID_EVENT,
        athleteId: UUID_ATHLETE,
        division: "MENS_OPEN",
        weightClass: "80kg",
        arm: "RIGHT"
      });

    const regId = regRes.body.id;
    const paymentRecord = testDbStore.payments.find(p => p.eventRegistrationId === regId);
    expect(paymentRecord).toBeDefined();

    // 2. Trigger simulated webhook success event the FIRST time
    const webhookPayload = {
      id: paymentRecord.stripePaymentIntentId,
      eventId: "evt_test_123456",
      type: "payment_intent.succeeded",
      amount: 5000,
      currency: "cad",
      metadata: {
        registrationId: regId
      }
    };

    const res1 = await request(app)
      .post("/payments/webhook")
      .set("stripe-signature", "mock-signature-here")
      .send(webhookPayload);

    expect(res1.status).toBe(200);
    expect(res1.body.received).toBe(true);
    expect(res1.body.duplicate).toBeUndefined();

    // Verify database states updated correctly
    const updatedPayment = testDbStore.payments.find(p => p.eventRegistrationId === regId);
    expect(updatedPayment.status).toBe("SUCCEEDED");

    const updatedReg = testDbStore.eventRegistrations.find(r => r.id === regId);
    expect(updatedReg.status).toBe("PENDING");

    // Manually mutate payment status in DB to detect if second webhook modifies it
    updatedPayment.status = "MUTATED_TEST_STATUS";

    // 3. Trigger simulated webhook success event the SECOND time with EXACTLY the same event ID
    const res2 = await request(app)
      .post("/payments/webhook")
      .set("stripe-signature", "mock-signature-here")
      .send(webhookPayload);

    expect(res2.status).toBe(200);
    expect(res2.body.received).toBe(true);
    expect(res2.body.duplicate).toBe(true);

    // Verify payment status in DB was NOT re-updated to "SUCCEEDED" by the second duplicate webhook
    const afterSecondWebhook = testDbStore.payments.find(p => p.eventRegistrationId === regId);
    expect(afterSecondWebhook.status).toBe("MUTATED_TEST_STATUS");
  });

  describe("Stripe Saved Payment Methods Endpoints", () => {
    it("should list payment methods, creating a Stripe customer if not exists", async () => {
      // 1. Initially athleteProfile has no stripeCustomerId
      const athlete = testDbStore.athleteProfiles.find(ap => ap.userId === "user-athlete");
      expect(athlete.stripeCustomerId).toBeUndefined();

      // 2. Call GET /payments/methods
      const res = await request(app)
        .get("/payments/methods")
        .set("Authorization", authHeader());

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(Array.isArray(res.body.data)).toBe(true);

      // Re-fetch the athlete from testDbStore because the update changed the reference!
      const updatedAthlete = testDbStore.athleteProfiles.find(ap => ap.userId === "user-athlete");
      expect(updatedAthlete.stripeCustomerId).toBeDefined();
      expect(updatedAthlete.stripeCustomerId).toContain("cus_mock_");

      // Now set it to "cus_mock_123" to test retrieving those seeded methods!
      updatedAthlete.stripeCustomerId = "cus_mock_123";

      const res2 = await request(app)
        .get("/payments/methods")
        .set("Authorization", authHeader());

      expect(res2.status).toBe(200);
      expect(res2.body.success).toBe(true);
      expect(res2.body.data.length).toBe(2);
      expect(res2.body.data[0]).toHaveProperty("id");
      expect(res2.body.data[0].brand).toBe("visa");
      expect(res2.body.data[0].last4).toBe("4242");
    });

    it("should delete a payment method successfully", async () => {
      // Seed athlete profile with a stripeCustomerId
      const athlete = testDbStore.athleteProfiles.find(ap => ap.userId === "user-athlete");
      athlete.stripeCustomerId = "cus_mock_123";

      // Verify there are 2 payment methods initially
      const resListBefore = await request(app)
        .get("/payments/methods")
        .set("Authorization", authHeader());
      expect(resListBefore.body.data.length).toBe(2);

      // Call DELETE /payments/methods/pm_mock_visa
      const resDelete = await request(app)
        .delete("/payments/methods/pm_mock_visa")
        .set("Authorization", authHeader());

      expect(resDelete.status).toBe(200);
      expect(resDelete.body.success).toBe(true);

      // Verify payment method is detached (should only have 1 now)
      const resListAfter = await request(app)
        .get("/payments/methods")
        .set("Authorization", authHeader());
      expect(resListAfter.body.data.length).toBe(1);
      expect(resListAfter.body.data[0].id).toBe("pm_mock_mastercard");
    });

    it("should reject deleting a payment method not owned by the user", async () => {
      // Seed athlete profile with a stripeCustomerId
      const athlete = testDbStore.athleteProfiles.find(ap => ap.userId === "user-athlete");
      athlete.stripeCustomerId = "cus_mock_other";

      // Attempt to delete pm_mock_visa which is owned by cus_mock_123
      const resDelete = await request(app)
        .delete("/payments/methods/pm_mock_visa")
        .set("Authorization", authHeader());

      expect(resDelete.status).toBe(403);
    });

    it("should create a setup intent successfully", async () => {
      const res = await request(app)
        .post("/payments/setup-intent")
        .set("Authorization", authHeader());

      expect(res.status).toBe(201);
      expect(res.body.success).toBe(true);
      expect(res.body.clientSecret).toBeDefined();
      expect(res.body.clientSecret).toContain("seti_mock_secret_");
      expect(res.body.customerId).toBeDefined();
    });
  });
});
