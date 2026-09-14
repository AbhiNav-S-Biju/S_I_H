// ==============================================================================
// NIRVANA - Session Restore Gate
// Description: Bridges Riverpod authentication/session state to a
// [Listenable] so GoRouter can re-evaluate its redirect the moment the
// persisted Supabase session (caregiver) or Hive pairing session (patient)
// finishes restoring on startup.
//
// Why this exists:
//   `CaregiverAuthNotifier` starts with `AsyncValue.data(null)` and restores
//   the persisted session asynchronously. If the router only read the auth
//   state once, an authenticated user reopening the app would briefly (or
//   permanently) see the Welcome screen. This gate exposes:
//     * `isRestoring`  -> while true, the router shows the splash and does not
//                        route to Welcome.
//     * a change notification -> every time the auth state changes, so the
//                        redirect runs again and lands on the correct
//                        dashboard.
// ==============================================================================

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/caregiver/providers/caregiver_providers.dart';

/// A [Listenable] that fires whenever the caregiver/auth session state changes,
/// suitable for `GoRouter.refreshListenable`.
///
/// Delegates to the [CaregiverAuthNotifier.sessionRevision] `ValueNotifier`, so
/// the router re-runs its redirect deterministically on every transition —
/// including the restore-finished event where the resulting value is `null`
/// (which a plain `AsyncValue` state change would not reliably surface).
final sessionRefreshListenableProvider = Provider<Listenable>((ref) {
  final notifier = ref.read(caregiverAuthProvider.notifier);
  return notifier.sessionRevision;
});
