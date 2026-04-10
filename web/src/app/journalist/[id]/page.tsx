"use client";

import { useState, useEffect, useCallback } from "react";
import { useParams, useRouter } from "next/navigation";
import { BadgeCheck, UserPlus, UserMinus, ArrowLeft, Newspaper } from "lucide-react";
import Link from "next/link";
import { Navbar } from "@/components/layout/navbar";
import { ArticleCard } from "@/components/feed/article-card";
import { ArticleSkeleton } from "@/components/feed/article-skeleton";
import type { Article, Journalist } from "@/types";

interface ProfileData {
  journalist: Journalist;
  isFollowing: boolean;
  articles: Article[];
  nextCursor: string | null;
}

export default function JournalistPage() {
  const params = useParams<{ id: string }>();
  const router = useRouter();
  const [data, setData] = useState<ProfileData | null>(null);
  const [loading, setLoading] = useState(true);
  const [notFound, setNotFound] = useState(false);
  const [loadingMore, setLoadingMore] = useState(false);
  const [following, setFollowing] = useState(false);
  const [followPending, setFollowPending] = useState(false);
  const [authed, setAuthed] = useState(false);

  // Check auth status
  useEffect(() => {
    fetch("/api/v1/auth/session")
      .then((r) => r.json())
      .then(({ data: s }) => setAuthed(!!s?.user))
      .catch(() => {});
  }, []);

  useEffect(() => {
    fetch(`/api/v1/journalists/${params.id}`)
      .then((r) => {
        if (r.status === 404) { setNotFound(true); return null; }
        return r.json();
      })
      .then((json) => {
        if (!json) return;
        setData(json.data);
        setFollowing(json.data.isFollowing);
      })
      .catch(() => setNotFound(true))
      .finally(() => setLoading(false));
  }, [params.id]);

  const loadMore = useCallback(async () => {
    if (!data?.nextCursor || loadingMore) return;
    setLoadingMore(true);
    const res = await fetch(`/api/v1/journalists/${params.id}?cursor=${data.nextCursor}&limit=10`);
    if (res.ok) {
      const json = await res.json();
      setData((prev) =>
        prev
          ? { ...prev, articles: [...prev.articles, ...(json.data.articles ?? [])], nextCursor: json.data.nextCursor }
          : prev
      );
    }
    setLoadingMore(false);
  }, [data, params.id, loadingMore]);

  const handleFollow = async () => {
    if (!authed) { router.push("/"); return; }
    if (followPending) return;
    const wasFollowing = following;
    setFollowing(!wasFollowing);
    setFollowPending(true);

    try {
      const res = await fetch(`/api/v1/journalists/${params.id}/follow`, {
        method: wasFollowing ? "DELETE" : "POST",
      });
      if (!res.ok && res.status !== 204 && res.status !== 201 && res.status !== 409) {
        setFollowing(wasFollowing); // rollback
      } else if (!wasFollowing) {
        setData((prev) =>
          prev
            ? {
                ...prev,
                journalist: {
                  ...prev.journalist,
                  followerCount: prev.journalist.followerCount + 1,
                },
              }
            : prev
        );
      } else {
        setData((prev) =>
          prev
            ? {
                ...prev,
                journalist: {
                  ...prev.journalist,
                  followerCount: Math.max(0, prev.journalist.followerCount - 1),
                },
              }
            : prev
        );
      }
    } catch {
      setFollowing(wasFollowing);
    } finally {
      setFollowPending(false);
    }
  };

  if (notFound) {
    return (
      <div className="min-h-screen bg-[var(--background)]">
        <Navbar />
        <div className="max-w-lg mx-auto px-5 pt-24 text-center">
          <p className="text-sm text-[var(--text-secondary)]">Journalist not found.</p>
          <Link href="/feed" className="mt-4 inline-block text-sm text-[var(--primary)] hover:underline">
            Back to feed
          </Link>
        </div>
      </div>
    );
  }

  const journalist = data?.journalist;

  return (
    <div className="min-h-screen bg-[var(--background)]">
      <Navbar />

      <main className="max-w-2xl mx-auto px-5 pb-24 pt-4">
        {/* Back */}
        <Link
          href="/feed"
          className="inline-flex items-center gap-1.5 text-sm text-[var(--text-secondary)] hover:text-[var(--text-primary)] transition-colors mb-6"
        >
          <ArrowLeft size={15} />
          Back
        </Link>

        {/* Profile header */}
        {loading ? (
          <div className="flex items-start gap-4 mb-8 animate-pulse">
            <div className="w-16 h-16 rounded-2xl bg-[var(--muted)] shrink-0" />
            <div className="flex-1 space-y-2">
              <div className="h-5 w-40 rounded bg-[var(--muted)]" />
              <div className="h-3 w-full rounded bg-[var(--muted)]" />
              <div className="h-3 w-3/4 rounded bg-[var(--muted)]" />
            </div>
          </div>
        ) : journalist ? (
          <div className="flex items-start gap-4 mb-8">
            {/* Avatar */}
            <div className="w-16 h-16 rounded-2xl bg-[var(--primary)] flex items-center justify-center shrink-0 overflow-hidden">
              {journalist.avatarUrl ? (
                // eslint-disable-next-line @next/next/no-img-element
                <img src={journalist.avatarUrl} alt={journalist.name} className="w-full h-full object-cover" />
              ) : (
                <span className="text-2xl font-bold text-white">
                  {journalist.name.charAt(0).toUpperCase()}
                </span>
              )}
            </div>

            {/* Info */}
            <div className="flex-1 min-w-0">
              <div className="flex items-center gap-2 mb-1 flex-wrap">
                <h1 className="font-display text-xl font-semibold text-[var(--text-primary)]">
                  {journalist.name}
                </h1>
                {journalist.isVerified && (
                  <BadgeCheck size={18} className="text-[var(--primary)] shrink-0" />
                )}
              </div>

              {journalist.bio && (
                <p className="text-sm text-[var(--text-secondary)] mb-2 leading-relaxed">
                  {journalist.bio}
                </p>
              )}

              <div className="flex items-center gap-4">
                <span className="text-xs text-[var(--text-secondary)]">
                  <span className="font-semibold text-[var(--text-primary)]">
                    {journalist.followerCount.toLocaleString()}
                  </span>{" "}
                  followers
                </span>

                <button
                  onClick={handleFollow}
                  disabled={followPending}
                  className={`flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-semibold transition-all disabled:opacity-60 ${
                    following
                      ? "border border-[var(--border)] text-[var(--text-secondary)] hover:border-red-400/50 hover:text-red-500"
                      : "bg-[var(--primary)] text-white hover:opacity-90"
                  }`}
                >
                  {following ? (
                    <><UserMinus size={13} /> Following</>
                  ) : (
                    <><UserPlus size={13} /> Follow</>
                  )}
                </button>
              </div>
            </div>
          </div>
        ) : null}

        {/* Articles */}
        <div className="flex items-center gap-2 mb-4">
          <Newspaper size={16} className="text-[var(--text-secondary)]" />
          <h2 className="text-sm font-semibold text-[var(--text-primary)]">Articles</h2>
        </div>

        {loading && (
          <div className="flex flex-col gap-3">
            {Array.from({ length: 4 }).map((_, i) => <ArticleSkeleton key={i} />)}
          </div>
        )}

        {!loading && (data?.articles.length ?? 0) === 0 && (
          <p className="text-sm text-[var(--text-secondary)] py-8 text-center">
            No articles found for this journalist.
          </p>
        )}

        {!loading && data && data.articles.length > 0 && (
          <div className="flex flex-col gap-3">
            {data.articles.map((article) => (
              <ArticleCard key={article.id} article={article} />
            ))}
          </div>
        )}

        {data?.nextCursor && (
          <button
            onClick={loadMore}
            disabled={loadingMore}
            className="mt-5 text-sm text-[var(--primary)] hover:underline disabled:opacity-50"
          >
            {loadingMore ? "Loading…" : "Load more articles"}
          </button>
        )}
      </main>
    </div>
  );
}
