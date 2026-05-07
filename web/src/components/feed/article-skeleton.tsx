import type { CardVariant } from "./article-card";

export function ArticleSkeleton({ variant = "default" }: { variant?: CardVariant }) {
  if (variant === "hero") {
    return (
      <div className="rounded-2xl overflow-hidden bg-[var(--surface)] border border-[var(--border)] animate-pulse">
        <div className="w-full aspect-[16/9] bg-[var(--muted)]" />
        <div className="px-5 py-3 border-t border-[var(--border)]">
          <div className="w-full h-4 bg-[var(--muted)] rounded mb-1.5" />
          <div className="w-2/3 h-4 bg-[var(--muted)] rounded" />
        </div>
      </div>
    );
  }

  if (variant === "featured") {
    return (
      <div className="flex gap-4 p-4 rounded-2xl bg-[var(--surface)] border border-[var(--border)] animate-pulse">
        <div className="flex-1 flex flex-col gap-2">
          <div className="w-16 h-4 bg-[var(--muted)] rounded-full" />
          <div className="w-full h-5 bg-[var(--muted)] rounded" />
          <div className="w-4/5 h-5 bg-[var(--muted)] rounded" />
          <div className="w-full h-3.5 bg-[var(--muted)] rounded mt-1" />
          <div className="w-2/3 h-3.5 bg-[var(--muted)] rounded" />
          <div className="flex gap-2 mt-auto pt-1">
            <div className="w-5 h-5 bg-[var(--muted)] rounded" />
            <div className="w-24 h-3.5 bg-[var(--muted)] rounded" />
          </div>
        </div>
        <div className="shrink-0 w-28 sm:w-36 aspect-[4/3] rounded-xl bg-[var(--muted)]" />
      </div>
    );
  }

  if (variant === "compact") {
    return (
      <div className="flex gap-3 py-3 border-b border-[var(--border)] animate-pulse">
        <div className="w-7 h-6 bg-[var(--muted)] rounded shrink-0" />
        <div className="flex-1">
          <div className="w-14 h-3.5 bg-[var(--muted)] rounded-full mb-2" />
          <div className="w-full h-4 bg-[var(--muted)] rounded mb-1" />
          <div className="w-3/4 h-4 bg-[var(--muted)] rounded" />
        </div>
      </div>
    );
  }

  /* default */
  return (
    <div className="flex gap-4 p-4 rounded-2xl bg-[var(--surface)] border border-[var(--border)] animate-pulse">
      <div className="flex-1 flex flex-col gap-2">
        <div className="flex gap-2">
          <div className="w-16 h-4 bg-[var(--muted)] rounded-full" />
          <div className="w-10 h-4 bg-[var(--muted)] rounded-full" />
        </div>
        <div className="w-full h-5 bg-[var(--muted)] rounded" />
        <div className="w-4/5 h-5 bg-[var(--muted)] rounded" />
        <div className="w-full h-3.5 bg-[var(--muted)] rounded mt-0.5" />
        <div className="flex gap-2 mt-auto pt-1">
          <div className="w-5 h-5 bg-[var(--muted)] rounded" />
          <div className="w-20 h-3.5 bg-[var(--muted)] rounded" />
        </div>
      </div>
      <div className="shrink-0 w-24 h-24 rounded-xl bg-[var(--muted)]" />
    </div>
  );
}
