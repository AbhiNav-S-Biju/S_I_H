-- Allow paired patient devices to record their own non-clinical game sessions.
-- Caregiver direct inserts remain protected by the existing RLS policy.

ALTER TABLE public.game_sessions
  DROP CONSTRAINT IF EXISTS game_sessions_game_type_check;

ALTER TABLE public.game_sessions
  ADD CONSTRAINT game_sessions_game_type_check
  CHECK (game_type IN (
    'remember_objects',
    'who_is_this',
    'grocery_memory',
    'jigsaw_puzzle'
  ));

CREATE OR REPLACE FUNCTION public.record_patient_game_session(
  p_patient_id UUID,
  p_device_id TEXT,
  p_session JSONB
) RETURNS VOID AS $$
BEGIN
  IF p_device_id IS NULL OR length(trim(p_device_id)) = 0 THEN
    RAISE EXCEPTION 'A paired device ID is required';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.patient_devices
    WHERE patient_id = p_patient_id
      AND device_id = p_device_id
      AND is_active = true
  ) THEN
    RAISE EXCEPTION 'Device is not actively paired with this patient';
  END IF;

  INSERT INTO public.game_sessions (
    id,
    patient_id,
    game_type,
    difficulty_level,
    total_trials,
    successful_trials,
    duration_seconds,
    activity_metadata,
    started_at,
    completed_at,
    created_at
  ) VALUES (
    COALESCE((p_session->>'id')::UUID, gen_random_uuid()),
    p_patient_id,
    p_session->>'game_type',
    COALESCE((p_session->>'difficulty_level')::INT, 1),
    COALESCE((p_session->>'total_trials')::INT, 0),
    COALESCE((p_session->>'successful_trials')::INT, 0),
    COALESCE((p_session->>'duration_seconds')::INT, 0),
    COALESCE(p_session->'activity_metadata', '{}'::JSONB),
    (p_session->>'started_at')::TIMESTAMPTZ,
    (p_session->>'completed_at')::TIMESTAMPTZ,
    COALESCE((p_session->>'created_at')::TIMESTAMPTZ, TIMEZONE('utc', NOW()))
  )
  ON CONFLICT (id) DO NOTHING;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

REVOKE ALL ON FUNCTION public.record_patient_game_session(UUID, TEXT, JSONB)
  FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.record_patient_game_session(UUID, TEXT, JSONB)
  TO anon, authenticated;
