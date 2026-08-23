import { v4 as uuidv4 } from "uuid";
import { UserRole } from "@armsphere/types";

export function createTestUserFixture(overrides: Partial<any> = {}) {
  const id = uuidv4();
  return {
    id,
    email: `test-${id.substring(0, 8)}@armsphere.com`,
    username: `user_${id.substring(0, 8)}`,
    passwordHash: "$2a$12$R9h/lIPzMRXzD1lH8H8M8O2fD.eJ5NCO7Z4yVlYc/U2VvFhY7oW8q", // Bcrypt hash for "password123"
    fullName: "Test Athlete User",
    role: UserRole.ATHLETE,
    isActive: true,
    createdAt: new Date(),
    updatedAt: new Date(),
    ...overrides,
  };
}

export function createTestSessionFixture(overrides: Partial<any> = {}) {
  const id = uuidv4();
  return {
    id,
    userId: uuidv4(),
    tokenFamily: uuidv4(),
    refreshTokenHash: "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855", // SHA-256 hash of "empty"
    isRevoked: false,
    expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000), // 30 days
    ipAddress: "127.0.0.1",
    userAgent: "Mozilla/5.0 (Test Agent)",
    createdAt: new Date(),
    ...overrides,
  };
}

export function createTestAuditLogFixture(overrides: Partial<any> = {}) {
  const id = uuidv4();
  return {
    id,
    userId: uuidv4(),
    action: "AUTH_LOGIN",
    details: { metadata: "test" },
    ipAddress: "127.0.0.1",
    userAgent: "Mozilla/5.0 (Test Agent)",
    createdAt: new Date(),
    ...overrides,
  };
}
