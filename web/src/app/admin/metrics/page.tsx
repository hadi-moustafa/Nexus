"use client";

import { useEffect, useState } from "react";
import { Users, TrendingUp, UserCheck, Shield, Mail, Globe } from "lucide-react";
import type { AdminUserMetrics } from "@/types";

function StatCard({
  label,
  value,
  sub,
  icon: Icon,
  color,
}: {
  label: string;
  value: number;
  sub?: string;
  icon: React.ElementType;
  color: string;
}) {
  return (
    <div className="p-5 rounded-2xl border border-[var(--border)] bg-[var(--surface)]">
      <Icon size={18} className={`${color} mb-3`} />
      <p className="text-2xl font-bold text-[var(--text-primary)]">{value.toLocaleString()}</p>
      <p className="text-xs text-[var(--text-secondary)] mt-0.5">{label}</p>
      {sub && <p className="text-[11px] text-[var(--text-secondary)] mt-0.5">{sub}</p>}
    </div>
  );
}

function MiniBar({ date, count, max }: { date: string; count: number; max: number }) {
  const pct = max > 0 ? Math.round((count / max) * 100) : 0;
  const label = new Date(date).toLocaleDateString("en-US", { month: "short", day: "numeric" });
  return (
    <div className="flex flex-col items-center gap-1 flex-1 min-w-0">
      <div className="w-full flex flex-col justify-end" style={{ height: 60 }}>
        <div
          className="w-full rounded-t-sm bg-[var(--primary)]"
          style={{ height: `${Math.max(pct, 2)}%` }}
        />
      </div>
      <span className="text-[9px] text-[var(--text-secondary)] rotate-45 origin-left whitespace-nowrap">{label}</span>
    </div>
  );
}

export default function AdminMetricsPage() {
  const [metrics, setMetrics] = useState<AdminUserMetrics | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetch("/api/v1/admin/metrics")
      .then(r => r.json())
      .then(({ data }) => setMetrics(data))
      .catch(console.error)
      .finally(() => setLoading(false));
  }, []);

  if (loading) {
    return (
      <div>
        <h1 className="font-display text-2xl font-semibold text-[var(--text-primary)] mb-8">User Metrics</h1>
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 animate-pulse">
          {Array.from({ length: 8 }).map((_, i) => (
            <div key={i} className="p-5 rounded-2xl border border-[var(--border)] bg-[var(--surface)] h-24" />
          ))}
        </div>
      </div>
    );
  }

  if (!metrics) {
    return (
      <div>
        <h1 className="font-display text-2xl font-semibold text-[var(--text-primary)] mb-8">User Metrics</h1>
        <p className="text-sm text-[var(--text-secondary)]">Failed to load metrics.</p>
      </div>
    );
  }

  const maxDay = Math.max(...metrics.signUpsByDay.map(d => d.count), 1);
  const last7 = metrics.signUpsByDay.slice(-7);

  return (
    <div>
      <h1 className="font-display text-2xl font-semibold text-[var(--text-primary)] mb-8">User Metrics</h1>

      {/* Stat grid */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
        <StatCard label="Total Users"          value={metrics.totalUsers}          icon={Users}      color="text-blue-500" />
        <StatCard label="New (last 7 days)"    value={metrics.newUsersLast7Days}   icon={TrendingUp} color="text-green-500" />
        <StatCard label="New (last 30 days)"   value={metrics.newUsersLast30Days}  icon={TrendingUp} color="text-teal-500" />
        <StatCard label="Active (last 7 days)" value={metrics.activeUsersLast7Days} icon={UserCheck} color="text-purple-500" sub="Sign-ins tracked" />
        <StatCard label="Google sign-ups"      value={metrics.googleUsers}         icon={Globe}      color="text-orange-500" />
        <StatCard label="Email sign-ups"       value={metrics.emailUsers}          icon={Mail}       color="text-sky-500" />
        <StatCard label="Admin accounts"       value={metrics.adminUsers}          icon={Shield}     color="text-[var(--primary)]" />
        <StatCard label="Banned users"         value={metrics.bannedUsers}         icon={Users}      color="text-red-500" />
      </div>

      {/* Sign-ups bar chart — last 30 days */}
      <div className="rounded-2xl border border-[var(--border)] bg-[var(--surface)] p-5 mb-8">
        <h2 className="text-sm font-semibold text-[var(--text-primary)] mb-4">Sign-ups — last 30 days</h2>
        <div className="flex items-end gap-0.5 pb-6 overflow-hidden">
          {metrics.signUpsByDay.map(d => (
            <MiniBar key={d.date} date={d.date} count={d.count} max={maxDay} />
          ))}
        </div>
        <p className="text-xs text-[var(--text-secondary)] mt-1">
          Total this period: <span className="font-semibold text-[var(--text-primary)]">{metrics.newUsersLast30Days.toLocaleString()}</span>
        </p>
      </div>

      {/* Last 7 days detail */}
      <div className="rounded-2xl border border-[var(--border)] bg-[var(--surface)] overflow-hidden">
        <div className="px-5 py-4 border-b border-[var(--border)]">
          <h2 className="text-sm font-semibold text-[var(--text-primary)]">Daily sign-ups — last 7 days</h2>
        </div>
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b border-[var(--border)]">
              <th className="text-left px-5 py-3 text-xs font-medium text-[var(--text-secondary)] uppercase tracking-wide">Date</th>
              <th className="text-right px-5 py-3 text-xs font-medium text-[var(--text-secondary)] uppercase tracking-wide">New Users</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-[var(--border)]">
            {last7.map(d => (
              <tr key={d.date} className="hover:bg-[var(--muted)] transition-colors">
                <td className="px-5 py-3 text-[var(--text-primary)]">
                  {new Date(d.date).toLocaleDateString("en-US", { weekday: "short", month: "short", day: "numeric" })}
                </td>
                <td className="px-5 py-3 text-right font-semibold text-[var(--text-primary)]">
                  {d.count}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
