import 'dart:math';
import 'package:rang_adda/shared/models/card_model.dart';
import 'package:rang_adda/shared/ai/bot_observation.dart';
import 'thulla_bot.dart';

class ThullaBotEasy extends ThullaBot {
  final _random = Random();

  ThullaBotEasy(super.personality);

  @override
  PlayingCard chooseCard(ThullaBotObservation obs) {
    // Wrap in List.from() so we always have a mutable copy — obs.myHand is
    // an unmodifiable list and calling .sort() on it directly throws
    // "Unsupported operation: sort" on the web/JS runtime.
    final validCards = List<PlayingCard>.from(_getValidCards(obs));

    // Easy bot just picks a random valid card.
    // Occasionally (30% of the time) it will deliberately pick the highest valid card,
    // which is a bad strategy in Thulla (since you want to avoid winning tricks).
    if (_random.nextDouble() < 0.3) {
      validCards.sort(
        (a, b) => _rankValue(b.rank).compareTo(_rankValue(a.rank)),
      );
      return validCards.first;
    }

    return validCards[_random.nextInt(validCards.length)];
  }

  // A helper method to derive valid cards from the observation.
  // This mirrors the validation logic in ThullaEngine.
  List<PlayingCard> _getValidCards(ThullaBotObservation obs) {
    if (obs.currentTrick.isEmpty) {
      if (obs.isFirstTrick) {
        // Must play Ace of Spades if they have it
        final aceSpades = obs.myHand.where(
          (c) => c.suit == Suit.spades && c.rank == Rank.ace,
        );
        if (aceSpades.isNotEmpty) return aceSpades.toList();
      }
      return obs.myHand;
    }

    final leadSuit = obs.leadSuit;
    if (leadSuit != null) {
      final matchingSuitCards = obs.myHand
          .where((c) => c.suit == leadSuit)
          .toList();
      if (matchingSuitCards.isNotEmpty) {
        return matchingSuitCards;
      }
    }
    return obs.myHand;
  }

  int _rankValue(Rank rank) {
    if (rank == Rank.ace) return 14;
    return rank.index + 1;
  }
}
