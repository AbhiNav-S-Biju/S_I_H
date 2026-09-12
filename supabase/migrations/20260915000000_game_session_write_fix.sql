-- ==============================================================================
-- NIRVANA — GAME SESSION WRITE PATH FIX
-- Migration: 20260915000000_game_session_write_fix.sql
--
-- WHY THIS MIGRATION EXISTS
-- Patient game results were not reaching public.game_sessions, and the caregiver
-- dashboard showed nothing. Root causes found on the client (fixed in Dart):
--   1. recordGameSession() sent a *randomly generated* device id when the stored
--      session had none, which the paired-device check rejected.
--   2. The rejection was swallowed into a sync queue that is never drained, so
--      the failure was completely silent.
--
-- This migration hardens the server side so the remaining failure modes are
-- visible and self-diagnosing rather than silent:
--
--   1. record_patient_game_session now returns JSONB instead of VOID, so the
--      client can distinguish "saved" from "rejected" without guessing.
--   2. It returns a precise reason code instead of a bare exception.
--   3. It tolerates a missing/blank device id ONLY when the patient has exactly
--      one active device (recovering already-paired installs whose local device
--      id was lost) — otherwise it still refuses.
--   4. It stamps activity_metadata with the source, so rows written via the
--      patient RPC are distinguishable from caregiver-authored rows.
--
-- IDEMPOTENT: safe to re-run.
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. Device resolution helper.
--    Returns the device row id when (patient, device) is a valid active pair.
--    When p_device_id is blank, falls back to the patient's single active device
--    so an install that lost its local id can still save (but never when the
--    patient has 0 or 2+ active devices, which would be ambiguous).
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.resolve_patient_device(
    p_patient_id UUID,
    p_device_id TEXT
) RETURNS TEXT AS $$
DECLARE
    v_device TEXT;
    v_active_count INT;
BEGIN
    IF p_patient_id IS NULL THEN
        RETURN NULL;
    END IF;

    -- Exact match on an active pairing.
    IF p_device_id IS NOT NULL AND length(trim(p_device_id)) > 0 THEN
        SELECT pd.device_id INTO v_device
        FROM public.patient_devices pd
        WHERE pd.patient_id = p_patient_id
          AND pd.device_id = p_device_id
          AND pd.is_active = TRUE
        LIMIT 1;

        RETURN v_device; -- NULL when not paired
    END IF;

    -- No device id supplied: only safe when exactly one active device exists.
    SELECT COUNT(*) INTO v_active_count
    FROM public.patient_devices
    WHERE patient_id = p_patient_id
      AND is_active = TRUE;

    IF v_active_count = 1 THEN
        SELECT device_id INTO v_device
        FROM public.patient_devices
        WHERE patient_id = p_patient_id
          AND is_active = TRUE
        LIMIT 1;
        RETURN v_device;
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

REVOKE ALL ON FUNCTION public.resolve_patient_device(UUID, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.resolve_patient_device(UUID, TEXT) TO anon, authenticated;

-- ------------------------------------------------------------------------------
-- 2. record_patient_game_session — now returns JSONB and a reason code.
--    Replaces the previous VOID version so the client can tell success from
--    rejection. The old VOID signature is dropped to avoid overload ambiguity.
-- ------------------------------------------------------------------------------
DROP FUNCTION IF EXISTS public.record_patient_game_session(UUID, TEXT, JSONB);

CREATE OR REPLACE FUNCTION public.record_patient_game_session(
    p_patient_id UUID,
    p_device_id TEXT,
    p_session JSONB
) RETURNS JSONB AS $$
DECLARE
    v_device TEXT;
    v_session_id UUID;
    v_game_type TEXT;
    v_total INT;
    v_successful INT;
BEGIN
    -- --- Validate inputs with precise reason codes -------------------------------
    IF p_patient_id IS NULL THEN
        RETURN jsonb_build_object(
            'success', FALSE, 'error', 'MISSING_PATIENT', 'message', 'No patient id supplied');
    END IF;

    IF p_session IS NULL OR p_session = '{}'::JSONB THEN
        RETURN jsonb_build_object(
            'success', FALSE, 'error', 'EMPTY_SESSION', 'message', 'No session payload supplied');
    END IF;

    v_game_type := p_session->>'game_type';
    IF v_game_type IS NULL OR v_game_type NOT IN (
        'remember_objects', 'who_is_this', 'grocery_memory', 'jigsaw_puzzle'
    ) THEN
        RETURN jsonb_build_object(
            'success', FALSE, 'error', 'INVALID_GAME_TYPE', 'game_type', v_game_type);
    END IF;

    -- --- Device authorization -----------------------------------------------------
    v_device := public.resolve_patient_device(p_patient_id, p_device_id);

    IF v_device IS NULL THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'error', 'DEVICE_NOT_PAIRED',
            'message', 'This device is not actively paired with the patient. '
                       'Re-pair the device, then try again.'
        );
    END IF;

    -- --- Clamp counters so a malformed payload cannot violate CHECK constraints ---
    v_total := GREATEST(COALESCE((p_session->>'total_trials')::INT, 0), 0);
    v_successful := GREATEST(COALESCE((p_session->>'successful_trials')::INT, 0), 0);
    IF v_successful > v_total AND v_total > 0 THEN
        v_successful := v_total;
    END IF;

    v_session_id := COALESCE((p_session->>'id')::UUID, gen_random_uuid());

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
        v_session_id,
        p_patient_id,
        v_game_type,
        LEAST(GREATEST(COALESCE((p_session->>'difficulty_level')::INT, 1), 1), 5),
        v_total,
        v_successful,
        GREATEST(COALESCE((p_session->>'duration_seconds')::INT, 0), 0),
        -- Tag the origin so patient-recorded rows are identifiable, and make
        -- sure the column is never NULL (it is NOT NULL in the schema).
        COALESCE(p_session->'activity_metadata', '{}'::JSONB)
            || jsonb_build_object('recorded_via', 'patient_device'),
        COALESCE(
            (p_session->>'started_at')::TIMESTAMPTZ,
            TIMEZONE('utc', NOW())
        ),
        COALESCE(
            (p_session->>'completed_at')::TIMESTAMPTZ,
            TIMEZONE('utc', NOW())
        ),
        COALESCE((p_session->>'created_at')::TIMESTAMPTZ, TIMEZONE('utc', NOW()))
    )
    ON CONFLICT (id) DO NOTHING;

    -- Distinguish a genuine insert from an idempotent replay.
    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'success', TRUE, 'session_id', v_session_id, 'duplicate', TRUE);
    END IF;

    RETURN jsonb_build_object(
        'success', TRUE, 'session_id', v_session_id, 'duplicate', FALSE);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

REVOKE ALL ON FUNCTION public.record_patient_game_session(UUID, TEXT, JSONB) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.record_patient_game_session(UUID, TEXT, JSONB) TO anon, authenticated;

-- ------------------------------------------------------------------------------
-- 3. caregiver_notifications: add the 'activity_completed' style already used?
--    No. The existing CHECK already permits 'game_completed'. Left untouched.
-- ------------------------------------------------------------------------------

-- ------------------------------------------------------------------------------
-- 4. Backfill diagnostic: report patients whose device pairing is missing.
--    Run this manually to confirm the pairing precondition holds:
--
--      SELECT p.id, p.display_name, COUNT(pd.id) AS active_devices
--      FROM public.patients p
--      LEFT JOIN public.patient_devices pd
--        ON pd.patient_id = p.id AND pd.is_active = TRUE
--      GROUP BY p.id, p.display_name
--      HAVING COUNT(pd.id) <> 1;
--
--    Any row here cannot record game sessions until the device is re-paired.
-- ------------------------------------------------------------------------------

-- ==============================================================================
-- END OF MIGRATION
-- ==============================================================================
