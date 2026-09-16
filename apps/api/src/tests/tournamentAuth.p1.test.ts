import { describe, it, expect, beforeEach } from "vitest";
import request from "supertest";
import { testDbStore } from "./setup.js";
import { app } from "../app.js";
import { UserRole } from "@armsphere/types";
import { generateAccessToken } from "@armsphere/cryptography";
import { v4 as uuidv4 } from "uuid";
import env from "../config/env.js";

describe("Tournament Event Lifecycle Authorization Hardening (P1 IDOR)", () => {
  const eventId = uuidv4();
  const nonExistentEventId = uuidv4();

  const organizerUserId = uuidv4();
  const adminUserId = uuidv4();
  const nationalDirectorUserId = uuidv4();
  const directorSameProvinceUserId = uuidv4();
  const directorDiffProvinceUserId = uuidv4();
  const directorNoJurUserId = uuidv4();
  const inactiveDirectorUserId = uuidv4();
  const athleteUserId = uuidv4();
  const refereeUserId = uuidv4();

  const PROVINCE_PUNJAB = "Punjab";
  const PROVINCE_SINDH = "Sindh";

  const tok = (uid: string, email: string, role: UserRole) =>
    generateAccessToken(uid, email, role, env.JWT_ACCESS_SECRET);

  beforeEach(() => {
    testDbStore.users = [
      {
        id: organizerUserId,
        email: "organizer@armsphere.test",
        username: "event_organizer",
        role: UserRole.PROVINCIAL_DIRECTOR,
        fullName: "Event Organizer",
        province: PROVINCE_PUNJAB,
        regionalCoverage: PROVINCE_PUNJAB,
        isActive: true,
      },
      {
        id: adminUserId,
        email: "admin@armsphere.test",
        username: "system_admin",
        role: UserRole.SYSTEM_ADMIN,
        fullName: "System Admin",
        isActive: true,
      },
      {
        id: nationalDirectorUserId,
        email: "national@armsphere.test",
        username: "national_director",
        role: UserRole.NATIONAL_DIRECTOR,
        fullName: "National Director",
        isActive: true,
      },
      {
        id: directorSameProvinceUserId,
        email: "dir_punjab@armsphere.test",
        username: "director_punjab",
        role: UserRole.PROVINCIAL_DIRECTOR,
        fullName: "Punjab Director",
        province: PROVINCE_PUNJAB,
        regionalCoverage: PROVINCE_PUNJAB,
        isActive: true,
      },
      {
        id: directorDiffProvinceUserId,
        email: "dir_sindh@armsphere.test",
        username: "director_sindh",
        role: UserRole.PROVINCIAL_DIRECTOR,
        fullName: "Sindh Director",
        province: PROVINCE_SINDH,
        regionalCoverage: PROVINCE_SINDH,
        isActive: true,
      },
      {
        id: directorNoJurUserId,
        email: "dir_nojur@armsphere.test",
        username: "director_nojur",
        role: UserRole.PROVINCIAL_DIRECTOR,
        fullName: "No Jurisdiction Director",
        province: null,
        regionalCoverage: null,
        isActive: true,
      },
      {
        id: inactiveDirectorUserId,
        email: "inactive@armsphere.test",
        username: "inactive_director",
        role: UserRole.PROVINCIAL_DIRECTOR,
        fullName: "Inactive Director",
        province: PROVINCE_PUNJAB,
        regionalCoverage: PROVINCE_PUNJAB,
        isActive: false,
      },
      {
        id: athleteUserId,
        email: "athlete@armsphere.test",
        username: "normal_athlete",
        role: UserRole.ATHLETE,
        fullName: "Normal Athlete",
        isActive: true,
      },
      {
        id: refereeUserId,
        email: "referee@armsphere.test",
        username: "certified_referee",
        role: UserRole.REFEREE,
        fullName: "Certified Referee",
        isActive: true,
      },
    ];

    testDbStore.events = [
      {
        id: eventId,
        name: "Punjab Armwrestling Championship",
        startDate: new Date("2026-10-01T09:00:00Z"),
        endDate: new Date("2026-10-03T18:00:00Z"),
        registrationStart: new Date("2026-08-01T00:00:00Z"),
        registrationEnd: new Date("2026-09-15T23:59:59Z"),
        province: PROVINCE_PUNJAB,
        city: "Lahore",
        venue: "Nishtar Park Sports Complex",
        capacity: 200,
        registrationFeeCents: 3000,
        status: "DRAFT",
        organizerId: organizerUserId,
        paymentMethod: "STRIPE",
        paymentQrImageUrl: null,
        createdAt: new Date(),
        updatedAt: new Date(),
      },
    ];
  });

  const fullEditPayload = {
    name: "Punjab Armwrestling Championship - Updated",
    startDate: "2026-10-01T09:00:00Z",
    endDate: "2026-10-03T18:00:00Z",
    registrationStart: "2026-08-01T00:00:00Z",
    registrationEnd: "2026-09-15T23:59:59Z",
    province: PROVINCE_PUNJAB,
    city: "Lahore",
    venue: "Gaddafi Stadium Arena",
    capacity: 250,
    registrationFeeCents: 3500,
    organizerId: organizerUserId,
    paymentMethod: "STRIPE",
  };

  describe("PUT /tournaments/events/:id (Full Edit)", () => {
    it("allows the owning event organizer to edit the event", async () => {
      const res = await request(app)
        .put(`/tournaments/events/${eventId}`)
        .set("Authorization", `Bearer ${tok(organizerUserId, "organizer@armsphere.test", UserRole.PROVINCIAL_DIRECTOR)}`)
        .send(fullEditPayload);

      expect(res.status).toBe(200);
      expect(res.body.venue).toBe("Gaddafi Stadium Arena");
      expect(res.body.capacity).toBe(250);
    });

    it("allows a universal SYSTEM_ADMIN to edit the event", async () => {
      const res = await request(app)
        .put(`/tournaments/events/${eventId}`)
        .set("Authorization", `Bearer ${tok(adminUserId, "admin@armsphere.test", UserRole.SYSTEM_ADMIN)}`)
        .send(fullEditPayload);

      expect(res.status).toBe(200);
      expect(res.body.venue).toBe("Gaddafi Stadium Arena");
    });

    it("allows a universal NATIONAL_DIRECTOR to edit the event", async () => {
      const res = await request(app)
        .put(`/tournaments/events/${eventId}`)
        .set("Authorization", `Bearer ${tok(nationalDirectorUserId, "national@armsphere.test", UserRole.NATIONAL_DIRECTOR)}`)
        .send(fullEditPayload);

      expect(res.status).toBe(200);
      expect(res.body.venue).toBe("Gaddafi Stadium Arena");
    });

    it("allows a PROVINCIAL_DIRECTOR with matching jurisdiction (Punjab) to edit the event", async () => {
      const res = await request(app)
        .put(`/tournaments/events/${eventId}`)
        .set("Authorization", `Bearer ${tok(directorSameProvinceUserId, "dir_punjab@armsphere.test", UserRole.PROVINCIAL_DIRECTOR)}`)
        .send(fullEditPayload);

      expect(res.status).toBe(200);
      expect(res.body.venue).toBe("Gaddafi Stadium Arena");
    });

    it("rejects a PROVINCIAL_DIRECTOR from a different province (Sindh) with 403", async () => {
      const res = await request(app)
        .put(`/tournaments/events/${eventId}`)
        .set("Authorization", `Bearer ${tok(directorDiffProvinceUserId, "dir_sindh@armsphere.test", UserRole.PROVINCIAL_DIRECTOR)}`)
        .send(fullEditPayload);

      expect(res.status).toBe(403);
      expect(res.body.detail).toContain("Sindh");
    });

    it("rejects a PROVINCIAL_DIRECTOR with null jurisdiction with 403", async () => {
      const res = await request(app)
        .put(`/tournaments/events/${eventId}`)
        .set("Authorization", `Bearer ${tok(directorNoJurUserId, "dir_nojur@armsphere.test", UserRole.PROVINCIAL_DIRECTOR)}`)
        .send(fullEditPayload);

      expect(res.status).toBe(403);
      expect(res.body.detail).toContain("missing");
    });

    it("rejects an inactive director with 403", async () => {
      const res = await request(app)
        .put(`/tournaments/events/${eventId}`)
        .set("Authorization", `Bearer ${tok(inactiveDirectorUserId, "inactive@armsphere.test", UserRole.PROVINCIAL_DIRECTOR)}`)
        .send(fullEditPayload);

      expect(res.status).toBe(403);
    });

    it("rejects unprivileged staff (REFEREE) with 403", async () => {
      const res = await request(app)
        .put(`/tournaments/events/${eventId}`)
        .set("Authorization", `Bearer ${tok(refereeUserId, "referee@armsphere.test", UserRole.REFEREE)}`)
        .send(fullEditPayload);

      expect(res.status).toBe(403);
    });

    it("rejects an athlete with spoofed SYSTEM_ADMIN token via canonical DB check", async () => {
      // JWT claims SYSTEM_ADMIN, but canonical user row is ATHLETE
      const res = await request(app)
        .put(`/tournaments/events/${eventId}`)
        .set("Authorization", `Bearer ${tok(athleteUserId, "athlete@armsphere.test", UserRole.SYSTEM_ADMIN)}`)
        .send(fullEditPayload);

      expect(res.status).toBe(403);
    });

    it("returns 404 for a non-existent event UUID", async () => {
      const res = await request(app)
        .put(`/tournaments/events/${nonExistentEventId}`)
        .set("Authorization", `Bearer ${tok(adminUserId, "admin@armsphere.test", UserRole.SYSTEM_ADMIN)}`)
        .send(fullEditPayload);

      expect(res.status).toBe(404);
    });

    it("returns 401 for an unauthenticated request", async () => {
      const res = await request(app)
        .put(`/tournaments/events/${eventId}`)
        .send(fullEditPayload);

      expect(res.status).toBe(401);
    });
  });

  describe("POST /tournaments/events/:id/publish (Publish Event)", () => {
    it("allows the owning organizer to publish the event", async () => {
      const res = await request(app)
        .post(`/tournaments/events/${eventId}/publish`)
        .set("Authorization", `Bearer ${tok(organizerUserId, "organizer@armsphere.test", UserRole.PROVINCIAL_DIRECTOR)}`);

      expect(res.status).toBe(200);
      expect(res.body.status).toBe("PUBLISHED");
    });

    it("allows a universal SYSTEM_ADMIN to publish the event", async () => {
      const res = await request(app)
        .post(`/tournaments/events/${eventId}/publish`)
        .set("Authorization", `Bearer ${tok(adminUserId, "admin@armsphere.test", UserRole.SYSTEM_ADMIN)}`);

      expect(res.status).toBe(200);
      expect(res.body.status).toBe("PUBLISHED");
    });

    it("allows a same-province PROVINCIAL_DIRECTOR to publish the event", async () => {
      const res = await request(app)
        .post(`/tournaments/events/${eventId}/publish`)
        .set("Authorization", `Bearer ${tok(directorSameProvinceUserId, "dir_punjab@armsphere.test", UserRole.PROVINCIAL_DIRECTOR)}`);

      expect(res.status).toBe(200);
      expect(res.body.status).toBe("PUBLISHED");
    });

    it("rejects a different-province PROVINCIAL_DIRECTOR from publishing with 403", async () => {
      const res = await request(app)
        .post(`/tournaments/events/${eventId}/publish`)
        .set("Authorization", `Bearer ${tok(directorDiffProvinceUserId, "dir_sindh@armsphere.test", UserRole.PROVINCIAL_DIRECTOR)}`);

      expect(res.status).toBe(403);
      expect(res.body.detail).toContain("Sindh");
    });

    it("rejects an unprivileged caller from publishing with 403", async () => {
      const res = await request(app)
        .post(`/tournaments/events/${eventId}/publish`)
        .set("Authorization", `Bearer ${tok(athleteUserId, "athlete@armsphere.test", UserRole.ATHLETE)}`);

      expect(res.status).toBe(403);
    });
  });

  describe("POST /tournaments/events/:id/cancel (Cancel Event)", () => {
    it("allows the owning organizer to cancel the event", async () => {
      const res = await request(app)
        .post(`/tournaments/events/${eventId}/cancel`)
        .set("Authorization", `Bearer ${tok(organizerUserId, "organizer@armsphere.test", UserRole.PROVINCIAL_DIRECTOR)}`);

      expect(res.status).toBe(200);
      expect(res.body.status).toBe("CANCELLED");
    });

    it("allows a universal SYSTEM_ADMIN to cancel the event", async () => {
      const res = await request(app)
        .post(`/tournaments/events/${eventId}/cancel`)
        .set("Authorization", `Bearer ${tok(adminUserId, "admin@armsphere.test", UserRole.SYSTEM_ADMIN)}`);

      expect(res.status).toBe(200);
      expect(res.body.status).toBe("CANCELLED");
    });

    it("allows a same-province PROVINCIAL_DIRECTOR to cancel the event", async () => {
      const res = await request(app)
        .post(`/tournaments/events/${eventId}/cancel`)
        .set("Authorization", `Bearer ${tok(directorSameProvinceUserId, "dir_punjab@armsphere.test", UserRole.PROVINCIAL_DIRECTOR)}`);

      expect(res.status).toBe(200);
      expect(res.body.status).toBe("CANCELLED");
    });

    it("rejects a different-province PROVINCIAL_DIRECTOR from cancelling with 403", async () => {
      const res = await request(app)
        .post(`/tournaments/events/${eventId}/cancel`)
        .set("Authorization", `Bearer ${tok(directorDiffProvinceUserId, "dir_sindh@armsphere.test", UserRole.PROVINCIAL_DIRECTOR)}`);

      expect(res.status).toBe(403);
      expect(res.body.detail).toContain("Sindh");
    });

    it("rejects an unprivileged caller from cancelling with 403", async () => {
      const res = await request(app)
        .post(`/tournaments/events/${eventId}/cancel`)
        .set("Authorization", `Bearer ${tok(athleteUserId, "athlete@armsphere.test", UserRole.ATHLETE)}`);

      expect(res.status).toBe(403);
    });
  });

  describe("PATCH /tournaments/events/:id (Partial Edit)", () => {
    it("allows the owning organizer to patch the event", async () => {
      const res = await request(app)
        .patch(`/tournaments/events/${eventId}`)
        .set("Authorization", `Bearer ${tok(organizerUserId, "organizer@armsphere.test", UserRole.PROVINCIAL_DIRECTOR)}`)
        .send({ venue: "Updated Via Patch" });

      expect(res.status).toBe(200);
      expect(res.body.venue).toBe("Updated Via Patch");
    });

    it("allows a universal SYSTEM_ADMIN to patch the event", async () => {
      const res = await request(app)
        .patch(`/tournaments/events/${eventId}`)
        .set("Authorization", `Bearer ${tok(adminUserId, "admin@armsphere.test", UserRole.SYSTEM_ADMIN)}`)
        .send({ capacity: 300 });

      expect(res.status).toBe(200);
      expect(res.body.capacity).toBe(300);
    });

    it("rejects an unprivileged athlete from patching with 403", async () => {
      const res = await request(app)
        .patch(`/tournaments/events/${eventId}`)
        .set("Authorization", `Bearer ${tok(athleteUserId, "athlete@armsphere.test", UserRole.ATHLETE)}`)
        .send({ venue: "Tampered Venue" });

      expect(res.status).toBe(403);
    });

    it("rejects an athlete with spoofed SYSTEM_ADMIN token via canonical DB check", async () => {
      const res = await request(app)
        .patch(`/tournaments/events/${eventId}`)
        .set("Authorization", `Bearer ${tok(athleteUserId, "athlete@armsphere.test", UserRole.SYSTEM_ADMIN)}`)
        .send({ venue: "Tampered Venue" });

      expect(res.status).toBe(403);
    });
  });
});
