import dotenv from "dotenv";
dotenv.config();
if (!process.env.DATABASE_URL && process.env.NODE_ENV !== "production") {
  dotenv.config({ path: ".env.neon" });
  dotenv.config({ path: "../../.env.neon" });
}

import { pool } from "../config/db.js";

export async function migrateMultiRole() {
  console.log("Applying Multi-Role Account Architecture database migrations...");

  const client = await pool.connect();
  try {
    await client.query("BEGIN");

    // 1. user_role_grants table
    await client.query(`
      CREATE TABLE IF NOT EXISTS "user_role_grants" (
        "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        "user_id" uuid NOT NULL REFERENCES "users"("id") ON DELETE CASCADE,
        "role" varchar(50) NOT NULL,
        "status" varchar(50) NOT NULL DEFAULT 'ACTIVE',
        "scope" varchar(100),
        "granted_by" uuid REFERENCES "users"("id"),
        "granted_at" timestamp NOT NULL DEFAULT now(),
        "revoked_at" timestamp,
        "revocation_reason" text,
        "verification_metadata" jsonb,
        "created_at" timestamp NOT NULL DEFAULT now(),
        "updated_at" timestamp NOT NULL DEFAULT now()
      );
    `);
    console.log("  ✓ Created or verified table: user_role_grants");

    // Indexes for user_role_grants
    await client.query(`
      CREATE UNIQUE INDEX IF NOT EXISTS "idx_user_role_grants_user_role" 
      ON "user_role_grants" ("user_id", "role");
    `);
    await client.query(`
      CREATE INDEX IF NOT EXISTS "idx_user_role_grants_user_status" 
      ON "user_role_grants" ("user_id", "status");
    `);
    console.log("  ✓ Created or verified indexes for user_role_grants");

    // 2. role_applications table
    await client.query(`
      CREATE TABLE IF NOT EXISTS "role_applications" (
        "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        "user_id" uuid NOT NULL REFERENCES "users"("id") ON DELETE CASCADE,
        "role" varchar(50) NOT NULL,
        "status" varchar(50) NOT NULL DEFAULT 'PENDING',
        "experience_details" text,
        "certification_number" varchar(100),
        "documents" jsonb,
        "reviewer_id" uuid REFERENCES "users"("id"),
        "reviewed_at" timestamp,
        "review_notes" text,
        "created_at" timestamp NOT NULL DEFAULT now(),
        "updated_at" timestamp NOT NULL DEFAULT now()
      );
    `);
    console.log("  ✓ Created or verified table: role_applications");

    // Indexes for role_applications
    await client.query(`
      CREATE INDEX IF NOT EXISTS "idx_role_applications_user_role_status" 
      ON "role_applications" ("user_id", "role", "status");
    `);
    await client.query(`
      CREATE INDEX IF NOT EXISTS "idx_role_applications_status" 
      ON "role_applications" ("status");
    `);
    console.log("  ✓ Created or verified indexes for role_applications");

    // 3. Backfill existing user primary roles into user_role_grants
    const backfillResult = await client.query(`
      INSERT INTO "user_role_grants" ("user_id", "role", "status", "granted_at", "created_at", "updated_at")
      SELECT id, role, 'ACTIVE', now(), now(), now()
      FROM "users"
      ON CONFLICT ("user_id", "role") DO NOTHING;
    `);
    console.log(`  ✓ Backfilled primary roles for ${backfillResult.rowCount || 0} user records into user_role_grants`);

    await client.query("COMMIT");
    console.log("\n✅ Multi-Role migration completed successfully.");
  } catch (error) {
    await client.query("ROLLBACK");
    console.error("Migration failed:", error);
    throw error;
  } finally {
    client.release();
    await pool.end();
  }
}

// Run directly if invoked via CLI
if (process.argv[1]?.replace(/\\/g, "/").includes("migrateMultiRole")) {
  migrateMultiRole()
    .then(() => process.exit(0))
    .catch(() => process.exit(1));
}
