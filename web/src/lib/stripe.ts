import Stripe from "stripe";

if (!process.env.STRIPE_SECRET_KEY) {
  throw new Error("STRIPE_SECRET_KEY env var is not set");
}

export const stripe = new Stripe(process.env.STRIPE_SECRET_KEY, {
  apiVersion: "2026-03-25.dahlia",
});

export const PLANS = {
  monthly: {
    priceId: process.env.STRIPE_MONTHLY_PRICE_ID ?? "",
    label: "Monthly",
    price: "$4.99",
    interval: "month",
  },
  annual: {
    priceId: process.env.STRIPE_ANNUAL_PRICE_ID ?? "",
    label: "Annual",
    price: "$39.99",
    interval: "year",
    savings: "Save 33%",
  },
} as const;

export type PlanKey = keyof typeof PLANS;
