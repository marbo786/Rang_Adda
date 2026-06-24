import 'package:rang_adda/shared/models/card_model.dart';
import 'package:rang_adda/shared/ai/card_tracker.dart';

/// A lightweight Monte Carlo utility for simulating random hand distributions.
class MonteCarloSimulator {
  /// Distributes remaining unseen cards randomly to opponents, respecting known void suits.
  /// Note: This is an approximation and might not find a perfect distribution
  /// if constraints are extremely tight, but it is fast enough for ~50 playouts.
  static Map<String, List<PlayingCard>> distributeCards(
    CardTracker tracker,
    Map<String, int> opponentCardCounts,
  ) {
    final unseenCards = List<PlayingCard>.from(tracker.unseenCards)..shuffle();
    final distribution = <String, List<PlayingCard>>{};

    for (final id in opponentCardCounts.keys) {
      distribution[id] = [];
    }

    for (final card in unseenCards) {
      // Find an opponent who needs a card and is not void in this suit.
      // We iterate through shuffled opponents to distribute somewhat evenly.
      final eligibleOpponents = opponentCardCounts.keys.where((id) {
        final needsCards = distribution[id]!.length < opponentCardCounts[id]!;
        final isNotVoid = !tracker.isPlayerVoid(id, card.suit);
        return needsCards && isNotVoid;
      }).toList()..shuffle();

      if (eligibleOpponents.isNotEmpty) {
        distribution[eligibleOpponents.first]!.add(card);
      }
    }

    return distribution;
  }
}
