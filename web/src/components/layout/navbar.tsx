"use client";

import { useTheme } from "next-themes";
import { Bell, Moon, Sun, LogIn, LogOut } from "lucide-react";
import { useEffect, useState } from "react";
import { createClient } from "@/lib/supabase/client";
import type { User } from "@supabase/supabase-js";
import Link from "next/link";
import { useRouter } from "next/navigation";

export function Navbar() {
  const { theme, setTheme } = useTheme();
  const [mounted, setMounted] = useState(false);
  const [user, setUser] = useState<User | null>(null);
  const router = useRouter();

  useEffect(() => {
    setMounted(true);
    const supabase = createClient();

    // Get current session on mount
    supabase.auth.getUser().then(({ data }) => setUser(data.user));

    // Keep user state in sync with auth changes
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

  const toggleTheme = () => setTheme(theme === "dark" ? "light" : "dark");

  // Render a fixed-height placeholder before hydration to prevent layout shift
  if (!mounted) {
    return <header className="sticky top-0 z-50 h-[72px] bg-[var(--background)] border-b border-[var(--border)] w-full" />;
  }

  return (
    <header className="sticky top-0 z-50 flex items-center justify-between px-6 py-4 bg-[var(--background)] border-b border-[var(--border)] w-full">
      {/* Logo */}
      <div className="flex items-center gap-3">
        <div className="flex items-center justify-center w-9 h-9 rounded-lg bg-[var(--primary)] text-white font-display font-bold text-lg shadow-[0_2px_10px_rgba(14,196,160,0.2)]">
          N
        </div>
        <h1 className="text-2xl font-semibold font-display text-[var(--text-primary)]">
          Nexus
        </h1>
      </div>

      {/* Actions */}
      <div className="flex items-center gap-3">
        <button
          onClick={toggleTheme}
          className="text-[var(--text-primary)] hover:opacity-70 transition-opacity"
          aria-label="Toggle theme"
        >
          {theme === "dark" ? <Sun size={22} /> : <Moon size={22} />}
        </button>

        {user ? (
          <>
            <button
              className="text-[var(--text-primary)] hover:opacity-70 transition-opacity"
              aria-label="Notifications"
            >
              <Bell size={22} />
            </button>

            {/* User avatar */}
            <div className="flex items-center gap-2 pl-1">
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
            </div>

            <button
              onClick={handleSignOut}
              className="text-[var(--text-secondary)] hover:text-[var(--text-primary)] hover:opacity-70 transition-opacity"
              aria-label="Sign out"
            >
              <LogOut size={20} />
            </button>
          </>
        ) : (
          <Link
            href="/login"
            className="flex items-center gap-1.5 text-sm font-medium text-[var(--primary)] hover:opacity-80 transition-opacity"
          >
            <LogIn size={18} />
            Sign in
          </Link>
        )}
      </div>
    </header>
  );
}
