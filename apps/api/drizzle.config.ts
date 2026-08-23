import type { Config } from "drizzle-kit";
import dotenv from "dotenv";

dotenv.config();

const connectionString = process.env.DATABASE_URL || "postgresql://USER:PASSWORD@ep-example.region.aws.neon.tech/neondb?sslmode=require";

export default {
  schema: "./packages/db-schema/index.ts",
  out: "./apps/api/migrations",
  driver: "pg",
  dbCredentials: {
    connectionString,
  },
} satisfies Config;
