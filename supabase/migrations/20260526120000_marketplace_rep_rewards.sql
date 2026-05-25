-- Marketplace economy: rep rewards + sync profiles.world_standings from world_members.

CREATE OR REPLACE FUNCTION public.bump_world_member_rep(
  p_world_id TEXT,
  p_resident_id TEXT,
  p_delta INT
) RETURNS INT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_new_rep INT;
  v_standings JSONB;
BEGIN
  IF p_delta IS NULL OR p_delta = 0 THEN
    SELECT rep INTO v_new_rep
    FROM public.world_members
    WHERE world_id = p_world_id AND resident_id = p_resident_id;
    RETURN COALESCE(v_new_rep, 0);
  END IF;

  UPDATE public.world_members
  SET rep = GREATEST(0, COALESCE(rep, 0) + p_delta)
  WHERE world_id = p_world_id AND resident_id = p_resident_id
  RETURNING rep INTO v_new_rep;

  IF NOT FOUND THEN
    RETURN 0;
  END IF;

  SELECT COALESCE(world_standings, '{}'::jsonb) INTO v_standings
  FROM public.profiles
  WHERE id = p_resident_id;

  v_standings := jsonb_set(
    v_standings,
    ARRAY[p_world_id],
    jsonb_build_object('rep', v_new_rep),
    true
  );

  UPDATE public.profiles
  SET world_standings = v_standings,
      last_activity_at = NOW()
  WHERE id = p_resident_id;

  RETURN v_new_rep;
END;
$$;

-- Extend purchase: buyer +3 rep, seller +5 rep in this world.
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
  v_buyer_rep INT;
  v_seller_rep INT;
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

  v_buyer_rep := public.bump_world_member_rep(v_listing.world_id, v_buyer, 3);
  v_seller_rep := public.bump_world_member_rep(v_listing.world_id, v_listing.seller_id, 5);

  RETURN jsonb_build_object(
    'success', true,
    'coin_price', v_listing.coin_price,
    'tax', v_tax,
    'seller_received', v_net,
    'buyer_rep', v_buyer_rep,
    'seller_rep', v_seller_rep,
    'buyer_rep_delta', 3,
    'seller_rep_delta', 5
  );
END;
$$;

-- Listing created: seller +2 rep.
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
  v_seller_id TEXT;
  v_rep INT;
BEGIN
  v_seller_id := auth.uid()::text;
  SELECT name INTO v_seller_name FROM public.profiles WHERE id = v_seller_id;

  INSERT INTO public.world_listings (
    world_id, seller_id, seller_name, title, description,
    price, price_note, category, image_url, coin_price
  ) VALUES (
    p_world_id, v_seller_id, COALESCE(v_seller_name, 'Member'),
    p_title, p_description, p_price, p_price_note, p_category, p_image_url, p_coin_price
  )
  RETURNING id INTO v_listing_id;

  v_rep := public.bump_world_member_rep(p_world_id, v_seller_id, 2);

  RETURN v_listing_id;
END;
$$;

REVOKE ALL ON FUNCTION public.bump_world_member_rep(TEXT, TEXT, INT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.bump_world_member_rep(TEXT, TEXT, INT) TO authenticated;
