// Bare layout for auth pages — no navbar, no dashboard chrome.
// Fonts and ThemeProvider come from the root layout.tsx.
export default function AuthLayout({ children }: { children: React.ReactNode }) {
  return (
    <main className="min-h-screen flex items-center justify-center bg-[var(--background)] px-5">
      {children}
    </main>
  );
}
