import 'dart:math';
import 'package:rang_adda/shared/models/card_model.dart';
import 'package:rang_adda/shared/ai/bot_observation.dart';
import 'bluff_bot.dart';

class BluffBotEasy extends BluffBot {
  final _random = Random();

  BluffBotEasy(super.personality);

  @override
  BluffPlayDecision choosePlay(BluffBotObservation obs) {
    // Easy bot logic:
    // Picks 1 or 2 random cards.
    // Claims a completely random rank.

    int maxCards = min(4, obs.myHand.length);
    int numCardsToPlay = 1;

    if (obs.centerPileCount == 0 && maxCards >= 2) {
      // First play must be at least 2 cards.
      numCardsToPlay = 2 + _random.nextInt(min(3, maxCards - 1));
    } else if (maxCards > 1) {
      numCardsToPlay = 1 + _random.nextInt(min(2, maxCards)); // 1 or 2 cards
    }

    final shuffledHand = List<PlayingCard>.from(obs.myHand)..shuffle();
    final selectedCards = shuffledHand.take(numCardsToPlay).toList();

    // Random rank (very high chance of bluffing, but maybe not on purpose)
    final randomRank = Rank.values[_random.nextInt(Rank.values.length)];

    return BluffPlayDecision(cards: selectedCards, claimedRank: randomRank);
  }

  @override
  BluffChallengeDecision respondToPlay(BluffBotObservation obs) {
    // Easy bot rarely calls bluff (10%).
    if (_random.nextDouble() < 0.1) {
      return BluffChallengeDecision.callBluff;
    }
    return BluffChallengeDecision.pass;
  }
}
