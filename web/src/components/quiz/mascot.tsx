"use client";

export type MascotMood = "happy" | "sad" | "thinking" | "excited" | "neutral";

interface MascotProps {
  mood?: MascotMood;
  size?: number;
  className?: string;
}

/**
 * Nexus mascot — a friendly owl named "Nex".
 * Mood changes the expression (eyes, brow, mouth).
 */
export function Mascot({ mood = "neutral", size = 120, className = "" }: MascotProps) {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 120 120"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
      className={className}
      aria-label={`Mascot feeling ${mood}`}
      role="img"
    >
      {/* Body */}
      <ellipse cx="60" cy="78" rx="32" ry="30" fill="#6366f1" />

      {/* Wing left */}
      <ellipse cx="28" cy="82" rx="14" ry="10" fill="#4f46e5" transform="rotate(-20 28 82)" />
      {/* Wing right */}
      <ellipse cx="92" cy="82" rx="14" ry="10" fill="#4f46e5" transform="rotate(20 92 82)" />

      {/* Belly */}
      <ellipse cx="60" cy="84" rx="18" ry="18" fill="#e0e7ff" />

      {/* Belly stripes */}
      <path d="M50 84 Q60 78 70 84" stroke="#c7d2fe" strokeWidth="1.5" fill="none" />
      <path d="M48 90 Q60 85 72 90" stroke="#c7d2fe" strokeWidth="1.5" fill="none" />

      {/* Head */}
      <ellipse cx="60" cy="46" rx="28" ry="26" fill="#6366f1" />

      {/* Ear tufts */}
      <polygon points="36,26 40,10 46,28" fill="#4f46e5" />
      <polygon points="74,26 80,10 84,28" fill="#4f46e5" />

      {/* Facial disc */}
      <ellipse cx="60" cy="48" rx="20" ry="18" fill="#e0e7ff" />

      {/* Left eye socket */}
      <circle cx="51" cy="46" r="9" fill="white" />
      {/* Right eye socket */}
      <circle cx="69" cy="46" r="9" fill="white" />

      {/* Eye expressions */}
      <EyePair mood={mood} />

      {/* Beak */}
      <polygon points="57,54 60,60 63,54" fill="#fbbf24" />

      {/* Feet */}
      <g fill="#fbbf24">
        <rect x="48" y="105" width="6" height="8" rx="1" />
        <rect x="42" y="108" width="5" height="6" rx="1" />
        <rect x="54" y="109" width="5" height="5" rx="1" />
        <rect x="66" y="105" width="6" height="8" rx="1" />
        <rect x="60" y="109" width="5" height="5" rx="1" />
        <rect x="72" y="108" width="5" height="6" rx="1" />
      </g>

      {/* Mood-specific accessory */}
      <MoodAccessory mood={mood} />
    </svg>
  );
}

function EyePair({ mood }: { mood: MascotMood }) {
  switch (mood) {
    case "happy":
    case "excited":
      return (
        <>
          {/* Happy — curved shut eyes */}
          <path d="M44 46 Q51 40 58 46" stroke="#1e1b4b" strokeWidth="2.5" fill="none" strokeLinecap="round" />
          <path d="M62 46 Q69 40 76 46" stroke="#1e1b4b" strokeWidth="2.5" fill="none" strokeLinecap="round" />
        </>
      );
    case "sad":
      return (
        <>
          {/* Sad — drooping eyes */}
          <circle cx="51" cy="47" r="5" fill="#1e1b4b" />
          <circle cx="69" cy="47" r="5" fill="#1e1b4b" />
          <circle cx="52.5" cy="45.5" r="1.5" fill="white" />
          <circle cx="70.5" cy="45.5" r="1.5" fill="white" />
          {/* Sad brow */}
          <path d="M44 40 Q51 44 58 40" stroke="#1e1b4b" strokeWidth="2" fill="none" strokeLinecap="round" />
          <path d="M62 40 Q69 44 76 40" stroke="#1e1b4b" strokeWidth="2" fill="none" strokeLinecap="round" />
        </>
      );
    case "thinking":
      return (
        <>
          {/* Thinking — one eye squinted */}
          <circle cx="51" cy="46" r="5" fill="#1e1b4b" />
          <circle cx="69" cy="46" r="5" fill="#1e1b4b" />
          <circle cx="52.5" cy="44.5" r="1.5" fill="white" />
          <circle cx="70.5" cy="44.5" r="1.5" fill="white" />
          {/* One raised brow */}
          <path d="M44 38 Q51 36 58 40" stroke="#1e1b4b" strokeWidth="2" fill="none" strokeLinecap="round" />
          <path d="M62 40 Q69 40 76 40" stroke="#1e1b4b" strokeWidth="2" fill="none" strokeLinecap="round" />
        </>
      );
    default:
      // neutral
      return (
        <>
          <circle cx="51" cy="46" r="5" fill="#1e1b4b" />
          <circle cx="69" cy="46" r="5" fill="#1e1b4b" />
          <circle cx="52.5" cy="44.5" r="1.5" fill="white" />
          <circle cx="70.5" cy="44.5" r="1.5" fill="white" />
        </>
      );
  }
}

function MoodAccessory({ mood }: { mood: MascotMood }) {
  switch (mood) {
    case "happy":
      // Small smile lines
      return (
        <>
          <path d="M42 60 Q43 63 46 62" stroke="#6366f1" strokeWidth="1.5" fill="none" strokeLinecap="round" />
          <path d="M74 60 Q75 63 78 62" stroke="#6366f1" strokeWidth="1.5" fill="none" strokeLinecap="round" />
        </>
      );
    case "excited":
      // Stars
      return (
        <>
          <text x="18" y="36" fontSize="10" fill="#fbbf24">✦</text>
          <text x="90" y="32" fontSize="8" fill="#fbbf24">✦</text>
          <text x="96" y="50" fontSize="6" fill="#fbbf24">✦</text>
        </>
      );
    case "thinking":
      // Thought dots
      return (
        <>
          <circle cx="88" cy="28" r="3" fill="#6366f1" opacity="0.5" />
          <circle cx="96" cy="20" r="4" fill="#6366f1" opacity="0.6" />
          <circle cx="106" cy="12" r="5" fill="#6366f1" opacity="0.4" />
        </>
      );
    case "sad":
      // Tear drop
      return (
        <ellipse cx="57" cy="60" rx="2" ry="3" fill="#93c5fd" opacity="0.8" />
      );
    default:
      return null;
  }
}
