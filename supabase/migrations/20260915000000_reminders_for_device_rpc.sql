-- ============================================================================
-- NIRVANA - Device-scoped reminder pull RPC
-- Migration: 20260915000000_reminders_for_device_rpc.sql
-- Description: Patient devices are unauthenticated (anon key, no login), so the
--   `reminders` RLS policies (TO authenticated) block them from reading any
--   rows. As a result caregiver-created reminders never reached the patient
--   device and the patient dashboard showed "0 of 0".
--
--   This adds a SECURITY DEFINER RPC, following the same pattern as
--   `get_social_media_accounts_for_device`, that returns a patient's reminders
--   to a device that is actively paired to that patient. Authorization is
--   enforced inside the function via `is_active_patient_device(...)`, so no
--   broad anon SELECT policy is exposed on the table.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.get_reminders_for_device(
    p_patient_id UUID,
    p_device_id TEXT
) RETURNS SETOF public.reminders AS $$
BEGIN
    IF NOT public.is_active_patient_device(p_patient_id, p_device_id) THEN
        RAISE EXCEPTION 'Device is not paired to this patient.';
    END IF;
    RETURN QUERY
        SELECT * FROM public.reminders
        WHERE patient_id = p_patient_id
          AND is_deleted = false
        ORDER BY schedule_time ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Reminder logs for the same patient (used for adherence status on the device).
CREATE OR REPLACE FUNCTION public.get_reminder_logs_for_device(
    p_patient_id UUID,
    p_device_id TEXT
) RETURNS SETOF public.reminder_logs AS $$
BEGIN
    IF NOT public.is_active_patient_device(p_patient_id, p_device_id) THEN
        RAISE EXCEPTION 'Device is not paired to this patient.';
    END IF;
    RETURN QUERY
        SELECT * FROM public.reminder_logs
        WHERE patient_id = p_patient_id
        ORDER BY created_at DESC
        LIMIT 200;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.get_reminders_for_device(UUID, TEXT)
    TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.get_reminder_logs_for_device(UUID, TEXT)
    TO anon, authenticated;
