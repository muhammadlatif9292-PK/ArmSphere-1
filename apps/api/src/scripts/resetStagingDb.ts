import dotenv from "dotenv";
dotenv.config();
if (process.env.NODE_ENV === "staging" || process.env.APP_ENV === "staging") {
  dotenv.config({ path: ".env.staging" });
  dotenv.config({ path: "../../.env.staging" });
}

import { pool } from "../config/db.js";
import { assertIsolatedStagingDatabase } from "../config/databaseGuard.js";
import { runMigrations } from "../config/migrate.js";
import { logger } from "@armsphere/core";

export async function resetStagingDb() {
  console.log("================================================================================");
  console.log("         ARMSPHERE ISOLATED STAGING DATABASE RESET & RE-MIGRATION");
  console.log("================================================================================");

  // 1. HARD SAFETY INVARIANT CHECK
  assertIsolatedStagingDatabase("resetStagingDb");

  try {
    console.log("\n[STEP 1] Connected to verified staging database.");
    const dbInfo = await pool.query("SELECT current_database(), current_user, version()");
    console.log(`  ✓ Database : ${dbInfo.rows[0].current_database}`);
    console.log(`  ✓ User     : ${dbInfo.rows[0].current_user}`);

    console.log("\n[STEP 2] Dropping public and drizzle schemas in staging database...");
    await pool.query(`
      DROP SCHEMA IF EXISTS drizzle CASCADE;
      DROP SCHEMA IF EXISTS public CASCADE;
      CREATE SCHEMA public;
      GRANT ALL ON SCHEMA public TO public;
    `);
    console.log("  ✓ Staging public & drizzle schemas wiped clean.");

    console.log("\n[STEP 3] Re-applying latest Drizzle migrations from migration journal...");
    await runMigrations();
    console.log("  ✓ All migrations applied cleanly to staging database.");

    console.log("\n================================================================================");
    console.log("            STAGING DATABASE RESET COMPLETED SAFELY");
    console.log("================================================================================\n");
  } catch (error) {
    logger.error({ error }, "Failed to reset staging database.");
    throw error;
  }
}

if (process.argv[1]?.endsWith("resetStagingDb.ts") || process.argv[1]?.endsWith("resetStagingDb.js")) {
  resetStagingDb()
    .then(async () => {
      await pool.end();
      process.exit(0);
    })
    .catch(async (err) => {
      console.error(err);
      await pool.end();
      process.exit(1);
    });
}
