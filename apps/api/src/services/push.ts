import { eq, and, sql } from "drizzle-orm";
import { db } from "../config/db.js";
import { userDevices, notifications } from "@armsphere/db-schema";
import { logger } from "@armsphere/core";
import env from "../config/env.js";
import jwt from "jsonwebtoken";
import http2 from "http2";
import { initializeApp, cert } from "firebase-admin/app";
import { getMessaging } from "firebase-admin/messaging";
import type { App } from "firebase-admin/app";
import type { Messaging } from "firebase-admin/messaging";

export class PushService {
  private static fcmApp: App | null = null;
  private static apnsToken: string | null = null;
  private static apnsTokenExpiresAt: number = 0;

  /**
   * Lazily initializes Firebase Admin SDK safely
   */
  private static getFcm(): Messaging | null {
    if (this.fcmApp) {
      return getMessaging(this.fcmApp);
    }

    const { FIREBASE_PROJECT_ID, FIREBASE_CLIENT_EMAIL, FIREBASE_PRIVATE_KEY } = env;

    if (!FIREBASE_PROJECT_ID || !FIREBASE_CLIENT_EMAIL || !FIREBASE_PRIVATE_KEY) {
      logger.warn("FCM credentials missing. Falling back to simulated push delivery.");
      return null;
    }

    try {
      // Handle escaped newlines in private key
      const privateKey = FIREBASE_PRIVATE_KEY.replace(/\\n/g, "\n");
      
      this.fcmApp = initializeApp({
        credential: cert({
          projectId: FIREBASE_PROJECT_ID,
          clientEmail: FIREBASE_CLIENT_EMAIL,
          privateKey: privateKey,
        }),
      }, "armsphere-fcm");

      logger.info({ projectId: FIREBASE_PROJECT_ID }, "Firebase Admin SDK initialized successfully");
      return getMessaging(this.fcmApp);
    } catch (error) {
      logger.error({ error }, "Failed to initialize Firebase Admin SDK");
      return null;
    }
  }

  /**
   * Generates or retrieves a valid APNs authentication token
   */
  private static getApnsToken(): string | null {
    const { APNS_KEY_ID, APNS_TEAM_ID, APNS_PRIVATE_KEY } = env;

    if (!APNS_KEY_ID || !APNS_TEAM_ID || !APNS_PRIVATE_KEY) {
      return null;
    }

    const now = Math.floor(Date.now() / 1000);
    // If token exists and is valid for at least 5 more minutes, reuse it
    if (this.apnsToken && now < this.apnsTokenExpiresAt - 300) {
      return this.apnsToken;
    }

    try {
      const privateKey = APNS_PRIVATE_KEY.replace(/\\n/g, "\n");
      const token = jwt.sign({}, privateKey, {
        algorithm: "ES256",
        header: {
          alg: "ES256",
          kid: APNS_KEY_ID,
        },
        issuer: APNS_TEAM_ID,
        expiresIn: "1h",
      });

      this.apnsToken = token;
      this.apnsTokenExpiresAt = now + 3600;
      logger.info("APNs token generated successfully");
      return token;
    } catch (error) {
      logger.error({ error }, "Failed to generate APNs token");
      return null;
    }
  }

  /**
   * Send push notification to all active devices of a user
   */
  static async sendToUser(userId: string, title: string, content: string, metadata: Record<string, any> = {}) {
    logger.info({ userId }, "Beginning push notification distribution process");

    // Retrieve active, push-enabled devices for the user
    const devices = await db
      .select()
      .from(userDevices)
      .where(and(eq(userDevices.userId, userId), eq(userDevices.pushEnabled, true)));

    if (devices.length === 0) {
      logger.info({ userId }, "No active, push-enabled devices found for user. Dispatch skipped.");
      return { sentCount: 0, devicesChecked: 0 };
    }

    let sentCount = 0;
    const fcm = this.getFcm();
    const apnsToken = this.getApnsToken();

    for (const device of devices) {
      try {
        let sent = false;

        // 1. Apple Push Notification (APNs) Route
        if (device.platform === "ios" && device.apnsToken) {
          if (apnsToken) {
            sent = await this.sendViaApns(device.apnsToken, title, content, metadata, apnsToken);
          } else if (fcm && device.fcmToken) {
            // Fallback: iOS can also receive notifications via FCM
            sent = await this.sendViaFcm(device.fcmToken, title, content, metadata, fcm);
          }
        } 
        // 2. Android & Web / General Route (via FCM)
        else if (device.fcmToken && fcm) {
          sent = await this.sendViaFcm(device.fcmToken, title, content, metadata, fcm);
        }

        if (sent) {
          sentCount++;
          // Update last active timestamp
          await db
            .update(userDevices)
            .set({ lastActiveAt: new Date(), updatedAt: new Date() })
            .where(eq(userDevices.id, device.id));
        } else {
          // If both FCM & APNs are unavailable or failed, run simulation fallback in non-prod
          if (env.NODE_ENV !== "production") {
            logger.info({ deviceId: device.deviceId, platform: device.platform }, "[SIMULATION FALLBACK] Sending push to device");
            sentCount++;
          }
        }
      } catch (error) {
        logger.error({ error, deviceId: device.deviceId }, "Failed to deliver push notification to device");
      }
    }

    return { sentCount, devicesChecked: devices.length };
  }

  /**
   * Send notification via FCM
   */
  private static async sendViaFcm(
    fcmToken: string,
    title: string,
    body: string,
    metadata: Record<string, any>,
    fcm: Messaging
  ): Promise<boolean> {
    try {
      // FCM payloads require string values for data map
      const stringData: Record<string, string> = {};
      Object.entries(metadata).forEach(([k, v]) => {
        stringData[k] = typeof v === "object" ? JSON.stringify(v) : String(v);
      });

      await fcm.send({
        token: fcmToken,
        notification: {
          title,
          body,
        },
        data: stringData,
        android: {
          priority: "high",
          notification: {
            sound: "default",
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
              badge: 1,
            },
          },
        },
      });

      logger.info({ fcmToken: `${fcmToken.substring(0, 10)}...` }, "Successfully sent push notification via FCM");
      return true;
    } catch (error: any) {
      logger.error({ error, fcmToken }, "FCM delivery error");
      
      // Auto-prune inactive/invalid tokens
      if (
        error.code === "messaging/registration-token-not-registered" ||
        error.code === "messaging/invalid-argument" ||
        error.message?.includes("not-registered")
      ) {
        logger.warn({ fcmToken }, "FCM token is stale or unregistered. Deleting associated device token.");
        await db.delete(userDevices).where(eq(userDevices.fcmToken, fcmToken));
      }
      return false;
    }
  }

  /**
   * Send notification via direct HTTP/2 APNs connection
   */
  private static async sendViaApns(
    apnsToken: string,
    title: string,
    body: string,
    metadata: Record<string, any>,
    authToken: string
  ): Promise<boolean> {
    return new Promise((resolve) => {
      try {
        const isSandbox = env.APNS_SANDBOX === "true";
        const host = isSandbox
          ? "api.sandbox.push.apple.com"
          : "api.push.apple.com";

        // Establish HTTP/2 client session
        const client = http2.connect(`https://${host}:443`);

        client.on("error", (err) => {
          logger.error({ err }, "APNs HTTP/2 Connection Error");
          resolve(false);
        });

        const payload = {
          aps: {
            alert: {
              title,
              body,
            },
            sound: "default",
            badge: 1,
            "mutable-content": 1,
          },
          ...metadata,
        };

        const headers = {
          ":method": "POST",
          ":path": `/3/device/${apnsToken}`,
          "authorization": `bearer ${authToken}`,
          "apns-topic": env.APNS_BUNDLE_ID || "com.armsphere.app",
          "apns-push-type": "alert",
          "apns-expiration": "0",
          "apns-priority": "10",
        };

        const req = client.request(headers);

        req.on("response", async (headers) => {
          const status = headers[":status"];
          
          if (status === 200) {
            logger.info({ apnsToken: `${apnsToken.substring(0, 10)}...` }, "Successfully sent push notification via APNs");
            client.close();
            resolve(true);
          } else {
            // Read error response body
            let data = "";
            req.setEncoding("utf8");
            req.on("data", (chunk) => { data += chunk; });
            req.on("end", async () => {
              logger.warn({ status, response: data, apnsToken }, "APNs gateway returned failure response");
              
              // Parse error to clean up stale APNs tokens
              try {
                const parsed = JSON.parse(data);
                if (parsed.reason === "BadDeviceToken" || parsed.reason === "Unregistered") {
                  logger.warn({ apnsToken }, `APNs token rejected (${parsed.reason}). Pruning device record.`);
                  await db.delete(userDevices).where(eq(userDevices.apnsToken, apnsToken));
                }
              } catch (parseErr) {
                logger.error({ parseErr }, "Failed to parse APNs error response JSON");
              }
              client.close();
              resolve(false);
            });
          }
        });

        req.on("error", (err) => {
          logger.error({ err }, "APNs HTTP/2 Request Error");
          client.close();
          resolve(false);
        });

        req.write(JSON.stringify(payload));
        req.end();
      } catch (error) {
        logger.error({ error }, "Unexpected error in sendViaApns");
        resolve(false);
      }
    });
  }

  /**
   * Delete stale tokens that haven't been active for 90 days
   */
  static async pruneStaleTokens() {
    logger.info("Executing periodic device token pruning routine");
    const ninetyDaysAgo = new Date();
    ninetyDaysAgo.setDate(ninetyDaysAgo.getDate() - 90);

    const result = await db
      .delete(userDevices)
      .where(sql`${userDevices.lastActiveAt} < ${ninetyDaysAgo}`);

    logger.info({ prunedCount: result.rowCount }, "Device token pruning completed");
    return result.rowCount;
  }

  /**
   * Register or update a device configuration for a user
   */
  static async registerDevice(userId: string, data: {
    deviceId: string;
    platform: "ios" | "android" | "web";
    fcmToken?: string;
    apnsToken?: string;
    appVersion?: string;
    locale?: string;
    timezone?: string;
    pushEnabled?: boolean;
  }) {
    logger.info({ userId, deviceId: data.deviceId }, "Registering user device metadata");

    // Clean up same token from any other users if it was registered previously (token leak prevention)
    if (data.fcmToken) {
      await db
        .delete(userDevices)
        .where(and(eq(userDevices.fcmToken, data.fcmToken), sql`${userDevices.userId} != ${userId}`));
    }
    if (data.apnsToken) {
      await db
        .delete(userDevices)
        .where(and(eq(userDevices.apnsToken, data.apnsToken), sql`${userDevices.userId} != ${userId}`));
    }

    // Check if the device exists
    const [existing] = await db
      .select()
      .from(userDevices)
      .where(eq(userDevices.deviceId, data.deviceId));

    if (existing) {
      const [updated] = await db
        .update(userDevices)
        .set({
          userId,
          platform: data.platform,
          fcmToken: data.fcmToken ?? existing.fcmToken,
          apnsToken: data.apnsToken ?? existing.apnsToken,
          appVersion: data.appVersion ?? existing.appVersion,
          locale: data.locale ?? existing.locale,
          timezone: data.timezone ?? existing.timezone,
          pushEnabled: data.pushEnabled ?? existing.pushEnabled,
          lastActiveAt: new Date(),
          updatedAt: new Date(),
        })
        .where(eq(userDevices.deviceId, data.deviceId))
        .returning();

      return updated;
    } else {
      const [created] = await db
        .insert(userDevices)
        .values({
          userId,
          deviceId: data.deviceId,
          platform: data.platform,
          fcmToken: data.fcmToken,
          apnsToken: data.apnsToken,
          appVersion: data.appVersion,
          locale: data.locale,
          timezone: data.timezone,
          pushEnabled: data.pushEnabled ?? true,
          lastActiveAt: new Date(),
        })
        .returning();

      return created;
    }
  }

  /**
   * Remove/deregister a device configuration for a user
   */
  static async deregisterDevice(userId: string, deviceIdOrId: string) {
    logger.info({ userId, deviceIdOrId }, "Deregistering user device");
    
    // Find by either primary id or deviceId
    const [existing] = await db
      .select()
      .from(userDevices)
      .where(
        and(
          eq(userDevices.userId, userId),
          sql`${userDevices.deviceId} = ${deviceIdOrId} OR ${userDevices.id}::text = ${deviceIdOrId}`
        )
      );

    if (!existing) {
      throw new Error("Device not found or not owned by user");
    }

    await db
      .delete(userDevices)
      .where(eq(userDevices.id, existing.id));

    return { success: true };
  }
}
