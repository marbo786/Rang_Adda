import 'package:flutter/material.dart';
import 'package:rang_adda/shared/models/card_model.dart';

class PlayingCardWidget extends StatelessWidget {
  final PlayingCard card;
  final bool isFaceUp;
  final double width;
  final double height;

  const PlayingCardWidget({
    super.key,
    required this.card,
    this.isFaceUp = true,
    this.width = 60,
    this.height = 90,
  });

  @override
  Widget build(BuildContext context) {
    if (!isFaceUp) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Icon(
            Icons.style,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            size: 32,
          ),
        ),
      );
    }

    final isRed = card.suit == Suit.hearts || card.suit == Suit.diamonds;
    // Red color from theme error status, Black is white text
    final color = isRed ? Theme.of(context).colorScheme.error : Colors.white;

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
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Top Left Small Indicator
          Positioned(
            top: 8,
            left: 10,
            child: Column(
              children: [
                Text(
                  rankSymbol,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
                Text(suitSymbol, style: TextStyle(color: color, fontSize: 14)),
              ],
            ),
          ),

          // Clean Center Symbol
          Center(
            child: Text(
              suitSymbol,
              style: TextStyle(
                color: color.withValues(alpha: 0.7),
                fontSize: 32,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
