"use client";

import { useState, useEffect, useCallback } from "react";
import { Trash2, EyeOff, Eye, Flag } from "lucide-react";
import Link from "next/link";

interface AdminComment {
  id: string;
  body: string;
  created_at: string;
  is_held: boolean;
  is_flagged: boolean;
  article_id: string;
  author_id: string;
  users: { display_name: string | null; email: string } | null;
}

type Filter = "all" | "flagged" | "held";

export default function AdminCommentsPage() {
  const [comments, setComments] = useState<AdminComment[]>([]);
  const [filter, setFilter] = useState<Filter>("all");
  const [loading, setLoading] = useState(true);
  const [acting, setActing] = useState<string | null>(null);

  const load = useCallback(async (f: Filter) => {
    setLoading(true);
    const res = await fetch(`/api/v1/admin/comments?filter=${f}&limit=50`);
    if (!res.ok) return;
    const { data } = await res.json();
    setComments(data ?? []);
    setLoading(false);
  }, []);

  useEffect(() => { load(filter); }, [filter, load]);

  const patch = async (id: string, updates: Record<string, boolean>) => {
    setActing(id);
    const res = await fetch(`/api/v1/admin/comments/${id}`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(updates),
    });
    if (res.ok) {
      setComments((prev) =>
        prev.map((c) => (c.id === id ? { ...c, ...updates } : c))
      );
    }
    setActing(null);
  };

  const remove = async (id: string) => {
    setActing(id);
    const res = await fetch(`/api/v1/admin/comments/${id}`, { method: "DELETE" });
    if (res.ok || res.status === 204) {
      setComments((prev) => prev.filter((c) => c.id !== id));
    }
    setActing(null);
  };

  const FILTERS: { value: Filter; label: string }[] = [
    { value: "all",     label: "All" },
    { value: "flagged", label: "Flagged" },
    { value: "held",    label: "Held" },
  ];

  return (
    <div>
      <h1 className="font-display text-2xl font-semibold text-[var(--text-primary)] mb-6">
        Comment Moderation
      </h1>

      {/* Filter chips */}
      <div className="flex gap-2 mb-6">
        {FILTERS.map((f) => (
          <button
            key={f.value}
            onClick={() => setFilter(f.value)}
            className={`px-4 py-1.5 rounded-full text-sm font-medium transition-all ${
              filter === f.value
                ? "bg-[var(--primary)] text-white"
                : "bg-[var(--muted)] text-[var(--text-secondary)] hover:text-[var(--text-primary)]"
            }`}
          >
            {f.label}
          </button>
        ))}
      </div>

      {loading && (
        <div className="space-y-3">
          {Array.from({ length: 4 }).map((_, i) => (
            <div key={i} className="p-4 rounded-2xl border border-[var(--border)] bg-[var(--surface)] animate-pulse">
              <div className="h-3 w-32 rounded bg-[var(--muted)] mb-2" />
              <div className="h-3 w-full rounded bg-[var(--muted)] mb-1" />
              <div className="h-3 w-3/4 rounded bg-[var(--muted)]" />
            </div>
          ))}
        </div>
      )}

      {!loading && comments.length === 0 && (
        <p className="text-sm text-[var(--text-secondary)] text-center py-16">
          No comments to show.
        </p>
      )}

      {!loading && (
        <div className="flex flex-col gap-3">
          {comments.map((c) => (
            <div
              key={c.id}
              className={`p-4 rounded-2xl border bg-[var(--surface)] ${
                c.is_flagged
                  ? "border-red-400/40"
                  : c.is_held
                  ? "border-yellow-400/40"
                  : "border-[var(--border)]"
              }`}
            >
              {/* Meta */}
              <div className="flex items-center gap-2 mb-2 flex-wrap">
                <span className="text-xs font-medium text-[var(--text-primary)]">
                  {c.users?.display_name ?? c.users?.email ?? "Unknown"}
                </span>
                <span className="text-xs text-[var(--text-secondary)]">
                  {new Date(c.created_at).toLocaleString()}
                </span>
                <Link
                  href={`/article/${c.article_id}`}
                  className="text-xs text-[var(--primary)] hover:underline ml-auto"
                  target="_blank"
                >
                  View article →
                </Link>
                {c.is_flagged && (
                  <span className="flex items-center gap-1 text-xs text-red-500 font-medium">
                    <Flag size={11} /> Flagged
                  </span>
                )}
                {c.is_held && (
                  <span className="flex items-center gap-1 text-xs text-yellow-600 font-medium">
                    <EyeOff size={11} /> Held
                  </span>
                )}
              </div>

              {/* Body */}
              <p className="text-sm text-[var(--text-primary)] leading-relaxed mb-3 whitespace-pre-wrap">
                {c.body}
              </p>

              {/* Actions */}
              <div className="flex items-center gap-2">
                <button
                  onClick={() => patch(c.id, { is_held: !c.is_held })}
                  disabled={acting === c.id}
                  className="flex items-center gap-1.5 text-xs px-2.5 py-1 rounded-lg border border-[var(--border)] text-[var(--text-secondary)] hover:text-[var(--text-primary)] transition-colors disabled:opacity-50"
                >
                  {c.is_held ? <Eye size={12} /> : <EyeOff size={12} />}
                  {c.is_held ? "Approve" : "Hold"}
                </button>

                <button
                  onClick={() => patch(c.id, { is_flagged: !c.is_flagged })}
                  disabled={acting === c.id}
                  className="flex items-center gap-1.5 text-xs px-2.5 py-1 rounded-lg border border-[var(--border)] text-[var(--text-secondary)] hover:text-red-500 hover:border-red-400/50 transition-colors disabled:opacity-50"
                >
                  <Flag size={12} />
                  {c.is_flagged ? "Unflag" : "Flag"}
                </button>

                <button
                  onClick={() => remove(c.id)}
                  disabled={acting === c.id}
                  className="flex items-center gap-1.5 text-xs px-2.5 py-1 rounded-lg border border-transparent text-red-500 hover:border-red-400/50 hover:bg-red-500/5 transition-colors disabled:opacity-50 ml-auto"
                >
                  <Trash2 size={12} />
                  Delete
                </button>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
