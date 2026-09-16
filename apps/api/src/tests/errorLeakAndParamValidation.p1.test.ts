import { describe, it, expect, beforeEach, afterEach } from "vitest";
import request from "supertest";
import { testDbStore } from "./setup.js";
import { app } from "../app.js";
import { UserRole } from "@armsphere/types";
import { generateAccessToken } from "@armsphere/cryptography";
import env from "../config/env.js";
import { errorHandler } from "@armsphere/core";

describe("Task 4: Malformed-ID & Error-Leak Prevention", () => {
  let adminToken: string;
  let athleteToken: string;
  const adminUserId = "00000000-0000-0000-0000-000000000001";
  const athleteUserId = "00000000-0000-0000-0000-000000000002";
  const athleteProfileId = "00000000-0000-0000-0000-000000000003";

  beforeEach(() => {
    testDbStore.users = [
      {
        id: adminUserId,
        email: "admin@armsphere.com",
        username: "admin_user",
        role: UserRole.SYSTEM_ADMIN,
        fullName: "System Admin",
        isActive: true,
      },
      {
        id: athleteUserId,
        email: "athlete@armsphere.com",
        username: "athlete_user",
        role: UserRole.ATHLETE,
        fullName: "Athlete User",
        isActive: true,
      },
    ];

    testDbStore.athleteProfiles = [
      {
        id: athleteProfileId,
        userId: athleteUserId,
        displayName: "Athlete User",
        province: "Punjab",
        city: "Lahore",
        handedness: "RIGHT",
        dominantArm: "RIGHT",
        dateOfBirth: new Date("1995-01-01"),
        gender: "MALE",
        weightClass: "80kg",
        profileVisibility: "PUBLIC",
        isSearchable: true,
        isDeleted: false,
      },
    ];

    adminToken = `Bearer ${generateAccessToken(
      adminUserId,
      "admin@armsphere.com",
      UserRole.SYSTEM_ADMIN,
      env.JWT_ACCESS_SECRET
    )}`;

    athleteToken = `Bearer ${generateAccessToken(
      athleteUserId,
      "athlete@armsphere.com",
      UserRole.ATHLETE,
      env.JWT_ACCESS_SECRET
    )}`;
  });

  describe("1. Governance Route Parameter UUID Validation", () => {
    it("POST /governance/disputes/:id/assign rejects malformed UUID with 400", async () => {
      const res = await request(app)
        .post("/governance/disputes/not-a-valid-uuid/assign")
        .set("Authorization", adminToken)
        .send({ reviewerId: "00000000-0000-0000-0000-000000000099" });

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
    });

    it("POST /governance/disputes/:id/evidence rejects malformed UUID with 400", async () => {
      const res = await request(app)
        .post("/governance/disputes/invalid-uuid/evidence")
        .set("Authorization", athleteToken)
        .send({ fileType: "IMAGE", fileUrl: "https://example.com/evidence.jpg" });

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
    });

    it("POST /governance/disputes/:id/comments rejects malformed UUID with 400", async () => {
      const res = await request(app)
        .post("/governance/disputes/invalid-uuid/comments")
        .set("Authorization", athleteToken)
        .send({ comment: "A legitimate comment body" });

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
    });

    it("POST /governance/disputes/:id/resolve rejects malformed UUID with 400", async () => {
      const res = await request(app)
        .post("/governance/disputes/invalid-uuid/resolve")
        .set("Authorization", adminToken)
        .send({ decision: "RESOLVED", resolutionDetails: "Valid resolution details here." });

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
    });

    it("POST /governance/disputes/:id/escalate rejects malformed UUID with 400", async () => {
      const res = await request(app)
        .post("/governance/disputes/invalid-uuid/escalate")
        .set("Authorization", athleteToken)
        .send({ escalationReason: "Valid escalation rationale." });

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
    });

    it("POST /governance/disputes/:id/appeal rejects malformed UUID with 400", async () => {
      const res = await request(app)
        .post("/governance/disputes/invalid-uuid/appeal")
        .set("Authorization", athleteToken)
        .send({ appealReason: "Valid appeal rationale statement." });

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
    });
  });

  describe("2. Community Route Parameter UUID Validation", () => {
    it("GET /community/posts/:id/comments rejects malformed UUID with 400", async () => {
      const res = await request(app)
        .get("/community/posts/not-a-valid-uuid/comments")
        .set("Authorization", athleteToken);

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
    });

    it("POST /community/posts/:id/comments rejects malformed UUID with 400", async () => {
      const res = await request(app)
        .post("/community/posts/not-a-valid-uuid/comments")
        .set("Authorization", athleteToken)
        .send({ body: "Valid comment text." });

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
    });

    it("POST /community/posts/:id/like rejects malformed UUID with 400", async () => {
      const res = await request(app)
        .post("/community/posts/not-a-valid-uuid/like")
        .set("Authorization", athleteToken);

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
    });

    it("DELETE /community/posts/:id/like rejects malformed UUID with 400", async () => {
      const res = await request(app)
        .delete("/community/posts/not-a-valid-uuid/like")
        .set("Authorization", athleteToken);

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
    });

    it("DELETE /community/posts/:id rejects malformed UUID with 400", async () => {
      const res = await request(app)
        .delete("/community/posts/not-a-valid-uuid")
        .set("Authorization", athleteToken);

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
    });

    it("GET /athletes/:id/training-log rejects malformed UUID with 400", async () => {
      const res = await request(app)
        .get("/athletes/not-a-valid-uuid/training-log")
        .set("Authorization", athleteToken);

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
    });

    it("GET /athletes/:id/training-log/prs rejects malformed UUID with 400", async () => {
      const res = await request(app)
        .get("/athletes/not-a-valid-uuid/training-log/prs")
        .set("Authorization", athleteToken);

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
    });
  });

  describe("3. Match Route Parameter UUID Validation", () => {
    it("GET /matches/:id rejects malformed UUID with 400", async () => {
      const res = await request(app)
        .get("/matches/not-a-valid-uuid")
        .set("Authorization", athleteToken);

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
    });

    it("POST /matches/:id/verify rejects malformed UUID with 400", async () => {
      const res = await request(app)
        .post("/matches/not-a-valid-uuid/verify")
        .set("Authorization", adminToken);

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
    });

    it("POST /matches/:id/dispute rejects malformed UUID with 400", async () => {
      const res = await request(app)
        .post("/matches/not-a-valid-uuid/dispute")
        .set("Authorization", athleteToken)
        .send({ reason: "Valid dispute explanation here." });

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
    });

    it("POST /matches/:id/void rejects malformed UUID with 400", async () => {
      const res = await request(app)
        .post("/matches/not-a-valid-uuid/void")
        .set("Authorization", adminToken)
        .send({ reason: "Valid void explanation here." });

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
    });
  });

  describe("4. Global Error Handler Sanitization & Database Error Handling", () => {
    let originalNodeEnv: string | undefined;

    beforeEach(() => {
      originalNodeEnv = process.env.NODE_ENV;
    });

    afterEach(() => {
      process.env.NODE_ENV = originalNodeEnv;
    });

    it("maps raw PostgreSQL 22P02 uuid syntax error into clean 400 Bad Request", () => {
      const mockReq: any = { method: "GET", path: "/test", id: "req-123" };
      let responseStatus = 0;
      let responseBody: any = null;
      const mockRes: any = {
        status: (code: number) => {
          responseStatus = code;
          return {
            json: (body: any) => {
              responseBody = body;
              return body;
            },
          };
        },
      };

      const pgUuidError = new Error('invalid input syntax for type uuid: "not-a-uuid"');
      (pgUuidError as any).code = "22P02";

      errorHandler(pgUuidError, mockReq, mockRes, () => {});

      expect(responseStatus).toBe(400);
      expect(responseBody.success).toBe(false);
      expect(responseBody.title).toBe("Bad Request");
      expect(responseBody.detail).toBe("Invalid UUID format in request identifier.");
      expect(responseBody.requestId).toBe("req-123");
    });

    it("sanitizes 500 error messages in production mode", () => {
      process.env.NODE_ENV = "production";

      const mockReq: any = { method: "POST", path: "/sensitive", id: "req-456" };
      let responseStatus = 0;
      let responseBody: any = null;
      const mockRes: any = {
        status: (code: number) => {
          responseStatus = code;
          return {
            json: (body: any) => {
              responseBody = body;
              return body;
            },
          };
        },
      };

      const internalError = new Error("Database connection password failed: postgres://user:secret@host:5432/db");

      errorHandler(internalError, mockReq, mockRes, () => {});

      expect(responseStatus).toBe(500);
      expect(responseBody.success).toBe(false);
      expect(responseBody.title).toBe("Internal Server Error");
      expect(responseBody.detail).toBe("An internal server error occurred.");
      expect(JSON.stringify(responseBody)).not.toContain("secret");
      expect(JSON.stringify(responseBody)).not.toContain("password");
      expect(responseBody.stack).toBeUndefined();
    });

    it("sanitizes 500 error messages in staging mode", () => {
      process.env.NODE_ENV = "staging";

      const mockReq: any = { method: "GET", path: "/internal", id: "req-789" };
      let responseStatus = 0;
      let responseBody: any = null;
      const mockRes: any = {
        status: (code: number) => {
          responseStatus = code;
          return {
            json: (body: any) => {
              responseBody = body;
              return body;
            },
          };
        },
      };

      const internalError = new Error("SELECT * FROM secret_table syntax error at or near 'WHERE'");

      errorHandler(internalError, mockReq, mockRes, () => {});

      expect(responseStatus).toBe(500);
      expect(responseBody.success).toBe(false);
      expect(responseBody.title).toBe("Internal Server Error");
      expect(responseBody.detail).toBe("An internal server error occurred.");
      expect(JSON.stringify(responseBody)).not.toContain("secret_table");
      expect(responseBody.stack).toBeUndefined();
    });
  });
});
