// ==============================================================================
// NIRVANA - Help Flow Controller (Patient)
// Description: Orchestrates the patient's "I'm Lost / I Need Help" journey.
//
//   1. Show a simple yes/no confirmation dialog.
//   2. On confirm, request location permission.
//   3. Start the session and open the live sharing screen.
//
// Kept as a plain function (not a widget) so it can be triggered from the home
// screen without adding navigation state.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/location_help_providers.dart';
import 'location_help_confirmation_dialog.dart';
import 'location_sharing_active_screen.dart';

/// Runs the confirm -> permission -> share sequence.
///
/// Returns true when a session is live and the sharing screen was opened.
Future<bool> startHelpFlow(BuildContext context, WidgetRef ref) async {
  final notifier = ref.read(locationHelpProvider.notifier);

  // ---------------------------------------------------------------------------
  // 1. Confirmation — deliberately simple, two clear choices.
  // ---------------------------------------------------------------------------
  final confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => LocationHelpConfirmationDialog(
      onCancel: () => Navigator.of(dialogContext).pop(false),
      onConfirm: () => Navigator.of(dialogContext).pop(true),
    ),
  );

  if (confirmed != true) return false;
  if (!context.mounted) return false;

  // ---------------------------------------------------------------------------
  // 2 & 3. Permission, then start. The notifier reports failures through state.
  // ---------------------------------------------------------------------------
  await notifier.confirmAndStart();

  if (!context.mounted) return false;

  final state = ref.read(locationHelpProvider);

  if (!state.isActive) {
    // Permission refused, device unpaired, or offline — explain in plain terms.
    if (state.permissionDeniedForever) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => LocationPermissionRationaleDialog(
          onCancel: () => Navigator.of(dialogContext).pop(),
          onOpenSettings: () {
            Navigator.of(dialogContext).pop();
            ref.read(locationServiceProvider).openAppSettings();
          },
        ),
      );
    } else if (state.errorMessage != null) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text(
            'Could not start',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          content: Text(
            state.errorMessage!,
            style: const TextStyle(fontSize: 18, height: 1.4),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(
                'OK',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      );
    }
    notifier.clearError();
    return false;
  }

  // ---------------------------------------------------------------------------
  // 4. Open the live sharing screen.
  // ---------------------------------------------------------------------------
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => const LocationSharingActiveScreen(),
      fullscreenDialog: true,
    ),
  );

  return true;
}
