-- ─────────────────────────────────────────────────────────────────────────────
-- Migration: journalist_requests — user-initiated journalist application flow
-- 2026-05-19
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.journalist_requests (
  id            uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       uuid        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  status        text        NOT NULL DEFAULT 'pending'
                            CHECK (status IN ('pending', 'approved', 'rejected')),
  message       text        CHECK (char_length(message) <= 1000),
  admin_note    text        CHECK (char_length(admin_note) <= 500),
  reviewed_by   uuid        REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at    timestamptz NOT NULL DEFAULT now(),
  reviewed_at   timestamptz,
  UNIQUE(user_id)  -- one active request per user; re-submit replaces it
);

CREATE INDEX IF NOT EXISTS journalist_requests_status_idx
  ON public.journalist_requests(status, created_at DESC);

-- RLS: users can read only their own request; all writes via service role
ALTER TABLE public.journalist_requests ENABLE ROW LEVEL SECURITY;

CREATE POLICY "journalist_requests_own_read"
  ON public.journalist_requests FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "journalist_requests_service_all"
  ON public.journalist_requests FOR ALL
  USING (true) WITH CHECK (true);
