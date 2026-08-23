import { rfc7807ErrorSchema } from "./common.js";

export const communityPaths = {
  "/community/posts": {
    post: {
      tags: ["Community & Media"],
      summary: "Create community post",
      description: "Submit a new community feed post linked with previously uploaded media key.",
      security: [{ BearerAuth: [] }],
      requestBody: {
        required: true,
        content: {
          "application/json": {
            schema: {
              type: "object",
              required: ["mediaType", "fileKey", "bucketName"],
              properties: {
                mediaType: { type: "string", enum: ["VIDEO", "PHOTO"], example: "VIDEO" },
                fileKey: { type: "string", example: "community_videos/d096a782-b7d6-4bc2-8f15-3add561e54f4.mp4" },
                bucketName: { type: "string", example: "community-media" },
                caption: { type: "string", example: "Working on bicep curl strength!" },
              },
            },
          },
        },
      },
      responses: {
        201: {
          description: "Community post created successfully.",
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
        400: { description: "Active athlete profile required or invalid payload.", content: { "application/problem+json": { schema: rfc7807ErrorSchema } } },
      },
    },
  },
};
