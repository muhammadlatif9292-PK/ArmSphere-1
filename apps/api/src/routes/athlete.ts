import { Router } from "express";
import { AthleteController } from "../controllers/athlete.js";
import { CommunityController } from "../controllers/community.js";
import { authenticate, requireRole } from "../middlewares/auth.js";
import { UserRole } from "@armsphere/types";

export const athleteRouter = Router();

// General athlete profile actions (requires authentication)
athleteRouter.post("/", authenticate, AthleteController.createProfile);
athleteRouter.get("/me", authenticate, AthleteController.getMe);
athleteRouter.patch("/me/visibility", authenticate, AthleteController.updateVisibility);
athleteRouter.get("/search", authenticate, AthleteController.searchAthletes);

// Club administration
athleteRouter.get("/clubs", authenticate, AthleteController.getClubs);
athleteRouter.post(
  "/clubs", 
  authenticate, 
  requireRole(UserRole.SYSTEM_ADMIN, UserRole.NATIONAL_DIRECTOR, UserRole.PROVINCIAL_DIRECTOR), 
  AthleteController.createClub
);

// Secure uploads & presigning (requires authentication)
athleteRouter.post("/upload", authenticate, AthleteController.directUpload);
athleteRouter.post("/presigned", authenticate, AthleteController.getPresignedUploadUrl);

// Verification flow
athleteRouter.post("/verification/document", authenticate, AthleteController.submitForVerification);
athleteRouter.post(
  "/verification/review", 
  authenticate, 
  requireRole(UserRole.SYSTEM_ADMIN, UserRole.NATIONAL_DIRECTOR, UserRole.PROVINCIAL_DIRECTOR), 
  AthleteController.reviewVerification
);

// Biometrics update
athleteRouter.post("/biometrics", authenticate, AthleteController.updateBiometrics);

// Specific profile detail retrieval & editing
athleteRouter.get("/:id", authenticate, AthleteController.getProfile);
athleteRouter.get("/:id/matches", authenticate, AthleteController.getAthleteMatches);
athleteRouter.get("/:id/training-log", authenticate, CommunityController.getTrainingLog);
athleteRouter.get("/:id/training-log/prs", authenticate, CommunityController.getTrainingLogPRs);
athleteRouter.patch("/:id", authenticate, AthleteController.updateProfile);

export default athleteRouter;
