import { describe, it, expect } from "vitest";
import {
  isProductionDatabase,
  isIsolatedStagingDatabase,
  assertIsolatedStagingDatabase,
  SafetyGuardError,
} from "../config/databaseGuard.js";

describe("Database Safety Guard (Production Isolation Invariant)", () => {
  const prodHostUrl = "postgresql://user:pass@ep-orange-hat-b5myi34s-pooler.c-7.us-east-2.aws.neon.tech/neondb?sslmode=require";
  const stagingHostUrl = "postgresql://user:pass@ep-staging-hat-98765432-pooler.c-7.us-east-2.aws.neon.tech/neondb?sslmode=require";
  const localUrl = "postgresql://postgres:postgres@localhost:5432/armsphere_staging";

  describe("isProductionDatabase", () => {
    it("identifies NEON_BRANCH=main as production", () => {
      expect(isProductionDatabase(stagingHostUrl, "main", "staging")).toBe(true);
    });

    it("identifies NEON_BRANCH=production as production", () => {
      expect(isProductionDatabase(stagingHostUrl, "production", "development")).toBe(true);
    });

    it("identifies production Neon cluster endpoint as production regardless of branch", () => {
      expect(isProductionDatabase(prodHostUrl, "staging", "staging")).toBe(true);
    });

    it("identifies NODE_ENV=production as production", () => {
      expect(isProductionDatabase(stagingHostUrl, "staging", "production")).toBe(true);
    });

    it("returns false for legitimate staging branch and endpoint", () => {
      expect(isProductionDatabase(stagingHostUrl, "staging", "staging")).toBe(false);
    });

    it("returns false for local staging database", () => {
      expect(isProductionDatabase(localUrl, "local", "development")).toBe(false);
    });
  });

  describe("isIsolatedStagingDatabase", () => {
    it("confirms NEON_BRANCH=staging with staging endpoint as isolated", () => {
      expect(isIsolatedStagingDatabase(stagingHostUrl, "staging")).toBe(true);
    });

    it("confirms local database URL containing staging as isolated", () => {
      expect(isIsolatedStagingDatabase(localUrl, "development")).toBe(true);
    });

    it("rejects production database even if branch says staging", () => {
      expect(isIsolatedStagingDatabase(prodHostUrl, "staging")).toBe(false);
    });

    it("rejects NEON_BRANCH=main even if URL has staging substring", () => {
      expect(isIsolatedStagingDatabase("postgresql://user:pass@host/armsphere_staging", "main")).toBe(false);
    });
  });

  describe("assertIsolatedStagingDatabase (Hard Invariant)", () => {
    it("throws SafetyGuardError when target is the production Neon cluster", () => {
      expect(() => {
        assertIsolatedStagingDatabase("E2E Test Run", {
          url: prodHostUrl,
          neonBranch: "staging",
          nodeEnv: "staging",
        });
      }).toThrowError(SafetyGuardError);
    });

    it("throws SafetyGuardError when NEON_BRANCH=main", () => {
      expect(() => {
        assertIsolatedStagingDatabase("Seed Staging Fixtures", {
          url: stagingHostUrl,
          neonBranch: "main",
          nodeEnv: "staging",
        });
      }).toThrowError(SafetyGuardError);
    });

    it("throws SafetyGuardError when NODE_ENV=production", () => {
      expect(() => {
        assertIsolatedStagingDatabase("Reset Staging Database", {
          url: stagingHostUrl,
          neonBranch: "staging",
          nodeEnv: "production",
        });
      }).toThrowError(SafetyGuardError);
    });

    it("passes cleanly when both endpoint and branch are isolated staging", () => {
      expect(() => {
        assertIsolatedStagingDatabase("Seed Staging Fixtures", {
          url: stagingHostUrl,
          neonBranch: "staging",
          nodeEnv: "staging",
        });
      }).not.toThrow();
    });

    it("passes cleanly for local database with staging in URL", () => {
      expect(() => {
        assertIsolatedStagingDatabase("Local Migration Test", {
          url: localUrl,
          neonBranch: "local",
          nodeEnv: "test",
        });
      }).not.toThrow();
    });
  });
});
