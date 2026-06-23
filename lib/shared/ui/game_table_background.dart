import 'package:flutter/material.dart';
import 'package:rang_adda/shared/ui/theme.dart';

class GameTableBackground extends StatelessWidget {
  final Widget child;

  const GameTableBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.backgroundPrimary,
      child: Stack(
        children: [
          // Grid layer
          Positioned.fill(
            child: CustomPaint(painter: _PerspectiveGridPainter()),
          ),
          // Glow layer
          Positioned.fill(
            child: IgnorePointer(
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      backgroundBlendMode: BlendMode.screen,
                      gradient: RadialGradient(
                        center: const Alignment(0, 0),
                        radius: 0.8,
                        colors: [
                          AppTheme.accentPrimary.withValues(alpha: 0.06),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      backgroundBlendMode: BlendMode.screen,
                      gradient: RadialGradient(
                        center: const Alignment(0, -0.2),
                        radius: 0.5,
                        colors: [
                          AppTheme.accentSecondary.withValues(alpha: 0.04),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Child content
          child,
          // Vignette layer
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, 0),
                    radius: 1.2,
                    colors: [
                      Colors.transparent,
                      Colors.transparent,
                      AppTheme.backgroundPrimary.withValues(alpha: 0.5),
                    ],
                    stops: const [0.0, 0.7, 1.0],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PerspectiveGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.accentPrimary.withValues(alpha: 0.04)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final double width = size.width;
    final double height = size.height;

    // Draw horizontal perspective lines
    // Make them get closer together towards the top
    for (int i = 0; i <= 20; i++) {
      double t = i / 20.0;
      double y = height * (t * t); // Perspective scaling
      canvas.drawLine(Offset(0, y), Offset(width, y), paint);
    }

    // Draw vertical radiating lines
    final double vanishingPointY = -height * 0.5;
    final double vanishingPointX = width * 0.5;

    for (int i = -10; i <= 10; i++) {
      double x = width * 0.5 + (i * width * 0.15);
      canvas.drawLine(
        Offset(vanishingPointX, vanishingPointY),
        Offset(x, height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
