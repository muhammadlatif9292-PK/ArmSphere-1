import dotenv from "dotenv";
dotenv.config();
if (!process.env.DATABASE_URL && process.env.NODE_ENV !== "production") {
  dotenv.config({ path: ".env.neon" });
  dotenv.config({ path: "../../.env.neon" });
}

import { db } from "../config/db.js";
import { users } from "@armsphere/db-schema";
import { eq, or } from "drizzle-orm";
import { UserRoleService } from "../services/userRole.js";
import { UserRole } from "@armsphere/types";

async function main() {
  const identifier = process.argv[2];
  if (!identifier) {
    console.error("Usage: npx tsx src/scripts/grantRoles.ts <email-or-username> [ROLES...]");
    console.error("Example: npx tsx src/scripts/grantRoles.ts reviewer@armsphere.com ALL");
    console.error("Example: npx tsx src/scripts/grantRoles.ts user@example.com REFEREE TOURNAMENT_OPERATOR");
    process.exit(1);
  }

  const [user] = await db
    .select()
    .from(users)
    .where(or(eq(users.email, identifier), eq(users.username, identifier)))
    .limit(1);

  if (!user) {
    console.error(`User not found: ${identifier}`);
    process.exit(1);
  }

  console.log(`Found user: ${user.fullName || user.username} (${user.email}) [ID: ${user.id}]`);

  const requestedRolesArg = process.argv.slice(3);
  let rolesToGrant: string[] = [];

  if (requestedRolesArg.length === 0 || requestedRolesArg.includes("ALL")) {
    rolesToGrant = [
      UserRole.ATHLETE,
      UserRole.REFEREE,
      UserRole.TOURNAMENT_OPERATOR,
      UserRole.ORGANIZATION_LEADER,
      UserRole.SYSTEM_ADMIN,
    ];
  } else {
    rolesToGrant = requestedRolesArg;
  }

  for (const role of rolesToGrant) {
    await UserRoleService.grantRole(user.id, role, undefined, {
      grantedVia: "grantRoles.ts CLI script",
      grantedAt: new Date().toISOString(),
    });
    console.log(`  ✓ Granted role: ${role}`);
  }

  const overview = await UserRoleService.getUserRolesOverview(user.id);
  console.log(`\nAll verified active roles for ${user.email}:`);
  console.log(overview.verifiedRoles.map((r) => `  - ${r}`).join("\n"));
  process.exit(0);
}

main().catch((err) => {
  console.error("Error granting roles:", err);
  process.exit(1);
});
