"use client";

import { useState, useEffect } from "react";
import { Plus, ToggleLeft, ToggleRight } from "lucide-react";

interface Source {
  id: string;
  name: string;
  base_url: string;
  is_active: boolean;
  updated_at: string;
}

export default function AdminSourcesPage() {
  const [sources, setSources] = useState<Source[]>([]);
  const [loading, setLoading] = useState(true);
  const [toggling, setToggling] = useState<string | null>(null);
  const [showForm, setShowForm] = useState(false);
  const [newName, setNewName] = useState("");
  const [newUrl, setNewUrl] = useState("");
  const [adding, setAdding] = useState(false);

  useEffect(() => {
    fetch("/api/v1/admin/sources")
      .then((r) => r.json())
      .then(({ data }) => setSources(data ?? []))
      .finally(() => setLoading(false));
  }, []);

  const toggleActive = async (source: Source) => {
    setToggling(source.id);
    const res = await fetch(`/api/v1/admin/sources/${source.id}`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ is_active: !source.is_active }),
    });
    if (res.ok) {
      setSources((prev) =>
        prev.map((s) => (s.id === source.id ? { ...s, is_active: !s.is_active } : s))
      );
    }
    setToggling(null);
  };

  const addSource = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newName.trim() || !newUrl.trim()) return;
    setAdding(true);
    const res = await fetch("/api/v1/admin/sources", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ name: newName.trim(), base_url: newUrl.trim() }),
    });
    if (res.ok) {
      const { data } = await res.json();
      setSources((prev) => [data, ...prev]);
      setNewName("");
      setNewUrl("");
      setShowForm(false);
    }
    setAdding(false);
  };

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <h1 className="font-display text-2xl font-semibold text-[var(--text-primary)]">
          News Sources
        </h1>
        <button
          onClick={() => setShowForm((v) => !v)}
          className="flex items-center gap-1.5 px-4 py-2 rounded-xl bg-[var(--primary)] text-white text-sm font-medium hover:opacity-90 transition-opacity"
        >
          <Plus size={15} />
          Add source
        </button>
      </div>

      {/* Add form */}
      {showForm && (
        <form
          onSubmit={addSource}
          className="mb-6 p-4 rounded-2xl border border-[var(--border)] bg-[var(--surface)] flex flex-col sm:flex-row gap-3"
        >
          <input
            value={newName}
            onChange={(e) => setNewName(e.target.value)}
            placeholder="Source name"
            required
            className="flex-1 px-3 py-2 rounded-lg border border-[var(--border)] bg-[var(--background)] text-sm text-[var(--text-primary)] focus:outline-none focus:border-[var(--primary)]"
          />
          <input
            value={newUrl}
            onChange={(e) => setNewUrl(e.target.value)}
            placeholder="https://example.com"
            required
            type="url"
            className="flex-1 px-3 py-2 rounded-lg border border-[var(--border)] bg-[var(--background)] text-sm text-[var(--text-primary)] focus:outline-none focus:border-[var(--primary)]"
          />
          <button
            type="submit"
            disabled={adding}
            className="px-4 py-2 rounded-lg bg-[var(--primary)] text-white text-sm font-medium hover:opacity-90 disabled:opacity-50 transition-opacity"
          >
            {adding ? "Adding…" : "Add"}
          </button>
        </form>
      )}

      <div className="rounded-2xl border border-[var(--border)] bg-[var(--surface)] overflow-hidden">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b border-[var(--border)]">
              <th className="text-left px-5 py-3 text-xs font-medium text-[var(--text-secondary)] uppercase tracking-wide">Source</th>
              <th className="text-left px-5 py-3 text-xs font-medium text-[var(--text-secondary)] uppercase tracking-wide hidden md:table-cell">URL</th>
              <th className="text-left px-5 py-3 text-xs font-medium text-[var(--text-secondary)] uppercase tracking-wide">Status</th>
              <th className="px-5 py-3" />
            </tr>
          </thead>
          <tbody className="divide-y divide-[var(--border)]">
            {loading
              ? Array.from({ length: 4 }).map((_, i) => (
                  <tr key={i} className="animate-pulse">
                    <td className="px-5 py-4"><div className="h-3 w-32 rounded bg-[var(--muted)]" /></td>
                    <td className="px-5 py-4 hidden md:table-cell"><div className="h-3 w-48 rounded bg-[var(--muted)]" /></td>
                    <td className="px-5 py-4"><div className="h-5 w-16 rounded-full bg-[var(--muted)]" /></td>
                    <td className="px-5 py-4" />
                  </tr>
                ))
              : sources.map((s) => (
                  <tr key={s.id} className="hover:bg-[var(--muted)] transition-colors">
                    <td className="px-5 py-3 font-medium text-[var(--text-primary)]">{s.name}</td>
                    <td className="px-5 py-3 text-xs text-[var(--text-secondary)] hidden md:table-cell truncate max-w-[240px]">
                      {s.base_url}
                    </td>
                    <td className="px-5 py-3">
                      <span className={`px-2 py-0.5 rounded-full text-xs font-medium ${
                        s.is_active
                          ? "bg-green-500/10 text-green-600"
                          : "bg-[var(--muted)] text-[var(--text-secondary)]"
                      }`}>
                        {s.is_active ? "Active" : "Inactive"}
                      </span>
                    </td>
                    <td className="px-5 py-3 text-right">
                      <button
                        onClick={() => toggleActive(s)}
                        disabled={toggling === s.id}
                        className="text-[var(--text-secondary)] hover:text-[var(--primary)] transition-colors disabled:opacity-50"
                        title={s.is_active ? "Deactivate" : "Activate"}
                      >
                        {s.is_active
                          ? <ToggleRight size={20} className="text-green-500" />
                          : <ToggleLeft size={20} />}
                      </button>
                    </td>
                  </tr>
                ))}
          </tbody>
        </table>
        {!loading && sources.length === 0 && (
          <p className="text-sm text-[var(--text-secondary)] text-center py-10">No sources yet.</p>
        )}
      </div>
    </div>
  );
}
