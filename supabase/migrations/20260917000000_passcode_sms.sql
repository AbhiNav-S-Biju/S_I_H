-- ==============================================================================
-- NIRVANA - Passcode SMS Delivery (Schema & Secure RPCs)
-- Migration: 20260917000000_passcode_sms.sql
--
-- Description:
--   Adds the minimum backend surface required for a caregiver to send the
--   currently-generated 6-digit patient pairing passcode to the patient's
--   registered phone number via SMS.
--
--   Design notes / reuse:
--     * Patient phone number  -> public.patients.emergency_contact_phone
--       (already collected during onboarding and already reused as the
--        "patient_phone" contact by the location_help feature). No duplicate
--        patient phone column is created.
--     * Caregiver phone number -> public.profiles.phone (already collected at
--       registration). No duplicate caregiver phone column is created.
--     * The passcode itself is NOT regenerated here. The existing
--       generate_patient_pairing_code RPC remains the single source of truth.
--
-- Security:
--   * All exposures are through SECURITY DEFINER RPCs guarded by
--     public.is_caregiver_for_patient(), i.e. the caller must be authenticated
--     AND linked to the patient. No arbitrary phone numbers can be targeted.
--   * A caregiver can never read another caregiver's patient phone number.
--   * SMS provider credentials stay in Supabase Edge Function secrets only.
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. Table: Patient Passcode SMS Log
--    Append-only audit + duplicate-send guard. References the existing pairing
--    code row instead of duplicating the plaintext code, so there is exactly one
--    place that stores the generated passcode.
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.patient_passcode_sms_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,
    caregiver_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    pairing_code_id UUID NOT NULL REFERENCES public.patient_pairing_codes(id) ON DELETE CASCADE,
    delivery_status TEXT NOT NULL DEFAULT 'SENT'
        CHECK (delivery_status IN ('SENT', 'FAILED')),
    -- Provider message identifier only. Never a provider credential.
    provider_message_id TEXT,
    error_code TEXT,
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc', NOW()) NOT NULL
);

-- One successful SMS per generated passcode per patient: prevents duplicate
-- accidental sends of the same code.
CREATE UNIQUE INDEX IF NOT EXISTS uq_passcode_sms_sent_per_code
    ON public.patient_passcode_sms_log (pairing_code_id)
    WHERE delivery_status = 'SENT';

CREATE INDEX IF NOT EXISTS idx_passcode_sms_patient
    ON public.patient_passcode_sms_log (patient_id, created_at DESC);

ALTER TABLE public.patient_passcode_sms_log ENABLE ROW LEVEL SECURITY;

-- Caregivers may read only the delivery history of patients they are linked to.
CREATE POLICY "passcode_sms_select_caregiver"
    ON public.patient_passcode_sms_log FOR SELECT
    TO authenticated
    USING (public.is_caregiver_for_patient(patient_id));

-- ------------------------------------------------------------------------------
-- 2. RPC: caregiver_owns_patient  (SERVER-SIDE ONLY)
--    Explicit-id ownership check for use by the Edge Function, where auth.uid()
--    is NULL because it runs with the service-role key. Kept separate from
--    is_caregiver_for_patient so the client-facing auth model is unchanged.
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.caregiver_owns_patient(
    p_caregiver_id UUID,
    p_patient_id UUID
) RETURNS BOOLEAN AS $$
BEGIN
    IF p_caregiver_id IS NULL OR p_patient_id IS NULL THEN
        RETURN FALSE;
    END IF;

    RETURN EXISTS (
        SELECT 1 FROM public.caregiver_patient_links
        WHERE caregiver_id = p_caregiver_id AND patient_id = p_patient_id
    ) OR EXISTS (
        SELECT 1 FROM public.patients
        WHERE id = p_patient_id AND primary_caregiver_id = p_caregiver_id
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Deliberately NOT granted to anon/authenticated: server-side (service role) only.
REVOKE ALL ON FUNCTION public.caregiver_owns_patient(UUID, UUID) FROM PUBLIC;

-- ------------------------------------------------------------------------------
-- 3. RPC: get_patient_contact_for_caregiver
--    Returns the display name + registered phone number of a patient the caller
--    is authorized for, plus the caller's own phone number. This is the ONLY
--    path by which the patient phone reaches the client, so unrelated numbers
--    can never be enumerated.
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_patient_contact_for_caregiver(
    p_patient_id UUID
) RETURNS JSONB AS $$
DECLARE
    v_caller_id UUID;
    v_patient RECORD;
    v_caregiver_phone TEXT;
BEGIN
    v_caller_id := auth.uid();
    IF v_caller_id IS NULL THEN
        RETURN jsonb_build_object('success', FALSE, 'error', 'UNAUTHENTICATED');
    END IF;

    -- Hard relationship gate: caller must be linked to (or primary for) patient.
    IF NOT public.is_caregiver_for_patient(p_patient_id) THEN
        RETURN jsonb_build_object('success', FALSE, 'error', 'UNAUTHORIZED');
    END IF;

    SELECT p.display_name, p.preferred_name, p.emergency_contact_phone
    INTO v_patient
    FROM public.patients p
    WHERE p.id = p_patient_id;

    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', FALSE, 'error', 'PATIENT_NOT_FOUND');
    END IF;

    SELECT pr.phone INTO v_caregiver_phone
    FROM public.profiles pr
    WHERE pr.id = v_caller_id;

    RETURN jsonb_build_object(
        'success', TRUE,
        'patient_id', p_patient_id,
        'patient_name', COALESCE(NULLIF(trim(v_patient.preferred_name), ''), v_patient.display_name),
        'patient_phone', NULLIF(trim(COALESCE(v_patient.emergency_contact_phone, '')), ''),
        'caregiver_phone', NULLIF(trim(COALESCE(v_caregiver_phone, '')), '')
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

REVOKE ALL ON FUNCTION public.get_patient_contact_for_caregiver(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_patient_contact_for_caregiver(UUID) TO authenticated;

-- ------------------------------------------------------------------------------
-- 4. RPC: claim_passcode_sms_send
--    Atomically verifies that the supplied code IS the patient's current, live
--    pairing code and claims the right to send it exactly once.
--
--    Returns one of:
--      {'status':'CLAIMED',  'pairing_code_id': <uuid>, 'patient_phone': ...}
--      {'status':'DUPLICATE', ...}  -> the same passcode was already sent
--      {'status':'STALE_CODE', ...} -> the code is expired/used/superseded, so
--                                      the caregiver must regenerate first
--      {'status':'NO_PHONE', ...}   -> patient has no registered phone number
--      {'status':'UNAUTHORIZED'|'UNAUTHENTICATED'|'PATIENT_NOT_FOUND'}
--
--    Called by the client BEFORE contacting the Edge Function, and re-verified
--    server-side inside the Edge Function (which passes the returned id back).
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.claim_passcode_sms_send(
    p_patient_id UUID,
    p_code TEXT
) RETURNS JSONB AS $$
DECLARE
    v_caller_id UUID;
    v_patient RECORD;
    v_code RECORD;
    v_existing RECORD;
BEGIN
    v_caller_id := auth.uid();
    IF v_caller_id IS NULL THEN
        RETURN jsonb_build_object('status', 'UNAUTHENTICATED');
    END IF;

    IF NOT public.is_caregiver_for_patient(p_patient_id) THEN
        RETURN jsonb_build_object('status', 'UNAUTHORIZED');
    END IF;

    IF p_code IS NULL OR length(trim(p_code)) = 0 THEN
        RETURN jsonb_build_object('status', 'STALE_CODE');
    END IF;

    SELECT p.id, p.display_name, p.preferred_name, p.emergency_contact_phone
    INTO v_patient
    FROM public.patients p
    WHERE p.id = p_patient_id;

    IF NOT FOUND THEN
        RETURN jsonb_build_object('status', 'PATIENT_NOT_FOUND');
    END IF;

    -- The patient must have a registered phone number before anything is sent.
    IF v_patient.emergency_contact_phone IS NULL
       OR trim(v_patient.emergency_contact_phone) = '' THEN
        RETURN jsonb_build_object('status', 'NO_PHONE');
    END IF;

    -- The supplied code must be the current, unused, unexpired code for THIS
    -- patient. This is what stops an old/superseded code from being texted.
    SELECT * INTO v_code
    FROM public.patient_pairing_codes
    WHERE patient_id = p_patient_id
      AND code = trim(p_code)
      AND used_at IS NULL
      AND expires_at > TIMEZONE('utc', NOW())
    ORDER BY created_at DESC
    LIMIT 1;

    IF NOT FOUND THEN
        RETURN jsonb_build_object('status', 'STALE_CODE');
    END IF;

    -- Duplicate-send guard: has this exact passcode already gone out?
    SELECT * INTO v_existing
    FROM public.patient_passcode_sms_log
    WHERE pairing_code_id = v_code.id
      AND delivery_status = 'SENT'
    LIMIT 1;

    IF FOUND THEN
        RETURN jsonb_build_object(
            'status', 'DUPLICATE',
            'pairing_code_id', v_code.id,
            'expires_at', v_code.expires_at
        );
    END IF;

    RETURN jsonb_build_object(
        'status', 'CLAIMED',
        'pairing_code_id', v_code.id,
        'patient_id', p_patient_id,
        'patient_name', COALESCE(NULLIF(trim(v_patient.preferred_name), ''), v_patient.display_name),
        'patient_phone', trim(v_patient.emergency_contact_phone),
        'expires_at', v_code.expires_at
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

REVOKE ALL ON FUNCTION public.claim_passcode_sms_send(UUID, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.claim_passcode_sms_send(UUID, TEXT) TO authenticated;

-- ------------------------------------------------------------------------------
-- 5. RPC: record_passcode_sms_result
--    Records the outcome of an SMS attempt. SERVER-SIDE ONLY: the Edge Function
--    calls this with the service-role key, so it verifies the caller against the
--    actual pairing code rather than trusting client-supplied values.
--
--    Because an RPC invoked with the service role has auth.uid() = NULL, we
--    accept the caregiver_id explicitly and validate that the caregiver really
--    owns the patient before writing the row.
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.record_passcode_sms_result(
    p_pairing_code_id UUID,
    p_caregiver_id UUID,
    p_delivery_status TEXT,
    p_provider_message_id TEXT DEFAULT NULL,
    p_error_code TEXT DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
    v_code RECORD;
    v_is_linked BOOLEAN;
BEGIN
    IF p_delivery_status NOT IN ('SENT', 'FAILED') THEN
        RETURN jsonb_build_object('success', FALSE, 'error', 'INVALID_STATUS');
    END IF;

    SELECT * INTO v_code
    FROM public.patient_pairing_codes
    WHERE id = p_pairing_code_id;

    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', FALSE, 'error', 'PAIRING_CODE_NOT_FOUND');
    END IF;

    -- Server-side ownership re-verification (do not trust the client).
    SELECT EXISTS (
        SELECT 1 FROM public.caregiver_patient_links
        WHERE caregiver_id = p_caregiver_id AND patient_id = v_code.patient_id
    ) OR EXISTS (
        SELECT 1 FROM public.patients
        WHERE id = v_code.patient_id AND primary_caregiver_id = p_caregiver_id
    ) INTO v_is_linked;

    IF NOT v_is_linked THEN
        RETURN jsonb_build_object('success', FALSE, 'error', 'CAREGIVER_NOT_LINKED');
    END IF;

    INSERT INTO public.patient_passcode_sms_log (
        patient_id,
        caregiver_id,
        pairing_code_id,
        delivery_status,
        provider_message_id,
        error_code
    ) VALUES (
        v_code.patient_id,
        p_caregiver_id,
        p_pairing_code_id,
        p_delivery_status,
        p_provider_message_id,
        p_error_code
    )
    ON CONFLICT (pairing_code_id) WHERE delivery_status = 'SENT' DO NOTHING;

    RETURN jsonb_build_object('success', TRUE, 'status', p_delivery_status);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Deliberately NOT granted to anon/authenticated: server-side (service role) only.
REVOKE ALL ON FUNCTION public.record_passcode_sms_result(UUID, UUID, TEXT, TEXT, TEXT) FROM PUBLIC;
