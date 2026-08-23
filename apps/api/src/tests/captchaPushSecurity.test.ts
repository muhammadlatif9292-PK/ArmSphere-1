import { describe, it, expect, beforeEach, afterEach, vi } from "vitest";
import request from "supertest";
import { testDbStore } from "./setup.js";
import { app } from "../app.js";
import { CaptchaService } from "../services/captcha.js";
import { PushService } from "../services/push.js";
import { generateAccessToken } from "@armsphere/cryptography";
import { UserRole } from "@armsphere/types";
import env from "../config/env.js";

function authHeader(userId: string, role: UserRole = UserRole.ATHLETE) {
  const token = generateAccessToken(userId, "test@armsphere.com", role, env.JWT_ACCESS_SECRET);
  return `Bearer ${token}`;
}

describe("CAPTCHA Security Boundaries", () => {
  afterEach(() => {
    vi.restoreAllMocks();
    vi.unstubAllGlobals();
  });

  it("bypasses verification without a secret key in non-production (documented dev fallback)", async () => {
    vi.spyOn(env, "CAPTCHA_SECRET_KEY", "get").mockReturnValue("");
    vi.spyOn(env, "NODE_ENV", "get").mockReturnValue("development");

    const response = await request(app)
      .post("/api/v1/security/captcha/verify")
      .send({ token: "any-garbage-token" });

    expect(response.status).toBe(200);
    expect(response.body.data.verified).toBe(true);
  });

  it("fails closed in production when no secret key is configured", async () => {
    vi.spyOn(env, "CAPTCHA_SECRET_KEY", "get").mockReturnValue("");
    vi.spyOn(env, "NODE_ENV", "get").mockReturnValue("production");

    const response = await request(app)
      .post("/api/v1/security/captcha/verify")
      .send({ token: "any-garbage-token" });

    expect(response.status).toBe(200);
    expect(response.body.data.verified).toBe(false);
  });

  it("rejects the hardcoded mock success tokens in production even when a secret key exists", async () => {
    vi.spyOn(env, "CAPTCHA_SECRET_KEY", "get").mockReturnValue("0xRealSecretAAA");
    vi.spyOn(env, "NODE_ENV", "get").mockReturnValue("production");

    const fetchSpy = vi.fn().mockResolvedValue({
      json: async () => ({ success: false, "error-codes": ["invalid-input-response"] }),
    });
    vi.stubGlobal("fetch", fetchSpy);

    for (const magic of ["MOCK_SUCCESS_TOKEN", "mock_token"]) {
      const response = await request(app)
        .post("/api/v1/security/captcha/verify")
        .send({ token: magic });
      expect(response.body.data.verified).toBe(false);
      // Must have gone out to Cloudflare instead of being short-circuited
      expect(fetchSpy).toHaveBeenCalled();
      fetchSpy.mockClear();
    }
  });

  it("still accepts the mock success tokens in non-production with a secret key (test tooling)", async () => {
    vi.spyOn(env, "CAPTCHA_SECRET_KEY", "get").mockReturnValue("0xTestSecretBBB");
    vi.spyOn(env, "NODE_ENV", "get").mockReturnValue("test");

    const response = await request(app)
      .post("/api/v1/security/captcha/verify")
      .send({ token: "MOCK_SUCCESS_TOKEN" });

    expect(response.body.data.verified).toBe(true);
  });

  it("returns verified=false when the Turnstile API call itself throws (secure failure posture)", async () => {
    vi.spyOn(env, "CAPTCHA_SECRET_KEY", "get").mockReturnValue("0xSecretCCC");
    vi.stubGlobal("fetch", vi.fn().mockRejectedValue(new Error("network down")));

    const result = await CaptchaService.verifyToken("some-token", "127.0.0.1");

    expect(result).toBe(false);
  });

  it("rejects a token that Cloudflare reports as failed", async () => {
    vi.spyOn(env, "CAPTCHA_SECRET_KEY", "get").mockReturnValue("0xSecretDDD");
    vi.stubGlobal("fetch", vi.fn().mockResolvedValue({
      json: async () => ({ success: false, "error-codes": ["timeout-or-duplicate"] }),
    }));

    const result = await CaptchaService.verifyToken("replayed-token");

    expect(result).toBe(false);
  });
});

describe("Push Notification Security & Ownership Boundaries", () => {
  let ownerId: string;
  let attackerId: string;

  beforeEach(() => {
    ownerId = "00000000-0000-4000-8000-000000000001";
    attackerId = "00000000-0000-4000-8000-000000000002";
    testDbStore.userDevices = [];
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  function seedDevice(overrides: Record<string, any> = {}) {
    return {
      id: overrides.id ?? "00000000-0000-4000-8000-00000000ffff",
      userId: ownerId,
      deviceId: "device-A",
      platform: "android",
      fcmToken: "fcm-token-OWNER",
      apnsToken: null,
      pushEnabled: true,
      lastActiveAt: new Date(),
      createdAt: new Date(),
      updatedAt: new Date(),
      ...overrides,
    };
  }

  it("prevents token takeover: registering an existing fcmToken under a new user removes it from other users", async () => {
    // Attacker re-registers owner's physical token under their own account
    await PushService.registerDevice(attackerId, {
      deviceId: "device-B",
      platform: "android",
      fcmToken: "fcm-token-SHARED",
    });

    testDbStore.userDevices = [
      seedDevice({ id: "00000000-0000-4000-8000-00000000aaaa", userId: ownerId, deviceId: "device-A", fcmToken: "fcm-token-SHARED" }),
      seedDevice({ id: "00000000-0000-4000-8000-00000000bbbb", userId: attackerId, deviceId: "device-B", fcmToken: "fcm-token-SHARED" }),
    ];

    // Re-registering triggers the takeover cleanup for tokens owned by others
    await PushService.registerDevice(ownerId, {
      deviceId: "device-C",
      platform: "android",
      fcmToken: "fcm-token-SHARED",
    });

    // Invariant: no OTHER user may retain the shared token afterwards.
    expect(testDbStore.userDevices.some((d) => d.id === "00000000-0000-4000-8000-00000000bbbb")).toBe(false);

    const remaining = testDbStore.userDevices.filter((d) => d.fcmToken === "fcm-token-SHARED");
    expect(remaining.length).toBeGreaterThanOrEqual(1);
    expect(remaining.every((d) => d.userId === ownerId)).toBe(true);
  });

  it("refuses to deregister a device the user does not own", async () => {
    testDbStore.userDevices = [
      seedDevice({ id: "00000000-0000-4000-8000-00000000cccc", deviceId: "victim-device" }),
    ];

    await expect(
      PushService.deregisterDevice(attackerId, "victim-device")
    ).rejects.toThrow(/not found or not owned/i);

    expect(testDbStore.userDevices.length).toBe(1);
    expect(testDbStore.userDevices[0].userId).toBe(ownerId);
  });

  it("allows the legitimate owner to deregister by deviceId or primary id", async () => {
    testDbStore.userDevices = [
      seedDevice({ id: "00000000-0000-4000-8000-00000000dddd", deviceId: "owner-device-x" }),
    ];

    await expect(PushService.deregisterDevice(ownerId, "owner-device-x")).resolves.toEqual({ success: true });
    expect(testDbStore.userDevices.length).toBe(0);

    testDbStore.userDevices = [
      seedDevice({ id: "00000000-0000-4000-8000-00000000eeee", deviceId: "owner-device-y" }),
    ];
    await expect(
      PushService.deregisterDevice(ownerId, "00000000-0000-4000-8000-00000000eeee")
    ).resolves.toEqual({ success: true });
    expect(testDbStore.userDevices.length).toBe(0);
  });

  it("never counts simulation fallback as delivery in production", async () => {
    vi.spyOn(env, "NODE_ENV", "get").mockReturnValue("production");
    // No FCM/APNs credentials configured -> both delivery paths unavailable
    vi.spyOn(env, "FIREBASE_PROJECT_ID", "get").mockReturnValue("");
    vi.spyOn(env, "FIREBASE_CLIENT_EMAIL", "get").mockReturnValue("");
    vi.spyOn(env, "FIREBASE_PRIVATE_KEY", "get").mockReturnValue("");

    testDbStore.userDevices = [seedDevice()];

    const result = await PushService.sendToUser(ownerId, "Hello", "Body");

    expect(result.devicesChecked).toBe(1);
    expect(result.sentCount).toBe(0);
    // Device record must survive a failed production send (no destructive pruning on transient failure)
    expect(testDbStore.userDevices.length).toBe(1);
  });

  it("counts simulated deliveries only outside production", async () => {
    vi.spyOn(env, "NODE_ENV", "get").mockReturnValue("development");
    vi.spyOn(env, "FIREBASE_PROJECT_ID", "get").mockReturnValue("");
    vi.spyOn(env, "FIREBASE_CLIENT_EMAIL", "get").mockReturnValue("");
    vi.spyOn(env, "FIREBASE_PRIVATE_KEY", "get").mockReturnValue("");

    testDbStore.userDevices = [seedDevice()];

    const result = await PushService.sendToUser(ownerId, "Hello", "Body");

    expect(result.sentCount).toBe(1);
  });

  it("skips devices with pushEnabled=false entirely", async () => {
    vi.spyOn(env, "NODE_ENV", "get").mockReturnValue("production");
    vi.spyOn(env, "FIREBASE_PROJECT_ID", "get").mockReturnValue("");
    vi.spyOn(env, "FIREBASE_CLIENT_EMAIL", "get").mockReturnValue("");
    vi.spyOn(env, "FIREBASE_PRIVATE_KEY", "get").mockReturnValue("");

    testDbStore.userDevices = [
      seedDevice({ pushEnabled: false, id: "00000000-0000-4000-8000-000000001111" }),
    ];

    const result = await PushService.sendToUser(ownerId, "Hello", "Body");

    expect(result.devicesChecked).toBe(0);
    expect(result.sentCount).toBe(0);
  });

  it("prunes only devices inactive beyond the threshold, never recent ones", async () => {
    const now = Date.now();
    testDbStore.userDevices = [
      seedDevice({ id: "00000000-0000-4000-8000-000000002222", lastActiveAt: new Date(now - 91 * 24 * 3600 * 1000) }),
      seedDevice({ id: "00000000-0000-4000-8000-000000003333", lastActiveAt: new Date(now - 89 * 24 * 3600 * 1000) }),
      seedDevice({ id: "00000000-0000-4000-8000-000000004444", lastActiveAt: new Date(now - 10 * 24 * 3600 * 1000) }),
    ];

    const pruned = await PushService.pruneStaleTokens();

    expect(pruned).toBe(1);
    const survivors = testDbStore.userDevices.map((d) => d.id);
    expect(survivors).toContain("00000000-0000-4000-8000-000000003333");
    expect(survivors).toContain("00000000-0000-4000-8000-000000004444");
    expect(survivors).not.toContain("00000000-0000-4000-8000-000000002222");
  });
});
