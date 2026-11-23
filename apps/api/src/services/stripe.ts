import Stripe from "stripe";
import { env } from "../config/env.js";

let stripeInstance: Stripe | null = null;

export function isStripeConfigured(): boolean {
  const key = (env.STRIPE_SECRET_KEY || process.env.STRIPE_SECRET_KEY || "").trim();
  if (!key) return false;
  // Reject placeholder/dummy keys that would trigger 401/500 errors from Stripe API
  if (
    key.includes("placeholder") ||
    key.includes("your_") ||
    key === "sk_test_dummy" ||
    key === "sk_test_placeholder" ||
    key.length < 16
  ) {
    return false;
  }
  return true;
}

export function getStripe(): Stripe {
  if (!stripeInstance) {
    // Note: STRIPE_SECRET_KEY is never logged or returned in any response
    const key = env.STRIPE_SECRET_KEY;
    if (!key) {
      throw new Error("STRIPE_SECRET_KEY environment variable is required but was not provided.");
    }
    stripeInstance = new Stripe(key, {
      apiVersion: "2023-10-16" as any,
    });
  }
  return stripeInstance;
}
