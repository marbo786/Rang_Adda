import 'package:flutter/material.dart';
import 'package:rang_adda/shared/ui/theme.dart';

/// A reusable background widget that gives game screens depth through
/// a radial gradient and subtle vignette effect.
/// 
/// Uses the existing theme colors (backgroundPrimary/Secondary) with
/// derived lighter/darker variants to create visual depth.
class GameTableBackground extends StatelessWidget {
  final Widget child;

  const GameTableBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // Derive lighter variant of backgroundSecondary for radial gradient center glow
    // Original: 0xFF171A21 (23, 26, 33) -> Lighter: ~(50, 55, 75) for subtle glow
    const Color centerGlow = Color(0xFF323749);

    // Vignette overlay: semi-transparent dark with slight blue tint
    const Color vignetteColor = Color(0x66000000);

    return Container(
      decoration: BoxDecoration(
        // Main radial gradient: center glow to outer darkness
        gradient: RadialGradient(
          center: const Alignment(0, 0),
          radius: 1.0,
          colors: [
            centerGlow,
            AppTheme.backgroundSecondary,
            AppTheme.backgroundPrimary,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: Stack(
        children: [
          child,
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
                      vignetteColor,
                    ],
                    stops: const [0.0, 0.6, 1.0],
                  ),
                  borderRadius: BorderRadius.zero,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
