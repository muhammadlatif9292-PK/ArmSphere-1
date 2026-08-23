import { Router } from "express";
import { VenueController } from "../controllers/venue.js";
import { authenticate, requireRole } from "../middlewares/auth.js";
import { UserRole } from "@armsphere/types";

export const venueRouter = Router();

// Submission (requires authentication)
venueRouter.post("/", authenticate, VenueController.createVenue);

// Public List & Detail
venueRouter.get("/", VenueController.getVenues);
venueRouter.get("/:id", VenueController.getVenueById);

// Update (requires authentication, only owner or admin)
venueRouter.patch("/:id", authenticate, VenueController.updateVenue);

// Verification (admin roles only)
venueRouter.post(
  "/:id/verify",
  authenticate,
  requireRole(UserRole.SYSTEM_ADMIN, UserRole.NATIONAL_DIRECTOR, UserRole.PROVINCIAL_DIRECTOR),
  VenueController.verifyVenue
);

export default venueRouter;
