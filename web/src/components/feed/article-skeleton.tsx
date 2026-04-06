export function ArticleSkeleton() {
  return (
    <article className="p-5 rounded-2xl bg-[var(--surface)] border border-[var(--border)] animate-pulse">
      <div className="flex items-center justify-between mb-3">
        <div className="w-16 h-4 bg-[var(--muted)] rounded" />
        <div className="w-12 h-3 bg-[var(--muted)] rounded" />
      </div>
      
      <div className="w-full h-6 bg-[var(--muted)] rounded mb-2" />
      <div className="w-3/4 h-6 bg-[var(--muted)] rounded mb-4" />
      
      <div className="flex items-center gap-2">
        <div className="w-[22px] h-[22px] rounded bg-[var(--muted)] shrink-0" />
        <div className="w-20 h-4 bg-[var(--muted)] rounded" />
      </div>
    </article>
  );
}
