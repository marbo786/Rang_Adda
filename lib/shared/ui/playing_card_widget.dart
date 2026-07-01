import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:rang_adda/shared/models/card_model.dart';
import 'package:rang_adda/shared/ui/theme.dart';

class PlayingCardWidget extends StatelessWidget {
  final PlayingCard card;
  final bool isFaceUp;
  final double width;
  final double height;
  final bool hasShadow;

  const PlayingCardWidget({
    super.key,
    required this.card,
    this.isFaceUp = true,
    this.width = 60,
    this.height = 90,
    this.hasShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      switchInCurve: Curves.easeOutBack,
      switchOutCurve: Curves.easeInBack,
      transitionBuilder: (Widget child, Animation<double> animation) {
        final rotateAnim = Tween(begin: math.pi, end: 0.0).animate(animation);
        return AnimatedBuilder(
          animation: rotateAnim,
          child: child,
          builder: (context, widget) {
            final isUnder = (ValueKey(isFaceUp) != widget!.key);
            final value = isUnder
                ? math.min(rotateAnim.value, math.pi / 2)
                : rotateAnim.value;
            return Transform(
              transform: Matrix4.rotationY(value)..setEntry(3, 0, 0.001),
              alignment: Alignment.center,
              child: widget,
            );
          },
        );
      },
      child: isFaceUp ? _buildFaceUp() : _buildFaceDown(),
    );
  }

  Widget _buildFaceDown() {
    return Container(
      key: const ValueKey(false),
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF3A5068), width: 1.5),
        boxShadow: hasShadow
            ? [
                BoxShadow(
                  color: AppTheme.neonGlow,
                  blurRadius: 10,
                  spreadRadius: 1,
                  offset: const Offset(0, 2),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.8),
                  blurRadius: 6,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.5),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.05),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.2),
                  ],
                ),
              ),
            ),
            Center(
              child: Text(
                '♠',
                style: TextStyle(
                  color: const Color(0xFF00FF88).withValues(alpha: 0.15),
                  fontSize: width * 0.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaceUp() {
    final isRed = card.suit == Suit.hearts || card.suit == Suit.diamonds;
    final color = isRed ? const Color(0xFFFF4D6A) : Colors.white;
    final borderColor = const Color(0xFF3A5068);
    final glowColor = isRed
        ? AppTheme.statusError.withValues(alpha: 0.25)
        : AppTheme.neonGlow;

    String suitSymbol;
    switch (card.suit) {
      case Suit.hearts:
        suitSymbol = '♥';
        break;
      case Suit.diamonds:
        suitSymbol = '♦';
        break;
      case Suit.clubs:
        suitSymbol = '♣';
        break;
      case Suit.spades:
        suitSymbol = '♠';
        break;
    }

    String rankSymbol;
    switch (card.rank) {
      case Rank.ace:
        rankSymbol = 'A';
        break;
      case Rank.jack:
        rankSymbol = 'J';
        break;
      case Rank.queen:
        rankSymbol = 'Q';
        break;
      case Rank.king:
        rankSymbol = 'K';
        break;
      default:
        rankSymbol = '${card.rank.index + 1}';
        break;
    }

    return Container(
      key: const ValueKey(true),
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF1E2D3D),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: hasShadow
            ? [BoxShadow(color: glowColor, blurRadius: 6, spreadRadius: 0)]
            : null,
      ),
      child: Stack(
        children: [
          // Clean Center Symbol Watermark
          Center(
            child: Text(
              suitSymbol,
              style: TextStyle(
                color: color.withValues(alpha: 0.18),
                fontSize: width * 0.533,
              ),
            ),
          ),

          // Top Left Rank and Suit
          Positioned(
            top: height * 0.066,
            left: width * 0.133,
            child: Column(
              children: [
                Text(
                  rankSymbol,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: width * 0.3,
                    height: 1.0,
                  ),
                ),
                Text(
                  suitSymbol,
                  style: TextStyle(
                    color: color,
                    fontSize: width * 0.233,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),

          // Bottom Right Rank and Suit (mirrored)
          Positioned(
            bottom: height * 0.066,
            right: width * 0.133,
            child: Transform.rotate(
              angle: math.pi,
              child: Column(
                children: [
                  Text(
                    rankSymbol,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w800,
                      fontSize: width * 0.3,
                      height: 1.0,
                    ),
                  ),
                  Text(
                    suitSymbol,
                    style: TextStyle(
                      color: color,
                      fontSize: width * 0.233,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
