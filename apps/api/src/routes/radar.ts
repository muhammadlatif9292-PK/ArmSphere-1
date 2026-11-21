import { Router } from "express";
import { RadarController } from "../controllers/radar.js";
import { authenticate } from "../middlewares/auth.js";

export const radarRouter = Router();

radarRouter.get("/nearby", authenticate, RadarController.getNearby);
radarRouter.post("/beacons", authenticate, RadarController.createBeacon);
radarRouter.delete("/beacons/:id", authenticate, RadarController.deleteBeacon);

export default radarRouter;
