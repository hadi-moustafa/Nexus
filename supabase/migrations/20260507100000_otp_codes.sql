-- Self-managed OTP codes for email verification.
-- Supabase's built-in email system is bypassed; we send via our own SMTP.

CREATE TABLE IF NOT EXISTS public.otp_codes (
  id         uuid        DEFAULT gen_random_uuid() PRIMARY KEY,
  email      text        NOT NULL,
  code_hash  text        NOT NULL,
  expires_at timestamptz NOT NULL,
  used_at    timestamptz,
  created_at timestamptz DEFAULT now() NOT NULL
);

CREATE INDEX IF NOT EXISTS otp_codes_lookup_idx
  ON public.otp_codes (email, expires_at)
  WHERE used_at IS NULL;

-- Service role only — no RLS needed (this table is never accessed from the client)
ALTER TABLE public.otp_codes DISABLE ROW LEVEL SECURITY;
