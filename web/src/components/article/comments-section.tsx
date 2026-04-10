"use client";

import { useState, useEffect, useRef } from "react";
import { MessageCircle, Send, Trash2, ChevronDown } from "lucide-react";

interface Comment {
  id: string;
  body: string;
  createdAt: string;
  editedAt: string | null;
  authorId: string;
  authorName: string;
  authorAvatar: string | null;
}

function relativeTime(iso: string): string {
  const diff = Date.now() - new Date(iso).getTime();
  const mins = Math.floor(diff / 60_000);
  if (mins < 1) return "just now";
  if (mins < 60) return `${mins}m ago`;
  const hours = Math.floor(mins / 60);
  if (hours < 24) return `${hours}h ago`;
  return `${Math.floor(hours / 24)}d ago`;
}

interface Props {
  articleId: string;
  /** userId of the currently signed-in user, or null if anonymous */
  currentUserId: string | null;
}

export function CommentsSection({ articleId, currentUserId }: Props) {
  const [comments, setComments] = useState<Comment[]>([]);
  const [nextCursor, setNextCursor] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [loadingMore, setLoadingMore] = useState(false);
  const [body, setBody] = useState("");
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const textareaRef = useRef<HTMLTextAreaElement>(null);

  useEffect(() => {
    fetch(`/api/v1/articles/${articleId}/comments?limit=10`)
      .then((r) => r.json())
      .then(({ data, meta }) => {
        setComments(data ?? []);
        setNextCursor(meta?.nextCursor ?? null);
      })
      .catch(console.error)
      .finally(() => setLoading(false));
  }, [articleId]);

  const loadMore = () => {
    if (!nextCursor || loadingMore) return;
    setLoadingMore(true);
    fetch(`/api/v1/articles/${articleId}/comments?limit=10&cursor=${nextCursor}`)
      .then((r) => r.json())
      .then(({ data, meta }) => {
        setComments((prev) => [...prev, ...(data ?? [])]);
        setNextCursor(meta?.nextCursor ?? null);
      })
      .catch(console.error)
      .finally(() => setLoadingMore(false));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    const trimmed = body.trim();
    if (!trimmed || submitting) return;

    setSubmitting(true);
    setError(null);
    try {
      const res = await fetch(`/api/v1/articles/${articleId}/comments`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ body: trimmed }),
      });
      if (res.status === 401) {
        setError("Sign in to post a comment.");
        return;
      }
      if (!res.ok) throw new Error("Failed");
      const { data } = await res.json();
      setComments((prev) => [data, ...prev]);
      setBody("");
      if (textareaRef.current) textareaRef.current.style.height = "auto";
    } catch {
      setError("Could not post comment. Try again.");
    } finally {
      setSubmitting(false);
    }
  };

  const handleDelete = async (commentId: string) => {
    try {
      await fetch(`/api/v1/articles/${articleId}/comments/${commentId}`, {
        method: "DELETE",
      });
      setComments((prev) => prev.filter((c) => c.id !== commentId));
    } catch {
      // silent — RLS will enforce the 10-min rule
    }
  };

  const autoResize = (e: React.ChangeEvent<HTMLTextAreaElement>) => {
    setBody(e.target.value);
    const el = e.target;
    el.style.height = "auto";
    el.style.height = `${el.scrollHeight}px`;
  };

  return (
    <section className="mt-8 pt-6 border-t border-[var(--border)]">
      <h2 className="flex items-center gap-2 text-base font-semibold text-[var(--text-primary)] mb-5">
        <MessageCircle size={18} className="text-[var(--primary)]" />
        Comments
        {comments.length > 0 && (
          <span className="text-sm font-normal text-[var(--text-secondary)]">
            ({comments.length}{nextCursor ? "+" : ""})
          </span>
        )}
      </h2>

      {/* Compose box */}
      <form onSubmit={handleSubmit} className="mb-6">
        <div className="relative rounded-xl border border-[var(--border)] bg-[var(--surface)] focus-within:border-[var(--primary)] transition-colors">
          <textarea
            ref={textareaRef}
            value={body}
            onChange={autoResize}
            placeholder={currentUserId ? "Add a comment…" : "Sign in to comment"}
            disabled={!currentUserId || submitting}
            rows={2}
            className="w-full px-4 pt-3 pb-10 resize-none bg-transparent text-sm text-[var(--text-primary)] placeholder:text-[var(--text-secondary)] focus:outline-none disabled:opacity-50"
          />
          <button
            type="submit"
            disabled={!body.trim() || submitting || !currentUserId}
            className="absolute right-3 bottom-3 flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-[var(--primary)] text-white text-xs font-semibold disabled:opacity-40 hover:opacity-90 transition-opacity"
          >
            <Send size={12} />
            {submitting ? "Posting…" : "Post"}
          </button>
        </div>
        {error && <p className="mt-2 text-xs text-red-500">{error}</p>}
      </form>

      {/* Comment list */}
      {loading && (
        <div className="space-y-4">
          {[1, 2, 3].map((i) => (
            <div key={i} className="flex gap-3 animate-pulse">
              <div className="w-8 h-8 rounded-full bg-[var(--muted)] shrink-0" />
              <div className="flex-1 space-y-2">
                <div className="h-3 w-24 rounded bg-[var(--muted)]" />
                <div className="h-3 w-full rounded bg-[var(--muted)]" />
                <div className="h-3 w-3/4 rounded bg-[var(--muted)]" />
              </div>
            </div>
          ))}
        </div>
      )}

      {!loading && comments.length === 0 && (
        <p className="text-sm text-[var(--text-secondary)] text-center py-6">
          No comments yet. Be the first!
        </p>
      )}

      {!loading && comments.length > 0 && (
        <div className="flex flex-col gap-4">
          {comments.map((c) => (
            <div key={c.id} className="flex gap-3">
              {/* Avatar */}
              <div className="w-8 h-8 rounded-full bg-[var(--primary)] flex items-center justify-center shrink-0 overflow-hidden">
                {c.authorAvatar ? (
                  // eslint-disable-next-line @next/next/no-img-element
                  <img src={c.authorAvatar} alt="" className="w-full h-full object-cover" />
                ) : (
                  <span className="text-xs font-bold text-white">
                    {c.authorName.charAt(0).toUpperCase()}
                  </span>
                )}
              </div>

              {/* Body */}
              <div className="flex-1 min-w-0">
                <div className="flex items-baseline gap-2 mb-1">
                  <span className="text-sm font-medium text-[var(--text-primary)]">
                    {c.authorId === currentUserId ? "You" : c.authorName}
                  </span>
                  <span className="text-xs text-[var(--text-secondary)]">
                    {relativeTime(c.createdAt)}
                  </span>
                  {c.editedAt && (
                    <span className="text-xs text-[var(--text-secondary)] italic">edited</span>
                  )}
                </div>
                <p className="text-sm text-[var(--text-primary)] leading-relaxed whitespace-pre-wrap break-words">
                  {c.body}
                </p>
              </div>

              {/* Delete (own comments only) */}
              {c.authorId === currentUserId && (
                <button
                  onClick={() => handleDelete(c.id)}
                  className="shrink-0 text-[var(--text-secondary)] hover:text-red-500 transition-colors mt-0.5"
                  title="Delete comment"
                >
                  <Trash2 size={14} />
                </button>
              )}
            </div>
          ))}
        </div>
      )}

      {/* Load more */}
      {nextCursor && (
        <button
          onClick={loadMore}
          disabled={loadingMore}
          className="mt-5 flex items-center gap-1.5 text-sm text-[var(--primary)] hover:underline disabled:opacity-50"
        >
          <ChevronDown size={15} />
          {loadingMore ? "Loading…" : "Load more comments"}
        </button>
      )}
    </section>
  );
}
