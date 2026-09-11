-- ============================================================================
-- NIRVANA - Add device_id to social_media_accounts for device-scoped encryption
-- Migration: 20260912000000_social_media_accounts_device_id.sql
-- Description: Adds device_id column to social_media_accounts table and updates
-- device RPCs to filter/save by device_id. Each device has its own encryption
-- key, so accounts must be scoped to the device that created them.
-- ============================================================================

-- ------------------------------------------------------------------------------
-- 1. Add device_id column to social_media_accounts
-- ------------------------------------------------------------------------------
ALTER TABLE public.social_media_accounts
    ADD COLUMN IF NOT EXISTS device_id TEXT;

-- Add foreign key reference to patient_devices (nullable for legacy accounts)
ALTER TABLE public.social_media_accounts
    ADD CONSTRAINT fk_social_media_accounts_device
    FOREIGN KEY (device_id) REFERENCES public.patient_devices(device_id)
    ON DELETE SET NULL;

-- Index for device-scoped queries
CREATE INDEX IF NOT EXISTS idx_social_media_accounts_device
    ON public.social_media_accounts(device_id, updated_at DESC);

-- ------------------------------------------------------------------------------
-- 2. Update upsert RPC to save the calling device_id
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.upsert_social_media_account_for_device(
    p_id UUID,
    p_patient_id UUID,
    p_device_id TEXT,
    p_platform TEXT,
    p_username_or_email TEXT,
    p_password_ciphertext TEXT,
    p_password_nonce TEXT,
    p_password_mac TEXT,
    p_encryption_version SMALLINT DEFAULT 1
) RETURNS public.social_media_accounts AS $$
DECLARE
    v_account public.social_media_accounts;
BEGIN
    IF NOT public.is_active_patient_device(p_patient_id, p_device_id) THEN
        RAISE EXCEPTION 'Device is not paired to this patient.';
    END IF;
    INSERT INTO public.social_media_accounts (
        id, patient_id, device_id, platform, username_or_email,
        password_ciphertext, password_nonce, password_mac,
        encryption_version
    ) VALUES (
        p_id, p_patient_id, p_device_id, p_platform, p_username_or_email,
        p_password_ciphertext, p_password_nonce, p_password_mac,
        p_encryption_version
    )
    ON CONFLICT (id) DO UPDATE SET
        platform = EXCLUDED.platform,
        username_or_email = EXCLUDED.username_or_email,
        password_ciphertext = EXCLUDED.password_ciphertext,
        password_nonce = EXCLUDED.password_nonce,
        password_mac = EXCLUDED.password_mac,
        encryption_version = EXCLUDED.encryption_version,
        updated_at = TIMEZONE('utc', NOW())
    WHERE social_media_accounts.patient_id = p_patient_id
      AND (social_media_accounts.device_id IS NULL OR social_media_accounts.device_id = p_device_id);

    SELECT * INTO v_account FROM public.social_media_accounts
    WHERE id = p_id AND patient_id = p_patient_id;
    RETURN v_account;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ------------------------------------------------------------------------------
-- 3. Update GET RPC to filter by device_id
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_social_media_accounts_for_device(
    p_patient_id UUID,
    p_device_id TEXT
) RETURNS SETOF public.social_media_accounts AS $$
BEGIN
    IF NOT public.is_active_patient_device(p_patient_id, p_device_id) THEN
        RAISE EXCEPTION 'Device is not paired to this patient.';
    END IF;
    RETURN QUERY
        SELECT * FROM public.social_media_accounts
        WHERE patient_id = p_patient_id
          AND device_id = p_device_id
        ORDER BY updated_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ------------------------------------------------------------------------------
-- 4. Update DELETE RPC to filter by device_id (optional but consistent)
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
      AND patient_id = p_patient_id
      AND device_id = p_device_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ------------------------------------------------------------------------------
-- 5. Grants (re-apply for new function signatures)
-- ------------------------------------------------------------------------------
GRANT EXECUTE ON FUNCTION public.get_social_media_accounts_for_device(UUID, TEXT)
    TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.upsert_social_media_account_for_device(
    UUID, UUID, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, SMALLINT
) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.delete_social_media_account_for_device(UUID, TEXT, UUID)
    TO anon, authenticated;