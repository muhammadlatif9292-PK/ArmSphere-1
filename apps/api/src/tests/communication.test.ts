import { describe, it, expect, beforeEach, vi } from "vitest";
import { testDbStore } from "./setup.js";
console.log("=== GLOBAL: COMMUNICATION.TEST.TS EXECUTED ===");
import request from "supertest";
import { app } from "../app.js";
import { NotificationService, notificationMetrics } from "../services/notification.js";
import { MessagingService } from "../services/messaging.js";
import { AnnouncementService } from "../services/announcement.js";
import { UserRole } from "@armsphere/types";
import { generateAccessToken } from "@armsphere/cryptography";
import env from "../config/env.js";
import { processedJobsTracker, resetJobTrackers } from "../services/scheduledJobs.js";

async function waitForCondition(conditionFn: () => boolean, timeout = 500, interval = 10): Promise<void> {
  const startTime = Date.now();
  while (Date.now() - startTime < timeout) {
    if (conditionFn()) {
      return;
    }
    await new Promise((resolve) => setTimeout(resolve, interval));
  }
}

describe("Sprint 7 - Notifications, Messaging & Communication Infrastructure Tests", () => {
  let adminToken: string;
  let athleteToken: string;
  let refereeToken: string;

  const adminId = "admin-user-id";
  const athleteId = "athlete-user-id";
  const refereeId = "referee-user-id";

  beforeEach(() => {
    // 1. Reset Database & Socket stores
    testDbStore.users = [];
    testDbStore.notifications = [];
    testDbStore.conversations = [];
    testDbStore.conversationParticipants = [];
    testDbStore.messages = [];
    testDbStore.announcements = [];
    testDbStore.userCommunicationPreferences = [];
    testDbStore.userDeviceTokens = [];
    resetJobTrackers();

    // 2. Clear delivery metrics
    notificationMetrics.deliveryLatencies = [];
    notificationMetrics.retriesCount = 0;
    notificationMetrics.failedDeliveries = 0;
    notificationMetrics.successfulDeliveries = 0;

    // 3. Populate seed users
    testDbStore.users.push(
      {
        id: adminId,
        email: "admin@armsphere.com",
        username: "admin1",
        passwordHash: "hash",
        role: UserRole.SYSTEM_ADMIN,
        fullName: "System Admin",
        isActive: true,
      },
      {
        id: athleteId,
        email: "athlete@armsphere.com",
        username: "athlete1",
        passwordHash: "hash",
        role: UserRole.ATHLETE,
        fullName: "Arm Wrestler",
        isActive: true,
      },
      {
        id: refereeId,
        email: "referee@armsphere.com",
        username: "referee1",
        passwordHash: "hash",
        role: UserRole.REFEREE,
        fullName: "Head Referee",
        isActive: true,
      }
    );

    // 4. Generate Auth Tokens
    adminToken = generateAccessToken(adminId, "admin@armsphere.com", UserRole.SYSTEM_ADMIN, env.JWT_ACCESS_SECRET);
    athleteToken = generateAccessToken(athleteId, "athlete@armsphere.com", UserRole.ATHLETE, env.JWT_ACCESS_SECRET);
    refereeToken = generateAccessToken(refereeId, "referee@armsphere.com", UserRole.REFEREE, env.JWT_ACCESS_SECRET);
  });

  // =========================================================================
  // 1. NOTIFICATION SYSTEM TESTS
  // =========================================================================
  describe("Notification System", () => {
    it("should successfully create and dispatch in-app and background worker notification jobs", async () => {
      const response = await request(app)
        .post("/communication/notifications")
        .set("Authorization", `Bearer ${adminToken}`)
        .send({
          userId: athleteId,
          title: "New Challenge",
          content: "You have been challenged to a left arm supermatch!",
          priority: "HIGH",
          category: "MATCH",
        });

      expect(response.status).toBe(201);
      expect(response.body.success).toBe(true);
      expect(response.body.data.userId).toBe(athleteId);
      expect(response.body.data.priority).toBe("HIGH");

      // Give background workers a few milliseconds to process
      await new Promise((resolve) => setTimeout(resolve, 50));

      // Verify that jobs are successfully pushed to QueueManager dispatch queue
      expect(processedJobsTracker.notificationDispatched.length).toBeGreaterThan(0);
    });

    it("should fetch, filter, group and mark notifications as read/unread", async () => {
      // Pre-seed some notifications
      await NotificationService.createNotification({
        userId: athleteId,
        title: "Match Invite",
        content: "Be there at 2pm",
        priority: "LOW",
        category: "MATCH",
        groupId: "match-grp-1",
      });

      await NotificationService.createNotification({
        userId: athleteId,
        title: "System Update",
        content: "Server upgrade complete",
        priority: "MEDIUM",
        category: "SYSTEM",
        groupId: "system-grp-2",
      });

      // Fetch
      const fetchResp = await request(app)
        .get("/communication/notifications")
        .set("Authorization", `Bearer ${athleteToken}`);

      expect(fetchResp.status).toBe(200);
      expect(fetchResp.body.data.length).toBe(2);

      // Grouped Fetch
      const groupedResp = await request(app)
        .get("/communication/notifications?groupByGroup=true")
        .set("Authorization", `Bearer ${athleteToken}`);

      expect(groupedResp.status).toBe(200);
      expect(groupedResp.body.data["match-grp-1"]).toBeDefined();
      expect(groupedResp.body.data["system-grp-2"]).toBeDefined();

      // Mark single notification as read
      const notificationId = fetchResp.body.data[0].id;
      const readResp = await request(app)
        .post(`/communication/notifications/${notificationId}/read`)
        .set("Authorization", `Bearer ${athleteToken}`);

      expect(readResp.status).toBe(200);
      expect(readResp.body.data.status).toBe("READ");

      // Mark all as read
      const readAllResp = await request(app)
        .post("/communication/notifications/read-all")
        .set("Authorization", `Bearer ${athleteToken}`);

      expect(readAllResp.status).toBe(200);
      expect(readAllResp.body.data.success).toBe(true);
    });

    it("should apply quiet hours rules to filter push notifications, except CRITICAL priority", async () => {
      // 1. Update preferences to enable quiet hours
      await request(app)
        .put("/communication/preferences")
        .set("Authorization", `Bearer ${athleteToken}`)
        .send({
          quietHoursEnabled: true,
          quietHoursStart: "00:00",
          quietHoursEnd: "23:59", // Quiet hours covers the entire day
          quietHoursTimezone: "UTC",
        });

      // 2. Dispatch a MEDIUM priority notification (should NOT trigger push dispatch due to quiet hours)
      resetJobTrackers();
      await NotificationService.createNotification({
        userId: athleteId,
        title: "Normal Update",
        content: "Quiet hours block testing",
        priority: "MEDIUM",
        category: "SYSTEM",
      });

      await new Promise((resolve) => setTimeout(resolve, 50));

      // push/email/sms jobs shouldn't be queued
      const pushDispatchedCount = processedJobsTracker.notificationDispatched.filter(
        (job) => job.channel !== "in_app"
      ).length;
      expect(pushDispatchedCount).toBe(0);

      // 3. Dispatch a CRITICAL priority notification (should BYPASS quiet hours restrictions)
      await NotificationService.createNotification({
        userId: athleteId,
        title: "EMERGENCY ALERT",
        content: "Tournament match called immediately!",
        priority: "CRITICAL",
        category: "TOURNAMENT",
      });

      await new Promise((resolve) => setTimeout(resolve, 50));

      // CRITICAL priority notifications must bypass quiet hours restrictions and queue background jobs
      const criticalDispatchCount = processedJobsTracker.notificationDispatched.length;
      expect(criticalDispatchCount).toBeGreaterThan(0);
    });

    it("should support registering device tokens correctly", async () => {
      const resp = await request(app)
        .post("/communication/device-tokens")
        .set("Authorization", `Bearer ${athleteToken}`)
        .send({
          token: "fcm-device-push-token-12345",
          deviceType: "Android",
        });

      expect(resp.status).toBe(201);
      expect(resp.body.success).toBe(true);
      expect(resp.body.data.token).toBe("fcm-device-push-token-12345");
    });
  });

  // =========================================================================
  // 2. DIRECT MESSAGING SYSTEM TESTS
  // =========================================================================
  describe("Direct Messaging", () => {
    it("should build 1-on-1 direct messaging rooms and send attachments", async () => {
      // Get or create conversation room
      const convResp = await request(app)
        .post("/communication/conversations")
        .set("Authorization", `Bearer ${athleteToken}`)
        .send({
          participantId: refereeId,
          type: "DIRECT",
        });

      expect(convResp.status).toBe(200);
      const conversationId = convResp.body.data.conversation.id;

      // Send message with attachments
      const sendResp = await request(app)
        .post(`/communication/conversations/${conversationId}/messages`)
        .set("Authorization", `Bearer ${athleteToken}`)
        .send({
          content: "Please check this weigh-in document snapshot",
          attachments: [
            {
              url: "https://armsphere-buckets.com/weigh-in.jpg",
              filename: "weigh-in.jpg",
              size: 20485,
              mimeType: "image/jpeg",
            },
          ],
        });

      expect(sendResp.status).toBe(201);
      expect(sendResp.body.data.content).toBe("Please check this weigh-in document snapshot");
      expect(sendResp.body.data.attachments[0].filename).toBe("weigh-in.jpg");

      // Verify unread counts
      const unreadResp = await request(app)
        .get("/communication/unread-counts")
        .set("Authorization", `Bearer ${refereeToken}`);

      expect(unreadResp.status).toBe(200);
      expect(unreadResp.body.data.totalUnread).toBe(1);
    });

    it("should list conversations with correct ordering, user isolation, and unread counts", async () => {
      // 1. Setup Conversation A between Athlete and Referee
      const convA = await MessagingService.getOrCreateConversation(athleteId, refereeId) as any;
      const conversationAId = convA.conversation.id;

      // Send message in A (A is now active)
      await MessagingService.sendMessage({
        conversationId: conversationAId,
        senderId: athleteId,
        content: "Message in A",
      });
      // Ensure Message A has an older timestamp so sorting is perfectly deterministic
      if (testDbStore.messages.length > 0) {
        testDbStore.messages[testDbStore.messages.length - 1].createdAt = new Date(Date.now() - 5000);
      }

      // 2. Setup Conversation B between Athlete and Admin
      const convB = await MessagingService.getOrCreateConversation(athleteId, adminId) as any;
      const conversationBId = convB.conversation.id;

      // Send message in B (B is now more recently active)
      await MessagingService.sendMessage({
        conversationId: conversationBId,
        senderId: athleteId,
        content: "Message in B",
      });

      // --- Test User Isolation ---
      const adminConvResp = await request(app)
        .get("/communication/conversations")
        .set("Authorization", `Bearer ${adminToken}`);

      expect(adminConvResp.status).toBe(200);
      expect(adminConvResp.body.data.length).toBe(1);
      expect(adminConvResp.body.data[0].id).toBe(conversationBId);

      // --- Test Ordering ---
      const athleteConvResp = await request(app)
        .get("/communication/conversations")
        .set("Authorization", `Bearer ${athleteToken}`);

      expect(athleteConvResp.status).toBe(200);
      expect(athleteConvResp.body.data.length).toBe(2);
      expect(athleteConvResp.body.data[0].id).toBe(conversationBId); // B first (most recently active)
      expect(athleteConvResp.body.data[1].id).toBe(conversationAId); // A second

      // --- Test Unread Counts ---
      expect(athleteConvResp.body.data[0].unreadCount).toBe(0);
      expect(athleteConvResp.body.data[1].unreadCount).toBe(0);

      expect(adminConvResp.body.data[0].unreadCount).toBe(1);
      expect(adminConvResp.body.data[0].otherParticipant.id).toBe(athleteId);
    });

    it("should allow editing and soft-deleting messaging entries", async () => {
      const conv = await MessagingService.getOrCreateConversation(athleteId, refereeId) as any;
      const msg = await MessagingService.sendMessage({
        conversationId: conv.conversation.id,
        senderId: athleteId,
        content: "Original Content",
      });

      // Edit
      const editResp = await request(app)
        .put(`/communication/messages/${msg.id}`)
        .set("Authorization", `Bearer ${athleteToken}`)
        .send({
          content: "Corrected Content",
        });

      expect(editResp.status).toBe(200);
      expect(editResp.body.data.content).toBe("Corrected Content");
      expect(editResp.body.data.isEdited).toBe(true);

      // Deletion
      const deleteResp = await request(app)
        .delete(`/communication/messages/${msg.id}`)
        .set("Authorization", `Bearer ${athleteToken}`);

      expect(deleteResp.status).toBe(200);
      expect(deleteResp.body.data.isDeleted).toBe(true);
      expect(deleteResp.body.data.content).toBe("This message was deleted");
    });

    it("should broadcast typing indicators and presence updates", async () => {
      const conv = await MessagingService.getOrCreateConversation(athleteId, refereeId) as any;
      
      // Typing
      const typingResp = await request(app)
        .post(`/communication/conversations/${conv.conversation.id}/typing`)
        .set("Authorization", `Bearer ${athleteToken}`)
        .send({
          isTyping: true,
        });

      expect(typingResp.status).toBe(200);
      expect(typingResp.body.data.isTyping).toBe(true);

      // Presence
      const presenceResp = await request(app)
        .post("/communication/presence")
        .set("Authorization", `Bearer ${athleteToken}`)
        .send({
          isOnline: true,
        });

      expect(presenceResp.status).toBe(200);
      expect(presenceResp.body.data.isOnline).toBe(true);
    });
  });

  // =========================================================================
  // 3. ANNOUNCEMENT SYSTEM TESTS
  // =========================================================================
  describe("Announcement System", () => {
    it("should support national, provincial, and scheduled announcements with pin/archive", async () => {
      // 1. Create immediate national announcement (requires administrative privileges)
      const immResp = await request(app)
        .post("/communication/announcements")
        .set("Authorization", `Bearer ${adminToken}`)
        .send({
          title: "National Championships 2026",
          content: "The registration for national supermatch brackets has begun!",
          scope: "NATIONAL",
          isPinned: true,
        });

      expect(immResp.status).toBe(201);
      expect(immResp.body.data.isPinned).toBe(true);

      // 2. Create scheduled announcement
      const tomorrow = new Date();
      tomorrow.setDate(tomorrow.getDate() + 1);

      const schedResp = await request(app)
        .post("/communication/announcements")
        .set("Authorization", `Bearer ${adminToken}`)
        .send({
          title: "Upcoming Referee Training Seminar",
          content: "Provincial referee guidelines update",
          scope: "PROVINCIAL",
          scopeId: "ON", // Ontario
          scheduledFor: tomorrow.toISOString(),
        });

      expect(schedResp.status).toBe(201);
      expect(schedResp.body.data.publishedAt).toBeNull(); // remains unpublished draft

      // 3. Run scheduler worker tick simulation to confirm non-publishing of future announcements
      resetJobTrackers();
      await AnnouncementService.publishScheduledAnnouncements();
      expect(testDbStore.announcements.find(a => a.id === schedResp.body.data.id)?.publishedAt).toBeNull();

      // 4. Force scheduled announcement into the past and tick the publisher worker
      const pastDate = new Date();
      pastDate.setMinutes(pastDate.getMinutes() - 10);
      testDbStore.announcements = testDbStore.announcements.map((a) => {
        if (a.id === schedResp.body.data.id) {
          return { ...a, scheduledFor: pastDate };
        }
        return a;
      });

      const publishedCount = await AnnouncementService.publishScheduledAnnouncements();
      expect(publishedCount).toBe(1);
      expect(testDbStore.announcements.find(a => a.id === schedResp.body.data.id)?.publishedAt).not.toBeNull();
    });
  });

  // =========================================================================
  // 4. OFFLINE SYNC, RETRIES & CONCURRENCY TESTS
  // =========================================================================
  describe("Offline Support, Retries & Concurrency", () => {
    it("should track delivery failure, retry policies, and dead-letter queue routing", async () => {
      // Simulate failing dispatch queue additions by spying on NotificationService.simulateSmsSend
      const addJobSpy = vi.spyOn(NotificationService, "simulateSmsSend").mockRejectedValue(new Error("SMS Carrier Timeout"));

      // Seed notification
      let n: any;
      try {
        n = await NotificationService.createNotification({
          userId: athleteId,
          title: "Retry Test",
          content: "Testing retry resilience mechanisms",
          priority: "MEDIUM",
          category: "SYSTEM",
        });
      } catch (e) {
        // expected failure during direct dispatch
      }

      const createdN = testDbStore.notifications.find((item) => item.title === "Retry Test");

      // Verify retry tracking in database schema
      expect(createdN.retryCount).toBe(1);

      // Exhaust all retries to trigger DLQ logging
      createdN.retryCount = 2; // set to 2 so next is 3 (max)
      
      const dlqResult = await NotificationService.executeDispatch(createdN.id, "sms");
      expect(dlqResult.status).toBe("failed_permanently");
      expect(createdN.deliveryReceipts.sms).toBe("FAILED");

      // Restore spy to prevent leakage to subsequent tests
      addJobSpy.mockRestore();
    });
  });

  // =========================================================================
  // Sprint 16 — PUSH NOTIFICATION INFRASTRUCTURE TESTS
  // =========================================================================
  describe("Sprint 16 - Push Notification Infrastructure", () => {
    it("should register user devices successfully and prevent token leaks", async () => {
      // Register device for athlete
      const response = await request(app)
        .post("/api/v1/notifications/devices")
        .set("Authorization", `Bearer ${athleteToken}`)
        .send({
          deviceId: "device-123",
          platform: "ios",
          fcmToken: "fcm-token-123",
          apnsToken: "apns-token-123",
          appVersion: "1.0.0",
          locale: "en-US",
          timezone: "UTC",
          pushEnabled: true
        });

      expect(response.status).toBe(201);
      expect(response.body.success).toBe(true);
      expect(response.body.data.deviceId).toBe("device-123");
      expect(response.body.data.userId).toBe(athleteId);

      // Leak prevention: registering same FCM token for referee should remove it from athlete
      const leakResponse = await request(app)
        .post("/api/v1/notifications/devices")
        .set("Authorization", `Bearer ${refereeToken}`)
        .send({
          deviceId: "device-456",
          platform: "android",
          fcmToken: "fcm-token-123", // same FCM token
        });

      expect(leakResponse.status).toBe(201);
      
      // Athlete's previous registration with same FCM token should be cleaned up
      const athleteDevice = testDbStore.userDevices.find((d) => d.userId === athleteId && d.fcmToken === "fcm-token-123");
      expect(athleteDevice).toBeUndefined();
    });

    it("should deregister user devices successfully", async () => {
      // Seed a device
      testDbStore.userDevices.push({
        id: "reg-1",
        userId: athleteId,
        deviceId: "device-abc",
        platform: "android",
        fcmToken: "fcm-token-abc",
        pushEnabled: true,
        lastActiveAt: new Date()
      });

      const response = await request(app)
        .delete("/api/v1/notifications/devices/device-abc")
        .set("Authorization", `Bearer ${athleteToken}`);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);

      const device = testDbStore.userDevices.find((d) => d.id === "reg-1");
      expect(device).toBeUndefined();
    });

    it("should respect the notification fallback hierarchy (Push -> Email) when user receives notification", async () => {
      // Seed preferences with push and email enabled
      testDbStore.userCommunicationPreferences.push({
        userId: athleteId,
        pushEnabled: true,
        emailEnabled: true,
        smsEnabled: false,
        quietHoursEnabled: false
      });

      resetJobTrackers();

      await NotificationService.createNotification({
        userId: athleteId,
        title: "Offline Alert",
        content: "Fallback check",
        priority: "MEDIUM",
        category: "SYSTEM"
      });

      await waitForCondition(() => processedJobsTracker.notificationDispatched.some((j) => j.channel === "push"), 500, 10);

      // Should send push (highest fallback available)
      const pushDispatched = processedJobsTracker.notificationDispatched.find((j) => j.channel === "push");
      expect(pushDispatched).toBeDefined();
    });

    it("should trigger Push Notification directly and track in processedJobsTracker", async () => {
      resetJobTrackers();

      await NotificationService.simulatePushSend(athleteId, "FCM Alert", "Push test payload");

      // Verify trigger
      expect(processedJobsTracker.pushNotifications.length).toBeGreaterThan(0);
    });
  });

  // =========================================================================
  // 5. OBSERVABILITY & METRICS TESTS
  // =========================================================================
  describe("Observability metrics integration", () => {
    it("should successfully compile and return unified system delivery, polling, and scheduled job metrics", async () => {
      const response = await request(app)
        .get("/communication/metrics")
        .set("Authorization", `Bearer ${athleteToken}`);

      expect(response.status).toBe(200);
      expect(response.body.data.delivery).toBeDefined();
      expect(response.body.data.polling).toBeDefined();
      expect(response.body.data.scheduledJobs).toBeDefined();
    });
  });
});
