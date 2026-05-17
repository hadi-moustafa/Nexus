import { type NextRequest, NextResponse } from "next/server";
import { createServiceClient } from "@/lib/supabase/server";
import { requireAuth } from "@/lib/auth";
import { logAction } from "@/lib/audit";

const ALLOWED_TYPES = ["image/jpeg", "image/png", "image/webp", "image/gif"];
const MAX_BYTES = 2 * 1024 * 1024; // 2 MB

/**
 * POST /api/v1/user/avatar
 *
 * Uploads a profile picture to Supabase Storage (bucket: "avatars")
 * and saves the public URL to the users table.
 *
 * Prerequisites (Supabase dashboard):
 *   1. Create a Storage bucket named "avatars" with public read access.
 *   2. Add RLS insert policy: auth.uid()::text = (storage.foldername(name))[1]
 *
 * Body: multipart/form-data with field "file" (image/jpeg|png|webp|gif, ≤2 MB)
 *
 * Response: { data: { avatarUrl: string } }
 */
export async function POST(request: NextRequest) {
  const auth = await requireAuth(request);
  if (auth instanceof NextResponse) return auth;

  try {
    const formData = await request.formData();
    const file = formData.get("file");

    if (!file || !(file instanceof File)) {
      return NextResponse.json(
        { error: { code: "VALIDATION_ERROR", message: "file field is required" } },
        { status: 400 }
      );
    }

    if (!ALLOWED_TYPES.includes(file.type)) {
      return NextResponse.json(
        { error: { code: "VALIDATION_ERROR", message: "Only JPEG, PNG, WebP, and GIF are supported" } },
        { status: 400 }
      );
    }

    if (file.size > MAX_BYTES) {
      return NextResponse.json(
        { error: { code: "VALIDATION_ERROR", message: "File must be under 2 MB" } },
        { status: 400 }
      );
    }

    const supabase = createServiceClient();
    const ext = file.type.split("/")[1].replace("jpeg", "jpg");
    const path = `${auth.userId}/avatar.${ext}`;

    const arrayBuffer = await file.arrayBuffer();
    const { error: uploadErr } = await supabase.storage
      .from("avatars")
      .upload(path, arrayBuffer, {
        contentType: file.type,
        upsert: true,
      });

    if (uploadErr) {
      console.error("[POST /api/v1/user/avatar] upload error:", uploadErr.message);
      return NextResponse.json(
        { error: { code: "INTERNAL_ERROR", message: "Upload failed. Ensure the 'avatars' storage bucket exists in Supabase." } },
        { status: 500 }
      );
    }

    const { data: urlData } = supabase.storage.from("avatars").getPublicUrl(path);
    const avatarUrl = urlData.publicUrl;

    const { error: updateErr } = await supabase
      .from("users")
      .update({ avatar_url: avatarUrl })
      .eq("id", auth.userId);

    if (updateErr) throw updateErr;

    void logAction("profile_updated", auth.userId, { avatarUrl }, request);
    return NextResponse.json({ data: { avatarUrl } });
  } catch (err) {
    console.error("[POST /api/v1/user/avatar]", err);
    return NextResponse.json(
      { error: { code: "INTERNAL_ERROR", message: "Failed to upload avatar" } },
      { status: 500 }
    );
  }
}
