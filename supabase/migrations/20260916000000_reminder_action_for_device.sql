-- ============================================================================
-- NIRVANA - Record a reminder action from a paired patient device
-- Migration: 20260916000000_reminder_action_for_device.sql
-- Description: Patient devices are unauthenticated (anon key). The
--   `reminder_logs` insert and `caregiver_notifications` insert are both gated to
--   `authenticated` caregivers, and `caregiver_patient_links` cannot be read by
--   anon device — so when the elder completed a reminder (Done, or simply
--   closing the alarm), the caregiver portal was NEVER updated.
--
--   This adds a SECURITY DEFINER RPC that a paired device can call to record a
--   reminder action. It:
--     1. Verifies the calling device is actively to the patient.
--     2. Writes the reminder log (done / snoozed / later_today).
--     3. Fans the event out to every linked caregiver as a
--        `caregiver_notifications` row so the caregiver portal updates.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.record_reminder_action_for_device(
    p_patient_id UUID,
    p_device_id TEXT,
    p_reminder_id UUID,
    p_log_id UUID,
    p_action TEXT,
    p_action_timestamp TIMESTAMPTZ,
    p_reminder_title TEXT,
    p_snoozed_until TIMESTAMPTZ DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
    v_patient RECORD;
    v_caregiver RECORD;
    v_status TEXT;
    v_type TEXT;
    v_title TEXT;
    v_message TEXT;
    v_display TEXT;
BEGIN
    IF NOT public.is_active_patient_device(p_patient_id, p_device_id) THEN
        RAISE EXCEPTION 'Device is not paired to this patient.';
    END IF;

    -- Map the action to the reminder_logs status + notification type.
    CASE p_action
        WHEN 'done' THEN
            v_status := 'acknowledged';
            v_type := 'reminder_completed';
        WHEN 'snoozed' THEN
            v_status := 'snoozed';
            v_type := 'reminder_snoozed';
        WHEN 'later_today' THEN
            v_status := 'snoozed';
            v_type := 'reminder_snoozed';
        WHEN 'missed' THEN
            v_status := 'missed';
            v_type := 'reminder_missed';
        ELSE
            v_status := 'pending';
            v_type := 'reminder_completed';
    END CASE;

    -- 1. Record the adherence log (idempotent on the client-generated log id).
    INSERT INTO public.reminder_logs (
        id, reminder_id, patient_id, scheduled_for, acknowledged_at,
        snoozed_until, status, created_at
    ) VALUES (
        p_log_id, p_reminder_id, p_patient_id, p_action_timestamp,
        CASE WHEN p_action = 'done' THEN p_action_timestamp ELSE NULL END,
        p_snoozed_until, v_status, TIMEZONE('utc', NOW())
    )
    ON CONFLICT (id) DO UPDATE SET
        acknowledged_at = EXCLUDED.acknowledged_at,
        snoozed_until = EXCLUDED.snoozed_until,
        status = EXCLUDED.status;

    -- 2. Resolve the patient's display name for the notification copy.
    SELECT display_name, preferred_name
      INTO v_patient
      FROM public.patients WHERE id = p_patient_id;
    v_display := COALESCE(NULLIF(v_patient.preferred_name, ''), v_patient.display_name, 'Loved One');

    -- 3. Build the caregiver-facing message.
    v_title := CASE p_action
        WHEN 'done' THEN 'Reminder Completed'
        WHEN 'snoozed' THEN 'Reminder Snoozed'
        WHEN 'later_today' THEN 'Reminder Snoozed'
        WHEN 'missed' THEN 'Missed Reminder'
        ELSE 'Reminder Updated'
    END;
    v_message := CASE p_action
        WHEN 'done' THEN v_display || ' completed their "' || p_reminder_title || '" reminder.'
        WHEN 'missed' THEN v_display || ' missed their "' || p_reminder_title || '" reminder.'
        ELSE v_display || ' snoozed "' || p_reminder_title || '".'
    END;

    -- 4. Notify every linked caregiver (explicit links + primary caregiver).
    FOR v_caregiver IN
        SELECT caregiver_id FROM public.caregiver_patient_links WHERE patient_id = p_patient_id
        UNION
        SELECT primary_caregiver_id AS caregiver_id FROM public.patients
         WHERE id = p_patient_id AND primary_caregiver_id IS NOT NULL
    LOOP
        INSERT INTO public.caregiver_notifications (
            caregiver_id, patient_id, notification_type, title, message,
            related_reminder_id, created_at
        ) VALUES (
            v_caregiver.caregiver_id, p_patient_id, v_type, v_title, v_message,
            p_reminder_id, TIMEZONE('utc', NOW())
        );
    END LOOP;

    RETURN jsonb_build_object(
        'success', true,
        'status', v_status,
        'notification_type', v_type
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.record_reminder_action_for_device(
    UUID, TEXT, UUID, UUID, TEXT, TIMESTAMPTZ, TEXT, TIMESTAMPTZ
) TO anon, authenticated;
