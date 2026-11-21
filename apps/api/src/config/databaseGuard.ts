import { logger } from "@armsphere/core";

export class SafetyGuardError extends Error {
  public readonly code = "PRODUCTION_DATABASE_MUTATION_BLOCKED";
  constructor(message: string) {
    super(message);
    this.name = "SafetyGuardError";
  }
}

/**
 * Known signatures and host patterns that identify the ArmSphere production database.
 */
const PRODUCTION_HOST_PATTERNS = [
  "ep-orange-hat-b5myi34s", // Neon production cluster endpoint
  "prod.",
  "production.",
];

/**
 * Returns true if the database configuration indicates a production environment.
 */
export function isProductionDatabase(
  url?: string,
  neonBranch?: string,
  nodeEnv?: string
): boolean {
  const resolvedUrl = (url || process.env.DATABASE_URL || "").toLowerCase();
  const resolvedBranch = (neonBranch || process.env.NEON_BRANCH || "").toLowerCase();
  const resolvedEnv = (nodeEnv || process.env.NODE_ENV || "").toLowerCase();

  // 1. Explicit production NODE_ENV
  if (resolvedEnv === "production") {
    return true;
  }

  // 2. Explicit production NEON_BRANCH
  if (resolvedBranch === "main" || resolvedBranch === "production" || resolvedBranch === "master") {
    return true;
  }

  // 3. Known production host signatures in connection string
  for (const pattern of PRODUCTION_HOST_PATTERNS) {
    if (resolvedUrl.includes(pattern)) {
      return true;
    }
  }

  return false;
}

/**
 * Returns true if the database configuration can be positively verified
 * as an isolated staging, test, or local development database.
 */
export function isIsolatedStagingDatabase(
  url?: string,
  neonBranch?: string
): boolean {
  const resolvedUrl = (url || process.env.DATABASE_URL || "").toLowerCase();
  const resolvedBranch = (neonBranch || process.env.NEON_BRANCH || "").toLowerCase();

  // Never isolated if it matches any production indicator
  if (isProductionDatabase(url, neonBranch)) {
    return false;
  }

  // Explicit staging / test branch
  if (
    resolvedBranch.includes("staging") ||
    resolvedBranch.includes("test") ||
    resolvedBranch.includes("preview") ||
    resolvedBranch.includes("dev")
  ) {
    return true;
  }

  // Explicit staging / test / localhost in database URL
  if (
    resolvedUrl.includes("staging") ||
    resolvedUrl.includes("test") ||
    resolvedUrl.includes("localhost") ||
    resolvedUrl.includes("127.0.0.1") ||
    resolvedUrl.includes("pg_mem")
  ) {
    return true;
  }

  // CI Service Container or explicit test override
  if (process.env.ALLOW_LOCAL_TEST_DB === "true" || process.env.CI === "true") {
    return true;
  }

  return false;
}

/**
 * HARD SAFETY INVARIANT:
 * Guarantees that any staging seed, fixture provisioning, migration reset, or mutating
 * E2E test run FAILS IMMEDIATELY before executing any SQL if the configured database
 * is detected as production or cannot be positively verified as an isolated environment.
 */
export function assertIsolatedStagingDatabase(
  actionDescription: string,
  overrides?: { url?: string; neonBranch?: string; nodeEnv?: string }
): void {
  const url = overrides?.url ?? process.env.DATABASE_URL;
  const neonBranch = overrides?.neonBranch ?? process.env.NEON_BRANCH;
  const nodeEnv = overrides?.nodeEnv ?? process.env.NODE_ENV;

  if (isProductionDatabase(url, neonBranch, nodeEnv)) {
    const errorMsg =
      `[CRITICAL SAFETY GUARD] Refusing to execute "${actionDescription}" against PRODUCTION database! ` +
      `Detected production configuration (NEON_BRANCH="${neonBranch || 'unset'}", NODE_ENV="${nodeEnv || 'unset'}"). ` +
      `Mutating tests, demo tournaments, and test fixtures are strictly prohibited on production data. ` +
      `Point your configuration to an isolated staging branch (e.g., NEON_BRANCH=staging).`;

    logger.error({ action: actionDescription, neonBranch, nodeEnv }, errorMsg);
    throw new SafetyGuardError(errorMsg);
  }

  if (!isIsolatedStagingDatabase(url, neonBranch)) {
    const errorMsg =
      `[SAFETY GUARD] Cannot execute "${actionDescription}": database connection could not be verified ` +
      `as an isolated staging/test environment. Target URL does not match known staging patterns. ` +
      `Set NEON_BRANCH=staging or provide a DATABASE_URL explicitly designated for staging or test.`;

    logger.error({ action: actionDescription, neonBranch }, errorMsg);
    throw new SafetyGuardError(errorMsg);
  }
}
