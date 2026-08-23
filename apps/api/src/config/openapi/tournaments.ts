import { rfc7807ErrorSchema } from "./common.js";

export const tournamentPaths = {
  "/api/v1/tournaments/events": {
    post: {
      tags: ["Tournaments & Brackets"],
      summary: "Create tournament event",
      description: "Registers a new tournament event. Requires Director/Admin.",
      security: [{ BearerAuth: [] }],
      requestBody: {
        required: true,
        content: {
          "application/json": {
            schema: {
              type: "object",
              required: ["title", "startDate", "location"],
              properties: {
                title: { type: "string", example: "Pacific Regional Armwrestling Open" },
                startDate: { type: "string", format: "date-time", example: "2026-08-15T09:00:00Z" },
                location: { type: "string", example: "Richmond Olympic Oval, BC" },
                ruleset: { type: "string", example: "WAF Standard" },
              },
            },
          },
        },
      },
      responses: {
        201: {
          description: "Event created successfully.",
          content: { "application/json": { schema: { type: "object", properties: { success: { type: "boolean", example: true }, data: { type: "object" } } } } },
        },
      },
    },
  },
  "/api/v1/tournaments/registrations": {
    post: {
      tags: ["Tournaments & Brackets"],
      summary: "Register athlete for a tournament event",
      description: "Registers an athlete for a tournament event division.",
      security: [{ BearerAuth: [] }],
      requestBody: {
        required: true,
        content: {
          "application/json": {
            schema: {
              type: "object",
              required: ["eventId", "athleteId", "divisionLabel"],
              properties: {
                eventId: { type: "string", format: "uuid", example: "e10e8400-e29b-41d4-a716-446655440001" },
                athleteId: { type: "string", format: "uuid", example: "550e8400-e29b-41d4-a716-446655440000" },
                divisionLabel: { type: "string", example: "95kg Pro Right Arm" },
              },
            },
          },
        },
      },
      responses: {
        201: {
          description: "Athlete registered for division.",
          content: { "application/json": { schema: { type: "object", properties: { success: { type: "boolean", example: true } } } } },
        },
      },
    },
  },
  "/api/v1/tournaments/weighins": {
    post: {
      tags: ["Tournaments & Brackets", "Weigh-In System"],
      summary: "Record athlete certified weigh-in",
      description: "Saves verified weight measurements during check-in window. Requires Referee/Director/Admin.",
      security: [{ BearerAuth: [] }],
      requestBody: {
        required: true,
        content: {
          "application/json": {
            schema: {
              type: "object",
              required: ["registrationId", "measuredWeightKg"],
              properties: {
                registrationId: { type: "string", format: "uuid", example: "r10e8400-e29b-41d4-a716-446655440002" },
                measuredWeightKg: { type: "number", example: 93.8 },
                notes: { type: "string", example: "Passed within 95kg limit." },
              },
            },
          },
        },
      },
      responses: {
        200: {
          description: "Weigh-in recorded.",
          content: { "application/json": { schema: { type: "object", properties: { success: { type: "boolean", example: true } } } } },
        },
      },
    },
  },
  "/api/v1/tournaments/brackets": {
    post: {
      tags: ["Tournaments & Brackets"],
      summary: "Create double-elimination bracket structure",
      description: "Sets up brackets for an active division.",
      security: [{ BearerAuth: [] }],
      requestBody: {
        required: true,
        content: {
          "application/json": {
            schema: {
              type: "object",
              required: ["eventId", "divisionLabel", "bracketType"],
              properties: {
                eventId: { type: "string", format: "uuid" },
                divisionLabel: { type: "string" },
                bracketType: { type: "string", enum: ["DOUBLE_ELIMINATION", "SINGLE_ELIMINATION", "ROUND_ROBIN"], default: "DOUBLE_ELIMINATION" },
              },
            },
          },
        },
      },
      responses: {
        201: {
          description: "Bracket initialized.",
          content: { "application/json": { schema: { type: "object", properties: { success: { type: "boolean", example: true } } } } },
        },
      },
    },
  },
  "/api/v1/tournaments/matches/result": {
    post: {
      tags: ["Tournaments & Brackets"],
      summary: "Submit bracket match round result",
      description: "Submits referee-signed live match results. Requires Referee/Director/Admin.",
      security: [{ BearerAuth: [] }],
      requestBody: {
        required: true,
        content: {
          "application/json": {
            schema: {
              type: "object",
              required: ["bracketMatchId", "winnerId"],
              properties: {
                bracketMatchId: { type: "string", format: "uuid" },
                winnerId: { type: "string", format: "uuid" },
                notes: { type: "string" },
              },
            },
          },
        },
      },
      responses: {
        200: {
          description: "Result updated successfully.",
          content: { "application/json": { schema: { type: "object", properties: { success: { type: "boolean", example: true } } } } },
        },
      },
    },
  },
};
