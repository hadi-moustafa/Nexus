"use client";

import { useTheme } from "next-themes";
import { Bell, Moon, Sun, LogIn, LogOut, Search, Newspaper, Globe, Trophy, Sparkles } from "lucide-react";
import { useEffect, useState } from "react";
import { createClient } from "@/lib/supabase/client";
import type { User } from "@supabase/supabase-js";
import Link from "next/link";
import { useRouter, usePathname } from "next/navigation";

const NAV_LINKS = [
  { href: "/",       label: "Map",    icon: Globe },
  { href: "/feed",   label: "Feed",   icon: Newspaper },
  { href: "/search", label: "Search", icon: Search },
  { href: "/quiz",   label: "Quiz",   icon: Trophy },
  { href: "/digest", label: "Digest", icon: Sparkles },
];

export function Navbar() {
  const { theme, setTheme } = useTheme();
  const [mounted, setMounted] = useState(false);
  const [user, setUser] = useState<User | null>(null);
  const router = useRouter();
  const pathname = usePathname();

  useEffect(() => {
    setMounted(true);
    const supabase = createClient();

    supabase.auth.getUser().then(({ data }) => setUser(data.user));

    const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, session) => {
      setUser(session?.user ?? null);
    });

    return () => subscription.unsubscribe();
  }, []);

  const handleSignOut = async () => {
    await fetch("/api/v1/auth/signout", { method: "POST" });
    setUser(null);
    router.push("/login");
    router.refresh();
  };

  if (!mounted) {
    return <header className="sticky top-0 z-50 h-16 bg-[var(--background)] border-b border-[var(--border)] w-full" />;
  }

  return (
    <header className="sticky top-0 z-50 bg-[var(--background)] border-b border-[var(--border)] w-full">
      <div className="flex items-center justify-between px-5 h-16">
        {/* Logo */}
        <Link href="/" className="flex items-center gap-2.5">
          <div className="flex items-center justify-center w-8 h-8 rounded-lg bg-[var(--primary)] text-white font-display font-bold text-base shadow-[0_2px_10px_rgba(14,196,160,0.2)]">
            N
          </div>
          <span className="text-xl font-semibold font-display text-[var(--text-primary)]">Nexus</span>
        </Link>

        {/* Nav links — desktop */}
        <nav className="hidden sm:flex items-center gap-1">
          {NAV_LINKS.map(({ href, label, icon: Icon }) => {
            const active = href === "/" ? pathname === "/" : pathname.startsWith(href);
            return (
              <Link
                key={href}
                href={href}
                className={`flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-sm font-medium transition-colors ${
                  active
                    ? "text-[var(--primary)] bg-[var(--primary)]/10"
                    : "text-[var(--text-secondary)] hover:text-[var(--text-primary)] hover:bg-[var(--muted)]"
                }`}
              >
                <Icon size={15} />
                {label}
              </Link>
            );
          })}
        </nav>

        {/* Actions */}
        <div className="flex items-center gap-2">
          <button
            onClick={() => setTheme(theme === "dark" ? "light" : "dark")}
            className="w-8 h-8 flex items-center justify-center rounded-lg text-[var(--text-secondary)] hover:text-[var(--text-primary)] hover:bg-[var(--muted)] transition-colors"
            aria-label="Toggle theme"
          >
            {theme === "dark" ? <Sun size={18} /> : <Moon size={18} />}
          </button>

          {user ? (
            <>
              <button
                className="w-8 h-8 flex items-center justify-center rounded-lg text-[var(--text-secondary)] hover:text-[var(--text-primary)] hover:bg-[var(--muted)] transition-colors"
                aria-label="Notifications"
              >
                <Bell size={18} />
              </button>

              <Link href="/profile">
                {user.user_metadata?.avatar_url ? (
                  // eslint-disable-next-line @next/next/no-img-element
                  <img
                    src={user.user_metadata.avatar_url}
                    alt={user.user_metadata?.full_name ?? "User"}
                    className="w-8 h-8 rounded-full border border-[var(--border)]"
                  />
                ) : (
                  <div className="w-8 h-8 rounded-full bg-[var(--primary)] flex items-center justify-center text-white text-sm font-bold">
                    {(user.email ?? "U")[0].toUpperCase()}
                  </div>
                )}
              </Link>

              <button
                onClick={handleSignOut}
                className="w-8 h-8 flex items-center justify-center rounded-lg text-[var(--text-secondary)] hover:text-[var(--text-primary)] hover:bg-[var(--muted)] transition-colors"
                aria-label="Sign out"
              >
                <LogOut size={18} />
              </button>
            </>
          ) : (
            <Link
              href="/login"
              className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-sm font-medium text-white bg-[var(--primary)] hover:opacity-90 transition-opacity"
            >
              <LogIn size={15} />
              Sign in
            </Link>
          )}
        </div>
      </div>

      {/* Mobile bottom nav bar */}
      <nav className="sm:hidden fixed bottom-0 left-0 right-0 z-50 flex items-center bg-[var(--background)] border-t border-[var(--border)]">
        {NAV_LINKS.map(({ href, label, icon: Icon }) => {
          const active = href === "/" ? pathname === "/" : pathname.startsWith(href);
          return (
            <Link
              key={href}
              href={href}
              className={`flex-1 flex flex-col items-center gap-0.5 py-3 text-[10px] font-medium transition-colors ${
                active ? "text-[var(--primary)]" : "text-[var(--text-secondary)]"
              }`}
            >
              <Icon size={20} />
              {label}
            </Link>
          );
        })}
      </nav>
    </header>
  );
}
