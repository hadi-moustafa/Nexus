"use client";

import { useState, useEffect, useCallback, useRef } from "react";
import { Navbar } from "@/components/layout/navbar";
import { ArticleCard } from "@/components/feed/article-card";
import { ArticleSkeleton } from "@/components/feed/article-skeleton";
import type { Article } from "@/types";

// Each tab maps to a set of query params sent to /api/v1/feed.
// `language: "ar"` activates the Arabic-only filter.
// `category: "lebanon"` triggers a keyword search on the backend.
type Tab = { label: string; category: string; language: string };

const TABS: Tab[] = [
  { label: "For You",       category: "",              language: "" },
  { label: "Lebanon",       category: "lebanon",       language: "" },
  { label: "العربية",       category: "",              language: "ar" },
  { label: "World",         category: "world",         language: "" },
  { label: "Tech",          category: "technology",    language: "" },
  { label: "Business",      category: "business",      language: "" },
  { label: "Sports",        category: "sports",        language: "" },
  { label: "Science",       category: "science",       language: "" },
  { label: "Health",        category: "health",        language: "" },
  { label: "Entertainment", category: "entertainment", language: "" },
];

function tabKey(tab: Tab) {
  return `${tab.category}|${tab.language}`;
}

export default function FeedPage() {
  const [activeTab, setActiveTab] = useState<Tab>(TABS[0]);
  const [articles, setArticles] = useState<Article[]>([]);
  const [nextCursor, setNextCursor] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [loadingMore, setLoadingMore] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const sentinelRef = useRef<HTMLDivElement>(null);

  const fetchArticles = useCallback(async (tab: Tab, cursor?: string) => {
    const params = new URLSearchParams({ limit: "20" });
    if (tab.category) params.set("category", tab.category);
    if (tab.language) params.set("language", tab.language);
    if (cursor) params.set("cursor", cursor);

    const res = await fetch(`/api/v1/feed?${params}`);
    if (!res.ok) throw new Error("Failed to fetch articles");
    return res.json() as Promise<{ data: Article[]; meta: { nextCursor: string | null } }>;
  }, []);

  // Reset and reload when tab changes
  useEffect(() => {
    let cancelled = false;
    setLoading(true);
    setError(null);
    setArticles([]);
    setNextCursor(null);

    fetchArticles(activeTab)
      .then(({ data, meta }) => {
        if (cancelled) return;
        setArticles(data);
        setNextCursor(meta.nextCursor);
      })
      .catch(() => {
        if (!cancelled) setError("Could not load articles. Please try again.");
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });

    return () => { cancelled = true; };
  }, [activeTab, fetchArticles]);

  // Infinite scroll
  useEffect(() => {
    if (!nextCursor) return;
    const sentinel = sentinelRef.current;
    if (!sentinel) return;

    const observer = new IntersectionObserver(
      (entries) => {
        if (!entries[0].isIntersecting || loadingMore || !nextCursor) return;
        setLoadingMore(true);
        fetchArticles(activeTab, nextCursor)
          .then(({ data, meta }) => {
            setArticles((prev) => [...prev, ...data]);
            setNextCursor(meta.nextCursor);
          })
          .catch(console.error)
          .finally(() => setLoadingMore(false));
      },
      { rootMargin: "200px" }
    );

    observer.observe(sentinel);
    return () => observer.disconnect();
  }, [nextCursor, loadingMore, activeTab, fetchArticles]);

  const activeKey = tabKey(activeTab);

  return (
    <div className="min-h-screen bg-[var(--background)]">
      <Navbar />

      {/* Tabs */}
      <div className="sticky top-[72px] z-40 bg-[var(--background)] border-b border-[var(--border)]">
        <div className="max-w-2xl mx-auto px-5">
          <div className="flex gap-1 overflow-x-auto py-3 scrollbar-none">
            {TABS.map((tab) => {
              const key = tabKey(tab);
              const isActive = activeKey === key;
              return (
                <button
                  key={key}
                  onClick={() => setActiveTab(tab)}
                  dir={tab.language === "ar" ? "rtl" : undefined}
                  className={`shrink-0 px-4 py-1.5 rounded-full text-sm font-medium transition-all ${
                    isActive
                      ? "bg-[var(--primary)] text-white shadow-sm"
                      : "text-[var(--text-secondary)] hover:text-[var(--text-primary)] hover:bg-[var(--muted)]"
                  }`}
                >
                  {tab.label}
                </button>
              );
            })}
          </div>
        </div>
      </div>

      {/* Feed */}
      <main className="max-w-2xl mx-auto px-5 py-6 pb-24">
        {loading && (
          <div className="flex flex-col gap-3">
            {Array.from({ length: 5 }).map((_, i) => <ArticleSkeleton key={i} />)}
          </div>
        )}

        {error && !loading && (
          <div className="p-5 text-center text-[var(--text-secondary)] border border-[var(--border)] rounded-2xl bg-[var(--surface)]">
            <p className="text-sm">{error}</p>
            <button
              onClick={() => setActiveTab({ ...activeTab })}
              className="mt-3 text-sm text-[var(--primary)] hover:underline"
            >
              Retry
            </button>
          </div>
        )}

        {!loading && !error && articles.length === 0 && (
          <div className="p-5 text-center text-[var(--text-secondary)] border border-[var(--border)] rounded-2xl bg-[var(--surface)]">
            <p className="text-sm">No articles found for this filter yet.</p>
          </div>
        )}

        {!loading && articles.length > 0 && (
          <div className="flex flex-col gap-3">
            {articles.map((article) => (
              <ArticleCard key={article.id} article={article} />
            ))}
          </div>
        )}

        {/* Infinite scroll sentinel */}
        <div ref={sentinelRef} className="h-1" />

        {loadingMore && (
          <div className="flex flex-col gap-3 mt-3">
            <ArticleSkeleton />
            <ArticleSkeleton />
          </div>
        )}

        {!loadingMore && !nextCursor && articles.length > 0 && (
          <p className="text-center text-xs text-[var(--text-secondary)] mt-8">
            You&apos;re all caught up
          </p>
        )}
      </main>
    </div>
  );
}
