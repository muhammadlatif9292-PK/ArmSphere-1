import { Router } from "express";
import { CommunityController } from "../controllers/community.js";
import { authenticate, requireRole } from "../middlewares/auth.js";
import { UserRole } from "@armsphere/types";

export const communityRouter = Router();

// Feed endpoint
communityRouter.get("/feed", authenticate, CommunityController.getFeed);

// Link submission & deletion
communityRouter.post("/links", authenticate, CommunityController.submitLink);
communityRouter.delete("/posts/:id", authenticate, CommunityController.deletePost);

// Moderation routes (admin-only)
communityRouter.post(
  "/links/:id/moderate",
  authenticate,
  requireRole(UserRole.SYSTEM_ADMIN, UserRole.NATIONAL_DIRECTOR, UserRole.PROVINCIAL_DIRECTOR),
  CommunityController.moderateLinkSubmission
);

communityRouter.get(
  "/links/pending",
  authenticate,
  requireRole(UserRole.SYSTEM_ADMIN, UserRole.NATIONAL_DIRECTOR, UserRole.PROVINCIAL_DIRECTOR),
  CommunityController.getPendingSubmissions
);

// Post likes
communityRouter.post("/posts/:id/like", authenticate, CommunityController.likePost);
communityRouter.delete("/posts/:id/like", authenticate, CommunityController.unlikePost);

// Post comments
communityRouter.post("/posts/:id/comments", authenticate, CommunityController.addComment);
communityRouter.get("/posts/:id/comments", authenticate, CommunityController.getComments);

export default communityRouter;
