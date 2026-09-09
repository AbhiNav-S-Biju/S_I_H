-- ==============================================================================
-- NIRVANA BACKEND SCHEMA & SECURITY EXPANSION (Phase 8: Caregiver Push Tokens)
-- Migration: 20260910000000_caregiver_push_tokens.sql
-- Description: Creates caregiver_push_tokens table, RLS policies, indexes,
-- and secure stored procedures for registering/deactivating FCM device tokens.
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. Table: Caregiver Push Tokens
-- Stores active FCM registration tokens for caregivers across their mobile devices
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.caregiver_push_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    caregiver_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    fcm_token TEXT NOT NULL,
    device_platform TEXT NOT NULL DEFAULT 'android' CHECK (device_platform IN ('android', 'ios', 'web', 'macos', 'windows')),
    device_name TEXT,
    is_active BOOLEAN NOT NULL DEFAULT true,
    last_used_at TIMESTAMPTZ DEFAULT TIMEZONE('utc', NOW()) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc', NOW()) NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT TIMEZONE('utc', NOW()) NOT NULL,
    CONSTRAINT uq_caregiver_fcm_token UNIQUE (caregiver_id, fcm_token)
);

CREATE TRIGGER set_caregiver_push_tokens_updated_at
    BEFORE UPDATE ON public.caregiver_push_tokens
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

CREATE INDEX IF NOT EXISTS idx_caregiver_push_tokens_caregiver
    ON public.caregiver_push_tokens(caregiver_id)
    WHERE is_active = true;

CREATE INDEX IF NOT EXISTS idx_caregiver_push_tokens_token
    ON public.caregiver_push_tokens(fcm_token);

-- ------------------------------------------------------------------------------
-- 2. Enable Row Level Security (RLS)
-- ------------------------------------------------------------------------------
ALTER TABLE public.caregiver_push_tokens ENABLE ROW LEVEL SECURITY;

-- ------------------------------------------------------------------------------
-- 3. Row Level Security Policies
-- Caregivers can strictly read, insert, update, and delete only their own push tokens
-- ------------------------------------------------------------------------------
CREATE POLICY "caregiver_push_tokens_select_own"
    ON public.caregiver_push_tokens FOR SELECT
    TO authenticated
    USING (caregiver_id = auth.uid());

CREATE POLICY "caregiver_push_tokens_insert_own"
    ON public.caregiver_push_tokens FOR INSERT
    TO authenticated
    WITH CHECK (caregiver_id = auth.uid());

CREATE POLICY "caregiver_push_tokens_update_own"
    ON public.caregiver_push_tokens FOR UPDATE
    TO authenticated
    USING (caregiver_id = auth.uid())
    WITH CHECK (caregiver_id = auth.uid());

CREATE POLICY "caregiver_push_tokens_delete_own"
    ON public.caregiver_push_tokens FOR DELETE
    TO authenticated
    USING (caregiver_id = auth.uid());

-- ------------------------------------------------------------------------------
-- 4. Secure Stored Procedures (RPCs)
-- ------------------------------------------------------------------------------

-- (a) Register or refresh an FCM device token for the authenticated caregiver
CREATE OR REPLACE FUNCTION public.register_caregiver_push_token(
    p_fcm_token TEXT,
    p_device_platform TEXT DEFAULT 'android',
    p_device_name TEXT DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
    v_uid UUID;
    v_record_id UUID;
BEGIN
    v_uid := auth.uid();
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'Authentication required: caller is not logged in';
    END IF;

    IF p_fcm_token IS NULL OR trim(p_fcm_token) = '' THEN
        RAISE EXCEPTION 'Invalid token: p_fcm_token cannot be empty';
    END IF;

    INSERT INTO public.caregiver_push_tokens (
        caregiver_id,
        fcm_token,
        device_platform,
        device_name,
        is_active,
        last_used_at,
        created_at,
        updated_at
    ) VALUES (
        v_uid,
        trim(p_fcm_token),
        COALESCE(p_device_platform, 'android'),
        p_device_name,
        true,
        TIMEZONE('utc', NOW()),
        TIMEZONE('utc', NOW()),
        TIMEZONE('utc', NOW())
    )
    ON CONFLICT (caregiver_id, fcm_token) DO UPDATE SET
        device_platform = EXCLUDED.device_platform,
        device_name = COALESCE(EXCLUDED.device_name, public.caregiver_push_tokens.device_name),
        is_active = true,
        last_used_at = TIMEZONE('utc', NOW()),
        updated_at = TIMEZONE('utc', NOW())
    RETURNING id INTO v_record_id;

    RETURN jsonb_build_object(
        'success', true,
        'id', v_record_id,
        'caregiver_id', v_uid,
        'fcm_token', trim(p_fcm_token),
        'is_active', true
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- (b) Deactivate an FCM device token (e.g., when logging out)
CREATE OR REPLACE FUNCTION public.deactivate_caregiver_push_token(
    p_fcm_token TEXT
) RETURNS JSONB AS $$
DECLARE
    v_uid UUID;
BEGIN
    v_uid := auth.uid();
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'Authentication required: caller is not logged in';
    END IF;

    UPDATE public.caregiver_push_tokens
    SET is_active = false,
        updated_at = TIMEZONE('utc', NOW())
    WHERE caregiver_id = v_uid
      AND fcm_token = trim(p_fcm_token);

    RETURN jsonb_build_object(
        'success', true,
        'fcm_token', trim(p_fcm_token),
        'is_active', false
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;
