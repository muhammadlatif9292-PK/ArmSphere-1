import { Router } from "express";
import { SyncController } from "../controllers/sync.js";
import { authenticate } from "../middlewares/auth.js";

export const syncRouter = Router();

syncRouter.get("/", authenticate, SyncController.getDelta);
syncRouter.post("/queue", authenticate, SyncController.queueAction);
syncRouter.get("/history", authenticate, SyncController.getActionsHistory);
syncRouter.get("/metrics", authenticate, SyncController.getQueueMetrics);

export default syncRouter;
