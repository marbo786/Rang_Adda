import 'package:rang_adda/shared/models/card_model.dart';
import 'package:rang_adda/shared/ai/bot_observation.dart';
import 'package:rang_adda/shared/ai/card_tracker.dart';
import 'thulla_bot.dart';

class ThullaBotHard extends ThullaBot {
  final CardTracker _tracker = CardTracker();
  final int _tricksPlayed = 0;

  ThullaBotHard(super.personality);

  @override
  PlayingCard chooseCard(ThullaBotObservation obs) {
    _updateTracker(obs);

    final validCards = List<PlayingCard>.from(_getValidCards(obs));
    // Wrap in List.from() so we always have a mutable copy — obs.myHand is
    // an unmodifiable list and calling .sort() on it directly throws
    // "Unsupported operation: sort" on the web/JS runtime.
    validCards.sort((a, b) => _rankValue(a.rank).compareTo(_rankValue(b.rank)));

    if (obs.currentTrick.isEmpty) {
      // Leading. We want to lead a suit where someone else MUST follow and ideally has a higher card.
      // But we don't know exactly what they have, except from probabilities.
      // Easiest heuristic: lead a low card in a suit where we know someone is NOT void.
      final safeValidCards = validCards
          .where((c) => !(c.suit == Suit.spades && c.rank == Rank.ace))
          .toList();

      if (safeValidCards.isNotEmpty) {
        // Try to find a suit where we hold a low card, and opponents are unlikely to be void.
        for (final card in safeValidCards) {
          bool anyOpponentVoid = false;
          for (final oppId in obs.opponentCardCounts.keys) {
            if (_tracker.isPlayerVoid(oppId, card.suit)) {
              anyOpponentVoid = true;
              break;
            }
          }
          if (!anyOpponentVoid) {
            return card; // Lead this safe low card
          }
        }
        // Fallback: just play our absolute lowest card
        return safeValidCards.first;
      }
      return validCards.first;
    }

    final leadSuit = obs.leadSuit;

    // Following suit
    if (leadSuit != null && validCards.any((c) => c.suit == leadSuit)) {
      // If we are the LAST player in the trick, and no one played higher than our highest valid card,
      // we might be forced to win. But we can play the highest possible card that is STILL LOWER than
      // the current highest in the trick to avoid winning while getting rid of a high card.

      int currentHighestRank = -1;
      for (final play in obs.currentTrick) {
        if (play.card.suit == leadSuit) {
          final val = _rankValue(play.card.rank);
          if (val > currentHighestRank) currentHighestRank = val;
        }
      }

      // Find cards lower than the current highest
      final lowerCards = validCards
          .where((c) => _rankValue(c.rank) < currentHighestRank)
          .toList();

      if (lowerCards.isNotEmpty) {
        // Play the highest card that is still lower than the winning card (shedding high card safely).
        return lowerCards.last;
      }

      // If we MUST win (all our valid cards are higher), or if no one played a high card yet:
      // Just play our lowest to minimize future damage.
      return validCards.first;
    }

    // We can't follow suit! (Tochoo opportunity).
    // Discard the absolute highest card we have.
    return validCards.last;
  }

  void _updateTracker(ThullaBotObservation obs) {
    if (obs.isFirstTrick && obs.currentTrick.isEmpty && _tricksPlayed == 0) {
      _tracker.initializeMyHand(obs.myHand);
    }

    for (final play in obs.currentTrick) {
      _tracker.markCardSeen(play.card);
      if (obs.leadSuit != null && play.card.suit != obs.leadSuit) {
        // Tochoo! This player is void in the lead suit.
        _tracker.markVoidSuit(play.playerId, obs.leadSuit!);
      }
    }

    for (final card in obs.wastePile) {
      _tracker.markCardSeen(card);
    }
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
