-- ==============================================================================
-- NIRVANA LOCATION HELP — AUTHORIZATION & HARDENING FIX
-- Migration: 20260914000000_location_help_authorization_fix.sql
--
-- WHY THIS MIGRATION EXISTS
-- The previous migration (20260913000000_location_help_feature.sql) assumed the
-- PATIENT device is a Supabase-authenticated user holding the `authenticated`
-- role. It is NOT. In this codebase a patient device is a zero-password,
-- unauthenticated device that identifies itself with (patient_id, device_id),
-- exactly like validate_and_pair_device / process_sync_event / social account
-- RPCs already do. The old policies therefore locked patients out of their own
-- session and allowed no writes at all.
--
-- This migration:
--   1. Replaces the broken location_sessions / patient_locations RLS policies.
--   2. Keeps location data readable ONLY by the authorized caregiver.
--   3. Adds device-verified SECURITY DEFINER RPCs for the patient device.
--   4. Allows 'location_help' notification types (CHECK constraint).
--   5. Exposes caregiver/patient phone numbers for the dialer (via RPC only).
--   6. Never stores raw device_id in location rows (no unnecessary logging).
--
-- IDEMPOTENT: safe to re-run.
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. Helper: is this device the paired, active device for this patient?
--    Mirrors the existing (patient_id, device_id) trust model used elsewhere.
--    Never trust a caller-supplied patient_id without this check.
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.is_device_for_patient(
    p_patient_id UUID,
    p_device_id TEXT
) RETURNS BOOLEAN AS $$
BEGIN
    IF p_patient_id IS NULL OR p_device_id IS NULL OR length(trim(p_device_id)) = 0 THEN
        RETURN FALSE;
    END IF;

    RETURN EXISTS (
        SELECT 1 FROM public.patient_devices
        WHERE patient_id = p_patient_id
          AND device_id = p_device_id
          AND is_active = TRUE
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

REVOKE ALL ON FUNCTION public.is_device_for_patient(UUID, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.is_device_for_patient(UUID, TEXT) TO anon, authenticated;

-- ------------------------------------------------------------------------------
-- 2. Helper: is the caller the authorized caregiver for the session's patient?
--    Used by the caregiver-side RPCs. Patients are never authenticated users.
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.can_view_location_session(
    p_session_id UUID
) RETURNS BOOLEAN AS $$
BEGIN
    IF auth.uid() IS NULL THEN
        RETURN FALSE;
    END IF;

    RETURN EXISTS (
        SELECT 1
        FROM public.location_sessions ls
        WHERE ls.id = p_session_id
          AND public.is_caregiver_for_patient(ls.patient_id)
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

REVOKE ALL ON FUNCTION public.can_view_location_session(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.can_view_location_session(UUID) TO authenticated;
-- ------------------------------------------------------------------------------
-- 3. Replace RLS policies on location_sessions
--    RULE: only an authorized caregiver (authenticated) can read/write rows
--    directly. The patient device touches these tables ONLY through the
--    SECURITY DEFINER RPCs below, which are device-verified.
-- ------------------------------------------------------------------------------
ALTER TABLE public.location_sessions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "location_sessions_select_authorized" ON public.location_sessions;
DROP POLICY IF EXISTS "location_sessions_insert_caregiver" ON public.location_sessions;
DROP POLICY IF EXISTS "location_sessions_update_authorized" ON public.location_sessions;
DROP POLICY IF EXISTS "location_sessions_delete_primary" ON public.location_sessions;
-- new policy names (re-run safety)
DROP POLICY IF EXISTS "location_sessions_select_caregiver" ON public.location_sessions;
DROP POLICY IF EXISTS "location_sessions_update_caregiver" ON public.location_sessions;

-- Authorized caregiver may read the session for their own patient only.
CREATE POLICY "location_sessions_select_caregiver"
    ON public.location_sessions FOR SELECT
    TO authenticated
    USING (public.is_caregiver_for_patient(patient_id));

-- Authorized caregiver may stop / update the session (status='stopped').
-- The WITH CHECK keeps caregiver_id immutable and pins it to a real caregiver.
CREATE POLICY "location_sessions_update_caregiver"
    ON public.location_sessions FOR UPDATE
    TO authenticated
    USING (public.is_caregiver_for_patient(patient_id))
    WITH CHECK (public.is_caregiver_for_patient(patient_id));

-- NOTE: deliberately NO INSERT policy. Sessions are only ever created by the
-- device-verified start_location_help_session() RPC (SECURITY DEFINER), which
-- bypasses RLS. This prevents a caregiver from forging sessions for a patient
-- they do not own, and prevents patients from creating arbitrary rows.

-- ------------------------------------------------------------------------------
-- 4. Replace RLS policies on patient_locations
--    Location rows are readable ONLY by the authorized caregiver, and ONLY while
--    the parent session is still active. Append-only: no UPDATE / DELETE policy.
-- ------------------------------------------------------------------------------
ALTER TABLE public.patient_locations ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "patient_locations_select_caregiver" ON public.patient_locations;
DROP POLICY IF EXISTS "patient_locations_insert_session" ON public.patient_locations;
DROP POLICY IF EXISTS "patient_locations_select_caregiver_active" ON public.patient_locations;

CREATE POLICY "patient_locations_select_caregiver_active"
    ON public.patient_locations FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1
            FROM public.location_sessions ls
            WHERE ls.id = patient_locations.session_id
              AND ls.patient_id = patient_locations.patient_id
              AND ls.status = 'active'
              AND ls.expires_at > TIMEZONE('utc', NOW())
              AND public.is_caregiver_for_patient(ls.patient_id)
        )
    );

-- No INSERT / UPDATE / DELETE policy: writes go through update_patient_location()
-- (SECURITY DEFINER, device-verified). This means even a compromised caregiver
-- token can never fabricate a patient's location trail.

-- ------------------------------------------------------------------------------
-- 5. Allow the new notification types on caregiver_notifications.
--    The previous migration reused 'device_paired' / 'device_revoked' as a
--    workaround; new installs get honest, dedicated types.
-- ------------------------------------------------------------------------------
ALTER TABLE public.caregiver_notifications
    DROP CONSTRAINT IF EXISTS caregiver_notifications_notification_type_check;

ALTER TABLE public.caregiver_notifications
    ADD CONSTRAINT caregiver_notifications_notification_type_check
    CHECK (
        notification_type IN (
            'reminder_completed',
            'reminder_missed',
            'reminder_snoozed',
            'game_completed',
            'device_paired',
            'device_revoked',
            'sync_restored',
            'sync_error',
            'location_help_requested',
            'location_help_stopped'
        )
    );

-- ------------------------------------------------------------------------------
-- 6. Realtime: make sure both tables are published, and that the caregiver only
--    receives rows it is allowed to see. RLS is enforced on realtime payloads,
--    so the SELECT policies above are the access boundary.
-- ------------------------------------------------------------------------------
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime') THEN
        BEGIN
            ALTER PUBLICATION supabase_realtime ADD TABLE public.location_sessions;
        EXCEPTION WHEN duplicate_object THEN NULL;
        END;
        BEGIN
            ALTER PUBLICATION supabase_realtime ADD TABLE public.patient_locations;
        EXCEPTION WHEN duplicate_object THEN NULL;
        END;
    END IF;
END $$;

-- Realtime needs the full row on UPDATE so the caregiver UI sees status change.
ALTER TABLE public.location_sessions REPLICA IDENTITY FULL;
ALTER TABLE public.patient_locations REPLICA IDENTITY FULL;
-- ------------------------------------------------------------------------------
-- 7. RPC: start_location_help_session  (PATIENT DEVICE — device-verified)
--    Called by the patient app after the "I'm Lost" confirmation.
--    Requires the caller to present the paired, active device_id.
--    Creates the session and notifies EVERY authorized caregiver.
-- ------------------------------------------------------------------------------
DROP FUNCTION IF EXISTS public.start_location_help_session(UUID);

CREATE OR REPLACE FUNCTION public.start_location_help_session(
    p_patient_id UUID,
    p_device_id TEXT,
    p_timeout_minutes INT DEFAULT 30
) RETURNS JSONB AS $$
DECLARE
    v_caregiver_id UUID;
    v_session_id UUID;
    v_expires_at TIMESTAMPTZ;
    v_existing RECORD;
BEGIN
    -- 1. Device authorization: never trust p_patient_id on its own.
    IF NOT public.is_device_for_patient(p_patient_id, p_device_id) THEN
        RAISE EXCEPTION 'Access denied: device is not paired with this patient'
            USING ERRCODE = '42501';
    END IF;

    -- 2. Resolve the assigned caregiver (primary first, then any link).
    SELECT primary_caregiver_id INTO v_caregiver_id
    FROM public.patients
    WHERE id = p_patient_id;

    IF v_caregiver_id IS NULL THEN
        SELECT caregiver_id INTO v_caregiver_id
        FROM public.caregiver_patient_links
        WHERE patient_id = p_patient_id
        ORDER BY (access_role = 'primary') DESC, created_at ASC
        LIMIT 1;
    END IF;

    IF v_caregiver_id IS NULL THEN
        RAISE EXCEPTION 'No caregiver is assigned to this patient'
            USING ERRCODE = 'P0002';
    END IF;

    -- 3. Reuse an existing live session instead of creating duplicates.
    SELECT * INTO v_existing
    FROM public.location_sessions
    WHERE patient_id = p_patient_id
      AND status = 'active'
      AND expires_at > TIMEZONE('utc', NOW())
    ORDER BY started_at DESC
    LIMIT 1;

    IF FOUND THEN
        RETURN jsonb_build_object(
            'success', TRUE,
            'session_id', v_existing.id,
            'caregiver_id', v_existing.caregiver_id,
            'expires_at', v_existing.expires_at,
            'reused', TRUE
        );
    END IF;

    -- 4. Expire anything stale left over from an earlier session.
    UPDATE public.location_sessions
    SET status = 'expired',
        stopped_at = TIMEZONE('utc', NOW()),
        updated_at = TIMEZONE('utc', NOW())
    WHERE patient_id = p_patient_id
      AND status = 'active'
      AND expires_at <= TIMEZONE('utc', NOW());

    -- 5. Timeout: clamp to a sane window (5..120 min), default 30 minutes.
    v_expires_at := TIMEZONE('utc', NOW())
        + (GREATEST(5, LEAST(COALESCE(p_timeout_minutes, 30), 120)) || ' minutes')::INTERVAL;

    INSERT INTO public.location_sessions (
        patient_id, caregiver_id, status, started_at, expires_at, last_location_update
    ) VALUES (
        p_patient_id, v_caregiver_id, 'active',
        TIMEZONE('utc', NOW()), v_expires_at, TIMEZONE('utc', NOW())
    ) RETURNING id INTO v_session_id;

    -- 6. Alert every caregiver linked to this patient.
    INSERT INTO public.caregiver_notifications (
        caregiver_id, patient_id, notification_type, title, message, created_at
    )
    SELECT
        cg.caregiver_id,
        p_patient_id,
        'location_help_requested',
        'Patient Needs Help',
        'Your patient has asked for help. Tap to see their live location.',
        TIMEZONE('utc', NOW())
    FROM (
        SELECT caregiver_id FROM public.caregiver_patient_links WHERE patient_id = p_patient_id
        UNION
        SELECT primary_caregiver_id FROM public.patients
        WHERE id = p_patient_id AND primary_caregiver_id IS NOT NULL
    ) AS cg;

    RETURN jsonb_build_object(
        'success', TRUE,
        'session_id', v_session_id,
        'caregiver_id', v_caregiver_id,
        'expires_at', v_expires_at,
        'reused', FALSE
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

REVOKE ALL ON FUNCTION public.start_location_help_session(UUID, TEXT, INT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.start_location_help_session(UUID, TEXT, INT) TO anon, authenticated;
-- ------------------------------------------------------------------------------
-- 8. RPC: update_patient_location  (PATIENT DEVICE — device-verified)
--    Appends one location point. Refuses to write if the session is no longer
--    active or has expired, so sharing stops the moment the session ends.
-- ------------------------------------------------------------------------------
DROP FUNCTION IF EXISTS public.update_patient_location(UUID, DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION);

CREATE OR REPLACE FUNCTION public.update_patient_location(
    p_session_id UUID,
    p_device_id TEXT,
    p_latitude DOUBLE PRECISION,
    p_longitude DOUBLE PRECISION,
    p_accuracy DOUBLE PRECISION DEFAULT NULL,
    p_altitude DOUBLE PRECISION DEFAULT NULL,
    p_speed DOUBLE PRECISION DEFAULT NULL,
    p_heading DOUBLE PRECISION DEFAULT NULL,
    p_recorded_at TIMESTAMPTZ DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
    v_session RECORD;
    v_location_id UUID;
BEGIN
    -- 1. Load the session and verify the device owns it.
    SELECT * INTO v_session
    FROM public.location_sessions
    WHERE id = p_session_id;

    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'success', FALSE, 'error', 'SESSION_NOT_FOUND',
            'message', 'Location session not found'
        );
    END IF;

    IF NOT public.is_device_for_patient(v_session.patient_id, p_device_id) THEN
        RAISE EXCEPTION 'Access denied: device is not paired with this patient'
            USING ERRCODE = '42501';
    END IF;

    -- 2. Reject writes once the session is stopped or has timed out.
    IF v_session.status <> 'active' THEN
        RETURN jsonb_build_object(
            'success', FALSE, 'error', 'SESSION_NOT_ACTIVE',
            'message', 'Session is no longer active'
        );
    END IF;

    IF v_session.expires_at <= TIMEZONE('utc', NOW()) THEN
        -- Self-healing: mark the session expired the first time we notice.
        UPDATE public.location_sessions
        SET status = 'expired',
            stopped_at = TIMEZONE('utc', NOW()),
            updated_at = TIMEZONE('utc', NOW())
        WHERE id = p_session_id AND status = 'active';

        RETURN jsonb_build_object(
            'success', FALSE, 'error', 'SESSION_EXPIRED',
            'message', 'Session has expired'
        );
    END IF;

    -- 3. Sanity-bound the coordinates before storing.
    IF p_latitude IS NULL OR p_longitude IS NULL
       OR p_latitude < -90 OR p_latitude > 90
       OR p_longitude < -180 OR p_longitude > 180 THEN
        RETURN jsonb_build_object(
            'success', FALSE, 'error', 'INVALID_COORDINATES',
            'message', 'Coordinates out of range'
        );
    END IF;

    INSERT INTO public.patient_locations (
        session_id, patient_id, latitude, longitude, accuracy,
        altitude, speed, heading, recorded_at
    ) VALUES (
        p_session_id, v_session.patient_id, p_latitude, p_longitude, p_accuracy,
        p_altitude, p_speed, p_heading,
        COALESCE(p_recorded_at, TIMEZONE('utc', NOW()))
    ) RETURNING id INTO v_location_id;

    UPDATE public.location_sessions
    SET last_location_update = TIMEZONE('utc', NOW()),
        updated_at = TIMEZONE('utc', NOW())
    WHERE id = p_session_id;

    RETURN jsonb_build_object(
        'success', TRUE,
        'location_id', v_location_id,
        'recorded_at', TIMEZONE('utc', NOW())
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

REVOKE ALL ON FUNCTION public.update_patient_location(UUID, TEXT, DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION, TIMESTAMPTZ) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.update_patient_location(UUID, TEXT, DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION, TIMESTAMPTZ) TO anon, authenticated;

-- ------------------------------------------------------------------------------
-- 9. RPC: stop_location_help_session  (BOTH SIDES)
--    Patient device: must present the paired device_id.
--    Caregiver: must be an authorized caregiver for the session's patient.
-- ------------------------------------------------------------------------------
DROP FUNCTION IF EXISTS public.stop_location_help_session(UUID, TEXT);

CREATE OR REPLACE FUNCTION public.stop_location_help_session(
    p_session_id UUID,
    p_device_id TEXT DEFAULT NULL,
    p_stopped_by TEXT DEFAULT 'patient'
) RETURNS JSONB AS $$
DECLARE
    v_session RECORD;
    v_authorized BOOLEAN := FALSE;
BEGIN
    SELECT * INTO v_session
    FROM public.location_sessions
    WHERE id = p_session_id;

    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'success', FALSE, 'error', 'SESSION_NOT_FOUND',
            'message', 'Location session not found'
        );
    END IF;

    -- Authorize as caregiver (authenticated session) or as the patient device.
    v_authorized := public.is_caregiver_for_patient(v_session.patient_id);
    IF NOT v_authorized AND p_device_id IS NOT NULL THEN
        v_authorized := public.is_device_for_patient(v_session.patient_id, p_device_id);
    END IF;

    IF NOT v_authorized THEN
        RAISE EXCEPTION 'Access denied: caller is not authorized for this session'
            USING ERRCODE = '42501';
    END IF;

    IF v_session.status <> 'active' THEN
        -- Already stopped/expired: idempotent success, nothing to unshare.
        RETURN jsonb_build_object(
            'success', TRUE,
            'stopped_at', COALESCE(v_session.stopped_at, v_session.expires_at),
            'already_stopped', TRUE
        );
    END IF;

    UPDATE public.location_sessions
    SET status = 'stopped',
        stopped_at = TIMEZONE('utc', NOW()),
        updated_at = TIMEZONE('utc', NOW())
    WHERE id = p_session_id;

    -- Tell the other side, in plain language.
    IF p_stopped_by = 'caregiver' THEN
        NULL; -- Patient device reflects this through the realtime session stream.
    ELSE
        INSERT INTO public.caregiver_notifications (
            caregiver_id, patient_id, notification_type, title, message, created_at
        ) VALUES (
            v_session.caregiver_id,
            v_session.patient_id,
            'location_help_stopped',
            'Location Sharing Stopped',
            'Your patient has stopped sharing their location.',
            TIMEZONE('utc', NOW())
        );
    END IF;

    RETURN jsonb_build_object(
        'success', TRUE,
        'stopped_at', TIMEZONE('utc', NOW()),
        'already_stopped', FALSE
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

REVOKE ALL ON FUNCTION public.stop_location_help_session(UUID, TEXT, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.stop_location_help_session(UUID, TEXT, TEXT) TO anon, authenticated;
-- ------------------------------------------------------------------------------
-- 10. RPC: get_active_location_session  (PATIENT DEVICE — device-verified)
--     Lets the patient app restore an in-flight session after an app restart so
--     a live share is never silently dropped. Also returns the caregiver's
--     phone number so the CALL CARETAKER button works.
-- ------------------------------------------------------------------------------
DROP FUNCTION IF EXISTS public.get_active_location_session(UUID);

CREATE OR REPLACE FUNCTION public.get_active_location_session(
    p_patient_id UUID,
    p_device_id TEXT
) RETURNS JSONB AS $$
DECLARE
    v_session RECORD;
    v_phone TEXT;
    v_name TEXT;
BEGIN
    IF NOT public.is_device_for_patient(p_patient_id, p_device_id) THEN
        RAISE EXCEPTION 'Access denied: device is not paired with this patient'
            USING ERRCODE = '42501';
    END IF;

    SELECT * INTO v_session
    FROM public.location_sessions
    WHERE patient_id = p_patient_id
      AND status = 'active'
      AND expires_at > TIMEZONE('utc', NOW())
    ORDER BY started_at DESC
    LIMIT 1;

    IF NOT FOUND THEN
        RETURN jsonb_build_object('active', FALSE);
    END IF;

    -- Caregiver contact details for the dialer (not exposed to any other party).
    SELECT p.phone, p.full_name INTO v_phone, v_name
    FROM public.profiles p
    WHERE p.id = v_session.caregiver_id;

    RETURN jsonb_build_object(
        'active', TRUE,
        'session_id', v_session.id,
        'caregiver_id', v_session.caregiver_id,
        'caregiver_name', v_name,
        'caregiver_phone', v_phone,
        'started_at', v_session.started_at,
        'expires_at', v_session.expires_at,
        'last_location_update', v_session.last_location_update
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

REVOKE ALL ON FUNCTION public.get_active_location_session(UUID, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_active_location_session(UUID, TEXT) TO anon, authenticated;

-- ------------------------------------------------------------------------------
-- 11. RPC: get_latest_location  (CAREGIVER — auth.uid() verified)
--     One call gives the caregiver everything the map header needs: the newest
--     point, its accuracy, when it was recorded, and the patient's phone number.
--     Returns UNAUTHORIZED for anyone who is not the assigned caregiver.
-- ------------------------------------------------------------------------------
DROP FUNCTION IF EXISTS public.get_latest_location(UUID);

CREATE OR REPLACE FUNCTION public.get_latest_location(
    p_session_id UUID
) RETURNS JSONB AS $$
DECLARE
    v_location RECORD;
    v_session RECORD;
    v_phone TEXT;
BEGIN
    SELECT * INTO v_session
    FROM public.location_sessions
    WHERE id = p_session_id;

    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', FALSE, 'error', 'SESSION_NOT_FOUND');
    END IF;

    -- Hard authorization gate: the caller must be the assigned caregiver.
    IF NOT public.is_caregiver_for_patient(v_session.patient_id) THEN
        RETURN jsonb_build_object('success', FALSE, 'error', 'UNAUTHORIZED');
    END IF;

    SELECT p.emergency_contact_phone INTO v_phone
    FROM public.patients p
    WHERE p.id = v_session.patient_id;

    SELECT * INTO v_location
    FROM public.patient_locations
    WHERE session_id = p_session_id
    ORDER BY recorded_at DESC
    LIMIT 1;

    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'success', TRUE, 'has_location', FALSE,
            'session_status', v_session.status,
            'expires_at', v_session.expires_at,
            'patient_phone', v_phone
        );
    END IF;

    RETURN jsonb_build_object(
        'success', TRUE, 'has_location', TRUE,
        'latitude', v_location.latitude,
        'longitude', v_location.longitude,
        'accuracy', v_location.accuracy,
        'altitude', v_location.altitude,
        'speed', v_location.speed,
        'heading', v_location.heading,
        'recorded_at', v_location.recorded_at,
        'session_status', v_session.status,
        'expires_at', v_session.expires_at,
        'patient_phone', v_phone
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

REVOKE ALL ON FUNCTION public.get_latest_location(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_latest_location(UUID) TO authenticated;

-- ------------------------------------------------------------------------------
-- 12. Housekeeping: keep the old cleanup helper, now scheduled-friendly.
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.cleanup_expired_location_sessions()
RETURNS JSONB AS $$
DECLARE
    v_count INT;
BEGIN
    UPDATE public.location_sessions
    SET status = 'expired',
        stopped_at = TIMEZONE('utc', NOW()),
        updated_at = TIMEZONE('utc', NOW())
    WHERE status = 'active'
      AND expires_at <= TIMEZONE('utc', NOW());

    GET DIAGNOSTICS v_count = ROW_COUNT;

    RETURN jsonb_build_object(
        'expired_count', v_count,
        'processed_at', TIMEZONE('utc', NOW())
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

REVOKE ALL ON FUNCTION public.cleanup_expired_location_sessions() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.cleanup_expired_location_sessions() TO authenticated;

-- ------------------------------------------------------------------------------
-- 13. Retention: prune location trails well after a session closes so the
--     historical breadcrumb trail is not kept indefinitely.
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.prune_old_patient_locations(
    p_retain_days INT DEFAULT 7
) RETURNS JSONB AS $$
DECLARE
    v_count INT;
BEGIN
    DELETE FROM public.patient_locations pl
    USING public.location_sessions ls
    WHERE pl.session_id = ls.id
      AND ls.status IN ('stopped', 'expired')
      AND COALESCE(ls.stopped_at, ls.expires_at) < TIMEZONE('utc', NOW()) - (GREATEST(p_retain_days, 1) || ' days')::INTERVAL;

    GET DIAGNOSTICS v_count = ROW_COUNT;

    RETURN jsonb_build_object('pruned_count', v_count);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

REVOKE ALL ON FUNCTION public.prune_old_patient_locations(INT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.prune_old_patient_locations(INT) TO authenticated;

-- ==============================================================================
-- END OF MIGRATION
-- ==============================================================================
