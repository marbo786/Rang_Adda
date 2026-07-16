import 'package:rang_adda/shared/models/card_model.dart';
import 'package:rang_adda/features/bluff/engine/bluff_game_state.dart';
import 'package:rang_adda/features/bluff/bot/bluff_bot_strategy.dart';

class BluffBotMedium implements BluffBotStrategy {
  @override
  BluffBotAction chooseAction(BluffGameState state, String botId) {
    final player = state.players.firstWhere((p) => p.id == botId);
    final hand = List<PlayingCard>.from(player.hand);

    // ── Step 1: Should we call bluff? ─────────────────────────────────────
    if (state.lastCardPlayerId != null &&
        state.lastCardPlayerId != botId &&
        state.lastPlayedCards.isNotEmpty) {
      final bluffProbability = _estimateBluffProbability(state, botId);

      // Call bluff if estimated probability of lying > 65%
      if (bluffProbability > 0.65) {
        return BluffBotAction.callBluff();
      }
    }

    // ── Step 2: Decide cards to play ──────────────────────────────────────
    final roundRank = state.currentRoundRank;

    if (roundRank == null) {
      // We're starting a new round — choose the best rank to declare
      return _startNewRound(state, botId, hand);
    } else {
      return _continueRound(state, botId, hand, roundRank);
    }
  }

  // ── Bluff probability estimation ─────────────────────────────────────────
  double _estimateBluffProbability(BluffGameState state, String botId) {
    final claimedRank = state.lastClaimedRank;
    if (claimedRank == null) return 0.0;

    final player = state.players.firstWhere((p) => p.id == botId);

    // Count how many cards of claimed rank I hold
    final myCountOfRank = player.hand
        .where((c) => c.rank == claimedRank)
        .length;

    // Count how many are in the waste pile (gone from game)
    // Note: in Bluff, waste Pile wasn't explicitly modeled in previous versions,
    // we use what we can see: cards in MY hand + any revealed cards
    // The prompt mentions counting in wastePile, but our engine discards them.
    // For simplicity, we just use our hand.

    // Max cards of any rank in a 52-card deck = 4 (one per suit)
    const totalOfAnyRank = 4;

    // Cards of this rank that could plausibly still be in play (not in my hand)
    final availableElsewhere = totalOfAnyRank - myCountOfRank;

    // Cards claimed in the last play
    final claimedCount = state.lastPlayedCards.length;

    // If claimed count exceeds what could possibly exist elsewhere → certain bluff
    if (claimedCount > availableElsewhere) return 1.0;

    // Base bluff probability from scarcity
    // If I hold 3 kings and they claim 2 kings, only 1 king exists outside my hand
    // → probability of bluff = high
    double scarcityFactor = myCountOfRank / totalOfAnyRank.toDouble();

    // Pile size factor: larger pile = more pressure to bluff
    // (more cards in pile = player is desperate to get rid of them)
    final pileSizeFactor = (state.centerPile.length / 20.0).clamp(0.0, 0.4);

    // Claimed count factor: claiming more cards = more likely to be bluffing
    final claimFactor = (claimedCount / availableElsewhere.toDouble()).clamp(
      0.0,
      0.5,
    );

    return (scarcityFactor * 0.5 + pileSizeFactor + claimFactor * 0.3).clamp(
      0.0,
      1.0,
    );
  }

  // ── Starting a new round: choose best rank to declare ────────────────────
  BluffBotAction _startNewRound(
    BluffGameState state,
    String botId,
    List<PlayingCard> hand,
  ) {
    // Strategy: declare the rank we have the MOST cards of
    // This maximizes the chance we can play honestly (harder to call bluff on truth)
    final rankCounts = <Rank, int>{};
    for (final card in hand) {
      rankCounts[card.rank] = (rankCounts[card.rank] ?? 0) + 1;
    }

    // Find rank with highest count
    final bestRank = rankCounts.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;

    final cardsOfBestRank = hand.where((c) => c.rank == bestRank).toList();

    // Play all cards of this rank (honest play — hard to catch)
    // But don't play more than 4
    final toPlay = cardsOfBestRank.take(4).toList();
    return BluffBotAction.play(cards: toPlay, claimedRank: bestRank);
  }

  // ── Continuing a round with a locked rank ────────────────────────────────
  BluffBotAction _continueRound(
    BluffGameState state,
    String botId,
    List<PlayingCard> hand,
    Rank roundRank,
  ) {
    final hasRoundRank = hand.where((c) => c.rank == roundRank).toList();
    final doesntHaveRoundRank = hand.where((c) => c.rank != roundRank).toList();

    // If we have cards of the required rank → play them honestly
    if (hasRoundRank.isNotEmpty) {
      // Play up to 2 cards honestly (conserve some for future rounds)
      final toPlay = hasRoundRank.take(2).toList();
      return BluffBotAction.play(cards: toPlay, claimedRank: roundRank);
    }

    // We don't have the rank → must bluff or pass
    // Pass if the pile is small and we don't want to risk it
    if (state.centerPile.length < 4 && hand.length < 8) {
      // Pile is small, our hand is small — not worth the risk of being caught
      return BluffBotAction.pass();
    }

    // Bluff with 1 card (minimum exposure)
    // Choose the card we least want to keep (highest rank card — risky to hold)
    final bluffCard = doesntHaveRoundRank.isNotEmpty
        ? doesntHaveRoundRank.reduce(
            (a, b) => _rankValue(a.rank) > _rankValue(b.rank) ? a : b,
          )
        : hand.first;

    return BluffBotAction.play(cards: [bluffCard], claimedRank: roundRank);
  }

  int _rankValue(Rank rank) {
    const v = {
      Rank.two: 2,
      Rank.three: 3,
      Rank.four: 4,
      Rank.five: 5,
      Rank.six: 6,
      Rank.seven: 7,
      Rank.eight: 8,
      Rank.nine: 9,
      Rank.ten: 10,
      Rank.jack: 11,
      Rank.queen: 12,
      Rank.king: 13,
      Rank.ace: 14,
    };
    return v[rank]!;
  }
}
