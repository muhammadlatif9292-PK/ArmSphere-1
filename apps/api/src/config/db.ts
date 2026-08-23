import { drizzle } from "drizzle-orm/node-postgres";
import pg from "pg";
import * as schema from "@armsphere/db-schema";
import env from "./env.js";

// Database Pool configuration using pg client
const maxConnections = env.IS_SERVERLESS
  ? 1
  : env.NODE_ENV === "production"
  ? 20
  : 5;

export const pool = new pg.Pool({
  connectionString: env.DATABASE_URL,
  ssl:
    env.NODE_ENV === "production" &&
    env.DATABASE_URL &&
    !env.DATABASE_URL.includes("localhost") &&
    !env.DATABASE_URL.includes("127.0.0.1")
      ? { rejectUnauthorized: false }
      : false,
  max: maxConnections,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 10000,
});

pool.on("error", (err) => {
  // Prevent idle PostgreSQL connection drops from crashing the Node.js server
  console.error("PostgreSQL pool idle client warning:", err?.message || err);
});

export const db = drizzle(pool, { schema });
export default db;
