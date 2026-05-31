-- ─────────────────────────────────────────────────────────────────────────────
-- Migration: post_bookmarks — users bookmarking journalist posts
-- 2026-05-30
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.post_bookmarks (
  id         uuid        DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id    uuid        NOT NULL REFERENCES public.users(id)            ON DELETE CASCADE,
  post_id    uuid        NOT NULL REFERENCES public.journalist_posts(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now() NOT NULL,
  CONSTRAINT post_bookmarks_user_post_key UNIQUE (user_id, post_id)
);

CREATE INDEX IF NOT EXISTS post_bookmarks_user_id_idx ON public.post_bookmarks (user_id);
CREATE INDEX IF NOT EXISTS post_bookmarks_post_id_idx ON public.post_bookmarks (post_id);

ALTER TABLE public.post_bookmarks ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "post_bookmarks_select_own" ON public.post_bookmarks;
DROP POLICY IF EXISTS "post_bookmarks_insert_own" ON public.post_bookmarks;
DROP POLICY IF EXISTS "post_bookmarks_delete_own" ON public.post_bookmarks;

CREATE POLICY "post_bookmarks_select_own" ON public.post_bookmarks
  FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "post_bookmarks_insert_own" ON public.post_bookmarks
  FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "post_bookmarks_delete_own" ON public.post_bookmarks
  FOR DELETE USING (user_id = auth.uid());
