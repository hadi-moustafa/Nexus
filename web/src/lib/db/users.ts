import { cookies } from "next/headers";
import { createClient } from "@/lib/supabase/server";
import type { UserProfile, UserPreferences, UserStats } from "@/types";

// ---------------------------------------------------------------------------
// Row mapping — snake_case DB columns → camelCase API types
// ---------------------------------------------------------------------------
function rowToUserProfile(row: Record<string, unknown>): UserProfile {
  return {
    id: row.id as string,
    email: row.email as string,
    displayName: (row.display_name as string | null) ?? null,
    avatarUrl: (row.avatar_url as string | null) ?? null,
    createdAt: row.created_at as string,
  };
}

function rowToPreferences(row: Record<string, unknown>): UserPreferences {
  return {
    topics: (row.topics as string[] | null) ?? [],
    preferredLanguage: (row.preferred_language as string) ?? "en",
    onboardingComplete: (row.onboarding_complete as boolean) ?? false,
  };
}

function rowToStats(row: Record<string, unknown>): UserStats {
  return {
    totalXp: (row.total_xp as number) ?? 0,
    currentStreak: (row.current_streak as number) ?? 0,
    longestStreak: (row.longest_streak as number) ?? 0,
    quizzesCompleted: (row.quizzes_completed as number) ?? 0,
    perfectScores: (row.perfect_scores as number) ?? 0,
    articlesRead: (row.articles_read as number) ?? 0,
  };
}

// ---------------------------------------------------------------------------
// getUserProfile
// Used by /api/v1/auth/session to return the current user's profile.
// Returns null if the row doesn't exist yet (edge case: trigger hasn't fired).
// ---------------------------------------------------------------------------
export async function getUserProfile(userId: string): Promise<UserProfile | null> {
  const cookieStore = await cookies();
  const supabase = createClient(cookieStore);

  const { data, error } = await supabase
    .from("users")
    .select("id, email, display_name, avatar_url, created_at")
    .eq("id", userId)
    .single();

  if (error) {
    if (error.code === "PGRST116") return null; // not found
    throw error;
  }

  return data ? rowToUserProfile(data as Record<string, unknown>) : null;
}

// ---------------------------------------------------------------------------
// getUserPreferences
// ---------------------------------------------------------------------------
export async function getUserPreferences(userId: string): Promise<UserPreferences | null> {
  const cookieStore = await cookies();
  const supabase = createClient(cookieStore);

  const { data, error } = await supabase
    .from("user_preferences")
    .select("topics, preferred_language, onboarding_complete")
    .eq("user_id", userId)
    .single();

  if (error) {
    if (error.code === "PGRST116") return null;
    throw error;
  }

  return data ? rowToPreferences(data as Record<string, unknown>) : null;
}

// ---------------------------------------------------------------------------
// updateUserPreferences
// Partial patch — only updates the fields that are provided.
// ---------------------------------------------------------------------------
export async function updateUserPreferences(
  userId: string,
  patch: Partial<UserPreferences>
): Promise<UserPreferences> {
  const cookieStore = await cookies();
  const supabase = createClient(cookieStore);

  const dbPatch: Record<string, unknown> = {};
  if (patch.topics !== undefined) dbPatch.topics = patch.topics;
  if (patch.preferredLanguage !== undefined) dbPatch.preferred_language = patch.preferredLanguage;
  if (patch.onboardingComplete !== undefined) dbPatch.onboarding_complete = patch.onboardingComplete;
  dbPatch.updated_at = new Date().toISOString();

  const { data, error } = await supabase
    .from("user_preferences")
    .update(dbPatch)
    .eq("user_id", userId)
    .select("topics, preferred_language, onboarding_complete")
    .single();

  if (error) throw error;

  return rowToPreferences(data as Record<string, unknown>);
}

// ---------------------------------------------------------------------------
// getUserStats
// ---------------------------------------------------------------------------
export async function getUserStats(userId: string): Promise<UserStats | null> {
  const cookieStore = await cookies();
  const supabase = createClient(cookieStore);

  const { data, error } = await supabase
    .from("user_stats")
    .select("total_xp, current_streak, longest_streak, quizzes_completed, perfect_scores")
    .eq("user_id", userId)
    .single();

  if (error) {
    if (error.code === "PGRST116") return null;
    throw error;
  }

  return data ? rowToStats(data as Record<string, unknown>) : null;
}
