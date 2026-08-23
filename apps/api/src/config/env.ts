import dotenv from "dotenv";
import { z } from "zod";

// Load environment variables from .env if present
dotenv.config();

const isProduction = process.env.NODE_ENV === "production";
const isTest = !!(process.env.VITEST || process.env.NODE_ENV === "test");

if (isTest && !process.env.CRON_SECRET) {
  process.env.CRON_SECRET = "test_cron_secret_key_1234567890_armsphere";
}

if (!isProduction) {
  if (!process.env.JWT_ACCESS_SECRET) {
    process.env.JWT_ACCESS_SECRET = "super_secret_armsphere_access_jwt_key_with_length_greater_than_32";
  }
  if (!process.env.JWT_REFRESH_SECRET) {
    process.env.JWT_REFRESH_SECRET = "super_secret_armsphere_refresh_jwt_key_with_length_greater_than_32";
  }
  if (!process.env.CRON_SECRET) {
    process.env.CRON_SECRET = "dev_cron_secret_armsphere_local_1234567890";
  }
}

const PLACEHOLDER_SECRET_PATTERNS = [
  "default_fallback_",
  "placeholder",
  "mock-",
  "changeme",
  "armsphere_password",
  "replace_me",
  "your_secret",
];

function hasUnsafeSecret(value?: string) {
  if (!value) return true;
  const normalized = value.toLowerCase();
  return PLACEHOLDER_SECRET_PATTERNS.some((pattern) => normalized.includes(pattern));
}

export const envSchema = z.object({
  NODE_ENV: z.enum(["development", "production", "test"]).default("development"),
  IS_SERVERLESS: z.preprocess(
    (val) => val === "true" || val === true,
    z.boolean()
  ).default(false),
  PORT: z.preprocess((val) => {
    if (val === undefined || val === null || val === "") return 3000;
    const parsed = Number(val);
    return Number.isFinite(parsed) ? parsed : 3000;
  }, z.number().int().min(1).max(65535)).default(3000),
  DATABASE_URL: z.preprocess(
    (val) => (typeof val === "string" && val.trim().length > 0 ? val : undefined),
    z.string().optional()
  ),
  JWT_ACCESS_SECRET: z.preprocess(
    (val) => (typeof val === "string" && val.trim().length >= 32 ? val : undefined),
    z.string().min(32)
  ),
  JWT_REFRESH_SECRET: z.preprocess(
    (val) => (typeof val === "string" && val.trim().length >= 32 ? val : undefined),
    z.string().min(32)
  ),
  JWT_ACCESS_EXPIRES_IN: z.string().default("15m"),
  JWT_REFRESH_EXPIRES_IN: z.string().default("30d"),
  STORAGE_PROVIDER: z.preprocess(
    (val) => (val === "minio" || val === "gcs" || val === "b2" ? val : "b2"),
    z.enum(["minio", "gcs", "b2"]).default("b2")
  ),
  B2_ENDPOINT: z.string().default("s3.us-west-004.backblazeb2.com"),
  B2_REGION: z.string().default("us-west-004"),
  B2_ACCESS_KEY_ID: z.string().default(""),
  B2_SECRET_ACCESS_KEY: z.string().default(""),
  B2_BUCKET_COMPLIANCE_DOCS: z.string().default("compliance-docs"),
  B2_BUCKET_ATHLETE_AVATARS: z.string().default("athlete-avatars"),
  GCP_PROJECT_ID: z.string().optional().default(""),
  CORS_ORIGIN: z.string().default("http://localhost:3000"),
  GOOGLE_CLIENT_ID: z.string().optional().default(""),
  GOOGLE_CLIENT_SECRET: z.string().optional().default(""),
  APPLE_CLIENT_ID: z.string().optional().default(""),
  APPLE_CLIENT_SECRET: z.string().optional().default(""),
  CAPTCHA_SECRET_KEY: z.string().optional().default(""),
  FIREBASE_PROJECT_ID: z.string().optional().default(""),
  FIREBASE_CLIENT_EMAIL: z.string().optional().default(""),
  FIREBASE_PRIVATE_KEY: z.string().optional().default(""),
  APNS_KEY_ID: z.string().optional().default(""),
  APNS_TEAM_ID: z.string().optional().default(""),
  APNS_BUNDLE_ID: z.string().optional().default(""),
  APNS_PRIVATE_KEY: z.string().optional().default(""),
  APNS_SANDBOX: z.string().optional().default("true"),
  CRON_SECRET: z.string().min(1, "CRON_SECRET environment variable is required and cannot be empty"),
  STRIPE_SECRET_KEY: z.string().optional().default(""),
  STRIPE_WEBHOOK_SECRET: z.string().optional().default("")
}).superRefine((data, ctx) => {
  if (data.NODE_ENV === "production") {
    const isTesting = typeof process !== "undefined" && (process.env.VITEST || process.env.NODE_ENV === "test");

    if (!data.DATABASE_URL) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        path: ["DATABASE_URL"],
        message: "Production environment does not have DATABASE_URL explicitly set.",
      });
    } else {
      const lower = data.DATABASE_URL.toLowerCase();
      if (lower.includes("localhost") || lower.includes("127.0.0.1")) {
        ctx.addIssue({
          code: z.ZodIssueCode.custom,
          path: ["DATABASE_URL"],
          message: "Production DATABASE_URL cannot use localhost.",
        });
      } else if (lower.includes("@postgres:") || lower.includes("@postgres/")) {
        ctx.addIssue({
          code: z.ZodIssueCode.custom,
          path: ["DATABASE_URL"],
          message: "Production DATABASE_URL cannot use localhost or internal container hostnames.",
        });
      }
    }

    if (hasUnsafeSecret(data.CRON_SECRET)) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        path: ["CRON_SECRET"],
        message: "Production CRON_SECRET must be a real secret and cannot use placeholder fallback values.",
      });
    }

    if (hasUnsafeSecret(data.JWT_ACCESS_SECRET) || hasUnsafeSecret(data.JWT_REFRESH_SECRET)) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        path: ["JWT_ACCESS_SECRET"],
        message: "Production JWT secrets must not use placeholder or default fallback values.",
      });
    }
  }
});

const parsed = envSchema.safeParse(process.env);

let resolvedEnv: z.infer<typeof envSchema>;

if (!parsed.success) {
  if (isProduction) {
    console.error("❌ Invalid environment variables configuration:");
    console.error(JSON.stringify(parsed.error.format(), null, 2));
    process.exit(1);
  }

  console.warn("⚠️ Non-production environment has incomplete env config; applying local defaults.");
  const fallback = envSchema.safeParse({
    ...process.env,
    JWT_ACCESS_SECRET: process.env.JWT_ACCESS_SECRET || "super_secret_armsphere_access_jwt_key_with_length_greater_than_32",
    JWT_REFRESH_SECRET: process.env.JWT_REFRESH_SECRET || "super_secret_armsphere_refresh_jwt_key_with_length_greater_than_32",
    CRON_SECRET: process.env.CRON_SECRET || "dev_cron_secret_armsphere_local_1234567890",
  });

  if (!fallback.success) {
    console.error("❌ Failed to recover local environment defaults:");
    console.error(JSON.stringify(fallback.error.format(), null, 2));
    process.exit(1);
  }

  resolvedEnv = fallback.data;
} else {
  resolvedEnv = parsed.data;
}

export const env = resolvedEnv;
export default env;
