"use client";

import { useTheme } from "next-themes";
import {
  Moon, Sun, LogIn, LogOut, Search,
  Newspaper, Globe, Trophy, Sparkles, ShieldCheck, Menu, X,
} from "lucide-react";
import { useEffect, useState } from "react";
import { createClient } from "@/lib/supabase/client";
import type { User } from "@supabase/supabase-js";
import Link from "next/link";
import { useRouter, usePathname } from "next/navigation";

const NAV_LINKS = [
  { href: "/",        label: "Home",   icon: Globe },
  { href: "/feed",    label: "Feed",   icon: Newspaper },
  { href: "/search",  label: "Search", icon: Search },
  { href: "/quiz",    label: "Quiz",   icon: Trophy },
  { href: "/digest",  label: "Digest", icon: Sparkles },
];

export function Navbar() {
  const { theme, setTheme } = useTheme();
  const [mounted, setMounted] = useState(false);
  const [user, setUser] = useState<User | null>(null);
  const [isAdmin, setIsAdmin] = useState(false);
  const [scrolled, setScrolled] = useState(false);
  const [mobileOpen, setMobileOpen] = useState(false);
  const router = useRouter();
  const pathname = usePathname();

  useEffect(() => {
    setMounted(true);
    const supabase = createClient();

    supabase.auth.getUser().then(({ data }) => {
      setUser(data.user);
      if (data.user) fetchRole();
    });

    const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, session) => {
      const u = session?.user ?? null;
      setUser(u);
      if (u) fetchRole();
      else setIsAdmin(false);
    });

    const onScroll = () => setScrolled(window.scrollY > 8);
    window.addEventListener("scroll", onScroll, { passive: true });

    return () => {
      subscription.unsubscribe();
      window.removeEventListener("scroll", onScroll);
    };
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const fetchRole = () => {
    fetch("/api/v1/auth/session")
      .then((r) => r.json())
      .then(({ data }) => setIsAdmin(data?.isAdmin === true))
      .catch(() => setIsAdmin(false));
  };

  const handleSignOut = async () => {
    await fetch("/api/v1/auth/signout", { method: "POST" });
    setUser(null);
    setIsAdmin(false);
    setMobileOpen(false);
    router.push("/login");
    router.refresh();
  };

  const isActive = (href: string) =>
    href === "/" ? pathname === "/" : pathname.startsWith(href);

  if (!mounted) {
    return <header className="sticky top-0 z-50 h-14 w-full" />;
  }

  return (
    <>
      <header
        className={`sticky top-0 z-50 w-full transition-all duration-200 ${
          scrolled
            ? "shadow-[var(--shadow-md)] border-b border-[var(--border)]"
            : "border-b border-transparent"
        }`}
        style={{ background: "var(--navbar-bg)", backdropFilter: "blur(16px)", WebkitBackdropFilter: "blur(16px)" }}
      >
        <div className="max-w-screen-xl mx-auto px-4 sm:px-6 h-14 flex items-center gap-4">

          {/* Logo */}
          <Link href="/" className="flex items-center gap-2.5 shrink-0 group">
            <div
              className="w-8 h-8 rounded-xl flex items-center justify-center text-white font-display font-bold text-base shadow-[0_2px_8px_rgba(14,196,160,0.35)]"
              style={{ background: "linear-gradient(135deg, #0EC4A0 0%, #0891B2 100%)" }}
            >
              N
            </div>
            <span className="text-[17px] font-display font-bold text-[var(--text-primary)] tracking-tight group-hover:text-[var(--primary)] transition-colors">
              Nexus
            </span>
          </Link>

          {/* Nav links — desktop */}
          <nav className="hidden md:flex items-center gap-0.5 flex-1 justify-center">
            {NAV_LINKS.map(({ href, label, icon: Icon }) => {
              const active = isActive(href);
              return (
                <Link
                  key={href}
                  href={href}
                  className={`relative flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-sm font-medium transition-colors ${
                    active
                      ? "text-[var(--primary)]"
                      : "text-[var(--text-secondary)] hover:text-[var(--text-primary)] hover:bg-[var(--muted)]"
                  }`}
                >
                  <Icon size={14} />
                  {label}
                  {active && (
                    <span className="absolute bottom-0 left-1/2 -translate-x-1/2 w-4 h-[2px] rounded-full bg-[var(--primary)]" />
                  )}
                </Link>
              );
            })}
            {isAdmin && (
              <Link
                href="/admin"
                className={`relative flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-sm font-medium transition-colors ${
                  pathname.startsWith("/admin")
                    ? "text-amber-500"
                    : "text-[var(--text-secondary)] hover:text-amber-500 hover:bg-amber-500/10"
                }`}
              >
                <ShieldCheck size={14} />
                Admin
                {pathname.startsWith("/admin") && (
                  <span className="absolute bottom-0 left-1/2 -translate-x-1/2 w-4 h-[2px] rounded-full bg-amber-500" />
                )}
              </Link>
            )}
          </nav>

          {/* Right actions */}
          <div className="flex items-center gap-1.5 ml-auto">
            {/* Theme toggle */}
            <button
              onClick={() => setTheme(theme === "dark" ? "light" : "dark")}
              className="w-8 h-8 flex items-center justify-center rounded-lg text-[var(--text-secondary)] hover:text-[var(--text-primary)] hover:bg-[var(--muted)] transition-colors"
              aria-label="Toggle theme"
            >
              {theme === "dark"
                ? <Sun size={16} />
                : <Moon size={16} />}
            </button>

            {user ? (
              <>
                <Link href="/profile" className="flex items-center">
                  {user.user_metadata?.avatar_url ? (
                    // eslint-disable-next-line @next/next/no-img-element
                    <img
                      src={user.user_metadata.avatar_url}
                      alt={user.user_metadata?.full_name ?? "User"}
                      className="w-8 h-8 rounded-full border-2 border-[var(--border)] hover:border-[var(--primary)] transition-colors object-cover"
                    />
                  ) : (
                    <div
                      className="w-8 h-8 rounded-full flex items-center justify-center text-white text-[13px] font-bold shadow-[var(--shadow-xs)]"
                      style={{ background: "linear-gradient(135deg, #0EC4A0 0%, #0891B2 100%)" }}
                    >
                      {(user.email ?? "U")[0].toUpperCase()}
                    </div>
                  )}
                </Link>

                <button
                  onClick={handleSignOut}
                  className="hidden sm:flex w-8 h-8 items-center justify-center rounded-lg text-[var(--text-secondary)] hover:text-[var(--text-primary)] hover:bg-[var(--muted)] transition-colors"
                  aria-label="Sign out"
                >
                  <LogOut size={15} />
                </button>
              </>
            ) : (
              <Link
                href="/login"
                className="hidden sm:flex items-center gap-1.5 px-3.5 py-1.5 rounded-lg text-sm font-semibold text-white transition-opacity hover:opacity-90"
                style={{ background: "linear-gradient(135deg, #0EC4A0 0%, #0891B2 100%)" }}
              >
                <LogIn size={14} />
                Sign in
              </Link>
            )}

            {/* Mobile hamburger */}
            <button
              className="md:hidden w-8 h-8 flex items-center justify-center rounded-lg text-[var(--text-secondary)] hover:bg-[var(--muted)] transition-colors"
              onClick={() => setMobileOpen((v) => !v)}
              aria-label="Toggle menu"
            >
              {mobileOpen ? <X size={18} /> : <Menu size={18} />}
            </button>
          </div>
        </div>

        {/* Mobile dropdown menu */}
        {mobileOpen && (
          <div className="md:hidden border-t border-[var(--border)] bg-[var(--surface)] px-4 py-3 flex flex-col gap-1">
            {NAV_LINKS.map(({ href, label, icon: Icon }) => {
              const active = isActive(href);
              return (
                <Link
                  key={href}
                  href={href}
                  onClick={() => setMobileOpen(false)}
                  className={`flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm font-medium transition-colors ${
                    active
                      ? "bg-[var(--primary-muted)] text-[var(--primary)]"
                      : "text-[var(--text-secondary)] hover:bg-[var(--muted)]"
                  }`}
                >
                  <Icon size={17} />
                  {label}
                </Link>
              );
            })}
            {isAdmin && (
              <Link
                href="/admin"
                onClick={() => setMobileOpen(false)}
                className={`flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm font-medium transition-colors ${
                  pathname.startsWith("/admin")
                    ? "bg-amber-500/10 text-amber-500"
                    : "text-[var(--text-secondary)] hover:bg-[var(--muted)]"
                }`}
              >
                <ShieldCheck size={17} />
                Admin
              </Link>
            )}
            {user ? (
              <button
                onClick={handleSignOut}
                className="flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm font-medium text-[var(--text-secondary)] hover:bg-[var(--muted)] transition-colors"
              >
                <LogOut size={17} />
                Sign out
              </button>
            ) : (
              <Link
                href="/login"
                onClick={() => setMobileOpen(false)}
                className="flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm font-semibold text-white transition-opacity hover:opacity-90"
                style={{ background: "linear-gradient(135deg, #0EC4A0 0%, #0891B2 100%)" }}
              >
                <LogIn size={17} />
                Sign in
              </Link>
            )}
          </div>
        )}
      </header>

      {/* Mobile bottom tab bar */}
      <nav className="md:hidden fixed bottom-0 left-0 right-0 z-50 flex items-center border-t border-[var(--border)]"
        style={{ background: "var(--navbar-bg)", backdropFilter: "blur(16px)", WebkitBackdropFilter: "blur(16px)" }}
      >
        {NAV_LINKS.map(({ href, label, icon: Icon }) => {
          const active = isActive(href);
          return (
            <Link
              key={href}
              href={href}
              className={`flex-1 flex flex-col items-center gap-0.5 py-2.5 text-[10px] font-semibold transition-colors ${
                active ? "text-[var(--primary)]" : "text-[var(--text-muted)]"
              }`}
            >
              <Icon size={20} strokeWidth={active ? 2.2 : 1.8} />
              {label}
            </Link>
          );
        })}
        {isAdmin && (
          <Link
            href="/admin"
            className={`flex-1 flex flex-col items-center gap-0.5 py-2.5 text-[10px] font-semibold transition-colors ${
              pathname.startsWith("/admin") ? "text-amber-500" : "text-[var(--text-muted)]"
            }`}
          >
            <ShieldCheck size={20} strokeWidth={pathname.startsWith("/admin") ? 2.2 : 1.8} />
            Admin
          </Link>
        )}
      </nav>
    </>
  );
}
