import 'dart:math';
import 'package:rang_adda/shared/models/card_model.dart';
import 'package:rang_adda/features/rang/engine/rang_game_state.dart';
import 'package:rang_adda/features/rang/engine/rang_engine.dart';
import 'package:rang_adda/features/rang/bot/rang_bot_strategy.dart';

class RangBotEasy implements RangBotStrategy {
  final Random _rng;

  RangBotEasy({Random? rng}) : _rng = rng ?? Random();

  @override
  PlayingCard chooseCard(RangGameState state, String botId) {
    final player = state.players.firstWhere((p) => p.id == botId);
    final valid = List<PlayingCard>.from(
      player.hand.where((c) => RangEngine.getMoveError(state, botId, c) == null)
    );
    valid.shuffle(_rng);
    return valid.first;
  }

  @override
  Suit chooseTrump(RangGameState state, String botId) {
    // Random suit for easy bot
    return Suit.values[_rng.nextInt(4)];
  }
}
