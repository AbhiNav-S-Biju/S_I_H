// ==============================================================================
// NIRVANA - 3D Claymorphic Scaffold Container
// ==============================================================================

import 'package:flutter/material.dart';
import '../../theme/nirvana_responsive.dart';
import 'clay_3d_decorations.dart';
import 'clay_3d_theme.dart';

class ClayScaffold3D extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final bool showAmbientDecorations;
  final bool showBottomWave;
  final bool showLeftCloud;
  final EdgeInsetsGeometry? padding;

  /// When false the [body] manages its own scrolling (list/grid views).
  final bool scrollable;

  /// Clamp body to a readable width on wide screens.
  final double? maxContentWidth;

  const ClayScaffold3D({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.showAmbientDecorations = true,
    this.showBottomWave = true,
    this.showLeftCloud = true,
    this.padding,
    this.scrollable = true,
    this.maxContentWidth,
  });

  @override
  Widget build(BuildContext context) {
    final effectivePadding = padding ?? NirvanaSpacing.page(context);

    Widget content = body;
    if (maxContentWidth != null) {
      content = Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxContentWidth!),
          child: content,
        ),
      );
    }

    if (scrollable) {
      content = SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: effectivePadding,
        child: content,
      );
    }

    return Scaffold(
      backgroundColor: Clay3DTheme.canvas,
      appBar: appBar,
      bottomNavigationBar: bottomNavigationBar,
      body: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          if (showAmbientDecorations)
            FloatingAmbient3DLayer(
              showBottomWave: showBottomWave,
              showLeftCloud: showLeftCloud,
            ),
          SafeArea(child: content),
        ],
      ),
    );
  }
}

/// Adds the shared clay atmosphere to layouts that manage their own scrolling.
class ClayBackdrop3D extends StatelessWidget {
  final Widget child;
  final bool showAmbientDecorations;

  const ClayBackdrop3D({
    super.key,
    required this.child,
    this.showAmbientDecorations = true,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Clay3DTheme.canvas,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (showAmbientDecorations) const FloatingAmbient3DLayer(),
          child,
        ],
      ),
    );
  }
}
