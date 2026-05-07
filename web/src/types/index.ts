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
  sourceName: string;
  category: string;
  language: string;
  countryCode: string | null;
  aiSummary: string | null;
  viewCount: number;
  journalistId: string | null;
  journalistName: string | null;
}

export interface Journalist {
  id: string;
  name: string;
  bio: string | null;
  avatarUrl: string | null;
  bylineMatch: string | null;
  isVerified: boolean;
  followerCount: number;
}

export interface UserProfile {
  id: string;
  email: string;
  displayName: string | null;
  avatarUrl: string | null;
  createdAt: string;
  /** "google" | "email" — determines whether password change is available */
  provider?: string;
}

export interface Subscription {
  id: string;
  plan: "monthly" | "annual";
  status: "active" | "canceled" | "trialing" | "past_due";
  startDate: string;
  endDate: string | null;
  autoRenew: boolean;
  trialEndsAt: string | null;
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

export interface Bookmark {
  id: string;
  articleId: string;
  createdAt: string;
  article: Article;
}

export interface UserSession {
  id: string;
  deviceName: string | null;
  browser: string | null;
  ipAddress: string | null;
  createdAt: string;
  lastActiveAt: string;
  isCurrent: boolean;
}

export type AuditAction =
  | "sign_in" | "sign_up" | "sign_out"
  | "otp_requested" | "otp_verified"
  | "password_changed"
  | "profile_updated" | "preferences_updated"
  | "bookmark_added" | "bookmark_removed"
  | "reaction_added"
  | "quiz_submitted" | "crossword_submitted"
  | "session_revoked" | "all_sessions_revoked"
  | "admin_role_changed" | "admin_ban" | "admin_force_signout"
  | "subscription_created" | "subscription_cancelled";

export interface AuditEntry {
  id: string;
  userId: string | null;
  action: AuditAction;
  metadata: Record<string, unknown>;
  ipAddress: string | null;
  userAgent: string | null;
  createdAt: string;
}

export interface AdminUserMetrics {
  totalUsers: number;
  newUsersLast7Days: number;
  newUsersLast30Days: number;
  activeUsersLast7Days: number;
  googleUsers: number;
  emailUsers: number;
  adminUsers: number;
  bannedUsers: number;
  signUpsByDay: Array<{ date: string; count: number }>;
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
