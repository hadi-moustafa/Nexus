"use client";

import { useState } from "react";
import { createClient } from "@/lib/supabase/client";
import { useRouter, useSearchParams } from "next/navigation";
import { Suspense } from "react";

// ── helpers ────────────────────────────────────────────────────────────────────

function friendlyError(raw: string): string {
  const msg = raw.toLowerCase();
  if (msg.includes("invalid login") || msg.includes("invalid credentials"))
    return "Incorrect email or password.";
  if (msg.includes("email already") || msg.includes("already registered"))
    return "An account with this email already exists.";
  if (msg.includes("weak password") || msg.includes("password should"))
    return "Password is too weak — use at least 6 characters.";
  if (msg.includes("network") || msg.includes("fetch"))
    return "Network error. Check your connection and try again.";
  return "Something went wrong. Please try again.";
}

// ── shared input styles ────────────────────────────────────────────────────────

const inputCls =
  "w-full px-4 py-3 rounded-xl border border-[var(--border)] bg-[var(--background)] text-[var(--text-primary)] text-sm placeholder:text-[var(--text-secondary)] focus:outline-none focus:ring-2 focus:ring-[var(--primary)] focus:border-transparent transition-all";

const primaryBtn =
  "w-full py-3 rounded-xl bg-[var(--primary)] text-white font-semibold text-sm hover:opacity-90 transition-opacity disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2";

// ── error box ──────────────────────────────────────────────────────────────────

function ErrorBox({ message }: { message: string }) {
  return (
    <div className="px-4 py-3 rounded-xl bg-red-500/10 border border-red-500/20 text-red-500 text-sm flex items-center gap-2">
      <svg width="16" height="16" viewBox="0 0 16 16" fill="currentColor">
        <path d="M8 1a7 7 0 1 0 0 14A7 7 0 0 0 8 1zm.75 4a.75.75 0 0 0-1.5 0v3.5a.75.75 0 0 0 1.5 0V5zm-.75 6a.875.875 0 1 0 0-1.75A.875.875 0 0 0 8 11z"/>
      </svg>
      {message}
    </div>
  );
}

// ── Google button ──────────────────────────────────────────────────────────────

function GoogleButton() {
  const [loading, setLoading] = useState(false);

  const handleClick = async () => {
    setLoading(true);
    const supabase = createClient();
    await supabase.auth.signInWithOAuth({
      provider: "google",
      options: { redirectTo: `${window.location.origin}/api/v1/auth/callback` },
    });
    // browser redirects — no cleanup needed
  };

  return (
    <button
      onClick={handleClick}
      disabled={loading}
      className="flex items-center justify-center gap-3 w-full py-3 px-4 rounded-xl border border-[var(--border)] bg-[var(--background)] text-[var(--text-primary)] font-medium text-sm hover:border-[var(--primary)]/40 hover:shadow-sm transition-all disabled:opacity-50 disabled:cursor-not-allowed"
    >
      <svg width="18" height="18" viewBox="0 0 18 18" fill="none">
        <path d="M17.64 9.205c0-.639-.057-1.252-.164-1.841H9v3.481h4.844a4.14 4.14 0 0 1-1.796 2.716v2.259h2.908c1.702-1.567 2.684-3.875 2.684-6.615Z" fill="#4285F4"/>
        <path d="M9 18c2.43 0 4.467-.806 5.956-2.18l-2.908-2.259c-.806.54-1.837.86-3.048.86-2.344 0-4.328-1.584-5.036-3.711H.957v2.332A8.997 8.997 0 0 0 9 18Z" fill="#34A853"/>
        <path d="M3.964 10.71A5.41 5.41 0 0 1 3.682 9c0-.593.102-1.17.282-1.71V4.958H.957A8.996 8.996 0 0 0 0 9c0 1.452.348 2.827.957 4.042l3.007-2.332Z" fill="#FBBC05"/>
        <path d="M9 3.58c1.321 0 2.508.454 3.44 1.345l2.582-2.58C13.463.891 11.426 0 9 0A8.997 8.997 0 0 0 .957 4.958L3.964 7.29C4.672 5.163 6.656 3.58 9 3.58Z" fill="#EA4335"/>
      </svg>
      {loading ? "Redirecting…" : "Continue with Google"}
    </button>
  );
}

// ── sign-in form ───────────────────────────────────────────────────────────────

function SignInForm() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const router = useRouter();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError(null);

    const supabase = createClient();
    const { error: err } = await supabase.auth.signInWithPassword({ email: email.trim(), password });

    if (err) {
      setError(friendlyError(err.message));
      setLoading(false);
      return;
    }

    // Check onboarding status — new users or users who never finished
    // onboarding should be sent there first.
    try {
      const res = await fetch("/api/v1/user/preferences");
      const { data: prefs } = await res.json();
      if (!prefs?.onboardingComplete) {
        router.push("/onboarding");
      } else {
        router.push("/feed");
      }
    } catch {
      router.push("/feed");
    }
    router.refresh();
  };

  return (
    <form onSubmit={handleSubmit} className="flex flex-col gap-4">
      <input
        type="email"
        placeholder="Email"
        value={email}
        onChange={e => setEmail(e.target.value)}
        required
        className={inputCls}
        autoComplete="email"
      />
      <input
        type="password"
        placeholder="Password"
        value={password}
        onChange={e => setPassword(e.target.value)}
        required
        className={inputCls}
        autoComplete="current-password"
      />
      {error && <ErrorBox message={error} />}
      <button type="submit" disabled={loading} className={primaryBtn}>
        {loading && (
          <svg className="animate-spin h-4 w-4" viewBox="0 0 24 24" fill="none">
            <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"/>
            <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8H4z"/>
          </svg>
        )}
        {loading ? "Signing in…" : "Sign In"}
      </button>
    </form>
  );
}

// ── sign-up form ───────────────────────────────────────────────────────────────

function SignUpForm() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [confirm, setConfirm] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [awaitingConfirm, setAwaitingConfirm] = useState(false);
  const [resending, setResending] = useState(false);
  const [resent, setResent] = useState(false);
  const router = useRouter();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (password !== confirm) { setError("Passwords do not match."); return; }
    if (password.length < 6) { setError("Password must be at least 6 characters."); return; }

    setLoading(true);
    setError(null);

    const supabase = createClient();
    const { data, error: err } = await supabase.auth.signUp({ email: email.trim(), password });

    if (err) {
      setError(friendlyError(err.message));
      setLoading(false);
      return;
    }

    if (data.session) {
      router.push("/onboarding");
      router.refresh();
      return;
    }

    // Email confirmation required — try signing in anyway (handles disabled-confirm projects)
    const { data: signInData } = await supabase.auth.signInWithPassword({ email: email.trim(), password });
    if (signInData.session) {
      router.push("/onboarding");
      router.refresh();
      return;
    }

    setLoading(false);
    setAwaitingConfirm(true);
  };

  const handleResend = async () => {
    setResending(true);
    const supabase = createClient();
    await supabase.auth.resend({ type: "signup", email: email.trim() });
    setResending(false);
    setResent(true);
  };

  if (awaitingConfirm) {
    return (
      <div className="flex flex-col items-center gap-4 py-2 text-center">
        <div className="w-14 h-14 rounded-full bg-[var(--primary)]/10 flex items-center justify-center">
          <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" className="text-[var(--primary)]">
            <path d="M3 8l7.89 5.26a2 2 0 0 0 2.22 0L21 8M5 19h14a2 2 0 0 0 2-2V7a2 2 0 0 0-2-2H5a2 2 0 0 0-2 2v10a2 2 0 0 0 2 2z" strokeLinecap="round" strokeLinejoin="round"/>
          </svg>
        </div>
        <div>
          <p className="font-semibold text-[var(--text-primary)]">Check your inbox</p>
          <p className="text-sm text-[var(--text-secondary)] mt-1 leading-relaxed">
            We sent a confirmation link to<br/>
            <span className="text-[var(--text-primary)] font-medium">{email}</span>
          </p>
        </div>
        {resent ? (
          <p className="text-sm text-[var(--primary)] font-medium flex items-center gap-1.5">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5"><polyline points="20 6 9 17 4 12"/></svg>
            Email resent!
          </p>
        ) : (
          <button
            onClick={handleResend}
            disabled={resending}
            className="text-sm text-[var(--primary)] font-semibold hover:underline disabled:opacity-50"
          >
            {resending ? "Resending…" : "Resend confirmation email"}
          </button>
        )}
        <button
          onClick={() => setAwaitingConfirm(false)}
          className="text-sm text-[var(--text-secondary)] hover:text-[var(--text-primary)] transition-colors"
        >
          Back to sign up
        </button>
      </div>
    );
  }

  return (
    <form onSubmit={handleSubmit} className="flex flex-col gap-4">
      <input
        type="email"
        placeholder="Email"
        value={email}
        onChange={e => setEmail(e.target.value)}
        required
        className={inputCls}
        autoComplete="email"
      />
      <input
        type="password"
        placeholder="Password"
        value={password}
        onChange={e => setPassword(e.target.value)}
        required
        className={inputCls}
        autoComplete="new-password"
      />
      <input
        type="password"
        placeholder="Confirm password"
        value={confirm}
        onChange={e => setConfirm(e.target.value)}
        required
        className={inputCls}
        autoComplete="new-password"
      />
      {error && <ErrorBox message={error} />}
      <button type="submit" disabled={loading} className={primaryBtn}>
        {loading && (
          <svg className="animate-spin h-4 w-4" viewBox="0 0 24 24" fill="none">
            <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"/>
            <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8H4z"/>
          </svg>
        )}
        {loading ? "Creating account…" : "Create Account"}
      </button>
    </form>
  );
}

// ── main login page ────────────────────────────────────────────────────────────

function LoginForm() {
  const [tab, setTab] = useState<"signin" | "signup">("signin");
  const searchParams = useSearchParams();
  const error = searchParams.get("error");

  return (
    <div className="w-full max-w-sm flex flex-col items-center gap-6">
      {/* Logo */}
      <div className="flex flex-col items-center gap-3">
        <div className="flex items-center justify-center w-14 h-14 rounded-2xl bg-[var(--primary)] text-white font-display font-bold text-3xl shadow-[0_4px_20px_rgba(14,196,160,0.3)]">
          N
        </div>
        <div className="text-center">
          <h1 className="text-3xl font-display font-semibold text-[var(--text-primary)]">Nexus</h1>
          <p className="text-sm text-[var(--text-secondary)] mt-1">Geo-contextual news, explored</p>
        </div>
      </div>

      {/* OAuth error from redirect */}
      {error && (
        <ErrorBox message={
          error === "auth_failed" ? "Sign-in failed. Please try again."
          : error === "missing_code" ? "Invalid sign-in link. Please try again."
          : "Something went wrong. Please try again."
        } />
      )}

      {/* Card */}
      <div className="w-full p-6 rounded-2xl bg-[var(--surface)] border border-[var(--border)] flex flex-col gap-5">
        {/* Tab bar */}
        <div className="flex rounded-xl bg-[var(--muted)] p-1 gap-1">
          {(["signin", "signup"] as const).map(t => (
            <button
              key={t}
              onClick={() => setTab(t)}
              className={`flex-1 py-2 rounded-lg text-sm font-semibold transition-all ${
                tab === t
                  ? "bg-[var(--surface)] text-[var(--text-primary)] shadow-sm"
                  : "text-[var(--text-secondary)] hover:text-[var(--text-primary)]"
              }`}
            >
              {t === "signin" ? "Sign In" : "Sign Up"}
            </button>
          ))}
        </div>

        {/* Form */}
        {tab === "signin" ? <SignInForm /> : <SignUpForm />}

        {/* Divider */}
        <div className="flex items-center gap-3">
          <div className="flex-1 h-px bg-[var(--border)]" />
          <span className="text-xs text-[var(--text-secondary)]">or continue with</span>
          <div className="flex-1 h-px bg-[var(--border)]" />
        </div>

        {/* Google */}
        <GoogleButton />
      </div>

      <p className="text-xs text-[var(--text-secondary)] text-center">
        By continuing you agree to our terms of service.
      </p>
    </div>
  );
}

export default function LoginPage() {
  return (
    <Suspense>
      <LoginForm />
    </Suspense>
  );
}
