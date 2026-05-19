-- Migration: Tighten notifications insert policy
-- The original policy WITH CHECK (true) allowed anyone — even unauthenticated — to insert.
-- This tightens it to require authentication at minimum.
-- Full server-side enforcement should eventually move notification creation to a DB trigger
-- or Edge Function, but this closes the unauthenticated spam vector immediately.

DROP POLICY IF EXISTS "notifications_insert" ON public.notifications;

CREATE POLICY "notifications_insert" ON public.notifications
  FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);
