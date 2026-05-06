"use client";

import { useState, useEffect, useCallback } from "react";
import { useRouter } from "next/navigation";
import {
  Flame, BookOpen, Trophy, Bookmark, LogOut, ChevronRight,
  User, Lock, CreditCard, Check, X, Loader2, AlertTriangle,
  Zap, Eye, EyeOff,
} from "lucide-react";
import Link from "next/link";
import { Navbar } from "@/components/layout/navbar";
import { ArticleCard } from "@/components/feed/article-card";
import { ArticleSkeleton } from "@/components/feed/article-skeleton";
import type { UserProfile, UserStats, Subscription, Article } from "@/types";

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
function formatDate(iso: string | null | undefined) {
  if (!iso) return "—";
  return new Date(iso).toLocaleDateString("en-US", { month: "short", day: "numeric", year: "numeric" });
}

function StatusBadge({ status }: { status: string }) {
  const styles: Record<string, string> = {
    active:   "bg-green-500/10 text-green-600 border-green-500/20",
    trialing: "bg-blue-500/10 text-blue-600 border-blue-500/20",
    canceled: "bg-red-500/10 text-red-500 border-red-500/20",
    past_due: "bg-yellow-500/10 text-yellow-600 border-yellow-500/20",
  };
  return (
    <span className={`text-[11px] font-semibold uppercase tracking-wide px-2 py-0.5 rounded-full border ${styles[status] ?? styles.canceled}`}>
      {status.replace("_", " ")}
    </span>
  );
}

type Toast = { type: "success" | "error"; text: string };

function ToastBanner({ toast, onDismiss }: { toast: Toast; onDismiss: () => void }) {
  return (
    <div className={`flex items-start gap-3 p-3.5 rounded-xl border text-sm mb-5 ${
      toast.type === "success"
        ? "border-green-400/40 bg-green-500/5 text-green-600"
        : "border-red-400/40 bg-red-500/5 text-red-500"
    }`}>
      {toast.type === "success" ? <Check size={15} className="shrink-0 mt-0.5" /> : <X size={15} className="shrink-0 mt-0.5" />}
      <span className="flex-1">{toast.text}</span>
      <button onClick={onDismiss} className="shrink-0 opacity-60 hover:opacity-100"><X size={14} /></button>
    </div>
  );
}

function StatCard({ icon, label, value }: { icon: React.ReactNode; label: string; value: string | number }) {
  return (
    <div className="flex flex-col items-center gap-1 p-4 rounded-2xl bg-[var(--surface)] border border-[var(--border)]">
      <div className="text-[var(--primary)] mb-1">{icon}</div>
      <span className="text-xl font-semibold text-[var(--text-primary)]">{value}</span>
      <span className="text-xs text-[var(--text-secondary)]">{label}</span>
    </div>
  );
}

type Tab = "overview" | "account" | "subscription" | "bookmarks";

// ---------------------------------------------------------------------------
// Profile Page
// ---------------------------------------------------------------------------
export default function ProfilePage() {
  const router = useRouter();

  // ── Core state
  const [profile, setProfile]             = useState<UserProfile | null>(null);
  const [stats, setStats]                 = useState<UserStats | null>(null);
  const [subscription, setSubscription]   = useState<Subscription | null>(null);
  const [bookmarks, setBookmarks]         = useState<Article[]>([]);
  const [loadingProfile, setLoadingProfile] = useState(true);
  const [bookmarksLoading, setBookmarksLoading] = useState(false);
  const [signingOut, setSigningOut]       = useState(false);
  const [activeTab, setActiveTab]         = useState<Tab>("overview");
  const [toast, setToast]                 = useState<Toast | null>(null);

  // ── Account tab state
  const [displayName, setDisplayName]     = useState("");
  const [savingName, setSavingName]       = useState(false);

  // ── Password state
  const [currentPassword, setCurrentPassword]   = useState("");
  const [newPassword, setNewPassword]           = useState("");
  const [confirmPassword, setConfirmPassword]   = useState("");
  const [showCurrent, setShowCurrent]           = useState(false);
  const [showNew, setShowNew]                   = useState(false);
  const [showConfirm, setShowConfirm]           = useState(false);
  const [savingPassword, setSavingPassword]     = useState(false);

  // ── Subscription state
  const [cancelConfirm, setCancelConfirm] = useState(false);
  const [canceling, setCanceling]         = useState(false);

  const showToast = useCallback((type: "success" | "error", text: string) => {
    setToast({ type, text });
    setTimeout(() => setToast(null), 4000);
  }, []);

  // ── Initial data load
  useEffect(() => {
    const sessionReq = fetch("/api/v1/auth/session").then((r) => r.json());
    const statsReq   = fetch("/api/v1/user/stats").then((r) => r.json());
    const subReq     = fetch("/api/v1/user/subscription").then((r) => r.json());

    Promise.allSettled([sessionReq, statsReq, subReq]).then(([sessionRes, statsRes, subRes]) => {
      if (sessionRes.status === "fulfilled") {
        const user = sessionRes.value?.data;
        if (user) {
          setProfile(user as UserProfile);
          setDisplayName(user.displayName ?? "");
        } else if (sessionRes.value?.error?.code === "UNAUTHORIZED") {
          router.replace("/login");
          return;
        }
      }
      if (statsRes.status === "fulfilled" && statsRes.value?.data) {
        setStats(statsRes.value.data);
      }
      if (subRes.status === "fulfilled" && subRes.value?.data) {
        // Map snake_case from DB response
        const d = subRes.value.data;
        setSubscription({
          id: d.id,
          plan: d.plan,
          status: d.status,
          startDate: d.start_date,
          endDate: d.end_date,
          autoRenew: d.auto_renew,
          trialEndsAt: d.trial_ends_at,
        });
      }
      setLoadingProfile(false);
    });
  }, [router]);

  // ── Load bookmarks when tab activates
  useEffect(() => {
    if (activeTab !== "bookmarks") return;
    setBookmarksLoading(true);
    fetch("/api/v1/user/bookmarks?limit=20")
      .then((r) => r.json())
      .then(({ data }) => setBookmarks((data ?? []).map((b: { article: Article }) => b.article)))
      .catch(console.error)
      .finally(() => setBookmarksLoading(false));
  }, [activeTab]);

  // ── Handlers
  const handleSignOut = async () => {
    setSigningOut(true);
    await fetch("/api/v1/auth/signout", { method: "POST" }).catch(console.error);
    router.replace("/");
  };

  const handleSaveName = async () => {
    if (!displayName.trim()) return;
    setSavingName(true);
    try {
      const res = await fetch("/api/v1/user/profile", {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ displayName: displayName.trim() }),
      });
      const { data, error } = await res.json();
      if (error) { showToast("error", error.message); return; }
      setProfile((p) => p ? { ...p, displayName: data.displayName } : p);
      showToast("success", "Display name updated");
    } catch {
      showToast("error", "Failed to update name");
    } finally {
      setSavingName(false);
    }
  };

  const handleChangePassword = async () => {
    if (newPassword.length < 8) {
      showToast("error", "New password must be at least 8 characters");
      return;
    }
    if (newPassword !== confirmPassword) {
      showToast("error", "Passwords do not match");
      return;
    }
    setSavingPassword(true);
    try {
      const isEmailUser = profile?.provider === "email" || !profile?.provider;
      const body: Record<string, string> = { newPassword };
      if (isEmailUser) body.currentPassword = currentPassword;

      const res = await fetch("/api/v1/auth/change-password", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(body),
      });
      const { error } = await res.json();
      if (error) { showToast("error", error.message); return; }

      setCurrentPassword("");
      setNewPassword("");
      setConfirmPassword("");
      showToast("success", "Password updated successfully");
    } catch {
      showToast("error", "Failed to update password");
    } finally {
      setSavingPassword(false);
    }
  };

  const handleCancelSubscription = async () => {
    setCanceling(true);
    try {
      const res = await fetch("/api/v1/user/subscription", { method: "DELETE" });
      const { error } = await res.json();
      if (error) { showToast("error", error.message); return; }
      setSubscription((s) => s ? { ...s, autoRenew: false } : s);
      setCancelConfirm(false);
      showToast("success", "Subscription will cancel at the end of the billing period");
    } catch {
      showToast("error", "Failed to cancel subscription");
    } finally {
      setCanceling(false);
    }
  };

  const avatarLetter = profile?.displayName?.charAt(0).toUpperCase()
    ?? profile?.email?.charAt(0).toUpperCase()
    ?? "?";

  const isEmailUser = profile?.provider === "email" || !profile?.provider || profile?.provider === undefined;

  // ── Tab definitions
  const TABS: { key: Tab; label: string; icon: React.ReactNode }[] = [
    { key: "overview",     label: "Overview",     icon: <Trophy size={14} /> },
    { key: "account",      label: "Account",      icon: <User size={14} /> },
    { key: "subscription", label: "Subscription", icon: <CreditCard size={14} /> },
    { key: "bookmarks",    label: "Bookmarks",    icon: <Bookmark size={14} /> },
  ];

  return (
    <div className="min-h-screen bg-[var(--background)]">
      <Navbar />

      <main className="max-w-2xl mx-auto px-5 pb-24 pt-6">

        {/* Toast */}
        {toast && <ToastBanner toast={toast} onDismiss={() => setToast(null)} />}

        {/* Avatar + name */}
        <div className={`flex items-center gap-4 mb-6 ${loadingProfile ? "animate-pulse" : ""}`}>
          {/* Avatar with PRO ring */}
          <div className={`relative shrink-0 ${subscription?.status === "active" || subscription?.status === "trialing" ? "p-0.5 rounded-[18px] bg-gradient-to-br from-[var(--primary)] to-purple-500" : ""}`}>
            <div className="w-16 h-16 rounded-2xl bg-[var(--primary)] flex items-center justify-center overflow-hidden">
              {profile?.avatarUrl ? (
                // eslint-disable-next-line @next/next/no-img-element
                <img src={profile.avatarUrl} alt="Avatar" className="w-full h-full object-cover" />
              ) : (
                <span className="text-2xl font-bold text-white">{avatarLetter}</span>
              )}
            </div>
            {(subscription?.status === "active" || subscription?.status === "trialing") && (
              <span className="absolute -bottom-1.5 -right-1.5 flex items-center gap-0.5 bg-[var(--primary)] text-white text-[9px] font-black uppercase tracking-wider px-1.5 py-0.5 rounded-full shadow-sm">
                <Zap size={8} />PRO
              </span>
            )}
          </div>

          <div className="flex-1 min-w-0">
            <div className="flex items-center gap-2 flex-wrap">
              <h1 className="font-display text-xl font-semibold text-[var(--text-primary)] truncate">
                {loadingProfile
                  ? <span className="inline-block h-5 w-36 rounded bg-[var(--muted)]" />
                  : (profile?.displayName ?? profile?.email ?? "—")}
              </h1>
              {(subscription?.status === "active" || subscription?.status === "trialing") && (
                <span className="inline-flex items-center gap-1 bg-gradient-to-r from-[var(--primary)] to-purple-500 text-white text-[10px] font-black uppercase tracking-wider px-2 py-0.5 rounded-full">
                  <Zap size={9} /> Pro
                </span>
              )}
            </div>
            {profile?.displayName && (
              <p className="text-sm text-[var(--text-secondary)] truncate">{profile.email}</p>
            )}
            {!loadingProfile && !subscription && (
              <button
                onClick={() => router.push("/premium")}
                className="text-[10px] font-medium text-[var(--primary)] hover:underline mt-0.5"
              >
                Upgrade to Pro →
              </button>
            )}
          </div>
        </div>

        {/* Tabs */}
        <div className="flex gap-1 mb-6 border-b border-[var(--border)] overflow-x-auto scrollbar-none">
          {TABS.map((tab) => (
            <button
              key={tab.key}
              onClick={() => setActiveTab(tab.key)}
              className={`shrink-0 flex items-center gap-1.5 px-3 py-2.5 text-sm font-medium capitalize transition-colors border-b-2 -mb-px ${
                activeTab === tab.key
                  ? "border-[var(--primary)] text-[var(--primary)]"
                  : "border-transparent text-[var(--text-secondary)] hover:text-[var(--text-primary)]"
              }`}
            >
              {tab.icon}
              {tab.label}
            </button>
          ))}
        </div>

        {/* ── OVERVIEW ── */}
        {activeTab === "overview" && (
          <>
            {/* XP banner */}
            <div className="mb-4 p-4 rounded-2xl bg-gradient-to-r from-[var(--primary)]/10 to-[var(--primary)]/5 border border-[var(--primary)]/20">
              <div className="flex items-center justify-between mb-2">
                <div className="flex items-center gap-2">
                  <Zap size={16} className="text-[var(--primary)]" />
                  <span className="text-sm font-semibold text-[var(--text-primary)]">Total XP</span>
                </div>
                <span className="text-2xl font-bold text-[var(--primary)]">{(stats?.totalXp ?? 0).toLocaleString()}</span>
              </div>
              {/* XP progress to next tier */}
              {(() => {
                const xp = stats?.totalXp ?? 0;
                const tiers = [
                  { name: "Rookie",    min: 0,    max: 500 },
                  { name: "Explorer",  min: 500,  max: 1500 },
                  { name: "Scholar",   min: 1500, max: 3000 },
                  { name: "Expert",    min: 3000, max: 6000 },
                  { name: "Master",    min: 6000, max: 12000 },
                  { name: "Legend",    min: 12000, max: Infinity },
                ];
                const tier = tiers.findLast((t) => xp >= t.min) ?? tiers[0];
                const next = tiers.find((t) => t.min > xp);
                const pct = next ? Math.min(100, Math.round(((xp - tier.min) / (next.min - tier.min)) * 100)) : 100;
                return (
                  <>
                    <div className="flex items-center justify-between text-xs text-[var(--text-secondary)] mb-1">
                      <span className="font-medium text-[var(--primary)]">{tier.name}</span>
                      {next && <span>{next.min - xp} XP to {next.name}</span>}
                    </div>
                    <div className="h-1.5 rounded-full bg-[var(--muted)] overflow-hidden">
                      <div className="h-full rounded-full bg-[var(--primary)] transition-all" style={{ width: `${pct}%` }} />
                    </div>
                  </>
                );
              })()}
            </div>

            {/* Stats grid */}
            <div className="grid grid-cols-3 gap-2 mb-4">
              <StatCard icon={<Flame size={18} />}    label="Day streak"    value={stats?.currentStreak ?? 0} />
              <StatCard icon={<BookOpen size={18} />} label="Articles read" value={stats?.articlesRead ?? 0} />
              <StatCard icon={<Trophy size={18} />}   label="Best streak"   value={stats?.longestStreak ?? 0} />
            </div>

            {/* Quiz stats */}
            <div className="mb-6 rounded-2xl border border-[var(--border)] bg-[var(--surface)] p-4">
              <h3 className="text-xs font-bold uppercase tracking-wider text-[var(--text-secondary)] mb-3">Quiz Stats</h3>
              <div className="grid grid-cols-2 gap-3">
                <div className="flex items-center gap-3">
                  <div className="w-8 h-8 rounded-xl bg-[var(--primary)]/10 flex items-center justify-center shrink-0">
                    <Trophy size={14} className="text-[var(--primary)]" />
                  </div>
                  <div>
                    <p className="text-base font-bold text-[var(--text-primary)]">{stats?.quizzesCompleted ?? 0}</p>
                    <p className="text-xs text-[var(--text-secondary)]">Quizzes done</p>
                  </div>
                </div>
                <div className="flex items-center gap-3">
                  <div className="w-8 h-8 rounded-xl bg-yellow-500/10 flex items-center justify-center shrink-0">
                    <span className="text-sm">⭐</span>
                  </div>
                  <div>
                    <p className="text-base font-bold text-[var(--text-primary)]">{stats?.perfectScores ?? 0}</p>
                    <p className="text-xs text-[var(--text-secondary)]">Perfect scores</p>
                  </div>
                </div>
              </div>
              <button
                onClick={() => router.push("/quiz")}
                className="w-full mt-3 py-2 rounded-xl border border-[var(--border)] text-xs font-medium text-[var(--text-secondary)] hover:text-[var(--primary)] transition-colors flex items-center justify-center gap-1.5"
              >
                Go to Quiz Centre <ChevronRight size={12} />
              </button>
            </div>

            {/* Quick links */}
            <div className="rounded-2xl border border-[var(--border)] bg-[var(--surface)] divide-y divide-[var(--border)] mb-6">
              <button
                onClick={() => setActiveTab("bookmarks")}
                className="w-full flex items-center justify-between px-4 py-3.5 text-sm hover:bg-[var(--muted)] transition-colors"
              >
                <div className="flex items-center gap-2 text-[var(--text-primary)]">
                  <Bookmark size={15} className="text-[var(--primary)]" />
                  Saved articles
                </div>
                <ChevronRight size={15} className="text-[var(--text-secondary)]" />
              </button>
              <button
                onClick={() => setActiveTab("subscription")}
                className="w-full flex items-center justify-between px-4 py-3.5 text-sm hover:bg-[var(--muted)] transition-colors"
              >
                <div className="flex items-center gap-2 text-[var(--text-primary)]">
                  <CreditCard size={15} className="text-[var(--primary)]" />
                  Subscription
                  {subscription?.status && (
                    <StatusBadge status={subscription.status} />
                  )}
                </div>
                <ChevronRight size={15} className="text-[var(--text-secondary)]" />
              </button>
              <Link
                href="/onboarding"
                className="flex items-center justify-between px-4 py-3.5 text-sm hover:bg-[var(--muted)] transition-colors"
              >
                <div className="flex items-center gap-2 text-[var(--text-primary)]">
                  <User size={15} className="text-[var(--primary)]" />
                  Edit news preferences
                </div>
                <ChevronRight size={15} className="text-[var(--text-secondary)]" />
              </Link>
            </div>

            {/* Sign out */}
            <button
              onClick={handleSignOut}
              disabled={signingOut}
              className="w-full flex items-center justify-center gap-2 py-3 rounded-xl border border-[var(--border)] bg-[var(--surface)] text-sm text-[var(--text-secondary)] hover:text-red-500 hover:border-red-400 transition-colors disabled:opacity-60"
            >
              {signingOut ? <Loader2 size={15} className="animate-spin" /> : <LogOut size={15} />}
              {signingOut ? "Signing out…" : "Sign out"}
            </button>
          </>
        )}

        {/* ── ACCOUNT ── */}
        {activeTab === "account" && (
          <div className="flex flex-col gap-5">

            {/* Display name */}
            <section className="rounded-2xl border border-[var(--border)] bg-[var(--surface)] overflow-hidden">
              <div className="px-4 py-3 border-b border-[var(--border)]">
                <h2 className="text-sm font-semibold text-[var(--text-primary)]">Display Name</h2>
                <p className="text-xs text-[var(--text-secondary)] mt-0.5">How your name appears across Nexus</p>
              </div>
              <div className="p-4 flex gap-3">
                <input
                  value={displayName}
                  onChange={(e) => setDisplayName(e.target.value)}
                  maxLength={50}
                  placeholder="Your name"
                  className="flex-1 h-10 px-3 rounded-xl border border-[var(--border)] bg-[var(--muted)] text-sm text-[var(--text-primary)] placeholder:text-[var(--text-secondary)] focus:outline-none focus:border-[var(--primary)] transition-colors"
                />
                <button
                  onClick={handleSaveName}
                  disabled={savingName || !displayName.trim() || displayName.trim() === profile?.displayName}
                  className="h-10 px-4 rounded-xl bg-[var(--primary)] text-white text-sm font-medium hover:opacity-90 transition-opacity disabled:opacity-40 flex items-center gap-1.5"
                >
                  {savingName ? <Loader2 size={14} className="animate-spin" /> : <Check size={14} />}
                  Save
                </button>
              </div>
            </section>

            {/* Email (read-only) */}
            <section className="rounded-2xl border border-[var(--border)] bg-[var(--surface)] overflow-hidden">
              <div className="px-4 py-3 border-b border-[var(--border)]">
                <h2 className="text-sm font-semibold text-[var(--text-primary)]">Email Address</h2>
                <p className="text-xs text-[var(--text-secondary)] mt-0.5">Your sign-in email — cannot be changed here</p>
              </div>
              <div className="p-4">
                <div className="h-10 px-3 rounded-xl border border-[var(--border)] bg-[var(--muted)]/50 text-sm text-[var(--text-secondary)] flex items-center">
                  {profile?.email ?? "—"}
                </div>
              </div>
            </section>

            {/* Password */}
            <section className="rounded-2xl border border-[var(--border)] bg-[var(--surface)] overflow-hidden">
              <div className="px-4 py-3 border-b border-[var(--border)]">
                <h2 className="text-sm font-semibold text-[var(--text-primary)]">
                  {isEmailUser ? "Change Password" : "Set a Password"}
                </h2>
                <p className="text-xs text-[var(--text-secondary)] mt-0.5">
                  {isEmailUser
                    ? "Enter your current password, then choose a new one"
                    : "You signed in with Google — you can also set a password for email sign-in"}
                </p>
              </div>
              <div className="p-4 flex flex-col gap-3">
                {/* Current password — only for email users */}
                {isEmailUser && (
                  <div className="relative">
                    <input
                      type={showCurrent ? "text" : "password"}
                      value={currentPassword}
                      onChange={(e) => setCurrentPassword(e.target.value)}
                      placeholder="Current password"
                      className="w-full h-10 px-3 pr-10 rounded-xl border border-[var(--border)] bg-[var(--muted)] text-sm text-[var(--text-primary)] placeholder:text-[var(--text-secondary)] focus:outline-none focus:border-[var(--primary)] transition-colors"
                    />
                    <button
                      type="button"
                      onClick={() => setShowCurrent(!showCurrent)}
                      className="absolute right-3 top-1/2 -translate-y-1/2 text-[var(--text-secondary)] hover:text-[var(--text-primary)]"
                    >
                      {showCurrent ? <EyeOff size={15} /> : <Eye size={15} />}
                    </button>
                  </div>
                )}

                {/* New password */}
                <div className="relative">
                  <input
                    type={showNew ? "text" : "password"}
                    value={newPassword}
                    onChange={(e) => setNewPassword(e.target.value)}
                    placeholder="New password (min 8 characters)"
                    className="w-full h-10 px-3 pr-10 rounded-xl border border-[var(--border)] bg-[var(--muted)] text-sm text-[var(--text-primary)] placeholder:text-[var(--text-secondary)] focus:outline-none focus:border-[var(--primary)] transition-colors"
                  />
                  <button
                    type="button"
                    onClick={() => setShowNew(!showNew)}
                    className="absolute right-3 top-1/2 -translate-y-1/2 text-[var(--text-secondary)] hover:text-[var(--text-primary)]"
                  >
                    {showNew ? <EyeOff size={15} /> : <Eye size={15} />}
                  </button>
                </div>

                {/* Confirm new password */}
                <div className="relative">
                  <input
                    type={showConfirm ? "text" : "password"}
                    value={confirmPassword}
                    onChange={(e) => setConfirmPassword(e.target.value)}
                    placeholder="Confirm new password"
                    className={`w-full h-10 px-3 pr-10 rounded-xl border bg-[var(--muted)] text-sm text-[var(--text-primary)] placeholder:text-[var(--text-secondary)] focus:outline-none transition-colors ${
                      confirmPassword && confirmPassword !== newPassword
                        ? "border-red-400 focus:border-red-400"
                        : "border-[var(--border)] focus:border-[var(--primary)]"
                    }`}
                  />
                  <button
                    type="button"
                    onClick={() => setShowConfirm(!showConfirm)}
                    className="absolute right-3 top-1/2 -translate-y-1/2 text-[var(--text-secondary)] hover:text-[var(--text-primary)]"
                  >
                    {showConfirm ? <EyeOff size={15} /> : <Eye size={15} />}
                  </button>
                </div>
                {confirmPassword && confirmPassword !== newPassword && (
                  <p className="text-xs text-red-500 -mt-1">Passwords do not match</p>
                )}

                <button
                  onClick={handleChangePassword}
                  disabled={
                    savingPassword ||
                    newPassword.length < 8 ||
                    newPassword !== confirmPassword ||
                    (isEmailUser && !currentPassword)
                  }
                  className="h-10 px-4 rounded-xl bg-[var(--primary)] text-white text-sm font-medium hover:opacity-90 transition-opacity disabled:opacity-40 flex items-center justify-center gap-1.5"
                >
                  {savingPassword ? <Loader2 size={14} className="animate-spin" /> : <Lock size={14} />}
                  {isEmailUser ? "Update Password" : "Set Password"}
                </button>
              </div>
            </section>

            {/* Danger zone — sign out */}
            <button
              onClick={handleSignOut}
              disabled={signingOut}
              className="w-full flex items-center justify-center gap-2 py-3 rounded-xl border border-[var(--border)] bg-[var(--surface)] text-sm text-[var(--text-secondary)] hover:text-red-500 hover:border-red-400 transition-colors disabled:opacity-60"
            >
              {signingOut ? <Loader2 size={15} className="animate-spin" /> : <LogOut size={15} />}
              {signingOut ? "Signing out…" : "Sign out"}
            </button>
          </div>
        )}

        {/* ── SUBSCRIPTION ── */}
        {activeTab === "subscription" && (
          <div className="flex flex-col gap-5">
            {!subscription ? (
              // No subscription
              <div className="rounded-2xl border border-[var(--border)] bg-[var(--surface)] p-6 text-center">
                <div className="w-12 h-12 rounded-2xl bg-[var(--primary)]/10 flex items-center justify-center mx-auto mb-4">
                  <Zap size={22} className="text-[var(--primary)]" />
                </div>
                <h2 className="font-display text-lg font-semibold text-[var(--text-primary)] mb-1">
                  Upgrade to Premium
                </h2>
                <p className="text-sm text-[var(--text-secondary)] mb-5">
                  AI digest, double XP, unlimited bookmarks and more.
                </p>
                <Link
                  href="/premium"
                  className="inline-flex items-center gap-2 px-5 py-2.5 rounded-xl bg-[var(--primary)] text-white text-sm font-semibold hover:opacity-90 transition-opacity"
                >
                  <Zap size={14} />
                  Get Premium
                </Link>
              </div>
            ) : (
              <>
                {/* Plan card */}
                <section className="rounded-2xl border border-[var(--border)] bg-[var(--surface)] overflow-hidden">
                  <div className="px-4 py-3 border-b border-[var(--border)] flex items-center justify-between">
                    <h2 className="text-sm font-semibold text-[var(--text-primary)]">Current Plan</h2>
                    <StatusBadge status={subscription.status} />
                  </div>
                  <div className="divide-y divide-[var(--border)]">
                    <div className="px-4 py-3 flex items-center justify-between text-sm">
                      <span className="text-[var(--text-secondary)]">Plan</span>
                      <span className="font-medium text-[var(--text-primary)] capitalize">
                        {subscription.plan} — {subscription.plan === "monthly" ? "$4.99/mo" : "$39.99/yr"}
                      </span>
                    </div>
                    <div className="px-4 py-3 flex items-center justify-between text-sm">
                      <span className="text-[var(--text-secondary)]">Started</span>
                      <span className="font-medium text-[var(--text-primary)]">{formatDate(subscription.startDate)}</span>
                    </div>
                    {subscription.endDate && (
                      <div className="px-4 py-3 flex items-center justify-between text-sm">
                        <span className="text-[var(--text-secondary)]">
                          {subscription.autoRenew ? "Next billing" : "Access until"}
                        </span>
                        <span className="font-medium text-[var(--text-primary)]">{formatDate(subscription.endDate)}</span>
                      </div>
                    )}
                    <div className="px-4 py-3 flex items-center justify-between text-sm">
                      <span className="text-[var(--text-secondary)]">Auto-renew</span>
                      <span className={`font-medium ${subscription.autoRenew ? "text-green-600" : "text-red-500"}`}>
                        {subscription.autoRenew ? "On" : "Off — cancels at period end"}
                      </span>
                    </div>
                  </div>
                </section>

                {/* Cancel / already canceled */}
                {subscription.status === "active" && subscription.autoRenew && (
                  <section className="rounded-2xl border border-[var(--border)] bg-[var(--surface)] overflow-hidden">
                    <div className="px-4 py-3 border-b border-[var(--border)]">
                      <h2 className="text-sm font-semibold text-[var(--text-primary)]">Cancel Subscription</h2>
                      <p className="text-xs text-[var(--text-secondary)] mt-0.5">
                        You&apos;ll keep Premium access until the end of your billing period
                      </p>
                    </div>
                    <div className="p-4">
                      {!cancelConfirm ? (
                        <button
                          onClick={() => setCancelConfirm(true)}
                          className="w-full py-2.5 rounded-xl border border-red-400/40 text-red-500 text-sm font-medium hover:bg-red-500/5 transition-colors"
                        >
                          Cancel subscription
                        </button>
                      ) : (
                        <div className="flex flex-col gap-3">
                          <div className="flex items-start gap-2.5 p-3 rounded-xl bg-red-500/5 border border-red-400/20">
                            <AlertTriangle size={15} className="text-red-500 shrink-0 mt-0.5" />
                            <p className="text-xs text-red-500">
                              Are you sure? Your subscription will cancel on {formatDate(subscription.endDate)} and you&apos;ll lose Premium features.
                            </p>
                          </div>
                          <div className="flex gap-2">
                            <button
                              onClick={() => setCancelConfirm(false)}
                              className="flex-1 py-2.5 rounded-xl border border-[var(--border)] text-sm text-[var(--text-secondary)] hover:bg-[var(--muted)] transition-colors"
                            >
                              Keep subscription
                            </button>
                            <button
                              onClick={handleCancelSubscription}
                              disabled={canceling}
                              className="flex-1 py-2.5 rounded-xl bg-red-500 text-white text-sm font-medium hover:opacity-90 transition-opacity disabled:opacity-60 flex items-center justify-center gap-1.5"
                            >
                              {canceling ? <Loader2 size={14} className="animate-spin" /> : null}
                              Yes, cancel
                            </button>
                          </div>
                        </div>
                      )}
                    </div>
                  </section>
                )}

                {/* Canceled — show resubscribe option */}
                {(subscription.status === "canceled" || !subscription.autoRenew) && (
                  <div className="rounded-2xl border border-[var(--border)] bg-[var(--surface)] p-4 flex items-center justify-between gap-4">
                    <div>
                      <p className="text-sm font-medium text-[var(--text-primary)]">Want to resubscribe?</p>
                      <p className="text-xs text-[var(--text-secondary)] mt-0.5">Start a new Premium plan anytime</p>
                    </div>
                    <Link
                      href="/premium"
                      className="shrink-0 flex items-center gap-1.5 px-4 py-2 rounded-xl bg-[var(--primary)] text-white text-sm font-medium hover:opacity-90 transition-opacity"
                    >
                      <Zap size={13} /> Resubscribe
                    </Link>
                  </div>
                )}
              </>
            )}
          </div>
        )}

        {/* ── BOOKMARKS ── */}
        {activeTab === "bookmarks" && (
          <>
            {bookmarksLoading && (
              <div className="flex flex-col gap-3">
                {Array.from({ length: 4 }).map((_, i) => <ArticleSkeleton key={i} />)}
              </div>
            )}
            {!bookmarksLoading && bookmarks.length === 0 && (
              <div className="py-16 text-center text-[var(--text-secondary)]">
                <Bookmark size={40} className="mx-auto mb-3 opacity-20" />
                <p className="text-sm">No saved articles yet</p>
                <p className="text-xs mt-1">Bookmark articles from the feed to find them here.</p>
              </div>
            )}
            {!bookmarksLoading && bookmarks.length > 0 && (
              <div className="flex flex-col gap-3">
                {bookmarks.filter(Boolean).map((article) => (
                  <ArticleCard key={article.id} article={article} />
                ))}
              </div>
            )}
          </>
        )}
      </main>
    </div>
  );
}
