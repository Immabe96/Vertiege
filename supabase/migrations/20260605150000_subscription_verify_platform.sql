-- Wave 9: record store platform + receipt digest; stricter token checks before grant.

ALTER TABLE public.subscription_purchases
  ADD COLUMN IF NOT EXISTS platform TEXT NOT NULL DEFAULT 'unknown'
    CHECK (platform IN ('ios', 'android', 'unknown')),
  ADD COLUMN IF NOT EXISTS store_receipt_digest TEXT;

CREATE OR REPLACE FUNCTION public.verify_subscription_purchase(
  p_product_id TEXT,
  p_purchase_token TEXT,
  p_platform TEXT DEFAULT 'unknown',
  p_store_payload TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_user_id TEXT;
  v_tier TEXT;
  v_token TEXT;
  v_digest TEXT;
BEGIN
  v_user_id := auth.uid()::text;
  IF v_user_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Not authenticated');
  END IF;

  v_token := trim(p_purchase_token);
  IF v_token IS NULL OR length(v_token) < 8 THEN
    RETURN jsonb_build_object('success', false, 'error', 'Invalid purchase token');
  END IF;

  IF coalesce(p_platform, 'unknown') = 'ios' AND length(v_token) < 16 THEN
    RETURN jsonb_build_object('success', false, 'error', 'Invalid App Store receipt');
  END IF;

  IF coalesce(p_platform, 'unknown') = 'android' AND length(v_token) < 12 THEN
    RETURN jsonb_build_object('success', false, 'error', 'Invalid Play purchase token');
  END IF;

  IF p_store_payload IS NOT NULL AND length(trim(p_store_payload)) > 0 THEN
    v_digest := encode(digest(trim(p_store_payload), 'sha256'), 'hex');
  ELSE
    v_digest := NULL;
  END IF;

  v_tier := CASE p_product_id
    WHEN 'subscription_patrician' THEN 'patrician'
    WHEN 'subscription_sovereign_elite' THEN 'sovereign_elite'
    ELSE NULL
  END;

  IF v_tier IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Unknown subscription product');
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.subscription_purchases
    WHERE purchase_token = v_token
  ) THEN
    RETURN jsonb_build_object('success', false, 'error', 'Purchase already redeemed');
  END IF;

  INSERT INTO public.subscription_purchases (
    user_id,
    product_id,
    purchase_token,
    tier_granted,
    platform,
    store_receipt_digest
  )
  VALUES (
    v_user_id,
    p_product_id,
    v_token,
    v_tier,
    coalesce(nullif(trim(p_platform), ''), 'unknown'),
    v_digest
  );

  UPDATE public.profiles
  SET subscription_tier = v_tier
  WHERE id = v_user_id;

  RETURN jsonb_build_object('success', true, 'tier', v_tier);
END;
$$;

REVOKE ALL ON FUNCTION public.verify_subscription_purchase(TEXT, TEXT, TEXT, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.verify_subscription_purchase(TEXT, TEXT, TEXT, TEXT) TO authenticated;
