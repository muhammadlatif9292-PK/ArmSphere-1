import type { Config } from "drizzle-kit";
import dotenv from "dotenv";

dotenv.config();

const connectionString = process.env.DATABASE_URL || "postgresql://USER:PASSWORD@ep-example.region.aws.neon.tech/neondb?sslmode=require";

const isInsideApi = process.cwd().replace(/\\/g, "/").endsWith("/apps/api") || process.cwd().replace(/\\/g, "/").endsWith("apps/api");

export default {
  schema: isInsideApi ? "../../packages/db-schema/index.ts" : "./packages/db-schema/index.ts",
  out: isInsideApi ? "./migrations" : "./apps/api/migrations",
  driver: "pg",
  dbCredentials: {
    connectionString,
  },
} satisfies Config;
