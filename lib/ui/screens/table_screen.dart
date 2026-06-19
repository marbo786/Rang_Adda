import 'package:flutter/material.dart';
import '../../core/models/card_model.dart';
import '../widgets/playing_card_widget.dart';

class TableScreen extends StatelessWidget {
  final String gameType;

  const TableScreen({super.key, required this.gameType});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${gameType.toUpperCase()} Table')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Welcome to $gameType', style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 40),
            const Text(
              'Sample Cards:',
              style: TextStyle(color: Colors.white54),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                PlayingCardWidget(
                  card: PlayingCard(suit: Suit.spades, rank: Rank.ace),
                ),
                SizedBox(width: 10),
                PlayingCardWidget(
                  card: PlayingCard(suit: Suit.hearts, rank: Rank.king),
                ),
                SizedBox(width: 10),
                PlayingCardWidget(
                  card: PlayingCard(suit: Suit.clubs, rank: Rank.seven),
                  isFaceUp: false,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
