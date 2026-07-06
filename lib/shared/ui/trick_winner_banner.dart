import 'package:flutter/material.dart';
import 'package:rang_adda/shared/ui/theme.dart';

/// Animated banner that slides down from above and fades in when a trick
/// resolves, then fades out before the engine resolves the trick.
///
/// Entry : slide-down + fade-in, 250 ms, easeOutCubic
/// Exit  : fade-out only,        200 ms, easeIn
class TrickWinnerBanner extends StatefulWidget {
  final String winnerName;
  final bool isTochoo;
  final bool visible;

  const TrickWinnerBanner({
    super.key,
    required this.winnerName,
    required this.isTochoo,
    required this.visible,
  });

  @override
  State<TrickWinnerBanner> createState() => _TrickWinnerBannerState();
}

class _TrickWinnerBannerState extends State<TrickWinnerBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250), // entry
      reverseDuration: const Duration(milliseconds: 200), // exit
    );

    _opacity = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeIn,
    );

    _slide =
        Tween<Offset>(
          begin: const Offset(0, -1.0), // starts fully above
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeIn,
          ),
        );

    if (widget.visible) _controller.forward();
  }

  @override
  void didUpdateWidget(TrickWinnerBanner old) {
    super.didUpdateWidget(old);
    if (widget.visible && !old.visible) {
      _controller.forward();
    } else if (!widget.visible && old.visible) {
      // Only use the reverse animation (fade-out, 200 ms easeIn)
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _opacity,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.accentPrimary.withValues(alpha: 0.4),
              width: 1.5,
            ),
            boxShadow: [BoxShadow(color: AppTheme.neonGlow, blurRadius: 16)],
          ),
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 18,
                letterSpacing: 1.0,
              ),
              children: widget.isTochoo
                  ? [
                      const TextSpan(
                        text: '🃏  THULLA!',
                        style: TextStyle(
                          color: AppTheme.accentPrimary,
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ]
                  : [
                      const TextSpan(text: '👑  '),
                      TextSpan(
                        text: widget.winnerName,
                        style: const TextStyle(
                          color: AppTheme.accentPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const TextSpan(text: ' is Senior'),
                    ],
            ),
          ),
        ),
      ),
    );
  }
}
