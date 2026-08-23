import { rfc7807ErrorSchema } from "./common.js";

export const authPaths = {
  "/api/v1/auth/register": {
    post: {
      tags: ["Authentication"],
      summary: "Register a new user account",
      description: "Creates a new user profile with selected roles.",
      requestBody: {
        required: true,
        content: {
          "application/json": {
            schema: {
              type: "object",
              required: ["email", "password", "fullName", "username"],
              properties: {
                email: { type: "string", format: "email", example: "competitor@armsphere.com" },
                password: { type: "string", minLength: 8, example: "SecretP@ss123" },
                fullName: { type: "string", example: "John Armwrestler" },
                username: { type: "string", example: "john_puller" },
                role: { type: "string", enum: ["ATHLETE", "REFEREE", "PROVINCIAL_DIRECTOR", "NATIONAL_DIRECTOR", "SYSTEM_ADMIN"], default: "ATHLETE" },
              },
            },
          },
        },
      },
      responses: {
        201: {
          description: "User registered successfully.",
          content: {
            "application/json": {
              schema: {
                type: "object",
                properties: {
                  success: { type: "boolean", example: true },
                  data: {
                    type: "object",
                    properties: {
                      id: { type: "string", format: "uuid", example: "550e8400-e29b-41d4-a716-446655440000" },
                      email: { type: "string", example: "competitor@armsphere.com" },
                      fullName: { type: "string", example: "John Armwrestler" },
                      username: { type: "string", example: "john_puller" },
                      role: { type: "string", example: "ATHLETE" },
                    },
                  },
                },
              },
            },
          },
        },
        400: {
          description: "Invalid request payload or validation failed.",
          content: { "application/problem+json": { schema: rfc7807ErrorSchema } },
        },
      },
    },
  },
  "/api/v1/auth/login": {
    post: {
      tags: ["Authentication"],
      summary: "Authenticate a user",
      description: "Validates credentials, checks for impossible travel/device changes, and prompts MFA if enabled.",
      requestBody: {
        required: true,
        content: {
          "application/json": {
            schema: {
              type: "object",
              required: ["email", "password"],
              properties: {
                email: { type: "string", format: "email", example: "competitor@armsphere.com" },
                password: { type: "string", example: "SecretP@ss123" },
                rememberDevice: { type: "boolean", default: false },
              },
            },
          },
        },
      },
      responses: {
        200: {
          description: "Successful authentication or MFA requirement response.",
          content: {
            "application/json": {
              schema: {
                type: "object",
                properties: {
                  success: { type: "boolean", example: true },
                  data: {
                    type: "object",
                    properties: {
                      mfaRequired: { type: "boolean", example: false },
                      userId: { type: "string", format: "uuid", example: "550e8400-e29b-41d4-a716-446655440000" },
                      accessToken: { type: "string", example: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..." },
                      refreshToken: { type: "string", example: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..." },
                      deviceTrustToken: { type: "string", nullable: true, example: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..." },
                    },
                  },
                },
              },
            },
          },
        },
        401: {
          description: "Invalid credentials or locked account.",
          content: { "application/problem+json": { schema: rfc7807ErrorSchema } },
        },
      },
    },
  },
  "/api/v1/auth/mfa/setup": {
    post: {
      tags: ["Authentication", "Multi-Factor Authentication"],
      summary: "Initiate MFA Setup",
      description: "Generates a dynamic TOTP secret, a setup QR code, and backup recovery codes.",
      security: [{ BearerAuth: [] }],
      responses: {
        200: {
          description: "MFA setup initialized successfully.",
          content: {
            "application/json": {
              schema: {
                type: "object",
                properties: {
                  success: { type: "boolean", example: true },
                  data: {
                    type: "object",
                    properties: {
                      secret: { type: "string", example: "NBSWY3DPEB3W64TBNQ" },
                      qrCode: { type: "string", example: "data:image/png;base64,iVBORw0KGgo..." },
                      recoveryCodes: {
                        type: "array",
                        items: { type: "string" },
                        example: ["A1B2-C3D4", "E5F6-G7H8"],
                      },
                    },
                  },
                },
              },
            },
          },
        },
        401: {
          description: "Unauthorized access.",
          content: { "application/problem+json": { schema: rfc7807ErrorSchema } },
        },
      },
    },
  },
  "/api/v1/auth/mfa/verify": {
    post: {
      tags: ["Authentication", "Multi-Factor Authentication"],
      summary: "Verify and enable MFA or solve login challenge",
      description: "Validates a TOTP token code to activate MFA, or complete login flow when unauthenticated.",
      requestBody: {
        required: true,
        content: {
          "application/json": {
            schema: {
              type: "object",
              required: ["code"],
              properties: {
                code: { type: "string", example: "123456" },
                userId: { type: "string", format: "uuid", example: "550e8400-e29b-41d4-a716-446655440000" },
                rememberDevice: { type: "boolean", default: false },
              },
            },
          },
        },
      },
      responses: {
        200: {
          description: "MFA code verified successfully.",
          content: {
            "application/json": {
              schema: {
                type: "object",
                properties: {
                  success: { type: "boolean", example: true },
                  data: {
                    type: "object",
                    properties: {
                      message: { type: "string", example: "Multi-Factor Authentication enabled successfully." },
                      accessToken: { type: "string", example: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..." },
                      refreshToken: { type: "string", example: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..." },
                    },
                  },
                },
              },
            },
          },
        },
        400: {
          description: "Invalid setup or code input.",
          content: { "application/problem+json": { schema: rfc7807ErrorSchema } },
        },
      },
    },
  },
  "/api/v1/auth/mfa/recovery": {
    post: {
      tags: ["Authentication", "Multi-Factor Authentication"],
      summary: "Recover account access via backup recovery code",
      description: "Allows a locked out user with active MFA to log in using one of their unused backup recovery codes.",
      requestBody: {
        required: true,
        content: {
          "application/json": {
            schema: {
              type: "object",
              required: ["email", "recoveryCode"],
              properties: {
                email: { type: "string", format: "email", example: "competitor@armsphere.com" },
                recoveryCode: { type: "string", example: "A1B2-C3D4" },
              },
            },
          },
        },
      },
      responses: {
        200: {
          description: "Account recovered successfully.",
          content: {
            "application/json": {
              schema: {
                type: "object",
                properties: {
                  success: { type: "boolean", example: true },
                  data: {
                    type: "object",
                    properties: {
                      message: { type: "string", example: "Account recovered successfully." },
                      user: { type: "object" },
                      accessToken: { type: "string", example: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..." },
                      refreshToken: { type: "string", example: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..." },
                    },
                  },
                },
              },
            },
          },
        },
        400: {
          description: "Invalid or already used backup code.",
          content: { "application/problem+json": { schema: rfc7807ErrorSchema } },
        },
      },
    },
  },
  "/api/v1/auth/google": {
    get: {
      tags: ["Authentication", "Social Auth"],
      summary: "Google OAuth login initiator",
      description: "Redirects the client to Google OAuth Consent Page.",
      parameters: [
        { name: "platform", in: "query", required: false, schema: { type: "string", default: "web" } },
        { name: "redirect", in: "query", required: false, schema: { type: "boolean", default: false } },
      ],
      responses: {
        200: {
          description: "OAuth initialization URL.",
          content: {
            "application/json": {
              schema: {
                type: "object",
                properties: {
                  success: { type: "boolean", example: true },
                  data: {
                    type: "object",
                    properties: { url: { type: "string", format: "uri", example: "https://accounts.google.com/o/oauth2/v2/auth..." } },
                  },
                },
              },
            },
          },
        },
      },
    },
  },
  "/api/v1/auth/apple": {
    get: {
      tags: ["Authentication", "Social Auth"],
      summary: "Apple OAuth login initiator",
      description: "Redirects the client to Apple Sign-In screen.",
      parameters: [
        { name: "platform", in: "query", required: false, schema: { type: "string", default: "web" } },
        { name: "redirect", in: "query", required: false, schema: { type: "boolean", default: false } },
      ],
      responses: {
        200: {
          description: "OAuth initialization URL.",
          content: {
            "application/json": {
              schema: {
                type: "object",
                properties: {
                  success: { type: "boolean", example: true },
                  data: {
                    type: "object",
                    properties: { url: { type: "string", format: "uri", example: "https://appleid.apple.com/auth/authorize..." } },
                  },
                },
              },
            },
          },
        },
      },
    },
  },
};
