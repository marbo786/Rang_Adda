import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rang_adda/shared/models/card_model.dart';
import 'package:rang_adda/shared/models/player.dart';
import 'package:rang_adda/shared/models/game_state.dart';
import 'package:rang_adda/features/rang/engine/rang_game_state.dart';
import 'package:rang_adda/features/rang/engine/rang_engine.dart';
import 'package:rang_adda/shared/ai/bot_observation.dart';
import 'package:rang_adda/features/rang/ai/rang_bot.dart';
import 'package:rang_adda/shared/ai/bot_delay.dart';

class RangNotifier extends Notifier<RangGameState?> {
  final Map<String, RangBot> _bots = {};

  @override
  RangGameState? build() {
    return null;
  }

  void startGame(List<Player> players) {
    _bots.clear();
    for (final p in players) {
      if (p.isBot && p.botDifficulty != null) {
        _bots[p.id] = RangBot.create(p.botDifficulty!, p.name);
      }
    }
    state = RangEngine.initializeGame(players);
    _triggerBotTurnIfNeeded();
  }

  void declareTrump(String callerId, Suit suit) {
    if (state == null) return;
    try {
      state = RangEngine.declareTrump(state!, callerId, suit);
      _triggerBotTurnIfNeeded();
    } catch (e) {
      // Ignore
    }
  }

  Future<String?> playCard(String playerId, PlayingCard card) async {
    if (state == null) return "Game not ready.";

    String? error = RangEngine.getMoveError(state!, playerId, card);
    if (error != null) return error;

    // Notice we capture the state BEFORE playing to see if the trick ended
    final trickBeforePlay = state!.currentTrick.length;

    state = RangEngine.playCard(state!, playerId, card);

    // If trick was just resolved (it went from 3 to 0 because engine resolves it instantly),
    // we could add an artificial delay here if needed, but for now we just trigger next bot.
    if (trickBeforePlay == 3 && state!.currentTrick.isEmpty) {
      // A trick just resolved.
      await Future.delayed(const Duration(milliseconds: 1500));
    }

    _triggerBotTurnIfNeeded();
    return null;
  }

  void acknowledgePass() {
    if (state == null) return;
    state = state!.copyWith(clearPassToPlayerId: true);
    _triggerBotTurnIfNeeded();
  }

  void _triggerBotTurnIfNeeded() async {
    if (state == null || state!.status == GameStatus.finished) return;

    if (state!.passToPlayerId != null) {
      final passingToPlayer = state!.players.firstWhere(
        (p) => p.id == state!.passToPlayerId,
      );
      if (passingToPlayer.isBot) {
        acknowledgePass();
        return;
      }
      return;
    }

    if (state!.currentPlayerId?.isEmpty ?? true) return;

    final currentPlayer = state!.players.firstWhere(
      (p) => p.id == state!.currentPlayerId,
    );
    if (currentPlayer.isBot && _bots.containsKey(currentPlayer.id)) {
      final bot = _bots[currentPlayer.id]!;

      await BotDelay.simulateThinking(currentPlayer.botDifficulty!);

      // Make sure it's still their turn
      if (state == null || state!.currentPlayerId != currentPlayer.id) return;

      final obs = RangBotObservation.fromState(state!, currentPlayer.id);

      if (state!.phase == RangPhase.trumpSelection) {
        final trump = bot.chooseTrump(obs);
        declareTrump(currentPlayer.id, trump);
      } else if (state!.phase == RangPhase.trickPlay) {
        final card = bot.chooseCard(obs);
        await playCard(currentPlayer.id, card);
      }
    }
  }
}

final rangProvider = NotifierProvider<RangNotifier, RangGameState?>(() {
  return RangNotifier();
});
