import { Router } from "express";
import { OrganizationController } from "../controllers/organization.js";
import { authenticate } from "../middlewares/auth.js";

export const organizationRouter = Router();

// Public: List approved organizations for selection
organizationRouter.get("/", OrganizationController.listApproved);

// Public: Verify access code and receive scoped operational session token
organizationRouter.post("/verify-access", OrganizationController.verifyAccess);

// Protected: Complete first-time onboarding (requires valid organization session token)
organizationRouter.post("/:id/onboard", authenticate, OrganizationController.onboard);
