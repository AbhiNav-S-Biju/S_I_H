// ==============================================================================
// NIRVANA - 3D Claymorphic Scaffold Container
// ==============================================================================

import 'package:flutter/material.dart';
import 'clay_3d_decorations.dart';
import 'clay_3d_theme.dart';

class ClayScaffold3D extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final bool showAmbientDecorations;
  final bool showBottomWave;
  final bool showLeftCloud;
  final EdgeInsetsGeometry padding;

  const ClayScaffold3D({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.showAmbientDecorations = true,
    this.showBottomWave = true,
    this.showLeftCloud = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 18.0, vertical: 18.0),
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Clay3DTheme.canvas,
      appBar: appBar,
      bottomNavigationBar: bottomNavigationBar,
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          if (showAmbientDecorations)
            FloatingAmbient3DLayer(
              showBottomWave: showBottomWave,
              showLeftCloud: showLeftCloud,
            ),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: padding,
              child: body,
            ),
          ),
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
