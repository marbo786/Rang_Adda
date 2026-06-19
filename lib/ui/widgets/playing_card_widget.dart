import 'package:flutter/material.dart';
import '../../core/models/card_model.dart';

class PlayingCardWidget extends StatelessWidget {
  final PlayingCard card;
  final bool isFaceUp;
  final double width;
  final double height;

  const PlayingCardWidget({
    Key? key,
    required this.card,
    this.isFaceUp = true,
    this.width = 60,
    this.height = 90,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!isFaceUp) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondary,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white24),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
        ),
        child: const Center(
          child: Icon(Icons.style, color: Colors.white54),
        ),
      );
    }

    final isRed = card.suit == Suit.hearts || card.suit == Suit.diamonds;
    final color = isRed ? Colors.redAccent : Colors.white;

    String suitSymbol;
    switch (card.suit) {
      case Suit.hearts: suitSymbol = '♥'; break;
      case Suit.diamonds: suitSymbol = '♦'; break;
      case Suit.clubs: suitSymbol = '♣'; break;
      case Suit.spades: suitSymbol = '♠'; break;
    }

    String rankSymbol;
    switch (card.rank) {
      case Rank.ace: rankSymbol = 'A'; break;
      case Rank.jack: rankSymbol = 'J'; break;
      case Rank.queen: rankSymbol = 'Q'; break;
      case Rank.king: rankSymbol = 'K'; break;
      default: rankSymbol = '${card.rank.index + 1}'; break;
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(2, 2))],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 4,
            left: 6,
            child: Column(
              children: [
                Text(rankSymbol, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
                Text(suitSymbol, style: TextStyle(color: color, fontSize: 14)),
              ],
            ),
          ),
          Center(
            child: Text(suitSymbol, style: TextStyle(color: color.withOpacity(0.3), fontSize: 36)),
          ),
        ],
      ),
    );
  }
}
