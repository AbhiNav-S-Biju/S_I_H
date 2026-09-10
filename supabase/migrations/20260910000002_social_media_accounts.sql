-- ============================================================================
-- NIRVANA SOCIAL MEDIA ACCOUNTS
-- Stores no plaintext passwords. password_ciphertext and password_nonce must
-- be produced by the client-side encryption layer before insertion.
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.social_media_accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,
    platform TEXT NOT NULL CHECK (
        platform IN (
            'instagram',
            'facebook',
            'xTwitter',
            'linkedIn',
            'snapchat',
            'tikTok',
            'discord'
        )
    ),
    username_or_email TEXT NOT NULL,
    password_ciphertext TEXT NOT NULL,
    password_nonce TEXT NOT NULL,
    password_mac TEXT NOT NULL,
    encryption_version SMALLINT NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT TIMEZONE('utc', NOW())
);

CREATE INDEX IF NOT EXISTS idx_social_media_accounts_patient
    ON public.social_media_accounts(patient_id, updated_at DESC);

CREATE TRIGGER set_social_media_accounts_updated_at
    BEFORE UPDATE ON public.social_media_accounts
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

ALTER TABLE public.social_media_accounts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "social_media_accounts_select_linked"
    ON public.social_media_accounts FOR SELECT
    TO authenticated
    USING (public.is_caregiver_for_patient(patient_id));

CREATE POLICY "social_media_accounts_insert_linked"
    ON public.social_media_accounts FOR INSERT
    TO authenticated
    WITH CHECK (public.is_caregiver_for_patient(patient_id));

CREATE POLICY "social_media_accounts_update_linked"
    ON public.social_media_accounts FOR UPDATE
    TO authenticated
    USING (public.is_caregiver_for_patient(patient_id))
    WITH CHECK (public.is_caregiver_for_patient(patient_id));

CREATE POLICY "social_media_accounts_delete_linked"
    ON public.social_media_accounts FOR DELETE
    TO authenticated
    USING (public.is_caregiver_for_patient(patient_id));