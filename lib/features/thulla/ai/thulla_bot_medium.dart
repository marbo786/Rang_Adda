import 'package:rang_adda/shared/models/card_model.dart';
import 'package:rang_adda/shared/ai/bot_observation.dart';
import 'thulla_bot.dart';

class ThullaBotMedium extends ThullaBot {
  ThullaBotMedium(super.personality);

  @override
  PlayingCard chooseCard(ThullaBotObservation obs) {
    // Wrap in List.from() so we always have a mutable copy — obs.myHand is
    // an unmodifiable list and calling .sort() on it directly throws
    // "Unsupported operation: sort" on the web/JS runtime.
    final validCards = List<PlayingCard>.from(_getValidCards(obs));

    // Sort cards ascending by rank.
    validCards.sort((a, b) => _rankValue(a.rank).compareTo(_rankValue(b.rank)));

    if (obs.currentTrick.isEmpty) {
      // We are leading.
      // Avoid leading the Ace of Spades if we have other valid cards.
      final safeValidCards = List<PlayingCard>.from(
        validCards.where((c) => !(c.suit == Suit.spades && c.rank == Rank.ace)),
      );

      if (safeValidCards.isNotEmpty) {
        // Lead the lowest card of our shortest suit to shed it early.
        final suitCounts = <Suit, int>{};
        for (final card in obs.myHand) {
          suitCounts[card.suit] = (suitCounts[card.suit] ?? 0) + 1;
        }
        safeValidCards.sort((a, b) {
          int countDiff = (suitCounts[a.suit] ?? 0).compareTo(
            suitCounts[b.suit] ?? 0,
          );
          if (countDiff != 0) return countDiff;
          return _rankValue(a.rank).compareTo(_rankValue(b.rank));
        });
        return safeValidCards.first;
      }
      return validCards.first;
    }

    final leadSuit = obs.leadSuit;

    // Following suit: Play the lowest card to try not to win the trick.
    if (leadSuit != null && validCards.any((c) => c.suit == leadSuit)) {
      return validCards.first;
    }

    // We can't follow suit! We get to discard (Tochoo).
    // Discard our highest card. (Sorted ascending, so pick the last).
    // Medium bot might consider aggressiveness, but generally shedding highest is best.
    return validCards.last;
  }

  List<PlayingCard> _getValidCards(ThullaBotObservation obs) {
    if (obs.currentTrick.isEmpty) {
      if (obs.isFirstTrick) {
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
