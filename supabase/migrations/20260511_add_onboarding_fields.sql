-- Add onboarding tracking fields to profiles table.
-- These persist across device wipes so users don't repeat onboarding.

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS onboarding_completed boolean DEFAULT false,
  ADD COLUMN IF NOT EXISTS gate_completed boolean DEFAULT false;
