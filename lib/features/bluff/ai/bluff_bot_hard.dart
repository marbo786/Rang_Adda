import 'package:rang_adda/shared/models/card_model.dart';
import 'package:rang_adda/shared/ai/bot_observation.dart';
import 'bluff_bot.dart';

class BluffBotHard extends BluffBot {
  // Tracks ranks that this bot KNOWS are in the pile because it put them there.
  // (Simplified tracking for this session)
  final Map<Rank, int> _myCardsInPile = {};
  int _lastSeenPileCount = 0;

  BluffBotHard(super.personality);

  @override
  BluffPlayDecision choosePlay(BluffBotObservation obs) {
    if (obs.centerPileCount < _lastSeenPileCount) {
      // Pile was taken! Reset our memory.
      _myCardsInPile.clear();
    }
    _lastSeenPileCount = obs.centerPileCount;

    // Hard bot plays perfectly honestly if possible.
    // If it MUST bluff, it plays 1 card and claims a rank it actually has a lot of.

    // Group hand by ranks
    final rankGroups = <Rank, List<PlayingCard>>{};
    for (final card in obs.myHand) {
      rankGroups.putIfAbsent(card.rank, () => []).add(card);
    }

    int minCardsToPlay = (obs.centerPileCount == 0) ? 2 : 1;

    // Try to find a group with enough cards to play honestly
    for (final rank in rankGroups.keys) {
      if (rankGroups[rank]!.length >= minCardsToPlay) {
        // Honest play. We'll play all of them to shed cards faster.
        final cardsToPlay = rankGroups[rank]!;

        // Remember we put these in the pile
        _myCardsInPile[rank] = (_myCardsInPile[rank] ?? 0) + cardsToPlay.length;

        return BluffPlayDecision(cards: cardsToPlay, claimedRank: rank);
      }
    }

    // Forced to bluff.
    // Best strategy: play exactly 1 card to minimize pile growth,
    // and claim a rank we hold the MOST of, so if someone challenges,
    // we take the pile but we already have those cards anyway (or to make our future claims of that rank more believable).

    Rank bestClaimRank = Rank.ace;
    int maxHeld = -1;
    for (final rank in rankGroups.keys) {
      if (rankGroups[rank]!.length > maxHeld) {
        maxHeld = rankGroups[rank]!.length;
        bestClaimRank = rank;
      }
    }

    if (maxHeld == -1) {
      // Should not happen, but fallback
      bestClaimRank = Rank.ace;
    }

    // Pick our lowest value card to bluff with, so we shed garbage
    obs.myHand.sort((a, b) => a.rank.index.compareTo(b.rank.index));
    final bluffCard = obs.myHand.first;

    // Remember our bluff (we didn't actually put bestClaimRank in, but we know what we put in)
    _myCardsInPile[bluffCard.rank] = (_myCardsInPile[bluffCard.rank] ?? 0) + 1;

    return BluffPlayDecision(
      cards: [bluffCard],
      claimedRank: bestClaimRank, // Claim the one we hold the most
    );
  }

  @override
  BluffChallengeDecision respondToPlay(BluffBotObservation obs) {
    if (obs.centerPileCount < _lastSeenPileCount) {
      _myCardsInPile.clear();
    }
    _lastSeenPileCount = obs.centerPileCount;

    if (obs.lastClaimedRank == null) return BluffChallengeDecision.pass;

    // Absolute truth checking:
    // How many of the claimed rank do we hold?
    int countInHand = obs.myHand
        .where((c) => c.rank == obs.lastClaimedRank)
        .length;
    int countWePutInPile = _myCardsInPile[obs.lastClaimedRank] ?? 0;

    // If they claim X, we hold Y, and we KNOW we put Z in the pile:
    // X + Y + Z > 4 means they MUST BE BLUFFING!
    if (obs.lastPlayedCount + countInHand + countWePutInPile > 4) {
      return BluffChallengeDecision.callBluff;
    }

    // If the person who just played has very few cards left (e.g. 1 or 2),
    // and the pile is large, they might be bluffing to go out. High risk for them, good time to challenge.
    int oppCardCount = obs.opponentCardCounts[obs.lastPlayerId] ?? 4;
    if (oppCardCount == 0 && obs.centerPileCount > 3) {
      // They just went out! Call their bluff if we are aggressive!
      if (personality.shouldTakeRisk(0.3)) {
        return BluffChallengeDecision.callBluff;
      }
    }

    return BluffChallengeDecision.pass;
  }
}
