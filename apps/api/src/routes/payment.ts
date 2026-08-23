import { Router } from "express";
import { PaymentController } from "../controllers/payment.js";
import { authenticate } from "../middlewares/auth.js";
import { rateLimiter } from "../middlewares/security.js";

export const paymentRouter = Router();

paymentRouter.post("/webhook", PaymentController.handleWebhook);

// Protected payment method endpoints
paymentRouter.get("/methods", authenticate, PaymentController.getPaymentMethods);
paymentRouter.delete("/methods/:id", authenticate, PaymentController.deletePaymentMethod);
paymentRouter.post("/setup-intent", authenticate, rateLimiter(60 * 1000, 5), PaymentController.createSetupIntent);

export default paymentRouter;
