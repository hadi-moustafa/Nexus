"use client";

import { useState, useRef } from "react";
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

// ── shared styles ─────────────────────────────────────────────────────────────

const inputCls =
  "w-full px-4 py-3 rounded-xl border border-[var(--border)] bg-[var(--background)] text-[var(--text-primary)] text-sm placeholder:text-[var(--text-secondary)] focus:outline-none focus:ring-2 focus:ring-[var(--primary)] focus:border-transparent transition-all";

const primaryBtn =
  "w-full py-3 rounded-xl bg-[var(--primary)] text-white font-semibold text-sm hover:opacity-90 transition-opacity disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2";

// ── sub-components ────────────────────────────────────────────────────────────

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

function Spinner() {
  return (
    <svg className="animate-spin h-4 w-4" viewBox="0 0 24 24" fill="none">
      <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"/>
      <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8H4z"/>
    </svg>
  );
}

function GoogleButton() {
  const [loading, setLoading] = useState(false);

  const handleClick = async () => {
    setLoading(true);
    const supabase = createClient();
    await supabase.auth.signInWithOAuth({
      provider: "google",
      options: { redirectTo: `${window.location.origin}/api/v1/auth/callback` },
    });
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
  const [email, setEmail]       = useState("");
  const [password, setPassword] = useState("");
  const [loading, setLoading]   = useState(false);
  const [error, setError]       = useState<string | null>(null);
  const router = useRouter();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError(null);

    const supabase = createClient();
    const { error: err } = await supabase.auth.signInWithPassword({
      email: email.trim(),
      password,
    });

    if (err) {
      setError(friendlyError(err.message));
      setLoading(false);
      return;
    }

    try {
      const res = await fetch("/api/v1/user/preferences");
      const { data: prefs } = await res.json();
      router.push(prefs?.onboardingComplete ? "/feed" : "/onboarding");
    } catch {
      router.push("/feed");
    }
    router.refresh();
  };

  return (
    <form onSubmit={handleSubmit} className="flex flex-col gap-4">
      <input
        type="email" placeholder="Email" value={email}
        onChange={e => setEmail(e.target.value)} required className={inputCls}
        autoComplete="email"
      />
      <input
        type="password" placeholder="Password" value={password}
        onChange={e => setPassword(e.target.value)} required className={inputCls}
        autoComplete="current-password"
      />
      {error && <ErrorBox message={error} />}
      <button type="submit" disabled={loading} className={primaryBtn}>
        {loading && <Spinner />}
        {loading ? "Signing in…" : "Sign In"}
      </button>
    </form>
  );
}

// ── OTP input ─────────────────────────────────────────────────────────────────

function OtpInput({
  email,
  password,
  onVerified,
  onBack,
}: {
  email: string;
  password: string;
  onVerified: () => void;
  onBack: () => void;
}) {
  const [digits, setDigits]   = useState(["", "", "", "", "", ""]);
  const [loading, setLoading] = useState(false);
  const [error, setError]     = useState<string | null>(null);
  const [resending, setResending] = useState(false);
  const [resent, setResent]   = useState(false);
  const inputRefs             = useRef<(HTMLInputElement | null)[]>([]);

  const handleChange = (idx: number, val: string) => {
    if (!/^\d*$/.test(val)) return;
    const next = [...digits];
    next[idx] = val.slice(-1);
    setDigits(next);
    if (val && idx < 5) inputRefs.current[idx + 1]?.focus();
    if (next.every(d => d) && val) {
      void submitOtp(next.join(""));
    }
  };

  const handleKeyDown = (idx: number, e: React.KeyboardEvent) => {
    if (e.key === "Backspace" && !digits[idx] && idx > 0) {
      inputRefs.current[idx - 1]?.focus();
    }
  };

  const handlePaste = (e: React.ClipboardEvent) => {
    const pasted = e.clipboardData.getData("text").replace(/\D/g, "").slice(0, 6);
    if (pasted.length === 6) {
      setDigits(pasted.split(""));
      void submitOtp(pasted);
    }
    e.preventDefault();
  };

  const submitOtp = async (token: string) => {
    setLoading(true);
    setError(null);
    const res = await fetch("/api/v1/auth/otp", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ action: "verify", email, token, password }),
    });
    const json = await res.json();
    if (!res.ok) {
      setError(json.error?.message ?? "Invalid code. Please try again.");
      setDigits(["", "", "", "", "", ""]);
      setLoading(false);
      inputRefs.current[0]?.focus();
      return;
    }
    onVerified();
  };

  const handleResend = async () => {
    setResending(true);
    await fetch("/api/v1/auth/otp", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ action: "send", email }),
    });
    setResending(false);
    setResent(true);
    setTimeout(() => setResent(false), 5000);
  };

  return (
    <div className="flex flex-col items-center gap-5">
      <div className="w-14 h-14 rounded-full bg-[var(--primary)]/10 flex items-center justify-center">
        <svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" className="text-[var(--primary)]">
          <path d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" strokeLinecap="round" strokeLinejoin="round"/>
        </svg>
      </div>
      <div className="text-center">
        <p className="font-semibold text-[var(--text-primary)]">Check your email</p>
        <p className="text-sm text-[var(--text-secondary)] mt-1">
          We sent a 6-digit code to<br/>
          <span className="font-medium text-[var(--text-primary)]">{email}</span>
        </p>
      </div>

      {/* 6-digit inputs */}
      <div className="flex gap-2" onPaste={handlePaste}>
        {digits.map((d, i) => (
          <input
            key={i}
            ref={el => { inputRefs.current[i] = el; }}
            type="text"
            inputMode="numeric"
            maxLength={1}
            value={d}
            onChange={e => handleChange(i, e.target.value)}
            onKeyDown={e => handleKeyDown(i, e)}
            disabled={loading}
            className="w-11 h-12 text-center text-lg font-bold rounded-xl border border-[var(--border)] bg-[var(--background)] text-[var(--text-primary)] focus:outline-none focus:ring-2 focus:ring-[var(--primary)] focus:border-transparent transition-all disabled:opacity-50"
          />
        ))}
      </div>

      {error && <ErrorBox message={error} />}

      {loading && (
        <div className="flex items-center gap-2 text-sm text-[var(--text-secondary)]">
          <Spinner /> Verifying…
        </div>
      )}

      <div className="flex flex-col items-center gap-2 w-full">
        {resent ? (
          <p className="text-sm text-[var(--primary)] font-medium flex items-center gap-1.5">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5"><polyline points="20 6 9 17 4 12"/></svg>
            Code resent!
          </p>
        ) : (
          <button
            onClick={handleResend}
            disabled={resending}
            className="text-sm text-[var(--primary)] font-semibold hover:underline disabled:opacity-50"
          >
            {resending ? "Resending…" : "Resend code"}
          </button>
        )}
        <button
          onClick={onBack}
          className="text-sm text-[var(--text-secondary)] hover:text-[var(--text-primary)] transition-colors"
        >
          Back
        </button>
      </div>
    </div>
  );
}

// ── sign-up form ───────────────────────────────────────────────────────────────

function SignUpForm() {
  const [email, setEmail]       = useState("");
  const [password, setPassword] = useState("");
  const [confirm, setConfirm]   = useState("");
  const [loading, setLoading]   = useState(false);
  const [error, setError]       = useState<string | null>(null);
  const [otpStep, setOtpStep]   = useState(false);
  const router = useRouter();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (password !== confirm) { setError("Passwords do not match."); return; }
    if (password.length < 6)  { setError("Password must be at least 6 characters."); return; }

    setLoading(true);
    setError(null);

    // 1. Check whether this email is already registered
    const checkRes = await fetch("/api/v1/auth/check-email", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ email: email.trim() }),
    });
    const checkJson = await checkRes.json();
    if (checkJson.data?.exists) {
      setError("An account with this email already exists. Please sign in.");
      setLoading(false);
      return;
    }

    // 2. Send OTP via our SMTP
    const sendRes = await fetch("/api/v1/auth/otp", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ action: "send", email: email.trim() }),
    });
    const sendJson = await sendRes.json();
    if (!sendRes.ok) {
      setError(sendJson.error?.message ?? "Failed to send verification code.");
      setLoading(false);
      return;
    }

    setLoading(false);
    setOtpStep(true);
  };

  const handleOtpVerified = () => {
    router.push("/onboarding");
    router.refresh();
  };

  if (otpStep) {
    return (
      <OtpInput
        email={email}
        password={password}
        onVerified={handleOtpVerified}
        onBack={() => setOtpStep(false)}
      />
    );
  }

  return (
    <form onSubmit={handleSubmit} className="flex flex-col gap-4">
      <input
        type="email" placeholder="Email" value={email}
        onChange={e => setEmail(e.target.value)} required className={inputCls}
        autoComplete="email"
      />
      <input
        type="password" placeholder="Password" value={password}
        onChange={e => setPassword(e.target.value)} required className={inputCls}
        autoComplete="new-password"
      />
      <input
        type="password" placeholder="Confirm password" value={confirm}
        onChange={e => setConfirm(e.target.value)} required className={inputCls}
        autoComplete="new-password"
      />
      {error && <ErrorBox message={error} />}
      <button type="submit" disabled={loading} className={primaryBtn}>
        {loading && <Spinner />}
        {loading ? "Sending code…" : "Create Account"}
      </button>
    </form>
  );
}

// ── main login page ────────────────────────────────────────────────────────────

function LoginForm() {
  const [tab, setTab] = useState<"signin" | "signup">("signin");
  const searchParams  = useSearchParams();
  const error         = searchParams.get("error");

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

      {error && (
        <ErrorBox message={
          error === "auth_failed"   ? "Sign-in failed. Please try again."
          : error === "missing_code" ? "Invalid sign-in link. Please try again."
          : "Something went wrong. Please try again."
        } />
      )}

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

        {tab === "signin" ? <SignInForm /> : <SignUpForm />}

        <div className="flex items-center gap-3">
          <div className="flex-1 h-px bg-[var(--border)]" />
          <span className="text-xs text-[var(--text-secondary)]">or continue with</span>
          <div className="flex-1 h-px bg-[var(--border)]" />
        </div>

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
