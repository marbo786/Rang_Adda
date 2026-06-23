import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:rang_adda/shared/ui/theme.dart';
import 'package:rang_adda/shared/models/card_model.dart';
import 'package:rang_adda/shared/ui/playing_card_widget.dart';

class RoundTableWidget extends StatefulWidget {
  final List<String> playerNames;
  final List<String> playerIds;
  final int activePlayerIndex;
  final List<int> cardCounts;
  final String? trumpSuit;
  final double size;
  final Map<String, PlayingCard?> currentTrickPlays;

  const RoundTableWidget({
    super.key,
    required this.playerNames,
    required this.playerIds,
    required this.activePlayerIndex,
    required this.cardCounts,
    required this.currentTrickPlays,
    this.trumpSuit,
    this.size = 280,
  });

  @override
  State<RoundTableWidget> createState() => _RoundTableWidgetState();
}

class _RoundTableWidgetState extends State<RoundTableWidget> with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late Animation<double> _rotation;
  double _currentAngle = 0.0;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _currentAngle = _calculateTargetAngle(widget.activePlayerIndex);
    _rotation = AlwaysStoppedAnimation(_currentAngle);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut);
  }

  @override
  void didUpdateWidget(RoundTableWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.activePlayerIndex != oldWidget.activePlayerIndex ||
        widget.playerNames.length != oldWidget.playerNames.length) {
      double target = _calculateTargetAngle(widget.activePlayerIndex);
      double diff = (target - _currentAngle) % (2 * math.pi);
      if (diff > math.pi) diff -= 2 * math.pi;
      if (diff < -math.pi) diff += 2 * math.pi;

      double newAngle = _currentAngle + diff;
      _rotation = Tween<double>(begin: _currentAngle, end: newAngle).animate(
        CurvedAnimation(parent: _rotationController, curve: Curves.easeInOutCubic),
      );
      _currentAngle = newAngle;
      _rotationController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  double _calculateTargetAngle(int activeIndex) {
    int n = widget.playerNames.length;
    if (n == 0) return 0.0;
    double playerAngle = -math.pi / 2 + (2 * math.pi / n) * activeIndex;
    return math.pi / 2 - playerAngle;
  }

  Color _getSuitColor(String suit) {
    if (suit == '♥' || suit == '♦') {
      return AppTheme.statusError;
    }
    return AppTheme.textPrimary;
  }

  @override
  Widget build(BuildContext context) {
    int n = widget.playerNames.length;
    if (n == 0) return SizedBox(width: widget.size, height: widget.size);

    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentPrimary.withValues(alpha: 0.15),
            blurRadius: 20,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Layer 1 - Table surface
          CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _TableSurfacePainter(),
          ),

          // Layer 2 & 3 - Rotating player ring
          AnimatedBuilder(
            animation: _rotation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotation.value,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ...List.generate(n, (i) {
                      double angle = -math.pi / 2 + (2 * math.pi / n) * i;
                      double radius = widget.size / 2 * 0.55;
                      double x = radius * math.cos(angle);
                      double y = radius * math.sin(angle);
                      String playerId = i < widget.playerIds.length ? widget.playerIds[i] : '';
                      PlayingCard? playedCard = widget.currentTrickPlays[playerId];

                      return Transform.translate(
                        offset: Offset(x, y),
                        child: Transform.rotate(
                          angle: -_rotation.value,
                          child: AnimatedOpacity(
                            opacity: playedCard != null ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 200),
                            child: playedCard != null
                                ? PlayingCardWidget(
                                    card: playedCard,
                                    isFaceUp: true,
                                    width: widget.size * 0.1,
                                    height: widget.size * 0.14,
                                  )
                                : SizedBox(width: widget.size * 0.1, height: widget.size * 0.14),
                          ),
                        ),
                      );
                    }),
                    ...List.generate(n, (i) {
                    double angle = -math.pi / 2 + (2 * math.pi / n) * i;
                    double radius = widget.size / 2 * 0.78;
                    double x = radius * math.cos(angle);
                    double y = radius * math.sin(angle);

                    bool isActive = i == widget.activePlayerIndex;
                    String name = widget.playerNames[i];
                    int cards = i < widget.cardCounts.length ? widget.cardCounts[i] : 0;
                    String initials = name.isNotEmpty
                        ? name.trim().split(' ').map((s) => s.isNotEmpty ? s[0] : '').take(2).join('').toUpperCase()
                        : '?';

                    return Transform.translate(
                      offset: Offset(x, y),
                      child: Transform.rotate(
                        angle: -_rotation.value, // Counter-rotation
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeOutCubic,
                              width: isActive ? widget.size * 0.15 : widget.size * 0.11,
                              height: isActive ? widget.size * 0.15 : widget.size * 0.11,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.surfaceElevated,
                                border: Border.all(
                                  color: isActive
                                      ? AppTheme.accentPrimary.withValues(alpha: 0.6)
                                      : AppTheme.textDisabled.withValues(alpha: 0.3),
                                  width: 2,
                                ),
                                boxShadow: isActive
                                    ? [
                                        BoxShadow(
                                          color: AppTheme.neonGlow,
                                          blurRadius: 12,
                                          spreadRadius: 2,
                                        )
                                      ]
                                    : null,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                initials,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: isActive ? 16 : 12,
                                  color: isActive ? AppTheme.accentPrimary : AppTheme.textSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '✦ $cards',
                              style: TextStyle(
                                color: isActive ? AppTheme.accentSecondary : AppTheme.textDisabled,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            SizedBox(
                              width: 60,
                              child: Text(
                                name,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: isActive ? 11 : 9,
                                  color: isActive ? AppTheme.textPrimary : AppTheme.textDisabled,
                                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            );
          },
          ),

          // Layer 4 - Center badge
          if (widget.trumpSuit != null)
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.surfaceElevated,
                    border: Border.all(
                      color: AppTheme.accentTertiary,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accentTertiary.withValues(alpha: 0.4 * _pulseAnimation.value),
                        blurRadius: 12,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.trumpSuit!,
                        style: TextStyle(
                          fontSize: 20,
                          height: 1.0,
                          color: _getSuitColor(widget.trumpSuit!),
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'TRUMP',
                        style: TextStyle(
                          color: AppTheme.accentTertiary,
                          fontSize: 8,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _TableSurfacePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    double radius = size.width / 2;
    Offset center = Offset(radius, radius);

    // Deep green felt
    final feltPaint = Paint()
      ..shader = RadialGradient(
        colors: [const Color(0xFF1A2D1A), const Color(0xFF0A1A0A)],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, feltPaint);

    // Spokes
    final spokePaint = Paint()
      ..color = AppTheme.accentPrimary.withValues(alpha: 0.04)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 8; i++) {
      double angle = i * math.pi / 4;
      canvas.drawLine(
        center,
        Offset(center.dx + radius * math.cos(angle), center.dy + radius * math.sin(angle)),
        spokePaint,
      );
    }

    // Inner dashed ring
    final dashPaint = Paint()
      ..color = AppTheme.accentPrimary.withValues(alpha: 0.08)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    
    double innerRadius = radius * 0.9;
    double dashWidth = 4.0;
    double dashSpace = 4.0;
    double circumference = 2 * math.pi * innerRadius;
    int dashCount = (circumference / (dashWidth + dashSpace)).floor();
    for (int i = 0; i < dashCount; i++) {
      double startAngle = (i * (dashWidth + dashSpace)) / innerRadius;
      double sweepAngle = dashWidth / innerRadius;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: innerRadius),
        startAngle,
        sweepAngle,
        false,
        dashPaint,
      );
    }
    
    // Outer rim border gradient
    final rimPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          AppTheme.accentPrimary.withValues(alpha: 0.4),
          AppTheme.accentSecondary.withValues(alpha: 0.2),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    
    canvas.drawCircle(center, radius - 1.25, rimPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
