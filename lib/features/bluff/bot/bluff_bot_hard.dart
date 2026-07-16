import 'dart:math';
import 'package:rang_adda/shared/models/card_model.dart';
import 'package:rang_adda/features/bluff/engine/bluff_game_state.dart';
import 'package:rang_adda/features/bluff/bot/bluff_bot_strategy.dart';

class BluffBotHard implements BluffBotStrategy {
  @override
  BluffBotAction chooseAction(BluffGameState state, String botId) {
    final player = state.players.firstWhere((p) => p.id == botId);
    final hand = List<PlayingCard>.from(player.hand);

    // ── Endgame detection ───────────────────────────────────────────────
    final minOpponentCards = state.players
        .where((p) => p.id != botId)
        .map((p) => p.hand.length)
        .fold(999, min);
    final isEndgame = minOpponentCards <= 3 || hand.length <= 3;

    // ── Call bluff? ─────────────────────────────────────────────────────
    if (state.lastCardPlayerId != null &&
        state.lastCardPlayerId != botId &&
        state.lastPlayedCards.isNotEmpty) {

      final prob = _estimateBluffProbability(state, botId);
      // Lower threshold in endgame (more aggressive calling)
      final threshold = isEndgame ? 0.45 : 0.70;

      // Also call bluff if center pile is huge — catching a bluff punishes
      // the opponent severely when pile is large
      final pileBonus = (state.centerPile.length / 52.0) * 0.15;

      if (prob + pileBonus > threshold) {
        return BluffBotAction.callBluff();
      }
    }

    final roundRank = state.currentRoundRank;

    if (roundRank == null) {
      return _startNewRoundHard(state, botId, hand, isEndgame);
    } else {
      return _continueRoundHard(state, botId, hand, roundRank, isEndgame);
    }
  }

  double _estimateBluffProbability(BluffGameState state, String botId) {
    final claimedRank = state.lastClaimedRank;
    if (claimedRank == null) return 0.0;

    final player = state.players.firstWhere((p) => p.id == botId);
    final myCount = player.hand.where((c) => c.rank == claimedRank).length;
    const totalOfRank = 4;
    final available = totalOfRank - myCount;
    final claimedCount = state.lastPlayedCards.length;

    if (claimedCount > available) return 1.0;  // mathematically impossible

    final scarcity = myCount / totalOfRank.toDouble();
    final pilePresure = (state.centerPile.length / 25.0).clamp(0.0, 0.35);
    final excessClaim = ((claimedCount - 1) / max(available, 1).toDouble())
        .clamp(0.0, 0.4);

    return (scarcity * 0.45 + pilePresure + excessClaim * 0.35).clamp(0.0, 1.0);
  }

  BluffBotAction _startNewRoundHard(
      BluffGameState state, String botId,
      List<PlayingCard> hand, bool isEndgame) {

    final rankCounts = <Rank, int>{};
    for (final c in hand) {
      rankCounts[c.rank] = (rankCounts[c.rank] ?? 0) + 1;
    }

    if (isEndgame) {
      // Endgame: play as many cards as possible to race to empty hand
      final bestRank = rankCounts.entries
          .reduce((a, b) => a.value >= b.value ? a : b).key;
      final all = hand.where((c) => c.rank == bestRank).take(4).toList();
      return BluffBotAction.play(cards: all, claimedRank: bestRank);
    }

    // Normal: declare rank we have most of, play 2–3 cards
    final bestRank = rankCounts.entries
        .reduce((a, b) => a.value >= b.value ? a : b).key;
    final toPlay = hand.where((c) => c.rank == bestRank).take(3).toList();
    return BluffBotAction.play(cards: toPlay, claimedRank: bestRank);
  }

  BluffBotAction _continueRoundHard(
      BluffGameState state, String botId,
      List<PlayingCard> hand, Rank roundRank, bool isEndgame) {

    final hasRank = hand.where((c) => c.rank == roundRank).toList();
    final noRank = hand.where((c) => c.rank != roundRank).toList();

    if (hasRank.isNotEmpty) {
      // Play all of this rank if endgame, or up to 3 normally
      final limit = isEndgame ? hasRank.length : min(3, hasRank.length);
      return BluffBotAction.play(
        cards: hasRank.take(limit).toList(),
        claimedRank: roundRank,
      );
    }

    // Need to bluff — dump the card we most want to get rid of
    // Priority: cards we have exactly 1 of (singleton ranks — hardest to use honestly)
    final rankCounts = <Rank, int>{};
    for (final c in noRank) {
      rankCounts[c.rank] = (rankCounts[c.rank] ?? 0) + 1;
    }

    // Find singletons (ranks we have only 1 of)
    final singletons = noRank.where((c) => rankCounts[c.rank] == 1).toList();
    final bluffCard = singletons.isNotEmpty ? singletons.first : noRank.first;

    // In endgame, bluff with up to 2 cards to dump faster
    final bluffCount = isEndgame ? min(2, noRank.length) : 1;
    final bluffCards = [bluffCard, ...noRank.where((c) => c != bluffCard)]
        .take(bluffCount)
        .toList();

    return BluffBotAction.play(cards: bluffCards, claimedRank: roundRank);
  }
}
