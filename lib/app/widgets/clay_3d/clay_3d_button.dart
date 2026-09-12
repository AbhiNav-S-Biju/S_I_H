// ==============================================================================
// NIRVANA - 3D Tactile Action Button
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'clay_3d_theme.dart';

class ClayButton3D extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Color color;
  final Color textColor;
  final double minHeight;
  final double borderRadius;
  final bool isLoading;

  const ClayButton3D({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
    this.color = Clay3DTheme.lavender,
    this.textColor = Clay3DTheme.textLight,
    this.minHeight = 56.0,
    this.borderRadius = 22.0,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = !isLoading && onPressed != null;
    return Semantics(
      button: true,
      enabled: isEnabled,
      label: label,
      child: GestureDetector(
        onTap: isEnabled ? onPressed : null,
        child: Container(
          constraints: BoxConstraints(minHeight: minHeight),
          padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
          decoration: BoxDecoration(
            color: isEnabled ? color : color.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: Clay3DTheme.buttonShadow(tint: color),
          ),
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: textColor,
                      strokeWidth: 2.5,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 24, color: textColor),
                        const SizedBox(width: 10),
                      ],
                      Flexible(
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.nunito(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: textColor,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
