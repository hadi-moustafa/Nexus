"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { Check, ArrowRight, Globe, Bell } from "lucide-react";

const TOPICS = [
  { value: "world",         label: "World" },
  { value: "technology",    label: "Technology" },
  { value: "business",      label: "Business" },
  { value: "sports",        label: "Sports" },
  { value: "health",        label: "Health" },
  { value: "science",       label: "Science" },
  { value: "entertainment", label: "Entertainment" },
  { value: "lebanon",       label: "Lebanon" },
];

const LANGUAGES = [
  { value: "en", label: "English" },
  { value: "ar", label: "Arabic" },
  { value: "fr", label: "French" },
];

type Step = 1 | 2 | 3;

export default function OnboardingPage() {
  const router = useRouter();
  const [step, setStep] = useState<Step>(1);
  const [topics, setTopics] = useState<string[]>([]);
  const [language, setLanguage] = useState("en");
  const [saving, setSaving] = useState(false);

  const toggleTopic = (value: string) => {
    setTopics((prev) =>
      prev.includes(value) ? prev.filter((t) => t !== value) : [...prev, value]
    );
  };

  const finish = async () => {
    setSaving(true);
    try {
      await fetch("/api/v1/user/preferences", {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ topics, preferredLanguage: language, onboardingComplete: true }),
      });
      router.replace("/feed");
    } catch {
      setSaving(false);
    }
  };

  return (
    <div className="min-h-screen bg-[var(--background)] flex flex-col items-center justify-center px-5 py-12">
      {/* Progress dots */}
      <div className="flex gap-2 mb-10">
        {([1, 2, 3] as Step[]).map((s) => (
          <div
            key={s}
            className={`h-1.5 rounded-full transition-all ${
              s === step
                ? "w-8 bg-[var(--primary)]"
                : s < step
                ? "w-4 bg-[var(--primary)]/50"
                : "w-4 bg-[var(--muted)]"
            }`}
          />
        ))}
      </div>

      <div className="w-full max-w-sm">
        {/* ── Step 1: Topics ── */}
        {step === 1 && (
          <>
            <h1 className="font-display text-2xl font-semibold text-[var(--text-primary)] mb-2">
              What are you into?
            </h1>
            <p className="text-sm text-[var(--text-secondary)] mb-8">
              Pick topics and we&apos;ll personalise your feed. You can change this anytime.
            </p>

            <div className="grid grid-cols-2 gap-2 mb-10">
              {TOPICS.map((t) => {
                const active = topics.includes(t.value);
                return (
                  <button
                    key={t.value}
                    onClick={() => toggleTopic(t.value)}
                    className={`relative flex items-center justify-between px-4 py-3 rounded-xl border text-sm font-medium transition-all ${
                      active
                        ? "border-[var(--primary)] bg-[var(--primary)]/10 text-[var(--primary)]"
                        : "border-[var(--border)] bg-[var(--surface)] text-[var(--text-primary)] hover:border-[var(--primary)]/40"
                    }`}
                  >
                    {t.label}
                    {active && (
                      <Check size={14} className="text-[var(--primary)]" />
                    )}
                  </button>
                );
              })}
            </div>

            <button
              onClick={() => setStep(2)}
              className="w-full flex items-center justify-center gap-2 py-3 rounded-xl bg-[var(--primary)] text-white text-sm font-semibold hover:opacity-90 transition-opacity"
            >
              {topics.length === 0 ? "Skip for now" : "Continue"}
              <ArrowRight size={16} />
            </button>
          </>
        )}

        {/* ── Step 2: Language ── */}
        {step === 2 && (
          <>
            <div className="w-10 h-10 rounded-xl bg-[var(--muted)] flex items-center justify-center mb-5">
              <Globe size={20} className="text-[var(--text-secondary)]" />
            </div>
            <h1 className="font-display text-2xl font-semibold text-[var(--text-primary)] mb-2">
              Preferred language
            </h1>
            <p className="text-sm text-[var(--text-secondary)] mb-8">
              We&apos;ll prioritise articles in your chosen language.
            </p>

            <div className="flex flex-col gap-2 mb-10">
              {LANGUAGES.map((l) => (
                <button
                  key={l.value}
                  onClick={() => setLanguage(l.value)}
                  className={`flex items-center justify-between px-4 py-3.5 rounded-xl border text-sm font-medium transition-all ${
                    language === l.value
                      ? "border-[var(--primary)] bg-[var(--primary)]/10 text-[var(--primary)]"
                      : "border-[var(--border)] bg-[var(--surface)] text-[var(--text-primary)] hover:border-[var(--primary)]/40"
                  }`}
                >
                  {l.label}
                  {language === l.value && <Check size={14} className="text-[var(--primary)]" />}
                </button>
              ))}
            </div>

            <button
              onClick={() => setStep(3)}
              className="w-full flex items-center justify-center gap-2 py-3 rounded-xl bg-[var(--primary)] text-white text-sm font-semibold hover:opacity-90 transition-opacity"
            >
              Continue
              <ArrowRight size={16} />
            </button>
          </>
        )}

        {/* ── Step 3: Notifications ── */}
        {step === 3 && (
          <>
            <div className="w-10 h-10 rounded-xl bg-[var(--primary)]/10 flex items-center justify-center mb-5">
              <Bell size={20} className="text-[var(--primary)]" />
            </div>
            <h1 className="font-display text-2xl font-semibold text-[var(--text-primary)] mb-2">
              Stay in the loop
            </h1>
            <p className="text-sm text-[var(--text-secondary)] mb-8">
              Get a daily digest of the top stories matching your interests, straight to your inbox.
            </p>

            <div className="p-4 rounded-xl border border-[var(--border)] bg-[var(--surface)] mb-4">
              <p className="text-xs text-[var(--text-secondary)]">
                Notification preferences can be managed in your profile settings at any time.
              </p>
            </div>

            <button
              onClick={finish}
              disabled={saving}
              className="w-full flex items-center justify-center gap-2 py-3 rounded-xl bg-[var(--primary)] text-white text-sm font-semibold hover:opacity-90 transition-opacity disabled:opacity-60"
            >
              {saving ? "Saving…" : "Get started"}
              {!saving && <ArrowRight size={16} />}
            </button>

            <button
              onClick={finish}
              disabled={saving}
              className="w-full mt-2 py-2.5 text-sm text-[var(--text-secondary)] hover:text-[var(--text-primary)] transition-colors"
            >
              Skip
            </button>
          </>
        )}
      </div>
    </div>
  );
}
