import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rang_adda/shared/models/card_model.dart';
import 'package:rang_adda/shared/models/game_state.dart';
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
  bool _botMovePending = false;
  bool _botPassAckPending = false;

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
    _checkAndScheduleBotMove();
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
        _checkAndScheduleBotMove();
      }
    } else {
      _checkAndScheduleBotMove();
    }
    return null;
  }

  void acknowledgePass() {
    if (state == null) return;
    state = state!.copyWith(clearPassToPlayerId: true);
    _checkAndScheduleBotMove();
  }

  bool _isBotPlayer(String? playerId) {
    if (playerId == null || state == null) return false;
    return state!.players.any((p) => p.id == playerId && p.isBot);
  }

  void _checkAndScheduleBotMove() {
    final currentState = state;
    if (currentState == null) return;
    if (currentState.status != GameStatus.playing) return;
    if (currentState.trickResolving) return;

    final currentPlayerId = currentState.currentPlayerId;
    if (_isBotPlayer(currentPlayerId) &&
        currentState.passToPlayerId == currentPlayerId) {
      _autoAcknowledgeBotPass();
      return;
    }

    if (currentState.passToPlayerId != null) return;
    if (!_isBotPlayer(currentPlayerId)) return;

    _scheduleBotMove();
  }

  Future<void> _autoAcknowledgeBotPass() async {
    if (_botPassAckPending) return;
    _botPassAckPending = true;

    await Future.delayed(const Duration(milliseconds: 300));

    final currentState = state;
    if (currentState != null &&
        _isBotPlayer(currentState.currentPlayerId) &&
        currentState.passToPlayerId == currentState.currentPlayerId) {
      acknowledgePass();
    }

    _botPassAckPending = false;
  }

  void _scheduleBotMove() {
    if (_botMovePending) return;
    _botMovePending = true;

    Future.delayed(const Duration(milliseconds: 800), () async {
      try {
        final currentState = state;
        if (currentState != null &&
            currentState.status == GameStatus.playing &&
            currentState.passToPlayerId == null &&
            !currentState.trickResolving &&
            _isBotPlayer(currentState.currentPlayerId)) {
          await _executeBotMove();
        }
      } finally {
        _botMovePending = false;
      }
    });
  }

  Future<void> _executeBotMove() async {
    final currentState = state;
    if (currentState == null) return;

    final currentPlayerId = currentState.currentPlayerId;
    if (currentPlayerId == null || !_bots.containsKey(currentPlayerId)) return;

    final currentPlayer = currentState.players.firstWhere(
      (p) => p.id == currentPlayerId,
    );
    final bot = _bots[currentPlayer.id]!;

    await BotDelay.simulateThinking(currentPlayer.botDifficulty!);

    if (state == null || state!.currentPlayerId != currentPlayer.id) return;

    final obs = ThullaBotObservation.fromState(state!, currentPlayer.id);
    final cardToPlay = bot.chooseCard(obs);

    await playCard(currentPlayer.id, cardToPlay);
  }
}
