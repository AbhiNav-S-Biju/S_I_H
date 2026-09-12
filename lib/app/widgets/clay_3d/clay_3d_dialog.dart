// ==============================================================================
// NIRVANA — 3D Claymorphic Dialog Helpers
// Description: Centralised, responsive dialog styling so every confirmation /
// information dialog in the app shares the same clay look, large touch targets
// and non-overflowing layout (scrollable body, wrapping action buttons).
// ==============================================================================

import 'package:flutter/material.dart';
import '../../theme/elder_theme.dart';
import 'clay_3d_theme.dart';

/// Rounded clay shape shared by all dialogs.
ShapeBorder clayDialogShape() => RoundedRectangleBorder(
  borderRadius: BorderRadius.circular(NirvanaRadii.card),
);

/// Responsive inset padding for dialogs — keeps dialogs off the screen edges on
/// every device size and leaves room for large fonts.
EdgeInsets clayDialogInsets(BuildContext context) {
  final w = MediaQuery.sizeOf(context).width;
  return EdgeInsets.symmetric(
    horizontal: w < 380 ? 16.0 : 28.0,
    vertical: 24.0,
  );
}

/// Shows a standard clay information / confirmation dialog.
Future<T?> showClayDialog<T>({
  required BuildContext context,
  required String title,
  String? message,
  Widget? content,
  IconData? icon,
  Color? iconColor,
  String? confirmLabel,
  String? cancelLabel,
  VoidCallback? onConfirm,
  bool barrierDismissible = true,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (dialogContext) {
      final theme = Theme.of(dialogContext);
      return AlertDialog(
        backgroundColor: ElderColors.surface,
        shape: clayDialogShape(),
        insetPadding: clayDialogInsets(dialogContext),
        contentPadding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 8.0),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Container(
                width: 72.0,
                height: 72.0,
                decoration: BoxDecoration(
                  color: (iconColor ?? ElderColors.primary).withValues(
                    alpha: 0.14,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: Clay3DTheme.cardShadow(blur: 10, offset: 4),
                ),
                alignment: Alignment.center,
                child: Icon(
                  icon,
                  size: 38.0,
                  color: iconColor ?? ElderColors.primary,
                ),
              ),
              const SizedBox(height: 16.0),
            ],
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: ElderColors.textPrimary,
              ),
            ),
          ],
        ),
        content:
            content ??
            (message != null
                ? SingleChildScrollView(
                    child: Text(
                      message,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: ElderColors.textSecondary,
                      ),
                    ),
                  )
                : null),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(16.0, 4.0, 16.0, 16.0),
        actions: [
          if (cancelLabel != null)
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: TextButton.styleFrom(
                minimumSize: const Size(96.0, 52.0),
                foregroundColor: ElderColors.textSecondary,
                textStyle: const TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: Text(cancelLabel),
            ),
          if (confirmLabel != null)
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                onConfirm?.call();
              },
              style: FilledButton.styleFrom(
                minimumSize: const Size(96.0, 52.0),
                backgroundColor: ElderColors.primary,
                foregroundColor: Colors.white,
                textStyle: const TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.w800,
                ),
              ),
              child: Text(confirmLabel),
            ),
        ],
      );
    },
  );
}
