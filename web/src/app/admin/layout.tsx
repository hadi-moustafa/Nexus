import Link from "next/link";
import { LayoutDashboard, Users, Rss, MessageSquare, Pen, CreditCard, Trophy, BarChart2, Inbox, FileText } from "lucide-react";
import { requireAdminPage } from "@/lib/admin";

const NAV = [
  { href: "/admin",                       label: "Overview",      icon: LayoutDashboard },
  { href: "/admin/metrics",               label: "Metrics",       icon: BarChart2 },
  { href: "/admin/users",                 label: "Users",         icon: Users },
  { href: "/admin/sources",               label: "Sources",       icon: Rss },
  { href: "/admin/comments",              label: "Comments",      icon: MessageSquare },
  { href: "/admin/journalists",           label: "Journalists",   icon: Pen },
  { href: "/admin/journalist-requests",   label: "J. Requests",   icon: Inbox },
  { href: "/admin/posts",                 label: "Posts",         icon: FileText },
  { href: "/admin/subscriptions",         label: "Subscriptions", icon: CreditCard },
  { href: "/admin/quiz",                  label: "Quizzes",       icon: Trophy },
];

export default async function AdminLayout({ children }: { children: React.ReactNode }) {
  // Gate — redirects to / if not admin
  await requireAdminPage();

  return (
    <div className="min-h-screen bg-[var(--background)] flex">
      {/* Sidebar */}
      <aside className="w-56 shrink-0 border-r border-[var(--border)] bg-[var(--surface)] flex flex-col py-6 px-3 hidden md:flex">
        <Link href="/" className="px-3 mb-8 font-display text-lg font-semibold text-[var(--primary)]">
          Nexus Admin
        </Link>

        <nav className="flex flex-col gap-0.5">
          {NAV.map(({ href, label, icon: Icon }) => (
            <Link
              key={href}
              href={href}
              className="flex items-center gap-2.5 px-3 py-2 rounded-lg text-sm text-[var(--text-secondary)] hover:bg-[var(--muted)] hover:text-[var(--text-primary)] transition-colors"
            >
              <Icon size={16} />
              {label}
            </Link>
          ))}
        </nav>
      </aside>

      {/* Mobile top bar */}
      <div className="md:hidden fixed top-0 left-0 right-0 z-50 bg-[var(--surface)] border-b border-[var(--border)] px-4 py-3 flex items-center gap-3 overflow-x-auto">
        {NAV.map(({ href, label, icon: Icon }) => (
          <Link
            key={href}
            href={href}
            className="shrink-0 flex items-center gap-1.5 text-xs text-[var(--text-secondary)] hover:text-[var(--primary)] transition-colors"
          >
            <Icon size={14} />
            {label}
          </Link>
        ))}
      </div>

      {/* Main content */}
      <main className="flex-1 min-w-0 p-6 md:p-8 pt-16 md:pt-8 overflow-auto">
        {children}
      </main>
    </div>
  );
}
