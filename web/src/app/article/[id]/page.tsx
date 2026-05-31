import { notFound } from "next/navigation";
import { ArrowLeft, ArrowRight, ExternalLink, Clock, Globe, BadgeCheck } from "lucide-react";
import Link from "next/link";
import { cookies } from "next/headers";
import { getArticleById } from "@/lib/db/articles";
import { createClient } from "@/lib/supabase/server";
import { Navbar } from "@/components/layout/navbar";
import { ReactionsBar } from "@/components/article/reactions-bar";
import { CommentsSection } from "@/components/article/comments-section";
import { ArticleViewTracker } from "@/components/article/view-tracker";
import type { Metadata } from "next";

interface Props {
  params: Promise<{ id: string }>;
}

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { id } = await params;
  const article = await getArticleById(id);
  if (!article) return { title: "Article not found | Nexus" };
  return {
    title: `${article.title} | Nexus`,
    description: article.summary ?? undefined,
    openGraph: {
      title: article.title,
      description: article.summary ?? undefined,
      images: article.imageUrl ? [article.imageUrl] : [],
    },
  };
}

function formatDate(iso: string) {
  return new Date(iso).toLocaleDateString("en-US", {
    month: "long",
    day: "numeric",
    year: "numeric",
  });
}

function estimateReadTime(text: string | null) {
  if (!text) return null;
  const words = text.trim().split(/\s+/).length;
  const mins = Math.max(1, Math.round(words / 200));
  return `${mins} min read`;
}

export default async function ArticlePage({ params }: Props) {
  const { id } = await params;
  const [article, cookieStore] = await Promise.all([getArticleById(id), cookies()]);

  if (!article) notFound();

  const supabase = createClient(cookieStore);
  const { data: { user } } = await supabase.auth.getUser();
  const currentUserId = user?.id ?? null;

  const readTime = estimateReadTime(article.content ?? article.summary);
  const isRtl = article.language === "ar";

  return (
    <div className="min-h-screen bg-[var(--background)]">
      <Navbar />
      {currentUserId && <ArticleViewTracker articleId={article.id} />}

      <main className="max-w-2xl mx-auto px-5 pb-24" dir={isRtl ? "rtl" : undefined}>
        {/* Back button */}
        <div className="py-4">
          <Link
            href="/feed"
            className="inline-flex items-center gap-1.5 text-sm text-[var(--text-secondary)] hover:text-[var(--text-primary)] transition-colors"
          >
            {isRtl ? <ArrowRight size={16} /> : <ArrowLeft size={16} />}
            {isRtl ? "العودة إلى الخلاصة" : "Back to feed"}
          </Link>
        </div>

        {/* Category + meta row */}
        <div className="flex items-center gap-3 mb-4">
          <span className="text-[11px] font-bold uppercase tracking-wider text-[var(--accent)]">
            {article.category}
          </span>
          {article.countryCode && (
            <>
              <span className="text-[var(--border)]">·</span>
              <Link
                href={`/country/${article.countryCode}`}
                className="flex items-center gap-1 text-xs text-[var(--text-secondary)] hover:text-[var(--primary)] transition-colors"
              >
                <Globe size={12} />
                {article.countryCode.toUpperCase()}
              </Link>
            </>
          )}
          {readTime && (
            <>
              <span className="text-[var(--border)]">·</span>
              <span className="flex items-center gap-1 text-xs text-[var(--text-secondary)]">
                <Clock size={12} />
                {readTime}
              </span>
            </>
          )}
        </div>

        {/* Title */}
        <h1 className="font-display text-[28px] font-semibold leading-tight text-[var(--text-primary)] mb-5">
          {article.title}
        </h1>

        {/* Source + journalist + date */}
        <div className="flex items-center gap-3 mb-6 pb-6 border-b border-[var(--border)]">
          <div className="w-8 h-8 rounded-lg border border-[var(--border)] bg-[var(--muted)] flex items-center justify-center shrink-0">
            <span className="text-xs font-bold text-[var(--text-secondary)] uppercase">
              {article.sourceName.charAt(0)}
            </span>
          </div>
          <div className="flex-1 min-w-0">
            <p className="text-sm font-medium text-[var(--text-primary)]">{article.sourceName}</p>
            <div className="flex items-center gap-1.5 text-xs text-[var(--text-secondary)]">
              {article.journalistId && article.journalistName ? (
                <Link
                  href={`/journalist/${article.journalistId}`}
                  className="flex items-center gap-1 text-[var(--primary)] hover:underline"
                >
                  <BadgeCheck size={11} />
                  {article.journalistName}
                </Link>
              ) : null}
              {article.journalistId && (
                <span className="text-[var(--border)]">·</span>
              )}
              <span>{formatDate(article.publishedAt)}</span>
            </div>
          </div>
        </div>

        {/* Hero image */}
        {article.imageUrl && (
          <div className="mb-6 rounded-2xl overflow-hidden bg-[var(--muted)] aspect-video">
            {/* eslint-disable-next-line @next/next/no-img-element */}
            <img
              src={article.imageUrl}
              alt={article.title}
              className="w-full h-full object-cover"
            />
          </div>
        )}

        {/* Article body */}
        <div className="prose prose-sm max-w-none text-[var(--text-primary)]">
          {article.content ? (
            <p className="text-[16px] leading-relaxed text-[var(--text-primary)]">
              {article.content}
            </p>
          ) : article.summary ? (
            <p className="text-[16px] leading-relaxed text-[var(--text-primary)]">
              {article.summary}
            </p>
          ) : (
            <p className="text-[var(--text-secondary)] italic">
              No preview available.
            </p>
          )}
        </div>

        {/* Read full article CTA */}
        <div className="mt-8 pt-6 border-t border-[var(--border)]">
          <a
            href={article.url}
            target="_blank"
            rel="noopener noreferrer"
            className="inline-flex items-center gap-2 px-5 py-3 rounded-xl bg-[var(--primary)] text-white text-sm font-semibold hover:opacity-90 transition-opacity"
          >
            Read full article on {article.sourceName}
            <ExternalLink size={15} />
          </a>
          <p className="mt-3 text-xs text-[var(--text-secondary)]">
            This article is sourced from {article.sourceName}. Nexus shows a preview only.
          </p>
        </div>

        {/* Reactions */}
        <div className="mt-6 pt-6 border-t border-[var(--border)]">
          <p className="text-xs font-medium text-[var(--text-secondary)] mb-3 uppercase tracking-wide">
            React to this story
          </p>
          <ReactionsBar articleId={article.id} currentUserId={currentUserId} />
        </div>

        {/* Comments */}
        <CommentsSection articleId={article.id} currentUserId={currentUserId} />
      </main>
    </div>
  );
}
