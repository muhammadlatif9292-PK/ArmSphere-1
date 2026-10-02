import { describe, it, expect, beforeEach, vi } from "vitest";
import request from "supertest";
import { testDbStore } from "./setup.js";
import { app } from "../app.js";
import crypto from "crypto";
import {
  FederationCertificateService,
  HttpFederationCertificateProvider,
  validatePdfArtifact,
  IFederationCertificateProvider,
  CertificatePayload,
} from "../services/federationCertificate.js";
import {
  ExternalServiceUnconfiguredError,
  ForbiddenError,
  NotFoundError,
  BadRequestError,
  InvalidCertificateArtifactError,
  CertificateTimeoutError,
  CertificateUpstreamError,
  StorageUploadError,
} from "@armsphere/core";
import { UserRole } from "@armsphere/types";
import { generateAccessToken } from "@armsphere/cryptography";
import env from "../config/env.js";

// Helper to create a valid minimal PDF buffer for testing
function createValidPdfBuffer(content = "PAFF Official Certificate Test"): Buffer {
  const header = "%PDF-1.4\n";
  const body = `1 0 obj\n<< /Title (${content}) >>\nendobj\n`;
  const padding = "%\n".repeat(30); // Ensure size > 100 bytes
  const trailer = "xref\n0 1\n0000000000 65535 f \ntrailer\n<< /Size 1 >>\nstartxref\n99\n%%EOF\n";
  return Buffer.from(header + body + padding + trailer, "utf-8");
}

describe("Federation Certificate & Sanction Closure Subsystem", () => {
  const mockAdminId = "11111111-1111-1111-1111-111111111111";
  const mockDirectorId = "22222222-2222-2222-2222-222222222222";
  const mockProvincialId = "33333333-3333-3333-3333-333333333333";
  const mockAthleteId = "44444444-4444-4444-4444-444444444444";
  const mockRefereeId = "55555555-5555-5555-5555-555555555555";
  const mockEventId = "66666666-6666-6666-6666-666666666666";

  let adminToken: string;
  let directorToken: string;
  let athleteToken: string;

  beforeEach(() => {
    // Reset DB store
    testDbStore.users = [
      {
        id: mockAdminId,
        email: "admin@armsphere.com",
        username: "admin_user",
        role: UserRole.SYSTEM_ADMIN,
        fullName: "System Admin",
        isActive: true,
      },
      {
        id: mockDirectorId,
        email: "director@armsphere.com",
        username: "director_user",
        role: UserRole.NATIONAL_DIRECTOR,
        fullName: "National Director",
        isActive: true,
      },
      {
        id: mockProvincialId,
        email: "provincial@armsphere.com",
        username: "provincial_user",
        role: UserRole.PROVINCIAL_DIRECTOR,
        regionalCoverage: "Punjab",
        fullName: "Provincial Director",
        isActive: true,
      },
      {
        id: mockAthleteId,
        email: "athlete@armsphere.com",
        username: "athlete_user",
        role: UserRole.ATHLETE,
        fullName: "Athlete User",
        isActive: true,
      },
      {
        id: mockRefereeId,
        email: "referee@armsphere.com",
        username: "referee_user",
        role: UserRole.REFEREE,
        fullName: "Referee User",
        isActive: true,
      },
    ];

    adminToken = `Bearer ${generateAccessToken(mockAdminId, "admin@armsphere.com", UserRole.SYSTEM_ADMIN, env.JWT_ACCESS_SECRET)}`;
    directorToken = `Bearer ${generateAccessToken(mockDirectorId, "director@armsphere.com", UserRole.NATIONAL_DIRECTOR, env.JWT_ACCESS_SECRET)}`;
    athleteToken = `Bearer ${generateAccessToken(mockAthleteId, "athlete@armsphere.com", UserRole.ATHLETE, env.JWT_ACCESS_SECRET)}`;

    testDbStore.events = [
      {
        id: mockEventId,
        name: "National Armwrestling Championship 2026",
        startDate: new Date("2026-08-01"),
        endDate: new Date("2026-08-03"),
        province: "PUNJAB",
        city: "Lahore",
        venue: "Nishtar Park Sports Complex",
        capacity: 500,
        status: "PUBLISHED",
      },
    ];
    testDbStore.officialCertificates = [];

    // Ensure external service is unconfigured by default in test env
    env.FEDERATION_CERT_SERVICE_URL = "";
    env.FEDERATION_CERT_API_KEY = "";
    env.FEDERATION_CERT_SIGNING_KEY_ID = "";
  });

  describe("1. Artifact Validation & Magic Bytes Verification", () => {
    it("should accept valid PDF buffers with %PDF- header and size >= 100 bytes", () => {
      const validPdf = createValidPdfBuffer("Valid Test Certificate");
      expect(validPdf.length).toBeGreaterThanOrEqual(100);
      expect(() => validatePdfArtifact(validPdf)).not.toThrow();
    });

    it("should reject buffers shorter than 100 bytes", () => {
      const shortBuffer = Buffer.from("%PDF-short", "utf-8");
      expect(() => validatePdfArtifact(shortBuffer)).toThrow(
        InvalidCertificateArtifactError
      );
      expect(() => validatePdfArtifact(shortBuffer)).toThrow("less than 100 bytes");
    });

    it("should reject non-PDF artifacts even if HTTP 200 (e.g. HTML error page or captive portal)", () => {
      const htmlPayload = Buffer.from(
        "<!DOCTYPE html><html><body><h1>Error 500</h1><p>Internal gateway failure</p></body></html>" +
          " ".repeat(100)
      );
      expect(() => validatePdfArtifact(htmlPayload)).toThrow(
        InvalidCertificateArtifactError
      );
      expect(() => validatePdfArtifact(htmlPayload)).toThrow(
        "missing %PDF- header magic bytes"
      );
    });

    it("should reject JSON responses masquerading as artifacts", () => {
      const jsonPayload = Buffer.from(
        JSON.stringify({ status: "error", message: "Upstream token revoked", padding: "x".repeat(100) })
      );
      expect(() => validatePdfArtifact(jsonPayload)).toThrow(
        InvalidCertificateArtifactError
      );
    });
  });

  describe("2. HTTP Provider Adapter Boundary", () => {
    it("should fail-closed when FEDERATION_CERT_SERVICE_URL is unconfigured", async () => {
      const provider = new HttpFederationCertificateProvider({ serviceUrl: "" });
      expect(provider.isConfigured()).toBe(false);

      const payload: CertificatePayload = {
        certificateType: "TOURNAMENT_SANCTION",
        entityId: mockEventId,
        recipientName: "National Armwrestling Championship",
        issuerId: mockAdminId,
        issuerRole: "SYSTEM_ADMIN",
        metadata: {},
        idempotencyKey: `sanction-${mockEventId}`,
      };

      await expect(provider.generateCertificate(payload)).rejects.toThrow(
        ExternalServiceUnconfiguredError
      );
    });

    it("should handle upstream HTTP 500 error gracefully without leaking secrets", async () => {
      // Mock global fetch to return 500
      const originalFetch = globalThis.fetch;
      globalThis.fetch = vi.fn().mockResolvedValue({
        ok: false,
        status: 500,
        statusText: "Internal Server Error",
      } as any);

      try {
        const provider = new HttpFederationCertificateProvider({
          serviceUrl: "https://pdf-stamping.internal/api/v1/generate",
          apiKey: "super-secret-key-12345",
        });

        const payload: CertificatePayload = {
          certificateType: "TOURNAMENT_SANCTION",
          entityId: mockEventId,
          recipientName: "National Armwrestling Championship",
          issuerId: mockAdminId,
          issuerRole: "SYSTEM_ADMIN",
          metadata: {},
          idempotencyKey: `sanction-${mockEventId}`,
        };

        await expect(provider.generateCertificate(payload)).rejects.toThrow(
          CertificateUpstreamError
        );
      } finally {
        globalThis.fetch = originalFetch;
      }
    });

    it("should handle network abort/timeout cleanly", async () => {
      const originalFetch = globalThis.fetch;
      globalThis.fetch = vi.fn().mockImplementation((url, options) => {
        return new Promise((_, reject) => {
          options.signal.addEventListener("abort", () => {
            const err = new Error("The operation was aborted");
            err.name = "AbortError";
            reject(err);
          });
        });
      });

      try {
        const provider = new HttpFederationCertificateProvider({
          serviceUrl: "https://pdf-stamping.internal/api/v1/generate",
          timeoutMs: 50, // Short timeout for test
        });

        const payload: CertificatePayload = {
          certificateType: "TOURNAMENT_SANCTION",
          entityId: mockEventId,
          recipientName: "National Armwrestling Championship",
          issuerId: mockAdminId,
          issuerRole: "SYSTEM_ADMIN",
          metadata: {},
          idempotencyKey: `sanction-${mockEventId}`,
        };

        await expect(provider.generateCertificate(payload)).rejects.toThrow(
          CertificateTimeoutError
        );
      } finally {
        globalThis.fetch = originalFetch;
      }
    });

    it("should validate and compute SHA-256 integrity hash when upstream succeeds", async () => {
      const validPdf = createValidPdfBuffer("Official Verified Certificate Stamped");
      const expectedHash = crypto.createHash("sha256").update(validPdf).digest("hex");

      const originalFetch = globalThis.fetch;
      globalThis.fetch = vi.fn().mockResolvedValue({
        ok: true,
        status: 200,
        arrayBuffer: async () => validPdf.buffer.slice(validPdf.byteOffset, validPdf.byteOffset + validPdf.byteLength),
      } as any);

      try {
        const provider = new HttpFederationCertificateProvider({
          serviceUrl: "https://pdf-stamping.internal/api/v1/generate",
          apiKey: "valid-key",
        });

        const payload: CertificatePayload = {
          certificateType: "TOURNAMENT_SANCTION",
          entityId: mockEventId,
          recipientName: "National Armwrestling Championship",
          issuerId: mockAdminId,
          issuerRole: "SYSTEM_ADMIN",
          metadata: {},
          idempotencyKey: `sanction-${mockEventId}`,
        };

        const result = await provider.generateCertificate(payload);
        expect(result.contentType).toBe("application/pdf");
        expect(result.sha256Hash).toBe(expectedHash);
        expect(result.pdfBuffer.length).toBe(validPdf.length);
      } finally {
        globalThis.fetch = originalFetch;
      }
    });
  });

  describe("3. Federation Certificate Service — Authorization & Gates", () => {
    it("should forbid non-executive roles (ATHLETE, REFEREE, PROVINCIAL_DIRECTOR) from issuing sanction certificates", async () => {
      // ATHLETE
      await expect(
        FederationCertificateService.issueSanctionCertificate(
          mockAthleteId,
          "ATHLETE",
          mockEventId
        )
      ).rejects.toThrow(ForbiddenError);

      // REFEREE
      await expect(
        FederationCertificateService.issueSanctionCertificate(
          mockRefereeId,
          "REFEREE",
          mockEventId
        )
      ).rejects.toThrow(ForbiddenError);

      // PROVINCIAL_DIRECTOR
      await expect(
        FederationCertificateService.issueSanctionCertificate(
          mockProvincialId,
          "PROVINCIAL_DIRECTOR",
          mockEventId
        )
      ).rejects.toThrow(ForbiddenError);
    });

    it("should throw NotFoundError if tournament event does not exist", async () => {
      await expect(
        FederationCertificateService.issueSanctionCertificate(
          mockAdminId,
          "SYSTEM_ADMIN",
          "00000000-0000-0000-0000-000000000000"
        )
      ).rejects.toThrow(NotFoundError);
    });

    it("should fail-closed with status BLOCKED when external service is unconfigured (Zero Fabrication)", async () => {
      expect(FederationCertificateService.isConfigured()).toBe(false);

      await expect(
        FederationCertificateService.issueSanctionCertificate(
          mockDirectorId,
          "NATIONAL_DIRECTOR",
          mockEventId
        )
      ).rejects.toThrow(ExternalServiceUnconfiguredError);


      // Verify that database recorded the status as BLOCKED honestly
      const certs = testDbStore.officialCertificates;
      expect(certs.length).toBe(1);
      expect(certs[0].status).toBe("BLOCKED");
      expect(certs[0].blockedReason).toContain("unconfigured");
      expect(certs[0].fileKey).toBeUndefined(); // NO fake file key created
    });
  });

  describe("4. End-to-End Success & Idempotency (with verified test provider)", () => {
    const validPdf = createValidPdfBuffer("PAFF Official Sanction Certificate 2026");
    const expectedHash = crypto.createHash("sha256").update(validPdf).digest("hex");

    const mockProvider: IFederationCertificateProvider = {
      name: "MockTestCertificateProvider",
      generateCertificate: vi.fn().mockResolvedValue({
        pdfBuffer: validPdf,
        contentType: "application/pdf",
        sha256Hash: expectedHash,
      }),
    };

    it("should issue sanction certificate, persist to B2 storage, and record in database", async () => {
      const storageSpy = vi.fn().mockResolvedValue(undefined);

      const result = await FederationCertificateService.issueSanctionCertificate(
        mockDirectorId,
        "NATIONAL_DIRECTOR",
        mockEventId,
        {
          providerOverride: mockProvider,
          storageUploadOverride: storageSpy,
        }
      );

      expect(result.status).toBe("ISSUED");
      expect(result.certificateNumber).toMatch(/^PAFF-SANC-/);
      expect(result.sha256Hash).toBe(expectedHash);
      expect(result.fileKey).toBe(`documents/certificates/sanction-${mockEventId}.pdf`);

      // Verify storage upload was called
      expect(storageSpy).toHaveBeenCalledTimes(1);

      // Verify database record
      const inDb = testDbStore.officialCertificates.find((c) => c.eventId === mockEventId);
      expect(inDb).toBeDefined();
      expect(inDb.status).toBe("ISSUED");
      expect(inDb.sha256Hash).toBe(expectedHash);
    });

    it("should handle duplicate issuance requests idempotently", async () => {
      const storageSpy = vi.fn().mockResolvedValue(undefined);

      // First call
      const first = await FederationCertificateService.issueSanctionCertificate(
        mockAdminId,
        "SYSTEM_ADMIN",
        mockEventId,
        {
          providerOverride: mockProvider,
          storageUploadOverride: storageSpy,
        }
      );

      // Second call (idempotent)
      const second = await FederationCertificateService.issueSanctionCertificate(
        mockAdminId,
        "SYSTEM_ADMIN",
        mockEventId,
        {
          providerOverride: mockProvider,
          storageUploadOverride: storageSpy,
        }
      );

      expect(second.status).toBe("ISSUED");
      expect(second.id).toBe(first.id);
      expect(second.certificateNumber).toBe(first.certificateNumber);
      // Ensure storage was not called a second time
      expect(storageSpy).toHaveBeenCalledTimes(1);
    });

    it("should fail cleanly if B2 object storage upload fails", async () => {
      const failingStorageSpy = vi.fn().mockRejectedValue(
        new Error("B2 connection reset by peer")
      );

      await expect(
        FederationCertificateService.issueSanctionCertificate(
          mockDirectorId,
          "NATIONAL_DIRECTOR",
          mockEventId,
          {
            providerOverride: mockProvider,
            storageUploadOverride: failingStorageSpy,
          }
        )
      ).rejects.toThrow(StorageUploadError);

      expect(failingStorageSpy).toHaveBeenCalledTimes(1);
    });
  });

  describe("5. Document Retrieval & Honest Reporting", () => {
    it("should report BLOCKED status in listTournamentDocuments when unconfigured", async () => {
      const docs = await FederationCertificateService.listTournamentDocuments(mockEventId);
      const sanctionDoc = docs.find((d) => d.id === "sanction-cert");
      expect(sanctionDoc).toBeDefined();
      expect(sanctionDoc?.isBlocked).toBe(true);
      expect(sanctionDoc?.status).toBe("BLOCKED");
      expect(sanctionDoc?.blockedReason).toContain("FEDERATION_CERT_SERVICE_URL");
    });

    it("should reject getTournamentDocument with 503 for unconfigured sanction certificate", async () => {
      await expect(
        FederationCertificateService.getTournamentDocument(mockEventId, "sanction-cert")
      ).rejects.toThrow(ExternalServiceUnconfiguredError);
    });

    it("should return valid download URL for static official documents (rulebook, medical)", async () => {
      const rulebook = await FederationCertificateService.getTournamentDocument(mockEventId, "rulebook");
      expect(rulebook.title).toContain("Rulebook");
      expect(rulebook.url).toContain(".pdf");
    });

    it("should return honest status in getEventSanctionCertificate", async () => {
      const status = await FederationCertificateService.getEventSanctionCertificate(mockEventId);
      expect(status.status).toBe("BLOCKED");
      expect(status.isConfigured).toBe(false);
      expect(status.blockedReason).toContain("FEDERATION_CERT_SERVICE_URL");
    });
  });

  describe("6. Sanction Preconditions & Incomplete Tournament State Validation", () => {
    it("should reject sanction issuance for a cancelled tournament with BadRequestError", async () => {
      const cancelledEventId = "cancelled-event-123";
      testDbStore.events.push({
        id: cancelledEventId,
        name: "Cancelled Arm Bash",
        startDate: new Date("2026-09-01"),
        endDate: new Date("2026-09-02"),
        province: "PUNJAB",
        city: "Lahore",
        venue: "Gym Hall",
        status: "CANCELLED",
      });

      await expect(
        FederationCertificateService.issueSanctionCertificate(
          mockDirectorId,
          "NATIONAL_DIRECTOR",
          cancelledEventId
        )
      ).rejects.toThrow("Cannot issue a sanction certificate for a cancelled tournament.");
    });

    it("should reject sanction issuance when mandatory venue/city/province are missing", async () => {
      const incompleteEventId = "incomplete-event-123";
      testDbStore.events.push({
        id: incompleteEventId,
        name: "Incomplete Tournament",
        startDate: new Date("2026-09-01"),
        endDate: new Date("2026-09-02"),
        province: "",
        city: "",
        venue: "",
        status: "PUBLISHED",
      });

      await expect(
        FederationCertificateService.issueSanctionCertificate(
          mockDirectorId,
          "NATIONAL_DIRECTOR",
          incompleteEventId
        )
      ).rejects.toThrow("Incomplete sanction conditions: Tournament venue, city, and province are mandatory.");
    });

    it("should reject sanction issuance when tournament end date precedes start date", async () => {
      const invalidDatesEventId = "invalid-dates-event-123";
      testDbStore.events.push({
        id: invalidDatesEventId,
        name: "Time Traveler Tournament",
        startDate: new Date("2026-09-10"),
        endDate: new Date("2026-09-05"), // before start
        province: "SINDH",
        city: "Karachi",
        venue: "Beach Arena",
        status: "PUBLISHED",
      });

      await expect(
        FederationCertificateService.issueSanctionCertificate(
          mockDirectorId,
          "NATIONAL_DIRECTOR",
          invalidDatesEventId
        )
      ).rejects.toThrow("Incomplete sanction conditions: Tournament end date cannot precede start date.");
    });
  });

  describe("7. HTTP Route-Level Integration & Fail-Closed Gating", () => {
    it("should reject unauthenticated POST /tournaments/events/:id/sanction-certificate with 401", async () => {
      const response = await request(app)
        .post(`/tournaments/events/${mockEventId}/sanction-certificate`)
        .send({});

      expect(response.status).toBe(401);
    });

    it("should reject unauthorized roles (ATHLETE) on POST /tournaments/events/:id/sanction-certificate with 403", async () => {
      const response = await request(app)
        .post(`/tournaments/events/${mockEventId}/sanction-certificate`)
        .set("Authorization", athleteToken)
        .send({});

      expect(response.status).toBe(403);
    });

    it("should fail-closed with 503 on POST /tournaments/events/:id/sanction-certificate when external service is unconfigured", async () => {
      const response = await request(app)
        .post(`/tournaments/events/${mockEventId}/sanction-certificate`)
        .set("Authorization", directorToken)
        .send({});

      expect(response.status).toBe(503);
      expect(response.body.title).toBe("Service Unavailable");
      expect(response.body.detail).toContain("unconfigured");
    });

    it("should return honest status BLOCKED on GET /tournaments/events/:id/sanction-certificate", async () => {
      const response = await request(app)
        .get(`/tournaments/events/${mockEventId}/sanction-certificate`)
        .set("Authorization", athleteToken);

      expect(response.status).toBe(200);
      expect(response.body.data.status).toBe("BLOCKED");
      expect(response.body.data.isConfigured).toBe(false);
    });

    it("should include blocked sanction-cert in GET /tournaments/events/:id/documents", async () => {
      const response = await request(app)
        .get(`/tournaments/events/${mockEventId}/documents`)
        .set("Authorization", athleteToken);

      expect(response.status).toBe(200);
      const docs = response.body;
      const sanctionDoc = docs.find((d: any) => d.id === "sanction-cert");
      expect(sanctionDoc).toBeDefined();
      expect(sanctionDoc.isBlocked).toBe(true);
      expect(sanctionDoc.status).toBe("BLOCKED");
    });

    it("should return 503 fail-closed on GET /tournaments/events/:id/documents/sanction-cert when unconfigured", async () => {
      const response = await request(app)
        .get(`/tournaments/events/${mockEventId}/documents/sanction-cert`)
        .set("Authorization", athleteToken);

      expect(response.status).toBe(503);
    });
  });
});
