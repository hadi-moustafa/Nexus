"use client";

import { useState, useEffect, useCallback } from "react";
import { useRouter } from "next/navigation";
import { Search, Shield, User, ChevronRight } from "lucide-react";
import { requireAdminPage } from "@/lib/admin";

interface AdminUser {
  id: string;
  email: string;
  display_name: string | null;
  role: string;
  created_at: string;
  onboarding_complete?: boolean;
}

// ─── Server guard ────────────────────────────────────────────────────────────
// NOTE: requireAdminPage() is called client-side via the API — the actual
// guard lives in the layout (server component). This page is client-only for
// search + role-toggle UX.

export default function AdminUsersPage() {
  const router = useRouter();
  const [users, setUsers] = useState<AdminUser[]>([]);
  const [query, setQuery] = useState("");
  const [loading, setLoading] = useState(true);
  const [updating, setUpdating] = useState<string | null>(null);

  const loadUsers = useCallback(async (q: string) => {
    setLoading(true);
    const params = new URLSearchParams({ limit: "50" });
    if (q) params.set("q", q);
    const res = await fetch(`/api/v1/admin/users?${params}`);
    if (!res.ok) return;
    const { data } = await res.json();
    setUsers(data ?? []);
    setLoading(false);
  }, []);

  useEffect(() => {
    loadUsers("");
  }, [loadUsers]);

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault();
    loadUsers(query);
  };

  const toggleRole = async (user: AdminUser) => {
    const newRole = user.role === "admin" ? "user" : "admin";
    setUpdating(user.id);
    const res = await fetch(`/api/v1/admin/users/${user.id}`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ role: newRole }),
    });
    if (res.ok) {
      setUsers((prev) =>
        prev.map((u) => (u.id === user.id ? { ...u, role: newRole } : u))
      );
    }
    setUpdating(null);
  };

  return (
    <div>
      <h1 className="font-display text-2xl font-semibold text-[var(--text-primary)] mb-6">
        Users
      </h1>

      {/* Search */}
      <form onSubmit={handleSearch} className="relative mb-6 max-w-sm">
        <Search
          size={16}
          className="absolute left-3 top-1/2 -translate-y-1/2 text-[var(--text-secondary)] pointer-events-none"
        />
        <input
          type="search"
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          placeholder="Search by email or name…"
          className="w-full pl-9 pr-4 py-2.5 rounded-xl border border-[var(--border)] bg-[var(--surface)] text-sm text-[var(--text-primary)] placeholder:text-[var(--text-secondary)] focus:outline-none focus:border-[var(--primary)] transition-colors"
        />
      </form>

      {/* Table */}
      <div className="rounded-2xl border border-[var(--border)] bg-[var(--surface)] overflow-hidden">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b border-[var(--border)]">
              <th className="text-left px-5 py-3 text-xs font-medium text-[var(--text-secondary)] uppercase tracking-wide">User</th>
              <th className="text-left px-5 py-3 text-xs font-medium text-[var(--text-secondary)] uppercase tracking-wide hidden sm:table-cell">Joined</th>
              <th className="text-left px-5 py-3 text-xs font-medium text-[var(--text-secondary)] uppercase tracking-wide">Role</th>
              <th className="px-5 py-3" />
            </tr>
          </thead>
          <tbody className="divide-y divide-[var(--border)]">
            {loading
              ? Array.from({ length: 6 }).map((_, i) => (
                  <tr key={i} className="animate-pulse">
                    <td className="px-5 py-4">
                      <div className="h-3 w-32 rounded bg-[var(--muted)] mb-1.5" />
                      <div className="h-2.5 w-48 rounded bg-[var(--muted)]" />
                    </td>
                    <td className="px-5 py-4 hidden sm:table-cell">
                      <div className="h-3 w-20 rounded bg-[var(--muted)]" />
                    </td>
                    <td className="px-5 py-4">
                      <div className="h-5 w-14 rounded-full bg-[var(--muted)]" />
                    </td>
                    <td className="px-5 py-4" />
                  </tr>
                ))
              : users.map((u) => (
                  <tr key={u.id} className="hover:bg-[var(--muted)] transition-colors">
                    <td className="px-5 py-3">
                      <p className="font-medium text-[var(--text-primary)]">
                        {u.display_name ?? "—"}
                      </p>
                      <p className="text-xs text-[var(--text-secondary)]">{u.email}</p>
                    </td>
                    <td className="px-5 py-3 text-xs text-[var(--text-secondary)] hidden sm:table-cell">
                      {new Date(u.created_at).toLocaleDateString()}
                    </td>
                    <td className="px-5 py-3">
                      <span
                        className={`inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium ${
                          u.role === "admin"
                            ? "bg-[var(--primary)]/10 text-[var(--primary)]"
                            : "bg-[var(--muted)] text-[var(--text-secondary)]"
                        }`}
                      >
                        {u.role === "admin" ? <Shield size={10} /> : <User size={10} />}
                        {u.role}
                      </span>
                    </td>
                    <td className="px-5 py-3 text-right">
                      <div className="flex items-center justify-end gap-3">
                        <button
                          onClick={() => toggleRole(u)}
                          disabled={updating === u.id}
                          className="text-xs text-[var(--primary)] hover:underline disabled:opacity-50"
                        >
                          {updating === u.id
                            ? "Saving…"
                            : u.role === "admin"
                            ? "Demote"
                            : "Make admin"}
                        </button>
                        <button
                          onClick={() => router.push(`/admin/users/${u.id}`)}
                          className="text-[var(--text-secondary)] hover:text-[var(--text-primary)] transition-colors"
                          title="View details"
                        >
                          <ChevronRight size={14} />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
          </tbody>
        </table>

        {!loading && users.length === 0 && (
          <p className="text-sm text-[var(--text-secondary)] text-center py-10">
            No users found.
          </p>
        )}
      </div>
    </div>
  );
}
