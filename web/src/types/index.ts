// Canonical shared types for Nexus.
// Dart models in mobile/lib/models/ mirror these exactly.
// API responses use camelCase; DB columns are snake_case.
// Mapping happens once in lib/db/*.ts — never in components.

export interface Article {
  id: string;
  title: string;
  summary: string | null;
  content: string | null;
  url: string;
  imageUrl: string | null;
  publishedAt: string; // ISO 8601
  sourceId: string;
  category: string;
  language: string;
  region: string | null;
}

export interface UserProfile {
  id: string;
  email: string;
  displayName: string | null;
  avatarUrl: string | null;
  createdAt: string;
}

export interface UserPreferences {
  topics: string[];
  preferredLanguage: string;
  onboardingComplete: boolean;
}

export interface UserStats {
  totalXp: number;
  currentStreak: number;
  longestStreak: number;
  quizzesCompleted: number;
  perfectScores: number;
  articlesRead: number;
}

export interface QuizQuestion {
  id: string;
  question: string;
  options: string[];
  timeLimit: number; // seconds
}

export interface QuizSession {
  id: string;
  questions: QuizQuestion[];
  expiresAt: string;
}

export interface Region {
  slug: string;
  label: string;
  articleCount: number;
}

// API response wrappers
export interface ApiSuccess<T> {
  data: T;
  meta?: { nextCursor?: string | null; total?: number };
}

export interface ApiError {
  error: { code: ApiErrorCode; message: string };
}

export type ApiErrorCode =
  | "UNAUTHORIZED"
  | "FORBIDDEN"
  | "NOT_FOUND"
  | "VALIDATION_ERROR"
  | "RATE_LIMITED"
  | "INTERNAL_ERROR";
