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
    if (!isFaceUp) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFF0F2335),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFF00FF88).withValues(alpha: 0.30),
            width: 1.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12.5),
          child: CustomPaint(
            painter: _CardBackPainter(),
          ),
        ),
      );
    }

    final isRed = card.suit == Suit.hearts || card.suit == Suit.diamonds;
    final color = isRed ? const Color(0xFFFF4D6A) : Colors.white;
    final borderColor = const Color(0xFF3A5068);
    final glowColor = isRed ? AppTheme.statusError.withValues(alpha: 0.25) : AppTheme.neonGlow;

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
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF1E2D3D),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: borderColor,
          width: 1.5,
        ),
        boxShadow: hasShadow ? [
          BoxShadow(
            color: glowColor,
            blurRadius: 6,
            spreadRadius: 0,
          ),
        ] : null,
      ),
      child: Stack(
        children: [
          // Clean Center Symbol Watermark
          Center(
            child: Text(
              suitSymbol,
              style: TextStyle(
                color: color.withValues(alpha: 0.18),
                fontSize: 32,
              ),
            ),
          ),
          
          // Top Left Rank and Suit
          Positioned(
            top: 6,
            left: 8,
            child: Column(
              children: [
                Text(
                  rankSymbol,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                Text(
                  suitSymbol,
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                  )
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CardBackPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00FF88).withValues(alpha: 0.12)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    final double width = size.width;
    final double height = size.height;
    final double step = 15.0;

    // Draw diamond pattern lines
    for (double i = -height; i < width + height; i += step) {
      canvas.drawLine(Offset(i, 0), Offset(i + height, height), paint);
      canvas.drawLine(Offset(i, height), Offset(i + height, 0), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
