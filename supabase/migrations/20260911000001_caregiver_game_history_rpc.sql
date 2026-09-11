-- Return patient game history through an explicitly caregiver-authorized RPC.

CREATE OR REPLACE FUNCTION public.get_caregiver_game_history(
  p_patient_id UUID,
  p_limit INT DEFAULT 50
) RETURNS SETOF public.game_sessions AS $$
BEGIN
  IF NOT public.is_caregiver_for_patient(p_patient_id) THEN
    RAISE EXCEPTION 'Access denied: caller is not an authorized caregiver';
  END IF;

  RETURN QUERY
    SELECT *
    FROM public.game_sessions
    WHERE patient_id = p_patient_id
    ORDER BY completed_at DESC
    LIMIT LEAST(GREATEST(COALESCE(p_limit, 50), 1), 100);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

REVOKE ALL ON FUNCTION public.get_caregiver_game_history(UUID, INT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_caregiver_game_history(UUID, INT) TO authenticated;