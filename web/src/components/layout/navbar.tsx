"use client";

import { useTheme } from "next-themes";
import { Bell, Moon, Sun } from "lucide-react";
import { useEffect, useState } from "react";

export function Navbar() {
  const { theme, setTheme } = useTheme();
  const [mounted, setMounted] = useState(false);

  useEffect(() => setMounted(true), []);
  const toggleTheme = () => setTheme(theme === "dark" ? "light" : "dark");

  if (!mounted) return <header className="sticky top-0 z-50 h-[72px] bg-[var(--background)] border-b border-[var(--border)] w-full"></header>;

  return (
    <header className="sticky top-0 z-50 flex items-center justify-between px-6 py-4 bg-[var(--background)] border-b border-[var(--border)] w-full">
      <div className="flex items-center gap-3">
        <div className="flex items-center justify-center w-9 h-9 rounded-lg bg-[var(--primary)] text-white font-display font-bold text-lg shadow-[0_2px_10px_rgba(14,196,160,0.2)]">
          N
        </div>
        <h1 className="text-2xl font-semibold font-display text-[var(--text-primary)]">
          Nexus
        </h1>
      </div>
      <div className="flex items-center gap-4">
        <button onClick={toggleTheme} className="text-[var(--text-primary)] hover:opacity-70 transition-opacity" aria-label="Toggle Theme">
          {theme === "dark" ? <Sun size={22} /> : <Moon size={22} />}
        </button>
        <button className="text-[var(--text-primary)] hover:opacity-70 transition-opacity" aria-label="Notifications">
          <Bell size={22} />
        </button>
      </div>
    </header>
  );
}
