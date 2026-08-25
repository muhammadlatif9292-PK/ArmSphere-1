import { Router } from "express";
import { SocialController } from "../controllers/social.js";
import { authenticate } from "../middlewares/auth.js";

export const socialRouter = Router();

// Follow actions (requires authentication)
socialRouter.post("/follow", authenticate, SocialController.follow);
socialRouter.delete("/follow/:followingId", authenticate, SocialController.unfollow);
socialRouter.get("/follow-status/:followingId", authenticate, SocialController.getFollowStatus);

// Follow lists (requires authentication)
socialRouter.get("/followers/:athleteId", authenticate, SocialController.getFollowers);
socialRouter.get("/following/:athleteId", authenticate, SocialController.getFollowing);

// Blocking actions (requires authentication)
socialRouter.post("/block/:athleteId", authenticate, SocialController.block);
socialRouter.delete("/block/:athleteId", authenticate, SocialController.unblock);
socialRouter.get("/blocked", authenticate, SocialController.getBlocked);

// Team actions (requires authentication)
socialRouter.post("/teams", authenticate, SocialController.createTeam);
socialRouter.post("/teams/:teamId/members", authenticate, SocialController.addTeamMember);
socialRouter.delete("/teams/:teamId/members/:athleteId", authenticate, SocialController.removeTeamMember);
socialRouter.get("/teams/:teamId", authenticate, SocialController.getTeam);
socialRouter.get("/my-teams", authenticate, SocialController.getMyTeams);

export default socialRouter;
