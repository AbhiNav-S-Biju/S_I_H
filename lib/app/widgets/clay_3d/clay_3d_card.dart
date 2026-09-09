// ==============================================================================
// NIRVANA - 3D Tactile Card, Slab & Pill Widgets
// ==============================================================================

import 'package:flutter/material.dart';
import 'clay_3d_theme.dart';

/// 3D Raised Clay Container / Card
class ClayCard3D extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Color? color;
  final List<BoxShadow>? customShadows;
  final VoidCallback? onTap;

  const ClayCard3D({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18.0),
    this.borderRadius = 24.0,
    this.color,
    this.customShadows,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? Clay3DTheme.cardSurface,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: customShadows ?? Clay3DTheme.cardShadow(),
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: card,
      );
    }
    return card;
  }
}

/// 3D Raised Header / Title Slab
class ClaySlab3D extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color? color;

  const ClaySlab3D({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
    this.borderRadius = 16.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? Clay3DTheme.cardSurface,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: Clay3DTheme.cardShadow(blur: 10, offset: 4),
      ),
      child: child,
    );
  }
}

/// 3D Embossed / Inset Pill Badge
class ClayPill3D extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final double borderRadius;

  const ClayPill3D({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
    required this.color,
    this.borderRadius = 14.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            offset: const Offset(2, 2),
            blurRadius: 4,
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.40),
            offset: const Offset(-1.5, -1.5),
            blurRadius: 3,
          ),
        ],
      ),
      child: child,
    );
  }
}
