import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rang_adda/shared/models/card_model.dart';
import 'package:rang_adda/shared/models/player.dart';
import 'package:rang_adda/features/thulla/engine/thulla_game_state.dart';
import 'package:rang_adda/features/thulla/engine/thulla_engine.dart';
import 'package:rang_adda/shared/ai/bot_observation.dart';
import 'package:rang_adda/features/thulla/ai/thulla_bot.dart';
import 'package:rang_adda/shared/ai/bot_delay.dart';

final thullaProvider = NotifierProvider<ThullaNotifier, ThullaGameState?>(() {
  return ThullaNotifier();
});

class ThullaNotifier extends Notifier<ThullaGameState?> {
  final Map<String, ThullaBot> _bots = {};

  @override
  ThullaGameState? build() {
    return null;
  }

  void startGame(List<Player> players) {
    _bots.clear();
    for (final p in players) {
      if (p.isBot && p.botDifficulty != null) {
        _bots[p.id] = ThullaBot.create(p.botDifficulty!, p.name);
      }
    }
    state = ThullaEngine.initializeGame(players);
    _triggerBotTurnIfNeeded();
  }

  Future<String?> playCard(String playerId, PlayingCard card) async {
    if (state == null) return "Game not ready.";
    if (state!.trickResolving) return "Please wait...";

    String? error = ThullaEngine.getMoveError(state!, playerId, card);
    if (error != null) return error;

    state = ThullaEngine.playCard(state!, playerId, card);

    if (state != null && state!.trickResolving) {
      await Future.delayed(const Duration(milliseconds: 1500));
      if (state != null) {
        state = ThullaEngine.resolveTrick(state!);
        _triggerBotTurnIfNeeded();
      }
    } else {
      _triggerBotTurnIfNeeded();
    }
    return null;
  }

  void acknowledgePass() {
    if (state == null) return;
    state = state!.copyWith(clearPassToPlayerId: true);
    _triggerBotTurnIfNeeded();
  }

  void _triggerBotTurnIfNeeded() async {
    if (state == null) return;

    // If waiting for someone to acknowledge pass screen, but it's a bot, auto-acknowledge
    if (state!.passToPlayerId != null) {
      final passingToPlayer = state!.players.firstWhere(
        (p) => p.id == state!.passToPlayerId,
      );
      if (passingToPlayer.isBot) {
        // Bots don't need a pass screen delay
        acknowledgePass();
        return;
      }
      return; // Waiting for human
    }

    if (state!.currentPlayerId == null) return;

    final currentPlayer = state!.players.firstWhere(
      (p) => p.id == state!.currentPlayerId,
    );
    if (currentPlayer.isBot && _bots.containsKey(currentPlayer.id)) {
      final bot = _bots[currentPlayer.id]!;

      // Artificial delay so humans can follow
      await BotDelay.simulateThinking(currentPlayer.botDifficulty!);

      // Make sure state hasn't changed/ended while thinking
      if (state == null || state!.currentPlayerId != currentPlayer.id) return;

      final obs = ThullaBotObservation.fromState(state!, currentPlayer.id);
      final cardToPlay = bot.chooseCard(obs);

      await playCard(currentPlayer.id, cardToPlay);
    }
  }
}
