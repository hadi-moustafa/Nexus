interface ArticleCardProps {
  title: string;
  source: string;
  time: string;
  category: string;
}

export function ArticleCard({ title, source, time, category }: ArticleCardProps) {
  return (
    <article className="p-5 rounded-2xl bg-[var(--surface)] border border-[var(--border)] transition-all hover:border-[var(--muted)] hover:shadow-sm cursor-pointer block group">
      <div className="flex items-center justify-between mb-3">
        <span className="text-[11px] font-bold text-[var(--accent)] uppercase tracking-wider">{category}</span>
        <span className="text-xs text-[var(--text-secondary)]">{time}</span>
      </div>
      
      <h3 className="font-display text-[18px] font-semibold leading-snug mb-4 text-[var(--text-primary)] group-hover:text-[var(--primary)] transition-colors">
        {title}
      </h3>
      
      <div className="flex items-center gap-2">
        <div className="w-[22px] h-[22px] rounded border border-[var(--border)] bg-[var(--muted)] shrink-0 flex items-center justify-center overflow-hidden">
             <span className="text-[10px] font-bold text-[var(--text-secondary)] uppercase">
               {source.charAt(0)}
             </span>
        </div>
        <span className="text-sm font-medium text-[var(--text-secondary)]">{source}</span>
      </div>
    </article>
  );
}
