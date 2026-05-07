"use client";

import { useEffect, useState, useCallback } from "react";
import { useParams, useRouter } from "next/navigation";
import {
  ArrowLeft, Shield, LogOut, Loader2, Monitor, Smartphone,
  User, Lock, Bookmark, Globe, Trophy, Settings,
} from "lucide-react";
import type { AuditEntry, UserSession } from "@/types";

const ACTION_ICON: Record<string, React.ReactNode> = {
  sign_in:               <Globe size={12} />,
  sign_up:               <User size={12} />,
  sign_out:              <LogOut size={12} />,
  otp_requested:         <Shield size={12} />,
  otp_verified:          <Shield size={12} />,
  password_changed:      <Lock size={12} />,
  profile_updated:       <User size={12} />,
  preferences_updated:   <Settings size={12} />,
  bookmark_added:        <Bookmark size={12} />,
  bookmark_removed:      <Bookmark size={12} />,
  quiz_submitted:        <Trophy size={12} />,
  crossword_submitted:   <Trophy size={12} />,
  session_revoked:       <Monitor size={12} />,
  all_sessions_revoked:  <Globe size={12} />,
  admin_role_changed:    <Shield size={12} />,
  admin_ban:             <Shield size={12} />,
  admin_force_signout:   <LogOut size={12} />,
};

const ACTION_COLOR: Record<string, string> = {
  sign_in:              "bg-green-500/10 text-green-600",
  sign_up:              "bg-blue-500/10 text-blue-600",
  sign_out:             "bg-slate-500/10 text-slate-500",
  password_changed:     "bg-yellow-500/10 text-yellow-600",
  profile_updated:      "bg-[var(--primary)]/10 text-[var(--primary)]",
  preferences_updated:  "bg-[var(--primary)]/10 text-[var(--primary)]",
  bookmark_added:       "bg-purple-500/10 text-purple-600",
  bookmark_removed:     "bg-purple-500/10 text-purple-600",
  admin_ban:            "bg-red-500/10 text-red-500",
  admin_force_signout:  "bg-red-500/10 text-red-500",
};

function getActionColor(action: string) {
  return ACTION_COLOR[action] ?? "bg-[var(--muted)] text-[var(--text-secondary)]";
}

interface AdminUserDetail {
  id: string;
  email: string;
  display_name: string | null;
  role: string;
  created_at: string;
  auth_provider: string | null;
}

export default function AdminUserDetailPage() {
  const { userId } = useParams<{ userId: string }>();
  const router     = useRouter();

  const [user, setUser]             = useState<AdminUserDetail | null>(null);
  const [activity, setActivity]     = useState<AuditEntry[]>([]);
  const [sessions, setSessions]     = useState<UserSession[]>([]);
  const [loading, setLoading]       = useState(true);
  const [forcingOut, setForcingOut] = useState(false);
  const [actCursor, setActCursor]   = useState<string | null>(null);
  const [loadingMore, setLoadingMore] = useState(false);

  const loadActivity = useCallback(async (cursor?: string) => {
    const params = new URLSearchParams({ limit: "30" });
    if (cursor) params.set("cursor", cursor);
    const res = await fetch(`/api/v1/admin/users/${userId}/activity?${params}`);
    const { data, meta } = await res.json();
    if (cursor) {
      setActivity(a => [...a, ...(data ?? [])]);
    } else {
      setActivity(data ?? []);
    }
    setActCursor(meta?.nextCursor ?? null);
  }, [userId]);

  useEffect(() => {
    if (!userId) return;

    const userReq     = fetch(`/api/v1/admin/users?q=${userId}&limit=1`).then(r => r.json());
    const sessionsReq = fetch(`/api/v1/admin/users/${userId}/sessions`).then(r => r.json());

    Promise.all([userReq, sessionsReq, loadActivity()]).then(([uRes, sRes]) => {
      // Try to find the user by ID in the list result
      const users = uRes?.data ?? [];
      const found = users.find((u: AdminUserDetail) => u.id === userId);
      setUser(found ?? null);
      setSessions(sRes?.data ?? []);
      setLoading(false);
    });
  }, [userId, loadActivity]);

  const handleForceSignOut = async () => {
    if (!confirm("Sign this user out from all devices?")) return;
    setForcingOut(true);
    try {
      await fetch(`/api/v1/admin/users/${userId}/sessions`, { method: "DELETE" });
      setSessions([]);
    } catch {
      alert("Failed to force sign-out");
    } finally {
      setForcingOut(false);
    }
  };

  const handleLoadMore = async () => {
    if (!actCursor) return;
    setLoadingMore(true);
    await loadActivity(actCursor);
    setLoadingMore(false);
  };

  if (loading) {
    return (
      <div className="animate-pulse space-y-4">
        <div className="h-6 w-48 rounded bg-[var(--muted)]" />
        <div className="h-32 rounded-2xl bg-[var(--surface)] border border-[var(--border)]" />
        <div className="h-64 rounded-2xl bg-[var(--surface)] border border-[var(--border)]" />
      </div>
    );
  }

  return (
    <div className="max-w-3xl">
      {/* Back */}
      <button
        onClick={() => router.push("/admin/users")}
        className="flex items-center gap-1.5 text-sm text-[var(--text-secondary)] hover:text-[var(--text-primary)] mb-5 transition-colors"
      >
        <ArrowLeft size={14} /> Back to Users
      </button>

      <h1 className="font-display text-2xl font-semibold text-[var(--text-primary)] mb-6">
        User Detail
      </h1>

      {/* User info card */}
      <div className="rounded-2xl border border-[var(--border)] bg-[var(--surface)] overflow-hidden mb-6">
        <div className="px-5 py-4 border-b border-[var(--border)] flex items-center justify-between">
          <h2 className="text-sm font-semibold text-[var(--text-primary)]">Profile</h2>
          <span className={`text-xs font-semibold px-2 py-0.5 rounded-full ${
            user?.role === "admin"
              ? "bg-[var(--primary)]/10 text-[var(--primary)]"
              : user?.role === "banned"
              ? "bg-red-500/10 text-red-500"
              : "bg-[var(--muted)] text-[var(--text-secondary)]"
          }`}>
            {user?.role ?? "user"}
          </span>
        </div>
        <div className="divide-y divide-[var(--border)]">
          {[
            ["ID",           user?.id ?? userId],
            ["Email",        user?.email ?? "—"],
            ["Display name", user?.display_name ?? "—"],
            ["Auth provider", user?.auth_provider ?? "email"],
            ["Joined",       user?.created_at ? new Date(user.created_at).toLocaleDateString("en-US", { year: "numeric", month: "long", day: "numeric" }) : "—"],
          ].map(([label, value]) => (
            <div key={label} className="px-5 py-3 flex items-center justify-between text-sm">
              <span className="text-[var(--text-secondary)]">{label}</span>
              <span className="font-medium text-[var(--text-primary)] break-all text-right ml-4">{value}</span>
            </div>
          ))}
        </div>
      </div>

      {/* Active sessions */}
      <div className="rounded-2xl border border-[var(--border)] bg-[var(--surface)] overflow-hidden mb-6">
        <div className="px-5 py-4 border-b border-[var(--border)] flex items-center justify-between">
          <h2 className="text-sm font-semibold text-[var(--text-primary)]">
            Active Sessions ({sessions.filter(s => !s.isCurrent).length})
          </h2>
          <button
            onClick={handleForceSignOut}
            disabled={forcingOut || sessions.length === 0}
            className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg border border-red-400/40 text-red-500 text-xs font-medium hover:bg-red-500/5 transition-colors disabled:opacity-50"
          >
            {forcingOut ? <Loader2 size={12} className="animate-spin" /> : <LogOut size={12} />}
            Force sign-out
          </button>
        </div>
        {sessions.length === 0 ? (
          <div className="py-6 text-center text-sm text-[var(--text-secondary)]">No active sessions</div>
        ) : (
          <div className="divide-y divide-[var(--border)]">
            {sessions.map(s => {
              const isPhone = s.deviceName === "Android" || s.deviceName === "iOS";
              return (
                <div key={s.id} className="px-5 py-3 flex items-center gap-3 text-sm">
                  <div className="w-7 h-7 rounded-lg bg-[var(--muted)] flex items-center justify-center shrink-0">
                    {isPhone ? <Smartphone size={13} /> : <Monitor size={13} />}
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="font-medium text-[var(--text-primary)] truncate">
                      {s.browser ?? s.deviceName ?? "Unknown"}
                    </p>
                    <p className="text-xs text-[var(--text-secondary)]">
                      {[s.deviceName, s.ipAddress].filter(Boolean).join(" · ")} · Last active{" "}
                      {new Date(s.lastActiveAt).toLocaleDateString()}
                    </p>
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>

      {/* Activity log */}
      <div className="rounded-2xl border border-[var(--border)] bg-[var(--surface)] overflow-hidden">
        <div className="px-5 py-4 border-b border-[var(--border)]">
          <h2 className="text-sm font-semibold text-[var(--text-primary)]">Activity Log</h2>
          <p className="text-xs text-[var(--text-secondary)] mt-0.5">All tracked actions for this user</p>
        </div>
        {activity.length === 0 ? (
          <div className="py-8 text-center text-sm text-[var(--text-secondary)]">No activity recorded yet</div>
        ) : (
          <>
            <div className="divide-y divide-[var(--border)]">
              {activity.map(entry => (
                <div key={entry.id} className="px-5 py-3 flex items-start gap-3">
                  <div className={`mt-0.5 w-5 h-5 rounded-md flex items-center justify-center shrink-0 ${getActionColor(entry.action)}`}>
                    {ACTION_ICON[entry.action] ?? <Globe size={12} />}
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2 flex-wrap">
                      <span className="text-sm font-medium text-[var(--text-primary)] capitalize">
                        {entry.action.replace(/_/g, " ")}
                      </span>
                      {Object.keys(entry.metadata ?? {}).length > 0 && (
                        <span className="text-xs text-[var(--text-secondary)] truncate max-w-xs">
                          {JSON.stringify(entry.metadata)}
                        </span>
                      )}
                    </div>
                    <p className="text-xs text-[var(--text-secondary)] mt-0.5">
                      {new Date(entry.createdAt).toLocaleString()}
                      {entry.ipAddress ? ` · ${entry.ipAddress}` : ""}
                    </p>
                  </div>
                </div>
              ))}
            </div>
            {actCursor && (
              <div className="px-5 py-4 border-t border-[var(--border)]">
                <button
                  onClick={handleLoadMore}
                  disabled={loadingMore}
                  className="w-full py-2 text-sm text-[var(--primary)] font-medium hover:opacity-80 disabled:opacity-50 flex items-center justify-center gap-1.5"
                >
                  {loadingMore && <Loader2 size={13} className="animate-spin" />}
                  Load more
                </button>
              </div>
            )}
          </>
        )}
      </div>
    </div>
  );
}
