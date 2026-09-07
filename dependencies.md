# NIRVANA - Dependencies Specification

## 1. Core Framework & State Management
- `flutter`: SDK
- `flutter_riverpod: ^2.6.1`: Modern, testable state management and dependency injection without BuildContext reliance.
- `riverpod_annotation: ^2.6.1`: Compile-time code generation for providers and notifiers.
- `go_router: ^14.8.1`: Declarative routing with deep linking and route guards for Elder vs Caregiver modes.

## 2. Local Storage & Offline Database
- `hive: ^2.2.3`: Fast, lightweight synchronous key-value NoSQL database.
- `hive_flutter: ^1.1.0`: Flutter extensions for box lifecycle and reactive value listenables.
- `path_provider: ^2.1.5`: Cross-platform document and cache directory access.

## 3. Remote Backend & Cloud Persistence
- `supabase_flutter: ^2.8.4`: Official Supabase client for PostgreSQL, Auth, Storage, and RPC execution.

## 4. Connectivity, Scheduling & Platform Integration
- `connectivity_plus: ^6.1.3`: Real-time network state monitoring for sync triggering.
- `flutter_local_notifications: ^18.0.1`: Exact local scheduled notifications for medications, hydration, and daily activities without internet.
- `timezone: ^0.10.0`: Exact timezone-aware scheduling for local notifications.
- `audioplayers: ^6.1.2`: Gentle audio playback for voice prompts, familiar cues, and calming interaction sounds.
- `uuid: ^4.5.1`: RFC4122 v4 UUID generator for local entity IDs and sync event IDs.
- `intl: ^0.20.2`: Date/time formatting and multi-language localization.

## 5. UI, Accessibility & Icons
- `flutter_animate: ^4.5.2`: Subtle, controllable, low-motion-friendly micro-interactions.
- `google_fonts: ^6.2.1`: High-legibility typography designed for accessibility (e.g. Lexend / Plus Jakarta Sans).
- `lucide_icons: ^0.257.0` or `material_symbols_icons`: Large, visually distinct iconography with high contrast.
- `fl_chart: ^0.70.2`: Clean, simple non-clinical charts for the Caregiver Dashboard.

## 6. Dev Dependencies & Code Generation
- `build_runner: ^2.4.15`: Build tool for generating type adapters and riverpod files.
- `hive_generator: ^2.0.1`: Generator for HiveType and HiveField adapters.
- `riverpod_generator: ^2.6.4`: Generator for Riverpod providers.
- `flutter_lints: ^5.0.0`: Recommended lint rules for Flutter & Dart.
- `mocktail: ^1.0.4`: Mocking library for repository and service unit testing.
