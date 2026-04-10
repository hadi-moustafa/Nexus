import { cookies } from "next/headers";
import { createClient } from "@/lib/supabase/server";
import { requireAdminPage } from "@/lib/admin";
import { Users, FileText, MessageSquare, Rss } from "lucide-react";

async function getStats() {
  const cookieStore = await cookies();
  const supabase = createClient(cookieStore);

  const [
    { count: userCount },
    { count: articleCount },
    { count: commentCount },
    { count: sourceCount },
    { count: flaggedCount },
  ] = await Promise.all([
    supabase.from("users").select("*", { count: "exact", head: true }),
    supabase.from("articles").select("*", { count: "exact", head: true }),
    supabase.from("comments").select("*", { count: "exact", head: true }),
    supabase.from("news_sources").select("*", { count: "exact", head: true }),
    supabase.from("comments").select("*", { count: "exact", head: true }).eq("is_flagged", true),
  ]);

  return { userCount, articleCount, commentCount, sourceCount, flaggedCount };
}

async function getRecentUsers() {
  const cookieStore = await cookies();
  const supabase = createClient(cookieStore);
  const { data } = await supabase
    .from("users")
    .select("id, email, display_name, created_at, role")
    .order("created_at", { ascending: false })
    .limit(5);
  return data ?? [];
}

export default async function AdminPage() {
  await requireAdminPage();
  const [stats, recentUsers] = await Promise.all([getStats(), getRecentUsers()]);

  const STAT_CARDS = [
    { label: "Total Users",     value: stats.userCount ?? 0,    icon: Users,          color: "text-blue-500" },
    { label: "Articles",        value: stats.articleCount ?? 0, icon: FileText,       color: "text-green-500" },
    { label: "Comments",        value: stats.commentCount ?? 0, icon: MessageSquare,  color: "text-purple-500" },
    { label: "News Sources",    value: stats.sourceCount ?? 0,  icon: Rss,            color: "text-orange-500" },
  ];

  return (
    <div>
      <h1 className="font-display text-2xl font-semibold text-[var(--text-primary)] mb-8">
        Dashboard
      </h1>

      {/* Stat cards */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-10">
        {STAT_CARDS.map(({ label, value, icon: Icon, color }) => (
          <div
            key={label}
            className="p-5 rounded-2xl border border-[var(--border)] bg-[var(--surface)]"
          >
            <Icon size={20} className={`${color} mb-3`} />
            <p className="text-2xl font-bold text-[var(--text-primary)]">{value.toLocaleString()}</p>
            <p className="text-xs text-[var(--text-secondary)] mt-1">{label}</p>
          </div>
        ))}
      </div>

      {/* Flagged comments alert */}
      {(stats.flaggedCount ?? 0) > 0 && (
        <div className="mb-6 flex items-center gap-3 p-4 rounded-xl border border-red-400/40 bg-red-500/5 text-red-500">
          <MessageSquare size={16} />
          <p className="text-sm font-medium">
            {stats.flaggedCount} flagged comment{stats.flaggedCount === 1 ? "" : "s"} awaiting review.{" "}
            <a href="/admin/comments" className="underline underline-offset-2">Review now →</a>
          </p>
        </div>
      )}

      {/* Recent users */}
      <div className="rounded-2xl border border-[var(--border)] bg-[var(--surface)] overflow-hidden">
        <div className="px-5 py-4 border-b border-[var(--border)]">
          <h2 className="text-sm font-semibold text-[var(--text-primary)]">Recent sign-ups</h2>
        </div>
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b border-[var(--border)]">
              <th className="text-left px-5 py-3 text-xs font-medium text-[var(--text-secondary)] uppercase tracking-wide">User</th>
              <th className="text-left px-5 py-3 text-xs font-medium text-[var(--text-secondary)] uppercase tracking-wide hidden sm:table-cell">Role</th>
              <th className="text-left px-5 py-3 text-xs font-medium text-[var(--text-secondary)] uppercase tracking-wide hidden md:table-cell">Joined</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-[var(--border)]">
            {recentUsers.map((u) => (
              <tr key={u.id} className="hover:bg-[var(--muted)] transition-colors">
                <td className="px-5 py-3">
                  <p className="font-medium text-[var(--text-primary)]">{u.display_name ?? "—"}</p>
                  <p className="text-xs text-[var(--text-secondary)]">{u.email}</p>
                </td>
                <td className="px-5 py-3 hidden sm:table-cell">
                  <span className={`px-2 py-0.5 rounded-full text-xs font-medium ${
                    u.role === "admin"
                      ? "bg-[var(--primary)]/10 text-[var(--primary)]"
                      : "bg-[var(--muted)] text-[var(--text-secondary)]"
                  }`}>
                    {u.role}
                  </span>
                </td>
                <td className="px-5 py-3 text-xs text-[var(--text-secondary)] hidden md:table-cell">
                  {new Date(u.created_at as string).toLocaleDateString()}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
