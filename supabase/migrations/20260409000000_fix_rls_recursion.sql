-- ============================================================
-- FIX: infinite recursion in users RLS policy
--
-- The "Admins can read all users" policy used a subquery that
-- read from public.users, which re-triggered the same policy,
-- causing infinite recursion (error code 42P17).
--
-- Solution: wrap the admin check in a SECURITY DEFINER function
-- so it runs with elevated privileges and bypasses RLS entirely.
-- This function is then used in ALL admin policies across the schema.
-- ============================================================

-- 1. Create the helper function
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin'
  );
$$;

-- 2. Fix the users table — drop the recursive policy and replace it
DROP POLICY IF EXISTS "Admins can read all users" ON public.users;

CREATE POLICY "Admins can read all users" ON public.users
  FOR SELECT USING (public.is_admin());

-- 3. Fix all other tables that used the same inline subquery pattern
--    (they won't recurse on their own tables, but using the function
--     is more efficient and consistent)

-- comments
DROP POLICY IF EXISTS "Admins can manage comments" ON public.comments;
-- (comments admin actions go through the API which uses service role, no policy needed)

-- journalists
DROP POLICY IF EXISTS "Admins can manage journalists" ON public.journalists;
CREATE POLICY "Admins can manage journalists" ON public.journalists
  FOR ALL USING (public.is_admin());

-- news_sources
DROP POLICY IF EXISTS "Admins can manage sources" ON public.news_sources;
CREATE POLICY "Admins can manage sources" ON public.news_sources
  FOR ALL USING (public.is_admin());

-- subscriptions
DROP POLICY IF EXISTS "Admins can read all subscriptions" ON public.subscriptions;
CREATE POLICY "Admins can read all subscriptions" ON public.subscriptions
  FOR SELECT USING (public.is_admin());

-- quiz_questions
DROP POLICY IF EXISTS "Admins can manage quiz questions" ON public.quiz_questions;
CREATE POLICY "Admins can manage quiz questions" ON public.quiz_questions
  FOR ALL USING (public.is_admin());
