-- ==============================================================================
-- NIRVANA BACKEND FIX: PATIENT ONBOARDING, CAREGIVER AUTHORIZATION & RLS
-- Migration: 20260909000000_fix_patient_onboarding_and_auth_rls.sql
-- Description: Fixes patient RLS insert checks, caregiver-patient link creation,
-- ensures auth.users -> profiles trigger, and provides atomic RPC for patient onboarding.
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. Automatic Profile Creation Trigger for auth.users
-- Ensures every authenticated user has a corresponding row in public.profiles
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, email, full_name, role)
    VALUES (
        NEW.id,
        COALESCE(NEW.email, ''),
        COALESCE(NEW.raw_user_meta_data->>'full_name', 'Caregiver'),
        COALESCE(NEW.raw_user_meta_data->>'role', 'caregiver')
    )
    ON CONFLICT (id) DO UPDATE SET
        email = EXCLUDED.email,
        full_name = CASE WHEN EXCLUDED.full_name <> 'Caregiver' THEN EXCLUDED.full_name ELSE public.profiles.full_name END,
        updated_at = TIMEZONE('utc', NOW());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- ------------------------------------------------------------------------------
-- 2. Authorization Helper Function
-- Securely checks if the current authenticated caller is an authorized caregiver
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.is_caregiver_for_patient(patient_uuid UUID)
RETURNS BOOLEAN AS $$
BEGIN
    IF auth.uid() IS NULL OR patient_uuid IS NULL THEN
        RETURN FALSE;
    END IF;

    RETURN EXISTS (
        SELECT 1 FROM public.patients
        WHERE id = patient_uuid
          AND primary_caregiver_id = auth.uid()
    ) OR EXISTS (
        SELECT 1 FROM public.caregiver_patient_links
        WHERE caregiver_id = auth.uid()
          AND patient_id = patient_uuid
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ------------------------------------------------------------------------------
-- 3. Row Level Security Policies for Patients Table
-- ------------------------------------------------------------------------------
ALTER TABLE public.patients ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "patients_select_linked" ON public.patients;
DROP POLICY IF EXISTS "patients_insert_primary" ON public.patients;
DROP POLICY IF EXISTS "patients_update_linked" ON public.patients;
DROP POLICY IF EXISTS "patients_delete_primary" ON public.patients;

-- SELECT: Caregiver can read patients they created or are linked to
CREATE POLICY "patients_select_linked"
    ON public.patients FOR SELECT
    TO authenticated
    USING (
        primary_caregiver_id = auth.uid()
        OR public.is_caregiver_for_patient(id)
    );

-- INSERT: Caregiver must be authenticated, set primary_caregiver_id = auth.uid(),
-- and have caregiver/admin role
CREATE POLICY "patients_insert_primary"
    ON public.patients FOR INSERT
    TO authenticated
    WITH CHECK (
        auth.uid() IS NOT NULL
        AND primary_caregiver_id = auth.uid()
        AND EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid()
              AND role IN ('caregiver', 'family_member', 'admin')
        )
    );

-- UPDATE: Caregiver can update patients they own or manage
CREATE POLICY "patients_update_linked"
    ON public.patients FOR UPDATE
    TO authenticated
    USING (
        primary_caregiver_id = auth.uid()
        OR public.is_caregiver_for_patient(id)
    )
    WITH CHECK (
        primary_caregiver_id = auth.uid()
        OR public.is_caregiver_for_patient(id)
    );

-- DELETE: Only primary caregiver can delete patient record
CREATE POLICY "patients_delete_primary"
    ON public.patients FOR DELETE
    TO authenticated
    USING (primary_caregiver_id = auth.uid());

-- ------------------------------------------------------------------------------
-- 4. Row Level Security Policies for Caregiver-Patient Links Table
-- ------------------------------------------------------------------------------
ALTER TABLE public.caregiver_patient_links ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "links_select_own" ON public.caregiver_patient_links;
DROP POLICY IF EXISTS "links_insert_primary" ON public.caregiver_patient_links;
DROP POLICY IF EXISTS "links_insert_authorized" ON public.caregiver_patient_links;
DROP POLICY IF EXISTS "links_update_authorized" ON public.caregiver_patient_links;
DROP POLICY IF EXISTS "links_delete_primary" ON public.caregiver_patient_links;
DROP POLICY IF EXISTS "links_delete_authorized" ON public.caregiver_patient_links;

-- SELECT: Caller can view their own links or links for patients they manage
CREATE POLICY "links_select_own"
    ON public.caregiver_patient_links FOR SELECT
    TO authenticated
    USING (
        caregiver_id = auth.uid()
        OR public.is_caregiver_for_patient(patient_id)
    );

-- INSERT: Caller can link themselves or link others if they are primary caregiver
CREATE POLICY "links_insert_authorized"
    ON public.caregiver_patient_links FOR INSERT
    TO authenticated
    WITH CHECK (
        caregiver_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM public.patients
            WHERE id = patient_id AND primary_caregiver_id = auth.uid()
        )
    );

-- UPDATE: Authorized caregiver can update link
CREATE POLICY "links_update_authorized"
    ON public.caregiver_patient_links FOR UPDATE
    TO authenticated
    USING (
        caregiver_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM public.patients
            WHERE id = patient_id AND primary_caregiver_id = auth.uid()
        )
    )
    WITH CHECK (
        caregiver_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM public.patients
            WHERE id = patient_id AND primary_caregiver_id = auth.uid()
        )
    );

-- DELETE: Primary caregiver or the caregiver themselves can remove link
CREATE POLICY "links_delete_authorized"
    ON public.caregiver_patient_links FOR DELETE
    TO authenticated
    USING (
        caregiver_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM public.patients
            WHERE id = patient_id AND primary_caregiver_id = auth.uid()
        )
    );

-- ------------------------------------------------------------------------------
-- 5. Row Level Security Policies for Patient Pairing Codes Table
-- ------------------------------------------------------------------------------
ALTER TABLE public.patient_pairing_codes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "pairing_codes_select_caregiver" ON public.patient_pairing_codes;
DROP POLICY IF EXISTS "pairing_codes_insert_caregiver" ON public.patient_pairing_codes;
DROP POLICY IF EXISTS "pairing_codes_update_caregiver" ON public.patient_pairing_codes;
DROP POLICY IF EXISTS "pairing_codes_delete_caregiver" ON public.patient_pairing_codes;

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

-- ------------------------------------------------------------------------------
-- 6. Atomic RPC: create_patient_with_caregiver
-- Performs patient insertion, caregiver-patient link creation, and initial reminders
-- in an atomic transaction verified by auth.uid().
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.create_patient_with_caregiver(
    p_display_name TEXT,
    p_preferred_name TEXT DEFAULT NULL,
    p_relationship_label TEXT DEFAULT 'Caregiver',
    p_date_of_birth DATE DEFAULT NULL,
    p_emergency_contact_phone TEXT DEFAULT NULL,
    p_accessibility_settings JSONB DEFAULT NULL,
    p_initial_reminders JSONB DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
    v_caregiver_id UUID;
    v_patient_id UUID;
    v_patient RECORD;
    v_reminder JSONB;
BEGIN
    -- 1. Securely identify authenticated caregiver
    v_caregiver_id := auth.uid();
    IF v_caregiver_id IS NULL THEN
        RAISE EXCEPTION 'Authentication required: caller is not authenticated' USING ERRCODE = '42501';
    END IF;

    -- 2. Ensure caregiver profile exists in public.profiles
    IF NOT EXISTS (SELECT 1 FROM public.profiles WHERE id = v_caregiver_id) THEN
        INSERT INTO public.profiles (id, email, full_name, role)
        VALUES (
            v_caregiver_id,
            COALESCE((SELECT email FROM auth.users WHERE id = v_caregiver_id), ''),
            'Caregiver',
            'caregiver'
        )
        ON CONFLICT (id) DO NOTHING;
    END IF;

    -- 3. Verify caregiver role permissions
    IF NOT EXISTS (
        SELECT 1 FROM public.profiles 
        WHERE id = v_caregiver_id 
          AND role IN ('caregiver', 'family_member', 'admin')
    ) THEN
        RAISE EXCEPTION 'Access denied: caller does not have caregiver permissions' USING ERRCODE = '42501';
    END IF;

    -- 4. Validate patient display name
    IF p_display_name IS NULL OR trim(p_display_name) = '' THEN
        RAISE EXCEPTION 'Patient name cannot be empty' USING ERRCODE = '22023';
    END IF;

    -- 5. Insert Patient Record
    INSERT INTO public.patients (
        primary_caregiver_id,
        display_name,
        preferred_name,
        date_of_birth,
        emergency_contact_phone,
        accessibility_settings,
        created_at,
        updated_at
    ) VALUES (
        v_caregiver_id,
        trim(p_display_name),
        COALESCE(NULLIF(trim(p_preferred_name), ''), trim(p_display_name)),
        p_date_of_birth,
        NULLIF(trim(p_emergency_contact_phone), ''),
        COALESCE(p_accessibility_settings, '{
            "large_text": true,
            "high_contrast": true,
            "audio_prompts": true,
            "haptic_feedback": true,
            "low_motion": true,
            "font_scale": 1.3
        }'::jsonb),
        TIMEZONE('utc', NOW()),
        TIMEZONE('utc', NOW())
    ) RETURNING * INTO v_patient;

    v_patient_id := v_patient.id;

    -- 6. Insert Caregiver-Patient Link atomically
    INSERT INTO public.caregiver_patient_links (
        caregiver_id,
        patient_id,
        relationship_label,
        access_role,
        created_at
    ) VALUES (
        v_caregiver_id,
        v_patient_id,
        COALESCE(NULLIF(trim(p_relationship_label), ''), 'Caregiver'),
        'primary',
        TIMEZONE('utc', NOW())
    )
    ON CONFLICT (caregiver_id, patient_id) DO UPDATE SET
        relationship_label = EXCLUDED.relationship_label,
        access_role = 'primary';

    -- 7. Insert Initial Reminders if provided
    IF p_initial_reminders IS NOT NULL AND jsonb_typeof(p_initial_reminders) = 'array' THEN
        FOR v_reminder IN SELECT * FROM jsonb_array_elements(p_initial_reminders)
        LOOP
            INSERT INTO public.reminders (
                patient_id,
                title,
                description,
                reminder_type,
                schedule_time,
                recurrence_days,
                is_active,
                audio_prompt_url,
                created_at,
                updated_at
            ) VALUES (
                v_patient_id,
                COALESCE(v_reminder->>'title', 'Daily Reminder'),
                v_reminder->>'description',
                COALESCE(v_reminder->>'reminder_type', 'general'),
                COALESCE((v_reminder->>'schedule_time')::TIME, '09:00:00'::TIME),
                ARRAY(SELECT jsonb_array_elements_text(COALESCE(v_reminder->'recurrence_days', '["mon","tue","wed","thu","fri","sat","sun"]'::jsonb))),
                COALESCE((v_reminder->>'is_active')::BOOLEAN, true),
                v_reminder->>'audio_prompt_url',
                TIMEZONE('utc', NOW()),
                TIMEZONE('utc', NOW())
            );
        END LOOP;
    END IF;

    -- 8. Return created patient structure
    RETURN jsonb_build_object(
        'id', v_patient.id,
        'primary_caregiver_id', v_patient.primary_caregiver_id,
        'display_name', v_patient.display_name,
        'preferred_name', v_patient.preferred_name,
        'date_of_birth', v_patient.date_of_birth,
        'emergency_contact_phone', v_patient.emergency_contact_phone,
        'relationship_label', COALESCE(NULLIF(trim(p_relationship_label), ''), 'Caregiver'),
        'accessibility_settings', v_patient.accessibility_settings,
        'created_at', v_patient.created_at,
        'updated_at', v_patient.updated_at
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ------------------------------------------------------------------------------
-- 7. Secure Pairing Code RPC: generate_patient_pairing_code
-- Generates a 6-digit one-time code for the authorized caregiver's patient
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.generate_patient_pairing_code(
    p_patient_id UUID,
    p_validity_minutes INT DEFAULT 15
) RETURNS TEXT AS $$
DECLARE
    v_code TEXT;
    v_is_authorized BOOLEAN;
    v_caller_id UUID;
BEGIN
    -- Validate caller authentication
    v_caller_id := auth.uid();
    IF v_caller_id IS NULL THEN
        RAISE EXCEPTION 'Authentication required: caller is not authenticated' USING ERRCODE = '42501';
    END IF;

    -- Validate caregiver authorization for this patient
    v_is_authorized := public.is_caregiver_for_patient(p_patient_id);
    IF NOT v_is_authorized THEN
        RAISE EXCEPTION 'Access denied: caller is not an authorized caregiver for patient %', p_patient_id USING ERRCODE = 'P0001';
    END IF;

    -- Expire any previous unexpired codes for this patient
    UPDATE public.patient_pairing_codes
    SET used_at = TIMEZONE('utc', NOW())
    WHERE patient_id = p_patient_id 
      AND used_at IS NULL 
      AND expires_at > TIMEZONE('utc', NOW());

    -- Generate a secure random 6-digit numeric string
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
        TIMEZONE('utc', NOW()) + (COALESCE(p_validity_minutes, 15) || ' minutes')::INTERVAL,
        TIMEZONE('utc', NOW())
    );

    RETURN v_code;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;
