"use client";

import { useState, useEffect, useCallback, useRef } from "react";
import { useRouter } from "next/navigation";
import {
  Trophy, Clock, CheckCircle, XCircle, Zap, Flame,
  ArrowRight, Grid3x3, BookOpen, Star, ChevronRight, RotateCcw
} from "lucide-react";
import { Navbar } from "@/components/layout/navbar";
import { Mascot, type MascotMood } from "@/components/quiz/mascot";

// ─────────────────────────────────────────────────────────────
// Types
// ─────────────────────────────────────────────────────────────
interface QuizQuestion {
  id: string;
  question: string;
  options: string[];
  timeLimit: number;
  position: number;
}

interface DailyQuizData {
  id: string;
  title: string;
  xpReward: number;
  scheduledFor: string;
  questions: QuizQuestion[];
  alreadyCompleted: boolean;
}

interface GeneralQuestion {
  id: string;
  question: string;
  options: string[];
  category: string;
  xpValue: number;
}

interface QuizResult {
  score: number;
  total: number;
  isPerfect: boolean;
  xpEarned: number;
  newStreak: number;
  correctAnswers: number[];
}

interface GeneralResult {
  score: number;
  total: number;
  xpEarned: number;
  streakBonus: number;
  newStreak: number;
  results: { questionId: string; correct: boolean; correctIndex: number; xpAwarded: number }[];
}

type Difficulty = "easy" | "medium" | "hard";
type Mode =
  | "hub"
  | "daily-loading" | "daily-playing" | "daily-done" | "daily-result"
  | "general-select" | "general-loading" | "general-playing" | "general-result";

// ─────────────────────────────────────────────────────────────
// Difficulty config
// ─────────────────────────────────────────────────────────────
const DIFFICULTY_CONFIG: Record<Difficulty, { label: string; color: string; xp: number; time: number; desc: string }> = {
  easy:   { label: "Easy",   color: "text-green-500",  xp: 10,  time: 30, desc: "5 questions · 10 XP each · 30s per question" },
  medium: { label: "Medium", color: "text-yellow-500", xp: 20,  time: 25, desc: "5 questions · 20 XP each · 25s per question" },
  hard:   { label: "Hard",   color: "text-red-500",    xp: 40,  time: 20, desc: "5 questions · 40 XP each · 20s per question" },
};

const TIME_LIMIT: Record<Difficulty, number> = { easy: 30, medium: 25, hard: 20 };

// ─────────────────────────────────────────────────────────────
// Main component
// ─────────────────────────────────────────────────────────────
export default function QuizPage() {
  const router = useRouter();
  const [mode, setMode] = useState<Mode>("hub");

  // Daily quiz state
  const [dailyQuiz, setDailyQuiz] = useState<DailyQuizData | null>(null);
  const [dailyCurrentIdx, setDailyCurrentIdx] = useState(0);
  const [dailySelected, setDailySelected] = useState<(number | null)[]>([]);
  const [dailyTimeLeft, setDailyTimeLeft] = useState(0);
  const [dailyResult, setDailyResult] = useState<QuizResult | null>(null);
  const [dailySubmitting, setDailySubmitting] = useState(false);
  const dailyTimerRef = useRef<ReturnType<typeof setInterval> | null>(null);

  // General quiz state
  const [difficulty, setDifficulty] = useState<Difficulty>("easy");
  const [generalQuestions, setGeneralQuestions] = useState<GeneralQuestion[]>([]);
  const [generalCurrentIdx, setGeneralCurrentIdx] = useState(0);
  const [generalSelected, setGeneralSelected] = useState<(number | null)[]>([]);
  const [generalTimeLeft, setGeneralTimeLeft] = useState(0);
  const [generalResult, setGeneralResult] = useState<GeneralResult | null>(null);
  const [generalSubmitting, setGeneralSubmitting] = useState(false);
  const generalTimerRef = useRef<ReturnType<typeof setInterval> | null>(null);

  // Mascot
  const [mascotMood, setMascotMood] = useState<MascotMood>("neutral");
  const [mascotMsg, setMascotMsg] = useState("What shall we learn today?");

  const setMascot = (mood: MascotMood, msg: string) => {
    setMascotMood(mood);
    setMascotMsg(msg);
  };

  // ── Load daily quiz ──
  const loadDailyQuiz = useCallback(async () => {
    setMode("daily-loading");
    try {
      const res = await fetch("/api/v1/quiz/today");
      const { data, error } = await res.json();
      if (error?.code === "NOT_FOUND" || !data) {
        setMascot("sad", "No daily quiz today. Try general knowledge!");
        setMode("hub");
        return;
      }
      setDailyQuiz(data);
      setDailySelected(new Array(data.questions.length).fill(null));
      if (data.alreadyCompleted) {
        setMascot("happy", "You already aced today's quiz!");
        setMode("daily-done");
      } else {
        setDailyTimeLeft(data.questions[0]?.timeLimit ?? 20);
        setMascot("excited", "Good luck on today's news quiz!");
        setMode("daily-playing");
      }
    } catch {
      setMascot("sad", "Couldn't load the quiz. Try again!");
      setMode("hub");
    }
  }, []);

  // ── Daily quiz: advance or submit ──
  const dailyAdvanceOrSubmit = useCallback(
    async (answers: (number | null)[]) => {
      if (!dailyQuiz) return;
      if (dailyCurrentIdx < dailyQuiz.questions.length - 1) {
        const next = dailyCurrentIdx + 1;
        setDailyCurrentIdx(next);
        setDailyTimeLeft(dailyQuiz.questions[next].timeLimit);
      } else {
        setDailySubmitting(true);
        try {
          const res = await fetch("/api/v1/quiz/submit", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ quizId: dailyQuiz.id, answers: answers.map((a) => a ?? -1) }),
          });
          if (res.status === 401) { router.push("/"); return; }
          // 409 = already submitted today (alreadyCompleted check in /today was
          // bypassed somehow, e.g. stale client state). Show the done screen.
          if (res.status === 409) {
            setMascot("happy", "You already completed today's quiz!");
            setMode("daily-done");
            return;
          }
          const json = await res.json();
          if (!json.data) {
            setMascot("sad", "Something went wrong. Try again later!");
            setMode("hub");
            return;
          }
          setDailyResult(json.data);
          if (json.data.isPerfect) setMascot("excited", "PERFECT SCORE! You're unstoppable!");
          else if (json.data.score >= json.data.total / 2) setMascot("happy", "Great job! Keep it up!");
          else setMascot("sad", "Don't worry — practice makes perfect!");
          setMode("daily-result");
        } catch {
          setMascot("sad", "Couldn't submit. Check your connection!");
          setMode("hub");
        } finally {
          setDailySubmitting(false);
        }
      }
    },
    [dailyQuiz, dailyCurrentIdx, router]
  );

  // Daily countdown
  useEffect(() => {
    if (mode !== "daily-playing") return;
    dailyTimerRef.current = setInterval(() => {
      setDailyTimeLeft((t) => {
        if (t <= 1) {
          setDailySelected((prev) => {
            const next = [...prev];
            dailyAdvanceOrSubmit(next);
            return next;
          });
          return 0;
        }
        return t - 1;
      });
    }, 1000);
    return () => { if (dailyTimerRef.current) clearInterval(dailyTimerRef.current); };
  }, [mode, dailyCurrentIdx, dailyAdvanceOrSubmit]);

  const handleDailySelect = (optionIdx: number) => {
    if (dailySelected[dailyCurrentIdx] !== null) return;
    if (dailyTimerRef.current) clearInterval(dailyTimerRef.current);
    const next = [...dailySelected];
    next[dailyCurrentIdx] = optionIdx;
    setDailySelected(next);
    setTimeout(() => dailyAdvanceOrSubmit(next), 700);
  };

  // ── Load general quiz ──
  const loadGeneralQuiz = useCallback(async (diff: Difficulty) => {
    setDifficulty(diff);
    setMode("general-loading");
    try {
      const res = await fetch(`/api/v1/quiz/general?difficulty=${diff}`);
      const { data, error } = await res.json();
      if (error || !data?.questions) {
        setMascot("sad", "Couldn't load questions. Try again!");
        setMode("general-select");
        return;
      }
      setGeneralQuestions(data.questions);
      setGeneralSelected(new Array(data.questions.length).fill(null));
      setGeneralCurrentIdx(0);
      setGeneralTimeLeft(TIME_LIMIT[diff]);
      setMascot("thinking", DIFFICULTY_CONFIG[diff].label === "Hard" ? "This one's tough — think carefully!" : "Let's go!");
      setMode("general-playing");
    } catch {
      setMascot("sad", "Couldn't load questions. Try again!");
      setMode("general-select");
    }
  }, []);

  // ── General quiz: advance or submit ──
  const generalAdvanceOrSubmit = useCallback(
    async (answers: (number | null)[]) => {
      if (generalCurrentIdx < generalQuestions.length - 1) {
        const next = generalCurrentIdx + 1;
        setGeneralCurrentIdx(next);
        setGeneralTimeLeft(TIME_LIMIT[difficulty]);
      } else {
        setGeneralSubmitting(true);
        try {
          const res = await fetch("/api/v1/quiz/general/submit", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({
              questionIds: generalQuestions.map((q) => q.id),
              answers: answers.map((a) => a ?? -1),
              difficulty,
            }),
          });
          if (res.status === 401) { router.push("/"); return; }
          const { data } = await res.json();
          setGeneralResult(data);
          if (data?.score === data?.total) setMascot("excited", "Perfect! You aced it!");
          else if (data?.score >= Math.ceil(data?.total / 2)) setMascot("happy", `${data?.score}/${data?.total} — nice work!`);
          else setMascot("sad", `${data?.score}/${data?.total} — keep practicing!`);
          setMode("general-result");
        } catch {
          setMode("general-result");
        } finally {
          setGeneralSubmitting(false);
        }
      }
    },
    [generalCurrentIdx, generalQuestions, difficulty, router]
  );

  // General countdown
  useEffect(() => {
    if (mode !== "general-playing") return;
    generalTimerRef.current = setInterval(() => {
      setGeneralTimeLeft((t) => {
        if (t <= 1) {
          setGeneralSelected((prev) => {
            const next = [...prev];
            generalAdvanceOrSubmit(next);
            return next;
          });
          return 0;
        }
        return t - 1;
      });
    }, 1000);
    return () => { if (generalTimerRef.current) clearInterval(generalTimerRef.current); };
  }, [mode, generalCurrentIdx, generalAdvanceOrSubmit]);

  const handleGeneralSelect = (optionIdx: number) => {
    if (generalSelected[generalCurrentIdx] !== null) return;
    if (generalTimerRef.current) clearInterval(generalTimerRef.current);
    const next = [...generalSelected];
    next[generalCurrentIdx] = optionIdx;
    setGeneralSelected(next);
    setTimeout(() => generalAdvanceOrSubmit(next), 700);
  };

  // ─────────────────────────────────────────────────────────────
  // HUB
  // ─────────────────────────────────────────────────────────────
  if (mode === "hub") {
    return (
      <div className="min-h-screen bg-[var(--background)]">
        <Navbar />
        <div className="max-w-lg mx-auto px-5 pt-8 pb-24">
          {/* Mascot banner */}
          <div className="flex items-center gap-5 mb-8 p-5 rounded-3xl bg-[var(--surface)] border border-[var(--border)]">
            <Mascot mood={mascotMood} size={96} />
            <div>
              <p className="text-xs font-medium text-[var(--primary)] uppercase tracking-wider mb-0.5">Nex says</p>
              <p className="text-base font-semibold text-[var(--text-primary)] leading-snug">{mascotMsg}</p>
            </div>
          </div>

          <h1 className="font-display text-2xl font-bold text-[var(--text-primary)] mb-6">Quiz Centre</h1>

          {/* Cards */}
          <div className="flex flex-col gap-4">
            {/* Daily news quiz */}
            <button
              onClick={loadDailyQuiz}
              className="group w-full text-left p-5 rounded-3xl border border-[var(--border)] bg-[var(--surface)] hover:border-[var(--primary)]/50 transition-all"
            >
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-4">
                  <div className="w-12 h-12 rounded-2xl bg-[var(--primary)]/10 flex items-center justify-center">
                    <BookOpen size={22} className="text-[var(--primary)]" />
                  </div>
                  <div>
                    <p className="font-semibold text-[var(--text-primary)] mb-0.5">Daily News Quiz</p>
                    <p className="text-xs text-[var(--text-secondary)]">5 questions · Up to 50 XP · Resets daily</p>
                  </div>
                </div>
                <ChevronRight size={18} className="text-[var(--muted)] group-hover:text-[var(--primary)] transition-colors" />
              </div>
            </button>

            {/* General knowledge */}
            <button
              onClick={() => { setMascot("thinking", "Pick your difficulty level!"); setMode("general-select"); }}
              className="group w-full text-left p-5 rounded-3xl border border-[var(--border)] bg-[var(--surface)] hover:border-[var(--primary)]/50 transition-all"
            >
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-4">
                  <div className="w-12 h-12 rounded-2xl bg-yellow-500/10 flex items-center justify-center">
                    <Star size={22} className="text-yellow-500" />
                  </div>
                  <div>
                    <p className="font-semibold text-[var(--text-primary)] mb-0.5">General Knowledge</p>
                    <p className="text-xs text-[var(--text-secondary)]">3 tiers · Up to 40 XP per question · Unlimited plays</p>
                  </div>
                </div>
                <ChevronRight size={18} className="text-[var(--muted)] group-hover:text-[var(--primary)] transition-colors" />
              </div>
            </button>

            {/* Crossword */}
            <button
              onClick={() => router.push("/crossword")}
              className="group w-full text-left p-5 rounded-3xl border border-[var(--border)] bg-[var(--surface)] hover:border-[var(--primary)]/50 transition-all"
            >
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-4">
                  <div className="w-12 h-12 rounded-2xl bg-purple-500/10 flex items-center justify-center">
                    <Grid3x3 size={22} className="text-purple-500" />
                  </div>
                  <div>
                    <p className="font-semibold text-[var(--text-primary)] mb-0.5">Daily Crossword</p>
                    <p className="text-xs text-[var(--text-secondary)]">5×5 grid · Up to 100 XP · New puzzle daily</p>
                  </div>
                </div>
                <ChevronRight size={18} className="text-[var(--muted)] group-hover:text-[var(--primary)] transition-colors" />
              </div>
            </button>
          </div>

          {/* Leaderboard link */}
          <button
            onClick={() => router.push("/leaderboard")}
            className="w-full mt-4 py-3 rounded-2xl border border-[var(--border)] text-sm text-[var(--text-secondary)] hover:text-[var(--text-primary)] flex items-center justify-center gap-2 transition-colors"
          >
            <Trophy size={14} />
            View Leaderboard
          </button>
        </div>
      </div>
    );
  }

  // ─────────────────────────────────────────────────────────────
  // DAILY QUIZ — loading
  // ─────────────────────────────────────────────────────────────
  if (mode === "daily-loading") {
    return (
      <div className="min-h-screen bg-[var(--background)] flex flex-col items-center justify-center gap-5">
        <Mascot mood="thinking" size={100} />
        <p className="text-sm text-[var(--text-secondary)] animate-pulse">Loading today&apos;s quiz…</p>
      </div>
    );
  }

  // ─────────────────────────────────────────────────────────────
  // DAILY QUIZ — already done
  // ─────────────────────────────────────────────────────────────
  if (mode === "daily-done") {
    return (
      <div className="min-h-screen bg-[var(--background)]">
        <Navbar />
        <div className="max-w-lg mx-auto px-5 pt-16 text-center">
          <Mascot mood="happy" size={110} className="mx-auto mb-4" />
          <h1 className="font-display text-2xl font-semibold text-[var(--text-primary)] mb-2">Already completed!</h1>
          <p className="text-sm text-[var(--text-secondary)] mb-8">You&apos;ve done today&apos;s quiz. Come back tomorrow!</p>
          <div className="flex flex-col gap-3">
            <button
              onClick={() => { setMascot("thinking", "Pick your difficulty!"); setMode("general-select"); }}
              className="w-full py-3 rounded-xl bg-[var(--primary)] text-white text-sm font-semibold hover:opacity-90 transition-opacity"
            >
              Try General Knowledge
            </button>
            <button onClick={() => setMode("hub")} className="w-full py-3 rounded-xl border border-[var(--border)] text-sm text-[var(--text-secondary)]">
              Back to hub
            </button>
          </div>
        </div>
      </div>
    );
  }

  // ─────────────────────────────────────────────────────────────
  // DAILY QUIZ — playing
  // ─────────────────────────────────────────────────────────────
  if (mode === "daily-playing" && dailyQuiz) {
    const currentQ = dailyQuiz.questions[dailyCurrentIdx];
    const isAnswered = dailySelected[dailyCurrentIdx] !== null;
    const maxTime = currentQ?.timeLimit ?? 20;

    return (
      <div className="min-h-screen bg-[var(--background)]">
        <Navbar />
        <div className="max-w-lg mx-auto px-5 pt-6 pb-24">
          <div className="flex items-center justify-between mb-4">
            <span className="text-sm text-[var(--text-secondary)]">{dailyCurrentIdx + 1} / {dailyQuiz.questions.length}</span>
            <div className={`flex items-center gap-1.5 text-sm font-semibold tabular-nums ${dailyTimeLeft <= 5 ? "text-red-500" : "text-[var(--text-secondary)]"}`}>
              <Clock size={14} />{dailyTimeLeft}s
            </div>
          </div>

          {/* Progress */}
          <div className="h-1.5 rounded-full bg-[var(--muted)] mb-3 overflow-hidden">
            <div className="h-full rounded-full bg-[var(--primary)] transition-all duration-300"
              style={{ width: `${((dailyCurrentIdx + 1) / dailyQuiz.questions.length) * 100}%` }} />
          </div>
          {/* Timer */}
          <div className="h-1 rounded-full bg-[var(--muted)] mb-8 overflow-hidden">
            <div className={`h-full rounded-full transition-all duration-1000 ${dailyTimeLeft <= 5 ? "bg-red-500" : "bg-[var(--accent)]"}`}
              style={{ width: `${(dailyTimeLeft / maxTime) * 100}%` }} />
          </div>

          <h2 className="font-display text-xl font-semibold text-[var(--text-primary)] mb-6 leading-snug">{currentQ?.question}</h2>

          <div className="flex flex-col gap-3">
            {currentQ?.options.map((opt, i) => {
              let style = "border-[var(--border)] bg-[var(--surface)] hover:border-[var(--primary)]/40 hover:bg-[var(--muted)]";
              if (isAnswered) {
                style = i === dailySelected[dailyCurrentIdx]
                  ? "border-[var(--primary)] bg-[var(--primary)]/10 text-[var(--primary)]"
                  : "border-[var(--border)] bg-[var(--surface)] opacity-40";
              }
              return (
                <button key={i} onClick={() => handleDailySelect(i)} disabled={isAnswered || dailySubmitting}
                  className={`w-full text-left px-5 py-3.5 rounded-2xl border text-sm font-medium transition-all ${style}`}>
                  <span className="inline-flex items-center gap-3">
                    <span className="w-6 h-6 rounded-full border border-current flex items-center justify-center text-xs font-bold shrink-0">
                      {String.fromCharCode(65 + i)}
                    </span>
                    {opt}
                  </span>
                </button>
              );
            })}
          </div>
          {dailySubmitting && <p className="text-center text-sm text-[var(--text-secondary)] mt-4 animate-pulse">Submitting…</p>}
        </div>
      </div>
    );
  }

  // ─────────────────────────────────────────────────────────────
  // DAILY QUIZ — result
  // ─────────────────────────────────────────────────────────────
  if (mode === "daily-result" && dailyResult) {
    const pct = Math.round((dailyResult.score / dailyResult.total) * 100);
    return (
      <div className="min-h-screen bg-[var(--background)]">
        <Navbar />
        <div className="max-w-lg mx-auto px-5 pt-8 pb-24">
          <div className="text-center mb-6">
            <Mascot mood={mascotMood} size={100} className="mx-auto mb-4" />
            <h1 className="font-display text-3xl font-bold text-[var(--text-primary)] mb-1">{dailyResult.score}/{dailyResult.total}</h1>
            <p className="text-sm text-[var(--text-secondary)]">{pct}% accuracy</p>
          </div>

          <div className="grid grid-cols-3 gap-3 mb-8">
            <StatCard icon={<Zap size={18} className="text-[var(--primary)]" />} value={`+${dailyResult.xpEarned}`} label="XP earned" />
            <StatCard icon={<Flame size={18} className="text-orange-500" />} value={String(dailyResult.newStreak)} label="Day streak" />
            <StatCard icon={<Trophy size={18} className="text-yellow-500" />} value={`${pct}%`} label="Score" />
          </div>

          {/* Answer review */}
          {dailyQuiz && (
            <div className="flex flex-col gap-3 mb-8">
              {dailyQuiz.questions.map((q, i) => {
                const ua = dailySelected[i];
                const correct = dailyResult.correctAnswers[i];
                const isCorrect = ua === correct;
                return (
                  <div key={q.id} className={`p-4 rounded-2xl border ${isCorrect ? "border-green-400/40 bg-green-500/5" : "border-red-400/40 bg-red-500/5"}`}>
                    <div className="flex items-start gap-2 mb-1.5">
                      {isCorrect ? <CheckCircle size={15} className="text-green-500 shrink-0 mt-0.5" /> : <XCircle size={15} className="text-red-500 shrink-0 mt-0.5" />}
                      <p className="text-sm font-medium text-[var(--text-primary)]">{q.question}</p>
                    </div>
                    <p className="text-xs text-[var(--text-secondary)] ml-5">Correct: <span className="font-medium text-[var(--text-primary)]">{q.options[correct]}</span></p>
                    {ua !== null && ua !== correct && <p className="text-xs text-red-500 ml-5 mt-0.5">Your answer: {q.options[ua]}</p>}
                    {ua === null && <p className="text-xs text-[var(--muted)] ml-5 mt-0.5">Time&apos;s up</p>}
                  </div>
                );
              })}
            </div>
          )}

          <div className="flex gap-3">
            <button onClick={() => router.push("/leaderboard")}
              className="flex-1 flex items-center justify-center gap-2 py-3 rounded-xl bg-[var(--primary)] text-white text-sm font-semibold hover:opacity-90">
              Leaderboard <ArrowRight size={14} />
            </button>
            <button onClick={() => setMode("hub")}
              className="flex-1 py-3 rounded-xl border border-[var(--border)] text-sm text-[var(--text-secondary)]">
              Back to hub
            </button>
          </div>
        </div>
      </div>
    );
  }

  // ─────────────────────────────────────────────────────────────
  // GENERAL — difficulty select
  // ─────────────────────────────────────────────────────────────
  if (mode === "general-select") {
    return (
      <div className="min-h-screen bg-[var(--background)]">
        <Navbar />
        <div className="max-w-lg mx-auto px-5 pt-8 pb-24">
          <div className="flex items-center gap-4 mb-8">
            <Mascot mood="thinking" size={80} />
            <div>
              <h1 className="font-display text-2xl font-bold text-[var(--text-primary)]">General Knowledge</h1>
              <p className="text-sm text-[var(--text-secondary)]">Choose your difficulty</p>
            </div>
          </div>

          <div className="flex flex-col gap-4">
            {(["easy", "medium", "hard"] as Difficulty[]).map((diff) => {
              const cfg = DIFFICULTY_CONFIG[diff];
              return (
                <button key={diff} onClick={() => loadGeneralQuiz(diff)}
                  className="group w-full text-left p-5 rounded-3xl border border-[var(--border)] bg-[var(--surface)] hover:border-[var(--primary)]/40 transition-all">
                  <div className="flex items-center justify-between">
                    <div>
                      <p className={`font-bold text-lg ${cfg.color} mb-0.5`}>{cfg.label}</p>
                      <p className="text-xs text-[var(--text-secondary)]">{cfg.desc}</p>
                    </div>
                    <div className={`text-2xl font-black ${cfg.color} opacity-30 group-hover:opacity-60 transition-opacity`}>
                      {diff === "easy" ? "✓" : diff === "medium" ? "⚡" : "🔥"}
                    </div>
                  </div>
                </button>
              );
            })}
          </div>

          <button onClick={() => setMode("hub")} className="w-full mt-5 py-3 rounded-xl border border-[var(--border)] text-sm text-[var(--text-secondary)]">
            Back to hub
          </button>
        </div>
      </div>
    );
  }

  // ─────────────────────────────────────────────────────────────
  // GENERAL — loading
  // ─────────────────────────────────────────────────────────────
  if (mode === "general-loading") {
    return (
      <div className="min-h-screen bg-[var(--background)] flex flex-col items-center justify-center gap-5">
        <Mascot mood="thinking" size={100} />
        <p className="text-sm text-[var(--text-secondary)] animate-pulse">Loading questions…</p>
      </div>
    );
  }

  // ─────────────────────────────────────────────────────────────
  // GENERAL — playing
  // ─────────────────────────────────────────────────────────────
  if (mode === "general-playing" && generalQuestions.length > 0) {
    const currentQ = generalQuestions[generalCurrentIdx];
    const isAnswered = generalSelected[generalCurrentIdx] !== null;
    const maxTime = TIME_LIMIT[difficulty];
    const cfg = DIFFICULTY_CONFIG[difficulty];

    return (
      <div className="min-h-screen bg-[var(--background)]">
        <Navbar />
        <div className="max-w-lg mx-auto px-5 pt-6 pb-24">
          <div className="flex items-center justify-between mb-4">
            <span className="text-sm text-[var(--text-secondary)]">
              <span className={`font-semibold ${cfg.color}`}>{cfg.label}</span> · {generalCurrentIdx + 1}/{generalQuestions.length}
            </span>
            <div className={`flex items-center gap-1.5 text-sm font-semibold tabular-nums ${generalTimeLeft <= 5 ? "text-red-500" : "text-[var(--text-secondary)]"}`}>
              <Clock size={14} />{generalTimeLeft}s
            </div>
          </div>

          <div className="h-1.5 rounded-full bg-[var(--muted)] mb-3 overflow-hidden">
            <div className="h-full rounded-full bg-[var(--primary)] transition-all duration-300"
              style={{ width: `${((generalCurrentIdx + 1) / generalQuestions.length) * 100}%` }} />
          </div>
          <div className="h-1 rounded-full bg-[var(--muted)] mb-8 overflow-hidden">
            <div className={`h-full rounded-full transition-all duration-1000 ${generalTimeLeft <= 5 ? "bg-red-500" : "bg-[var(--accent)]"}`}
              style={{ width: `${(generalTimeLeft / maxTime) * 100}%` }} />
          </div>

          <div className="mb-2">
            <span className="text-xs font-medium text-[var(--text-secondary)] uppercase tracking-wider">{currentQ?.category}</span>
          </div>
          <h2 className="font-display text-xl font-semibold text-[var(--text-primary)] mb-6 leading-snug">{currentQ?.question}</h2>

          <div className="flex flex-col gap-3">
            {currentQ?.options.map((opt, i) => {
              let style = "border-[var(--border)] bg-[var(--surface)] hover:border-[var(--primary)]/40 hover:bg-[var(--muted)]";
              if (isAnswered) {
                style = i === generalSelected[generalCurrentIdx]
                  ? "border-[var(--primary)] bg-[var(--primary)]/10 text-[var(--primary)]"
                  : "border-[var(--border)] bg-[var(--surface)] opacity-40";
              }
              return (
                <button key={i} onClick={() => handleGeneralSelect(i)} disabled={isAnswered || generalSubmitting}
                  className={`w-full text-left px-5 py-3.5 rounded-2xl border text-sm font-medium transition-all ${style}`}>
                  <span className="inline-flex items-center gap-3">
                    <span className="w-6 h-6 rounded-full border border-current flex items-center justify-center text-xs font-bold shrink-0">
                      {String.fromCharCode(65 + i)}
                    </span>
                    {opt}
                  </span>
                </button>
              );
            })}
          </div>
          {generalSubmitting && <p className="text-center text-sm text-[var(--text-secondary)] mt-4 animate-pulse">Submitting…</p>}
        </div>
      </div>
    );
  }

  // ─────────────────────────────────────────────────────────────
  // GENERAL — result
  // ─────────────────────────────────────────────────────────────
  if (mode === "general-result" && generalResult) {
    const pct = Math.round((generalResult.score / generalResult.total) * 100);
    const cfg = DIFFICULTY_CONFIG[difficulty];

    return (
      <div className="min-h-screen bg-[var(--background)]">
        <Navbar />
        <div className="max-w-lg mx-auto px-5 pt-8 pb-24">
          <div className="text-center mb-6">
            <Mascot mood={mascotMood} size={100} className="mx-auto mb-4" />
            <p className={`text-sm font-semibold ${cfg.color} mb-1`}>{cfg.label} Mode</p>
            <h1 className="font-display text-3xl font-bold text-[var(--text-primary)] mb-1">{generalResult.score}/{generalResult.total}</h1>
            <p className="text-sm text-[var(--text-secondary)]">{pct}% accuracy</p>
          </div>

          <div className="grid grid-cols-3 gap-3 mb-8">
            <StatCard icon={<Zap size={18} className="text-[var(--primary)]" />} value={`+${generalResult.xpEarned}`} label="XP earned" />
            <StatCard icon={<Flame size={18} className="text-orange-500" />} value={String(generalResult.newStreak)} label="Day streak" />
            <StatCard icon={<Trophy size={18} className="text-yellow-500" />} value={`${pct}%`} label="Score" />
          </div>

          {/* Answer review */}
          <div className="flex flex-col gap-3 mb-8">
            {generalQuestions.map((q, i) => {
              const res = generalResult.results[i];
              const ua = generalSelected[i];
              return (
                <div key={q.id} className={`p-4 rounded-2xl border ${res?.correct ? "border-green-400/40 bg-green-500/5" : "border-red-400/40 bg-red-500/5"}`}>
                  <div className="flex items-start gap-2 mb-1.5">
                    {res?.correct ? <CheckCircle size={15} className="text-green-500 shrink-0 mt-0.5" /> : <XCircle size={15} className="text-red-500 shrink-0 mt-0.5" />}
                    <p className="text-sm font-medium text-[var(--text-primary)]">{q.question}</p>
                  </div>
                  <p className="text-xs text-[var(--text-secondary)] ml-5">
                    Correct: <span className="font-medium text-[var(--text-primary)]">{q.options[res?.correctIndex ?? 0]}</span>
                  </p>
                  {ua !== null && !res?.correct && (
                    <p className="text-xs text-red-500 ml-5 mt-0.5">Your answer: {q.options[ua]}</p>
                  )}
                  {ua === null && <p className="text-xs text-[var(--muted)] ml-5 mt-0.5">Time&apos;s up</p>}
                  {res?.xpAwarded > 0 && <p className="text-xs text-[var(--primary)] ml-5 mt-0.5">+{res.xpAwarded} XP</p>}
                </div>
              );
            })}
          </div>

          <div className="flex gap-3">
            <button onClick={() => loadGeneralQuiz(difficulty)}
              className="flex-1 flex items-center justify-center gap-2 py-3 rounded-xl bg-[var(--primary)] text-white text-sm font-semibold hover:opacity-90">
              <RotateCcw size={14} /> Play again
            </button>
            <button onClick={() => setMode("general-select")}
              className="flex-1 py-3 rounded-xl border border-[var(--border)] text-sm text-[var(--text-secondary)]">
              Change difficulty
            </button>
          </div>
          <button onClick={() => setMode("hub")} className="w-full mt-3 py-3 rounded-xl border border-[var(--border)] text-sm text-[var(--text-secondary)]">
            Back to hub
          </button>
        </div>
      </div>
    );
  }

  return null;
}

// ─────────────────────────────────────────────────────────────
// Stat card helper
// ─────────────────────────────────────────────────────────────
function StatCard({ icon, value, label }: { icon: React.ReactNode; value: string; label: string }) {
  return (
    <div className="p-4 rounded-2xl border border-[var(--border)] bg-[var(--surface)] text-center">
      <div className="flex justify-center mb-1">{icon}</div>
      <p className="text-lg font-bold text-[var(--text-primary)]">{value}</p>
      <p className="text-xs text-[var(--text-secondary)]">{label}</p>
    </div>
  );
}
