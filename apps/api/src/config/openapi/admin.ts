import { rfc7807ErrorSchema } from "./common.js";

export const adminPaths = {
  "/admin/users/roles": {
    post: {
      tags: ["Administration"],
      summary: "Modify user system-wide roles",
      description: "Allows a System Administrator or National Director to elevate or demote roles. Requires Admin/Director.",
      security: [{ BearerAuth: [] }],
      requestBody: {
        required: true,
        content: {
          "application/json": {
            schema: {
              type: "object",
              required: ["userId", "role"],
              properties: {
                userId: { type: "string", format: "uuid", example: "550e8400-e29b-41d4-a716-446655440000" },
                role: { type: "string", enum: ["ATHLETE", "REFEREE", "PROVINCIAL_DIRECTOR", "NATIONAL_DIRECTOR", "SYSTEM_ADMIN"], example: "REFEREE" },
              },
            },
          },
        },
      },
      responses: {
        200: {
          description: "Role successfully updated.",
          content: { "application/json": { schema: { type: "object", properties: { success: { type: "boolean", example: true } } } } },
        },
        403: { description: "Insufficient privileges.", content: { "application/problem+json": { schema: rfc7807ErrorSchema } } },
      },
    },
  },
  "/admin/secrets/rotate-jwt": {
    post: {
      tags: ["Administration", "Security Operations"],
      summary: "Rotate system JWT signing secrets",
      description: "Triggers active JWT keys rotation and invalidation chains. Requires System Admin.",
      security: [{ BearerAuth: [] }],
      requestBody: {
        required: true,
        content: {
          "application/json": {
            schema: {
              type: "object",
              required: ["newAccessSecret", "newRefreshSecret"],
              properties: {
                newAccessSecret: { type: "string", minLength: 32, example: "super_secure_access_secret_rotated_value_32_chars" },
                newRefreshSecret: { type: "string", minLength: 32, example: "super_secure_refresh_secret_rotated_value_32_chars" },
              },
            },
          },
        },
      },
      responses: {
        200: {
          description: "JWT secrets rotated.",
          content: { "application/json": { schema: { type: "object", properties: { success: { type: "boolean", example: true } } } } },
        },
      },
    },
  },
  "/api/v1/security/captcha/verify": {
    post: {
      tags: ["Security Operations"],
      summary: "Verify client-side CAPTCHA tokens",
      description: "Authenticates Cloudflare Turnstile or Google reCAPTCHA v3 tokens from the client browser.",
      requestBody: {
        required: true,
        content: {
          "application/json": {
            schema: {
              type: "object",
              required: ["token"],
              properties: {
                token: { type: "string", example: "XXXX.YYYY.ZZZZ" },
              },
            },
          },
        },
      },
      responses: {
        200: {
          description: "CAPTCHA verification result.",
          content: {
            "application/json": {
              schema: {
                type: "object",
                properties: {
                  success: { type: "boolean", example: true },
                  data: {
                    type: "object",
                    properties: {
                      verified: { type: "boolean", example: true },
                      message: { type: "string", example: "CAPTCHA verification succeeded." },
                    },
                  },
                },
              },
            },
          },
        },
      },
    },
  },
  "/api/health": {
    get: {
      tags: ["Observability & Diagnostics"],
      summary: "Platform general health status check",
      description: "Checks if server is accepting requests.",
      responses: {
        200: {
          description: "Server is healthy.",
          content: { "application/json": { schema: { type: "object", properties: { status: { type: "string", example: "healthy" } } } } },
        },
      },
    },
  },
  "/api/ready": {
    get: {
      tags: ["Observability & Diagnostics"],
      summary: "Database connectivity readiness probe",
      description: "Checks deep connection dependencies for database and caching servers.",
      responses: {
        200: {
          description: "Infrastructure ready.",
          content: { "application/json": { schema: { type: "object", properties: { status: { type: "string", example: "ready" } } } } },
        },
        503: {
          description: "Infrastructure degraded or database down.",
          content: { "application/json": { schema: { type: "object", properties: { status: { type: "string", example: "degraded" } } } } },
        },
      },
    },
  },
};
