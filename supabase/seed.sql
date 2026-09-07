-- ==============================================================================
-- NIRVANA BACKEND SEED DATA
-- File: supabase/seed.sql
-- Description: Realistic non-clinical seed data for testing Elder & Caregiver workflows
-- ==============================================================================

-- 1. Create Demo Auth User (Caregiver) in auth.users if not already existing
-- In local Supabase development, auth.users is accessible for seeding
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM auth.users WHERE id = 'a0000000-0000-0000-0000-000000000001') THEN
        INSERT INTO auth.users (
            id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
            created_at, updated_at, raw_app_meta_data, raw_user_meta_data, is_super_admin
        ) VALUES (
            'a0000000-0000-0000-0000-000000000001',
            '00000000-0000-0000-0000-000000000000',
            'authenticated',
            'authenticated',
            'caregiver.demo@nirvana-care.org',
            crypt('NirvanaDemo2026!', gen_salt('bf')),
            NOW(),
            NOW() - INTERVAL '30 days',
            NOW(),
            '{"provider":"email","providers":["email"]}'::jsonb,
            '{"full_name":"Sarah Jenkins","role":"caregiver"}'::jsonb,
            false
        );
    END IF;
END $$;

-- 2. Caregiver Profile
INSERT INTO public.profiles (
    id, email, full_name, role, phone, avatar_url, preferences, created_at, updated_at
) VALUES (
    'a0000000-0000-0000-0000-000000000001',
    'caregiver.demo@nirvana-care.org',
    'Sarah Jenkins',
    'caregiver',
    '+1 (555) 234-5678',
    'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&w=300&q=80',
    '{"theme": "system", "notifications_enabled": true, "email_alerts": true, "digest_frequency": "daily"}'::jsonb,
    NOW() - INTERVAL '30 days',
    NOW()
) ON CONFLICT (id) DO UPDATE SET
    full_name = EXCLUDED.full_name,
    preferences = EXCLUDED.preferences;

-- 3. Demo Patient (Elder: Robert Jenkins)
INSERT INTO public.patients (
    id, primary_caregiver_id, display_name, preferred_name, avatar_url, date_of_birth, emergency_contact_phone, accessibility_settings, created_at, updated_at
) VALUES (
    'b0000000-0000-0000-0000-000000000001',
    'a0000000-0000-0000-0000-000000000001',
    'Robert Jenkins',
    'Dad',
    'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=300&q=80',
    '1948-06-15',
    '+1 (555) 234-5678',
    '{
        "large_text": true,
        "high_contrast": true,
        "audio_prompts": true,
        "haptic_feedback": true,
        "low_motion": true,
        "font_scale": 1.35
    }'::jsonb,
    NOW() - INTERVAL '30 days',
    NOW()
) ON CONFLICT (id) DO UPDATE SET
    display_name = EXCLUDED.display_name,
    accessibility_settings = EXCLUDED.accessibility_settings;

-- 4. Link Caregiver to Patient
INSERT INTO public.caregiver_patient_links (
    id, caregiver_id, patient_id, relationship_label, access_role, created_at
) VALUES (
    'c0000000-0000-0000-0000-000000000001',
    'a0000000-0000-0000-0000-000000000001',
    'b0000000-0000-0000-0000-000000000001',
    'Daughter & Primary Caregiver',
    'primary',
    NOW() - INTERVAL '30 days'
) ON CONFLICT (caregiver_id, patient_id) DO NOTHING;

-- 5. Family Photos with Voice Note References
INSERT INTO public.family_photos (
    id, patient_id, title, relationship, photo_url, audio_note_url, display_order, is_active, is_deleted, created_at, updated_at
) VALUES 
(
    'd0000000-0000-0000-0000-000000000001',
    'b0000000-0000-0000-0000-000000000001',
    'Emily',
    'Granddaughter',
    'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=600&q=80',
    'https://cdn.nirvana-care.org/audio/notes/emily_greeting.mp3',
    1,
    true,
    false,
    NOW() - INTERVAL '20 days',
    NOW()
),
(
    'd0000000-0000-0000-0000-000000000002',
    'b0000000-0000-0000-0000-000000000001',
    'Sarah & David',
    'Daughter & Son-in-law',
    'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?auto=format&fit=crop&w=600&q=80',
    'https://cdn.nirvana-care.org/audio/notes/sarah_david_greeting.mp3',
    2,
    true,
    false,
    NOW() - INTERVAL '20 days',
    NOW()
),
(
    'd0000000-0000-0000-0000-000000000003',
    'b0000000-0000-0000-0000-000000000001',
    'Bailey',
    'Family Golden Retriever',
    'https://images.unsplash.com/photo-1552053831-71594a27632d?auto=format&fit=crop&w=600&q=80',
    'https://cdn.nirvana-care.org/audio/notes/bailey_bark.mp3',
    3,
    true,
    false,
    NOW() - INTERVAL '15 days',
    NOW()
) ON CONFLICT (id) DO NOTHING;

-- 6. Reminders (3 Daily Active Reminders)
INSERT INTO public.reminders (
    id, patient_id, title, description, reminder_type, schedule_time, recurrence_days, is_active, audio_prompt_url, is_deleted, created_at, updated_at
) VALUES
(
    'e0000000-0000-0000-0000-000000000001',
    'b0000000-0000-0000-0000-000000000001',
    'Morning Blood Pressure Medicine',
    'Take 1 blue pill with a full glass of water after breakfast',
    'medication',
    '08:30:00',
    ARRAY['mon','tue','wed','thu','fri','sat','sun'],
    true,
    'https://cdn.nirvana-care.org/audio/prompts/morning_meds.mp3',
    false,
    NOW() - INTERVAL '25 days',
    NOW()
),
(
    'e0000000-0000-0000-0000-000000000002',
    'b0000000-0000-0000-0000-000000000001',
    'Afternoon Hydration',
    'Enjoy a refreshing glass of water or herbal tea',
    'hydration',
    '14:00:00',
    ARRAY['mon','tue','wed','thu','fri','sat','sun'],
    true,
    'https://cdn.nirvana-care.org/audio/prompts/hydration_time.mp3',
    false,
    NOW() - INTERVAL '25 days',
    NOW()
),
(
    'e0000000-0000-0000-0000-000000000003',
    'b0000000-0000-0000-0000-000000000001',
    'Evening Garden Walk & Call',
    'Step out in the fresh evening air and check in with Sarah',
    'social',
    '17:30:00',
    ARRAY['mon','wed','fri','sun'],
    true,
    'https://cdn.nirvana-care.org/audio/prompts/evening_walk.mp3',
    false,
    NOW() - INTERVAL '25 days',
    NOW()
) ON CONFLICT (id) DO NOTHING;

-- 7. Reminder Logs (Past 7 Days Acknowledgements)
INSERT INTO public.reminder_logs (
    id, reminder_id, patient_id, scheduled_for, acknowledged_at, status, created_at
) VALUES
-- Day -6
('f0000000-0000-0000-0000-000000000001', 'e0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000001', NOW() - INTERVAL '6 days 13 hours 30 mins', NOW() - INTERVAL '6 days 13 hours 25 mins', 'acknowledged', NOW() - INTERVAL '6 days 13 hours 25 mins'),
('f0000000-0000-0000-0000-000000000002', 'e0000000-0000-0000-0000-000000000002', 'b0000000-0000-0000-0000-000000000001', NOW() - INTERVAL '6 days 8 hours', NOW() - INTERVAL '6 days 7 hours 50 mins', 'acknowledged', NOW() - INTERVAL '6 days 7 hours 50 mins'),

-- Day -5
('f0000000-0000-0000-0000-000000000003', 'e0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000001', NOW() - INTERVAL '5 days 13 hours 30 mins', NOW() - INTERVAL '5 days 13 hours 20 mins', 'acknowledged', NOW() - INTERVAL '5 days 13 hours 20 mins'),
('f0000000-0000-0000-0000-000000000004', 'e0000000-0000-0000-0000-000000000002', 'b0000000-0000-0000-0000-000000000001', NOW() - INTERVAL '5 days 8 hours', NULL, 'missed', NOW() - INTERVAL '5 days 6 hours'),

-- Day -4
('f0000000-0000-0000-0000-000000000005', 'e0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000001', NOW() - INTERVAL '4 days 13 hours 30 mins', NOW() - INTERVAL '4 days 13 hours 28 mins', 'acknowledged', NOW() - INTERVAL '4 days 13 hours 28 mins'),
('f0000000-0000-0000-0000-000000000006', 'e0000000-0000-0000-0000-000000000002', 'b0000000-0000-0000-0000-000000000001', NOW() - INTERVAL '4 days 8 hours', NOW() - INTERVAL '4 days 7 hours 45 mins', 'acknowledged', NOW() - INTERVAL '4 days 7 hours 45 mins'),
('f0000000-0000-0000-0000-000000000007', 'e0000000-0000-0000-0000-000000000003', 'b0000000-0000-0000-0000-000000000001', NOW() - INTERVAL '4 days 4 hours 30 mins', NOW() - INTERVAL '4 days 4 hours 15 mins', 'acknowledged', NOW() - INTERVAL '4 days 4 hours 15 mins'),

-- Day -3
('f0000000-0000-0000-0000-000000000008', 'e0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000001', NOW() - INTERVAL '3 days 13 hours 30 mins', NOW() - INTERVAL '3 days 13 hours 22 mins', 'acknowledged', NOW() - INTERVAL '3 days 13 hours 22 mins'),
('f0000000-0000-0000-0000-000000000009', 'e0000000-0000-0000-0000-000000000002', 'b0000000-0000-0000-0000-000000000001', NOW() - INTERVAL '3 days 8 hours', NOW() - INTERVAL '3 days 7 hours 30 mins', 'acknowledged', NOW() - INTERVAL '3 days 7 hours 30 mins'),

-- Day -2
('f0000000-0000-0000-0000-000000000010', 'e0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000001', NOW() - INTERVAL '2 days 13 hours 30 mins', NOW() - INTERVAL '2 days 13 hours 15 mins', 'acknowledged', NOW() - INTERVAL '2 days 13 hours 15 mins'),
('f0000000-0000-0000-0000-000000000011', 'e0000000-0000-0000-0000-000000000002', 'b0000000-0000-0000-0000-000000000001', NOW() - INTERVAL '2 days 8 hours', NOW() - INTERVAL '2 days 7 hours 55 mins', 'acknowledged', NOW() - INTERVAL '2 days 7 hours 55 mins'),
('f0000000-0000-0000-0000-000000000012', 'e0000000-0000-0000-0000-000000000003', 'b0000000-0000-0000-0000-000000000001', NOW() - INTERVAL '2 days 4 hours 30 mins', NOW() - INTERVAL '2 days 4 hours 20 mins', 'acknowledged', NOW() - INTERVAL '2 days 4 hours 20 mins'),

-- Day -1
('f0000000-0000-0000-0000-000000000013', 'e0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000001', NOW() - INTERVAL '1 day 13 hours 30 mins', NOW() - INTERVAL '1 day 13 hours 20 mins', 'acknowledged', NOW() - INTERVAL '1 day 13 hours 20 mins'),
('f0000000-0000-0000-0000-000000000014', 'e0000000-0000-0000-0000-000000000002', 'b0000000-0000-0000-0000-000000000001', NOW() - INTERVAL '1 day 8 hours', NOW() - INTERVAL '1 day 7 hours 40 mins', 'acknowledged', NOW() - INTERVAL '1 day 7 hours 40 mins'),

-- Today
('f0000000-0000-0000-0000-000000000015', 'e0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000001', NOW() - INTERVAL '3 hours 30 mins', NOW() - INTERVAL '3 hours 25 mins', 'acknowledged', NOW() - INTERVAL '3 hours 25 mins')
ON CONFLICT (id) DO NOTHING;

-- 8. Seven Days of Realistic Game Activity (Non-Clinical Engagement Sessions)
INSERT INTO public.game_sessions (
    id, patient_id, game_type, difficulty_level, total_trials, successful_trials, duration_seconds, activity_metadata, started_at, completed_at, created_at
) VALUES
-- Day 1 (7 days ago): Remember Objects & Who Is This
(
    '10000000-0000-0000-0000-000000000001',
    'b0000000-0000-0000-0000-000000000001',
    'remember_objects',
    1,
    4,
    4,
    180,
    '{"category": "everyday_items", "hints_used": 0, "completed_without_pause": true}'::jsonb,
    NOW() - INTERVAL '7 days 10 hours',
    NOW() - INTERVAL '7 days 9 hours 57 mins',
    NOW() - INTERVAL '7 days 9 hours 57 mins'
),
(
    '10000000-0000-0000-0000-000000000002',
    'b0000000-0000-0000-0000-000000000001',
    'who_is_this',
    1,
    3,
    3,
    210,
    '{"voice_notes_played": 2, "hints_used": 1}'::jsonb,
    NOW() - INTERVAL '7 days 9 hours 40 mins',
    NOW() - INTERVAL '7 days 9 hours 36 mins 30 secs',
    NOW() - INTERVAL '7 days 9 hours 36 mins 30 secs'
),

-- Day 2 (6 days ago): Grocery Memory & Remember Objects
(
    '10000000-0000-0000-0000-000000000003',
    'b0000000-0000-0000-0000-000000000001',
    'grocery_memory',
    1,
    3,
    3,
    240,
    '{"items_in_list": ["Bread", "Milk", "Apples"], "basket_accuracy": 1.0}'::jsonb,
    NOW() - INTERVAL '6 days 11 hours',
    NOW() - INTERVAL '6 days 10 hours 56 mins',
    NOW() - INTERVAL '6 days 10 hours 56 mins'
),
(
    '10000000-0000-0000-0000-000000000004',
    'b0000000-0000-0000-0000-000000000001',
    'remember_objects',
    2,
    4,
    3,
    210,
    '{"category": "nature", "hints_used": 1}'::jsonb,
    NOW() - INTERVAL '6 days 10 hours 30 mins',
    NOW() - INTERVAL '6 days 10 hours 26 mins 30 secs',
    NOW() - INTERVAL '6 days 10 hours 26 mins 30 secs'
),

-- Day 3 (5 days ago): Who Is This?
(
    '10000000-0000-0000-0000-000000000005',
    'b0000000-0000-0000-0000-000000000001',
    'who_is_this',
    1,
    3,
    3,
    195,
    '{"voice_notes_played": 3, "enjoyed_photo": "Emily"}'::jsonb,
    NOW() - INTERVAL '5 days 10 hours',
    NOW() - INTERVAL '5 days 9 hours 56 mins 45 secs',
    NOW() - INTERVAL '5 days 9 hours 56 mins 45 secs'
),

-- Day 4 (4 days ago): Grocery Memory & Remember Objects
(
    '10000000-0000-0000-0000-000000000006',
    'b0000000-0000-0000-0000-000000000001',
    'grocery_memory',
    2,
    4,
    4,
    310,
    '{"items_in_list": ["Bananas", "Tea", "Biscuits", "Butter"], "basket_accuracy": 1.0}'::jsonb,
    NOW() - INTERVAL '4 days 11 hours 15 mins',
    NOW() - INTERVAL '4 days 11 hours 9 mins 50 secs',
    NOW() - INTERVAL '4 days 11 hours 9 mins 50 secs'
),
(
    '10000000-0000-0000-0000-000000000007',
    'b0000000-0000-0000-0000-000000000001',
    'remember_objects',
    2,
    4,
    4,
    220,
    '{"category": "kitchen", "hints_used": 0}'::jsonb,
    NOW() - INTERVAL '4 days 10 hours 45 mins',
    NOW() - INTERVAL '4 days 10 hours 41 mins 20 secs',
    NOW() - INTERVAL '4 days 10 hours 41 mins 20 secs'
),

-- Day 5 (3 days ago): Remember Objects
(
    '10000000-0000-0000-0000-000000000008',
    'b0000000-0000-0000-0000-000000000001',
    'remember_objects',
    2,
    4,
    3,
    205,
    '{"category": "everyday_items", "hints_used": 1}'::jsonb,
    NOW() - INTERVAL '3 days 10 hours',
    NOW() - INTERVAL '3 days 9 hours 56 mins 35 secs',
    NOW() - INTERVAL '3 days 9 hours 56 mins 35 secs'
),

-- Day 6 (2 days ago): Who Is This? & Grocery Memory
(
    '10000000-0000-0000-0000-000000000009',
    'b0000000-0000-0000-0000-000000000001',
    'who_is_this',
    1,
    3,
    3,
    180,
    '{"voice_notes_played": 1, "hints_used": 0}'::jsonb,
    NOW() - INTERVAL '2 days 11 hours',
    NOW() - INTERVAL '2 days 10 hours 57 mins',
    NOW() - INTERVAL '2 days 10 hours 57 mins'
),
(
    '10000000-0000-0000-0000-000000000010',
    'b0000000-0000-0000-0000-000000000001',
    'grocery_memory',
    2,
    3,
    3,
    230,
    '{"items_in_list": ["Oranges", "Oatmeal", "Yogurt"], "basket_accuracy": 1.0}'::jsonb,
    NOW() - INTERVAL '2 days 10 hours 30 mins',
    NOW() - INTERVAL '2 days 10 hours 26 mins 10 secs',
    NOW() - INTERVAL '2 days 10 hours 26 mins 10 secs'
),

-- Day 7 (Yesterday / Today): All 3 Engagement Activities
(
    '10000000-0000-0000-0000-000000000011',
    'b0000000-0000-0000-0000-000000000001',
    'remember_objects',
    2,
    4,
    4,
    215,
    '{"category": "garden", "hints_used": 0}'::jsonb,
    NOW() - INTERVAL '1 day 10 hours 30 mins',
    NOW() - INTERVAL '1 day 10 hours 26 mins 25 secs',
    NOW() - INTERVAL '1 day 10 hours 26 mins 25 secs'
),
(
    '10000000-0000-0000-0000-000000000012',
    'b0000000-0000-0000-0000-000000000001',
    'who_is_this',
    1,
    3,
    3,
    170,
    '{"voice_notes_played": 2, "hints_used": 0}'::jsonb,
    NOW() - INTERVAL '4 hours',
    NOW() - INTERVAL '3 hours 57 mins 10 secs',
    NOW() - INTERVAL '3 hours 57 mins 10 secs'
),
(
    '10000000-0000-0000-0000-000000000013',
    'b0000000-0000-0000-0000-000000000001',
    'grocery_memory',
    2,
    4,
    4,
    240,
    '{"items_in_list": ["Soup", "Crackers", "Strawberries", "Honey"], "basket_accuracy": 1.0}'::jsonb,
    NOW() - INTERVAL '3 hours 30 mins',
    NOW() - INTERVAL '3 hours 26 mins',
    NOW() - INTERVAL '3 hours 26 mins'
) ON CONFLICT (id) DO NOTHING;

-- 9. Seed Matching Idempotent Sync Events
INSERT INTO public.sync_events (
    event_id, patient_id, entity_type, entity_id, operation, payload, sync_status, created_at, processed_at
) VALUES
(
    '90000000-0000-0000-0000-000000000001',
    'b0000000-0000-0000-0000-000000000001',
    'game_session',
    '10000000-0000-0000-0000-000000000013',
    'INSERT',
    '{"game_type": "grocery_memory", "difficulty_level": 2, "total_trials": 4, "successful_trials": 4, "duration_seconds": 240}'::jsonb,
    'PROCESSED',
    NOW() - INTERVAL '3 hours 26 mins',
    NOW() - INTERVAL '3 hours 25 mins 50 secs'
),
(
    '90000000-0000-0000-0000-000000000002',
    'b0000000-0000-0000-0000-000000000001',
    'reminder_log',
    'f0000000-0000-0000-0000-000000000015',
    'INSERT',
    '{"reminder_id": "e0000000-0000-0000-0000-000000000001", "status": "acknowledged"}'::jsonb,
    'PROCESSED',
    NOW() - INTERVAL '3 hours 25 mins',
    NOW() - INTERVAL '3 hours 24 mins 50 secs'
) ON CONFLICT (event_id) DO NOTHING;
