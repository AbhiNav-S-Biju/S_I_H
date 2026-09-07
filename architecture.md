# NIRVANA - System Architecture Specification

## 1. Executive Summary & Core Philosophy

**NIRVANA** is an offline-first mobile application tailored specifically for elderly users, including individuals living with mild-to-moderate cognitive changes or dementia, along with a connected Caregiver Dashboard.

### Strict Safety & Ethical Mandates
1. **Non-Clinical Guarantee**: The application **does not** diagnose dementia, estimate cognitive impairment stages, evaluate disease progression, or provide medical/treatment advice.
2. **Metric Transparency**: All metrics are strictly framed as **"Non-Clinical Activity & Engagement Summaries"** (e.g., participation consistency, completed activities, daily streaks), never "Cognitive Health", "Brain Age", or "Memory Scores".
3. **Privacy & Biometric Protection**: No facial recognition, biometric identity scanning, or patient personally identifiable information (PII) is transmitted to third-party or external Large Language Model (LLM) APIs.
4. **Offline-First Sovereignty**: Core features—including engagement games, daily reminder notifications, family photo albums, and activity logging—function 100% reliably without an active internet connection.

---

## 2. High-Level Architecture Pattern

NIRVANA is built using **Clean Feature-Based Layered Architecture** with strict unidirectional data flow.

```
┌─────────────────────────────────────────────────────────┐
│                    Presentation Layer                   │
│  ┌───────────────────────┐   ┌───────────────────────┐  │
│  │   Elder UI Widgets    │   │ Caregiver UI Widgets  │  │
│  │ (Large touch, simple) │   │ (Metrics, management) │  │
│  └───────────▲───────────┘   └───────────▲───────────┘  │
│              │                           │              │
│              └─────────────┬─────────────┘              │
│                            │ (watch/read State)         │
│             ┌──────────────▼──────────────┐             │
│             │  Riverpod Notifiers/State   │             │
│             └──────────────┬──────────────┘             │
└────────────────────────────┼────────────────────────────┘
                             │ (calls domain logic / repos)
┌────────────────────────────▼────────────────────────────┐
│                      Domain Layer                       │
│  ┌───────────────────────────────────────────────────┐  │
│  │  Entities, Value Objects, Enums, Interfaces       │  │
│  │  Pure Dart - zero UI / framework dependencies     │  │
│  └───────────────────────────────────────────────────┘  │
└────────────────────────────┬────────────────────────────┘
                             │
┌────────────────────────────▼────────────────────────────┐
│                    Repository Layer                     │
│  ┌───────────────────────────────────────────────────┐  │
│  │  Unified Repository Abstractions                  │  │
│  │  (Reads local Hive; writes local + enqueues sync) │  │
│  └─────────────┬───────────────────────────┬─────────┘  │
└────────────────┼───────────────────────────┼────────────┘
                 │                           │
┌────────────────▼──────────┐ ┌──────────────▼────────────┐
│     Local Data Source     │ │    Remote Data Source     │
│  ┌─────────────────────┐  │ │  ┌─────────────────────┐  │
│  │ Hive Boxes          │  │ │  │ Supabase PostgreSQL │  │
│  │ - profiles          │  │ │  │ - RLS Policies      │  │
│  │ - game_sessions     │  │ │  │ - Profiles/Patients │  │
│  │ - reminders/logs    │  │ │  │ - Sessions/Photos   │  │
│  │ - family_photos     │  │ │  │ Supabase Storage    │  │
│  │ - sync_queue        │  │ │  │ Supabase Auth       │  │
│  └─────────────────────┘  │ │  └─────────────────────┘  │
└───────────────────────────┘ └───────────────────────────┘
```

---

## 3. Layer Separation Rules & Constraints

### 3.1 Presentation Layer (`/presentation`)
- **Elder UI Principles**:
  - High visual contrast (WCAG AAA compliant color ratios).
  - Minimum touch target dimension: 64x64 dp (far exceeding standard 48 dp).
  - Minimum text size: 18sp for body, 24sp-32sp for headings.
  - Zero cluttered menus; max 2–3 primary actions per screen.
  - Supportive, compassionate microcopy with no aggressive timers or red failure indicators.
  - Low-motion default (respects system reduce-motion settings and app-level toggle).
- **Caregiver Dashboard**:
  - Clear weekly/monthly engagement graphs (activity consistency, reminder completion rate).
  - Management interfaces for configuring patient reminders, uploading family photos with audio notes, and configuring elder mode.
- **Rule**: Presentation widgets **must never** communicate directly with Hive, Supabase, or platform channels. All interaction occurs through Riverpod `StateNotifier` / `AsyncNotifier` controllers.

### 3.2 Domain Layer (`/domain`)
- Contains immutable models (using `@freezed` or standard Dart immutable classes).
- Contains repository contracts (abstract classes).
- Contains business rules (e.g., game progression algorithms, reminder recurrence math, engagement calculation).
- Free from any third-party persistence or UI libraries.

### 3.3 Data Layer (`/data`)
- Implements repository interfaces defined in the domain layer.
- **Local-First Write Strategy**:
  1. Write transaction executed directly to local Hive storage.
  2. Emit updated state immediately to reactive local streams.
  3. Formulate an immutable `SyncEvent` record.
  4. Write `SyncEvent` with status `pending` to local `sync_events` box.
  5. Trigger background sync worker via `SyncService` if network is connected.
- **Remote Data Source**:
  - Supabase client wrapper interacting with PostgreSQL and Supabase Storage.
  - Handles network timeouts gracefully, allowing sync worker to retry with exponential backoff.

### 3.4 Platform Services Layer (`/services`)
- **NotificationService**: Wraps `flutter_local_notifications` for offline local scheduling of medicine and daily reminders.
- **ConnectivityService**: Wraps `connectivity_plus` with reactive stream broadcasting online/offline transitions.
- **AudioService**: Handles gentle encouraging audio prompts and family voice notes.
- **StorageService**: Manages local caching of cached family photo files and thumbnail generation.

---

## 4. State Management Architecture (Riverpod 2.x)

```dart
// Dependency Injection Hierarchy
// 1. Core Services
final connectivityServiceProvider = Provider<ConnectivityService>((ref) => ConnectivityService());
final localStorageServiceProvider = Provider<LocalStorageService>((ref) => LocalStorageService());

// 2. Data Sources & Repositories
final gameRepositoryProvider = Provider<GameRepository>((ref) {
  return GameRepositoryImpl(
    localSource: ref.read(gameLocalDataSourceProvider),
    syncQueue: ref.read(syncQueueRepositoryProvider),
  );
});

// 3. Presentation State Notifiers
final rememberObjectsGameControllerProvider = 
    StateNotifierProvider.autoDispose<RememberObjectsController, RememberObjectsState>((ref) {
  return RememberObjectsController(
    gameRepository: ref.read(gameRepositoryProvider),
  );
});
```

---

## 5. Security & Privacy Architecture

1. **Supabase Row Level Security (RLS)**:
   - Authenticated JWT tokens define the acting user (`auth.uid()`).
   - Explicit relational RLS policies enforce that a caregiver can only query/mutate patient records explicitly linked to their caregiver ID via `caregiver_patient_links`.
   - Elder devices operating in standalone offline mode use local cryptographic device tokens before pairing with a caregiver account.
2. **Zero Plaintext Secrets**:
   - Supabase `anon` key only inside Flutter client builds.
   - `service_role` keys are strictly forbidden and never embedded into mobile/desktop binaries.
3. **Local Storage Encryption / Sandboxing**:
   - Hive boxes are stored in protected application documents directory sandboxed by Android/iOS/Windows OS permission boundaries.

---

## 6. Multi-Platform Support Strategy
- **Android**: Target SDK 34, Min SDK 24 (covers Android 7.0+ devices). Optimized for tablets and large display phones. Exact alarm scheduling permissions (`SCHEDULE_EXACT_ALARM`) for robust offline notifications.
- **Windows**: Native desktop support with responsive layout breakpoints (`LayoutBuilder`) allowing full keyboard and mouse accessibility, high DPI scaling, and local notification integration.
- **iOS / Web**: Compatible clean codebase prepared for multi-platform expansion.
