// ==============================================================================
// NIRVANA - Location Help Confirmation Dialog
// Description: Simple, senior-friendly confirmation dialog for starting location sharing.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:nirvana/app/theme/elder_theme.dart';

class LocationHelpConfirmationDialog extends StatelessWidget {
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const LocationHelpConfirmationDialog({
    super.key,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Share Your Location?',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w900,
          color: ElderColors.textPrimary,
        ),
      ),
      content: const Text(
        'This will share your live location with your caregiver for up to 30 minutes. '
        'They will be able to see where you are on a map and call you directly.',
        style: TextStyle(
          fontSize: 18,
          color: ElderColors.textSecondary,
          height: 1.4,
        ),
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          style: TextButton.styleFrom(
            foregroundColor: ElderColors.textSecondary,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
          child: const Text(
            'Cancel',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
        FilledButton(
          onPressed: onConfirm,
          style: FilledButton.styleFrom(
            backgroundColor: ElderColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
          child: const Text(
            'Yes, Share Location',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }
}

// ==============================================================================
// Permission Rationale Dialog
// ==============================================================================

class LocationPermissionRationaleDialog extends StatelessWidget {
  final VoidCallback onOpenSettings;
  final VoidCallback onCancel;

  const LocationPermissionRationaleDialog({
    super.key,
    required this.onOpenSettings,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.location_on_rounded, size: 28, color: ElderColors.primary),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Location Permission Needed',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: ElderColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
      content: const Text(
        'To share your location with your caregiver, this app needs access to your device\'s location. '
        'Please allow location access in the next prompt.',
        style: TextStyle(
          fontSize: 18,
          color: ElderColors.textSecondary,
          height: 1.4,
        ),
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          style: TextButton.styleFrom(
            foregroundColor: ElderColors.textSecondary,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
          child: const Text(
            'Not Now',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
        FilledButton(
          onPressed: onOpenSettings,
          style: FilledButton.styleFrom(
            backgroundColor: ElderColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
          child: const Text(
            'Allow Location',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }
}