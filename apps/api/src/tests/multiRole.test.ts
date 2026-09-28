import { describe, it, expect, beforeEach } from "vitest";
import request from "supertest";
import { app } from "../app.js";
import { testDbStore } from "./setup.js";
import { UserRole } from "@armsphere/types";
import { generateAccessToken } from "@armsphere/cryptography";
import env from "../config/env.js";
import { UserRoleService } from "../services/userRole.js";
import { v4 as uuidv4 } from "uuid";

describe("Multi-Role Account Architecture & Authoritative Authorization", () => {
  beforeEach(() => {
    testDbStore.users = [];
    testDbStore.userRoleGrants = [];
    testDbStore.roleApplications = [];
    testDbStore.userSessions = [];
    testDbStore.auditLogs = [];
  });

  const athleteUser = {
    id: "user-athlete-uuid-1",
    email: "athlete@armsphere.com",
    username: "athlete_champ",
    fullName: "Athlete Champ",
    role: UserRole.ATHLETE,
    isActive: true,
    createdAt: new Date(),
    updatedAt: new Date(),
  };

  const adminUser = {
    id: "admin-director-uuid-1",
    email: "director@armsphere.com",
    username: "national_director",
    fullName: "National Director",
    role: UserRole.NATIONAL_DIRECTOR,
    isActive: true,
    createdAt: new Date(),
    updatedAt: new Date(),
  };

  // Case 1: User with only ATHLETE role has verifiedRoles = ['ATHLETE']
  it("Case 1: User with only ATHLETE role has verifiedRoles = ['ATHLETE']", async () => {
    testDbStore.users.push({ ...athleteUser });

    const athleteToken = generateAccessToken(
      athleteUser.id,
      athleteUser.email,
      athleteUser.role,
      env.JWT_ACCESS_SECRET
    );

    const res = await request(app)
      .get("/auth/roles")
      .set("Authorization", `Bearer ${athleteToken}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.verifiedRoles).toEqual([UserRole.ATHLETE]);
    expect(res.body.data.roleGrants).toHaveLength(1);
    expect(res.body.data.roleGrants[0].status).toBe("ACTIVE");
  });

  // Case 2: User granted REFEREE role has verifiedRoles = ['ATHLETE', 'REFEREE']
  it("Case 2: User granted REFEREE role has verifiedRoles = ['ATHLETE', 'REFEREE']", async () => {
    testDbStore.users.push({ ...athleteUser });
    testDbStore.userRoleGrants.push({
      id: uuidv4(),
      userId: athleteUser.id,
      role: UserRole.ATHLETE,
      status: "ACTIVE",
      grantedAt: new Date(),
    });
    testDbStore.userRoleGrants.push({
      id: uuidv4(),
      userId: athleteUser.id,
      role: UserRole.REFEREE,
      status: "ACTIVE",
      grantedAt: new Date(),
    });

    const athleteToken = generateAccessToken(
      athleteUser.id,
      athleteUser.email,
      athleteUser.role,
      env.JWT_ACCESS_SECRET
    );

    const res = await request(app)
      .get("/auth/roles")
      .set("Authorization", `Bearer ${athleteToken}`);

    expect(res.status).toBe(200);
    expect(res.body.data.verifiedRoles).toContain(UserRole.ATHLETE);
    expect(res.body.data.verifiedRoles).toContain(UserRole.REFEREE);
    expect(res.body.data.verifiedRoles).toHaveLength(2);
  });

  // Case 3: requireRole(REFEREE) passes for multi-role user with active REFEREE grant even if JWT contains ATHLETE
  it("Case 3: requireRole(REFEREE) passes for user with active REFEREE grant even if JWT contains ATHLETE", async () => {
    testDbStore.users.push({ ...athleteUser });
    testDbStore.userRoleGrants.push({
      id: uuidv4(),
      userId: athleteUser.id,
      role: UserRole.ATHLETE,
      status: "ACTIVE",
      grantedAt: new Date(),
    });
    testDbStore.userRoleGrants.push({
      id: uuidv4(),
      userId: athleteUser.id,
      role: UserRole.REFEREE,
      status: "ACTIVE",
      grantedAt: new Date(),
    });

    // Token was minted when user logged in with ATHLETE persona
    const athleteJwt = generateAccessToken(
      athleteUser.id,
      athleteUser.email,
      UserRole.ATHLETE,
      env.JWT_ACCESS_SECRET
    );

    // Call a route requiring REFEREE (e.g. tournament match operations or admin inspect)
    const hasAccess = await UserRoleService.hasActiveRole(
      athleteUser.id,
      [UserRole.REFEREE],
      UserRole.ATHLETE
    );
    expect(hasAccess).toBe(true);
  });

  // Case 4: requireRole(REFEREE) fails if REFEREE grant is REVOKED even if JWT claims REFEREE
  it("Case 4: requireRole(REFEREE) fails if REFEREE grant is REVOKED even if JWT claims REFEREE", async () => {
    testDbStore.users.push({ ...athleteUser });
    testDbStore.userRoleGrants.push({
      id: uuidv4(),
      userId: athleteUser.id,
      role: UserRole.ATHLETE,
      status: "ACTIVE",
      grantedAt: new Date(),
    });
    testDbStore.userRoleGrants.push({
      id: uuidv4(),
      userId: athleteUser.id,
      role: UserRole.REFEREE,
      status: "REVOKED",
      revokedAt: new Date(),
      revocationReason: "Disciplinary action",
    });

    const hasAccess = await UserRoleService.hasActiveRole(
      athleteUser.id,
      [UserRole.REFEREE],
      UserRole.REFEREE // Even if token claims REFEREE!
    );
    expect(hasAccess).toBe(false);
  });

  // Case 5: requireRole(REFEREE) fails if REFEREE grant is SUSPENDED even if JWT claims REFEREE
  it("Case 5: requireRole(REFEREE) fails if REFEREE grant is SUSPENDED even if JWT claims REFEREE", async () => {
    testDbStore.users.push({ ...athleteUser });
    testDbStore.userRoleGrants.push({
      id: uuidv4(),
      userId: athleteUser.id,
      role: UserRole.ATHLETE,
      status: "ACTIVE",
      grantedAt: new Date(),
    });
    testDbStore.userRoleGrants.push({
      id: uuidv4(),
      userId: athleteUser.id,
      role: UserRole.REFEREE,
      status: "SUSPENDED",
      revocationReason: "Pending investigation",
    });

    const hasAccess = await UserRoleService.hasActiveRole(
      athleteUser.id,
      [UserRole.REFEREE],
      UserRole.REFEREE
    );
    expect(hasAccess).toBe(false);
  });

  // Case 6: User cannot self-service apply for SYSTEM_ADMIN or NATIONAL_DIRECTOR
  it("Case 6: User cannot self-service apply for SYSTEM_ADMIN or NATIONAL_DIRECTOR (throws 400)", async () => {
    testDbStore.users.push({ ...athleteUser });

    const athleteToken = generateAccessToken(
      athleteUser.id,
      athleteUser.email,
      athleteUser.role,
      env.JWT_ACCESS_SECRET
    );

    const res = await request(app)
      .post("/auth/roles/apply")
      .set("Authorization", `Bearer ${athleteToken}`)
      .send({
        role: UserRole.SYSTEM_ADMIN,
        experienceDetails: "I want to be system administrator.",
      });

    expect(res.status).toBe(400);
    expect(res.body.message || res.body.detail).toContain(
      "Applications for governance and executive roles cannot be submitted via self-service."
    );
  });

  // Case 7: User can submit role application for REFEREE (returns 201 with status PENDING)
  it("Case 7: User can submit role application for REFEREE (returns 201 with status PENDING)", async () => {
    testDbStore.users.push({ ...athleteUser });

    const athleteToken = generateAccessToken(
      athleteUser.id,
      athleteUser.email,
      athleteUser.role,
      env.JWT_ACCESS_SECRET
    );

    const res = await request(app)
      .post("/auth/roles/apply")
      .set("Authorization", `Bearer ${athleteToken}`)
      .send({
        role: UserRole.REFEREE,
        experienceDetails: "Officiated 5 regional tournaments in Punjab.",
        certificationNumber: "PAFF-REF-2026-99",
      });

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.role).toBe(UserRole.REFEREE);
    expect(res.body.data.status).toBe("PENDING");
    expect(res.body.data.certificationNumber).toBe("PAFF-REF-2026-99");
  });

  // Case 8: User cannot submit duplicate PENDING application for the same role
  it("Case 8: User cannot submit duplicate PENDING application for the same role (throws 409 Conflict)", async () => {
    testDbStore.users.push({ ...athleteUser });
    testDbStore.roleApplications.push({
      id: uuidv4(),
      userId: athleteUser.id,
      role: UserRole.REFEREE,
      status: "PENDING",
      createdAt: new Date(),
    });

    const athleteToken = generateAccessToken(
      athleteUser.id,
      athleteUser.email,
      athleteUser.role,
      env.JWT_ACCESS_SECRET
    );

    const res = await request(app)
      .post("/auth/roles/apply")
      .set("Authorization", `Bearer ${athleteToken}`)
      .send({
        role: UserRole.REFEREE,
        experienceDetails: "Another application for referee.",
      });

    expect(res.status).toBe(409);
    expect(res.body.message || res.body.detail).toContain(
      "An application for the role of REFEREE is already pending review."
    );
  });

  // Case 9: User cannot apply for a role they already actively possess
  it("Case 9: User cannot apply for a role they already actively possess (throws 400 BadRequest)", async () => {
    testDbStore.users.push({ ...athleteUser });
    testDbStore.userRoleGrants.push({
      id: uuidv4(),
      userId: athleteUser.id,
      role: UserRole.REFEREE,
      status: "ACTIVE",
      grantedAt: new Date(),
    });

    const athleteToken = generateAccessToken(
      athleteUser.id,
      athleteUser.email,
      athleteUser.role,
      env.JWT_ACCESS_SECRET
    );

    const res = await request(app)
      .post("/auth/roles/apply")
      .set("Authorization", `Bearer ${athleteToken}`)
      .send({
        role: UserRole.REFEREE,
        experienceDetails: "Applying again for referee.",
      });

    expect(res.status).toBe(400);
    expect(res.body.message || res.body.detail).toContain(
      "You already have an active verified grant for the role of REFEREE."
    );
  });

  // Case 10: Admin can approve application -> status becomes APPROVED and active user_role_grants row is created
  it("Case 10: Admin can approve application -> status APPROVED and user_role_grants created", async () => {
    testDbStore.users.push({ ...athleteUser });
    testDbStore.users.push({ ...adminUser });

    const appId = uuidv4();
    testDbStore.roleApplications.push({
      id: appId,
      userId: athleteUser.id,
      role: UserRole.REFEREE,
      status: "PENDING",
      certificationNumber: "CERT-777",
      createdAt: new Date(),
      updatedAt: new Date(),
    });

    const adminToken = generateAccessToken(
      adminUser.id,
      adminUser.email,
      adminUser.role,
      env.JWT_ACCESS_SECRET
    );

    const res = await request(app)
      .post(`/admin/roles/applications/${appId}/review`)
      .set("Authorization", `Bearer ${adminToken}`)
      .send({
        decision: "APPROVED",
        notes: "Verified credentials with provincial board.",
      });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.application.status).toBe("APPROVED");
    expect(res.body.data.grant).toBeDefined();
    expect(res.body.data.grant.role).toBe(UserRole.REFEREE);
    expect(res.body.data.grant.status).toBe("ACTIVE");

    // Verify stored grant in db
    const userGrants = testDbStore.userRoleGrants.filter(
      (g) => g.userId === athleteUser.id && g.role === UserRole.REFEREE
    );
    expect(userGrants).toHaveLength(1);
    expect(userGrants[0].status).toBe("ACTIVE");
  });

  // Case 11: Admin can reject application -> status becomes REJECTED, no grant created
  it("Case 11: Admin can reject application -> status REJECTED, no grant created", async () => {
    testDbStore.users.push({ ...athleteUser });
    testDbStore.users.push({ ...adminUser });

    const appId = uuidv4();
    testDbStore.roleApplications.push({
      id: appId,
      userId: athleteUser.id,
      role: UserRole.TOURNAMENT_OPERATOR,
      status: "PENDING",
      createdAt: new Date(),
      updatedAt: new Date(),
    });

    const adminToken = generateAccessToken(
      adminUser.id,
      adminUser.email,
      adminUser.role,
      env.JWT_ACCESS_SECRET
    );

    const res = await request(app)
      .post(`/admin/roles/applications/${appId}/review`)
      .set("Authorization", `Bearer ${adminToken}`)
      .send({
        decision: "REJECTED",
        notes: "Insufficient tournament management experience.",
      });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.application.status).toBe("REJECTED");
    expect(res.body.data.grant).toBeNull();

    // Verify no operator grant created
    const operatorGrants = testDbStore.userRoleGrants.filter(
      (g) => g.userId === athleteUser.id && g.role === UserRole.TOURNAMENT_OPERATOR
    );
    expect(operatorGrants).toHaveLength(0);
  });

  // Case 12: Admin self-approval of role application is strictly forbidden (throws 403 Forbidden)
  it("Case 12: Admin self-approval of role application is strictly forbidden (throws 403 Forbidden)", async () => {
    testDbStore.users.push({ ...adminUser });

    const selfAppId = uuidv4();
    testDbStore.roleApplications.push({
      id: selfAppId,
      userId: adminUser.id, // Application submitted by admin
      role: UserRole.REFEREE,
      status: "PENDING",
      createdAt: new Date(),
      updatedAt: new Date(),
    });

    const adminToken = generateAccessToken(
      adminUser.id,
      adminUser.email,
      adminUser.role,
      env.JWT_ACCESS_SECRET
    );

    // Admin attempts to approve their own application
    const res = await request(app)
      .post(`/admin/roles/applications/${selfAppId}/review`)
      .set("Authorization", `Bearer ${adminToken}`)
      .send({
        decision: "APPROVED",
        notes: "Approving myself.",
      });

    expect(res.status).toBe(403);
    expect(res.body.message || res.body.detail).toContain(
      "Self-approval of role applications is strictly forbidden."
    );
  });
});
