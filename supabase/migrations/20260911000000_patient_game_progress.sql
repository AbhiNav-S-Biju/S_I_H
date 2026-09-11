-- Patient-scoped game level progress shared across paired devices.

CREATE TABLE IF NOT EXISTS public.game_level_progress (
  patient_id UUID NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,
  game_type TEXT NOT NULL CHECK (game_type IN (
    'remember_objects', 'who_is_this', 'grocery_memory', 'jigsaw_puzzle'
  )),
  level_number INT NOT NULL CHECK (level_number BETWEEN 1 AND 8),
  stars_earned INT NOT NULL DEFAULT 0 CHECK (stars_earned BETWEEN 0 AND 3),
  best_score INT NOT NULL DEFAULT 0 CHECK (best_score >= 0),
  times_played INT NOT NULL DEFAULT 0 CHECK (times_played >= 0),
  completed_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
  PRIMARY KEY (patient_id, game_type, level_number)
);

ALTER TABLE public.game_level_progress ENABLE ROW LEVEL SECURITY;

CREATE POLICY "game_progress_select_linked"
  ON public.game_level_progress FOR SELECT
  USING (public.is_caregiver_for_patient(patient_id));

CREATE OR REPLACE FUNCTION public.get_patient_game_progress(
  p_patient_id UUID,
  p_device_id TEXT
) RETURNS SETOF public.game_level_progress AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.patient_devices
    WHERE patient_id = p_patient_id
      AND device_id = p_device_id
      AND is_active = true
  ) THEN
    RAISE EXCEPTION 'Device is not actively paired with this patient';
  END IF;

  RETURN QUERY
    SELECT * FROM public.game_level_progress
    WHERE patient_id = p_patient_id
    ORDER BY game_type, level_number;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.upsert_patient_game_progress(
  p_patient_id UUID,
  p_device_id TEXT,
  p_progress JSONB
) RETURNS VOID AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.patient_devices
    WHERE patient_id = p_patient_id
      AND device_id = p_device_id
      AND is_active = true
  ) THEN
    RAISE EXCEPTION 'Device is not actively paired with this patient';
  END IF;

  INSERT INTO public.game_level_progress (
    patient_id, game_type, level_number, stars_earned, best_score,
    times_played, completed_at, updated_at
  ) VALUES (
    p_patient_id,
    p_progress->>'game_type',
    (p_progress->>'level_number')::INT,
    COALESCE((p_progress->>'stars_earned')::INT, 0),
    COALESCE((p_progress->>'best_score')::INT, 0),
    COALESCE((p_progress->>'times_played')::INT, 0),
    (p_progress->>'completed_at')::TIMESTAMPTZ,
    TIMEZONE('utc', NOW())
  )
  ON CONFLICT (patient_id, game_type, level_number) DO UPDATE SET
    stars_earned = GREATEST(game_level_progress.stars_earned, EXCLUDED.stars_earned),
    best_score = GREATEST(game_level_progress.best_score, EXCLUDED.best_score),
    times_played = GREATEST(game_level_progress.times_played, EXCLUDED.times_played),
    completed_at = COALESCE(EXCLUDED.completed_at, game_level_progress.completed_at),
    updated_at = TIMEZONE('utc', NOW());
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

REVOKE ALL ON FUNCTION public.get_patient_game_progress(UUID, TEXT) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.upsert_patient_game_progress(UUID, TEXT, JSONB) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_patient_game_progress(UUID, TEXT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.upsert_patient_game_progress(UUID, TEXT, JSONB) TO anon, authenticated;