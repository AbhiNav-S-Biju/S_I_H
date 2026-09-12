-- ==============================================================================
-- NIRVANA LOCATION HELP FEATURE
-- Migration: 20260913000000_location_help_feature.sql
-- Description: Adds location_sessions and patient_locations tables for the
-- "I'm Lost / I Need Help" emergency location sharing feature.
-- Includes RLS policies, RPCs for session management, and realtime support.
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. Table: Location Sessions
-- Tracks active location-sharing sessions between patient and caregiver
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.location_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,
    caregiver_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'stopped', 'expired')),
    started_at TIMESTAMPTZ DEFAULT TIMEZONE('utc', NOW()) NOT NULL,
    stopped_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ NOT NULL,
    last_location_update TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc', NOW()) NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT TIMEZONE('utc', NOW()) NOT NULL
);

CREATE TRIGGER set_location_sessions_updated_at
    BEFORE UPDATE ON public.location_sessions
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

CREATE INDEX IF NOT EXISTS idx_location_sessions_patient ON public.location_sessions(patient_id);
CREATE INDEX IF NOT EXISTS idx_location_sessions_caregiver ON public.location_sessions(caregiver_id);
CREATE INDEX IF NOT EXISTS idx_location_sessions_status ON public.location_sessions(status) WHERE status = 'active';
CREATE INDEX IF NOT EXISTS idx_location_sessions_expires ON public.location_sessions(expires_at);

-- ------------------------------------------------------------------------------
-- 2. Table: Patient Locations
-- Stores individual location points during an active session
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.patient_locations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL REFERENCES public.location_sessions(id) ON DELETE CASCADE,
    patient_id UUID NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    accuracy DOUBLE PRECISION,
    altitude DOUBLE PRECISION,
    speed DOUBLE PRECISION,
    heading DOUBLE PRECISION,
    recorded_at TIMESTAMPTZ DEFAULT TIMEZONE('utc', NOW()) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc', NOW()) NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_patient_locations_session ON public.patient_locations(session_id, recorded_at DESC);
CREATE INDEX IF NOT EXISTS idx_patient_locations_patient ON public.patient_locations(patient_id, recorded_at DESC);

-- ------------------------------------------------------------------------------
-- 3. Enable Row Level Security
-- ------------------------------------------------------------------------------
ALTER TABLE public.location_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.patient_locations ENABLE ROW LEVEL SECURITY;

-- ------------------------------------------------------------------------------
-- 4. Row Level Security Policies for Location Sessions
-- ------------------------------------------------------------------------------

-- SELECT: Caregiver can view sessions for their patients; Patient can view their own active session
CREATE POLICY "location_sessions_select_authorized"
    ON public.location_sessions FOR SELECT
    TO authenticated
    USING (
        -- Caregiver access
        public.is_caregiver_for_patient(patient_id)
        OR
        -- Patient can see their own active session (for the "Stop Sharing" button)
        (patient_id IN (
            SELECT id FROM public.patients WHERE primary_caregiver_id IS NOT NULL
        ) AND auth.uid() = (
            SELECT primary_caregiver_id FROM public.patients WHERE id = location_sessions.patient_id
        ))
        OR
        -- Direct patient access via a patient-specific auth mechanism would need custom handling
        -- For now, we rely on caregiver access; patient app uses a different approach
        FALSE
    );

-- INSERT: Only system/caregiver can create sessions (via RPC)
CREATE POLICY "location_sessions_insert_caregiver"
    ON public.location_sessions FOR INSERT
    TO authenticated
    WITH CHECK (public.is_caregiver_for_patient(patient_id));

-- UPDATE: Caregiver can stop session; System updates last_location_update
CREATE POLICY "location_sessions_update_authorized"
    ON public.location_sessions FOR UPDATE
    TO authenticated
    USING (public.is_caregiver_for_patient(patient_id))
    WITH CHECK (public.is_caregiver_for_patient(patient_id));

-- DELETE: Only primary caregiver can delete
CREATE POLICY "location_sessions_delete_primary"
    ON public.location_sessions FOR DELETE
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.patients
            WHERE id = location_sessions.patient_id
            AND primary_caregiver_id = auth.uid()
        )
    );

-- ------------------------------------------------------------------------------
-- 5. Row Level Security Policies for Patient Locations
-- ------------------------------------------------------------------------------

-- SELECT: Caregiver can view locations for their patients' active sessions
CREATE POLICY "patient_locations_select_caregiver"
    ON public.patient_locations FOR SELECT
    TO authenticated
    USING (
        public.is_caregiver_for_patient(patient_id)
        AND EXISTS (
            SELECT 1 FROM public.location_sessions ls
            WHERE ls.id = patient_locations.session_id
            AND ls.status = 'active'
        )
    );

-- INSERT: System inserts via RPC during active session
CREATE POLICY "patient_locations_insert_session"
    ON public.patient_locations FOR INSERT
    TO authenticated
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.location_sessions ls
            WHERE ls.id = patient_locations.session_id
            AND ls.status = 'active'
            AND public.is_caregiver_for_patient(ls.patient_id)
        )
    );

-- No UPDATE/DELETE policies - locations are append-only during session

-- ------------------------------------------------------------------------------
-- 6. Supabase Realtime Publication
-- ------------------------------------------------------------------------------
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime') THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.location_sessions;
        ALTER PUBLICATION supabase_realtime ADD TABLE public.patient_locations;
    END IF;
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

-- ------------------------------------------------------------------------------
-- 7. RPC: Start Location Help Session
-- Called by patient app when "I'm Lost" is confirmed
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.start_location_help_session(
    p_patient_id UUID
) RETURNS JSONB AS $$
DECLARE
    v_caregiver_id UUID;
    v_session_id UUID;
    v_expires_at TIMESTAMPTZ;
BEGIN
    -- 1. Verify patient exists and get primary caregiver
    SELECT primary_caregiver_id INTO v_caregiver_id
    FROM public.patients
    WHERE id = p_patient_id;

    IF v_caregiver_id IS NULL THEN
        RAISE EXCEPTION 'Patient not found or has no primary caregiver';
    END IF;

    -- 2. Check if there's already an active session for this patient
    IF EXISTS (
        SELECT 1 FROM public.location_sessions
        WHERE patient_id = p_patient_id
        AND status = 'active'
        AND expires_at > TIMEZONE('utc', NOW())
    ) THEN
        RAISE EXCEPTION 'An active location help session already exists for this patient';
    END IF;

    -- 3. Set expiration to 30 minutes from now
    v_expires_at := TIMEZONE('utc', NOW()) + INTERVAL '30 minutes';

    -- 4. Create the session
    INSERT INTO public.location_sessions (
        patient_id,
        caregiver_id,
        status,
        started_at,
        expires_at,
        last_location_update
    ) VALUES (
        p_patient_id,
        v_caregiver_id,
        'active',
        TIMEZONE('utc', NOW()),
        v_expires_at,
        TIMEZONE('utc', NOW())
    ) RETURNING id INTO v_session_id;

    -- 5. Notify caregiver via notification table
    INSERT INTO public.caregiver_notifications (
        caregiver_id,
        patient_id,
        notification_type,
        title,
        message,
        created_at
    ) VALUES (
        v_caregiver_id,
        p_patient_id,
        'device_paired', -- Reusing existing type; could add 'location_help_requested'
        'Patient Needs Help',
        'Your patient has requested location assistance. Tap to view their live location.',
        TIMEZONE('utc', NOW())
    );

    RETURN jsonb_build_object(
        'success', true,
        'session_id', v_session_id,
        'caregiver_id', v_caregiver_id,
        'expires_at', v_expires_at
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ------------------------------------------------------------------------------
-- 8. RPC: Update Patient Location
-- Called periodically by patient app during active session
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.update_patient_location(
    p_session_id UUID,
    p_latitude DOUBLE PRECISION,
    p_longitude DOUBLE PRECISION,
    p_accuracy DOUBLE PRECISION DEFAULT NULL,
    p_altitude DOUBLE PRECISION DEFAULT NULL,
    p_speed DOUBLE PRECISION DEFAULT NULL,
    p_heading DOUBLE PRECISION DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
    v_session RECORD;
    v_location_id UUID;
BEGIN
    -- 1. Verify session exists and is active
    SELECT * INTO v_session
    FROM public.location_sessions
    WHERE id = p_session_id
    AND status = 'active'
    AND expires_at > TIMEZONE('utc', NOW());

    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'SESSION_NOT_ACTIVE',
            'message', 'No active location session found or session has expired'
        );
    END IF;

    -- 2. Insert location point
    INSERT INTO public.patient_locations (
        session_id,
        patient_id,
        latitude,
        longitude,
        accuracy,
        altitude,
        speed,
        heading,
        recorded_at
    ) VALUES (
        p_session_id,
        v_session.patient_id,
        p_latitude,
        p_longitude,
        p_accuracy,
        p_altitude,
        p_speed,
        p_heading,
        TIMEZONE('utc', NOW())
    ) RETURNING id INTO v_location_id;

    -- 3. Update session's last_location_update timestamp
    UPDATE public.location_sessions
    SET last_location_update = TIMEZONE('utc', NOW()),
        updated_at = TIMEZONE('utc', NOW())
    WHERE id = p_session_id;

    RETURN jsonb_build_object(
        'success', true,
        'location_id', v_location_id,
        'recorded_at', TIMEZONE('utc', NOW())
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ------------------------------------------------------------------------------
-- 9. RPC: Stop Location Help Session
-- Called by patient (Stop Sharing) or caregiver (Stop Sharing)
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.stop_location_help_session(
    p_session_id UUID,
    p_stopped_by TEXT DEFAULT 'patient' -- 'patient' or 'caregiver'
) RETURNS JSONB AS $$
DECLARE
    v_session RECORD;
BEGIN
    -- 1. Get session
    SELECT * INTO v_session
    FROM public.location_sessions
    WHERE id = p_session_id
    AND status = 'active';

    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'SESSION_NOT_FOUND',
            'message', 'Active session not found'
        );
    END IF;

    -- 2. Update session status
    UPDATE public.location_sessions
    SET status = 'stopped',
        stopped_at = TIMEZONE('utc', NOW()),
        updated_at = TIMEZONE('utc', NOW())
    WHERE id = p_session_id;

    -- 3. Notify the other party
    IF p_stopped_by = 'patient' THEN
        INSERT INTO public.caregiver_notifications (
            caregiver_id,
            patient_id,
            notification_type,
            title,
            message,
            created_at
        ) VALUES (
            v_session.caregiver_id,
            v_session.patient_id,
            'device_revoked', -- Reusing; could add 'location_help_stopped'
            'Location Sharing Stopped',
            'The patient has stopped sharing their location.',
            TIMEZONE('utc', NOW())
        );
    ELSE
        -- Caregiver stopped - could notify patient if they have a notification system
        -- For now, just log
        NULL;
    END IF;

    RETURN jsonb_build_object(
        'success', true,
        'stopped_at', TIMEZONE('utc', NOW())
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ------------------------------------------------------------------------------
-- 10. RPC: Get Active Location Session for Patient
-- Called by patient app to check if session is active
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_active_location_session(
    p_patient_id UUID
) RETURNS JSONB AS $$
DECLARE
    v_session RECORD;
BEGIN
    SELECT * INTO v_session
    FROM public.location_sessions
    WHERE patient_id = p_patient_id
    AND status = 'active'
    AND expires_at > TIMEZONE('utc', NOW())
    ORDER BY started_at DESC
    LIMIT 1;

    IF NOT FOUND THEN
        RETURN jsonb_build_object('active', false);
    END IF;

    RETURN jsonb_build_object(
        'active', true,
        'session_id', v_session.id,
        'caregiver_id', v_session.caregiver_id,
        'started_at', v_session.started_at,
        'expires_at', v_session.expires_at,
        'last_location_update', v_session.last_location_update
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ------------------------------------------------------------------------------
-- 11. RPC: Get Latest Location for Session
-- Called by caregiver app to get initial location
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_latest_location(
    p_session_id UUID
) RETURNS JSONB AS $$
DECLARE
    v_location RECORD;
    v_session RECORD;
BEGIN
    -- Verify session exists and caller is authorized
    SELECT * INTO v_session
    FROM public.location_sessions
    WHERE id = p_session_id;

    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'SESSION_NOT_FOUND');
    END IF;

    IF NOT public.is_caregiver_for_patient(v_session.patient_id) THEN
        RETURN jsonb_build_object('success', false, 'error', 'UNAUTHORIZED');
    END IF;

    -- Get latest location
    SELECT * INTO v_location
    FROM public.patient_locations
    WHERE session_id = p_session_id
    ORDER BY recorded_at DESC
    LIMIT 1;

    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'success', true,
            'has_location', false,
            'session_status', v_session.status,
            'expires_at', v_session.expires_at
        );
    END IF;

    RETURN jsonb_build_object(
        'success', true,
        'has_location', true,
        'latitude', v_location.latitude,
        'longitude', v_location.longitude,
        'accuracy', v_location.accuracy,
        'altitude', v_location.altitude,
        'speed', v_location.speed,
        'heading', v_location.heading,
        'recorded_at', v_location.recorded_at,
        'session_status', v_session.status,
        'expires_at', v_session.expires_at
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ------------------------------------------------------------------------------
-- 12. Function: Cleanup Expired Sessions
-- Can be run via pg_cron or scheduled job
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