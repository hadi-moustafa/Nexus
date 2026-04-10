import { type NextRequest, NextResponse } from "next/server";
import { cookies } from "next/headers";
import { createClient } from "@/lib/supabase/server";
import { stripe } from "@/lib/stripe";
import type Stripe from "stripe";

/**
 * POST /api/v1/stripe/webhook
 *
 * Handles Stripe webhook events to keep the subscriptions table in sync.
 * Verifies the Stripe-Signature header before processing.
 *
 * Events handled:
 *   checkout.session.completed        → create/update subscription row
 *   customer.subscription.updated     → update status/dates
 *   customer.subscription.deleted     → mark as canceled
 */
export async function POST(request: NextRequest) {
  const sig = request.headers.get("stripe-signature");
  const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET;

  if (!sig || !webhookSecret) {
    return NextResponse.json({ error: "Missing signature or webhook secret" }, { status: 400 });
  }

  let event: Stripe.Event;
  try {
    const body = await request.text();
    event = stripe.webhooks.constructEvent(body, sig, webhookSecret);
  } catch (err) {
    console.error("[webhook] signature verification failed:", err);
    return NextResponse.json({ error: "Invalid signature" }, { status: 400 });
  }

  const cookieStore = await cookies();
  const supabase = createClient(cookieStore);

  try {
    switch (event.type) {
      case "checkout.session.completed": {
        const session = event.data.object as Stripe.Checkout.Session;
        const userId = session.metadata?.nexus_user_id;
        const plan = session.metadata?.plan ?? "monthly";
        if (!userId) break;

        const subId = session.subscription as string | null;
        let endDate: string | null = null;
        let stripeCustomerId = session.customer as string | null;

        let startDate: string = new Date().toISOString();
        let stripeSubscriptionId: string | null = subId;

        if (subId) {
          const stripeSub = await stripe.subscriptions.retrieve(subId);
          const periodEnd = (stripeSub as unknown as Record<string, unknown>).current_period_end as number | undefined;
          const periodStart = (stripeSub as unknown as Record<string, unknown>).current_period_start as number | undefined;
          endDate = periodEnd ? new Date(periodEnd * 1000).toISOString() : null;
          startDate = periodStart ? new Date(periodStart * 1000).toISOString() : startDate;
          stripeCustomerId = stripeSub.customer as string;
          stripeSubscriptionId = stripeSub.id;
        }

        await supabase.from("subscriptions").upsert(
          {
            user_id: userId,
            plan,
            status: "active",
            stripe_customer_id: stripeCustomerId,
            stripe_subscription_id: stripeSubscriptionId,
            start_date: startDate,
            end_date: endDate,
            auto_renew: true,
            updated_at: new Date().toISOString(),
          },
          { onConflict: "user_id" }
        );
        break;
      }

      case "customer.subscription.updated": {
        const sub = event.data.object as Stripe.Subscription;
        const userId = sub.metadata?.nexus_user_id;
        if (!userId) break;

        const periodEnd = (sub as unknown as Record<string, unknown>).current_period_end as number | undefined;
        const periodStart = (sub as unknown as Record<string, unknown>).current_period_start as number | undefined;
        await supabase.from("subscriptions").upsert(
          {
            user_id: userId,
            status: sub.status,
            stripe_subscription_id: sub.id,
            start_date: periodStart ? new Date(periodStart * 1000).toISOString() : undefined,
            end_date: periodEnd ? new Date(periodEnd * 1000).toISOString() : null,
            auto_renew: !sub.cancel_at_period_end,
            updated_at: new Date().toISOString(),
          },
          { onConflict: "user_id" }
        );
        break;
      }

      case "customer.subscription.deleted": {
        const sub = event.data.object as Stripe.Subscription;
        const userId = sub.metadata?.nexus_user_id;
        if (!userId) break;

        await supabase
          .from("subscriptions")
          .update({
            status: "canceled",
            auto_renew: false,
            updated_at: new Date().toISOString(),
          })
          .eq("user_id", userId);
        break;
      }

      default:
        // Unhandled event type — ignore
        break;
    }
  } catch (err) {
    console.error(`[webhook] error processing ${event.type}:`, err);
    return NextResponse.json({ error: "Handler failed" }, { status: 500 });
  }

  return NextResponse.json({ received: true });
}

// Stripe requires raw body — disable Next.js body parsing
export const config = { api: { bodyParser: false } };
