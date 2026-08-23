import serverless from "serverless-http";
import { app } from "../../apps/api/src/app.js";

export const handler = serverless(app);
