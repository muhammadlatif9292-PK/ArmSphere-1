import { rfc7807ErrorSchema } from "./common.js";

export const athletePaths = {
  "/api/v1/athletes": {
    post: {
      tags: ["Athletes"],
      summary: "Create athlete profile",
      description: "Creates an athlete profile linking weight classes, bio details, and club associations.",
      security: [{ BearerAuth: [] }],
      requestBody: {
        required: true,
        content: {
          "application/json": {
            schema: {
              type: "object",
              required: ["firstName", "lastName", "dateOfBirth", "gender"],
              properties: {
                firstName: { type: "string", example: "John" },
                lastName: { type: "string", example: "Armwrestler" },
                dateOfBirth: { type: "string", format: "date", example: "1990-05-15" },
                gender: { type: "string", enum: ["MALE", "FEMALE"], example: "MALE" },
                clubId: { type: "string", format: "uuid", example: "770e8400-e29b-41d4-a716-446655440001" },
                gripStyle: { type: "string", example: "Hook" },
                pullingHand: { type: "string", enum: ["LEFT", "RIGHT", "BOTH"], example: "BOTH" },
              },
            },
          },
        },
      },
      responses: {
        201: {
          description: "Athlete profile created successfully.",
          content: {
            "application/json": {
              schema: {
                type: "object",
                properties: {
                  success: { type: "boolean", example: true },
                  data: { type: "object" },
                },
              },
            },
          },
        },
        400: { description: "Validation error.", content: { "application/problem+json": { schema: rfc7807ErrorSchema } } },
      },
    },
  },
  "/api/v1/athletes/me": {
    get: {
      tags: ["Athletes"],
      summary: "Retrieve logged-in athlete details",
      description: "Gets the full authenticated user details and active athlete profile context.",
      security: [{ BearerAuth: [] }],
      responses: {
        200: {
          description: "Athlete profile retrieved successfully.",
          content: {
            "application/json": {
              schema: {
                type: "object",
                properties: {
                  success: { type: "boolean", example: true },
                  data: { type: "object" },
                },
              },
            },
          },
        },
      },
    },
  },
  "/api/v1/athletes/search": {
    get: {
      tags: ["Athletes"],
      summary: "Search athletes directory",
      description: "Filter athletes by name, weight range, club, and verification status.",
      security: [{ BearerAuth: [] }],
      parameters: [
        { name: "q", in: "query", required: false, schema: { type: "string" }, description: "Full name search string." },
        { name: "weightClass", in: "query", required: false, schema: { type: "string" }, description: "Weight class filter." },
        { name: "verified", in: "query", required: false, schema: { type: "boolean" }, description: "Filter by verification status." },
      ],
      responses: {
        200: {
          description: "Athletes search results.",
          content: {
            "application/json": {
              schema: {
                type: "object",
                properties: {
                  success: { type: "boolean", example: true },
                  data: { type: "array", items: { type: "object" } },
                },
              },
            },
          },
        },
      },
    },
  },
  "/api/v1/athletes/clubs": {
    get: {
      tags: ["Athletes", "Clubs"],
      summary: "Get registered armwrestling clubs",
      description: "Retrieves a listing of official clubs for team associations.",
      security: [{ BearerAuth: [] }],
      responses: {
        200: {
          description: "Club lists.",
          content: {
            "application/json": {
              schema: {
                type: "object",
                properties: {
                  success: { type: "boolean", example: true },
                  data: { type: "array", items: { type: "object" } },
                },
              },
            },
          },
        },
      },
    },
    post: {
      tags: ["Athletes", "Clubs"],
      summary: "Register a new official Club",
      description: "Creates a new club node. Requires Director-level credentials.",
      security: [{ BearerAuth: [] }],
      requestBody: {
        required: true,
        content: {
          "application/json": {
            schema: {
              type: "object",
              required: ["name", "region"],
              properties: {
                name: { type: "string", example: "Pacific Pullers Club" },
                region: { type: "string", example: "British Columbia" },
                city: { type: "string", example: "Vancouver" },
              },
            },
          },
        },
      },
      responses: {
        201: {
          description: "Club created successfully.",
          content: {
            "application/json": {
              schema: {
                type: "object",
                properties: {
                  success: { type: "boolean", example: true },
                  data: { type: "object" },
                },
              },
            },
          },
        },
        403: { description: "Insufficient permissions.", content: { "application/problem+json": { schema: rfc7807ErrorSchema } } },
      },
    },
  },
  "/api/v1/athletes/biometrics": {
    post: {
      tags: ["Athletes"],
      summary: "Update biometrics records",
      description: "Submits current certified biometric statistics (height, wingspan, bicep size, forearm size).",
      security: [{ BearerAuth: [] }],
      requestBody: {
        required: true,
        content: {
          "application/json": {
            schema: {
              type: "object",
              properties: {
                heightCm: { type: "number", example: 185.5 },
                wingspanCm: { type: "number", example: 191.0 },
                bicepCircumferenceCm: { type: "number", example: 42.0 },
                forearmCircumferenceCm: { type: "number", example: 38.5 },
              },
            },
          },
        },
      },
      responses: {
        200: {
          description: "Biometrics updated.",
          content: { "application/json": { schema: { type: "object", properties: { success: { type: "boolean", example: true } } } } },
        },
      },
    },
  },
  "/api/v1/athletes/verification/document": {
    post: {
      tags: ["Athletes", "Identity Verification"],
      summary: "Submit ID document for profile verification",
      description: "Submits government photo ID or provincial membership card for referee validation.",
      security: [{ BearerAuth: [] }],
      requestBody: {
        required: true,
        content: {
          "application/json": {
            schema: {
              type: "object",
              required: ["documentType", "documentUrl"],
              properties: {
                documentType: { type: "string", enum: ["PASSPORT", "DRIVERS_LICENSE", "PROVINCIAL_CARD"], example: "DRIVERS_LICENSE" },
                documentUrl: { type: "string", format: "uri", example: "https://armsphere-bucket.s3.amazonaws.com/uploads/doc.jpg" },
              },
            },
          },
        },
      },
      responses: {
        200: {
          description: "Verification request registered.",
          content: { "application/json": { schema: { type: "object", properties: { success: { type: "boolean", example: true } } } } },
        },
      },
    },
  },
  "/api/v1/athletes/verification/review": {
    post: {
      tags: ["Athletes", "Identity Verification"],
      summary: "Review profile verification document",
      description: "Approves or rejects a submitted profile document. Requires Admin or Director privileges.",
      security: [{ BearerAuth: [] }],
      requestBody: {
        required: true,
        content: {
          "application/json": {
            schema: {
              type: "object",
              required: ["athleteId", "approved"],
              properties: {
                athleteId: { type: "string", format: "uuid", example: "550e8400-e29b-41d4-a716-446655440000" },
                approved: { type: "boolean", example: true },
                rejectionReason: { type: "string", example: "Document image is too blurry." },
              },
            },
          },
        },
      },
      responses: {
        200: {
          description: "Document review recorded.",
          content: { "application/json": { schema: { type: "object", properties: { success: { type: "boolean", example: true } } } } },
        },
      },
    },
  },
};
