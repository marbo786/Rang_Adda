import 'package:flutter/material.dart';
import '../theme.dart';

/// A pulsed glow animation that highlights a player as the trick/bluff winner.
/// Shows one pulse cycle (grows and fades out) over ~500ms.
class WinnerPulseGlow extends StatefulWidget {
  final bool show;

  const WinnerPulseGlow({
    super.key,
    required this.show,
  });

  @override
  State<WinnerPulseGlow> createState() => _WinnerPulseGlowState();
}

class _WinnerPulseGlowState extends State<WinnerPulseGlow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    if (widget.show) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(WinnerPulseGlow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.show && !oldWidget.show) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Pulse grows from 0 to 1.2x over 60% of animation, then fades out
        final pulseProgress = _controller.value;
        final scale = 1.0 + (pulseProgress * 0.4); // 1.0 to 1.4
        final opacity = 1.0 - (pulseProgress * pulseProgress); // Smooth fade

        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppTheme.accentPrimary.withValues(alpha: opacity),
              width: 4,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.accentPrimary.withValues(alpha: opacity * 0.6),
                blurRadius: 16 * pulseProgress,
                spreadRadius: 4 * pulseProgress,
              ),
            ],
          ),
          child: Transform.scale(
            scale: scale,
            child: const SizedBox(
              width: 64,
              height: 64,
            ),
          ),
        );
      },
    );
  }
}
