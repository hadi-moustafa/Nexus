"use client";

import { useState, useEffect } from "react";
import { CreditCard } from "lucide-react";

interface Subscription {
  id: string;
  user_id: string;
  plan: string | null;
  status: string | null;
  start_date: string;
  end_date: string | null;
  auto_renew: boolean;
  trial_ends_at: string | null;
  stripe_customer_id: string | null;
  users: { email: string; display_name: string | null } | null;
}

const STATUS_COLORS: Record<string, string> = {
  active:   "bg-green-500/10 text-green-600",
  trialing: "bg-blue-500/10 text-blue-600",
  past_due: "bg-yellow-500/10 text-yellow-700",
  canceled: "bg-[var(--muted)] text-[var(--text-secondary)]",
};

export default function AdminSubscriptionsPage() {
  const [subs, setSubs] = useState<Subscription[]>([]);
  const [loading, setLoading] = useState(true);
  const [nextCursor, setNextCursor] = useState<string | null>(null);
  const [loadingMore, setLoadingMore] = useState(false);

  const load = async (cursor?: string) => {
    const params = new URLSearchParams({ limit: "50" });
    if (cursor) params.set("cursor", cursor);
    const res = await fetch(`/api/v1/admin/subscriptions?${params}`);
    if (!res.ok) return;
    const { data, meta } = await res.json();
    return { data: data ?? [], nextCursor: meta?.nextCursor ?? null };
  };

  useEffect(() => {
    load()
      .then((result) => {
        if (!result) return;
        setSubs(result.data);
        setNextCursor(result.nextCursor);
      })
      .finally(() => setLoading(false));
  }, []);

  const loadMore = async () => {
    if (!nextCursor || loadingMore) return;
    setLoadingMore(true);
    const result = await load(nextCursor);
    if (result) {
      setSubs((prev) => [...prev, ...result.data]);
      setNextCursor(result.nextCursor);
    }
    setLoadingMore(false);
  };

  const activeCount = subs.filter((s) => s.status === "active" || s.status === "trialing").length;

  return (
    <div>
      <h1 className="font-display text-2xl font-semibold text-[var(--text-primary)] mb-2">
        Subscriptions
      </h1>
      {!loading && (
        <p className="text-sm text-[var(--text-secondary)] mb-6">
          {activeCount} active / trialing out of {subs.length} shown
        </p>
      )}

      <div className="rounded-2xl border border-[var(--border)] bg-[var(--surface)] overflow-hidden">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b border-[var(--border)]">
              <th className="text-left px-5 py-3 text-xs font-medium text-[var(--text-secondary)] uppercase tracking-wide">User</th>
              <th className="text-left px-5 py-3 text-xs font-medium text-[var(--text-secondary)] uppercase tracking-wide hidden sm:table-cell">Plan</th>
              <th className="text-left px-5 py-3 text-xs font-medium text-[var(--text-secondary)] uppercase tracking-wide">Status</th>
              <th className="text-left px-5 py-3 text-xs font-medium text-[var(--text-secondary)] uppercase tracking-wide hidden md:table-cell">Started</th>
              <th className="text-left px-5 py-3 text-xs font-medium text-[var(--text-secondary)] uppercase tracking-wide hidden lg:table-cell">Renews</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-[var(--border)]">
            {loading
              ? Array.from({ length: 5 }).map((_, i) => (
                  <tr key={i} className="animate-pulse">
                    <td className="px-5 py-4">
                      <div className="h-3 w-40 rounded bg-[var(--muted)] mb-1.5" />
                      <div className="h-2.5 w-28 rounded bg-[var(--muted)]" />
                    </td>
                    <td className="px-5 py-4 hidden sm:table-cell"><div className="h-3 w-16 rounded bg-[var(--muted)]" /></td>
                    <td className="px-5 py-4"><div className="h-5 w-16 rounded-full bg-[var(--muted)]" /></td>
                    <td className="px-5 py-4 hidden md:table-cell"><div className="h-3 w-20 rounded bg-[var(--muted)]" /></td>
                    <td className="px-5 py-4 hidden lg:table-cell"><div className="h-3 w-20 rounded bg-[var(--muted)]" /></td>
                  </tr>
                ))
              : subs.map((s) => (
                  <tr key={s.id} className="hover:bg-[var(--muted)] transition-colors">
                    <td className="px-5 py-3">
                      <p className="font-medium text-[var(--text-primary)]">
                        {s.users?.display_name ?? "—"}
                      </p>
                      <p className="text-xs text-[var(--text-secondary)]">{s.users?.email ?? s.user_id}</p>
                    </td>
                    <td className="px-5 py-3 hidden sm:table-cell">
                      <div className="flex items-center gap-1.5 text-[var(--text-secondary)]">
                        <CreditCard size={13} />
                        <span className="capitalize">{s.plan ?? "—"}</span>
                      </div>
                    </td>
                    <td className="px-5 py-3">
                      <span className={`px-2 py-0.5 rounded-full text-xs font-medium capitalize ${
                        STATUS_COLORS[s.status ?? ""] ?? "bg-[var(--muted)] text-[var(--text-secondary)]"
                      }`}>
                        {s.status ?? "unknown"}
                      </span>
                    </td>
                    <td className="px-5 py-3 text-xs text-[var(--text-secondary)] hidden md:table-cell">
                      {new Date(s.start_date).toLocaleDateString()}
                    </td>
                    <td className="px-5 py-3 text-xs text-[var(--text-secondary)] hidden lg:table-cell">
                      {s.end_date ? new Date(s.end_date).toLocaleDateString() : "—"}
                    </td>
                  </tr>
                ))}
          </tbody>
        </table>

        {!loading && subs.length === 0 && (
          <p className="text-sm text-[var(--text-secondary)] text-center py-10">
            No subscriptions yet.
          </p>
        )}
      </div>

      {nextCursor && (
        <button
          onClick={loadMore}
          disabled={loadingMore}
          className="mt-4 text-sm text-[var(--primary)] hover:underline disabled:opacity-50"
        >
          {loadingMore ? "Loading…" : "Load more"}
        </button>
      )}
    </div>
  );
}
