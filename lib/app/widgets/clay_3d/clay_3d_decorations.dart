// ==============================================================================
// NIRVANA - 3D Ambient Decorative Components
// ==============================================================================

import 'package:flutter/material.dart';
import 'clay_3d_painters.dart';
import 'clay_3d_theme.dart';

class FloatingAmbient3DLayer extends StatelessWidget {
  final bool showBottomWave;
  final bool showLeftCloud;

  const FloatingAmbient3DLayer({
    super.key,
    this.showBottomWave = true,
    this.showLeftCloud = true,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: true,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. Left Puffy Cloud under header/banner
          if (showLeftCloud)
            const Positioned(
              top: 260.0,
              left: -32.0,
              child: SizedBox(
                width: 80.0,
                height: 48.0,
                child: CustomPaint(
                  painter: ClayCloud3DPainter(
                    color: Clay3DTheme.lavenderLight,
                  ),
                ),
              ),
            ),

          // 2. Middle-Right Teal Kidney/Pebble
          const Positioned(
            top: 285.0,
            right: -15.0,
            child: SizedBox(
              width: 50.0,
              height: 38.0,
              child: CustomPaint(
                painter: ClayPebble3DPainter(
                  color: Clay3DTheme.tealLight,
                  tilt: 0.4,
                ),
              ),
            ),
          ),

          // 3. Middle-Right Coral Clay Pebble
          const Positioned(
            top: 335.0,
            right: 22.0,
            child: SizedBox(
              width: 28.0,
              height: 28.0,
              child: CustomPaint(
                painter: ClaySphere3DPainter(
                  color: Clay3DTheme.coralLight,
                ),
              ),
            ),
          ),

          // 4. Middle-Right Small Teal Drop Pebble
          const Positioned(
            top: 365.0,
            right: -8.0,
            child: SizedBox(
              width: 32.0,
              height: 24.0,
              child: CustomPaint(
                painter: ClayPebble3DPainter(
                  color: Clay3DTheme.tealLight,
                  tilt: -0.2,
                ),
              ),
            ),
          ),

          // 5. Lower-Left Coral Organic Blob
          const Positioned(
            top: 670.0,
            left: -20.0,
            child: SizedBox(
              width: 48.0,
              height: 70.0,
              child: CustomPaint(
                painter: ClayPebble3DPainter(
                  color: Clay3DTheme.coralLight,
                  tilt: 0.1,
                ),
              ),
            ),
          ),

          // 6. Bottom-Right 3D Wave Landscape + Gold Ribbon
          if (showBottomWave)
            const Positioned(
              bottom: -20.0,
              right: -20.0,
              child: SizedBox(
                width: 220.0,
                height: 220.0,
                child: CustomPaint(
                  painter: ClayWaveLandscape3DPainter(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
