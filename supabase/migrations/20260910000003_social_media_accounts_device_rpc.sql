-- ============================================================================
-- PATIENT DEVICE ACCESS FOR ENCRYPTED SOCIAL MEDIA ACCOUNTS
-- Device RPCs accept ciphertext only. They never receive or return plaintext
-- passwords and verify the device is actively paired to the patient.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.is_active_patient_device(
    p_patient_id UUID,
    p_device_id TEXT
) RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.patient_devices
        WHERE patient_id = p_patient_id
          AND device_id = p_device_id
          AND is_active = true
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

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
        ORDER BY updated_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

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
        id, patient_id, platform, username_or_email,
        password_ciphertext, password_nonce, password_mac,
        encryption_version
    ) VALUES (
        p_id, p_patient_id, p_platform, p_username_or_email,
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
    WHERE social_media_accounts.patient_id = p_patient_id;

    SELECT * INTO v_account FROM public.social_media_accounts
    WHERE id = p_id AND patient_id = p_patient_id;
    RETURN v_account;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

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
    WHERE id = p_id AND patient_id = p_patient_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.get_social_media_accounts_for_device(UUID, TEXT)
    TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.upsert_social_media_account_for_device(
    UUID, UUID, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, SMALLINT
) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.delete_social_media_account_for_device(UUID, TEXT, UUID)
    TO anon, authenticated;
