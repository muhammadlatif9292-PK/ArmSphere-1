import { migrate } from "drizzle-orm/node-postgres/migrator";
import { db } from "./db.js";
import { logger } from "@armsphere/core";
import path from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

export async function runMigrations() {
  logger.info("Executing database migration sync...");
  try {
    // Resolve migrations folder path relative to the runtime build
    const migrationsFolder = path.resolve(__dirname, "../../migrations");
    await migrate(db, { migrationsFolder });
    logger.info("Database migrations executed successfully.");
  } catch (error) {
    logger.error({ error }, "Database migration sync failed.");
    throw error;
  }
}
