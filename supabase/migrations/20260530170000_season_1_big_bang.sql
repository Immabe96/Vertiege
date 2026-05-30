-- Season 1: The Big Bang — global season metadata (not league brackets).

CREATE TABLE IF NOT EXISTS public.global_seasons (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  tagline TEXT NOT NULL DEFAULT '',
  narrative TEXT NOT NULL DEFAULT '',
  starts_at TIMESTAMPTZ NOT NULL,
  ends_at TIMESTAMPTZ,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.global_seasons ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS global_seasons_read ON public.global_seasons;
CREATE POLICY global_seasons_read ON public.global_seasons
  FOR SELECT USING (true);

INSERT INTO public.global_seasons (
  id,
  name,
  tagline,
  narrative,
  starts_at,
  ends_at,
  is_active
)
VALUES (
  'season_1',
  'Season 1: The Big Bang',
  'Empty worlds fill. New councils rise. Sovereigns claim the map.',
  'The first age of Vertiege: dormant realms awaken, residents claim standing, '
  'and worlds grow through real achievement — not paid shortcuts. '
  'Watch unclaimed worlds gain sovereigns, councils form, and prestige unlock '
  'lounge, treasury, and governance together.',
  '2026-01-01T00:00:00Z',
  NULL,
  true
)
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  tagline = EXCLUDED.tagline,
  narrative = EXCLUDED.narrative,
  is_active = EXCLUDED.is_active;
