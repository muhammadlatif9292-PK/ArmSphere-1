import { describe, it, expect, beforeEach, afterEach } from "vitest";
import { envSchema } from "../config/env.js";

describe("Environment Configuration Validation", () => {
  const originalEnv = { ...process.env };

  beforeEach(() => {
    process.env = { ...originalEnv };
  });

  afterEach(() => {
    process.env = originalEnv;
  });

  it("accepts production configuration with a valid Neon DATABASE_URL", () => {
    const neonUrl = "postgresql://armsphere_user:pass123@ep-example-123456.us-east-2.aws.neon.tech/neondb?sslmode=require";
    process.env.DATABASE_URL = neonUrl;
    
    const input = {
      NODE_ENV: "production",
      DATABASE_URL: neonUrl,
      CRON_SECRET: "test_cron_secret_key_1234567890_armsphere",
      JWT_ACCESS_SECRET: "super_secret_armsphere_access_jwt_key_with_length_greater_than_32",
      JWT_REFRESH_SECRET: "super_secret_armsphere_refresh_jwt_key_with_length_greater_than_32",
    };

    const result = envSchema.safeParse(input);
    expect(result.success).toBe(true);
  });

  it("respects an explicit PORT override from the runtime environment", () => {
    const neonUrl = "postgresql://armsphere_user:pass123@ep-example-123456.us-east-2.aws.neon.tech/neondb?sslmode=require";
    const input = {
      NODE_ENV: "production",
      PORT: 3001,
      DATABASE_URL: neonUrl,
      CRON_SECRET: "test_cron_secret_key_1234567890_armsphere",
      JWT_ACCESS_SECRET: "super_secret_armsphere_access_jwt_key_with_length_greater_than_32",
      JWT_REFRESH_SECRET: "super_secret_armsphere_refresh_jwt_key_with_length_greater_than_32",
    };

    const result = envSchema.safeParse(input);
    expect(result.success).toBe(true);
    if (result.success) {
      expect(result.data.PORT).toBe(3001);
    }
  });

  it("rejects production configuration when secrets rely on placeholder fallbacks", () => {
    const neonUrl = "postgresql://armsphere_user:pass123@ep-example-123456.us-east-2.aws.neon.tech/neondb?sslmode=require";

    const input = {
      NODE_ENV: "production",
      DATABASE_URL: neonUrl,
      CRON_SECRET: "default_fallback_cron_secret_placeholder_keys_for_graceful_startup",
      JWT_ACCESS_SECRET: "super_secret_armsphere_access_jwt_key_with_length_greater_than_32",
      JWT_REFRESH_SECRET: "super_secret_armsphere_refresh_jwt_key_with_length_greater_than_32",
    };

    const result = envSchema.safeParse(input);
    expect(result.success).toBe(false);
    if (!result.success) {
      const issue = result.error.issues.find((i) => i.path.includes("CRON_SECRET"));
      expect(issue?.message).toContain("CRON_SECRET");
    }
  });

  it("rejects production configuration when DATABASE_URL is missing or relies on fallback", () => {
    delete process.env.DATABASE_URL;

    const input = {
      NODE_ENV: "production",
      CRON_SECRET: "test_cron_secret_key_1234567890_armsphere",
      JWT_ACCESS_SECRET: "super_secret_armsphere_access_jwt_key_with_length_greater_than_32",
      JWT_REFRESH_SECRET: "super_secret_armsphere_refresh_jwt_key_with_length_greater_than_32",
    };

    const result = envSchema.safeParse(input);
    expect(result.success).toBe(false);
    if (!result.success) {
      const issue = result.error.issues.find((i) => i.path.includes("DATABASE_URL"));
      expect(issue?.message).toContain("DATABASE_URL");
    }
  });

  it("rejects production configuration pointing to localhost", () => {
    const localhostUrl = "postgresql://armsphere:armsphere_password@localhost:5432/armsphere";
    process.env.DATABASE_URL = localhostUrl;

    const input = {
      NODE_ENV: "production",
      DATABASE_URL: localhostUrl,
      CRON_SECRET: "test_cron_secret_key_1234567890_armsphere",
      JWT_ACCESS_SECRET: "super_secret_armsphere_access_jwt_key_with_length_greater_than_32",
      JWT_REFRESH_SECRET: "super_secret_armsphere_refresh_jwt_key_with_length_greater_than_32",
    };

    const result = envSchema.safeParse(input);
    expect(result.success).toBe(false);
    if (!result.success) {
      const issue = result.error.issues.find((i) => i.path.includes("DATABASE_URL"));
      expect(issue?.message).toContain("cannot use localhost");
    }
  });

  it("rejects production configuration pointing to internal postgres container host", () => {
    const containerUrl = "postgres://postgres:password@postgres:5432/armsphere_production";
    process.env.DATABASE_URL = containerUrl;

    const input = {
      NODE_ENV: "production",
      DATABASE_URL: containerUrl,
      CRON_SECRET: "test_cron_secret_key_1234567890_armsphere",
      JWT_ACCESS_SECRET: "super_secret_armsphere_access_jwt_key_with_length_greater_than_32",
      JWT_REFRESH_SECRET: "super_secret_armsphere_refresh_jwt_key_with_length_greater_than_32",
    };

    const result = envSchema.safeParse(input);
    expect(result.success).toBe(false);
    if (!result.success) {
      const issue = result.error.issues.find((i) => i.path.includes("DATABASE_URL"));
      expect(issue?.message).toContain("cannot use localhost or internal container hostnames");
    }
  });

  it("accepts development configuration with local database host", () => {
    const localUrl = "postgresql://armsphere:armsphere_password@localhost:5432/armsphere";
    process.env.DATABASE_URL = localUrl;

    const input = {
      NODE_ENV: "development",
      DATABASE_URL: localUrl,
      CRON_SECRET: "test_cron_secret_key_1234567890_armsphere",
      JWT_ACCESS_SECRET: "super_secret_armsphere_access_jwt_key_with_length_greater_than_32",
      JWT_REFRESH_SECRET: "super_secret_armsphere_refresh_jwt_key_with_length_greater_than_32",
    };

    const result = envSchema.safeParse(input);
    expect(result.success).toBe(true);
  });
});
