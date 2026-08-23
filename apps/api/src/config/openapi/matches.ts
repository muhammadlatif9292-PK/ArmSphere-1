import { rfc7807ErrorSchema } from "./common.js";

export const matchPaths = {
  "/api/v1/matches": {
    post: {
      tags: ["Matches"],
      summary: "Submit a new match result",
      description: "Records an official match result between two athletes (pullers), specifying winner, match type, round details, and referee signatures.",
      security: [{ BearerAuth: [] }],
      requestBody: {
        required: true,
        content: {
          "application/json": {
            schema: {
              type: "object",
              required: ["challengerId", "defenderId", "winnerId", "championshipId"],
              properties: {
                challengerId: { type: "string", format: "uuid", example: "550e8400-e29b-41d4-a716-446655440001" },
                defenderId: { type: "string", format: "uuid", example: "550e8400-e29b-41d4-a716-446655440002" },
                winnerId: { type: "string", format: "uuid", example: "550e8400-e29b-41d4-a716-446655440001" },
                championshipId: { type: "string", format: "uuid", example: "770e8400-e29b-41d4-a716-446655440001" },
                roundWinsChallenger: { type: "integer", minimum: 0, example: 3 },
                roundWinsDefender: { type: "integer", minimum: 0, example: 1 },
                matchType: { type: "string", enum: ["OFFICIAL", "EXHIBITION", "PRACTICE"], default: "OFFICIAL" },
                refereeId: { type: "string", format: "uuid", example: "880e8400-e29b-41d4-a716-446655440003" },
              },
            },
          },
        },
      },
      responses: {
        201: {
          description: "Match submitted successfully.",
          content: {
            "application/json": {
              schema: {
                type: "object",
                properties: {
                  success: { type: "boolean", example: true },
                  data: {
                    type: "object",
                    properties: {
                      id: { type: "string", format: "uuid", example: "990e8400-e29b-41d4-a716-446655440001" },
                      status: { type: "string", example: "PENDING_VERIFICATION" },
                      calculatedEloChange: { type: "number", example: 16.5 },
                    },
                  },
                },
              },
            },
          },
        },
        400: { description: "Validation failure.", content: { "application/problem+json": { schema: rfc7807ErrorSchema } } },
      },
    },
  },
  "/api/v1/matches/{id}": {
    get: {
      tags: ["Matches"],
      summary: "Get match details",
      description: "Gets detailed records of a match, including rounds and ELO updates.",
      security: [{ BearerAuth: [] }],
      parameters: [
        { name: "id", in: "path", required: true, schema: { type: "string", format: "uuid" }, description: "Match ID" },
      ],
      responses: {
        200: {
          description: "Match records.",
          content: { "application/json": { schema: { type: "object", properties: { success: { type: "boolean", example: true }, data: { type: "object" } } } } },
        },
        404: { description: "Match not found.", content: { "application/problem+json": { schema: rfc7807ErrorSchema } } },
      },
    },
  },
  "/api/v1/matches/{id}/verify": {
    post: {
      tags: ["Matches"],
      summary: "Verify match outcome",
      description: "Approved by referee or tournament directors to verify accuracy and cement ELO updates. Requires Referee/Director/Admin.",
      security: [{ BearerAuth: [] }],
      parameters: [
        { name: "id", in: "path", required: true, schema: { type: "string", format: "uuid" }, description: "Match ID" },
      ],
      requestBody: {
        required: true,
        content: {
          "application/json": {
            schema: {
              type: "object",
              properties: {
                notes: { type: "string", example: "No rules violated, verified on site." },
              },
            },
          },
        },
      },
      responses: {
        200: {
          description: "Match verified successfully.",
          content: { "application/json": { schema: { type: "object", properties: { success: { type: "boolean", example: true } } } } },
        },
      },
    },
  },
  "/api/v1/matches/{id}/dispute": {
    post: {
      tags: ["Matches", "Disputes"],
      summary: "Raise a dispute on match results",
      description: "Allows an athlete or club manager to contest a match outcome within the dispute window.",
      security: [{ BearerAuth: [] }],
      parameters: [
        { name: "id", in: "path", required: true, schema: { type: "string", format: "uuid" }, description: "Match ID" },
      ],
      requestBody: {
        required: true,
        content: {
          "application/json": {
            schema: {
              type: "object",
              required: ["reason"],
              properties: {
                reason: { type: "string", example: "Defender claims phantom slip occurred in Round 2." },
                proofUrl: { type: "string", format: "uri", example: "https://youtube.com/watch?v=match" },
              },
            },
          },
        },
      },
      responses: {
        200: {
          description: "Dispute successfully initiated.",
          content: { "application/json": { schema: { type: "object", properties: { success: { type: "boolean", example: true } } } } },
        },
      },
    },
  },
  "/api/v1/matches/{id}/void": {
    post: {
      tags: ["Matches"],
      summary: "Void a match",
      description: "SRE and Director tool to void a match, rolling back ratings securely without breaking history sequences. Requires Director/Admin.",
      security: [{ BearerAuth: [] }],
      parameters: [
        { name: "id", in: "path", required: true, schema: { type: "string", format: "uuid" }, description: "Match ID" },
      ],
      requestBody: {
        required: true,
        content: {
          "application/json": {
            schema: {
              type: "object",
              required: ["voidReason"],
              properties: {
                voidReason: { type: "string", example: "Corrective action due to hardware fault in referee score system." },
              },
            },
          },
        },
      },
      responses: {
        200: {
          description: "Match successfully voided.",
          content: { "application/json": { schema: { type: "object", properties: { success: { type: "boolean", example: true } } } } },
        },
      },
    },
  },
};
