// ==============================================================================
// NIRVANA — Clay Surface (dual-shadow raised primitive)
// Description: The single building block behind every raised claymorphic
// surface on the patient dashboard. It guarantees the two-entry dual shadow
// (warm-white top-left highlight + warm-brown bottom-right ambient) that the
// claymorphism spec requires, and simulates an "inset" pressed state, which
// Flutter cannot express natively.
//
// Responsive / overflow rules applied here (see §3 of the dashboard spec):
//   * The surface NEVER fixes its own height. It wraps whatever child it is
//     given and lets that child's intrinsic height drive layout, so long or
//     font-scaled text grows the card instead of clipping.
//   * Radius is a parameter drawn from [NirvanaRadii]; cards use 18–26px and
//     small icon buttons use 14–20px. No widget hardcodes its own corner.
// ==============================================================================

import 'package:flutter/material.dart';

import '../../theme/elder_theme.dart';
import '../../theme/nirvana_responsive.dart';

/// A soft, puffy raised clay surface with an optional press-in interaction.
///
/// When [onTap] is supplied the surface darkens its shadow into a simulated
/// inset look on press (Flutter has no native `inset` box-shadow, so we swap
/// the raised dual shadow for [NirvanaShadows.clayPressed] and nudge the surface
/// down-right by 1px via an [AnimatedContainer] to sell the "pushed in" feel).
class ClaySurface extends StatefulWidget {
  /// Content laid out inside the raised surface. Height is intrinsic.
  final Widget child;

  /// Corner radius. Defaults to the shared card radius (24px).
  final double radius;

  /// Fill colour. Defaults to the cream clay surface — never pure white.
  final Color? color;

  /// Optional gradient fill (e.g. the purple Daily Moment card). When set it
  /// takes precedence over [color] and the surface is still shadow-raising.
  final Gradient? gradient;

  /// Tap handler. When null the surface is inert (no ripple, no press state).
  final VoidCallback? onTap;

  /// Semantics label announced to screen readers when tappable.
  final String? semanticLabel;

  /// Padding inside the surface. Defaults to a generous 20px so text has room.
  final EdgeInsetsGeometry padding;

  /// Shadow strength tuning passed straight through to the dual-shadow helper.
  final double shadowBlur;
  final double shadowOffset;

  /// Optional hairline border for high-contrast themes / busy backgrounds.
  final BorderSide? border;

  const ClaySurface({
    super.key,
    required this.child,
    this.radius = NirvanaRadii.card,
    this.color,
    this.gradient,
    this.onTap,
    this.semanticLabel,
    this.padding = const EdgeInsets.all(NirvanaSpacing.lg),
    this.shadowBlur = 16.0,
    this.shadowOffset = 6.0,
    this.border,
  });

  @override
  State<ClaySurface> createState() => _ClaySurfaceState();
}

class _ClaySurfaceState extends State<ClaySurface> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (!mounted || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final interactive = widget.onTap != null;
    final pressed = interactive && _pressed;

    final decoration = BoxDecoration(
      color: widget.gradient == null
          ? (widget.color ?? ElderColors.claySurface)
          : null,
      gradient: widget.gradient,
      borderRadius: BorderRadius.circular(widget.radius),
      border: widget.border == null
          ? null
          : Border.fromBorderSide(widget.border!),
      boxShadow: pressed
          ? NirvanaShadows.clayPressed()
          : NirvanaShadows.clayRaised(
              blur: widget.shadowBlur,
              offset: widget.shadowOffset,
            ),
    );

    Widget surface = AnimatedContainer(
      // Short, purposeful transition only — no decorative motion loops.
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      padding: widget.padding,
      decoration: decoration,
      // A 1px nudge down-right reinforces the inset illusion on press.
      transform: pressed
          ? (Matrix4.translationValues(1.0, 1.0, 0.0))
          : Matrix4.identity(),
      transformAlignment: Alignment.center,
      child: widget.child,
    );

    if (!interactive) return surface;

    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(widget.radius),
        child: InkWell(
          // Rounded to the same radius so the ripple never bleeds past the edge.
          borderRadius: BorderRadius.circular(widget.radius),
          onTap: widget.onTap,
          onTapDown: (_) => _setPressed(true),
          onTapUp: (_) => _setPressed(false),
          onTapCancel: () => _setPressed(false),
          splashColor: ElderColors.clayInk.withValues(alpha: 0.06),
          highlightColor: Colors.transparent,
          // The Ink lives INSIDE the surface so the press state and the ripple
          // share one rounded geometry.
          child: surface,
        ),
      ),
    );
  }
}
