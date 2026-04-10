"use client";

import { useState, useEffect, useRef, useCallback } from "react";
import { useRouter } from "next/navigation";
import { ArrowLeft, Clock, CheckCircle, Zap, Flame, Trophy, RotateCcw, HelpCircle } from "lucide-react";
import { Navbar } from "@/components/layout/navbar";
import { Mascot, type MascotMood } from "@/components/quiz/mascot";

// ─────────────────────────────────────────────────────────────
// Puzzle definition
// ─────────────────────────────────────────────────────────────
/**
 * 5×5 grid — null = black square
 *
 *  O  R  B  I  T
 *  .  O  I  .  R
 *  P  U  L  S  E
 *  .  S  L  .  E
 *  N  E  X  U  S
 *
 * Across: ORBIT (1), PULSE (3), NEXUS (5)
 * Down:   ROUSE (2, col 1), BILL (4, col 2, len 4), TREES (6, col 4)
 */
const ANSWER: (string | null)[][] = [
  ["O", "R", "B", "I", "T"],
  [null, "O", "I", null, "R"],
  ["P", "U", "L", "S", "E"],
  [null, "S", "L", null, "E"],
  ["N", "E", "X", "U", "S"],
];

interface Clue {
  id: string;
  number: number;
  direction: "across" | "down";
  row: number;
  col: number;
  length: number;
  clue: string;
}

const CLUES: Clue[] = [
  { id: "1A", number: 1, direction: "across", row: 0, col: 0, length: 5, clue: "Earth's path around the sun; also a space station module (5)" },
  { id: "3A", number: 3, direction: "across", row: 2, col: 0, length: 5, clue: "Heartbeat rhythm; a throbbing sensation of energy (5)" },
  { id: "5A", number: 5, direction: "across", row: 4, col: 0, length: 5, clue: "Central point where things converge; this app's name! (5)" },
  { id: "2D", number: 2, direction: "down",   row: 0, col: 1, length: 5, clue: "To awaken or stir up; anagram of EUROS (5)" },
  { id: "4D", number: 4, direction: "down",   row: 0, col: 2, length: 4, clue: "A banknote, a statement, or a bird's beak (4)" },
  { id: "6D", number: 6, direction: "down",   row: 0, col: 4, length: 5, clue: "Tall plants with trunks; they line boulevards (5)" },
];

// Number labels per cell (top-left corner)
const CELL_NUMBERS: Record<string, number> = {
  "0-0": 1, "0-1": 2, "0-2": 4, "0-4": 6, "2-0": 3, "4-0": 5,
};

function clueCells(cl: Clue): [number, number][] {
  return Array.from({ length: cl.length }, (_, i) =>
    cl.direction === "across" ? [cl.row, cl.col + i] as [number, number] : [cl.row + i, cl.col] as [number, number]
  );
}

const GRID_SIZE = 5;
type Phase = "loading" | "playing" | "complete" | "already-done";

export default function CrosswordPage() {
  const router = useRouter();

  const [phase, setPhase] = useState<Phase>("loading");
  const [userGrid, setUserGrid] = useState<string[][]>(() =>
    Array.from({ length: GRID_SIZE }, () => new Array(GRID_SIZE).fill(""))
  );
  const [selectedCell, setSelectedCell] = useState<[number, number]>([0, 0]);
  const [direction, setDirection] = useState<"across" | "down">("across");
  const [activeClue, setActiveClue] = useState<Clue>(CLUES[0]);
  const [incorrectCells, setIncorrectCells] = useState<Set<string>>(new Set());
  const [revealedCells, setRevealedCells] = useState<Set<string>>(new Set());
  const [seconds, setSeconds] = useState(0);
  const [result, setResult] = useState<{ xpEarned: number; isFast: boolean; newStreak: number } | null>(null);
  const [prevResult, setPrevResult] = useState<{ xpEarned: number; timeSeconds: number | null } | null>(null);
  const [mascotMood, setMascotMood] = useState<MascotMood>("neutral");
  const [mascotMsg, setMascotMsg] = useState("Fill in the grid — good luck!");
  const [showClues, setShowClues] = useState(false);
  const timerRef = useRef<ReturnType<typeof setInterval> | null>(null);
  const inputRefs = useRef<Record<string, HTMLInputElement | null>>({});
  const hasSubmitted = useRef(false);

  // ── Check completion status ──
  useEffect(() => {
    fetch("/api/v1/crossword")
      .then((r) => r.json())
      .then(({ data }) => {
        if (data?.alreadyCompleted) {
          setPrevResult({ xpEarned: data.xpEarned, timeSeconds: data.timeSeconds });
          setPhase("already-done");
        } else {
          setPhase("playing");
        }
      })
      .catch(() => setPhase("playing"));
  }, []);

  // ── Timer ──
  useEffect(() => {
    if (phase !== "playing") return;
    timerRef.current = setInterval(() => setSeconds((s) => s + 1), 1000);
    return () => { if (timerRef.current) clearInterval(timerRef.current); };
  }, [phase]);

  const formatTime = (s: number) => `${Math.floor(s / 60)}:${String(s % 60).padStart(2, "0")}`;

  // ── Clue lookup ──
  const getClueForCell = useCallback((r: number, c: number, dir: "across" | "down"): Clue | null =>
    CLUES.find((cl) => {
      if (cl.direction !== dir) return false;
      return clueCells(cl).some(([cr, cc]) => cr === r && cc === c);
    }) ?? null,
  []);

  const selectCell = useCallback((r: number, c: number, preferDir?: "across" | "down") => {
    if (ANSWER[r][c] === null) return;
    const [pr, pc] = selectedCell;
    const newDir = preferDir ?? (pr === r && pc === c ? (direction === "across" ? "down" : "across") : direction);
    const clue = getClueForCell(r, c, newDir) ?? getClueForCell(r, c, newDir === "across" ? "down" : "across");
    setSelectedCell([r, c]);
    setDirection(newDir);
    if (clue) setActiveClue(clue);
    setTimeout(() => inputRefs.current[`${r}-${c}`]?.focus(), 0);
  }, [selectedCell, direction, getClueForCell]);

  // ── Advance cursor ──
  const advance = useCallback((r: number, c: number, forward: boolean) => {
    const cells = clueCells(activeClue);
    const idx = cells.findIndex(([cr, cc]) => cr === r && cc === c);
    const nextIdx = forward ? idx + 1 : idx - 1;
    if (nextIdx >= 0 && nextIdx < cells.length) {
      const [nr, nc] = cells[nextIdx];
      setSelectedCell([nr, nc]);
      setTimeout(() => inputRefs.current[`${nr}-${nc}`]?.focus(), 0);
    }
  }, [activeClue]);

  // ── Check if puzzle is solved ──
  const checkSolved = useCallback((grid: string[][]): boolean => {
    for (let r = 0; r < GRID_SIZE; r++) {
      for (let c = 0; c < GRID_SIZE; c++) {
        if (ANSWER[r][c] === null) continue;
        if (grid[r][c] !== ANSWER[r][c]) return false;
      }
    }
    return true;
  }, []);

  // ── Submit completion ──
  const submitCompletion = useCallback(async (time: number) => {
    if (hasSubmitted.current) return;
    hasSubmitted.current = true;
    if (timerRef.current) clearInterval(timerRef.current);
    try {
      const res = await fetch("/api/v1/crossword", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ timeSeconds: time }),
      });
      const { data, error } = await res.json();
      if (error?.code === "ALREADY_COMPLETED") { setPhase("already-done"); return; }
      if (data) {
        setResult(data);
        if (data.isFast) { setMascotMood("excited"); setMascotMsg("Lightning fast! Speed bonus unlocked!"); }
        else { setMascotMood("happy"); setMascotMsg("Puzzle complete! Well done!"); }
      }
    } catch {
      setMascotMood("happy");
      setMascotMsg("Puzzle complete!");
    }
    setPhase("complete");
  }, []);

  // ── Key handler ──
  const handleKeyDown = useCallback((e: React.KeyboardEvent, r: number, c: number) => {
    if (e.key === "Backspace") {
      e.preventDefault();
      const newGrid = userGrid.map((row) => [...row]);
      if (newGrid[r][c]) {
        newGrid[r][c] = "";
      } else {
        advance(r, c, false);
      }
      setUserGrid(newGrid);
      setIncorrectCells((prev) => { const n = new Set(prev); n.delete(`${r}-${c}`); return n; });
      return;
    }
    if (e.key === "ArrowRight") { e.preventDefault(); selectCell(r, c + 1 <= 4 ? c + 1 : c, "across"); return; }
    if (e.key === "ArrowLeft")  { e.preventDefault(); selectCell(r, c - 1 >= 0 ? c - 1 : c, "across"); return; }
    if (e.key === "ArrowDown")  { e.preventDefault(); selectCell(r + 1 <= 4 ? r + 1 : r, c, "down"); return; }
    if (e.key === "ArrowUp")    { e.preventDefault(); selectCell(r - 1 >= 0 ? r - 1 : r, c, "down"); return; }

    if (/^[a-zA-Z]$/.test(e.key)) {
      e.preventDefault();
      const letter = e.key.toUpperCase();
      const newGrid = userGrid.map((row) => [...row]);
      newGrid[r][c] = letter;
      setUserGrid(newGrid);
      setIncorrectCells((prev) => { const n = new Set(prev); n.delete(`${r}-${c}`); return n; });
      advance(r, c, true);
      // Auto-complete check
      if (checkSolved(newGrid)) {
        submitCompletion(seconds);
      }
    }
  }, [userGrid, advance, selectCell, checkSolved, submitCompletion, seconds]);

  // ── Check cells (highlight mistakes) ──
  const handleCheck = useCallback(() => {
    const wrong = new Set<string>();
    for (let r = 0; r < GRID_SIZE; r++) {
      for (let c = 0; c < GRID_SIZE; c++) {
        if (ANSWER[r][c] === null || !userGrid[r][c]) continue;
        if (userGrid[r][c] !== ANSWER[r][c]) wrong.add(`${r}-${c}`);
      }
    }
    setIncorrectCells(wrong);
    if (wrong.size === 0) { setMascotMood("happy"); setMascotMsg("All correct so far! Keep going!"); }
    else { setMascotMood("sad"); setMascotMsg(`${wrong.size} mistake${wrong.size > 1 ? "s" : ""} — shown in red.`); }
  }, [userGrid]);

  // ── Reveal current word ──
  const handleRevealWord = useCallback(() => {
    const cells = clueCells(activeClue);
    const newGrid = userGrid.map((row) => [...row]);
    const newRevealed = new Set(revealedCells);
    for (const [r, c] of cells) {
      newGrid[r][c] = ANSWER[r][c] ?? "";
      newRevealed.add(`${r}-${c}`);
    }
    setUserGrid(newGrid);
    setRevealedCells(newRevealed);
    setIncorrectCells((prev) => { const n = new Set(prev); for (const [r, c] of cells) n.delete(`${r}-${c}`); return n; });
    if (checkSolved(newGrid)) submitCompletion(seconds);
  }, [activeClue, userGrid, revealedCells, checkSolved, submitCompletion, seconds]);

  // ── Reset ──
  const handleReset = useCallback(() => {
    setUserGrid(Array.from({ length: GRID_SIZE }, () => new Array(GRID_SIZE).fill("")));
    setRevealedCells(new Set());
    setIncorrectCells(new Set());
    setMascotMood("neutral");
    setMascotMsg("Fresh start — you've got this!");
  }, []);

  // ── Cell style ──
  const getCellBg = (r: number, c: number): string => {
    if (ANSWER[r][c] === null) return "bg-[var(--text-primary)]";
    const key = `${r}-${c}`;
    const [sr, sc] = selectedCell;
    const isSelected = sr === r && sc === c;
    const isInWord = clueCells(activeClue).some(([cr, cc]) => cr === r && cc === c);
    if (incorrectCells.has(key)) return "bg-red-100 border-red-400 dark:bg-red-900/30 dark:border-red-500";
    if (isSelected) return "bg-[var(--primary)] border-[var(--primary)]";
    if (isInWord) return "bg-[var(--primary)]/15 border-[var(--primary)]/40";
    if (revealedCells.has(key)) return "bg-yellow-100 border-yellow-300 dark:bg-yellow-900/20";
    return "bg-[var(--surface)] border-[var(--border)]";
  };

  // ─────────────────────────────────────────────────────────────
  // LOADING
  // ─────────────────────────────────────────────────────────────
  if (phase === "loading") {
    return (
      <div className="min-h-screen bg-[var(--background)] flex flex-col items-center justify-center gap-4">
        <Mascot mood="thinking" size={90} />
        <p className="text-sm text-[var(--text-secondary)] animate-pulse">Loading puzzle…</p>
      </div>
    );
  }

  // ─────────────────────────────────────────────────────────────
  // ALREADY DONE
  // ─────────────────────────────────────────────────────────────
  if (phase === "already-done") {
    return (
      <div className="min-h-screen bg-[var(--background)]">
        <Navbar />
        <div className="max-w-lg mx-auto px-5 pt-16 text-center">
          <Mascot mood="happy" size={110} className="mx-auto mb-4" />
          <h1 className="font-display text-2xl font-semibold text-[var(--text-primary)] mb-2">Already solved!</h1>
          <p className="text-sm text-[var(--text-secondary)] mb-2">You solved today&apos;s crossword. Come back tomorrow!</p>
          {prevResult && (
            <p className="text-sm font-medium text-[var(--primary)] mb-8">
              +{prevResult.xpEarned} XP{prevResult.timeSeconds ? ` · ${formatTime(prevResult.timeSeconds)}` : ""}
            </p>
          )}
          <div className="flex flex-col gap-3 max-w-xs mx-auto">
            <button onClick={() => router.push("/quiz")}
              className="w-full py-3 rounded-xl bg-[var(--primary)] text-white text-sm font-semibold hover:opacity-90">
              Back to Quiz Centre
            </button>
            <button onClick={() => router.push("/leaderboard")}
              className="w-full py-3 rounded-xl border border-[var(--border)] text-sm text-[var(--text-secondary)]">
              Leaderboard
            </button>
          </div>
        </div>
      </div>
    );
  }

  // ─────────────────────────────────────────────────────────────
  // COMPLETE
  // ─────────────────────────────────────────────────────────────
  if (phase === "complete") {
    return (
      <div className="min-h-screen bg-[var(--background)]">
        <Navbar />
        <div className="max-w-lg mx-auto px-5 pt-8 pb-24 text-center">
          <Mascot mood={mascotMood} size={110} className="mx-auto mb-4" />
          <h1 className="font-display text-3xl font-bold text-[var(--text-primary)] mb-1">Puzzle solved!</h1>
          <p className="text-sm text-[var(--text-secondary)] mb-6">{mascotMsg}</p>

          <div className="grid grid-cols-3 gap-3 mb-6 max-w-xs mx-auto">
            <div className="p-4 rounded-2xl border border-[var(--border)] bg-[var(--surface)] text-center">
              <Zap size={18} className="mx-auto mb-1 text-[var(--primary)]" />
              <p className="text-lg font-bold text-[var(--text-primary)]">+{result?.xpEarned ?? 100}</p>
              <p className="text-xs text-[var(--text-secondary)]">XP earned</p>
            </div>
            <div className="p-4 rounded-2xl border border-[var(--border)] bg-[var(--surface)] text-center">
              <Clock size={18} className="mx-auto mb-1 text-[var(--text-secondary)]" />
              <p className="text-lg font-bold text-[var(--text-primary)]">{formatTime(seconds)}</p>
              <p className="text-xs text-[var(--text-secondary)]">Time</p>
            </div>
            <div className="p-4 rounded-2xl border border-[var(--border)] bg-[var(--surface)] text-center">
              <Flame size={18} className="mx-auto mb-1 text-orange-500" />
              <p className="text-lg font-bold text-[var(--text-primary)]">{result?.newStreak ?? "—"}</p>
              <p className="text-xs text-[var(--text-secondary)]">Streak</p>
            </div>
          </div>

          {result?.isFast && (
            <div className="mb-6 px-4 py-3 rounded-2xl bg-yellow-500/10 border border-yellow-400/30 text-sm font-medium text-yellow-600 dark:text-yellow-400">
              ⚡ Speed bonus: +30 XP for finishing under 3 minutes!
            </div>
          )}

          {/* Solved grid */}
          <div className="flex justify-center mb-8">
            <div className="inline-grid gap-1" style={{ gridTemplateColumns: `repeat(${GRID_SIZE}, 2.5rem)` }}>
              {ANSWER.map((row, r) =>
                row.map((letter, c) => (
                  <div key={`${r}-${c}`}
                    className={`w-10 h-10 flex items-center justify-center text-sm font-bold rounded ${
                      letter
                        ? "bg-green-500/10 border border-green-400/40 text-green-600 dark:text-green-400"
                        : "bg-[var(--text-primary)] rounded"
                    }`}>
                    {letter ?? ""}
                  </div>
                ))
              )}
            </div>
          </div>

          <div className="flex flex-col gap-3 max-w-xs mx-auto">
            <button onClick={() => router.push("/quiz")}
              className="w-full flex items-center justify-center gap-2 py-3 rounded-xl bg-[var(--primary)] text-white text-sm font-semibold hover:opacity-90">
              Quiz Centre
            </button>
            <button onClick={() => router.push("/leaderboard")}
              className="w-full py-3 rounded-xl border border-[var(--border)] text-sm text-[var(--text-secondary)]">
              <Trophy size={13} className="inline mr-1" /> Leaderboard
            </button>
          </div>
        </div>
      </div>
    );
  }

  // ─────────────────────────────────────────────────────────────
  // PLAYING
  // ─────────────────────────────────────────────────────────────
  const [selR, selC] = selectedCell;

  return (
    <div className="min-h-screen bg-[var(--background)]">
      <Navbar />
      <div className="max-w-lg mx-auto px-4 pt-4 pb-28">

        {/* Header */}
        <div className="flex items-center justify-between mb-4">
          <button onClick={() => router.push("/quiz")}
            className="flex items-center gap-1.5 text-sm text-[var(--text-secondary)] hover:text-[var(--text-primary)]">
            <ArrowLeft size={15} /> Quiz Centre
          </button>
          <div className="flex items-center gap-3">
            <div className="flex items-center gap-1.5 text-sm font-semibold tabular-nums text-[var(--text-secondary)]">
              <Clock size={13} />{formatTime(seconds)}
            </div>
            <button onClick={() => setShowClues((v) => !v)}
              className="text-[var(--text-secondary)] hover:text-[var(--primary)]">
              <HelpCircle size={18} />
            </button>
          </div>
        </div>

        <h1 className="font-display text-xl font-bold text-[var(--text-primary)] mb-1">Daily Crossword</h1>
        <p className="text-xs text-[var(--text-secondary)] mb-4">100 XP · +30 XP speed bonus under 3 min</p>

        {/* Mascot hint */}
        <div className="flex items-center gap-3 mb-4 p-3 rounded-2xl bg-[var(--surface)] border border-[var(--border)]">
          <Mascot mood={mascotMood} size={48} />
          <p className="text-sm text-[var(--text-secondary)]">{mascotMsg}</p>
        </div>

        {/* Active clue */}
        <div className="mb-4 p-3 rounded-2xl bg-[var(--primary)]/8 border border-[var(--primary)]/20">
          <p className="text-xs font-bold text-[var(--primary)] mb-0.5 uppercase tracking-wide">
            {activeClue.number} {activeClue.direction}
          </p>
          <p className="text-sm text-[var(--text-primary)]">{activeClue.clue}</p>
        </div>

        {/* Grid */}
        <div className="flex justify-center mb-5">
          <div className="inline-grid gap-1" style={{ gridTemplateColumns: `repeat(${GRID_SIZE}, 1fr)` }}>
            {ANSWER.map((row, r) =>
              row.map((letter, c) => {
                const key = `${r}-${c}`;
                const isBlack = letter === null;
                const cellNum = CELL_NUMBERS[key];
                const [sr2, sc2] = selectedCell;
                const isSelected = sr2 === r && sc2 === c;
                const isInWord = clueCells(activeClue).some(([cr, cc]) => cr === r && cc === c);
                const isIncorrect = incorrectCells.has(key);
                const isRevealed = revealedCells.has(key);

                let bg = "bg-[var(--surface)] border-[var(--border)]";
                if (!isBlack) {
                  if (isIncorrect) bg = "bg-red-100 border-red-400 dark:bg-red-900/30 dark:border-red-500";
                  else if (isSelected) bg = "bg-[var(--primary)] border-[var(--primary)]";
                  else if (isInWord) bg = "bg-[var(--primary)]/15 border-[var(--primary)]/40";
                  else if (isRevealed) bg = "bg-yellow-100 border-yellow-300 dark:bg-yellow-900/20";
                }

                return (
                  <div key={key} className="relative w-11 h-11 sm:w-12 sm:h-12">
                    {isBlack ? (
                      <div className="w-full h-full rounded bg-[var(--text-primary)] opacity-90" />
                    ) : (
                      <>
                        {cellNum && (
                          <span className="absolute top-0.5 left-0.5 text-[8px] font-bold text-[var(--text-secondary)] leading-none z-10 pointer-events-none select-none">
                            {cellNum}
                          </span>
                        )}
                        <input
                          ref={(el) => { inputRefs.current[key] = el; }}
                          type="text"
                          inputMode="text"
                          maxLength={2}
                          value={userGrid[r][c]}
                          onClick={() => selectCell(r, c)}
                          onKeyDown={(e) => handleKeyDown(e, r, c)}
                          onChange={(e) => {
                            // Handle mobile input (onChange fires for on-screen keyboard)
                            const raw = e.target.value.replace(/[^a-zA-Z]/g, "").toUpperCase();
                            const letter = raw.slice(-1);
                            if (!letter) return;
                            const newGrid = userGrid.map((row) => [...row]);
                            newGrid[r][c] = letter;
                            setUserGrid(newGrid);
                            setIncorrectCells((prev) => { const n = new Set(prev); n.delete(key); return n; });
                            advance(r, c, true);
                            if (checkSolved(newGrid)) submitCompletion(seconds);
                          }}
                          className={`w-full h-full border-2 rounded text-center text-sm font-bold uppercase cursor-pointer transition-colors outline-none ${bg} ${
                            isSelected ? "text-white caret-white" : "text-[var(--text-primary)] caret-transparent"
                          }`}
                        />
                      </>
                    )}
                  </div>
                );
              })
            )}
          </div>
        </div>

        {/* Action row */}
        <div className="flex gap-2 mb-5">
          <button onClick={handleCheck}
            className="flex-1 py-2.5 rounded-xl border border-[var(--border)] text-xs font-semibold text-[var(--text-secondary)] hover:text-[var(--text-primary)] flex items-center justify-center gap-1.5 transition-colors">
            <CheckCircle size={12} /> Check
          </button>
          <button onClick={handleRevealWord}
            className="flex-1 py-2.5 rounded-xl border border-yellow-400/40 bg-yellow-50 dark:bg-yellow-900/10 text-xs font-semibold text-yellow-600 dark:text-yellow-400 flex items-center justify-center gap-1.5">
            Reveal word
          </button>
          <button onClick={handleReset}
            className="flex-1 py-2.5 rounded-xl border border-[var(--border)] text-xs font-semibold text-[var(--text-secondary)] hover:text-[var(--text-primary)] flex items-center justify-center gap-1.5 transition-colors">
            <RotateCcw size={12} /> Reset
          </button>
        </div>

        {/* Clue list (toggleable) */}
        {showClues && (
          <div className="grid grid-cols-2 gap-4 rounded-2xl border border-[var(--border)] bg-[var(--surface)] p-4">
            <div>
              <p className="text-xs font-bold uppercase tracking-wider text-[var(--text-secondary)] mb-2">Across</p>
              {CLUES.filter((cl) => cl.direction === "across").map((cl) => (
                <button key={cl.id}
                  onClick={() => { setActiveClue(cl); setDirection("across"); const [cr, cc] = clueCells(cl)[0]; selectCell(cr, cc, "across"); }}
                  className={`block w-full text-left text-xs leading-snug py-1.5 px-2 rounded-lg mb-1 transition-colors ${
                    activeClue.id === cl.id ? "bg-[var(--primary)]/10 text-[var(--primary)] font-medium" : "text-[var(--text-secondary)] hover:text-[var(--text-primary)]"
                  }`}>
                  <span className="font-bold">{cl.number}.</span> {cl.clue}
                </button>
              ))}
            </div>
            <div>
              <p className="text-xs font-bold uppercase tracking-wider text-[var(--text-secondary)] mb-2">Down</p>
              {CLUES.filter((cl) => cl.direction === "down").map((cl) => (
                <button key={cl.id}
                  onClick={() => { setActiveClue(cl); setDirection("down"); const [cr, cc] = clueCells(cl)[0]; selectCell(cr, cc, "down"); }}
                  className={`block w-full text-left text-xs leading-snug py-1.5 px-2 rounded-lg mb-1 transition-colors ${
                    activeClue.id === cl.id ? "bg-[var(--primary)]/10 text-[var(--primary)] font-medium" : "text-[var(--text-secondary)] hover:text-[var(--text-primary)]"
                  }`}>
                  <span className="font-bold">{cl.number}.</span> {cl.clue}
                </button>
              ))}
            </div>
          </div>
        )}

        <p className="text-center text-xs text-[var(--muted)] mt-4">
          Puzzle completes automatically when all letters are correct
        </p>
      </div>
    </div>
  );
}
