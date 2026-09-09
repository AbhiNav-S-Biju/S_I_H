// ==============================================================================
// NIRVANA - 3D Claymorphic Volumetric Custom Painters
// ==============================================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'clay_3d_theme.dart';

/// Volumetric 3D Clay Heart Painter
class ClayHeart3DPainter extends CustomPainter {
  final Color color;

  const ClayHeart3DPainter({this.color = Clay3DTheme.lavender});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final shadowPath = Path();
    shadowPath.moveTo(w * 0.5, h * 0.85);
    shadowPath.cubicTo(w * 0.15, h * 0.55, w * 0.05, h * 0.25, w * 0.28, h * 0.15);
    shadowPath.cubicTo(w * 0.40, h * 0.10, w * 0.48, h * 0.25, w * 0.5, h * 0.35);
    shadowPath.cubicTo(w * 0.52, h * 0.25, w * 0.60, h * 0.10, w * 0.72, h * 0.15);
    shadowPath.cubicTo(w * 0.95, h * 0.25, w * 0.85, h * 0.55, w * 0.5, h * 0.85);

    canvas.drawPath(
      shadowPath.shift(const Offset(5, 7)),
      Paint()
        ..color = const Color(0xFF382A1E).withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    final heartPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.45),
        radius: 0.95,
        colors: [
          Colors.white.withValues(alpha: 0.95),
          color.withValues(alpha: 0.95),
          Color.lerp(color, const Color(0xFF6B58A0), 0.55)!,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawPath(shadowPath, heartPaint);

    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    canvas.drawPath(shadowPath, highlightPaint);
  }

  @override
  bool shouldRepaint(covariant ClayHeart3DPainter oldDelegate) => false;
}

/// Volumetric 3D Puffy Clay Cloud Painter
class ClayCloud3DPainter extends CustomPainter {
  final Color color;

  const ClayCloud3DPainter({this.color = Clay3DTheme.lavenderLight});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final spheres = [
      _CloudSphere(center: Offset(w * 0.32, h * 0.60), radius: h * 0.38),
      _CloudSphere(center: Offset(w * 0.52, h * 0.42), radius: h * 0.44),
      _CloudSphere(center: Offset(w * 0.72, h * 0.55), radius: h * 0.36),
      _CloudSphere(center: Offset(w * 0.88, h * 0.65), radius: h * 0.26),
    ];

    for (final s in spheres) {
      canvas.drawCircle(
        s.center + const Offset(4, 6),
        s.radius + 2,
        Paint()
          ..color = const Color(0xFF382A1E).withValues(alpha: 0.15)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }

    for (final s in spheres) {
      final rect = Rect.fromCircle(center: s.center, radius: s.radius);
      final paint = Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.4, -0.45),
          radius: 0.9,
          colors: [
            Colors.white.withValues(alpha: 0.90),
            color,
            Color.lerp(color, const Color(0xFF6B5A96), 0.40)!,
          ],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(rect);

      canvas.drawCircle(s.center, s.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant ClayCloud3DPainter oldDelegate) => false;
}

class _CloudSphere {
  final Offset center;
  final double radius;
  const _CloudSphere({required this.center, required this.radius});
}

/// Glossy 3D Clay Sphere Painter
class ClaySphere3DPainter extends CustomPainter {
  final Color color;

  const ClaySphere3DPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    canvas.drawCircle(
      center + const Offset(3, 4),
      radius,
      Paint()
        ..color = const Color(0xFF382A1E).withValues(alpha: 0.16)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );

    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.4, -0.45),
        radius: 0.85,
        colors: [
          Colors.white.withValues(alpha: 0.95),
          color,
          Color.lerp(color, Colors.black, 0.35)!,
        ],
        stops: const [0.0, 0.40, 1.0],
      ).createShader(rect);

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant ClaySphere3DPainter oldDelegate) => false;
}

/// Organic Oval 3D Clay Pebble Painter
class ClayPebble3DPainter extends CustomPainter {
  final Color color;
  final double tilt;

  const ClayPebble3DPainter({required this.color, this.tilt = 0.0});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(tilt);
    canvas.translate(-size.width / 2, -size.height / 2);

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(size.height * 0.5));

    canvas.drawRRect(
      rrect.shift(const Offset(4, 5)),
      Paint()
        ..color = const Color(0xFF382A1E).withValues(alpha: 0.16)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    final paint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.40),
        radius: 0.95,
        colors: [
          Colors.white.withValues(alpha: 0.92),
          color,
          Color.lerp(color, Colors.black, 0.32)!,
        ],
        stops: const [0.0, 0.42, 1.0],
      ).createShader(rect);

    canvas.drawRRect(rrect, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant ClayPebble3DPainter oldDelegate) => false;
}

/// 3D Glowing Star Painter
class ClayStar3DPainter extends CustomPainter {
  final Color color;

  const ClayStar3DPainter({this.color = Clay3DTheme.starYellow});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);

    canvas.drawCircle(
      center,
      w * 0.65,
      Paint()
        ..color = color.withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    final path = Path();
    const points = 5;
    final outerRadius = w * 0.45;
    final innerRadius = w * 0.20;

    for (int i = 0; i < points * 2; i++) {
      final radius = i.isEven ? outerRadius : innerRadius;
      final angle = (i * math.pi / points) - (math.pi / 2);
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    final paint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.3),
        colors: [
          Colors.white,
          color,
          const Color(0xFFE5A510),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant ClayStar3DPainter oldDelegate) => false;
}

/// 3D Wave Landscape & Gold Ribbon Painter
class ClayWaveLandscape3DPainter extends CustomPainter {
  const ClayWaveLandscape3DPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final wavePath = Path();
    wavePath.moveTo(w * 0.20, h);
    wavePath.cubicTo(w * 0.20, h * 0.65, w * 0.50, h * 0.60, w * 0.65, h * 0.45);
    wavePath.cubicTo(w * 0.80, h * 0.30, w * 0.90, h * 0.40, w, h * 0.30);
    wavePath.lineTo(w, h);
    wavePath.close();

    canvas.drawPath(
      wavePath.shift(const Offset(4, 6)),
      Paint()
        ..color = const Color(0xFF382A1E).withValues(alpha: 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    final wavePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFD6C8F5),
          Color(0xFFBAA7EC),
          Color(0xFF9E89D7),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawPath(wavePath, wavePaint);

    // Shiny 4-Point Sparkle
    _drawSparkle(canvas, Offset(w * 0.72, h * 0.60), 14.0);

    // 3D Glossy Gold Ribbon Tube
    final ribbonPath = Path();
    ribbonPath.moveTo(w * 0.35, h);
    ribbonPath.cubicTo(w * 0.40, h * 0.80, w * 0.60, h * 0.85, w * 0.75, h * 0.72);
    ribbonPath.cubicTo(w * 0.90, h * 0.60, w * 0.95, h * 0.80, w, h * 0.75);

    canvas.drawPath(
      ribbonPath.shift(const Offset(3, 4)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.20)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10.0
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    final ribbonPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFFFFF2A8),
          Color(0xFFE4BC50),
          Color(0xFFB88C22),
          Color(0xFFFFF2A8),
        ],
        stops: [0.0, 0.4, 0.8, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9.0
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(ribbonPath, ribbonPaint);

    // Floating Gold Egg
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.55, h * 0.50), width: 22, height: 18),
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.35, -0.40),
          colors: [Colors.white, Color(0xFFE5C067), Color(0xFF9E7B24)],
        ).createShader(Rect.fromLTWH(w * 0.45, h * 0.40, 22, 18)),
    );

    // Floating Coral Pebble
    canvas.drawCircle(
      Offset(w * 0.28, h * 0.52),
      12.0,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.35, -0.40),
          colors: [Colors.white, Color(0xFFF19E8E), Color(0xFFC55A48)],
        ).createShader(Rect.fromLTWH(w * 0.20, h * 0.45, 24, 24)),
    );

    // Floating Turquoise Pebble
    canvas.drawCircle(
      Offset(w * 0.15, h * 0.65),
      8.0,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.35, -0.40),
          colors: [Colors.white, Color(0xFF68C2BE), Color(0xFF287975)],
        ).createShader(Rect.fromLTWH(w * 0.10, h * 0.60, 16, 16)),
    );
  }

  void _drawSparkle(Canvas canvas, Offset center, double size) {
    final path = Path();
    path.moveTo(center.dx, center.dy - size);
    path.quadraticBezierTo(center.dx, center.dy, center.dx + size, center.dy);
    path.quadraticBezierTo(center.dx, center.dy, center.dx, center.dy + size);
    path.quadraticBezierTo(center.dx, center.dy, center.dx - size, center.dy);
    path.quadraticBezierTo(center.dx, center.dy, center.dx, center.dy - size);
    path.close();

    canvas.drawPath(
      path,
      Paint()..color = Colors.white.withValues(alpha: 0.90),
    );
  }

  @override
  bool shouldRepaint(covariant ClayWaveLandscape3DPainter oldDelegate) => false;
}
