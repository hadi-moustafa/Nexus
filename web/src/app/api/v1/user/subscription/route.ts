import { type NextRequest, NextResponse } from "next/server";
import { createServiceClient } from "@/lib/supabase/server";
import { requireAuth } from "@/lib/auth";
import { stripe } from "@/lib/stripe";

/**
 * GET /api/v1/user/subscription
 * Returns the current user's subscription status.
 */
export async function GET(request: NextRequest) {
  const auth = await requireAuth(request);
  if (auth instanceof NextResponse) return auth;

  try {
    const supabase = createServiceClient();

    const { data, error } = await supabase
      .from("subscriptions")
      .select("id, plan, status, start_date, end_date, auto_renew, trial_ends_at")
      .eq("user_id", auth.userId)
      .single();

    if (error && error.code === "PGRST116") {
      return NextResponse.json({ data: null });
    }
    if (error) throw error;

    return NextResponse.json({ data });
  } catch (err) {
    console.error("[GET /api/v1/user/subscription]", err);
    return NextResponse.json(
      { error: { code: "INTERNAL_ERROR", message: "Failed to fetch subscription" } },
      { status: 500 }
    );
  }
}

/**
 * DELETE /api/v1/user/subscription
 *
 * Cancels the user's active subscription at the end of the current
 * billing period (cancel_at_period_end = true). Access continues until
 * `end_date`. Our DB row is updated to auto_renew = false.
 */
export async function DELETE(request: NextRequest) {
  const auth = await requireAuth(request);
  if (auth instanceof NextResponse) return auth;

  try {
    const supabase = createServiceClient();

    // Fetch our subscription row for the Stripe customer ID
    const { data: sub, error: fetchErr } = await supabase
      .from("subscriptions")
      .select("id, status, stripe_customer_id, auto_renew")
      .eq("user_id", auth.userId)
      .single();

    if (fetchErr || !sub) {
      return NextResponse.json(
        { error: { code: "NOT_FOUND", message: "No active subscription found" } },
        { status: 404 }
      );
    }

    if (sub.status === "canceled") {
      return NextResponse.json(
        { error: { code: "VALIDATION_ERROR", message: "Subscription is already canceled" } },
        { status: 400 }
      );
    }

    if (!sub.auto_renew) {
      return NextResponse.json(
        { error: { code: "VALIDATION_ERROR", message: "Subscription is already set to cancel" } },
        { status: 400 }
      );
    }

    // Find the active Stripe subscription for this customer
    if (sub.stripe_customer_id) {
      const stripeSubs = await stripe.subscriptions.list({
        customer: sub.stripe_customer_id as string,
        status: "active",
        limit: 1,
      });

      if (stripeSubs.data.length > 0) {
        await stripe.subscriptions.update(stripeSubs.data[0].id, {
          cancel_at_period_end: true,
        });
      }
    }

    // Mirror the change in our DB
    await supabase
      .from("subscriptions")
      .update({ auto_renew: false, updated_at: new Date().toISOString() })
      .eq("user_id", auth.userId);

    return NextResponse.json({ data: { canceled: true } });
  } catch (err) {
    console.error("[DELETE /api/v1/user/subscription]", err);
    return NextResponse.json(
      { error: { code: "INTERNAL_ERROR", message: "Failed to cancel subscription" } },
      { status: 500 }
    );
  }
}
