import { runMigrations } from "../config/migrate.js";
import { pool } from "../config/db.js";
import { logger } from "@armsphere/core";

async function main() {
  try {
    await runMigrations();
    logger.info("Migration CLI executed successfully.");
    await pool.end().catch(() => {});
    process.exit(0);
  } catch (error) {
    logger.error({ error }, "Migration CLI failed.");
    await pool.end().catch(() => {});
    process.exit(1);
  }
}

main();
