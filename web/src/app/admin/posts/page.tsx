"use client";

import { useState, useEffect, useCallback } from "react";
import { Search, Trash2, Eye, MessageSquare, Heart, CheckCircle2 } from "lucide-react";

interface AdminPost {
  id: string;
  journalistId: string;
  journalistName: string;
  isVerified: boolean;
  title: string;
  body: string;
  imageUrl: string | null;
  category: string;
  viewCount: number;
  commentCount: number;
  reactionCount: number;
  createdAt: string;
}

export default function AdminPostsPage() {
  const [posts, setPosts] = useState<AdminPost[]>([]);
  const [query, setQuery] = useState("");
  const [loading, setLoading] = useState(true);
  const [deleting, setDeleting] = useState<string | null>(null);
  const [nextCursor, setNextCursor] = useState<string | null>(null);
  const [loadingMore, setLoadingMore] = useState(false);

  const loadPosts = useCallback(async (q: string, replace = true) => {
    replace ? setLoading(true) : setLoadingMore(true);
    const params = new URLSearchParams({ limit: "30" });
    if (q) params.set("q", q);
    const res = await fetch(`/api/v1/admin/posts?${params}`);
    if (res.ok) {
      const json = await res.json();
      if (replace) {
        setPosts(json.data ?? []);
      } else {
        setPosts((prev) => [...prev, ...(json.data ?? [])]);
      }
      setNextCursor(json.meta?.nextCursor ?? null);
    }
    replace ? setLoading(false) : setLoadingMore(false);
  }, []);

  useEffect(() => {
    loadPosts("");
  }, [loadPosts]);

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault();
    loadPosts(query);
  };

  const handleDelete = async (postId: string) => {
    if (!confirm("Delete this post? This cannot be undone.")) return;
    setDeleting(postId);
    const res = await fetch(`/api/v1/admin/posts/${postId}`, { method: "DELETE" });
    if (res.ok || res.status === 204) {
      setPosts((prev) => prev.filter((p) => p.id !== postId));
    }
    setDeleting(null);
  };

  const loadMore = () => {
    if (!nextCursor || loadingMore) return;
    const params = new URLSearchParams({ limit: "30", cursor: nextCursor });
    if (query) params.set("q", query);
    fetch(`/api/v1/admin/posts?${params}`)
      .then((r) => r.json())
      .then((json) => {
        setPosts((prev) => [...prev, ...(json.data ?? [])]);
        setNextCursor(json.meta?.nextCursor ?? null);
        setLoadingMore(false);
      });
    setLoadingMore(true);
  };

  return (
    <div>
      <h1 className="font-display text-2xl font-semibold text-[var(--text-primary)] mb-6">
        Journalist Posts
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
          placeholder="Search by title…"
          className="w-full pl-9 pr-4 py-2.5 rounded-xl border border-[var(--border)] bg-[var(--surface)] text-sm text-[var(--text-primary)] placeholder:text-[var(--text-secondary)] focus:outline-none focus:border-[var(--primary)] transition-colors"
        />
      </form>

      {/* Table */}
      <div className="rounded-2xl border border-[var(--border)] bg-[var(--surface)] overflow-hidden">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b border-[var(--border)]">
              <th className="text-left px-5 py-3 text-xs font-medium text-[var(--text-secondary)] uppercase tracking-wide">Post</th>
              <th className="text-left px-5 py-3 text-xs font-medium text-[var(--text-secondary)] uppercase tracking-wide hidden md:table-cell">Journalist</th>
              <th className="text-left px-5 py-3 text-xs font-medium text-[var(--text-secondary)] uppercase tracking-wide hidden sm:table-cell">Category</th>
              <th className="text-left px-5 py-3 text-xs font-medium text-[var(--text-secondary)] uppercase tracking-wide hidden lg:table-cell">Stats</th>
              <th className="text-left px-5 py-3 text-xs font-medium text-[var(--text-secondary)] uppercase tracking-wide hidden sm:table-cell">Date</th>
              <th className="px-5 py-3" />
            </tr>
          </thead>
          <tbody className="divide-y divide-[var(--border)]">
            {loading
              ? Array.from({ length: 6 }).map((_, i) => (
                  <tr key={i} className="animate-pulse">
                    <td className="px-5 py-4">
                      <div className="h-3 w-48 rounded bg-[var(--muted)] mb-1.5" />
                      <div className="h-2.5 w-64 rounded bg-[var(--muted)]" />
                    </td>
                    <td className="px-5 py-4 hidden md:table-cell">
                      <div className="h-3 w-24 rounded bg-[var(--muted)]" />
                    </td>
                    <td className="px-5 py-4 hidden sm:table-cell">
                      <div className="h-5 w-16 rounded-full bg-[var(--muted)]" />
                    </td>
                    <td className="px-5 py-4 hidden lg:table-cell">
                      <div className="h-3 w-20 rounded bg-[var(--muted)]" />
                    </td>
                    <td className="px-5 py-4 hidden sm:table-cell">
                      <div className="h-3 w-20 rounded bg-[var(--muted)]" />
                    </td>
                    <td className="px-5 py-4" />
                  </tr>
                ))
              : posts.map((p) => (
                  <tr key={p.id} className="hover:bg-[var(--muted)] transition-colors">
                    <td className="px-5 py-3 max-w-xs">
                      <p className="font-medium text-[var(--text-primary)] truncate">{p.title}</p>
                      <p className="text-xs text-[var(--text-secondary)] line-clamp-2 mt-0.5">{p.body}</p>
                    </td>
                    <td className="px-5 py-3 hidden md:table-cell">
                      <span className="flex items-center gap-1 text-sm text-[var(--text-primary)]">
                        {p.journalistName}
                        {p.isVerified && <CheckCircle2 size={12} className="text-teal-500 shrink-0" />}
                      </span>
                    </td>
                    <td className="px-5 py-3 hidden sm:table-cell">
                      <span className="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium bg-[var(--muted)] text-[var(--text-secondary)] capitalize">
                        {p.category}
                      </span>
                    </td>
                    <td className="px-5 py-3 hidden lg:table-cell">
                      <div className="flex items-center gap-3 text-xs text-[var(--text-secondary)]">
                        <span className="flex items-center gap-1"><Eye size={11} />{p.viewCount}</span>
                        <span className="flex items-center gap-1"><Heart size={11} />{p.reactionCount}</span>
                        <span className="flex items-center gap-1"><MessageSquare size={11} />{p.commentCount}</span>
                      </div>
                    </td>
                    <td className="px-5 py-3 hidden sm:table-cell text-xs text-[var(--text-secondary)]">
                      {new Date(p.createdAt).toLocaleDateString()}
                    </td>
                    <td className="px-5 py-3 text-right">
                      {deleting === p.id ? (
                        <span className="text-xs text-[var(--text-secondary)]">Deleting…</span>
                      ) : (
                        <button
                          onClick={() => handleDelete(p.id)}
                          className="text-red-400 hover:text-red-500 transition-colors"
                          title="Delete post"
                        >
                          <Trash2 size={15} />
                        </button>
                      )}
                    </td>
                  </tr>
                ))}
          </tbody>
        </table>

        {!loading && posts.length === 0 && (
          <p className="text-sm text-[var(--text-secondary)] text-center py-10">
            No posts found.
          </p>
        )}
      </div>

      {nextCursor && (
        <div className="mt-4 flex justify-center">
          <button
            onClick={loadMore}
            disabled={loadingMore}
            className="px-4 py-2 rounded-xl border border-[var(--border)] text-sm text-[var(--text-secondary)] hover:bg-[var(--muted)] transition-colors disabled:opacity-50"
          >
            {loadingMore ? "Loading…" : "Load more"}
          </button>
        </div>
      )}
    </div>
  );
}
