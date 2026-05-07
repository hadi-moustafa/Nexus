const HEADLINES = [
  "UN Security Council calls emergency session over regional tensions",
  "Federal Reserve holds rates; signals two cuts before year-end",
  "Lebanon economic recovery plan receives IMF endorsement",
  "AI companies face new transparency rules under landmark EU Act",
  "Global obesity rate reaches record 40% — WHO warns of health crisis",
  "Beirut port reconstruction begins as international donors release funds",
  "SpaceX Starship completes first commercial payload mission",
  "Manchester City wins Premier League title for sixth consecutive season",
];

export function BreakingNewsBanner() {
  const repeated = [...HEADLINES, ...HEADLINES];

  return (
    <div className="flex items-stretch overflow-hidden bg-[var(--surface)] border-b border-[var(--border)] h-9 select-none">
      {/* Live badge */}
      <div className="flex items-center gap-1.5 px-3 bg-red-600 shrink-0">
        <span className="w-1.5 h-1.5 rounded-full bg-white animate-pulse" />
        <span className="text-white text-[10px] font-black tracking-widest leading-none uppercase">Live</span>
      </div>

      {/* Divider */}
      <div className="w-px bg-[var(--border)]" />

      {/* Ticker */}
      <div className="flex-1 overflow-hidden flex items-center">
        <div className="ticker-track">
          {repeated.map((headline, i) => (
            <span key={i} className="text-[12px] font-medium text-[var(--text-secondary)] whitespace-nowrap px-6 flex items-center gap-2">
              <span className="text-[var(--primary)] font-bold text-[10px]">●</span>
              {headline}
            </span>
          ))}
        </div>
      </div>
    </div>
  );
}
