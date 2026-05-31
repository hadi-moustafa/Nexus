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
  postCount: number;
  userId: string | null;
  badges: JournalistBadge[];
}

export type BadgeType = 'rising_star' | 'popular' | 'gold' | 'prolific' | 'verified' | 'featured';

export interface JournalistBadge {
  id: string;
  badgeType: BadgeType;
  awardedAt: string;
  awardedBy: string | null;
}

export interface JournalistPost {
  id: string;
  journalistId: string;
  journalistName: string;
  journalistAvatarUrl: string | null;
  isVerified: boolean;
  title: string;
  body: string;
  imageUrl: string | null;
  category: string;
  viewCount: number;
  commentCount: number;
  reactionCount: number;
  createdAt: string;
  updatedAt: string;
}

export interface PostComment {
  id: string;
  postId: string;
  authorId: string;
  authorName: string;
  authorAvatar: string | null;
  body: string;
  createdAt: string;
}

export interface UserProfile {
  id: string;
  email: string;
  displayName: string | null;
  avatarUrl: string | null;
  createdAt: string;
  /** "google" | "email" — determines whether password change is available */
  provider?: string;
  /** "user" | "journalist" | "admin" | "banned" */
  role?: string;
  /** Set when role === "journalist" — their journalist profile id */
  journalistId?: string | null;
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

export type JournalistRequestStatus = 'pending' | 'approved' | 'rejected';

export interface JournalistRequest {
  id: string;
  userId: string;
  userEmail: string;
  userDisplayName: string | null;
  status: JournalistRequestStatus;
  message: string | null;
  adminNote: string | null;
  reviewedBy: string | null;
  createdAt: string;
  reviewedAt: string | null;
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
  | "subscription_created" | "subscription_cancelled"
  | "journalist_post_created" | "journalist_post_deleted"
  | "admin_post_deleted"
  | "admin_badge_awarded" | "admin_badge_revoked"
  | "admin_comment_deleted" | "admin_user_banned"
  | "journalist_request_submitted" | "journalist_request_approved" | "journalist_request_rejected";

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
