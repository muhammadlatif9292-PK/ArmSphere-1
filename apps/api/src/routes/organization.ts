import { Router } from "express";
import { OrganizationController } from "../controllers/organization.js";
import { authenticate } from "../middlewares/auth.js";

export const organizationRouter = Router();

// Public: List approved organizations for selection
organizationRouter.get("/", OrganizationController.listApproved);

// Public: Create a new sanctioning organization with auto-approved access code
organizationRouter.post("/", OrganizationController.create);

// Public: Verify access code and receive scoped operational session token
organizationRouter.post("/verify-access", OrganizationController.verifyAccess);

// Public: Get organization details by ID or slug
organizationRouter.get("/:id", OrganizationController.getById);

// Public: List official sanctioned events for this organization
organizationRouter.get("/:id/events", OrganizationController.listEventsForOrganization);

// Protected: Complete first-time onboarding (requires valid organization session token)
organizationRouter.post("/:id/onboard", authenticate, OrganizationController.onboard);
