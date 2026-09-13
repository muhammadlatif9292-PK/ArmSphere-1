import { describe, it, expect, beforeEach } from "vitest";
import request from "supertest";
import { testDbStore } from "./setup.js";
import { app } from "../app.js";
import { generateAccessToken } from "@armsphere/cryptography";
import { UserRole } from "@armsphere/types";
import env from "../config/env.js";

function authHeader(role: UserRole = UserRole.ATHLETE, userId?: string) {
  let defaultUserId = "00000000-0000-0000-0000-000000000099";
  if (role === UserRole.REFEREE) defaultUserId = UUID_REFEREE;
  else if (role === UserRole.PROVINCIAL_DIRECTOR) defaultUserId = UUID_DIRECTOR;
  const token = generateAccessToken(userId || defaultUserId, "test@armsphere.com", role, env.JWT_ACCESS_SECRET);
  return `Bearer ${token}`;
}

const UUID_ATHLETE_A = "00000000-0000-0000-0000-000000000001";
const UUID_ATHLETE_B = "00000000-0000-0000-0000-000000000002";
const UUID_ATHLETE_C = "00000000-0000-0000-0000-000000000003";
const UUID_DIRECTOR = "00000000-0000-0000-0000-000000000004";
const UUID_REFEREE = "00000000-0000-0000-0000-000000000005";

const F1_FREE_EVENT = "11111111-1111-4111-8111-111111111111";
const F1_PAID_EVENT = "22222222-2222-4222-8222-222222222222";
const F1_FREE_REG = "33333333-3333-4333-8333-333333333333";
const F1_UNPAID_REG = "44444444-4444-4333-8333-444444444444";
const F1_FLOW_REG = "55555555-5555-4333-8333-555555555555";
const F1_ATHLETE_REG = "a6666666-6666-4333-8333-666666666666";
const F1_DUP_REG = "77777777-7777-4333-8333-777777777777";

describe("F1 Registration Approval Payment Gate", () => {
  beforeEach(() => {
    testDbStore.users = [
      { id: "user-a", role: UserRole.ATHLETE },
      { id: "user-b", role: UserRole.ATHLETE },
      { id: "user-c", role: UserRole.ATHLETE },
      { id: UUID_DIRECTOR, role: UserRole.PROVINCIAL_DIRECTOR },
      { id: UUID_REFEREE, role: UserRole.REFEREE },
      { id: "00000000-0000-0000-0000-000000000099", role: UserRole.ATHLETE },
    ];
    testDbStore.athleteProfiles = [
      { id: UUID_ATHLETE_A, userId: "user-a", displayName: "John Doe", gender: "MALE", leftArmElo: 1200, rightArmElo: 1250, province: "Ontario", clubName: "Ottawa Arms", isActive: true },
      { id: UUID_ATHLETE_B, userId: "user-b", displayName: "Jane Smith", gender: "FEMALE", leftArmElo: 1100, rightArmElo: 1150, province: "Quebec", clubName: "Montreal Pullers", isActive: true },
      { id: UUID_ATHLETE_C, userId: "user-c", displayName: "Bob Johnson", gender: "MALE", leftArmElo: 1000, rightArmElo: 1050, province: "Ontario", clubName: "Ottawa Arms", isActive: true },
    ];
    testDbStore.events = [];
    testDbStore.eventRegistrations = [];
    testDbStore.auditEvents = [];
    testDbStore.auditLogs = [];
    testDbStore.events.push(
      {
        id: F1_FREE_EVENT, name: "F1 Free Cup",
        registrationStart: new Date(Date.now() - 3600000), registrationEnd: new Date(Date.now() + 3600000),
        startDate: new Date(Date.now() + 86400000), endDate: new Date(Date.now() + 172800000),
        province: "Ontario", city: "Toronto", venue: "Stadium", capacity: 50,
        status: "PUBLISHED", registrationFeeCents: null, paymentMethod: "MANUAL_QR", organizerId: UUID_DIRECTOR,
      },
      {
        id: F1_PAID_EVENT, name: "F1 Paid Manual QR Cup",
        registrationStart: new Date(Date.now() - 3600000), registrationEnd: new Date(Date.now() + 3600000),
        startDate: new Date(Date.now() + 86400000), endDate: new Date(Date.now() + 172800000),
        province: "Ontario", city: "Ottawa", venue: "Community Hall", capacity: 50,
        status: "PUBLISHED", registrationFeeCents: 5000, paymentMethod: "MANUAL_QR", organizerId: UUID_DIRECTOR,
      }
    );
    testDbStore.eventRegistrations.push(
      { id: F1_FREE_REG, eventId: F1_FREE_EVENT, athleteId: UUID_ATHLETE_A, division: "SENIOR", weightClass: "70KG", arm: "RIGHT", status: "PENDING", paymentConfirmedByOrganizer: false, paymentConfirmedAt: null, approvedBy: null },
      { id: F1_UNPAID_REG, eventId: F1_PAID_EVENT, athleteId: UUID_ATHLETE_A, division: "SENIOR", weightClass: "70KG", arm: "RIGHT", status: "PENDING_PAYMENT", paymentConfirmedByOrganizer: false, paymentConfirmedAt: null, approvedBy: null },
      { id: F1_FLOW_REG, eventId: F1_PAID_EVENT, athleteId: UUID_ATHLETE_B, division: "SENIOR", weightClass: "70KG", arm: "RIGHT", status: "PENDING_PAYMENT", paymentConfirmedByOrganizer: false, paymentConfirmedAt: null, approvedBy: null },
      { id: F1_ATHLETE_REG, eventId: F1_PAID_EVENT, athleteId: UUID_ATHLETE_C, division: "SENIOR", weightClass: "70KG", arm: "RIGHT", status: "PENDING_PAYMENT", paymentConfirmedByOrganizer: false, paymentConfirmedAt: null, approvedBy: null },
      { id: F1_DUP_REG, eventId: F1_FREE_EVENT, athleteId: UUID_ATHLETE_B, division: "SENIOR", weightClass: "70KG", arm: "RIGHT", status: "PENDING", paymentConfirmedByOrganizer: false, paymentConfirmedAt: null, approvedBy: null }
    );
  });

  it("A. approves a FREE registration: PENDING -> APPROVED with audit", async () => {
    const res = await request(app)
      .post(`/tournaments/registrations/${F1_FREE_REG}/approve`)
      .set("Authorization", authHeader(UserRole.PROVINCIAL_DIRECTOR, UUID_DIRECTOR));
    expect(res.status).toBe(200);
    expect(res.body.status).toBe("APPROVED");
    expect(res.body.approvedBy).toBe(UUID_DIRECTOR);
    const stored = testDbStore.eventRegistrations.find((r) => r.id === F1_FREE_REG);
    expect(stored?.status).toBe("APPROVED");
    expect(stored?.approvedBy).toBe(UUID_DIRECTOR);
    const approvals = testDbStore.auditEvents.filter((e) => e.action === "REGISTRATION_APPROVAL" && e.entityId === F1_FREE_REG);
    expect(approvals.length).toBe(1);
    expect(approvals[0].actorId).toBe(UUID_DIRECTOR);
    expect(approvals[0].entityType).toBe("event_registrations");
  });

  it("B. rejects unpaid MANUAL_QR approval with 400 and NO mutation or audit", async () => {
    const res = await request(app)
      .post(`/tournaments/registrations/${F1_UNPAID_REG}/approve`)
      .set("Authorization", authHeader(UserRole.PROVINCIAL_DIRECTOR, UUID_DIRECTOR));
    expect(res.status).toBe(400);
    expect(res.body.detail).toContain("Payment must be confirmed");
    const stored = testDbStore.eventRegistrations.find((r) => r.id === F1_UNPAID_REG);
    expect(stored?.status).toBe("PENDING_PAYMENT");
    expect(stored?.approvedBy).toBeNull();
    expect(testDbStore.auditEvents.filter((e) => e.entityId === F1_UNPAID_REG).length).toBe(0);
    expect(testDbStore.auditEvents.length).toBe(0);
  });

  it("C. allows confirm-manual-payment then approval for paid MANUAL_QR", async () => {
    const confirm = await request(app)
      .post(`/tournaments/registrations/${F1_FLOW_REG}/confirm-manual-payment`)
      .set("Authorization", authHeader(UserRole.PROVINCIAL_DIRECTOR, UUID_DIRECTOR));
    expect(confirm.status).toBe(200);
    expect(confirm.body.status).toBe("PENDING");
    expect(confirm.body.paymentConfirmedByOrganizer).toBe(true);
    const approve = await request(app)
      .post(`/tournaments/registrations/${F1_FLOW_REG}/approve`)
      .set("Authorization", authHeader(UserRole.PROVINCIAL_DIRECTOR, UUID_DIRECTOR));
    expect(approve.status).toBe(200);
    expect(approve.body.status).toBe("APPROVED");
    expect(approve.body.approvedBy).toBe(UUID_DIRECTOR);
    const stored = testDbStore.eventRegistrations.find((r) => r.id === F1_FLOW_REG);
    expect(stored?.status).toBe("APPROVED");
    expect(stored?.paymentConfirmedByOrganizer).toBe(true);
    const actions = testDbStore.auditEvents.filter((e) => e.entityId === F1_FLOW_REG).map((e) => e.action);
    expect(actions).toContain("MANUAL_PAYMENT_CONFIRMATION");
    expect(actions).toContain("REGISTRATION_APPROVAL");
  });

  it("D. rejects athlete approval with 403 and leaves row unchanged", async () => {
    const res = await request(app)
      .post(`/tournaments/registrations/${F1_ATHLETE_REG}/approve`)
      .set("Authorization", authHeader(UserRole.ATHLETE, "user-a"));
    expect(res.status).toBe(403);
    const stored = testDbStore.eventRegistrations.find((r) => r.id === F1_ATHLETE_REG);
    expect(stored?.status).toBe("PENDING_PAYMENT");
    expect(testDbStore.auditEvents.length).toBe(0);
  });

  it("E. duplicate approval is idempotent with a single audit event", async () => {
    const first = await request(app)
      .post(`/tournaments/registrations/${F1_DUP_REG}/approve`)
      .set("Authorization", authHeader(UserRole.PROVINCIAL_DIRECTOR, UUID_DIRECTOR));
    expect(first.status).toBe(200);
    expect(first.body.status).toBe("APPROVED");
    const second = await request(app)
      .post(`/tournaments/registrations/${F1_DUP_REG}/approve`)
      .set("Authorization", authHeader(UserRole.PROVINCIAL_DIRECTOR, UUID_DIRECTOR));
    expect(second.status).toBe(200);
    expect(second.body.status).toBe("APPROVED");
    const approvals = testDbStore.auditEvents.filter((e) => e.action === "REGISTRATION_APPROVAL" && e.entityId === F1_DUP_REG);
    expect(approvals.length).toBe(1);
  });
});
