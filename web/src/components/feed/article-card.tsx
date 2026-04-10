import Link from "next/link";
import type { Article } from "@/types";

interface ArticleCardProps {
  article: Article;
  /** Show thumbnail image. Default true. */
  showImage?: boolean;
}

/** Formats a published_at ISO string as a relative or absolute date label. */
function formatDate(iso: string): string {
  const diff = Date.now() - new Date(iso).getTime();
  const mins = Math.floor(diff / 60_000);
  if (mins < 60) return `${mins}m ago`;
  const hrs = Math.floor(mins / 60);
  if (hrs < 24) return `${hrs}h ago`;
  return new Date(iso).toLocaleDateString("en-US", { month: "short", day: "numeric" });
}

export function ArticleCard({ article, showImage = true }: ArticleCardProps) {
  const { id, title, summary, imageUrl, publishedAt, sourceName, category, language } = article;
  const isRtl = language === "ar";

  return (
    <Link
      href={`/article/${id}`}
      dir={isRtl ? "rtl" : undefined}
      className="group flex gap-4 p-4 rounded-2xl bg-[var(--surface)] border border-[var(--border)] hover:border-[var(--primary)]/40 hover:shadow-sm transition-all"
    >
      {/* Text content */}
      <div className="flex-1 min-w-0 flex flex-col gap-2">
        {/* Category + time row */}
        <div className="flex items-center justify-between gap-2">
          <span className="text-[10px] font-bold uppercase tracking-wider text-[var(--accent)]">
            {category}
          </span>
          <span className="text-xs text-[var(--text-secondary)] shrink-0">
            {formatDate(publishedAt)}
          </span>
        </div>

        {/* Title */}
        <h3 className="font-display text-[16px] font-semibold leading-snug text-[var(--text-primary)] group-hover:text-[var(--primary)] transition-colors line-clamp-3">
          {title}
        </h3>

        {/* Summary */}
        {summary && (
          <p className="text-sm text-[var(--text-secondary)] leading-relaxed line-clamp-2">
            {summary}
          </p>
        )}

        {/* Source row */}
        <div className="flex items-center gap-2 mt-auto pt-1">
          <div className="w-5 h-5 rounded border border-[var(--border)] bg-[var(--muted)] flex items-center justify-center overflow-hidden shrink-0">
            <span className="text-[9px] font-bold text-[var(--text-secondary)] uppercase">
              {sourceName.charAt(0)}
            </span>
          </div>
          <span className="text-xs font-medium text-[var(--text-secondary)] truncate">
            {sourceName}
          </span>
        </div>
      </div>

      {/* Thumbnail */}
      {showImage && imageUrl && (
        <div className="shrink-0 w-24 h-24 rounded-xl overflow-hidden bg-[var(--muted)]">
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img
            src={imageUrl}
            alt=""
            className="w-full h-full object-cover"
            loading="lazy"
          />
        </div>
      )}
      {showImage && !imageUrl && (
        <div className="shrink-0 w-24 h-24 rounded-xl bg-[var(--muted)] flex items-center justify-center">
          <span className="text-2xl font-display font-bold text-[var(--primary)]/30">N</span>
        </div>
      )}
    </Link>
  );
}
