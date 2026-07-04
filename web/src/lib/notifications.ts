import { createServiceClient } from "@/lib/supabase/server";

export type NotificationType =
  | "new_comment"
  | "new_reaction"
  | "new_post"
  | "subscription_activated"
  | "subscription_canceled"
  | "bookmark_added";

/**
 * Insert an in-app notification row. Read via GET /api/v1/user/notifications
 * and pushed live to mobile/web clients through the Supabase realtime channel
 * they subscribe to on `notifications` filtered by user_id.
 */
export async function createNotification(
  userId: string,
  type: NotificationType,
  title: string,
  body?: string
): Promise<void> {
  try {
    const supabase = createServiceClient();
    await supabase.from("notifications").insert({
      user_id: userId,
      type,
      title,
      body: body ?? null,
    });
  } catch {
    // Notifications are best-effort — must never break the calling request
  }
}
