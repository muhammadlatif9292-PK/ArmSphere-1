import dotenv from "dotenv";
dotenv.config();
if (!process.env.DATABASE_URL) {
  dotenv.config({ path: ".env.neon" });
  dotenv.config({ path: "../../.env.neon" });
}

import { db, pool } from "../config/db.js";
import { users } from "@armsphere/db-schema";
import { eq } from "drizzle-orm";
import { hashPassword } from "@armsphere/cryptography";
import { UserRole } from "@armsphere/types";
import crypto from "crypto";

export async function seedProduction() {
  console.log("================================================================================");
  console.log("           ARMSPHERE PRODUCTION BASELINE DATABASE INITIALIZATION");
  console.log("================================================================================");

  try {
    // 1. Verify Database Connectivity
    console.log("\n[STEP 1] Probing Database Connectivity...");
    const healthCheck = await pool.query("SELECT current_database(), current_user, version()");
    console.log(`  ✓ Database : ${healthCheck.rows[0].current_database}`);
    console.log(`  ✓ User     : ${healthCheck.rows[0].current_user}`);
    console.log(`  ✓ Engine   : ${healthCheck.rows[0].version.split(",")[0]}`);

    // 2. Verify Core Schema Tables
    console.log("\n[STEP 2] Verifying Core Schema Migration State...");
    const tablesCheck = await pool.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public' 
      AND table_name IN ('users', 'athlete_profiles', 'events', 'matches', 'audit_logs')
      ORDER BY table_name
    `);
    const foundTables = tablesCheck.rows.map((r: { table_name: string }) => r.table_name);
    console.log(`  ✓ Verified core tables: ${foundTables.join(", ")}`);
    if (foundTables.length < 5) {
      throw new Error(`Incomplete schema: expected at least 5 core tables, found ${foundTables.length}. Run 'npm run db:migrate' first.`);
    }

    // 3. Optional System Admin Bootstrap
    console.log("\n[STEP 3] Evaluating System Administrator Bootstrap State...");
    const adminEmail = process.env.SYSTEM_ADMIN_EMAIL;
    const adminPassword = process.env.SYSTEM_ADMIN_PASSWORD;

    if (adminEmail && adminPassword) {
      const existingAdmin = await db.select().from(users).where(eq(users.email, adminEmail)).limit(1);

      if (existingAdmin.length > 0) {
        console.log(`  ✓ System Administrator '${adminEmail}' already provisioned (ID: ${existingAdmin[0].id})`);
      } else {
        const adminId = crypto.randomUUID();
        const passwordHash = await hashPassword(adminPassword);
        const username = process.env.SYSTEM_ADMIN_USERNAME || "system_admin";

        await db.insert(users).values({
          id: adminId,
          email: adminEmail,
          username,
          passwordHash,
          role: UserRole.SYSTEM_ADMIN,
          fullName: "System Administrator",
          isActive: true,
          createdAt: new Date(),
          updatedAt: new Date(),
        });
        console.log(`  ✓ Created initial System Administrator account '${adminEmail}' (ID: ${adminId})`);
      }
    } else {
      console.log("  ℹ No SYSTEM_ADMIN_EMAIL / SYSTEM_ADMIN_PASSWORD provided in environment.");
      console.log("  ℹ Production database remains clean of hardcoded administrators.");
    }

    console.log("\n================================================================================");
    console.log("        PRODUCTION DATABASE BASELINE VERIFICATION: SUCCESS");
    console.log("================================================================================");
    console.log("  - Zero synthetic match records injected.");
    console.log("  - Zero fake athlete profiles or demo brackets created.");
    console.log("  - Schema verified ready for organic production traffic.");
    console.log("================================================================================\n");

  } catch (error) {
    console.error("Error executing seedProduction:", error);
    throw error;
  }
}

// Allow direct execution
if (process.argv[1]?.endsWith("seedProduction.ts") || process.argv[1]?.endsWith("seedProduction.js")) {
  seedProduction()
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
