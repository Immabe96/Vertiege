-- Treasury withdrawals: council and sovereign only (no member proposals).

CREATE OR REPLACE FUNCTION public.request_treasury_withdrawal(
  p_world_id TEXT,
  p_amount INT,
  p_description TEXT DEFAULT ''
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Not authenticated');
  END IF;
  IF NOT public.is_council_or_above(p_world_id) THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Only council or sovereign may withdraw from treasury'
    );
  END IF;
  IF public.withdraw_from_treasury(p_world_id, p_amount, p_description) THEN
    RETURN jsonb_build_object('success', true, 'executed', true);
  END IF;
  RETURN jsonb_build_object('success', false, 'error', 'Withdrawal failed');
END;
$$;
