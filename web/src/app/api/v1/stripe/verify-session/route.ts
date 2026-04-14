import { type NextRequest, NextResponse } from "next/server";
import { createServiceClient } from "@/lib/supabase/server";
import { stripe } from "@/lib/stripe";
import { requireAuth } from "@/lib/auth";

/**
 * POST /api/v1/stripe/verify-session
 *
 * Called immediately after a successful Stripe Checkout redirect.
 * Retrieves the session from Stripe, confirms payment, and writes
 * the subscription row to the DB.
 *
 * This is the fallback for when the webhook hasn't fired yet (e.g. dev).
 *
 * Body: { sessionId: string }
 */
export async function POST(request: NextRequest) {
  const auth = await requireAuth(request);
  if (auth instanceof NextResponse) return auth;

  try {
    const { sessionId } = await request.json() as { sessionId?: string };

    if (!sessionId) {
      return NextResponse.json(
        { error: { code: "VALIDATION_ERROR", message: "sessionId is required" } },
        { status: 400 }
      );
    }

    // Retrieve session from Stripe
    const session = await stripe.checkout.sessions.retrieve(sessionId, {
      expand: ["subscription"],
    });

    // Verify the session belongs to this user
    if (session.metadata?.nexus_user_id !== auth.userId) {
      return NextResponse.json(
        { error: { code: "FORBIDDEN", message: "Session does not belong to this user" } },
        { status: 403 }
      );
    }

    if (session.payment_status !== "paid" && session.status !== "complete") {
      return NextResponse.json(
        { error: { code: "PAYMENT_INCOMPLETE", message: "Payment not completed" } },
        { status: 402 }
      );
    }

    // DB plan enum is "premium" — metadata plan ("monthly"/"annual") is the billing interval, not the tier
    const billingInterval = (session.metadata?.plan ?? "monthly") as "monthly" | "annual";
    const stripeCustomerId = session.customer as string;
    const stripeSub = session.subscription as import("stripe").Stripe.Subscription | null;

    const periodEnd = stripeSub
      ? ((stripeSub as unknown as Record<string, unknown>).current_period_end as number | undefined)
      : undefined;
    const periodStart = stripeSub
      ? ((stripeSub as unknown as Record<string, unknown>).current_period_start as number | undefined)
      : undefined;

    const endDate = periodEnd ? new Date(periodEnd * 1000).toISOString() : null;
    const startDate = periodStart ? new Date(periodStart * 1000).toISOString() : new Date().toISOString();

    // Use service client — this is a trusted server-side write, RLS must not block it.
    const supabase = createServiceClient();

    // Upsert subscription row — plan enum is "premium", not the billing interval
    const { error: upsertErr } = await supabase.from("subscriptions").upsert(
      {
        user_id: auth.userId,
        plan: "premium",
        status: "active",
        stripe_customer_id: stripeCustomerId,
        stripe_subscription_id: stripeSub?.id ?? null,
        start_date: startDate,
        end_date: endDate,
        auto_renew: true,
        updated_at: new Date().toISOString(),
      },
      { onConflict: "user_id" }
    );

    if (upsertErr) throw upsertErr;

    return NextResponse.json({
      data: {
        status: "active",
        plan: billingInterval,
        endDate,
      },
    });
  } catch (err) {
    console.error("[POST /api/v1/stripe/verify-session]", err);
    return NextResponse.json(
      { error: { code: "INTERNAL_ERROR", message: "Failed to verify session" } },
      { status: 500 }
    );
  }
}
