-- ==============================================================================
-- NIRVANA BACKEND SECURITY & IDEMPOTENCY MIGRATION (Phase 2: RLS & Functions)
-- Migration: 20260907000001_rls_and_idempotency.sql
-- Description: Strict Row Level Security policies, access checks & idempotent sync engine
-- ==============================================================================

-- 1. Enable Row Level Security on ALL public tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.patients ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.caregiver_patient_links ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.game_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reminders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reminder_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.family_photos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sync_events ENABLE ROW LEVEL SECURITY;

-- ------------------------------------------------------------------------------
-- 2. Security & Relationship Helper Functions
-- ------------------------------------------------------------------------------

-- Check if authenticated caller is authorized for a specific patient
CREATE OR REPLACE FUNCTION public.is_caregiver_for_patient(patient_uuid UUID)
RETURNS BOOLEAN AS $$
BEGIN
    -- Reject unauthenticated or anonymous calls immediately
    IF auth.uid() IS NULL THEN
        RETURN FALSE;
    END IF;

    RETURN EXISTS (
        SELECT 1 FROM public.caregiver_patient_links
        WHERE caregiver_id = auth.uid()
        AND patient_id = patient_uuid
    ) OR EXISTS (
        SELECT 1 FROM public.patients
        WHERE id = patient_uuid
        AND primary_caregiver_id = auth.uid()
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Return all patient IDs accessible to the current authenticated caregiver
CREATE OR REPLACE FUNCTION public.get_accessible_patient_ids()
RETURNS TABLE (patient_id UUID) AS $$
BEGIN
    IF auth.uid() IS NULL THEN
        RETURN;
    END IF;

    RETURN QUERY
        SELECT cpl.patient_id
        FROM public.caregiver_patient_links cpl
        WHERE cpl.caregiver_id = auth.uid()
        UNION
        SELECT p.id AS patient_id
        FROM public.patients p
        WHERE p.primary_caregiver_id = auth.uid();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ------------------------------------------------------------------------------
-- 3. Row Level Security Policies
-- ------------------------------------------------------------------------------

-- (a) Profiles Policies
CREATE POLICY "profiles_select_own"
    ON public.profiles FOR SELECT
    TO authenticated
    USING (auth.uid() = id);

CREATE POLICY "profiles_insert_own"
    ON public.profiles FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = id);

CREATE POLICY "profiles_update_own"
    ON public.profiles FOR UPDATE
    TO authenticated
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- (b) Patients Policies
CREATE POLICY "patients_select_linked"
    ON public.patients FOR SELECT
    TO authenticated
    USING (public.is_caregiver_for_patient(id));

CREATE POLICY "patients_insert_primary"
    ON public.patients FOR INSERT
    TO authenticated
    WITH CHECK (primary_caregiver_id = auth.uid());

CREATE POLICY "patients_update_linked"
    ON public.patients FOR UPDATE
    TO authenticated
    USING (public.is_caregiver_for_patient(id))
    WITH CHECK (public.is_caregiver_for_patient(id));

-- (c) Caregiver-Patient Links Policies
CREATE POLICY "links_select_own"
    ON public.caregiver_patient_links FOR SELECT
    TO authenticated
    USING (caregiver_id = auth.uid() OR public.is_caregiver_for_patient(patient_id));

CREATE POLICY "links_insert_primary"
    ON public.caregiver_patient_links FOR INSERT
    TO authenticated
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.patients
            WHERE id = patient_id AND primary_caregiver_id = auth.uid()
        )
    );

CREATE POLICY "links_delete_primary"
    ON public.caregiver_patient_links FOR DELETE
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.patients
            WHERE id = patient_id AND primary_caregiver_id = auth.uid()
        )
    );

-- (d) Game Sessions Policies
CREATE POLICY "game_sessions_select_linked"
    ON public.game_sessions FOR SELECT
    TO authenticated
    USING (public.is_caregiver_for_patient(patient_id));

CREATE POLICY "game_sessions_insert_linked"
    ON public.game_sessions FOR INSERT
    TO authenticated
    WITH CHECK (public.is_caregiver_for_patient(patient_id));

-- (e) Reminders Policies
CREATE POLICY "reminders_select_linked"
    ON public.reminders FOR SELECT
    TO authenticated
    USING (public.is_caregiver_for_patient(patient_id));

CREATE POLICY "reminders_insert_linked"
    ON public.reminders FOR INSERT
    TO authenticated
    WITH CHECK (public.is_caregiver_for_patient(patient_id));

CREATE POLICY "reminders_update_linked"
    ON public.reminders FOR UPDATE
    TO authenticated
    USING (public.is_caregiver_for_patient(patient_id))
    WITH CHECK (public.is_caregiver_for_patient(patient_id));

-- (f) Reminder Logs Policies
CREATE POLICY "reminder_logs_select_linked"
    ON public.reminder_logs FOR SELECT
    TO authenticated
    USING (public.is_caregiver_for_patient(patient_id));

CREATE POLICY "reminder_logs_insert_linked"
    ON public.reminder_logs FOR INSERT
    TO authenticated
    WITH CHECK (public.is_caregiver_for_patient(patient_id));

-- (g) Family Photos Policies
CREATE POLICY "family_photos_select_linked"
    ON public.family_photos FOR SELECT
    TO authenticated
    USING (public.is_caregiver_for_patient(patient_id));

CREATE POLICY "family_photos_insert_linked"
    ON public.family_photos FOR INSERT
    TO authenticated
    WITH CHECK (public.is_caregiver_for_patient(patient_id));

CREATE POLICY "family_photos_update_linked"
    ON public.family_photos FOR UPDATE
    TO authenticated
    USING (public.is_caregiver_for_patient(patient_id))
    WITH CHECK (public.is_caregiver_for_patient(patient_id));

-- (h) Sync Events Policies
CREATE POLICY "sync_events_select_linked"
    ON public.sync_events FOR SELECT
    TO authenticated
    USING (public.is_caregiver_for_patient(patient_id));

CREATE POLICY "sync_events_insert_linked"
    ON public.sync_events FOR INSERT
    TO authenticated
    WITH CHECK (public.is_caregiver_for_patient(patient_id));

-- ------------------------------------------------------------------------------
-- 4. Idempotent Synchronization RPC Function
-- Used by Flutter SyncEngine to ingest mutations safely with zero duplicate writes
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
                id, reminder_id, patient_id, scheduled_for, acknowledged_at, status, created_at
            ) VALUES (
                p_entity_id,
                (p_payload->>'reminder_id')::UUID,
                p_patient_id,
                (p_payload->>'scheduled_for')::TIMESTAMPTZ,
                (p_payload->>'acknowledged_at')::TIMESTAMPTZ,
                p_payload->>'status',
                p_created_at
            )
            ON CONFLICT (id) DO NOTHING;

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

-- Batch version of idempotent synchronization for high-throughput reconnects
CREATE OR REPLACE FUNCTION public.process_sync_events_batch(
    p_events JSONB
) RETURNS JSONB AS $$
DECLARE
    v_event JSONB;
    v_results JSONB := '[]'::jsonb;
    v_res JSONB;
BEGIN
    FOR v_event IN SELECT * FROM jsonb_array_elements(p_events)
    LOOP
        BEGIN
            v_res := public.process_sync_event(
                (v_event->>'event_id')::UUID,
                (v_event->>'patient_id')::UUID,
                v_event->>'entity_type',
                (v_event->>'entity_id')::UUID,
                v_event->>'operation',
                v_event->'payload',
                (v_event->>'created_at')::TIMESTAMPTZ
            );
            v_results := v_results || jsonb_build_array(v_res);
        EXCEPTION WHEN OTHERS THEN
            v_results := v_results || jsonb_build_array(jsonb_build_object(
                'status', 'FAILED',
                'event_id', v_event->>'event_id',
                'error', SQLERRM
            ));
        END;
    END LOOP;

    RETURN jsonb_build_object('total', jsonb_array_length(p_events), 'results', v_results);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;
