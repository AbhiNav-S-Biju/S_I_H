# NIRVANA - Caregiver Push Notification Architecture (Phase 8)

## 1. Overview & Architecture Flow

The NIRVANA Push Notification Architecture delivers real-time notifications to caregivers when critical patient events occur (such as medication reminders completed, missed, or snoozed, cognitive games completed, and new devices paired).

```
Patient Event (Offline / Online)
         ↓
Supabase Database (Sync / RPC)
         ↓
caregiver_notifications Table (In-App Feed & Source of Truth)
         ↓
Database Webhook Trigger (INSERT)
         ↓
Supabase Edge Function (push-caregiver-notification)
         ↓
Firebase Cloud Messaging (FCM HTTP v1 API using Server-Side Service Account)
         ↓
Caregiver Android/iOS Device (Foreground / Background / Terminated)
         ↓
Notification Tap -> Deep Link to Caregiver Dashboard & Alert Context
```

---

## 2. Core Security Rules (Zero-Credential Exposure)

> [!IMPORTANT]
> **Strict Client-Side Security Isolation**:
> 1. **Zero Service Accounts in Flutter**: The Flutter mobile client **never** contains Firebase service account JSON files, private keys, or server credentials.
> 2. **Zero Supabase Service-Role Keys in Flutter**: The Flutter app strictly uses the Supabase Anonymous Key (`anonKey`) with Row-Level Security (RLS) enforcement.
> 3. **Server-Side FCM Dispatch**: Dispatching push notifications to FCM is executed purely in the backend (Supabase Edge Function / Secure Server Process) where the Firebase Service Account is stored as an encrypted secret (`FIREBASE_SERVICE_ACCOUNT_JSON`).

---

## 3. Client-Side Implementation (Flutter)

### A. Source of Truth & Fallback Behavior
- The **in-app notification system** (`caregiver_notifications` table + Supabase Realtime + local caching) is the **single source of truth**.
- Push notification delivery is an **additional layer** designed to alert caregivers when their app is backgrounded or inactive.
- If Firebase is not configured (e.g. `google-services.json` has not been added yet, or running on desktop/offline), `CaregiverPushNotificationService` catches this gracefully and the application continues to run 100% normally with zero crashes or blockers.

### B. Lifecycle & Services
- **Service**: `CaregiverPushNotificationService` (`lib/features/caregiver/services/caregiver_push_notification_service.dart`)
- **Background Entrypoint**: `@pragma('vm:entry-point') Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message)`
- **Foreground Display**: `FlutterLocalNotificationsPlugin` displays high-importance heads-up banners on channel `nirvana_caregiver_alerts`.
- **Token Synchronization**: Automatically registers and updates the FCM device token in Supabase table `caregiver_push_tokens` upon login, and unregisters/deactivates it on logout.
- **Deep Linking**: Tapping a push notification automatically navigates the caregiver to `/caregiver/dashboard` and focuses on the associated patient and alert.

---

## 4. Setup Guide: Firebase & Android

### Step 1: Create a Firebase Project
1. Open the [Firebase Console](https://console.firebase.google.com/).
2. Create a project named `nirvana-care` (or use an existing project).
3. Add an **Android Application**:
   - **Android package name**: `com.nirvana.app.nirvana`
   - **App nickname**: `NIRVANA`
4. Download the generated `google-services.json` file.
5. Place `google-services.json` inside:
   ```
   android/app/google-services.json
   ```

### Step 2: Android Gradle Setup (Optional for native build)
If you wish to apply the Google Services Gradle plugin directly:
In `android/settings.gradle.kts`:
```kotlin
plugins {
    id("com.google.gms.google-services") version "4.4.2" apply false
}
```
In `android/app/build.gradle.kts`:
```kotlin
plugins {
    id("com.google.gms.google-services")
}
```

---

## 5. Setup Guide: Server-Side Backend Dispatch (Supabase Edge Function)

### Step 1: Generate Firebase Service Account Key
1. In Firebase Console, navigate to **Project Settings** > **Service accounts**.
2. Click **Generate new private key** and download the JSON file.

### Step 2: Set Supabase Secret
Using the Supabase CLI, upload the service account JSON as a secret:
```bash
supabase secrets set FIREBASE_SERVICE_ACCOUNT_JSON='{"type":"service_account","project_id":"...","private_key":"...","client_email":"..."}'
```

### Step 3: Deploy the Edge Function
Deploy the pre-built Edge Function in `supabase/functions/push-caregiver-notification/`:
```bash
supabase functions deploy push-caregiver-notification
```

### Step 4: Configure Database Webhook
In the Supabase Dashboard:
1. Navigate to **Database** > **Webhooks** > **Create a new webhook**.
2. **Name**: `on_caregiver_notification_insert`
3. **Table**: `public.caregiver_notifications`
4. **Events**: Check `INSERT`
5. **Type**: `Supabase Edge Function`
6. **Function**: `push-caregiver-notification`
7. Save the webhook.

---

## 6. Database Schema Summary

### Table: `public.caregiver_push_tokens`
```sql
CREATE TABLE public.caregiver_push_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    caregiver_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    fcm_token TEXT NOT NULL,
    device_platform TEXT NOT NULL DEFAULT 'android',
    device_name TEXT,
    is_active BOOLEAN NOT NULL DEFAULT true,
    last_used_at TIMESTAMPTZ DEFAULT TIMEZONE('utc', NOW()) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc', NOW()) NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT TIMEZONE('utc', NOW()) NOT NULL,
    CONSTRAINT uq_caregiver_fcm_token UNIQUE (caregiver_id, fcm_token)
);
```

### Security & RLS Policies
- `caregiver_push_tokens_select_own`: Caregiver can view only their registered tokens.
- `caregiver_push_tokens_insert_own`: Caregiver can insert their device token.
- `caregiver_push_tokens_update_own`: Caregiver can update token state.
- `caregiver_push_tokens_delete_own`: Caregiver can remove token.

---

## 7. Verification Checklist

- [x] `flutter analyze` runs with zero errors.
- [x] App starts up smoothly in offline mode without `google-services.json` present.
- [x] Zero service credentials committed in the repository or mobile client.
- [x] In-app notification system remains authoritative and responsive.
- [x] Full FCM lifecycle (permissions, token sync, foreground alerts, background handler, tap navigation) implemented.
