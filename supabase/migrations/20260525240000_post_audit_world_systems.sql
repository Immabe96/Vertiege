-- Post-audit: jobs board, marketplace purchase → treasury tax, poll vote v2, coin-backed treasury.

-- ─── Listings: coin price for purchases ───
ALTER TABLE public.world_listings
  ADD COLUMN IF NOT EXISTS coin_price INT CHECK (coin_price IS NULL OR coin_price > 0);

-- ─── World jobs (role board) ───
CREATE TABLE IF NOT EXISTS public.world_jobs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  world_id TEXT NOT NULL REFERENCES public.worlds(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  role_label TEXT NOT NULL DEFAULT 'Contributor',
  min_standing_level INT NOT NULL DEFAULT 1 CHECK (min_standing_level BETWEEN 1 AND 7),
  min_tier INT NOT NULL DEFAULT 1 CHECK (min_tier BETWEEN 1 AND 5),
  status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'filled', 'closed')),
  created_by TEXT NOT NULL REFERENCES public.profiles(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_world_jobs_world_status
  ON public.world_jobs (world_id, status, created_at DESC);

ALTER TABLE public.world_jobs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS world_jobs_read ON public.world_jobs;
CREATE POLICY world_jobs_read ON public.world_jobs
  FOR SELECT USING (public.is_world_member(world_id));

DROP POLICY IF EXISTS world_jobs_insert ON public.world_jobs;
CREATE POLICY world_jobs_insert ON public.world_jobs
  FOR INSERT WITH CHECK (
    created_by = auth.uid()::text
    AND public.is_world_member(world_id)
    AND (
      EXISTS (
        SELECT 1 FROM public.worlds w
        WHERE w.id = world_id AND w.sovereign_id = auth.uid()::text
      )
      OR EXISTS (
        SELECT 1 FROM public.world_members wm
        WHERE wm.world_id = world_jobs.world_id
          AND wm.resident_id = auth.uid()::text
          AND wm.rep >= 5000
      )
    )
  );

DROP POLICY IF EXISTS world_jobs_update ON public.world_jobs;
CREATE POLICY world_jobs_update ON public.world_jobs
  FOR UPDATE USING (
    created_by = auth.uid()::text
    OR EXISTS (
      SELECT 1 FROM public.worlds w
      WHERE w.id = world_id AND w.sovereign_id = auth.uid()::text
    )
  );

-- ─── Treasury donate: deduct sovereign coins ───
CREATE OR REPLACE FUNCTION public.donate_to_treasury(
  p_world_id TEXT,
  p_amount INT,
  p_description TEXT
) RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_user_id TEXT;
  v_balance INT;
BEGIN
  v_user_id := auth.uid()::text;
  IF v_user_id IS NULL THEN RETURN FALSE; END IF;
  IF p_amount IS NULL OR p_amount <= 0 THEN RETURN FALSE; END IF;
  IF NOT public.is_world_member(p_world_id) THEN RETURN FALSE; END IF;

  SELECT sovereign_coins INTO v_balance FROM public.profiles WHERE id = v_user_id;
  IF v_balance IS NULL OR v_balance < p_amount THEN RETURN FALSE; END IF;

  UPDATE public.profiles
  SET sovereign_coins = sovereign_coins - p_amount
  WHERE id = v_user_id;

  INSERT INTO public.treasury_transactions (world_id, user_id, transaction_type, amount, description)
  VALUES (p_world_id, v_user_id, 'donation', p_amount, COALESCE(p_description, ''));

  INSERT INTO public.world_treasury (world_id, balance, total_donated)
  VALUES (p_world_id, p_amount, p_amount)
  ON CONFLICT (world_id) DO UPDATE
  SET balance = world_treasury.balance + p_amount,
      total_donated = world_treasury.total_donated + p_amount;

  RETURN TRUE;
END;
$$;

-- ─── Marketplace purchase: coins → seller, tax → treasury ───
CREATE OR REPLACE FUNCTION public.purchase_listing(p_listing_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_buyer TEXT;
  v_listing RECORD;
  v_tax_rate INT;
  v_tax INT;
  v_net INT;
  v_buyer_coins INT;
  v_seller_coins INT;
BEGIN
  v_buyer := auth.uid()::text;
  IF v_buyer IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Not authenticated');
  END IF;

  SELECT l.*, w.tax_rate
  INTO v_listing
  FROM public.world_listings l
  JOIN public.worlds w ON w.id = l.world_id
  WHERE l.id = p_listing_id
  FOR UPDATE OF l;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Listing not found');
  END IF;
  IF v_listing.status <> 'active' THEN
    RETURN jsonb_build_object('success', false, 'error', 'Listing not available');
  END IF;
  IF v_listing.seller_id = v_buyer THEN
    RETURN jsonb_build_object('success', false, 'error', 'Cannot buy your own listing');
  END IF;
  IF v_listing.coin_price IS NULL OR v_listing.coin_price <= 0 THEN
    RETURN jsonb_build_object('success', false, 'error', 'Listing has no coin price');
  END IF;
  IF NOT public.is_world_member(v_listing.world_id) THEN
    RETURN jsonb_build_object('success', false, 'error', 'Join this world first');
  END IF;

  SELECT sovereign_coins INTO v_buyer_coins FROM public.profiles WHERE id = v_buyer;
  IF v_buyer_coins IS NULL OR v_buyer_coins < v_listing.coin_price THEN
    RETURN jsonb_build_object('success', false, 'error', 'Not enough sovereign coins');
  END IF;

  v_tax_rate := COALESCE(v_listing.tax_rate, 0);
  v_tax := (v_listing.coin_price * v_tax_rate / 100);
  v_net := v_listing.coin_price - v_tax;

  UPDATE public.profiles
  SET sovereign_coins = sovereign_coins - v_listing.coin_price
  WHERE id = v_buyer;

  SELECT sovereign_coins INTO v_seller_coins FROM public.profiles WHERE id = v_listing.seller_id;
  UPDATE public.profiles
  SET sovereign_coins = COALESCE(v_seller_coins, 0) + v_net
  WHERE id = v_listing.seller_id;

  IF v_tax > 0 THEN
    INSERT INTO public.treasury_transactions (
      world_id, user_id, transaction_type, amount, description
    ) VALUES (
      v_listing.world_id,
      v_buyer,
      'tax',
      v_tax,
      'Marketplace tax on listing ' || p_listing_id::text
    );

    INSERT INTO public.world_treasury (world_id, balance, total_donated)
    VALUES (v_listing.world_id, v_tax, v_tax)
    ON CONFLICT (world_id) DO UPDATE
    SET balance = world_treasury.balance + v_tax,
        total_donated = world_treasury.total_donated + v_tax;
  END IF;

  UPDATE public.world_listings
  SET status = 'sold'
  WHERE id = p_listing_id;

  RETURN jsonb_build_object(
    'success', true,
    'coin_price', v_listing.coin_price,
    'tax', v_tax,
    'seller_received', v_net
  );
END;
$$;

-- ─── Create listing with optional coin price ───
CREATE OR REPLACE FUNCTION public.create_listing(
  p_world_id TEXT,
  p_title TEXT,
  p_description TEXT,
  p_price TEXT,
  p_price_note TEXT,
  p_category TEXT,
  p_image_url TEXT,
  p_coin_price INT DEFAULT NULL
) RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_listing_id UUID;
  v_seller_name TEXT;
BEGIN
  SELECT display_name INTO v_seller_name FROM public.profiles WHERE id = auth.uid()::text;

  INSERT INTO public.world_listings (
    world_id, seller_id, seller_name, title, description,
    price, price_note, category, image_url, coin_price
  )
  VALUES (
    p_world_id, auth.uid()::text, v_seller_name, p_title, p_description,
    p_price, p_price_note, p_category, p_image_url, p_coin_price
  )
  RETURNING id INTO v_listing_id;

  RETURN v_listing_id;
END;
$$;

-- ─── Poll vote v2 (member check + voter tracking) ───
CREATE OR REPLACE FUNCTION public.vote_on_poll_v2(
  p_poll_id UUID,
  p_option_index INT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_poll RECORD;
  v_results JSONB;
  v_option_count INT;
  v_user_id TEXT;
  v_entry JSONB;
  v_voters JSONB;
  v_count INT;
BEGIN
  v_user_id := auth.uid()::text;
  IF v_user_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Not authenticated');
  END IF;

  SELECT * INTO v_poll FROM public.world_polls WHERE id = p_poll_id AND is_closed = FALSE;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Poll not found or closed');
  END IF;

  IF NOT public.is_world_member(v_poll.world_id) THEN
    RETURN jsonb_build_object('success', false, 'error', 'Not a member of this world');
  END IF;

  v_results := COALESCE(v_poll.results, '{}'::jsonb);
  v_option_count := jsonb_array_length(v_poll.options);

  IF p_option_index < 0 OR p_option_index >= v_option_count THEN
    RETURN jsonb_build_object('success', false, 'error', 'Invalid option');
  END IF;

  -- Prevent double vote on any option in this poll
  FOR v_entry IN SELECT value FROM jsonb_each(v_results) LOOP
    v_voters := v_entry->'voters';
    IF v_voters IS NOT NULL AND v_voters ? v_user_id THEN
      RETURN jsonb_build_object('success', false, 'error', 'Already voted');
    END IF;
  END LOOP;

  v_entry := v_results->(p_option_index::text);
  IF v_entry IS NULL OR jsonb_typeof(v_entry) <> 'object' THEN
    v_results := jsonb_set(
      v_results,
      ARRAY[p_option_index::text],
      jsonb_build_object('count', 1, 'voters', jsonb_build_array(v_user_id))
    );
  ELSE
    v_count := COALESCE((v_entry->>'count')::int, 0) + 1;
    v_voters := COALESCE(v_entry->'voters', '[]'::jsonb) || to_jsonb(v_user_id);
    v_results := jsonb_set(
      v_results,
      ARRAY[p_option_index::text],
      jsonb_build_object('count', v_count, 'voters', v_voters)
    );
  END IF;

  UPDATE public.world_polls SET results = v_results WHERE id = p_poll_id;

  RETURN jsonb_build_object('success', true, 'results', v_results);
END;
$$;

REVOKE ALL ON FUNCTION public.purchase_listing(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.purchase_listing(UUID) TO authenticated;
REVOKE ALL ON FUNCTION public.vote_on_poll_v2(UUID, INT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.vote_on_poll_v2(UUID, INT) TO authenticated;
