"use client";

import { useState, useEffect } from "react";
import { Plus, BadgeCheck } from "lucide-react";

interface Journalist {
  id: string;
  name: string;
  bio: string | null;
  byline_match: string | null;
  is_verified: boolean;
  follower_count: number;
  created_at: string;
}

export default function AdminJournalistsPage() {
  const [journalists, setJournalists] = useState<Journalist[]>([]);
  const [loading, setLoading] = useState(true);
  const [toggling, setToggling] = useState<string | null>(null);
  const [showForm, setShowForm] = useState(false);
  const [form, setForm] = useState({ name: "", byline_match: "", bio: "" });
  const [adding, setAdding] = useState(false);

  useEffect(() => {
    fetch("/api/v1/admin/journalists")
      .then((r) => r.json())
      .then(({ data }) => setJournalists(data ?? []))
      .finally(() => setLoading(false));
  }, []);

  const toggleVerified = async (j: Journalist) => {
    setToggling(j.id);
    const res = await fetch(`/api/v1/admin/journalists/${j.id}`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ is_verified: !j.is_verified }),
    });
    if (res.ok) {
      setJournalists((prev) =>
        prev.map((x) => (x.id === j.id ? { ...x, is_verified: !j.is_verified } : x))
      );
    }
    setToggling(null);
  };

  const addJournalist = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!form.name.trim()) return;
    setAdding(true);
    const res = await fetch("/api/v1/admin/journalists", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        name: form.name.trim(),
        byline_match: form.byline_match.trim() || null,
        bio: form.bio.trim() || null,
      }),
    });
    if (res.ok) {
      const { data } = await res.json();
      setJournalists((prev) => [data, ...prev]);
      setForm({ name: "", byline_match: "", bio: "" });
      setShowForm(false);
    }
    setAdding(false);
  };

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <h1 className="font-display text-2xl font-semibold text-[var(--text-primary)]">
          Journalists
        </h1>
        <button
          onClick={() => setShowForm((v) => !v)}
          className="flex items-center gap-1.5 px-4 py-2 rounded-xl bg-[var(--primary)] text-white text-sm font-medium hover:opacity-90 transition-opacity"
        >
          <Plus size={15} />
          Add journalist
        </button>
      </div>

      {/* Add form */}
      {showForm && (
        <form
          onSubmit={addJournalist}
          className="mb-6 p-4 rounded-2xl border border-[var(--border)] bg-[var(--surface)] flex flex-col gap-3"
        >
          <input
            value={form.name}
            onChange={(e) => setForm((f) => ({ ...f, name: e.target.value }))}
            placeholder="Full name *"
            required
            className="px-3 py-2 rounded-lg border border-[var(--border)] bg-[var(--background)] text-sm text-[var(--text-primary)] focus:outline-none focus:border-[var(--primary)]"
          />
          <input
            value={form.byline_match}
            onChange={(e) => setForm((f) => ({ ...f, byline_match: e.target.value }))}
            placeholder="Byline match (e.g. 'John Doe')"
            className="px-3 py-2 rounded-lg border border-[var(--border)] bg-[var(--background)] text-sm text-[var(--text-primary)] focus:outline-none focus:border-[var(--primary)]"
          />
          <textarea
            value={form.bio}
            onChange={(e) => setForm((f) => ({ ...f, bio: e.target.value }))}
            placeholder="Short bio (optional)"
            rows={2}
            className="px-3 py-2 rounded-lg border border-[var(--border)] bg-[var(--background)] text-sm text-[var(--text-primary)] focus:outline-none focus:border-[var(--primary)] resize-none"
          />
          <button
            type="submit"
            disabled={adding}
            className="self-end px-4 py-2 rounded-lg bg-[var(--primary)] text-white text-sm font-medium hover:opacity-90 disabled:opacity-50 transition-opacity"
          >
            {adding ? "Adding…" : "Add"}
          </button>
        </form>
      )}

      <div className="rounded-2xl border border-[var(--border)] bg-[var(--surface)] overflow-hidden">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b border-[var(--border)]">
              <th className="text-left px-5 py-3 text-xs font-medium text-[var(--text-secondary)] uppercase tracking-wide">Journalist</th>
              <th className="text-left px-5 py-3 text-xs font-medium text-[var(--text-secondary)] uppercase tracking-wide hidden md:table-cell">Byline match</th>
              <th className="text-left px-5 py-3 text-xs font-medium text-[var(--text-secondary)] uppercase tracking-wide">Followers</th>
              <th className="px-5 py-3" />
            </tr>
          </thead>
          <tbody className="divide-y divide-[var(--border)]">
            {loading
              ? Array.from({ length: 4 }).map((_, i) => (
                  <tr key={i} className="animate-pulse">
                    <td className="px-5 py-4"><div className="h-3 w-32 rounded bg-[var(--muted)]" /></td>
                    <td className="px-5 py-4 hidden md:table-cell"><div className="h-3 w-24 rounded bg-[var(--muted)]" /></td>
                    <td className="px-5 py-4"><div className="h-3 w-12 rounded bg-[var(--muted)]" /></td>
                    <td className="px-5 py-4" />
                  </tr>
                ))
              : journalists.map((j) => (
                  <tr key={j.id} className="hover:bg-[var(--muted)] transition-colors">
                    <td className="px-5 py-3">
                      <div className="flex items-center gap-2">
                        <span className="font-medium text-[var(--text-primary)]">{j.name}</span>
                        {j.is_verified && (
                          <BadgeCheck size={14} className="text-[var(--primary)] shrink-0" />
                        )}
                      </div>
                      {j.bio && (
                        <p className="text-xs text-[var(--text-secondary)] mt-0.5 line-clamp-1">
                          {j.bio}
                        </p>
                      )}
                    </td>
                    <td className="px-5 py-3 text-xs text-[var(--text-secondary)] hidden md:table-cell">
                      {j.byline_match ?? "—"}
                    </td>
                    <td className="px-5 py-3 text-sm text-[var(--text-secondary)]">
                      {j.follower_count.toLocaleString()}
                    </td>
                    <td className="px-5 py-3 text-right">
                      <button
                        onClick={() => toggleVerified(j)}
                        disabled={toggling === j.id}
                        className={`text-xs px-2.5 py-1 rounded-lg border transition-colors disabled:opacity-50 ${
                          j.is_verified
                            ? "border-[var(--primary)]/40 text-[var(--primary)] hover:bg-[var(--primary)]/5"
                            : "border-[var(--border)] text-[var(--text-secondary)] hover:text-[var(--primary)] hover:border-[var(--primary)]/40"
                        }`}
                      >
                        {toggling === j.id ? "Saving…" : j.is_verified ? "Unverify" : "Verify"}
                      </button>
                    </td>
                  </tr>
                ))}
          </tbody>
        </table>
        {!loading && journalists.length === 0 && (
          <p className="text-sm text-[var(--text-secondary)] text-center py-10">
            No journalist profiles yet.
          </p>
        )}
      </div>
    </div>
  );
}
