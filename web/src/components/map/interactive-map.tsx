"use client";

import { Globe } from "lucide-react";

export function InteractiveMap() {
  return (
    <section className="my-8">
      <h2 className="text-[22px] font-display font-semibold mb-1 text-[var(--text-primary)]">Explore Global News</h2>
      <p className="text-sm text-[var(--text-secondary)] mb-6">Tap on a region to discover stories</p>
      
      <div className="relative w-full h-[280px] rounded-[24px] bg-gradient-to-br border border-[var(--border)] flex items-center justify-center overflow-hidden from-[var(--muted)] to-[var(--background)]">
        <Globe size={180} className="text-[var(--primary)] opacity-[0.08] absolute" />
        
        <MapHotspot label="Americas" count={31} top="30%" left="20%" />
        <MapHotspot label="Europe" count={24} top="25%" left="48%" />
        <MapHotspot label="Asia" count={18} top="35%" left="70%" />
        <MapHotspot label="Africa" count={12} top="55%" left="52%" />
      </div>
    </section>
  );
}

function MapHotspot({ label, count, top, left }: { label: string; count: number; top: string; left: string }) {
  return (
    <div className="absolute flex flex-col items-center" style={{ top, left }}>
      <button 
        className="w-10 h-10 rounded-full bg-[var(--primary)] shadow-[0_0_15px_rgba(14,196,160,0.4)] flex items-center justify-center text-white font-bold text-sm cursor-pointer hover:scale-110 transition-transform active:scale-95"
        aria-label={`View ${label} news`}
      >
        {count}
      </button>
      <span className="text-xs font-semibold mt-1.5 text-[var(--text-primary)]">{label}</span>
    </div>
  );
}
