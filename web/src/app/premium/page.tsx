"use client";

import { useState, useEffect, Suspense } from "react";
import { useSearchParams, useRouter } from "next/navigation";
import {
  Zap, Check, Sparkles, Newspaper, Trophy, BookOpen, X, Loader2,
} from "lucide-react";
import { Navbar } from "@/components/layout/navbar";

const FEATURES = [
  { icon: Sparkles, text: "AI-generated daily digest" },
  { icon: Newspaper, text: "Ad-free reading experience" },
  { icon: Trophy, text: "Double XP on daily quizzes" },
  { icon: BookOpen, text: "Unlimited article saves" },
  { icon: Zap, text: "Early access to new features" },
];

const PLANS = [
  { key: "monthly", label: "Monthly", price: "$4.99", period: "/month", savings: null },
  { key: "annual",  label: "Annual",  price: "$39.99", period: "/year", savings: "Save 33%" },
] as const;

type PlanKey = "monthly" | "annual";

function PremiumContent() {
  const searchParams = useSearchParams();
  const router = useRouter();
  const [selectedPlan, setSelectedPlan] = useState<PlanKey>("annual");
  const [loading, setLoading]           = useState(false);
  const [verifying, setVerifying]       = useState(false);
  const [isPremium, setIsPremium]       = useState<boolean | null>(null);
  const [banner, setBanner]             = useState<{ type: "success" | "error"; text: string } | null>(null);

  const successParam  = searchParams.get("success");
  const canceledParam = searchParams.get("canceled");
  const sessionId     = searchParams.get("session_id");

  // ── On mount: check current subscription status ──
  useEffect(() => {
    fetch("/api/v1/user/subscription")
      .then((r) => r.json())
      .then(({ data }) => {
        setIsPremium(data?.status === "active" || data?.status === "trialing");
      })
      .catch(() => setIsPremium(false));
  }, []);

  // ── After successful Stripe redirect: verify & sync session ──
  useEffect(() => {
    if (successParam !== "true" || !sessionId) return;

    // Clear query params immediately so refresh doesn't re-trigger
    router.replace("/premium");

    setVerifying(true);
    fetch("/api/v1/stripe/verify-session", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ sessionId }),
    })
      .then((r) => r.json())
      .then(({ data, error }) => {
        if (error) {
          setBanner({ type: "error", text: error.message ?? "Could not confirm payment." });
          return;
        }
        setIsPremium(true);
        setBanner({ type: "success", text: "Welcome to Nexus Premium! Your subscription is now active." });
      })
      .catch(() => {
        setBanner({ type: "error", text: "Payment confirmed but sync failed — please refresh." });
      })
      .finally(() => setVerifying(false));
  }, [successParam, sessionId, router]);

  // ── Canceled ──
  useEffect(() => {
    if (canceledParam === "true") {
      setBanner({ type: "error", text: "Checkout was canceled. You can try again anytime." });
      router.replace("/premium");
    }
  }, [canceledParam, router]);

  const handleCheckout = async () => {
    setLoading(true);
    try {
      const res = await fetch("/api/v1/stripe/checkout", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ plan: selectedPlan }),
      });
      if (res.status === 401) { router.push("/"); return; }
      const { data, error } = await res.json();
      if (error) { setBanner({ type: "error", text: error.message }); return; }
      window.location.href = data.url;
    } catch {
      setBanner({ type: "error", text: "Something went wrong. Please try again." });
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-[var(--background)]">
      <Navbar />

      <main className="max-w-lg mx-auto px-5 pb-24 pt-8">
        {/* Verifying overlay */}
        {verifying && (
          <div className="mb-6 flex items-center gap-3 p-4 rounded-xl border border-[var(--primary)]/30 bg-[var(--primary)]/5 text-sm text-[var(--primary)]">
            <Loader2 size={16} className="animate-spin shrink-0" />
            Confirming your payment…
          </div>
        )}

        {/* Banner */}
        {banner && !verifying && (
          <div className={`mb-6 flex items-start gap-3 p-4 rounded-xl border text-sm ${
            banner.type === "success"
              ? "border-green-400/40 bg-green-500/5 text-green-600"
              : "border-red-400/40 bg-red-500/5 text-red-500"
          }`}>
            <span className="flex-1">{banner.text}</span>
            <button onClick={() => setBanner(null)}><X size={15} /></button>
          </div>
        )}

        {/* Already premium */}
        {isPremium && !verifying && (
          <div className="mb-6 flex items-center gap-3 p-4 rounded-2xl border border-[var(--primary)]/30 bg-[var(--primary)]/5">
            <Zap size={18} className="text-[var(--primary)] shrink-0" />
            <div>
              <p className="text-sm font-semibold text-[var(--text-primary)]">You&apos;re a Premium member</p>
              <p className="text-xs text-[var(--text-secondary)]">Enjoy all Nexus Premium features.</p>
            </div>
          </div>
        )}

        {/* Hero */}
        <div className="text-center mb-8">
          <div className="inline-flex items-center justify-center w-14 h-14 rounded-2xl bg-[var(--primary)]/10 mb-4">
            <Zap size={28} className="text-[var(--primary)]" />
          </div>
          <h1 className="font-display text-3xl font-bold text-[var(--text-primary)] mb-2">Nexus Premium</h1>
          <p className="text-sm text-[var(--text-secondary)]">Smarter news. Less noise. All yours.</p>
        </div>

        {/* Features */}
        <ul className="space-y-3 mb-8">
          {FEATURES.map(({ icon: Icon, text }) => (
            <li key={text} className="flex items-center gap-3 text-sm text-[var(--text-primary)]">
              <div className="w-7 h-7 rounded-lg bg-[var(--primary)]/10 flex items-center justify-center shrink-0">
                <Icon size={14} className="text-[var(--primary)]" />
              </div>
              {text}
            </li>
          ))}
        </ul>

        {/* Plans */}
        {!isPremium && (
          <div className="flex flex-col gap-3 mb-6">
            {PLANS.map((plan) => (
              <button
                key={plan.key}
                onClick={() => setSelectedPlan(plan.key)}
                className={`relative flex items-center justify-between px-5 py-4 rounded-2xl border text-left transition-all ${
                  selectedPlan === plan.key
                    ? "border-[var(--primary)] bg-[var(--primary)]/5"
                    : "border-[var(--border)] bg-[var(--surface)] hover:border-[var(--primary)]/40"
                }`}
              >
                <div>
                  <p className={`text-sm font-semibold ${selectedPlan === plan.key ? "text-[var(--primary)]" : "text-[var(--text-primary)]"}`}>
                    {plan.label}
                  </p>
                  {plan.savings && (
                    <span className="text-xs font-medium text-green-600 bg-green-500/10 px-1.5 py-0.5 rounded-full">
                      {plan.savings}
                    </span>
                  )}
                </div>
                <div className="text-right">
                  <p className={`text-lg font-bold ${selectedPlan === plan.key ? "text-[var(--primary)]" : "text-[var(--text-primary)]"}`}>
                    {plan.price}
                  </p>
                  <p className="text-xs text-[var(--text-secondary)]">{plan.period}</p>
                </div>
                {selectedPlan === plan.key && (
                  <div className="absolute top-3 right-3">
                    <Check size={15} className="text-[var(--primary)]" />
                  </div>
                )}
              </button>
            ))}
          </div>
        )}

        {/* CTA */}
        {!isPremium && !verifying && (
          <button
            onClick={handleCheckout}
            disabled={loading}
            className="w-full py-3.5 rounded-2xl bg-[var(--primary)] text-white text-sm font-semibold hover:opacity-90 transition-opacity disabled:opacity-60"
          >
            {loading
              ? "Redirecting to checkout…"
              : `Subscribe — ${PLANS.find((p) => p.key === selectedPlan)?.price}${PLANS.find((p) => p.key === selectedPlan)?.period}`}
          </button>
        )}

        {isPremium && !verifying && (
          <button
            onClick={() => router.push("/digest")}
            className="w-full py-3.5 rounded-2xl bg-[var(--primary)] text-white text-sm font-semibold hover:opacity-90 transition-opacity"
          >
            View today&apos;s digest →
          </button>
        )}

        <p className="text-center text-xs text-[var(--text-secondary)] mt-4">
          Cancel anytime. Secure payment via Stripe.
        </p>
      </main>
    </div>
  );
}

export default function PremiumPage() {
  return (
    <Suspense fallback={<div className="min-h-screen bg-[var(--background)]"><Navbar /></div>}>
      <PremiumContent />
    </Suspense>
  );
}
