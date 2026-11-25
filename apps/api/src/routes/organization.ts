import { Router } from "express";
import { OrganizationController } from "../controllers/organization.js";
import { OrganizationCertificationController } from "../controllers/organizationCertification.js";
import { authenticate } from "../middlewares/auth.js";

export const organizationRouter = Router();

// Public: List approved organizations for selection
organizationRouter.get("/", OrganizationController.listApproved);

// Public: List featured approved organizations with real event and belt counts
organizationRouter.get("/featured", OrganizationController.listFeatured);

// Public: Create a new sanctioning organization with auto-approved access code
organizationRouter.post("/", OrganizationController.create);

// Public: Verify access code and receive scoped operational session token
organizationRouter.post("/verify-access", OrganizationController.verifyAccess);

// Protected: Organization-Issued Referee Certifications (strictly org-scoped / admin-authorized)
organizationRouter.get(
  "/:orgId/certifications/requests",
  authenticate,
  OrganizationCertificationController.listRequests
);
organizationRouter.post(
  "/:orgId/certifications/requests/:requestId/review",
  authenticate,
  OrganizationCertificationController.reviewRequest
);
organizationRouter.get(
  "/:orgId/certifications/athletes/search",
  authenticate,
  OrganizationCertificationController.searchAthletes
);
organizationRouter.post(
  "/:orgId/certifications/grant",
  authenticate,
  OrganizationCertificationController.grantCertification
);
organizationRouter.get(
  "/:orgId/certifications",
  authenticate,
  OrganizationCertificationController.listCertifications
);
organizationRouter.patch(
  "/:orgId/certifications/:certId/revoke",
  authenticate,
  OrganizationCertificationController.revokeCertification
);

// Public: List active certified officials for this organization (non-sensitive profile view)
organizationRouter.get("/:id/officials", OrganizationCertificationController.listPublicOfficials);

// Public: List official sanctioned events for this organization
organizationRouter.get("/:id/events", OrganizationController.listEventsForOrganization);

// Public: List official championship belts & titleholders for this organization
organizationRouter.get("/:id/champions", OrganizationController.listChampionsForOrganization);

// Protected: Complete first-time onboarding (requires valid organization session token)
organizationRouter.post("/:id/onboard", authenticate, OrganizationController.onboard);

// Public: Get organization details by ID or slug
organizationRouter.get("/:id", OrganizationController.getById);
