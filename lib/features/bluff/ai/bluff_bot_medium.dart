import 'dart:math';
import 'package:rang_adda/shared/models/card_model.dart';
import 'package:rang_adda/shared/ai/bot_observation.dart';
import 'bluff_bot.dart';

class BluffBotMedium extends BluffBot {
  final _random = Random();

  BluffBotMedium(super.personality);

  @override
  BluffPlayDecision choosePlay(BluffBotObservation obs) {
    // Medium bot tries to play honestly if possible, but uses bluffFrequency
    // to occasionally lie, especially if they don't have matching cards.

    // Check if we want to bluff based on personality
    bool willBluff = personality.shouldTakeRisk(
      1.0 - personality.bluffFrequency,
    );

    // Group hand by ranks
    final rankGroups = <Rank, List<PlayingCard>>{};
    for (final card in obs.myHand) {
      rankGroups.putIfAbsent(card.rank, () => []).add(card);
    }

    int minCardsToPlay = (obs.centerPileCount == 0) ? 2 : 1;

    if (!willBluff) {
      // Try to find a group with enough cards to play honestly
      for (final rank in rankGroups.keys) {
        if (rankGroups[rank]!.length >= minCardsToPlay) {
          // Play honestly
          int toPlay = min(4, rankGroups[rank]!.length);
          if (toPlay > minCardsToPlay && _random.nextBool()) {
            // Mix it up, don't always play all
            toPlay =
                minCardsToPlay + _random.nextInt(toPlay - minCardsToPlay + 1);
          }
          return BluffPlayDecision(
            cards: rankGroups[rank]!.take(toPlay).toList(),
            claimedRank: rank,
          );
        }
      }
    }

    // Forced to bluff or decided to bluff
    // Pick 1-3 random cards, and claim a rank we DON'T have, or just a random one.
    int maxCards = min(4, obs.myHand.length);
    int numCardsToPlay =
        minCardsToPlay + _random.nextInt(min(3, maxCards - minCardsToPlay + 1));

    final shuffledHand = List<PlayingCard>.from(obs.myHand)..shuffle();
    final selectedCards = shuffledHand.take(numCardsToPlay).toList();

    // Claim a rank we actually have 1 of (to throw people off), or random.
    Rank claimRank;
    if (rankGroups.isNotEmpty && _random.nextBool()) {
      claimRank = rankGroups.keys.elementAt(_random.nextInt(rankGroups.length));
    } else {
      claimRank = Rank.values[_random.nextInt(Rank.values.length)];
    }

    return BluffPlayDecision(cards: selectedCards, claimedRank: claimRank);
  }

  @override
  BluffChallengeDecision respondToPlay(BluffBotObservation obs) {
    if (obs.lastClaimedRank == null) return BluffChallengeDecision.pass;

    // How many of the claimed rank do we hold?
    int countInHand = obs.myHand
        .where((c) => c.rank == obs.lastClaimedRank)
        .length;

    // If they claimed 3, and we hold 2 (total 5), it's IMPOSSIBLE. Call bluff!
    if (countInHand + obs.lastPlayedCount > 4) {
      return BluffChallengeDecision.callBluff;
    }

    // If pile is big, we might want to risk calling bluff to punish them
    double pileFactor = min(
      1.0,
      obs.centerPileCount / 15.0,
    ); // max 1.0 at 15 cards

    // If they played a lot of cards, it's more likely a bluff
    double countFactor =
        (obs.lastPlayedCount - 1) * 0.2; // 0.0 for 1, 0.6 for 4

    // Personality risk tolerance comes into play
    double bluffSuspicion =
        pileFactor * 0.4 + countFactor * 0.4 + (countInHand * 0.1);

    if (personality.shouldTakeRisk(1.0 - bluffSuspicion)) {
      return BluffChallengeDecision.callBluff;
    }

    return BluffChallengeDecision.pass;
  }
}
