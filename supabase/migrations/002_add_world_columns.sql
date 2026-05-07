-- Vertiege: Add missing columns to worlds table

ALTER TABLE public.worlds
  ADD COLUMN IF NOT EXISTS activity_score INT DEFAULT 0,
  ADD COLUMN IF NOT EXISTS boost_count INT DEFAULT 0,
  ADD COLUMN IF NOT EXISTS last_boost_month TEXT,
  ADD COLUMN IF NOT EXISTS constitution JSONB DEFAULT '{}';

-- Vertiege: Create verification_submissions table

CREATE TABLE IF NOT EXISTS public.verification_submissions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  resident_id TEXT NOT NULL REFERENCES public.profiles(id),
  resident_name TEXT NOT NULL,
  profession TEXT NOT NULL,
  proof_url TEXT,
  status TEXT DEFAULT 'pending', -- pending, approved, rejected
  reviewer_notes TEXT,
  reviewed_by TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE public.verification_submissions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read own submissions"
  ON public.verification_submissions FOR SELECT
  USING (auth.uid()::text = resident_id);

CREATE POLICY "Users can insert own submissions"
  ON public.verification_submissions FOR INSERT
  WITH CHECK (auth.uid()::text = resident_id);

CREATE POLICY "Users can update own submissions"
  ON public.verification_submissions FOR UPDATE
  USING (auth.uid()::text = resident_id);
