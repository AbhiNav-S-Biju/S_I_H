-- ==============================================================================
-- NIRVANA BACKEND SCHEMA MIGRATION (Phase 1: Tables, Constraints, Indexes)
-- Migration: 20260907000000_init_nirvana_schema.sql
-- Description: Core schema for offline-first cognitive engagement & caregiver platform
-- ==============================================================================

-- 1. Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 2. Helper function to manage updated_at timestamps automatically
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = TIMEZONE('utc', NOW());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ------------------------------------------------------------------------------
-- Table 1: Profiles (Caregivers, Family Members, Clinicians/Admins)
-- Mirrors auth.users metadata with app-specific preferences and role definitions
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT UNIQUE NOT NULL,
    full_name TEXT NOT NULL,
    role TEXT NOT NULL DEFAULT 'caregiver' CHECK (role IN ('caregiver', 'family_member', 'admin')),
    phone TEXT,
    avatar_url TEXT,
    preferences JSONB DEFAULT '{"theme": "system", "notifications_enabled": true, "email_alerts": true}'::jsonb NOT NULL,
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc', NOW()) NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT TIMEZONE('utc', NOW()) NOT NULL
);

CREATE TRIGGER set_profiles_updated_at
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- ------------------------------------------------------------------------------
-- Table 2: Patients (Elderly Profile / Care Recipient)
-- Contains accessibility preferences, personal details, emergency contact
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.patients (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    primary_caregiver_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    display_name TEXT NOT NULL,
    preferred_name TEXT NOT NULL,
    avatar_url TEXT,
    date_of_birth DATE,
    emergency_contact_phone TEXT,
    accessibility_settings JSONB DEFAULT '{
        "large_text": true,
        "high_contrast": true,
        "audio_prompts": true,
        "haptic_feedback": true,
        "low_motion": true,
        "font_scale": 1.3
    }'::jsonb NOT NULL,
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc', NOW()) NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT TIMEZONE('utc', NOW()) NOT NULL
);

CREATE TRIGGER set_patients_updated_at
    BEFORE UPDATE ON public.patients
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- ------------------------------------------------------------------------------
-- Table 3: Caregiver-Patient Links (Access Control Association)
-- Allows multiple caregivers/family members to collaborate with fine-grained access
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.caregiver_patient_links (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    caregiver_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    patient_id UUID NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,
    relationship_label TEXT DEFAULT 'Caregiver' NOT NULL,
    access_role TEXT NOT NULL DEFAULT 'primary' CHECK (access_role IN ('primary', 'secondary', 'viewer')),
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc', NOW()) NOT NULL,
    CONSTRAINT uq_caregiver_patient UNIQUE (caregiver_id, patient_id)
);

-- ------------------------------------------------------------------------------
-- Table 4: Game Sessions (Non-Clinical Cognitive Engagement Logs)
-- Strictly stores activity telemetry: consistency, trials, duration, preferred choices
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.game_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,
    game_type TEXT NOT NULL CHECK (game_type IN ('remember_objects', 'who_is_this', 'grocery_memory', 'jigsaw_puzzle')),
    difficulty_level INT NOT NULL DEFAULT 1 CHECK (difficulty_level >= 1 AND difficulty_level <= 5),
    total_trials INT NOT NULL DEFAULT 0 CHECK (total_trials >= 0),
    successful_trials INT NOT NULL DEFAULT 0 CHECK (successful_trials >= 0),
    duration_seconds INT NOT NULL DEFAULT 0 CHECK (duration_seconds >= 0),
    activity_metadata JSONB DEFAULT '{}'::jsonb NOT NULL,
    started_at TIMESTAMPTZ NOT NULL,
    completed_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc', NOW()) NOT NULL
);

-- ------------------------------------------------------------------------------
-- Table 5: Reminders (Medication, Hydration, Daily Routine Tasks)
-- Configurable reminders with offline exact alarm schedules and audio prompt URLs
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.reminders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    reminder_type TEXT NOT NULL CHECK (reminder_type IN ('medication', 'hydration', 'meal', 'social', 'activity', 'general')),
    schedule_time TIME NOT NULL,
    recurrence_days TEXT[] DEFAULT ARRAY['mon','tue','wed','thu','fri','sat','sun'] NOT NULL,
    is_active BOOLEAN DEFAULT true NOT NULL,
    audio_prompt_url TEXT,
    is_deleted BOOLEAN DEFAULT false NOT NULL,
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc', NOW()) NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT TIMEZONE('utc', NOW()) NOT NULL
);

CREATE TRIGGER set_reminders_updated_at
    BEFORE UPDATE ON public.reminders
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- ------------------------------------------------------------------------------
-- Table 6: Reminder Logs (Acknowledgement & Compliance History)
-- Append-only log tracking elder responses to scheduled reminders
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.reminder_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reminder_id UUID NOT NULL REFERENCES public.reminders(id) ON DELETE CASCADE,
    patient_id UUID NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,
    scheduled_for TIMESTAMPTZ NOT NULL,
    acknowledged_at TIMESTAMPTZ,
    status TEXT NOT NULL CHECK (status IN ('acknowledged', 'missed', 'snoozed')),
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc', NOW()) NOT NULL
);

-- ------------------------------------------------------------------------------
-- Table 7: Family Photos (Familiar Faces & Cherished Memories Album)
-- Privacy-safe album with voice clips for the "Who Is This?" game and memory gallery
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.family_photos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    relationship TEXT NOT NULL,
    photo_url TEXT NOT NULL,
    audio_note_url TEXT,
    display_order INT DEFAULT 0 NOT NULL,
    is_active BOOLEAN DEFAULT true NOT NULL,
    is_deleted BOOLEAN DEFAULT false NOT NULL,
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc', NOW()) NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT TIMEZONE('utc', NOW()) NOT NULL
);

CREATE TRIGGER set_family_photos_updated_at
    BEFORE UPDATE ON public.family_photos
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- ------------------------------------------------------------------------------
-- Table 8: Sync Events (Idempotent Journal & Server Replication Log)
-- Tracks every mutation from local mobile clients to ensure exact-once execution
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.sync_events (
    event_id UUID PRIMARY KEY,
    patient_id UUID NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,
    entity_type TEXT NOT NULL CHECK (entity_type IN ('game_session', 'reminder', 'reminder_log', 'family_photo', 'patient', 'profile')),
    entity_id UUID NOT NULL,
    operation TEXT NOT NULL CHECK (operation IN ('INSERT', 'UPDATE', 'DELETE')),
    payload JSONB NOT NULL,
    sync_status TEXT NOT NULL DEFAULT 'PROCESSED' CHECK (sync_status IN ('PROCESSED', 'FAILED', 'IGNORED_DUPLICATE')),
    retry_count INT DEFAULT 0 NOT NULL,
    error_message TEXT,
    created_at TIMESTAMPTZ NOT NULL,
    processed_at TIMESTAMPTZ DEFAULT TIMEZONE('utc', NOW()) NOT NULL
);

-- ------------------------------------------------------------------------------
-- Performance & Lookup Indexes
-- ------------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_patients_primary_caregiver ON public.patients(primary_caregiver_id);
CREATE INDEX IF NOT EXISTS idx_caregiver_patient_links_caregiver ON public.caregiver_patient_links(caregiver_id);
CREATE INDEX IF NOT EXISTS idx_caregiver_patient_links_patient ON public.caregiver_patient_links(patient_id);

CREATE INDEX IF NOT EXISTS idx_game_sessions_patient_created ON public.game_sessions(patient_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_game_sessions_type_patient ON public.game_sessions(patient_id, game_type, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_reminders_patient_active ON public.reminders(patient_id, is_active) WHERE is_deleted = false;
CREATE INDEX IF NOT EXISTS idx_reminder_logs_patient_scheduled ON public.reminder_logs(patient_id, scheduled_for DESC);
CREATE INDEX IF NOT EXISTS idx_reminder_logs_reminder_scheduled ON public.reminder_logs(reminder_id, scheduled_for DESC);

CREATE INDEX IF NOT EXISTS idx_family_photos_patient_order ON public.family_photos(patient_id, display_order ASC) WHERE is_deleted = false;
CREATE INDEX IF NOT EXISTS idx_sync_events_patient_created ON public.sync_events(patient_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_sync_events_entity ON public.sync_events(entity_type, entity_id);
