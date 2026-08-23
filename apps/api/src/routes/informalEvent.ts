import { Router } from "express";
import { InformalEventController } from "../controllers/informalEvent.js";
import { authenticate } from "../middlewares/auth.js";
import { rateLimiter } from "../middlewares/security.js";

export const informalEventRouter = Router();

// Submit a new informal event (requires authentication, rate-limited)
informalEventRouter.post("/", authenticate, rateLimiter(60 * 1000, 10), InformalEventController.createEvent);

// List informal events (Public)
informalEventRouter.get("/", InformalEventController.getEvents);

// Get informal event details (Public)
informalEventRouter.get("/:id", InformalEventController.getEventById);

// Join an informal event (requires authentication)
informalEventRouter.post("/:id/join", authenticate, InformalEventController.joinEvent);

// Leave an informal event (requires authentication)
informalEventRouter.delete("/:id/leave", authenticate, InformalEventController.leaveEvent);

// Delete/cancel an informal event (requires authentication)
informalEventRouter.delete("/:id", authenticate, InformalEventController.deleteEvent);

export default informalEventRouter;
