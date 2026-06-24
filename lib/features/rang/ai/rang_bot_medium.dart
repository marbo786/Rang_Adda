import 'package:rang_adda/shared/models/card_model.dart';
import 'package:rang_adda/shared/ai/bot_observation.dart';
import 'rang_bot.dart';

class RangBotMedium extends RangBot {
  RangBotMedium(super.personality);

  @override
  Suit chooseTrump(RangBotObservation obs) {
    // Choose the suit we have the most of, or highest value of.
    final counts = <Suit, int>{};
    for (final card in obs.myHand) {
      counts[card.suit] = (counts[card.suit] ?? 0) + 1;
    }

    Suit bestSuit = Suit.spades;
    int maxCount = -1;
    for (final suit in counts.keys) {
      if (counts[suit]! > maxCount) {
        maxCount = counts[suit]!;
        bestSuit = suit;
      }
    }
    return bestSuit;
  }

  @override
  PlayingCard chooseCard(RangBotObservation obs) {
    final validCards = _getValidCards(obs);
    validCards.sort((a, b) => _rankValue(a.rank).compareTo(_rankValue(b.rank)));

    if (obs.currentTrick.isEmpty) {
      // Leading: Play a high card of a non-trump suit to try to win,
      // or a trump card if we want to draw out trumps.
      // For medium: just play highest card.
      return validCards.last;
    }

    final leadSuit = obs.leadSuit;

    if (leadSuit != null && validCards.any((c) => c.suit == leadSuit)) {
      // Following suit:
      // If we can win the trick, play the lowest card that wins.
      // Otherwise, play our lowest card.

      int currentHighestRank = -1;
      for (final play in obs.currentTrick) {
        if (play.card.suit == leadSuit) {
          final val = _rankValue(play.card.rank);
          if (val > currentHighestRank) currentHighestRank = val;
        } else if (play.card.suit == obs.trumpSuit) {
          // Someone trumped it! We can't win by following suit.
          currentHighestRank = 999;
        }
      }

      final winningCards = validCards
          .where((c) => _rankValue(c.rank) > currentHighestRank)
          .toList();
      if (winningCards.isNotEmpty) {
        return winningCards.first; // Lowest winning card
      }

      return validCards.first; // Throw lowest
    }

    // We can't follow suit! We can cut with Trump.
    final trumpCards = validCards
        .where((c) => c.suit == obs.trumpSuit)
        .toList();
    if (trumpCards.isNotEmpty) {
      // Cut with lowest trump
      return trumpCards.first;
    }

    // No trump, just discard lowest
    return validCards.first;
  }

  List<PlayingCard> _getValidCards(RangBotObservation obs) {
    if (obs.currentTrick.isEmpty) {
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
