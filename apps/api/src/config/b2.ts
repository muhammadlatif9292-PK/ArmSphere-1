import { S3Client } from "@aws-sdk/client-s3";
import env from "./env.js";

let clientInstance: S3Client | null = null;

export function getB2Client(): S3Client {
  if (env.NODE_ENV === "production" && env.STORAGE_PROVIDER === "b2") {
    if (
      !env.B2_ACCESS_KEY_ID ||
      env.B2_ACCESS_KEY_ID === "mock-access-key" ||
      !env.B2_SECRET_ACCESS_KEY ||
      env.B2_SECRET_ACCESS_KEY === "mock-secret-key"
    ) {
      throw new Error(
        "Production configuration error: Valid non-mock B2_ACCESS_KEY_ID and B2_SECRET_ACCESS_KEY must be configured when STORAGE_PROVIDER is b2."
      );
    }
  }

  if (!clientInstance) {
    clientInstance = new S3Client({
      endpoint: env.B2_ENDPOINT ? (env.B2_ENDPOINT.startsWith("http") ? env.B2_ENDPOINT : `https://${env.B2_ENDPOINT}`) : "https://s3.us-west-004.backblazeb2.com",
      region: env.B2_REGION || "us-west-004",
      credentials: {
        accessKeyId: env.B2_ACCESS_KEY_ID || "mock-access-key",
        secretAccessKey: env.B2_SECRET_ACCESS_KEY || "mock-secret-key",
      },
      forcePathStyle: true,
    });
  }

  return clientInstance;
}

export const b2Client = new Proxy({} as S3Client, {
  get(_target, prop) {
    const client = getB2Client();
    const value = (client as any)[prop];
    if (typeof value === "function") {
      return value.bind(client);
    }
    return value;
  },
});


