"use client";

import { useState, useEffect, useCallback, useRef } from "react";
import { Navbar } from "@/components/layout/navbar";
import { ArticleCard } from "@/components/feed/article-card";
import { ArticleSkeleton } from "@/components/feed/article-skeleton";
import type { Article } from "@/types";

type Tab = { label: string; icon: string; category: string; language: string };

const TABS: Tab[] = [
  { label: "For You",       icon: "✨", category: "",              language: "" },
  { label: "Lebanon",       icon: "🇱🇧", category: "lebanon",       language: "" },
  { label: "العربية",       icon: "🌐", category: "",              language: "ar" },
  { label: "World",         icon: "🌍", category: "world",         language: "" },
  { label: "Tech",          icon: "💻", category: "technology",    language: "" },
  { label: "Business",      icon: "📈", category: "business",      language: "" },
  { label: "Sports",        icon: "⚽", category: "sports",        language: "" },
  { label: "Science",       icon: "🔬", category: "science",       language: "" },
  { label: "Health",        icon: "❤️", category: "health",        language: "" },
  { label: "Entertainment", icon: "🎬", category: "entertainment", language: "" },
];

function tabKey(tab: Tab) { return `${tab.category}|${tab.language}`; }

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
      .catch(() => { if (!cancelled) setError("Could not load articles. Please try again."); })
      .finally(() => { if (!cancelled) setLoading(false); });

    return () => { cancelled = true; };
  }, [activeTab, fetchArticles]);

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
      { rootMargin: "300px" }
    );
    observer.observe(sentinel);
    return () => observer.disconnect();
  }, [nextCursor, loadingMore, activeTab, fetchArticles]);

  const activeKey = tabKey(activeTab);
  const [hero, ...rest] = articles;

  return (
    <div className="min-h-screen bg-[var(--background)]">
      <Navbar />

      {/* Sticky tab bar */}
      <div
        className="sticky top-14 z-40 border-b border-[var(--border)]"
        style={{ background: "var(--navbar-bg)", backdropFilter: "blur(16px)", WebkitBackdropFilter: "blur(16px)" }}
      >
        <div className="max-w-screen-xl mx-auto px-4 sm:px-6">
          <div className="flex gap-0.5 overflow-x-auto scrollbar-none py-2">
            {TABS.map((tab) => {
              const key = tabKey(tab);
              const isActive = activeKey === key;
              return (
                <button
                  key={key}
                  onClick={() => setActiveTab(tab)}
                  dir={tab.language === "ar" ? "rtl" : undefined}
                  className={`shrink-0 flex items-center gap-1.5 px-3.5 py-1.5 rounded-full text-[13px] font-semibold transition-all ${
                    isActive
                      ? "bg-[var(--primary)] text-white shadow-[0_2px_8px_rgba(14,196,160,0.35)]"
                      : "text-[var(--text-secondary)] hover:text-[var(--text-primary)] hover:bg-[var(--muted)]"
                  }`}
                >
                  <span>{tab.icon}</span>
                  {tab.label}
                </button>
              );
            })}
          </div>
        </div>
      </div>

      {/* Feed content */}
      <main className="max-w-screen-xl mx-auto px-4 sm:px-6 lg:px-8 py-6 pb-24 md:pb-8">

        {loading && (
          <div className="flex flex-col gap-4">
            <ArticleSkeleton variant="hero" />
            <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-3 gap-4">
              {Array.from({ length: 6 }).map((_, i) => <ArticleSkeleton key={i} />)}
            </div>
          </div>
        )}

        {error && !loading && (
          <div className="p-6 text-center border border-[var(--border)] rounded-2xl bg-[var(--surface)]">
            <p className="text-sm text-[var(--text-secondary)] mb-3">{error}</p>
            <button
              onClick={() => setActiveTab({ ...activeTab })}
              className="text-sm font-semibold text-[var(--primary)] hover:underline"
            >
              Retry
            </button>
          </div>
        )}

        {!loading && !error && articles.length === 0 && (
          <div className="p-10 text-center border border-[var(--border)] rounded-2xl bg-[var(--surface)]">
            <p className="text-3xl mb-3">📰</p>
            <p className="text-sm text-[var(--text-secondary)]">No articles found for this category yet.</p>
          </div>
        )}

        {!loading && articles.length > 0 && (
          <div className="flex flex-col gap-4">
            {hero && <ArticleCard article={hero} variant="hero" />}
            {rest.length > 0 && (
              <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-3 gap-4">
                {rest.map((article) => (
                  <ArticleCard key={article.id} article={article} />
                ))}
              </div>
            )}
          </div>
        )}

        <div ref={sentinelRef} className="h-1" />

        {loadingMore && (
          <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-3 gap-4 mt-4">
            {Array.from({ length: 3 }).map((_, i) => <ArticleSkeleton key={i} />)}
          </div>
        )}

        {!loadingMore && !nextCursor && articles.length > 0 && (
          <p className="text-center text-xs text-[var(--text-muted)] mt-10 pb-2">
            You&apos;re all caught up ✓
          </p>
        )}
      </main>
    </div>
  );
}
