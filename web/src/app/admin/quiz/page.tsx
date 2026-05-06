"use client";

import { useState, useEffect } from "react";
import { Plus, Eye, EyeOff, Trash2, Sparkles } from "lucide-react";

interface Quiz {
  id: string;
  title: string | null;
  scheduled_for: string;
  is_published: boolean;
  xp_reward: number;
  questionCount: number;
}

interface QuestionDraft {
  question: string;
  options: string[];
  correct_index: number;
  explanation: string;
  time_limit: number;
}

const emptyQuestion = (): QuestionDraft => ({
  question: "",
  options: ["", "", "", ""],
  correct_index: 0,
  explanation: "",
  time_limit: 20,
});

export default function AdminQuizPage() {
  const [quizzes, setQuizzes] = useState<Quiz[]>([]);
  const [loading, setLoading] = useState(true);
  const [toggling, setToggling] = useState<string | null>(null);
  const [showForm, setShowForm] = useState(false);
  const [generating, setGenerating] = useState(false);
  const [genResult, setGenResult] = useState<{ created: number; errors?: string[] } | null>(null);
  const [scheduledFor, setScheduledFor] = useState(new Date().toISOString().slice(0, 10));
  const [title, setTitle] = useState("Daily News Quiz");
  const [xpReward, setXpReward] = useState(100);
  const [questions, setQuestions] = useState<QuestionDraft[]>([emptyQuestion()]);
  const [saving, setSaving] = useState(false);
  const [formError, setFormError] = useState<string | null>(null);

  useEffect(() => {
    fetch("/api/v1/admin/quiz")
      .then((r) => r.json())
      .then(({ data }) => setQuizzes(data ?? []))
      .finally(() => setLoading(false));
  }, []);

  const generateQuizzes = async () => {
    setGenerating(true);
    setGenResult(null);
    try {
      const res = await fetch("/api/v1/internal/generate-quizzes", { method: "POST" });
      const json = await res.json();
      if (json.data) {
        setGenResult(json.data);
        // Refresh quiz list
        fetch("/api/v1/admin/quiz")
          .then((r) => r.json())
          .then(({ data }) => setQuizzes(data ?? []));
      } else {
        setGenResult({ created: 0, errors: [json.error?.message ?? "Unknown error"] });
      }
    } catch {
      setGenResult({ created: 0, errors: ["Network error"] });
    }
    setGenerating(false);
  };

  const togglePublish = async (quiz: Quiz) => {
    setToggling(quiz.id);
    const res = await fetch(`/api/v1/admin/quiz/${quiz.id}`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ is_published: !quiz.is_published }),
    });
    if (res.ok) {
      setQuizzes((prev) =>
        prev.map((q) => (q.id === quiz.id ? { ...q, is_published: !quiz.is_published } : q))
      );
    }
    setToggling(null);
  };

  const addQuestion = () => setQuestions((prev) => [...prev, emptyQuestion()]);

  const removeQuestion = (idx: number) =>
    setQuestions((prev) => prev.filter((_, i) => i !== idx));

  const updateQuestion = (idx: number, field: keyof QuestionDraft, value: unknown) => {
    setQuestions((prev) =>
      prev.map((q, i) => (i === idx ? { ...q, [field]: value } : q))
    );
  };

  const updateOption = (qIdx: number, oIdx: number, value: string) => {
    setQuestions((prev) =>
      prev.map((q, i) =>
        i === qIdx
          ? { ...q, options: q.options.map((o, j) => (j === oIdx ? value : o)) }
          : q
      )
    );
  };

  const saveQuiz = async (e: React.FormEvent) => {
    e.preventDefault();
    setFormError(null);

    for (const [i, q] of questions.entries()) {
      if (!q.question.trim()) { setFormError(`Question ${i + 1} text is empty.`); return; }
      if (q.options.some((o) => !o.trim())) { setFormError(`Question ${i + 1} has empty options.`); return; }
    }

    setSaving(true);
    const res = await fetch("/api/v1/admin/quiz", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        title,
        scheduled_for: scheduledFor,
        xp_reward: xpReward,
        questions: questions.map((q) => ({
          question: q.question.trim(),
          options: q.options.map((o) => o.trim()),
          correct_index: q.correct_index,
          explanation: q.explanation.trim() || null,
          time_limit: q.time_limit,
        })),
      }),
    });

    if (res.ok) {
      const { data } = await res.json();
      setQuizzes((prev) => [
        {
          id: data.id,
          title,
          scheduled_for: scheduledFor,
          is_published: false,
          xp_reward: xpReward,
          questionCount: questions.length,
        },
        ...prev,
      ]);
      setShowForm(false);
      setQuestions([emptyQuestion()]);
    } else {
      const { error } = await res.json();
      setFormError(error?.message ?? "Failed to save quiz.");
    }
    setSaving(false);
  };

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <h1 className="font-display text-2xl font-semibold text-[var(--text-primary)]">
          Quizzes
        </h1>
        <div className="flex items-center gap-2">
          <button
            onClick={generateQuizzes}
            disabled={generating}
            className="flex items-center gap-1.5 px-4 py-2 rounded-xl border border-[var(--border)] text-sm font-medium text-[var(--text-primary)] hover:border-[var(--primary)] hover:text-[var(--primary)] transition-colors disabled:opacity-50"
          >
            <Sparkles size={15} />
            {generating ? "Generating…" : "AI Generate 30 days"}
          </button>
          <button
            onClick={() => setShowForm((v) => !v)}
            className="flex items-center gap-1.5 px-4 py-2 rounded-xl bg-[var(--primary)] text-white text-sm font-medium hover:opacity-90 transition-opacity"
          >
            <Plus size={15} />
            New quiz
          </button>
        </div>
      </div>

      {/* Generation result banner */}
      {genResult && (
        <div className={`mb-4 p-3 rounded-xl border text-sm ${
          genResult.errors?.length
            ? "border-amber-400/40 bg-amber-500/5 text-amber-700"
            : "border-green-400/40 bg-green-500/5 text-green-700"
        }`}>
          {genResult.created > 0 && <span>✓ Created {genResult.created} quiz{genResult.created !== 1 ? "zes" : ""}. </span>}
          {genResult.errors?.map((e, i) => <span key={i} className="block text-xs opacity-70">{e}</span>)}
          {genResult.created === 0 && !genResult.errors?.length && <span>All upcoming dates already have quizzes.</span>}
        </div>
      )}

      {/* ── Create form ── */}
      {showForm && (
        <form onSubmit={saveQuiz} className="mb-8 p-5 rounded-2xl border border-[var(--border)] bg-[var(--surface)] space-y-5">
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
            <input
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              placeholder="Quiz title"
              className="col-span-1 sm:col-span-1 px-3 py-2 rounded-lg border border-[var(--border)] bg-[var(--background)] text-sm focus:outline-none focus:border-[var(--primary)]"
            />
            <input
              type="date"
              value={scheduledFor}
              onChange={(e) => setScheduledFor(e.target.value)}
              className="px-3 py-2 rounded-lg border border-[var(--border)] bg-[var(--background)] text-sm focus:outline-none focus:border-[var(--primary)]"
            />
            <input
              type="number"
              value={xpReward}
              onChange={(e) => setXpReward(Number(e.target.value))}
              placeholder="XP reward"
              min={10}
              max={500}
              className="px-3 py-2 rounded-lg border border-[var(--border)] bg-[var(--background)] text-sm focus:outline-none focus:border-[var(--primary)]"
            />
          </div>

          {/* Questions */}
          <div className="space-y-4">
            {questions.map((q, qi) => (
              <div key={qi} className="p-4 rounded-xl border border-[var(--border)] bg-[var(--background)] space-y-3">
                <div className="flex items-center justify-between">
                  <span className="text-xs font-semibold text-[var(--text-secondary)] uppercase tracking-wide">
                    Question {qi + 1}
                  </span>
                  {questions.length > 1 && (
                    <button type="button" onClick={() => removeQuestion(qi)}>
                      <Trash2 size={14} className="text-[var(--text-secondary)] hover:text-red-500" />
                    </button>
                  )}
                </div>

                <textarea
                  value={q.question}
                  onChange={(e) => updateQuestion(qi, "question", e.target.value)}
                  placeholder="Question text…"
                  rows={2}
                  className="w-full px-3 py-2 rounded-lg border border-[var(--border)] bg-[var(--surface)] text-sm focus:outline-none focus:border-[var(--primary)] resize-none"
                />

                <div className="grid grid-cols-2 gap-2">
                  {q.options.map((opt, oi) => (
                    <div key={oi} className="flex items-center gap-2">
                      <input
                        type="radio"
                        name={`correct-${qi}`}
                        checked={q.correct_index === oi}
                        onChange={() => updateQuestion(qi, "correct_index", oi)}
                        className="accent-[var(--primary)] shrink-0"
                        title="Mark as correct"
                      />
                      <input
                        value={opt}
                        onChange={(e) => updateOption(qi, oi, e.target.value)}
                        placeholder={`Option ${String.fromCharCode(65 + oi)}`}
                        className="flex-1 px-2 py-1.5 rounded-lg border border-[var(--border)] bg-[var(--surface)] text-sm focus:outline-none focus:border-[var(--primary)]"
                      />
                    </div>
                  ))}
                </div>

                <div className="flex gap-3">
                  <input
                    value={q.explanation}
                    onChange={(e) => updateQuestion(qi, "explanation", e.target.value)}
                    placeholder="Explanation (optional)"
                    className="flex-1 px-3 py-1.5 rounded-lg border border-[var(--border)] bg-[var(--surface)] text-sm focus:outline-none focus:border-[var(--primary)]"
                  />
                  <input
                    type="number"
                    value={q.time_limit}
                    onChange={(e) => updateQuestion(qi, "time_limit", Number(e.target.value))}
                    min={5}
                    max={60}
                    className="w-20 px-2 py-1.5 rounded-lg border border-[var(--border)] bg-[var(--surface)] text-sm focus:outline-none focus:border-[var(--primary)]"
                    title="Time limit (s)"
                  />
                </div>
              </div>
            ))}
          </div>

          <button
            type="button"
            onClick={addQuestion}
            className="flex items-center gap-1.5 text-sm text-[var(--primary)] hover:underline"
          >
            <Plus size={14} /> Add question
          </button>

          {formError && <p className="text-xs text-red-500">{formError}</p>}

          <div className="flex gap-3 pt-1">
            <button
              type="submit"
              disabled={saving}
              className="px-5 py-2 rounded-xl bg-[var(--primary)] text-white text-sm font-semibold hover:opacity-90 disabled:opacity-50 transition-opacity"
            >
              {saving ? "Saving…" : "Save quiz"}
            </button>
            <button
              type="button"
              onClick={() => setShowForm(false)}
              className="px-5 py-2 rounded-xl border border-[var(--border)] text-sm text-[var(--text-secondary)] hover:text-[var(--text-primary)] transition-colors"
            >
              Cancel
            </button>
          </div>
        </form>
      )}

      {/* ── Quiz list ── */}
      <div className="rounded-2xl border border-[var(--border)] bg-[var(--surface)] overflow-hidden">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b border-[var(--border)]">
              <th className="text-left px-5 py-3 text-xs font-medium text-[var(--text-secondary)] uppercase tracking-wide">Title</th>
              <th className="text-left px-5 py-3 text-xs font-medium text-[var(--text-secondary)] uppercase tracking-wide hidden sm:table-cell">Date</th>
              <th className="text-left px-5 py-3 text-xs font-medium text-[var(--text-secondary)] uppercase tracking-wide hidden md:table-cell">Questions</th>
              <th className="text-left px-5 py-3 text-xs font-medium text-[var(--text-secondary)] uppercase tracking-wide">Status</th>
              <th className="px-5 py-3" />
            </tr>
          </thead>
          <tbody className="divide-y divide-[var(--border)]">
            {loading
              ? Array.from({ length: 3 }).map((_, i) => (
                  <tr key={i} className="animate-pulse">
                    <td className="px-5 py-4"><div className="h-3 w-40 rounded bg-[var(--muted)]" /></td>
                    <td className="px-5 py-4 hidden sm:table-cell"><div className="h-3 w-24 rounded bg-[var(--muted)]" /></td>
                    <td className="px-5 py-4 hidden md:table-cell"><div className="h-3 w-8 rounded bg-[var(--muted)]" /></td>
                    <td className="px-5 py-4"><div className="h-5 w-16 rounded-full bg-[var(--muted)]" /></td>
                    <td className="px-5 py-4" />
                  </tr>
                ))
              : quizzes.map((q) => (
                  <tr key={q.id} className="hover:bg-[var(--muted)] transition-colors">
                    <td className="px-5 py-3 font-medium text-[var(--text-primary)]">
                      {q.title ?? "Daily News Quiz"}
                    </td>
                    <td className="px-5 py-3 text-xs text-[var(--text-secondary)] hidden sm:table-cell">
                      {q.scheduled_for}
                    </td>
                    <td className="px-5 py-3 text-xs text-[var(--text-secondary)] hidden md:table-cell">
                      {q.questionCount}
                    </td>
                    <td className="px-5 py-3">
                      <span className={`px-2 py-0.5 rounded-full text-xs font-medium ${
                        q.is_published
                          ? "bg-green-500/10 text-green-600"
                          : "bg-[var(--muted)] text-[var(--text-secondary)]"
                      }`}>
                        {q.is_published ? "Published" : "Draft"}
                      </span>
                    </td>
                    <td className="px-5 py-3 text-right">
                      <button
                        onClick={() => togglePublish(q)}
                        disabled={toggling === q.id}
                        className="flex items-center gap-1 text-xs text-[var(--text-secondary)] hover:text-[var(--primary)] transition-colors disabled:opacity-50"
                      >
                        {toggling === q.id
                          ? "Saving…"
                          : q.is_published
                          ? <><EyeOff size={13} /> Unpublish</>
                          : <><Eye size={13} /> Publish</>}
                      </button>
                    </td>
                  </tr>
                ))}
          </tbody>
        </table>
        {!loading && quizzes.length === 0 && (
          <p className="text-sm text-[var(--text-secondary)] text-center py-10">No quizzes yet.</p>
        )}
      </div>
    </div>
  );
}
