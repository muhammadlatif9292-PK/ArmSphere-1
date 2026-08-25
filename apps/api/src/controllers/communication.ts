import { Request, Response, NextFunction } from "express";
import { NotificationService, notificationMetrics } from "../services/notification.js";
import { MessagingService } from "../services/messaging.js";
import { AnnouncementService } from "../services/announcement.js";
import { BadRequestError, ForbiddenError } from "@armsphere/core";

export class CommunicationController {
  // --- Notifications ---
  
  static async createNotification(req: Request, res: Response, next: NextFunction) {
    try {
      // Notifications target arbitrary users and fan out through push/email/SMS,
      // so only federation staff may create them.
      const STAFF_ROLES = [
        "SYSTEM_ADMIN",
        "NATIONAL_DIRECTOR",
        "PROVINCIAL_DIRECTOR",
        "COMPLIANCE_OFFICER",
        "SUPPORT_AGENT",
        "REFEREE",
        "TOURNAMENT_OPERATOR",
      ];
      if (!req.user || !STAFF_ROLES.includes(req.user.role)) {
        throw new ForbiddenError("Only federation staff can send direct notifications.");
      }

      const { userId, title, content, priority, category, groupId, expiresAt, metadata } = req.body;
      const result = await NotificationService.createNotification({
        userId,
        title,
        content,
        priority,
        category,
        groupId,
        expiresAt: expiresAt ? new Date(expiresAt) : undefined,
        metadata,
      });
      res.status(201).json({ success: true, data: result });
    } catch (error) {
      next(error);
    }
  }

  static async getNotifications(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = (req as any).user.id;
      const { status, category, groupByGroup, limit, offset } = req.query;
      
      const result = await NotificationService.getNotifications(userId, {
        status: status as any,
        category: category as any,
        groupByGroup: groupByGroup === "true",
        limit: limit ? Number(limit) : undefined,
        offset: offset ? Number(offset) : undefined,
      });

      res.status(200).json({ success: true, data: result });
    } catch (error) {
      next(error);
    }
  }

  static async markAsRead(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = (req as any).user.id;
      const { id } = req.params;
      const result = await NotificationService.markAsRead(userId, id);
      res.status(200).json({ success: true, data: result });
    } catch (error) {
      next(error);
    }
  }

  static async markAllAsRead(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = (req as any).user.id;
      const result = await NotificationService.markAllAsRead(userId);
      res.status(200).json({ success: true, data: result });
    } catch (error) {
      next(error);
    }
  }

  // --- Preferences & Device Tokens ---

  static async getPreferences(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = (req as any).user.id;
      const result = await NotificationService.getOrCreatePreferences(userId);
      res.status(200).json({ success: true, data: result });
    } catch (error) {
      next(error);
    }
  }

  static async updatePreferences(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = (req as any).user.id;
      const result = await NotificationService.updatePreferences(userId, req.body);
      res.status(200).json({ success: true, data: result });
    } catch (error) {
      next(error);
    }
  }

  static async registerDeviceToken(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = (req as any).user.id;
      const { token, deviceType } = req.body;
      const result = await NotificationService.manageDeviceToken(userId, token, deviceType);
      res.status(201).json({ success: true, data: result });
    } catch (error) {
      next(error);
    }
  }

  static async registerDevice(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = (req as any).user.id;
      const { 
        deviceId, 
        platform, 
        fcmToken, 
        apnsToken, 
        appVersion, 
        locale, 
        timezone, 
        pushEnabled 
      } = req.body;

      if (!deviceId || !platform) {
        throw new BadRequestError("deviceId and platform are required parameters.");
      }

      const { PushService } = await import("../services/push.js");
      const result = await PushService.registerDevice(userId, {
        deviceId,
        platform,
        fcmToken,
        apnsToken,
        appVersion,
        locale,
        timezone,
        pushEnabled,
      });

      res.status(201).json({ success: true, data: result });
    } catch (error) {
      next(error);
    }
  }

  static async deregisterDevice(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = (req as any).user.id;
      const { id } = req.params;

      if (!id) {
        throw new BadRequestError("Device registration ID or deviceId parameter is required.");
      }

      const { PushService } = await import("../services/push.js");
      const result = await PushService.deregisterDevice(userId, id);

      res.status(200).json({ success: true, data: result });
    } catch (error) {
      next(error);
    }
  }

  // --- Direct Messaging ---

  static async getOrCreateConversation(req: Request, res: Response, next: NextFunction) {
    try {
      const creatorId = (req as any).user.id;
      const { participantId, type } = req.body;
      const result = await MessagingService.getOrCreateConversation(creatorId, participantId, type);
      res.status(200).json({ success: true, data: result });
    } catch (error) {
      next(error);
    }
  }

  static async getConversations(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = (req as any).user.id;
      const result = await MessagingService.getConversations(userId);
      res.status(200).json({ success: true, data: result });
    } catch (error) {
      console.error("DEBUG ERROR IN CONTROLLER:", error);
      next(error);
    }
  }

  static async getConversationMessages(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = (req as any).user.id;
      const { id } = req.params;
      const { limit, offset } = req.query;
      const result = await MessagingService.getConversationMessages(
        userId,
        id,
        limit ? Number(limit) : undefined,
        offset ? Number(offset) : undefined
      );
      res.status(200).json({ success: true, data: result });
    } catch (error) {
      next(error);
    }
  }

  static async sendMessage(req: Request, res: Response, next: NextFunction) {
    try {
      const senderId = (req as any).user.id;
      const { id } = req.params;
      const { content, attachments } = req.body;
      const result = await MessagingService.sendMessage({
        conversationId: id,
        senderId,
        content,
        attachments,
      });
      res.status(201).json({ success: true, data: result });
    } catch (error) {
      next(error);
    }
  }

  static async editMessage(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = (req as any).user.id;
      const { id } = req.params;
      const { content } = req.body;
      const result = await MessagingService.editMessage(userId, id, content);
      res.status(200).json({ success: true, data: result });
    } catch (error) {
      next(error);
    }
  }

  static async deleteMessage(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = (req as any).user.id;
      const { id } = req.params;
      const result = await MessagingService.deleteMessage(userId, id);
      res.status(200).json({ success: true, data: result });
    } catch (error) {
      next(error);
    }
  }

  static async setTypingIndicator(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = (req as any).user.id;
      const { id } = req.params;
      const { isTyping } = req.body;
      const result = await MessagingService.setTypingIndicator(userId, id, isTyping);
      res.status(200).json({ success: true, data: result });
    } catch (error) {
      next(error);
    }
  }

  static async setPresence(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = (req as any).user.id;
      const { isOnline } = req.body;
      const result = await MessagingService.setPresence(userId, isOnline);
      res.status(200).json({ success: true, data: result });
    } catch (error) {
      next(error);
    }
  }

  static async getUnreadCounts(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = (req as any).user.id;
      const result = await MessagingService.getUnreadCounts(userId);
      res.status(200).json({ success: true, data: result });
    } catch (error) {
      next(error);
    }
  }

  static async markConversationAsRead(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = (req as any).user.id;
      const { id } = req.params;
      const result = await MessagingService.markConversationAsRead(userId, id);
      res.status(200).json({ success: true, data: result });
    } catch (error) {
      next(error);
    }
  }

  // --- Announcements ---

  static async createAnnouncement(req: Request, res: Response, next: NextFunction) {
    try {
      const createdById = (req as any).user.id;
      const { title, content, scope, scopeId, isPinned, scheduledFor } = req.body;
      const result = await AnnouncementService.createAnnouncement({
        title,
        content,
        scope,
        scopeId,
        createdById,
        isPinned,
        scheduledFor: scheduledFor ? new Date(scheduledFor) : undefined,
      });
      res.status(201).json({ success: true, data: result });
    } catch (error) {
      next(error);
    }
  }

  static async getAnnouncements(req: Request, res: Response, next: NextFunction) {
    try {
      const { scope, scopeId, includeArchived, limit, offset } = req.query;
      const result = await AnnouncementService.getAnnouncements({
        scope: scope as any,
        scopeId: scopeId as string,
        includeArchived: includeArchived === "true",
        limit: limit ? Number(limit) : undefined,
        offset: offset ? Number(offset) : undefined,
      });
      res.status(200).json({ success: true, data: result });
    } catch (error) {
      next(error);
    }
  }

  static async updateAnnouncement(req: Request, res: Response, next: NextFunction) {
    try {
      const { id } = req.params;
      const result = await AnnouncementService.updateAnnouncement(id, req.body);
      res.status(200).json({ success: true, data: result });
    } catch (error) {
      next(error);
    }
  }

  // --- Observability Metrics ---

  static async getMetrics(req: Request, res: Response, next: NextFunction) {
    try {
      // Calculate latency aggregates
      const latencies = notificationMetrics.deliveryLatencies;
      const avgLatency = latencies.length > 0 
        ? latencies.reduce((a, b) => a + b, 0) / latencies.length 
        : 0;

      res.status(200).json({
        success: true,
        data: {
          delivery: {
            successful: notificationMetrics.successfulDeliveries,
            failed: notificationMetrics.failedDeliveries,
            retries: notificationMetrics.retriesCount,
            avgLatencyMs: avgLatency,
          },
          polling: {
            status: "ACTIVE",
          },
          scheduledJobs: {
            status: "PG_BACKED_ACTIVE",
          },
        },
      });
    } catch (error) {
      next(error);
    }
  }
}
