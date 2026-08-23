import { rfc7807ErrorSchema } from "./common.js";

export const rankingPaths = {
  "/api/v1/rankings/leaderboard": {
    get: {
      tags: ["ELO Rankings"],
      summary: "Get global ELO rankings leaderboard",
      description: "Retrieves top rated pullers filtered by weight class, division, gender, region, or club.",
      security: [{ BearerAuth: [] }],
      parameters: [
        { name: "weightClass", in: "query", required: false, schema: { type: "string" }, description: "Filter by class (e.g. '75kg', '90kg', '95kg+')" },
        { name: "gender", in: "query", required: false, schema: { type: "string", enum: ["MALE", "FEMALE"] } },
        { name: "region", in: "query", required: false, schema: { type: "string" }, description: "Filter by province/region." },
        { name: "hand", in: "query", required: false, schema: { type: "string", enum: ["LEFT", "RIGHT"] }, description: "Which arm to display ELO rankings for." },
        { name: "limit", in: "query", required: false, schema: { type: "integer", default: 50 } },
      ],
      responses: {
        200: {
          description: "Global leaderboard retrieved successfully.",
          content: {
            "application/json": {
              schema: {
                type: "object",
                properties: {
                  success: { type: "boolean", example: true },
                  data: {
                    type: "array",
                    items: {
                      type: "object",
                      properties: {
                        rank: { type: "integer", example: 1 },
                        athleteId: { type: "string", format: "uuid" },
                        fullName: { type: "string", example: "Devon Larratt" },
                        eloRatingLeft: { type: "number", example: 1820 },
                        eloRatingRight: { type: "number", example: 2150 },
                        clubName: { type: "string", example: "Ottawa Armwrestling" },
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
  },
  "/api/v1/rankings/snapshots": {
    post: {
      tags: ["ELO Rankings"],
      summary: "Trigger dynamic ELO snapshots",
      description: "Triggers a full system-wide snapshot of current ratings. Requires National Director or System Admin privileges.",
      security: [{ BearerAuth: [] }],
      requestBody: {
        required: false,
        content: {
          "application/json": {
            schema: {
              type: "object",
              properties: {
                label: { type: "string", example: "National Championship Post-Event ELO" },
              },
            },
          },
        },
      },
      responses: {
        202: {
          description: "Snapshot job successfully queued.",
          content: {
            "application/json": {
              schema: {
                type: "object",
                properties: {
                  success: { type: "boolean", example: true },
                  message: { type: "string", example: "ELO ranking snapshot process successfully queued." },
                },
              },
            },
          },
        },
        403: { description: "Insufficient permissions.", content: { "application/problem+json": { schema: rfc7807ErrorSchema } } },
      },
    },
  },
};
