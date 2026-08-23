import { eq, and, desc, isNull, sql } from "drizzle-orm";
import { db } from "../config/db.js";
import { 
  notifications, 
  userCommunicationPreferences, 
  userDeviceTokens, 
  users 
} from "@armsphere/db-schema";
import { BadRequestError, NotFoundError, logger } from "@armsphere/core";
import { scheduleJob, SCHEDULED_JOB_TYPES, processedJobsTracker } from "./scheduledJobs.js";

// Memory metric store for Observability requirements
export const notificationMetrics = {
  deliveryLatencies: [] as number[], // in ms
  retriesCount: 0,
  failedDeliveries: 0,
  successfulDeliveries: 0,
};

export class NotificationService {
  /**
   * Create and process a notification
   */
  static async createNotification(params: {
    userId: string;
    title: string;
    content: string;
    priority: "LOW" | "MEDIUM" | "HIGH" | "CRITICAL";
    category: "SYSTEM" | "TOURNAMENT" | "CHAT" | "MATCH" | "GOVERNANCE";
    groupId?: string;
    expiresAt?: Date;
    metadata?: any;
  }) {
    logger.info(params, "Creating and queuing new notification");

    // 1. Resolve user preferences
    let prefs = await this.getOrCreatePreferences(params.userId);

    // 2. Insert notification record
    const [notification] = await db
      .insert(notifications)
      .values({
        userId: params.userId,
        title: params.title,
        content: params.content,
        priority: params.priority,
        category: params.category,
        status: "UNREAD",
        groupId: params.groupId || null,
        expiresAt: params.expiresAt || null,
        metadata: params.metadata || {},
        deliveryReceipts: { in_app: "PENDING" },
        retryCount: 0,
        maxRetries: 3,
      })
      .returning();

    // 3. Determine dispatch channels based on fallback hierarchy: Push -> Email -> SMS
    const isQuiet = this.isQuietHoursActive(prefs);
    
    // In-app is always enabled unless expired
    const channelsToDispatch: string[] = ["in_app"];

    // Push, Email, SMS check with Quiet Hours override (CRITICAL bypasses quiet hours)
    const bypassQuiet = params.priority === "CRITICAL" || params.priority === "HIGH";

    if (prefs.pushEnabled && (!isQuiet || bypassQuiet)) {
      channelsToDispatch.push("push");
    } else if (prefs.emailEnabled && (!isQuiet || bypassQuiet)) {
      channelsToDispatch.push("email");
    } else if (prefs.smsEnabled && (!isQuiet || bypassQuiet)) {
      channelsToDispatch.push("sms");
    }

    // Execute dispatches directly
    for (const channel of channelsToDispatch) {
      if (channel === "in_app") {
        // Mark as immediately delivered for in-app
        await this.updateDeliveryReceipt(notification.id, "in_app", "DELIVERED");
      } else {
        processedJobsTracker.notificationDispatched.push({
          notificationId: notification.id,
          channel,
        });
        await this.executeDispatch(notification.id, channel as "push" | "email" | "sms");
      }
    }

    return notification;
  }

  /**
   * Fetch user notifications with grouping, status filtering, and pagination
   */
  static async getNotifications(userId: string, filters: {
    status?: "UNREAD" | "READ" | "ARCHIVED";
    category?: string;
    groupByGroup?: boolean;
    limit?: number;
    offset?: number;
  }) {
    const limit = filters.limit || 50;
    const offset = filters.offset || 0;

    let conditions = [eq(notifications.userId, userId)];

    if (filters.status) {
      conditions.push(eq(notifications.status, filters.status));
    }
    if (filters.category) {
      conditions.push(eq(notifications.category, filters.category));
    }

    const queryResults = await db
      .select()
      .from(notifications)
      .where(and(...conditions))
      .orderBy(desc(notifications.createdAt));

    // Handle expiry cleanup on delivery reads
    const now = new Date();
    const activeResults = queryResults.filter((n) => {
      if (n.expiresAt && new Date(n.expiresAt) < now) {
        return false;
      }
      return true;
    });

    const paginated = activeResults.slice(offset, offset + limit);

    if (filters.groupByGroup) {
      // Grouping notifications by groupId or fallback to singular
      const grouped: Record<string, any[]> = {};
      paginated.forEach((n) => {
        const key = n.groupId || "ungrouped";
        if (!grouped[key]) grouped[key] = [];
        grouped[key].push(n);
      });
      return grouped;
    }

    return paginated;
  }

  /**
   * Mark specific notification as read
   */
  static async markAsRead(userId: string, notificationId: string) {
    const [n] = await db
      .select()
      .from(notifications)
      .where(and(eq(notifications.id, notificationId), eq(notifications.userId, userId)));

    if (!n) {
      throw new NotFoundError("Notification not found");
    }

    const [updated] = await db
      .update(notifications)
      .set({ status: "READ", updatedAt: new Date() })
      .where(eq(notifications.id, notificationId))
      .returning();

    return updated;
  }

  /**
   * Mark all notifications as read
   */
  static async markAllAsRead(userId: string) {
    await db
      .update(notifications)
      .set({ status: "READ", updatedAt: new Date() })
      .where(and(eq(notifications.userId, userId), eq(notifications.status, "UNREAD")));

    return { success: true };
  }

  /**
   * Executes the channel dispatch (called by scheduled job runner)
   */
  static async executeDispatch(notificationId: string, channel: string) {
    const startTime = Date.now();
    const [notification] = await db
      .select()
      .from(notifications)
      .where(eq(notifications.id, notificationId));

    if (!notification) {
      logger.error({ notificationId }, "Dispatch skipped: notification record missing");
      return { status: "skipped", reason: "record_missing" };
    }

    // Increment retry tracking
    const currentRetry = notification.retryCount + 1;
    await db
      .update(notifications)
      .set({
        retryCount: currentRetry,
        lastAttemptAt: new Date(),
        updatedAt: new Date(),
      })
      .where(eq(notifications.id, notificationId));

    try {
      if (channel === "push") {
        await this.simulatePushSend(notification.userId, notification.title, notification.content);
      } else if (channel === "email") {
        await this.simulateEmailSend(notification.userId, notification.title, notification.content);
      } else if (channel === "sms") {
        await this.simulateSmsSend(notification.userId, notification.content);
      }

      await this.updateDeliveryReceipt(notificationId, channel, "DELIVERED");
      
      // Observability latency tracing
      const latency = Date.now() - startTime;
      notificationMetrics.deliveryLatencies.push(latency);
      notificationMetrics.successfulDeliveries++;

      return { status: "delivered", channel, latency };
    } catch (err: any) {
      notificationMetrics.retriesCount++;
      logger.warn({ err, notificationId, channel }, "Channel dispatch attempt failed");

      if (currentRetry >= notification.maxRetries) {
        notificationMetrics.failedDeliveries++;
        await this.updateDeliveryReceipt(notificationId, channel, "FAILED");
        return { status: "failed_permanently", error: err.message };
      }

      throw err; // propagates to trigger scheduled job retry
    }
  }

  /**
   * Update JSONB delivery status receipts
   */
  private static async updateDeliveryReceipt(notificationId: string, channel: string, status: "PENDING" | "DELIVERED" | "FAILED") {
    const [n] = await db
      .select()
      .from(notifications)
      .where(eq(notifications.id, notificationId));

    if (!n) return;

    const currentReceipts = (n.deliveryReceipts as Record<string, string>) || {};
    currentReceipts[channel] = status;

    await db
      .update(notifications)
      .set({
        deliveryReceipts: currentReceipts,
        updatedAt: new Date(),
      })
      .where(eq(notifications.id, notificationId));
  }

  /**
   * Quiet hours algorithm
   */
  public static isQuietHoursActive(prefs: any): boolean {
    if (!prefs.quietHoursEnabled || !prefs.quietHoursStart || !prefs.quietHoursEnd) {
      return false;
    }

    try {
      const now = new Date();
      // Format current HH:MM in timezone
      let timeString = now.toLocaleTimeString("en-US", {
        hour12: false,
        hour: "2-digit",
        minute: "2-digit",
        timeZone: prefs.quietHoursTimezone || "UTC",
      });

      const [nowH, nowM] = timeString.split(":").map(Number);
      const [startH, startM] = prefs.quietHoursStart.split(":").map(Number);
      const [endH, endM] = prefs.quietHoursEnd.split(":").map(Number);

      const nowVal = nowH * 60 + nowM;
      const startVal = startH * 60 + startM;
      const endVal = endH * 60 + endM;

      if (startVal <= endVal) {
        return nowVal >= startVal && nowVal <= endVal;
      } else {
        // quiet hours cross midnight (e.g., 22:00 to 08:00)
        return nowVal >= startVal || nowVal <= endVal;
      }
    } catch {
      return false; // safe fallback
    }
  }

  /**
   * Gets or initializes user preferences
   */
  public static async getOrCreatePreferences(userId: string) {
    const [user] = await db
      .select()
      .from(users)
      .where(eq(users.id, userId));

    if (!user) {
      throw new NotFoundError("User not found");
    }

    const [existing] = await db
      .select()
      .from(userCommunicationPreferences)
      .where(eq(userCommunicationPreferences.userId, userId));

    if (existing) {
      return existing;
    }

    const [created] = await db
      .insert(userCommunicationPreferences)
      .values({
        userId,
        pushEnabled: true,
        emailEnabled: true,
        smsEnabled: true,
        quietHoursEnabled: false,
        quietHoursStart: "22:00",
        quietHoursEnd: "08:00",
        quietHoursTimezone: "UTC",
        categoriesConfig: {
          SYSTEM: ["push", "email"],
          TOURNAMENT: ["push", "email", "sms"],
          CHAT: ["push"],
          MATCH: ["push", "email"],
          GOVERNANCE: ["push", "email"],
        },
      })
      .returning();

    return created;
  }

  /**
   * Update preference configuration
   */
  public static async updatePreferences(userId: string, updates: {
    pushEnabled?: boolean;
    emailEnabled?: boolean;
    smsEnabled?: boolean;
    quietHoursEnabled?: boolean;
    quietHoursStart?: string;
    quietHoursEnd?: string;
    quietHoursTimezone?: string;
    categoriesConfig?: any;
  }) {
    await this.getOrCreatePreferences(userId);

    const [updated] = await db
      .update(userCommunicationPreferences)
      .set({
        ...updates,
        updatedAt: new Date(),
      })
      .where(eq(userCommunicationPreferences.userId, userId))
      .returning();

    return updated;
  }

  /**
   * Device tokens configuration
   */
  public static async manageDeviceToken(userId: string, token: string, deviceType: string) {
    // Delete duplicate if exists
    await db
      .delete(userDeviceTokens)
      .where(and(eq(userDeviceTokens.userId, userId), eq(userDeviceTokens.token, token)));

    const [created] = await db
      .insert(userDeviceTokens)
      .values({
        userId,
        token,
        deviceType,
        lastUsedAt: new Date(),
      })
      .returning();

    return created;
  }

  // Simulated / Production delivery sender utilities
  static async simulatePushSend(userId: string, title: string, content: string, metadata?: any) {
    logger.info({ userId, title, content }, "Forwarding push delivery to PushService pipeline");
    processedJobsTracker.pushNotifications.push({ userId, title, content, metadata });
    try {
      const { PushService } = await import("./push.js");
      const result = await PushService.sendToUser(userId, title, content, metadata);
      return { success: true, timestamp: new Date(), ...result };
    } catch (error: any) {
      logger.error({ error, userId }, "Push Notification delivery failed, scheduling retry");
      await scheduleJob(SCHEDULED_JOB_TYPES.PUSH_RETRY, new Date(Date.now() + 2000), {
        userId,
        title,
        content,
        metadata,
        retryReason: error.message,
        attemptCount: 1,
      });
      throw error;
    }
  }

  static async simulateEmailSend(userId: string, title: string, content: string) {
    logger.info({ userId, title, content }, "[SIMULATED EMAIL] Triggered SMTP/SendGrid delivery");
    return { success: true, timestamp: new Date() };
  }

  static async simulateSmsSend(userId: string, content: string) {
    logger.info({ userId, content }, "[SIMULATED SMS] Triggered Twilio delivery");
    return { success: true, timestamp: new Date() };
  }
}
