-- ==============================================================================
-- NIRVANA BACKEND SCHEMA & SECURITY EXPANSION (Phase 1: Device Pairing, Codes, Notifications)
-- Migration: 20260908000000_pairing_devices_and_notifications.sql
-- Description: Adds patient_devices, patient_pairing_codes, caregiver_notifications,
-- extends reminder_logs, implements server-side pairing RPCs, and enforces RLS.
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. Table: Patient Devices
-- Tracks authorized mobile/tablet devices paired with a patient record
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.patient_devices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,
    device_id TEXT NOT NULL UNIQUE,
    device_name TEXT,
    is_active BOOLEAN NOT NULL DEFAULT true,
    last_seen_at TIMESTAMPTZ DEFAULT TIMEZONE('utc', NOW()),
    paired_at TIMESTAMPTZ DEFAULT TIMEZONE('utc', NOW()) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc', NOW()) NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT TIMEZONE('utc', NOW()) NOT NULL
);

CREATE TRIGGER set_patient_devices_updated_at
    BEFORE UPDATE ON public.patient_devices
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

CREATE INDEX IF NOT EXISTS idx_patient_devices_patient ON public.patient_devices(patient_id);
CREATE INDEX IF NOT EXISTS idx_patient_devices_device ON public.patient_devices(device_id);

-- ------------------------------------------------------------------------------
-- 2. Table: Patient Pairing Codes
-- Generates short-lived, single-use 6-digit codes for pairing offline elder devices
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.patient_pairing_codes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,
    code TEXT NOT NULL UNIQUE,
    expires_at TIMESTAMPTZ NOT NULL,
    used_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc', NOW()) NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_pairing_codes_lookup ON public.patient_pairing_codes(code, expires_at) WHERE used_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_pairing_codes_patient ON public.patient_pairing_codes(patient_id);

-- ------------------------------------------------------------------------------
-- 3. Table: Caregiver Notifications
-- Real-time alert feed notifying caregivers about medication adherence, game completions, device changes
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.caregiver_notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    caregiver_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    patient_id UUID NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,
    notification_type TEXT NOT NULL CHECK (
        notification_type IN (
            'reminder_completed',
            'reminder_missed',
            'reminder_snoozed',
            'game_completed',
            'device_paired',
            'device_revoked',
            'sync_restored',
            'sync_error'
        )
    ),
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    related_reminder_id UUID REFERENCES public.reminders(id) ON DELETE SET NULL,
    related_game_session_id UUID REFERENCES public.game_sessions(id) ON DELETE SET NULL,
    is_read BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc', NOW()) NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_caregiver_notifications_caregiver ON public.caregiver_notifications(caregiver_id, is_read, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_caregiver_notifications_patient ON public.caregiver_notifications(patient_id, created_at DESC);

-- ------------------------------------------------------------------------------
-- 4. Extend Table: Reminder Logs
-- Support 'pending', 'acknowledged', 'missed', 'snoozed' + snoozed_until timestamp
-- ------------------------------------------------------------------------------
ALTER TABLE public.reminder_logs 
    ADD COLUMN IF NOT EXISTS snoozed_until TIMESTAMPTZ;

-- Safely update status constraint on reminder_logs
ALTER TABLE public.reminder_logs 
    DROP CONSTRAINT IF EXISTS reminder_logs_status_check;

ALTER TABLE public.reminder_logs 
    ADD CONSTRAINT reminder_logs_status_check 
    CHECK (status IN ('pending', 'acknowledged', 'missed', 'snoozed'));

-- ------------------------------------------------------------------------------
-- 5. Enable Row Level Security (RLS) on New Tables
-- ------------------------------------------------------------------------------
ALTER TABLE public.patient_devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.patient_pairing_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.caregiver_notifications ENABLE ROW LEVEL SECURITY;

-- ------------------------------------------------------------------------------
-- 6. Row Level Security Policies
-- ------------------------------------------------------------------------------

-- (a) Patient Devices Policies
CREATE POLICY "patient_devices_select_caregiver"
    ON public.patient_devices FOR SELECT
    TO authenticated
    USING (public.is_caregiver_for_patient(patient_id));

CREATE POLICY "patient_devices_insert_caregiver"
    ON public.patient_devices FOR INSERT
    TO authenticated
    WITH CHECK (public.is_caregiver_for_patient(patient_id));

CREATE POLICY "patient_devices_update_caregiver"
    ON public.patient_devices FOR UPDATE
    TO authenticated
    USING (public.is_caregiver_for_patient(patient_id))
    WITH CHECK (public.is_caregiver_for_patient(patient_id));

CREATE POLICY "patient_devices_delete_caregiver"
    ON public.patient_devices FOR DELETE
    TO authenticated
    USING (public.is_caregiver_for_patient(patient_id));

-- (b) Patient Pairing Codes Policies
CREATE POLICY "pairing_codes_select_caregiver"
    ON public.patient_pairing_codes FOR SELECT
    TO authenticated
    USING (public.is_caregiver_for_patient(patient_id));

CREATE POLICY "pairing_codes_insert_caregiver"
    ON public.patient_pairing_codes FOR INSERT
    TO authenticated
    WITH CHECK (public.is_caregiver_for_patient(patient_id));

CREATE POLICY "pairing_codes_update_caregiver"
    ON public.patient_pairing_codes FOR UPDATE
    TO authenticated
    USING (public.is_caregiver_for_patient(patient_id))
    WITH CHECK (public.is_caregiver_for_patient(patient_id));

CREATE POLICY "pairing_codes_delete_caregiver"
    ON public.patient_pairing_codes FOR DELETE
    TO authenticated
    USING (public.is_caregiver_for_patient(patient_id));

-- (c) Caregiver Notifications Policies
CREATE POLICY "caregiver_notifications_select_own"
    ON public.caregiver_notifications FOR SELECT
    TO authenticated
    USING (caregiver_id = auth.uid());

CREATE POLICY "caregiver_notifications_insert_authorized"
    ON public.caregiver_notifications FOR INSERT
    TO authenticated
    WITH CHECK (caregiver_id = auth.uid() OR public.is_caregiver_for_patient(patient_id));

CREATE POLICY "caregiver_notifications_update_own"
    ON public.caregiver_notifications FOR UPDATE
    TO authenticated
    USING (caregiver_id = auth.uid())
    WITH CHECK (caregiver_id = auth.uid());

CREATE POLICY "caregiver_notifications_delete_own"
    ON public.caregiver_notifications FOR DELETE
    TO authenticated
    USING (caregiver_id = auth.uid());

-- ------------------------------------------------------------------------------
-- 7. Server-Side Secure Pairing Functions
-- ------------------------------------------------------------------------------

-- (a) Generate a 6-digit one-time pairing code for a patient
CREATE OR REPLACE FUNCTION public.generate_patient_pairing_code(
    p_patient_id UUID,
    p_validity_minutes INT DEFAULT 15
) RETURNS TEXT AS $$
DECLARE
    v_code TEXT;
    v_is_authorized BOOLEAN;
BEGIN
    -- Authorization check
    v_is_authorized := public.is_caregiver_for_patient(p_patient_id);
    IF NOT v_is_authorized THEN
        RAISE EXCEPTION 'Access denied: caller is not an authorized caregiver for patient %', p_patient_id;
    END IF;

    -- Expire any previous unexpired codes for this patient
    UPDATE public.patient_pairing_codes
    SET used_at = TIMEZONE('utc', NOW())
    WHERE patient_id = p_patient_id AND used_at IS NULL AND expires_at > TIMEZONE('utc', NOW());

    -- Generate a random 6-digit numeric string
    v_code := lpad(floor(random() * 900000 + 100000)::text, 6, '0');

    -- Insert new pairing code
    INSERT INTO public.patient_pairing_codes (
        patient_id,
        code,
        expires_at,
        created_at
    ) VALUES (
        p_patient_id,
        v_code,
        TIMEZONE('utc', NOW()) + (p_validity_minutes || ' minutes')::INTERVAL,
        TIMEZONE('utc', NOW())
    );

    RETURN v_code;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- (b) Validate pairing code and pair device server-side
CREATE OR REPLACE FUNCTION public.validate_and_pair_device(
    p_code TEXT,
    p_device_id TEXT,
    p_device_name TEXT DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
    v_record RECORD;
    v_patient RECORD;
    v_caregiver RECORD;
BEGIN
    -- 1. Find valid pairing code
    SELECT * INTO v_record
    FROM public.patient_pairing_codes
    WHERE code = trim(p_code)
      AND used_at IS NULL
      AND expires_at > TIMEZONE('utc', NOW());

    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'INVALID_OR_EXPIRED_CODE',
            'message', 'The pairing code is invalid or has expired. Please ask your caregiver for a new code.'
        );
    END IF;

    -- 2. Mark code as used immediately
    UPDATE public.patient_pairing_codes
    SET used_at = TIMEZONE('utc', NOW())
    WHERE id = v_record.id;

    -- 3. Register or update the patient device
    INSERT INTO public.patient_devices (
        patient_id,
        device_id,
        device_name,
        is_active,
        last_seen_at,
        paired_at,
        created_at,
        updated_at
    ) VALUES (
        v_record.patient_id,
        p_device_id,
        COALESCE(p_device_name, 'Elder Mobile Device'),
        true,
        TIMEZONE('utc', NOW()),
        TIMEZONE('utc', NOW()),
        TIMEZONE('utc', NOW()),
        TIMEZONE('utc', NOW())
    )
    ON CONFLICT (device_id) DO UPDATE SET
        patient_id = EXCLUDED.patient_id,
        device_name = COALESCE(EXCLUDED.device_name, public.patient_devices.device_name),
        is_active = true,
        last_seen_at = TIMEZONE('utc', NOW()),
        updated_at = TIMEZONE('utc', NOW());

    -- 4. Fetch patient info
    SELECT * INTO v_patient FROM public.patients WHERE id = v_record.patient_id;

    -- 5. Send notification to all linked caregivers
    FOR v_caregiver IN
        SELECT caregiver_id FROM public.caregiver_patient_links WHERE patient_id = v_record.patient_id
        UNION
        SELECT primary_caregiver_id AS caregiver_id FROM public.patients WHERE id = v_record.patient_id AND primary_caregiver_id IS NOT NULL
    LOOP
        INSERT INTO public.caregiver_notifications (
            caregiver_id,
            patient_id,
            notification_type,
            title,
            message,
            created_at
        ) VALUES (
            v_caregiver.caregiver_id,
            v_record.patient_id,
            'device_paired',
            'New Device Paired',
            'A device (' || COALESCE(p_device_name, 'Elder Device') || ') was successfully paired with ' || v_patient.display_name || '.',
            TIMEZONE('utc', NOW())
        );
    END LOOP;

    RETURN jsonb_build_object(
        'success', true,
        'patient_id', v_record.patient_id,
        'display_name', v_patient.display_name,
        'preferred_name', v_patient.preferred_name,
        'device_id', p_device_id
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ------------------------------------------------------------------------------
-- 8. Update process_sync_event to handle new fields and entities
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.process_sync_event(
    p_event_id UUID,
    p_patient_id UUID,
    p_entity_type TEXT,
    p_entity_id UUID,
    p_operation TEXT,
    p_payload JSONB,
    p_created_at TIMESTAMPTZ
) RETURNS JSONB AS $$
DECLARE
    v_is_authorized BOOLEAN;
BEGIN
    -- 1. Authorization check under RLS context
    v_is_authorized := public.is_caregiver_for_patient(p_patient_id);
    IF NOT v_is_authorized THEN
        RAISE EXCEPTION 'Access denied: caller is not an authorized caregiver for patient %', p_patient_id;
    END IF;

    -- 2. Idempotency verification: Check if event was previously processed
    IF EXISTS (SELECT 1 FROM public.sync_events WHERE event_id = p_event_id) THEN
        RETURN jsonb_build_object(
            'status', 'IGNORED_DUPLICATE',
            'event_id', p_event_id,
            'message', 'Event already processed'
        );
    END IF;

    -- 3. Execute entity mutation according to type and operation
    CASE p_entity_type
        WHEN 'game_session' THEN
            INSERT INTO public.game_sessions (
                id, patient_id, game_type, difficulty_level, 
                total_trials, successful_trials, duration_seconds, 
                activity_metadata, started_at, completed_at, created_at
            ) VALUES (
                p_entity_id,
                p_patient_id,
                p_payload->>'game_type',
                COALESCE((p_payload->>'difficulty_level')::INT, 1),
                COALESCE((p_payload->>'total_trials')::INT, 0),
                COALESCE((p_payload->>'successful_trials')::INT, 0),
                COALESCE((p_payload->>'duration_seconds')::INT, 0),
                COALESCE(p_payload->'activity_metadata', '{}'::jsonb),
                (p_payload->>'started_at')::TIMESTAMPTZ,
                (p_payload->>'completed_at')::TIMESTAMPTZ,
                p_created_at
            )
            ON CONFLICT (id) DO NOTHING;

        WHEN 'reminder' THEN
            IF p_operation = 'DELETE' THEN
                UPDATE public.reminders 
                SET is_deleted = true, updated_at = TIMEZONE('utc', NOW())
                WHERE id = p_entity_id AND patient_id = p_patient_id;
            ELSE
                INSERT INTO public.reminders (
                    id, patient_id, title, description, reminder_type, 
                    schedule_time, recurrence_days, is_active, 
                    audio_prompt_url, is_deleted, created_at, updated_at
                ) VALUES (
                    p_entity_id,
                    p_patient_id,
                    p_payload->>'title',
                    p_payload->>'description',
                    p_payload->>'reminder_type',
                    (p_payload->>'schedule_time')::TIME,
                    ARRAY(SELECT jsonb_array_elements_text(COALESCE(p_payload->'recurrence_days', '["mon","tue","wed","thu","fri","sat","sun"]'::jsonb))),
                    COALESCE((p_payload->>'is_active')::BOOLEAN, true),
                    p_payload->>'audio_prompt_url',
                    COALESCE((p_payload->>'is_deleted')::BOOLEAN, false),
                    p_created_at,
                    TIMEZONE('utc', NOW())
                )
                ON CONFLICT (id) DO UPDATE SET
                    title = EXCLUDED.title,
                    description = EXCLUDED.description,
                    reminder_type = EXCLUDED.reminder_type,
                    schedule_time = EXCLUDED.schedule_time,
                    recurrence_days = EXCLUDED.recurrence_days,
                    is_active = EXCLUDED.is_active,
                    audio_prompt_url = EXCLUDED.audio_prompt_url,
                    is_deleted = EXCLUDED.is_deleted,
                    updated_at = TIMEZONE('utc', NOW());
            END IF;

        WHEN 'reminder_log' THEN
            INSERT INTO public.reminder_logs (
                id, reminder_id, patient_id, scheduled_for, acknowledged_at, snoozed_until, status, created_at
            ) VALUES (
                p_entity_id,
                (p_payload->>'reminder_id')::UUID,
                p_patient_id,
                (p_payload->>'scheduled_for')::TIMESTAMPTZ,
                (p_payload->>'acknowledged_at')::TIMESTAMPTZ,
                (p_payload->>'snoozed_until')::TIMESTAMPTZ,
                COALESCE(p_payload->>'status', 'acknowledged'),
                p_created_at
            )
            ON CONFLICT (id) DO UPDATE SET
                acknowledged_at = EXCLUDED.acknowledged_at,
                snoozed_until = EXCLUDED.snoozed_until,
                status = EXCLUDED.status;

        WHEN 'family_photo' THEN
            IF p_operation = 'DELETE' THEN
                UPDATE public.family_photos 
                SET is_deleted = true, updated_at = TIMEZONE('utc', NOW())
                WHERE id = p_entity_id AND patient_id = p_patient_id;
            ELSE
                INSERT INTO public.family_photos (
                    id, patient_id, title, relationship, photo_url, 
                    audio_note_url, display_order, is_active, 
                    is_deleted, created_at, updated_at
                ) VALUES (
                    p_entity_id,
                    p_patient_id,
                    p_payload->>'title',
                    p_payload->>'relationship',
                    p_payload->>'photo_url',
                    p_payload->>'audio_note_url',
                    COALESCE((p_payload->>'display_order')::INT, 0),
                    COALESCE((p_payload->>'is_active')::BOOLEAN, true),
                    COALESCE((p_payload->>'is_deleted')::BOOLEAN, false),
                    p_created_at,
                    TIMEZONE('utc', NOW())
                )
                ON CONFLICT (id) DO UPDATE SET
                    title = EXCLUDED.title,
                    relationship = EXCLUDED.relationship,
                    photo_url = EXCLUDED.photo_url,
                    audio_note_url = EXCLUDED.audio_note_url,
                    display_order = EXCLUDED.display_order,
                    is_active = EXCLUDED.is_active,
                    is_deleted = EXCLUDED.is_deleted,
                    updated_at = TIMEZONE('utc', NOW());
            END IF;

        WHEN 'patient_device' THEN
            INSERT INTO public.patient_devices (
                id, patient_id, device_id, device_name, is_active, last_seen_at, paired_at, created_at, updated_at
            ) VALUES (
                p_entity_id,
                p_patient_id,
                p_payload->>'device_id',
                p_payload->>'device_name',
                COALESCE((p_payload->>'is_active')::BOOLEAN, true),
                COALESCE((p_payload->>'last_seen_at')::TIMESTAMPTZ, TIMEZONE('utc', NOW())),
                COALESCE((p_payload->>'paired_at')::TIMESTAMPTZ, TIMEZONE('utc', NOW())),
                p_created_at,
                TIMEZONE('utc', NOW())
            )
            ON CONFLICT (device_id) DO UPDATE SET
                is_active = EXCLUDED.is_active,
                last_seen_at = EXCLUDED.last_seen_at,
                updated_at = TIMEZONE('utc', NOW());

        ELSE
            RAISE EXCEPTION 'Unsupported entity_type: %', p_entity_type;
    END CASE;

    -- 4. Record event into sync_events ledger
    INSERT INTO public.sync_events (
        event_id, patient_id, entity_type, entity_id, 
        operation, payload, sync_status, created_at, processed_at
    ) VALUES (
        p_event_id, p_patient_id, p_entity_type, p_entity_id, 
        p_operation, p_payload, 'PROCESSED', p_created_at, TIMEZONE('utc', NOW())
    );

    RETURN jsonb_build_object(
        'status', 'PROCESSED',
        'event_id', p_event_id,
        'entity_type', p_entity_type,
        'entity_id', p_entity_id
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;
