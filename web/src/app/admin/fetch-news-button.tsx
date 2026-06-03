"use client";

import { useState } from "react";
import { RefreshCw } from "lucide-react";

export function FetchNewsButton() {
  const [state, setState] = useState<"idle" | "loading" | "done" | "error">("idle");
  const [result, setResult] = useState<{ gnews: number; guardian: number; arabic: number } | null>(null);

  const handleFetch = async () => {
    setState("loading");
    setResult(null);
    try {
      const res = await fetch("/api/v1/internal/fetch-news", { method: "POST" });
      const json = await res.json();
      if (res.ok && json.data) {
        setResult({
          gnews:    json.data.gnews?.totalInserted    ?? 0,
          guardian: json.data.guardian?.totalInserted ?? 0,
          arabic:   json.data.arabic?.totalInserted   ?? 0,
        });
        setState("done");
      } else {
        setState("error");
      }
    } catch {
      setState("error");
    }
  };

  return (
    <div className="flex flex-col items-end gap-2">
      <button
        onClick={handleFetch}
        disabled={state === "loading"}
        className="flex items-center gap-1.5 px-4 py-2 rounded-xl border border-[var(--border)] text-sm font-medium text-[var(--text-primary)] hover:border-[var(--primary)] hover:text-[var(--primary)] transition-colors disabled:opacity-50"
      >
        <RefreshCw size={15} className={state === "loading" ? "animate-spin" : ""} />
        {state === "loading" ? "Fetching…" : "Fetch news now"}
      </button>
      {state === "done" && result && (
        <p className="text-xs text-green-600">
          ✓ {result.gnews + result.guardian + result.arabic} new articles ingested
          (GNews: {result.gnews}, Guardian: {result.guardian}, Arabic: {result.arabic})
        </p>
      )}
      {state === "error" && (
        <p className="text-xs text-red-500">Failed to fetch news. Check server logs.</p>
      )}
    </div>
  );
}
