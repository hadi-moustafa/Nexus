export function BreakingNewsBanner() {
  return (
    <section className="my-6 p-4 rounded-xl border border-red-500/30 bg-red-500/10 flex items-center gap-3">
      <div className="px-2.5 py-1 bg-red-600 rounded flex items-center gap-1.5 shadow-sm shrink-0">
        <span className="w-1.5 h-1.5 rounded-full bg-white animate-pulse"></span>
        <span className="text-white text-[10px] font-bold tracking-wider leading-none">LIVE</span>
      </div>
      <p className="text-sm font-medium text-[var(--text-primary)] truncate">
        Breaking: Major diplomatic talks underway in Geneva
      </p>
    </section>
  );
}
