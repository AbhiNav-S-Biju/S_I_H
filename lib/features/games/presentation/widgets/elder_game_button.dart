// ==============================================================================
// NIRVANA - ElderGameButton Widget
// Description: Large, high-contrast, accessible touch target button (min 64dp)
// ==============================================================================

import 'package:flutter/material.dart';

class ElderGameButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double minHeight;
  final bool isSecondary;

  const ElderGameButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.minHeight = 64.0,
    this.isSecondary = false,
  });

  @override
  Widget build(BuildContext context) {
    final defaultBg = isSecondary
        ? const Color(0xFFF1F5F9)
        : const Color(0xFF0F766E); // Deep calming teal
    final defaultFg = isSecondary
        ? const Color(0xFF0F172A)
        : Colors.white;

    final bg = backgroundColor ?? defaultBg;
    final fg = foregroundColor ?? defaultFg;

    return Semantics(
      button: true,
      label: label,
      enabled: onPressed != null,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: minHeight,
          minWidth: 140.0,
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: bg,
            foregroundColor: fg,
            disabledBackgroundColor: const Color(0xFFE2E8F0),
            disabledForegroundColor: const Color(0xFF94A3B8),
            elevation: isSecondary ? 0 : 3,
            shadowColor: Colors.black26,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
              side: BorderSide(
                color: isSecondary ? const Color(0xFFCBD5E1) : Colors.transparent,
                width: 2.0,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          ),
          onPressed: onPressed,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 28.0, color: fg),
                const SizedBox(width: 12.0),
              ],
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
