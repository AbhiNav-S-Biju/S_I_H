1-- ============================================================================
-- NIRVANA - Scope social media accounts by patient (account-specific)
-- Migration: 20260914000000_social_media_accounts_patient_scoped.sql
-- Description: Social media accounts are account/patient-specific, NOT
--   device-specific. Any device actively paired to the patient must see and
--   manage the same set of accounts.
--
--   This migration:
--     1. Drops the strict `device_id = p_device_id` filters on GET/DELETE so a
--        patient's accounts are visible/manageable from every paired device.
--     2. Keeps `device_id` on the row purely as an audit trail of the device
--        that last wrote it (it is no longer used to filter reads).
--     3. Keeps the `is_active_patient_device(...)` authorization check, so only
--        devices currently paired to the patient can read or mutate rows.
--
--   Decryption is handled client-side and is now keyed by the patient (see
--   SupabaseSocialMediaAccountRepository), so all of the patient's paired
--   devices share the same encryption key and can decrypt each other's rows.
-- ============================================================================

-- ------------------------------------------------------------------------------
-- 1. GET: return every account for the patient (ignoring which device wrote it)
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_social_media_accounts_for_device(
    p_patient_id UUID,
    p_device_id TEXT
) RETURNS SETOF public.social_media_accounts AS $$
BEGIN
    -- Authorization only: the calling device must still be paired to the patient.
    IF NOT public.is_active_patient_device(p_patient_id, p_device_id) THEN
        RAISE EXCEPTION 'Device is not paired to this patient.';
    END IF;
    RETURN QUERY
        SELECT * FROM public.social_media_accounts
        WHERE patient_id = p_patient_id
        ORDER BY updated_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ------------------------------------------------------------------------------
-- 2. DELETE: allow any paired device to delete any of the patient's accounts
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.delete_social_media_account_for_device(
    p_patient_id UUID,
    p_device_id TEXT,
    p_id UUID
) RETURNS VOID AS $$
BEGIN
    IF NOT public.is_active_patient_device(p_patient_id, p_device_id) THEN
        RAISE EXCEPTION 'Device is not paired to this patient.';
    END IF;
    DELETE FROM public.social_media_accounts
    WHERE id = p_id
      AND patient_id = p_patient_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ------------------------------------------------------------------------------
-- 3. Grants (re-apply for the rewritten functions)
-- ------------------------------------------------------------------------------
GRANT EXECUTE ON FUNCTION public.get_social_media_accounts_for_device(UUID, TEXT)
    TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.delete_social_media_account_for_device(UUID, TEXT, UUID)
    TO anon, authenticated;
