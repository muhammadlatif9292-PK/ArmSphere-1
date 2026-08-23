import { rfc7807ErrorSchema } from "./common.js";

export const syncPaths = {
  "/sync": {
    get: {
      tags: ["Offline Sync Engine"],
      summary: "Differential (pull) sync — fetch changes since a cursor",
      description: "Returns the authenticated athlete's own profile and match history changed since the `since` cursor, plus tombstones for any hard-deleted records they own. Omit `since` for a first full sync. The response's `serverTime` is the cursor to pass as `since` on the next call.",
      security: [{ BearerAuth: [] }],
      parameters: [
        {
          name: "since",
          in: "query",
          required: false,
          schema: { type: "string", format: "date-time" },
          description: "ISO 8601 timestamp cursor from a previous call's serverTime. Omitted or absent means a full sync.",
        },
      ],
      responses: {
        200: {
          description: "Differential sync payload.",
          content: {
            "application/json": {
              schema: {
                type: "object",
                properties: {
                  success: { type: "boolean", example: true },
                  data: {
                    type: "object",
                    properties: {
                      since: { type: "string", format: "date-time" },
                      serverTime: { type: "string", format: "date-time" },
                      profile: { type: "object", nullable: true },
                      matches: { type: "array", items: { type: "object" } },
                      deletions: {
                        type: "array",
                        items: {
                          type: "object",
                          properties: {
                            table: { type: "string" },
                            recordId: { type: "string", format: "uuid" },
                            deletedAt: { type: "string", format: "date-time" },
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
        400: {
          description: "Malformed 'since' cursor.",
          content: { "application/json": { schema: rfc7807ErrorSchema } },
        },
      },
    },
  },
  "/api/v1/sync/queue": {
    post: {
      tags: ["Offline Sync Engine"],
      summary: "Queue action for background synchronization",
      description: "Registers local client database mutations to be processed asynchronously by the PostgreSQL database on the server when connection is re-established.",
      security: [{ BearerAuth: [] }],
      requestBody: {
        required: true,
        content: {
          "application/json": {
            schema: {
              type: "object",
              required: ["actionType", "payload"],
              properties: {
                actionType: { type: "string", enum: ["MATCH_SUBMIT", "WEIGH_IN_RECORD", "BIOMETRICS_UPDATE"], example: "MATCH_SUBMIT" },
                payload: { type: "object", description: "JSON payload corresponding to actionType" },
                clientUuid: { type: "string", format: "uuid", example: "uuid-from-client-db" },
              },
            },
          },
        },
      },
      responses: {
        202: {
          description: "Action accepted and queued.",
          content: {
            "application/json": {
              schema: {
                type: "object",
                properties: {
                  success: { type: "boolean", example: true },
                  jobId: { type: "string", example: "sync-job-103" },
                },
              },
            },
          },
        },
      },
    },
  },
  "/api/v1/sync/history": {
    get: {
      tags: ["Offline Sync Engine"],
      summary: "Get actions synchronization history",
      description: "Gets historic synchronization logs to let clients align local status states.",
      security: [{ BearerAuth: [] }],
      responses: {
        200: {
          description: "Sync history listing.",
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
                        id: { type: "string" },
                        actionType: { type: "string" },
                        status: { type: "string", enum: ["COMPLETED", "FAILED", "PENDING"] },
                        errorDetails: { type: "string", nullable: true },
                        syncedAt: { type: "string", format: "date-time" },
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
  "/api/v1/sync/metrics": {
    get: {
      tags: ["Offline Sync Engine"],
      summary: "Get server sync queue metrics",
      description: "Returns general background queue metrics (pending counts, processed counts, fail ratios).",
      security: [{ BearerAuth: [] }],
      responses: {
        200: {
          description: "Sync metrics report.",
          content: {
            "application/json": {
              schema: {
                type: "object",
                properties: {
                  success: { type: "boolean", example: true },
                  metrics: {
                    type: "object",
                    properties: {
                      active: { type: "integer" },
                      completed: { type: "integer" },
                      failed: { type: "integer" },
                      delayed: { type: "integer" },
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
};
