import { runMigrations } from "../config/migrate.js";
import { logger } from "@armsphere/core";

async function main() {
  try {
    await runMigrations();
    logger.info("Migration CLI executed successfully.");
    process.exit(0);
  } catch (error) {
    logger.error({ error }, "Migration CLI failed.");
    process.exit(1);
  }
}

main();
