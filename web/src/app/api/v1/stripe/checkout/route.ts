import { type NextRequest, NextResponse } from "next/server";
import { createServiceClient } from "@/lib/supabase/server";
import { stripe, PLANS, type PlanKey } from "@/lib/stripe";
import { requireAuth } from "@/lib/auth";

/**
 * POST /api/v1/stripe/checkout
 *
 * Creates a Stripe Checkout session for a subscription plan.
 * Requires auth.
 *
 * Body: { plan: "monthly" | "annual" }
 */
export async function POST(request: NextRequest) {
  const auth = await requireAuth(request);
  if (auth instanceof NextResponse) return auth;

  try {
    const { plan } = await request.json() as { plan: PlanKey };

    if (!plan || !(plan in PLANS)) {
      return NextResponse.json(
        { error: { code: "VALIDATION_ERROR", message: "plan must be 'monthly' or 'annual'" } },
        { status: 400 }
      );
    }

    const planConfig = PLANS[plan];

    if (!planConfig.priceId) {
      return NextResponse.json(
        { error: { code: "INTERNAL_ERROR", message: "Stripe price ID not configured" } },
        { status: 500 }
      );
    }

    const supabase = createServiceClient();

    // Fetch or reuse existing Stripe customer ID
    const { data: sub } = await supabase
      .from("subscriptions")
      .select("stripe_customer_id")
      .eq("user_id", auth.userId)
      .single();

    const { data: userRow } = await supabase
      .from("users")
      .select("email")
      .eq("id", auth.userId)
      .single();

    let customerId = sub?.stripe_customer_id as string | undefined;

    if (!customerId) {
      const customer = await stripe.customers.create({
        email: userRow?.email as string | undefined,
        metadata: { nexus_user_id: auth.userId },
      });
      customerId = customer.id;
    }

    // Mobile requests (Bearer token) have no browser Origin header, so always
    // use NEXT_PUBLIC_APP_URL — a network-accessible URL the phone's browser
    // can actually reach.  Web requests use the request origin as usual.
    const isMobile = request.headers.get("authorization")?.startsWith("Bearer ");
    const appUrl = process.env.NEXT_PUBLIC_APP_URL?.replace(/\/$/, "") ?? "";
    const webOrigin = request.headers.get("origin")?.replace(/\/$/, "") ?? appUrl;
    const baseUrl = isMobile ? appUrl : webOrigin;

    const successUrl = isMobile
      ? `${baseUrl}/payment-callback?status=success&session_id={CHECKOUT_SESSION_ID}`
      : `${baseUrl}/premium?success=true&session_id={CHECKOUT_SESSION_ID}`;
    const cancelUrl = isMobile
      ? `${baseUrl}/payment-callback?status=canceled`
      : `${baseUrl}/premium?canceled=true`;

    const session = await stripe.checkout.sessions.create({
      customer: customerId,
      mode: "subscription",
      payment_method_types: ["card"],
      line_items: [{ price: planConfig.priceId, quantity: 1 }],
      success_url: successUrl,
      cancel_url: cancelUrl,
      metadata: { nexus_user_id: auth.userId, plan },
      subscription_data: {
        metadata: { nexus_user_id: auth.userId, plan },
      },
    });

    return NextResponse.json({ data: { url: session.url } });
  } catch (err) {
    console.error("[POST /api/v1/stripe/checkout]", err);
    return NextResponse.json(
      { error: { code: "INTERNAL_ERROR", message: "Failed to create checkout session" } },
      { status: 500 }
    );
  }
}
