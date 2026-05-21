-- ═══════════════════════════════════════════════════════════════
-- 20260516_world_system_complete.sql
-- Complete World System: Constitution, Polls, Announcements,
-- Treasury, Challenges, Templates, Analytics, Rivalries,
-- Landmarks, Academy, Archive, Lineage
-- ═══════════════════════════════════════════════════════════════

-- ─── Helper Functions (MUST come first - referenced by RLS policies) ───
-- is_world_member already exists from earlier migration, skip redefinition

DROP FUNCTION IF EXISTS public.is_sovereign_or_council(text) CASCADE;
CREATE OR REPLACE FUNCTION public.is_sovereign_or_council(p_world_id TEXT) RETURNS BOOLEAN AS $$
DECLARE
  v_user_id TEXT;
  v_sovereign_id TEXT;
  v_rep INT;
BEGIN
  v_user_id := auth.uid()::text;
  SELECT sovereign_id INTO v_sovereign_id FROM public.worlds WHERE id = p_world_id;
  SELECT rep INTO v_rep FROM public.world_members WHERE world_id = p_world_id AND resident_id = v_user_id;
  
  RETURN v_user_id = v_sovereign_id OR COALESCE(v_rep, 0) >= 5000;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

DROP FUNCTION IF EXISTS public.is_council_or_above(text) CASCADE;
CREATE OR REPLACE FUNCTION public.is_council_or_above(p_world_id TEXT) RETURNS BOOLEAN AS $$
DECLARE
  v_user_id TEXT;
  v_rep INT;
BEGIN
  v_user_id := auth.uid()::text;
  SELECT rep INTO v_rep FROM public.world_members WHERE world_id = p_world_id AND resident_id = v_user_id;
  RETURN COALESCE(v_rep, 0) >= 5000;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

-- ─── World Fields Expansion ───
ALTER TABLE public.worlds ADD COLUMN IF NOT EXISTS motto TEXT DEFAULT '';
ALTER TABLE public.worlds ADD COLUMN IF NOT EXISTS accent_color TEXT DEFAULT '';
ALTER TABLE public.worlds ADD COLUMN IF NOT EXISTS lore TEXT DEFAULT '';
ALTER TABLE public.worlds ADD COLUMN IF NOT EXISTS lineage JSONB DEFAULT '[]';
ALTER TABLE public.worlds ADD COLUMN IF NOT EXISTS tags TEXT[] DEFAULT '{}';
ALTER TABLE public.worlds ADD COLUMN IF NOT EXISTS world_currency_name TEXT DEFAULT 'Coins';
ALTER TABLE public.worlds ADD COLUMN IF NOT EXISTS tax_rate INT DEFAULT 0;
ALTER TABLE public.worlds ADD COLUMN IF NOT EXISTS landmark_level INT DEFAULT 1;
ALTER TABLE public.worlds ADD COLUMN IF NOT EXISTS dominion_type TEXT DEFAULT '';
ALTER TABLE public.worlds ADD COLUMN IF NOT EXISTS welcome_message TEXT DEFAULT '';
ALTER TABLE public.worlds ADD COLUMN IF NOT EXISTS rules_acknowledged BOOLEAN DEFAULT FALSE;

-- ─── World Announcements (Decrees) ───
CREATE TABLE IF NOT EXISTS public.world_announcements (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  world_id        TEXT NOT NULL REFERENCES public.worlds(id) ON DELETE CASCADE,
  author_id       TEXT NOT NULL REFERENCES public.profiles(id),
  author_name     TEXT NOT NULL,
  title           TEXT NOT NULL,
  content         TEXT NOT NULL,
  image_url       TEXT,
  priority        TEXT DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
  is_pinned       BOOLEAN DEFAULT FALSE,
  expires_at      TIMESTAMPTZ,
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  updated_at      TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_announcements_world ON public.world_announcements(world_id, is_pinned, created_at DESC);

ALTER TABLE public.world_announcements ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "announcements_read" ON public.world_announcements;
CREATE POLICY "announcements_read" ON public.world_announcements
  FOR SELECT USING (public.is_world_member(world_id));
DROP POLICY IF EXISTS "announcements_insert" ON public.world_announcements;
CREATE POLICY "announcements_insert" ON public.world_announcements
  FOR INSERT WITH CHECK (public.is_sovereign_or_council(world_id));
DROP POLICY IF EXISTS "announcements_update" ON public.world_announcements;
CREATE POLICY "announcements_update" ON public.world_announcements
  FOR UPDATE USING (public.is_sovereign_or_council(world_id));
DROP POLICY IF EXISTS "announcements_delete" ON public.world_announcements;
CREATE POLICY "announcements_delete" ON public.world_announcements
  FOR DELETE USING (public.is_sovereign_or_council(world_id));

-- ─── World Listings (Marketplace) ───
CREATE TABLE IF NOT EXISTS public.world_listings (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  world_id        TEXT NOT NULL REFERENCES public.worlds(id) ON DELETE CASCADE,
  seller_id       TEXT NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  seller_name     TEXT NOT NULL,
  title           TEXT NOT NULL,
  description     TEXT DEFAULT '',
  price           TEXT,
  price_note      TEXT,
  category        TEXT NOT NULL DEFAULT 'general',
  image_url       TEXT,
  status          TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'sold', 'cancelled')),
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  updated_at      TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_listings_world ON public.world_listings(world_id, status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_listings_seller ON public.world_listings(seller_id);
CREATE INDEX IF NOT EXISTS idx_listings_category ON public.world_listings(category);

ALTER TABLE public.world_listings ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "listings_read" ON public.world_listings;
CREATE POLICY "listings_read" ON public.world_listings
  FOR SELECT USING (public.is_world_member(world_id) OR status = 'active');
DROP POLICY IF EXISTS "listings_insert" ON public.world_listings;
CREATE POLICY "listings_insert" ON public.world_listings
  FOR INSERT WITH CHECK (seller_id = auth.uid()::text);
DROP POLICY IF EXISTS "listings_update" ON public.world_listings;
CREATE POLICY "listings_update" ON public.world_listings
  FOR UPDATE USING (seller_id = auth.uid()::text);
DROP POLICY IF EXISTS "listings_delete" ON public.world_listings;
CREATE POLICY "listings_delete" ON public.world_listings
  FOR DELETE USING (seller_id = auth.uid()::text);

-- ─── World Currency Ledger ───
CREATE TABLE IF NOT EXISTS public.world_currency (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  world_id        TEXT NOT NULL REFERENCES public.worlds(id) ON DELETE CASCADE,
  resident_id     TEXT NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  balance         INT NOT NULL DEFAULT 0,
  earned_total    INT NOT NULL DEFAULT 0,
  spent_total     INT NOT NULL DEFAULT 0,
  UNIQUE(world_id, resident_id)
);
CREATE INDEX IF NOT EXISTS idx_currency_world ON public.world_currency(world_id);

ALTER TABLE public.world_currency ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "currency_read" ON public.world_currency;
CREATE POLICY "currency_read" ON public.world_currency
  FOR SELECT USING (resident_id = auth.uid()::text OR public.is_world_member(world_id));

-- ─── World Treasury ───
CREATE TABLE IF NOT EXISTS public.world_treasury (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  world_id        TEXT NOT NULL REFERENCES public.worlds(id) ON DELETE CASCADE,
  balance         INT NOT NULL DEFAULT 0,
  total_donated   INT NOT NULL DEFAULT 0,
  total_spent     INT NOT NULL DEFAULT 0,
  UNIQUE(world_id)
);

ALTER TABLE public.world_treasury ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "treasury_read" ON public.world_treasury;
CREATE POLICY "treasury_read" ON public.world_treasury
  FOR SELECT USING (public.is_world_member(world_id));

CREATE TABLE IF NOT EXISTS public.treasury_transactions (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  world_id        TEXT NOT NULL REFERENCES public.worlds(id) ON DELETE CASCADE,
  user_id         TEXT NOT NULL REFERENCES public.profiles(id),
  transaction_type TEXT NOT NULL CHECK (transaction_type IN ('donation', 'withdrawal', 'tax', 'reward', 'refund')),
  amount          INT NOT NULL,
  description     TEXT DEFAULT '',
  created_at      TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_treasury_tx_world ON public.treasury_transactions(world_id, created_at DESC);

ALTER TABLE public.treasury_transactions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "treasury_tx_read" ON public.treasury_transactions;
CREATE POLICY "treasury_tx_read" ON public.treasury_transactions
  FOR SELECT USING (public.is_world_member(world_id));
DROP POLICY IF EXISTS "treasury_tx_insert" ON public.treasury_transactions;
CREATE POLICY "treasury_tx_insert" ON public.treasury_transactions
  FOR INSERT WITH CHECK (public.is_world_member(world_id));

-- ─── World Polls ───
CREATE TABLE IF NOT EXISTS public.world_polls (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  world_id        TEXT NOT NULL REFERENCES public.worlds(id) ON DELETE CASCADE,
  channel_id      TEXT REFERENCES public.channels(id),
  question        TEXT NOT NULL,
  options         JSONB NOT NULL,
  results         JSONB DEFAULT '{}',
  created_by      TEXT NOT NULL REFERENCES public.profiles(id),
  expires_at      BIGINT,
  is_closed       BOOLEAN DEFAULT FALSE,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_polls_world ON public.world_polls(world_id, is_closed, created_at DESC);

ALTER TABLE public.world_polls ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "polls_read" ON public.world_polls;
CREATE POLICY "polls_read" ON public.world_polls
  FOR SELECT USING (public.is_world_member(world_id));
DROP POLICY IF EXISTS "polls_insert" ON public.world_polls;
CREATE POLICY "polls_insert" ON public.world_polls
  FOR INSERT WITH CHECK (public.is_council_or_above(world_id));
DROP POLICY IF EXISTS "polls_update" ON public.world_polls;
CREATE POLICY "polls_update" ON public.world_polls
  FOR UPDATE USING (public.is_council_or_above(world_id));

-- ─── World Milestones ───
CREATE TABLE IF NOT EXISTS public.world_milestones (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  world_id        TEXT NOT NULL REFERENCES public.worlds(id) ON DELETE CASCADE,
  resident_id     TEXT REFERENCES public.profiles(id),
  milestone_type  TEXT NOT NULL,
  milestone_data  JSONB DEFAULT '{}',
  created_at      TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_milestones_world ON public.world_milestones(world_id, created_at DESC);

ALTER TABLE public.world_milestones ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "milestones_read" ON public.world_milestones;
CREATE POLICY "milestones_read" ON public.world_milestones
  FOR SELECT USING (public.is_world_member(world_id));

-- ─── World Timeline ───
CREATE TABLE IF NOT EXISTS public.world_timeline (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  world_id        TEXT NOT NULL REFERENCES public.worlds(id) ON DELETE CASCADE,
  event_type      TEXT NOT NULL,
  event_data      JSONB DEFAULT '{}',
  event_date      TIMESTAMPTZ DEFAULT NOW(),
  created_at      TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_timeline_world ON public.world_timeline(world_id, event_date DESC);

ALTER TABLE public.world_timeline ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "timeline_read" ON public.world_timeline;
CREATE POLICY "timeline_read" ON public.world_timeline
  FOR SELECT USING (public.is_world_member(world_id));

-- ─── World Challenges/Quests ───
CREATE TABLE IF NOT EXISTS public.world_challenges (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  world_id        TEXT NOT NULL REFERENCES public.worlds(id) ON DELETE CASCADE,
  title           TEXT NOT NULL,
  description     TEXT NOT NULL,
  challenge_type  TEXT NOT NULL DEFAULT 'individual' CHECK (challenge_type IN ('individual', 'collective')),
  target_value    INT NOT NULL,
  current_value   INT DEFAULT 0,
  reward_xp       INT DEFAULT 0,
  reward_currency INT DEFAULT 0,
  starts_at       TIMESTAMPTZ DEFAULT NOW(),
  expires_at      TIMESTAMPTZ,
  is_active       BOOLEAN DEFAULT TRUE,
  created_by      TEXT NOT NULL REFERENCES public.profiles(id),
  created_at      TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_challenges_world ON public.world_challenges(world_id, is_active, expires_at DESC);

ALTER TABLE public.world_challenges ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "challenges_read" ON public.world_challenges;
CREATE POLICY "challenges_read" ON public.world_challenges
  FOR SELECT USING (public.is_world_member(world_id));
DROP POLICY IF EXISTS "challenges_insert" ON public.world_challenges;
CREATE POLICY "challenges_insert" ON public.world_challenges
  FOR INSERT WITH CHECK (public.is_sovereign_or_council(world_id));
DROP POLICY IF EXISTS "challenges_update" ON public.world_challenges;
CREATE POLICY "challenges_update" ON public.world_challenges
  FOR UPDATE USING (public.is_sovereign_or_council(world_id));

-- ─── Challenge Progress ───
CREATE TABLE IF NOT EXISTS public.challenge_progress (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  challenge_id    UUID NOT NULL REFERENCES public.world_challenges(id) ON DELETE CASCADE,
  resident_id     TEXT NOT NULL REFERENCES public.profiles(id),
  contribution    INT DEFAULT 0,
  completed       BOOLEAN DEFAULT FALSE,
  completed_at    TIMESTAMPTZ,
  UNIQUE(challenge_id, resident_id)
);

ALTER TABLE public.challenge_progress ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "challenge_progress_read" ON public.challenge_progress;
CREATE POLICY "challenge_progress_read" ON public.challenge_progress
  FOR SELECT USING (resident_id = auth.uid()::text OR public.is_world_member((SELECT world_id FROM public.world_challenges WHERE id = challenge_id)));
DROP POLICY IF EXISTS "challenge_progress_upsert" ON public.challenge_progress;
CREATE POLICY "challenge_progress_upsert" ON public.challenge_progress
  FOR INSERT WITH CHECK (resident_id = auth.uid()::text);
DROP POLICY IF EXISTS "challenge_progress_update" ON public.challenge_progress;
CREATE POLICY "challenge_progress_update" ON public.challenge_progress
  FOR UPDATE USING (resident_id = auth.uid()::text);

-- ─── World Templates ───
CREATE TABLE IF NOT EXISTS public.world_templates (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id      TEXT NOT NULL REFERENCES public.profiles(id),
  name            TEXT NOT NULL,
  description     TEXT DEFAULT '',
  dominion_type   TEXT DEFAULT '',
  template_data   JSONB NOT NULL,
  uses_count      INT DEFAULT 0,
  is_public       BOOLEAN DEFAULT TRUE,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_templates_public ON public.world_templates(is_public, uses_count DESC);

ALTER TABLE public.world_templates ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "templates_read" ON public.world_templates;
CREATE POLICY "templates_read" ON public.world_templates
  FOR SELECT USING (is_public OR creator_id = auth.uid()::text);
DROP POLICY IF EXISTS "templates_insert" ON public.world_templates;
CREATE POLICY "templates_insert" ON public.world_templates
  FOR INSERT WITH CHECK (creator_id = auth.uid()::text);
DROP POLICY IF EXISTS "templates_update" ON public.world_templates;
CREATE POLICY "templates_update" ON public.world_templates
  FOR UPDATE USING (creator_id = auth.uid()::text);
DROP POLICY IF EXISTS "templates_delete" ON public.world_templates;
CREATE POLICY "templates_delete" ON public.world_templates
  FOR DELETE USING (creator_id = auth.uid()::text);

-- ─── World Analytics (Aggregated) ───
CREATE TABLE IF NOT EXISTS public.world_analytics (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  world_id        TEXT NOT NULL REFERENCES public.worlds(id) ON DELETE CASCADE,
  date            DATE NOT NULL,
  metric_name     TEXT NOT NULL,
  metric_value    INT DEFAULT 0,
  UNIQUE(world_id, date, metric_name)
);
CREATE INDEX IF NOT EXISTS idx_analytics_world ON public.world_analytics(world_id, date DESC);

ALTER TABLE public.world_analytics ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "analytics_read" ON public.world_analytics;
CREATE POLICY "analytics_read" ON public.world_analytics
  FOR SELECT USING (public.is_sovereign_or_council(world_id));

-- ─── World Rivalries ───
CREATE TABLE IF NOT EXISTS public.world_rivalries (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  world_1_id      TEXT NOT NULL REFERENCES public.worlds(id) ON DELETE CASCADE,
  world_2_id      TEXT NOT NULL REFERENCES public.worlds(id) ON DELETE CASCADE,
  challenge_type  TEXT DEFAULT 'general',
  status          TEXT DEFAULT 'active' CHECK (status IN ('active', 'resolved', 'pending')),
  world_1_score   INT DEFAULT 0,
  world_2_score   INT DEFAULT 0,
  started_at      TIMESTAMPTZ DEFAULT NOW(),
  resolved_at     TIMESTAMPTZ,
  CHECK (world_1_id != world_2_id),
  UNIQUE(world_1_id, world_2_id, challenge_type, status)
);
CREATE INDEX IF NOT EXISTS idx_rivalries_world ON public.world_rivalries(world_1_id, world_2_id, status);

ALTER TABLE public.world_rivalries ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "rivalries_read" ON public.world_rivalries;
CREATE POLICY "rivalries_read" ON public.world_rivalries
  FOR SELECT USING (public.is_world_member(world_1_id) OR public.is_world_member(world_2_id));
DROP POLICY IF EXISTS "rivalries_insert" ON public.world_rivalries;
CREATE POLICY "rivalries_insert" ON public.world_rivalries
  FOR INSERT WITH CHECK (public.is_sovereign_or_council(world_1_id) AND public.is_sovereign_or_council(world_2_id));

-- ─── Academy: Courses ───
CREATE TABLE IF NOT EXISTS public.academy_courses (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  world_id        TEXT NOT NULL REFERENCES public.worlds(id) ON DELETE CASCADE,
  instructor_id   TEXT NOT NULL REFERENCES public.profiles(id),
  instructor_name TEXT NOT NULL,
  title           TEXT NOT NULL,
  description     TEXT DEFAULT '',
  syllabus        JSONB DEFAULT '[]',
  difficulty      TEXT DEFAULT 'beginner' CHECK (difficulty IN ('beginner', 'intermediate', 'advanced')),
  duration_weeks  INT DEFAULT 4,
  enrolled_count  INT DEFAULT 0,
  is_published    BOOLEAN DEFAULT FALSE,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_courses_world ON public.academy_courses(world_id, is_published);

ALTER TABLE public.academy_courses ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "courses_read" ON public.academy_courses;
CREATE POLICY "courses_read" ON public.academy_courses
  FOR SELECT USING (public.is_world_member(world_id));
DROP POLICY IF EXISTS "courses_insert" ON public.academy_courses;
CREATE POLICY "courses_insert" ON public.academy_courses
  FOR INSERT WITH CHECK (public.is_world_member(world_id));
DROP POLICY IF EXISTS "courses_update" ON public.academy_courses;
CREATE POLICY "courses_update" ON public.academy_courses
  FOR UPDATE USING (instructor_id = auth.uid()::text OR public.is_sovereign_or_council(world_id));

-- ─── Academy: Enrollments ───
CREATE TABLE IF NOT EXISTS public.academy_enrollments (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  course_id       UUID NOT NULL REFERENCES public.academy_courses(id) ON DELETE CASCADE,
  student_id      TEXT NOT NULL REFERENCES public.profiles(id),
  progress_pct    INT DEFAULT 0,
  grade           TEXT,
  completed       BOOLEAN DEFAULT FALSE,
  completed_at    TIMESTAMPTZ,
  enrolled_at     TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(course_id, student_id)
);

ALTER TABLE public.academy_enrollments ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "enrollments_read" ON public.academy_enrollments;
CREATE POLICY "enrollments_read" ON public.academy_enrollments
  FOR SELECT USING (student_id = auth.uid()::text OR public.is_world_member((SELECT world_id FROM public.academy_courses WHERE id = course_id)));
DROP POLICY IF EXISTS "enrollments_insert" ON public.academy_enrollments;
CREATE POLICY "enrollments_insert" ON public.academy_enrollments
  FOR INSERT WITH CHECK (student_id = auth.uid()::text);

-- ─── Academy: Assignments ───
CREATE TABLE IF NOT EXISTS public.academy_assignments (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  course_id       UUID NOT NULL REFERENCES public.academy_courses(id) ON DELETE CASCADE,
  title           TEXT NOT NULL,
  description     TEXT NOT NULL,
  due_date        TIMESTAMPTZ,
  max_points      INT DEFAULT 100,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.academy_assignments ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "assignments_read" ON public.academy_assignments;
CREATE POLICY "assignments_read" ON public.academy_assignments
  FOR SELECT USING (public.is_world_member((SELECT world_id FROM public.academy_courses WHERE id = course_id)));

-- ─── Academy: Submissions ───
CREATE TABLE IF NOT EXISTS public.academy_submissions (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  assignment_id   UUID NOT NULL REFERENCES public.academy_assignments(id) ON DELETE CASCADE,
  student_id      TEXT NOT NULL REFERENCES public.profiles(id),
  content         TEXT,
  attachment_url  TEXT,
  points_earned   INT,
  feedback        TEXT,
  submitted_at    TIMESTAMPTZ DEFAULT NOW(),
  graded_at       TIMESTAMPTZ,
  UNIQUE(assignment_id, student_id)
);

ALTER TABLE public.academy_submissions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "submissions_read" ON public.academy_submissions;
CREATE POLICY "submissions_read" ON public.academy_submissions
  FOR SELECT USING (student_id = auth.uid()::text OR public.is_world_member((SELECT world_id FROM public.academy_courses WHERE id = (SELECT course_id FROM public.academy_assignments WHERE id = assignment_id))));
DROP POLICY IF EXISTS "submissions_insert" ON public.academy_submissions;
CREATE POLICY "submissions_insert" ON public.academy_submissions
  FOR INSERT WITH CHECK (student_id = auth.uid()::text);
DROP POLICY IF EXISTS "submissions_update" ON public.academy_submissions;
CREATE POLICY "submissions_update" ON public.academy_submissions
  FOR UPDATE USING (student_id = auth.uid()::text OR public.is_world_member((SELECT world_id FROM public.academy_courses WHERE id = (SELECT course_id FROM public.academy_assignments WHERE id = assignment_id))));

-- ─── Archive: Documents ───
CREATE TABLE IF NOT EXISTS public.archive_documents (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  world_id        TEXT NOT NULL REFERENCES public.worlds(id) ON DELETE CASCADE,
  author_id       TEXT NOT NULL REFERENCES public.profiles(id),
  author_name     TEXT NOT NULL,
  title           TEXT NOT NULL,
  content         TEXT NOT NULL,
  category        TEXT DEFAULT 'general',
  tags            TEXT[] DEFAULT '{}',
  version         INT DEFAULT 1,
  citations       JSONB DEFAULT '[]',
  is_published    BOOLEAN DEFAULT FALSE,
  view_count      INT DEFAULT 0,
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  updated_at      TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_documents_world ON public.archive_documents(world_id, is_published, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_documents_search ON public.archive_documents USING GIN (to_tsvector('english', title || ' ' || content));

ALTER TABLE public.archive_documents ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "documents_read" ON public.archive_documents;
CREATE POLICY "documents_read" ON public.archive_documents
  FOR SELECT USING (public.is_world_member(world_id) OR is_published);
DROP POLICY IF EXISTS "documents_insert" ON public.archive_documents;
CREATE POLICY "documents_insert" ON public.archive_documents
  FOR INSERT WITH CHECK (public.is_world_member(world_id));
DROP POLICY IF EXISTS "documents_update" ON public.archive_documents;
CREATE POLICY "documents_update" ON public.archive_documents
  FOR UPDATE USING (author_id = auth.uid()::text OR public.is_sovereign_or_council(world_id));
DROP POLICY IF EXISTS "documents_delete" ON public.archive_documents;
CREATE POLICY "documents_delete" ON public.archive_documents
  FOR DELETE USING (author_id = auth.uid()::text OR public.is_sovereign_or_council(world_id));

-- ─── Archive: Document Versions ───
CREATE TABLE IF NOT EXISTS public.archive_document_versions (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  document_id     UUID NOT NULL REFERENCES public.archive_documents(id) ON DELETE CASCADE,
  version         INT NOT NULL,
  content         TEXT NOT NULL,
  change_summary  TEXT DEFAULT '',
  created_by      TEXT NOT NULL REFERENCES public.profiles(id),
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.archive_document_versions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "doc_versions_read" ON public.archive_document_versions;
CREATE POLICY "doc_versions_read" ON public.archive_document_versions
  FOR SELECT USING (public.is_world_member((SELECT world_id FROM public.archive_documents WHERE id = document_id)));

-- ─── Archive: Curators ───
CREATE TABLE IF NOT EXISTS public.archive_curators (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  world_id        TEXT NOT NULL REFERENCES public.worlds(id) ON DELETE CASCADE,
  curator_id      TEXT NOT NULL REFERENCES public.profiles(id),
  curator_name    TEXT NOT NULL,
  rank            TEXT DEFAULT 'curator' CHECK (rank IN ('curator', 'senior_curator', 'archivist', 'keeper')),
  appointed_at    TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(world_id, curator_id)
);

ALTER TABLE public.archive_curators ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "curators_read" ON public.archive_curators;
CREATE POLICY "curators_read" ON public.archive_curators
  FOR SELECT USING (public.is_world_member(world_id));

-- ─── RPC: Create Listing ───
CREATE OR REPLACE FUNCTION public.create_listing(
  p_world_id TEXT,
  p_title TEXT,
  p_description TEXT,
  p_price TEXT,
  p_price_note TEXT,
  p_category TEXT,
  p_image_url TEXT
) RETURNS UUID AS $$
DECLARE
  v_listing_id UUID;
  v_seller_name TEXT;
BEGIN
  SELECT display_name INTO v_seller_name FROM public.profiles WHERE id = auth.uid()::text;
  
  INSERT INTO public.world_listings (world_id, seller_id, seller_name, title, description, price, price_note, category, image_url)
  VALUES (p_world_id, auth.uid()::text, v_seller_name, p_title, p_description, p_price, p_price_note, p_category, p_image_url)
  RETURNING id INTO v_listing_id;
  
  RETURN v_listing_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

-- ─── RPC: Vote on Poll ───
CREATE OR REPLACE FUNCTION public.vote_on_poll(
  p_poll_id UUID,
  p_option_index INT,
  p_user_id TEXT
) RETURNS BOOLEAN AS $$
DECLARE
  v_poll RECORD;
  v_results JSONB;
  v_option_count INT;
BEGIN
  SELECT * INTO v_poll FROM public.world_polls WHERE id = p_poll_id AND is_closed = FALSE;
  IF NOT FOUND THEN RETURN FALSE; END IF;
  
  v_results := COALESCE(v_poll.results, '{}'::jsonb);
  v_option_count := jsonb_array_length(v_poll.options);
  
  IF p_option_index < 0 OR p_option_index >= v_option_count THEN RETURN FALSE; END IF;
  
  v_results := jsonb_set(v_results, ARRAY[p_option_index::text], 
    COALESCE((v_results->>p_option_index::text)::int, 0)::text::jsonb + 1);
  
  UPDATE public.world_polls SET results = v_results WHERE id = p_poll_id;
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

-- ─── RPC: Donate to Treasury ───
CREATE OR REPLACE FUNCTION public.donate_to_treasury(
  p_world_id TEXT,
  p_amount INT,
  p_description TEXT
) RETURNS BOOLEAN AS $$
DECLARE
  v_user_id TEXT;
BEGIN
  v_user_id := auth.uid()::text;
  
  INSERT INTO public.treasury_transactions (world_id, user_id, transaction_type, amount, description)
  VALUES (p_world_id, v_user_id, 'donation', p_amount, p_description);
  
  UPDATE public.world_treasury 
  SET balance = balance + p_amount, total_donated = total_donated + p_amount
  WHERE world_id = p_world_id;
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

-- ─── RPC: Withdraw from Treasury ───
CREATE OR REPLACE FUNCTION public.withdraw_from_treasury(
  p_world_id TEXT,
  p_amount INT,
  p_description TEXT
) RETURNS BOOLEAN AS $$
DECLARE
  v_balance INT;
BEGIN
  SELECT balance INTO v_balance FROM public.world_treasury WHERE world_id = p_world_id;
  IF v_balance IS NULL OR v_balance < p_amount THEN RETURN FALSE; END IF;
  
  INSERT INTO public.treasury_transactions (world_id, user_id, transaction_type, amount, description)
  VALUES (p_world_id, auth.uid()::text, 'withdrawal', p_amount, p_description);
  
  UPDATE public.world_treasury 
  SET balance = balance - p_amount, total_spent = total_spent + p_amount
  WHERE world_id = p_world_id;
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

-- ─── RPC: Update Challenge Progress ───
CREATE OR REPLACE FUNCTION public.update_challenge_progress(
  p_challenge_id UUID,
  p_contribution INT
) RETURNS BOOLEAN AS $$
DECLARE
  v_challenge RECORD;
  v_progress RECORD;
BEGIN
  SELECT * INTO v_challenge FROM public.world_challenges WHERE id = p_challenge_id AND is_active = TRUE;
  IF NOT FOUND THEN RETURN FALSE; END IF;
  
  SELECT * INTO v_progress FROM public.challenge_progress 
    WHERE challenge_id = p_challenge_id AND resident_id = auth.uid()::text;
  
  IF v_progress IS NULL THEN
    INSERT INTO public.challenge_progress (challenge_id, resident_id, contribution)
    VALUES (p_challenge_id, auth.uid()::text, p_contribution);
  ELSE
    UPDATE public.challenge_progress 
    SET contribution = contribution + p_contribution
    WHERE challenge_id = p_challenge_id AND resident_id = auth.uid()::text;
  END IF;
  
  UPDATE public.world_challenges 
  SET current_value = (SELECT SUM(contribution) FROM public.challenge_progress WHERE challenge_id = p_challenge_id)
  WHERE id = p_challenge_id;
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

-- ─── RPC: Increment Document Views ───
CREATE OR REPLACE FUNCTION public.increment_doc_views(
  p_doc_id UUID
) RETURNS VOID AS $$
BEGIN
  UPDATE public.archive_documents SET view_count = view_count + 1 WHERE id = p_doc_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

-- ─── RPC: Create World from Template ───
CREATE OR REPLACE FUNCTION public.create_world_from_template(
  p_template_id UUID,
  p_world_id TEXT,
  p_world_name TEXT,
  p_sovereign_id TEXT
) RETURNS BOOLEAN AS $$
DECLARE
  v_template RECORD;
BEGIN
  SELECT * INTO v_template FROM public.world_templates WHERE id = p_template_id;
  IF NOT FOUND THEN RETURN FALSE; END IF;
  
  UPDATE public.world_templates SET uses_count = uses_count + 1 WHERE id = p_template_id;
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

-- ─── RPC: Record World Analytics ───
CREATE OR REPLACE FUNCTION public.record_analytics(
  p_world_id TEXT,
  p_date DATE,
  p_metric_name TEXT,
  p_metric_value INT
) RETURNS VOID AS $$
BEGIN
  INSERT INTO public.world_analytics (world_id, date, metric_name, metric_value)
  VALUES (p_world_id, p_date, p_metric_name, p_metric_value)
  ON CONFLICT (world_id, date, metric_name) 
  DO UPDATE SET metric_value = EXCLUDED.metric_value;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;
