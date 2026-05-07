import Link from "next/link";
import type { Article } from "@/types";

export type CardVariant = "hero" | "featured" | "compact" | "default";

interface ArticleCardProps {
  article: Article;
  variant?: CardVariant;
  showImage?: boolean;
  index?: number;
}

function formatDate(iso: string): string {
  const diff = Date.now() - new Date(iso).getTime();
  const mins = Math.floor(diff / 60_000);
  if (mins < 60) return `${mins}m ago`;
  const hrs = Math.floor(mins / 60);
  if (hrs < 24) return `${hrs}h ago`;
  return new Date(iso).toLocaleDateString("en-US", { month: "short", day: "numeric" });
}

const CAT_CLASSES: Record<string, { text: string; bg: string }> = {
  world:         { text: "text-blue-700 dark:text-blue-400",    bg: "bg-blue-50 dark:bg-blue-950/40" },
  technology:    { text: "text-violet-700 dark:text-violet-400",bg: "bg-violet-50 dark:bg-violet-950/40" },
  business:      { text: "text-emerald-700 dark:text-emerald-400", bg: "bg-emerald-50 dark:bg-emerald-950/40" },
  sports:        { text: "text-amber-700 dark:text-amber-400",  bg: "bg-amber-50 dark:bg-amber-950/40" },
  science:       { text: "text-sky-700 dark:text-sky-400",      bg: "bg-sky-50 dark:bg-sky-950/40" },
  health:        { text: "text-rose-700 dark:text-rose-400",    bg: "bg-rose-50 dark:bg-rose-950/40" },
  entertainment: { text: "text-fuchsia-700 dark:text-fuchsia-400", bg: "bg-fuchsia-50 dark:bg-fuchsia-950/40" },
  lebanon:       { text: "text-green-700 dark:text-green-400",  bg: "bg-green-50 dark:bg-green-950/40" },
};

function CategoryBadge({ category, light = false }: { category: string; light?: boolean }) {
  const key = category?.toLowerCase() ?? "";
  if (light) {
    return (
      <span className="text-[10px] font-bold uppercase tracking-widest text-white/90 bg-white/20 backdrop-blur-sm px-2 py-0.5 rounded-full">
        {category}
      </span>
    );
  }
  const cls = CAT_CLASSES[key] ?? { text: "text-[var(--primary)]", bg: "bg-[var(--primary-muted)]" };
  return (
    <span className={`text-[10px] font-bold uppercase tracking-widest px-2.5 py-0.5 rounded-full ${cls.text} ${cls.bg}`}>
      {category}
    </span>
  );
}

function SourceRow({ sourceName, publishedAt }: { sourceName: string; publishedAt: string }) {
  return (
    <div className="flex items-center gap-2">
      <div className="w-5 h-5 rounded-md bg-[var(--muted)] border border-[var(--border)] flex items-center justify-center shrink-0">
        <span className="text-[9px] font-bold text-[var(--text-secondary)] uppercase leading-none">
          {sourceName.charAt(0)}
        </span>
      </div>
      <span className="text-xs font-medium text-[var(--text-secondary)] truncate">{sourceName}</span>
      <span className="text-[var(--text-muted)] text-xs shrink-0">·</span>
      <span className="text-xs text-[var(--text-muted)] shrink-0">{formatDate(publishedAt)}</span>
    </div>
  );
}

/* ── HERO — full-width card with overlaid text on image ─────── */
function HeroCard({ article }: { article: Article }) {
  const { id, title, summary, imageUrl, publishedAt, sourceName, category, language } = article;
  const isRtl = language === "ar";

  return (
    <Link
      href={`/article/${id}`}
      dir={isRtl ? "rtl" : undefined}
      className="group block rounded-2xl overflow-hidden bg-[var(--surface)] border border-[var(--border)] shadow-[var(--shadow-card)] card-lift"
    >
      {/* Image with overlay text */}
      <div className="relative w-full aspect-[16/9] overflow-hidden bg-[var(--muted)] img-zoom">
        {imageUrl
          ? <img src={imageUrl} alt="" className="w-full h-full object-cover" loading="eager" />
          : (
            <div className="w-full h-full flex items-center justify-center bg-gradient-to-br from-[var(--muted)] to-[var(--surface-2)]">
              <span className="text-7xl font-display font-bold text-[var(--primary)]/15">N</span>
            </div>
          )
        }
        <div className="absolute inset-0 hero-overlay" />
        <div className="absolute bottom-0 left-0 right-0 p-5 sm:p-6">
          <div className="mb-2.5"><CategoryBadge category={category} light /></div>
          <h2 className="font-display text-xl sm:text-2xl lg:text-3xl font-bold leading-tight text-white line-clamp-3 mb-3">
            {title}
          </h2>
          <div className="flex items-center gap-2">
            <div className="w-4 h-4 rounded bg-white/20 flex items-center justify-center">
              <span className="text-[8px] font-bold text-white uppercase">{sourceName.charAt(0)}</span>
            </div>
            <span className="text-xs font-medium text-white/80">{sourceName}</span>
            <span className="text-white/40 text-xs">·</span>
            <span className="text-xs text-white/60">{formatDate(publishedAt)}</span>
          </div>
        </div>
      </div>

      {/* Summary strip */}
      {summary && (
        <div className="px-5 py-3 border-t border-[var(--border)]">
          <p className="text-sm text-[var(--text-secondary)] leading-relaxed line-clamp-2">{summary}</p>
        </div>
      )}
    </Link>
  );
}

/* ── FEATURED — horizontal card with prominent image ────────── */
function FeaturedCard({ article }: { article: Article }) {
  const { id, title, summary, imageUrl, publishedAt, sourceName, category, language } = article;
  const isRtl = language === "ar";

  return (
    <Link
      href={`/article/${id}`}
      dir={isRtl ? "rtl" : undefined}
      className="group flex gap-4 p-4 sm:p-5 rounded-2xl bg-[var(--surface)] border border-[var(--border)] shadow-[var(--shadow-card)] card-lift"
    >
      <div className="flex-1 min-w-0 flex flex-col gap-2">
        <div className="flex items-center gap-2 flex-wrap">
          <CategoryBadge category={category} />
          <span className="text-xs text-[var(--text-muted)]">{formatDate(publishedAt)}</span>
        </div>
        <h3 className="font-display text-[17px] sm:text-lg font-bold leading-snug text-[var(--text-primary)] group-hover:text-[var(--primary)] transition-colors line-clamp-3">
          {title}
        </h3>
        {summary && (
          <p className="text-sm text-[var(--text-secondary)] leading-relaxed line-clamp-2 hidden sm:block">
            {summary}
          </p>
        )}
        <div className="mt-auto pt-1">
          <SourceRow sourceName={sourceName} publishedAt={publishedAt} />
        </div>
      </div>

      <div className="shrink-0 w-28 sm:w-36 self-start rounded-xl overflow-hidden bg-[var(--muted)] img-zoom">
        <div className="aspect-[4/3]">
          {imageUrl
            ? <img src={imageUrl} alt="" className="w-full h-full object-cover" loading="lazy" />
            : (
              <div className="w-full h-full flex items-center justify-center bg-gradient-to-br from-[var(--muted)] to-[var(--surface-2)]">
                <span className="text-3xl font-display font-bold text-[var(--primary)]/20">N</span>
              </div>
            )
          }
        </div>
      </div>
    </Link>
  );
}

/* ── COMPACT — numbered sidebar entry ───────────────────────── */
function CompactCard({ article, index }: { article: Article; index: number }) {
  const { id, title, publishedAt, category, language } = article;
  const isRtl = language === "ar";

  return (
    <Link
      href={`/article/${id}`}
      dir={isRtl ? "rtl" : undefined}
      className="group flex gap-3 py-3 border-b border-[var(--border)] last:border-0 rounded-lg px-1 -mx-1 hover:bg-[var(--surface-2)] transition-colors"
    >
      <span className="font-display text-[22px] font-bold leading-none pt-0.5 shrink-0 w-7 text-right text-[var(--primary)]/20 group-hover:text-[var(--primary)]/50 transition-colors">
        {index}
      </span>
      <div className="flex-1 min-w-0">
        <div className="mb-1"><CategoryBadge category={category} /></div>
        <h4 className="font-display text-[13px] font-semibold leading-snug text-[var(--text-primary)] group-hover:text-[var(--primary)] transition-colors line-clamp-2">
          {title}
        </h4>
        <span className="text-[11px] text-[var(--text-muted)] mt-0.5 block">{formatDate(publishedAt)}</span>
      </div>
    </Link>
  );
}

/* ── DEFAULT — standard card (improved) ─────────────────────── */
function DefaultCard({ article, showImage }: { article: Article; showImage: boolean }) {
  const { id, title, summary, imageUrl, publishedAt, sourceName, category, language } = article;
  const isRtl = language === "ar";

  return (
    <Link
      href={`/article/${id}`}
      dir={isRtl ? "rtl" : undefined}
      className="group flex gap-4 p-4 rounded-2xl bg-[var(--surface)] border border-[var(--border)] shadow-[var(--shadow-card)] card-lift"
    >
      <div className="flex-1 min-w-0 flex flex-col gap-1.5">
        <div className="flex items-center gap-2 flex-wrap">
          <CategoryBadge category={category} />
          <span className="text-xs text-[var(--text-muted)]">{formatDate(publishedAt)}</span>
        </div>
        <h3 className="font-display text-[15px] font-semibold leading-snug text-[var(--text-primary)] group-hover:text-[var(--primary)] transition-colors line-clamp-3">
          {title}
        </h3>
        {summary && (
          <p className="text-sm text-[var(--text-secondary)] line-clamp-2 leading-relaxed">{summary}</p>
        )}
        <div className="mt-auto pt-1">
          <SourceRow sourceName={sourceName} publishedAt={publishedAt} />
        </div>
      </div>

      {showImage && (
        <div className="shrink-0 w-24 h-24 rounded-xl overflow-hidden bg-[var(--muted)] img-zoom">
          {imageUrl
            ? <img src={imageUrl} alt="" className="w-full h-full object-cover" loading="lazy" />
            : (
              <div className="w-full h-full flex items-center justify-center bg-gradient-to-br from-[var(--muted)] to-[var(--surface-2)]">
                <span className="text-2xl font-display font-bold text-[var(--primary)]/20">N</span>
              </div>
            )
          }
        </div>
      )}
    </Link>
  );
}

/* ── Public export ───────────────────────────────────────────── */
export function ArticleCard({ article, variant = "default", showImage = true, index }: ArticleCardProps) {
  switch (variant) {
    case "hero":     return <HeroCard article={article} />;
    case "featured": return <FeaturedCard article={article} />;
    case "compact":  return <CompactCard article={article} index={index ?? 1} />;
    default:         return <DefaultCard article={article} showImage={showImage} />;
  }
}
