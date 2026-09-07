# NIRVANA - Folder Structure Specification

The project follows a **Feature-First Clean Architecture**:

```
lib/
├── main.dart                          # App entry point, Hive init, service registration
├── app.dart                           # NirvanaApp widget, theme, router binding
│
├── core/                              # Shared cross-feature infrastructure
│   ├── constants/
│   │   ├── app_colors.dart            # High-contrast WCAG AAA elder color system
│   │   ├── app_dimensions.dart        # 64dp min touch targets, typography scales
│   │   ├── app_strings.dart           # Non-clinical approved wording dictionary
│   │   └── hive_constants.dart        # Box names, adapter type IDs
│   ├── localization/                  # Multi-language string catalogs
│   ├── router/
│   │   ├── app_router.dart            # GoRouter definition with mode guards
│   │   └── route_paths.dart           # Route string constants
│   ├── services/
│   │   ├── audio_service.dart         # Sound effects and voice note player
│   │   ├── connectivity_service.dart  # Reactive network status stream
│   │   ├── notification_service.dart  # Offline local notification scheduler
│   │   └── storage_service.dart       # Local photo caching and file paths
│   ├── theme/
│   │   ├── elder_theme.dart           # High-contrast, large-scale typography theme
│   │   └── caregiver_theme.dart       # Modern clean dashboard theme
│   └── widgets/                       # Reusable accessible UI primitives
│       ├── elder_app_bar.dart         # High-contrast accessible top bar
│       ├── elder_button.dart          # 64dp+ large touch target button
│       ├── elder_card.dart            # Tactile high-contrast card
│       ├── mode_switch_banner.dart    # Discreet mode toggle for caregiver
│       └── non_clinical_badge.dart    # Mandatory non-clinical disclaimer badge
│
├── features/
│   ├── onboarding/                    # First-run elder vs caregiver mode selection
│   │   ├── presentation/
│   │   └── controllers/
│   │
│   ├── home/                          # Elder home screen (Max 2-3 primary actions)
│   │   ├── presentation/
│   │   └── controllers/
│   │
│   ├── games/                         # Cognitive engagement activities
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── game_session.dart  # Non-clinical session record
│   │   │   └── repositories/
│   │   │       └── game_repository.dart
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   └── game_session_model.dart # Hive TypeAdapter
│   │   │   └── repositories/
│   │   │       └── game_repository_impl.dart
│   │   ├── presentation/
│   │   │   ├── remember_objects/      # Game 1: Remember Objects
│   │   │   ├── who_is_this/           # Game 2: Who Is This?
│   │   │   ├── grocery_memory/        # Game 3: Grocery Memory
│   │   │   └── widgets/               # Encouragement banners, gentle progress
│   │   └── controllers/
│   │
│   ├── reminders/                     # Medicine, water, activity alarms
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── reminder.dart
│   │   │   │   └── reminder_log.dart
│   │   │   └── repositories/
│   │   │       └── reminder_repository.dart
│   │   ├── data/
│   │   │   ├── models/
│   │   │   └── repositories/
│   │   ├── presentation/
│   │   │   ├── elder_reminder_dialog.dart
│   │   │   └── reminder_list_screen.dart
│   │   └── controllers/
│   │
│   ├── family_album/                  # Photos of family with voice notes
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── family_photo.dart
│   │   │   └── repositories/
│   │   │       └── family_photo_repository.dart
│   │   ├── data/
│   │   ├── presentation/
│   │   └── controllers/
│   │
│   ├── caregiver/                     # Caregiver dashboard & patient management
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── activity_summary.dart
│   │   │   └── repositories/
│   │   │       └── caregiver_repository.dart
│   │   ├── presentation/
│   │   │   ├── dashboard_screen.dart
│   │   │   ├── manage_reminders_screen.dart
│   │   │   ├── manage_photos_screen.dart
│   │   │   └── widgets/
│   │   │       └── non_clinical_activity_chart.dart
│   │   └── controllers/
│   │
│   ├── sync/                          # Offline-first sync engine
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── sync_event.dart
│   │   │   └── repositories/
│   │   │       └── sync_repository.dart
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   ├── sync_local_datasource.dart
│   │   │   │   └── sync_remote_datasource.dart
│   │   │   └── repositories/
│   │   │       └── sync_repository_impl.dart
│   │   └── services/
│   │       └── sync_engine.dart       # Background worker, FIFO queue processor
│   │
│   └── settings/                      # Accessibility, font size, audio, mode switch
│       ├── domain/
│       ├── presentation/
│       └── controllers/
│
└── supabase/                          # Backend migration scripts & DDL
    ├── schema.sql                     # Full schema DDL
    └── rls_policies.sql               # Security policies
```
