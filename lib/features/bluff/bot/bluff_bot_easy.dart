import 'dart:math';
import 'package:rang_adda/shared/models/card_model.dart';
import 'package:rang_adda/features/bluff/engine/bluff_game_state.dart';
import 'package:rang_adda/features/bluff/bot/bluff_bot_strategy.dart';

/// Easy bot: makes random but always-valid decisions.
class BluffBotEasy implements BluffBotStrategy {
  final Random _rng = Random();

  @override
  BluffBotAction chooseAction(BluffGameState state, String botId) {
    // 10% chance to call bluff (random, not strategic)
    if (state.lastCardPlayerId != null && _rng.nextDouble() < 0.10) {
      return BluffBotAction.callBluff();
    }

    final player = state.players.firstWhere((p) => p.id == botId);
    final hand = List<PlayingCard>.from(player.hand);

    // 15% chance to pass if not the round starter
    if (state.currentRoundRank != null && _rng.nextDouble() < 0.15) {
      return BluffBotAction.pass();
    }

    // Play 1–4 random cards from hand
    hand.shuffle(_rng);
    final count = min(
      1 + _rng.nextInt(3),
      hand.length,
    ); // 1 to min(4, hand size)
    final cards = hand.take(count).toList();

    // Claim the locked rank if round is in progress, else random rank
    final rank =
        state.currentRoundRank ?? Rank.values[_rng.nextInt(Rank.values.length)];

    return BluffBotAction.play(cards: cards, claimedRank: rank);
  }
}
