import { Router } from "express";
import { CommunicationController } from "../controllers/communication.js";
import { authenticate, requireRole } from "../middlewares/auth.js";
import { UserRole } from "@armsphere/types";

export const communicationRouter = Router();

// --- Notifications ---
communicationRouter.post(
  "/notifications",
  authenticate,
  CommunicationController.createNotification
);
communicationRouter.get(
  "/notifications",
  authenticate,
  CommunicationController.getNotifications
);
communicationRouter.post(
  "/notifications/:id/read",
  authenticate,
  CommunicationController.markAsRead
);
communicationRouter.post(
  "/notifications/read-all",
  authenticate,
  CommunicationController.markAllAsRead
);

// --- Preferences & Device Tokens ---
communicationRouter.get(
  "/preferences",
  authenticate,
  CommunicationController.getPreferences
);
communicationRouter.put(
  "/preferences",
  authenticate,
  CommunicationController.updatePreferences
);
communicationRouter.post(
  "/device-tokens",
  authenticate,
  CommunicationController.registerDeviceToken
);

// --- Device Registration ---
communicationRouter.post(
  "/devices",
  authenticate,
  CommunicationController.registerDevice
);
communicationRouter.delete(
  "/devices/:id",
  authenticate,
  CommunicationController.deregisterDevice
);

// --- Direct Messaging ---
communicationRouter.get(
  "/conversations",
  authenticate,
  CommunicationController.getConversations
);
communicationRouter.post(
  "/conversations",
  authenticate,
  CommunicationController.getOrCreateConversation
);
communicationRouter.get(
  "/conversations/:id/messages",
  authenticate,
  CommunicationController.getConversationMessages
);
communicationRouter.post(
  "/conversations/:id/messages",
  authenticate,
  CommunicationController.sendMessage
);
communicationRouter.put(
  "/messages/:id",
  authenticate,
  CommunicationController.editMessage
);
communicationRouter.delete(
  "/messages/:id",
  authenticate,
  CommunicationController.deleteMessage
);
communicationRouter.post(
  "/conversations/:id/typing",
  authenticate,
  CommunicationController.setTypingIndicator
);
communicationRouter.post(
  "/presence",
  authenticate,
  CommunicationController.setPresence
);
communicationRouter.get(
  "/unread-counts",
  authenticate,
  CommunicationController.getUnreadCounts
);
communicationRouter.post(
  "/conversations/:id/read",
  authenticate,
  CommunicationController.markConversationAsRead
);

// --- Announcements ---
communicationRouter.post(
  "/announcements",
  authenticate,
  requireRole(UserRole.SYSTEM_ADMIN, UserRole.NATIONAL_DIRECTOR, UserRole.PROVINCIAL_DIRECTOR),
  CommunicationController.createAnnouncement
);
communicationRouter.get(
  "/announcements",
  CommunicationController.getAnnouncements
);
communicationRouter.put(
  "/announcements/:id",
  authenticate,
  requireRole(UserRole.SYSTEM_ADMIN, UserRole.NATIONAL_DIRECTOR, UserRole.PROVINCIAL_DIRECTOR),
  CommunicationController.updateAnnouncement
);

// --- Observability Metrics ---
communicationRouter.get(
  "/metrics",
  authenticate,
  CommunicationController.getMetrics
);
