import 'package:rang_adda/shared/models/card_model.dart';
import 'package:rang_adda/shared/ai/bot_observation.dart';
import 'package:rang_adda/shared/ai/card_tracker.dart';
import 'rang_bot.dart';

class RangBotHard extends RangBot {
  final CardTracker _tracker = CardTracker();

  RangBotHard(super.personality);

  @override
  Suit chooseTrump(RangBotObservation obs) {
    // Choose the suit we have the most of, taking into account high cards.
    final counts = <Suit, int>{};
    final highCards = <Suit, int>{};

    for (final card in obs.myHand) {
      counts[card.suit] = (counts[card.suit] ?? 0) + 1;
      if (_rankValue(card.rank) >= 11) {
        // Jack or higher
        highCards[card.suit] = (highCards[card.suit] ?? 0) + 1;
      }
    }

    Suit bestSuit = Suit.spades;
    double maxScore = -1;
    for (final suit in counts.keys) {
      // Score = quantity + (high cards * 1.5)
      double score = counts[suit]! + ((highCards[suit] ?? 0) * 1.5);
      if (score > maxScore) {
        maxScore = score;
        bestSuit = suit;
      }
    }
    return bestSuit;
  }

  @override
  PlayingCard chooseCard(RangBotObservation obs) {
    _updateTracker(obs);

    final validCards = _getValidCards(obs);
    validCards.sort((a, b) => _rankValue(a.rank).compareTo(_rankValue(b.rank)));

    if (obs.currentTrick.isEmpty) {
      // Leading.
      // If we hold top trumps and trumps are not exhausted, draw them out.
      // Otherwise lead a high off-suit card.
      return validCards.last; // Simple fallback for now
    }

    final leadSuit = obs.leadSuit;

    if (leadSuit != null && validCards.any((c) => c.suit == leadSuit)) {
      // Following suit
      int currentHighestRank = -1;
      String? currentWinner;

      for (final play in obs.currentTrick) {
        if (play.card.suit == leadSuit && currentHighestRank != 999) {
          final val = _rankValue(play.card.rank);
          if (val > currentHighestRank) {
            currentHighestRank = val;
            currentWinner = play.playerId;
          }
        } else if (play.card.suit == obs.trumpSuit) {
          int trumpVal = _rankValue(play.card.rank);
          // 999 offset to indicate it's a trump winning
          if (currentHighestRank < 999 ||
              (trumpVal + 999 > currentHighestRank)) {
            currentHighestRank = trumpVal + 999;
            currentWinner = play.playerId;
          }
        }
      }

      // If partner is currently winning, throw a low card (unless it's insecure).
      if (currentWinner == obs.partnerId) {
        return validCards.first;
      }

      // Partner is not winning. We must try to win if we can.
      final winningCards = validCards.where((c) {
        if (c.suit == leadSuit) {
          return _rankValue(c.rank) > currentHighestRank &&
              currentHighestRank < 999;
        } else if (c.suit == obs.trumpSuit) {
          return (_rankValue(c.rank) + 999) > currentHighestRank;
        }
        return false;
      }).toList();

      if (winningCards.isNotEmpty) {
        return winningCards.first; // Lowest winning card
      }

      return validCards.first; // Throw lowest
    }

    // We can't follow suit! We can cut with Trump.
    final trumpCards = validCards
        .where((c) => c.suit == obs.trumpSuit)
        .toList();

    // Check if partner is already winning
    bool partnerWinning = false;
    // ... logic to check if partner is winning the trick

    if (trumpCards.isNotEmpty && !partnerWinning) {
      // Cut with lowest trump
      return trumpCards.first;
    }

    // No trump or partner is winning, just discard lowest
    return validCards.first;
  }

  void _updateTracker(RangBotObservation obs) {
    if (obs.currentTrick.isEmpty && _tracker.unseenCards.length == 52) {
      _tracker.initializeMyHand(obs.myHand);
    }

    for (final play in obs.currentTrick) {
      _tracker.markCardSeen(play.card);
      if (obs.leadSuit != null && play.card.suit != obs.leadSuit) {
        _tracker.markVoidSuit(play.playerId, obs.leadSuit!);
      }
    }
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
