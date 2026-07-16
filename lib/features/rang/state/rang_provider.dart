import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rang_adda/shared/models/card_model.dart';
import 'package:rang_adda/shared/models/player.dart';
import 'package:rang_adda/shared/models/game_state.dart';
import 'package:rang_adda/features/rang/engine/rang_game_state.dart';
import 'package:rang_adda/features/rang/engine/rang_engine.dart';
import 'package:rang_adda/shared/ai/bot_difficulty.dart';
import 'package:rang_adda/features/rang/bot/rang_bot_strategy.dart';
import 'package:rang_adda/features/rang/bot/rang_bot_easy.dart';
import 'package:rang_adda/features/rang/bot/rang_bot_pimc.dart';
import 'package:rang_adda/features/rang/bot/rang_bot_hard.dart';

class RangNotifier extends Notifier<RangGameState?> {
  bool _botMovePending = false;

  @override
  RangGameState? build() {
    return null;
  }

  void startGame(List<Player> players) {
    state = RangEngine.initializeGame(players);
    _autoAcknowledgeBotPassIfNeeded();
    _checkAndScheduleBotMove();
  }

  void declareTrump(String callerId, Suit suit) {
    if (state == null) return;
    try {
      state = RangEngine.declareTrump(state!, callerId, suit);
      _autoAcknowledgeBotPassIfNeeded();
      _checkAndScheduleBotMove();
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

    _autoAcknowledgeBotPassIfNeeded();
    _checkAndScheduleBotMove();
    return null;
  }

  void acknowledgePass() {
    if (state == null) return;
    state = state!.copyWith(clearPassToPlayerId: true);
    
    final s = state!;
    if (s.phase == RangPhase.trumpSelection &&
        _isBotPlayer(s.trumpCallerId) &&
        s.passToPlayerId == null) {
      Future.delayed(const Duration(milliseconds: 700), () {
        _botDeclareTrump();
      });
    }

    _autoAcknowledgeBotPassIfNeeded();
    _checkAndScheduleBotMove();
  }

  bool _isBotPlayer(String? id) {
    if (id == null || state == null) return false;
    final p = state!.players.firstWhere((p) => p.id == id, orElse: () => state!.players.first);
    return p.id == id && p.isBot;
  }

  Future<void> _autoAcknowledgeBotPassIfNeeded() async {
    final s = state;
    if (s == null) return;
    if (s.passToPlayerId == null) return;
    if (!_isBotPlayer(s.passToPlayerId)) return;

    // Brief visual pause so the UI can show something happened
    await Future.delayed(const Duration(milliseconds: 350));

    // Re-check state is still the same (another update may have happened)
    if (state?.passToPlayerId == s.passToPlayerId) {
      acknowledgePass();
    }
  }

  void _botDeclareTrump() {
    if (state == null || state!.trumpCallerId == null) return;
    final callerId = state!.trumpCallerId!;
    final player = state!.players.firstWhere((p) => p.id == callerId);
    final bot = _getBotForDifficulty(player.botDifficulty ?? BotDifficulty.easy);
    final suit = bot.chooseTrump(state!, callerId);
    declareTrump(callerId, suit);
  }

  void _checkAndScheduleBotMove() {
    final s = state;
    if (s == null) return;
    if (s.status != GameStatus.playing) return;
    if (s.phase != RangPhase.trickPlay) return;
    if (s.passToPlayerId != null) return;
    if (!_isBotPlayer(s.currentPlayerId)) return;
    
    _scheduleBotMove();
  }

  void _scheduleBotMove() {
    if (_botMovePending) return;
    _botMovePending = true;
    Future.delayed(const Duration(milliseconds: 900), () {
      final s = state;
      if (s != null && s.status == GameStatus.playing &&
          s.phase == RangPhase.trickPlay &&
          _isBotPlayer(s.currentPlayerId) &&
          s.passToPlayerId == null) {
        _executeBotMove();
      }
      _botMovePending = false;
    });
  }

  void _executeBotMove() {
    if (state == null) return;
    final botId = state!.currentPlayerId!;
    final player = state!.players.firstWhere((p) => p.id == botId);
    final bot = _getBotForDifficulty(player.botDifficulty ?? BotDifficulty.easy);
    final card = bot.chooseCard(state!, botId);

    final error = RangEngine.getMoveError(state!, botId, card);
    if (error != null) return;  // safety check

    playCard(botId, card);
  }

  RangBotStrategy _getBotForDifficulty(BotDifficulty diff) {
    switch (diff) {
      case BotDifficulty.easy:
        return RangBotEasy();
      case BotDifficulty.medium:
        return RangBotPIMC();
      case BotDifficulty.hard:
      case BotDifficulty.expert:
      case BotDifficulty.ml:
        return RangBotHard();
    }
  }
}

final rangProvider = NotifierProvider<RangNotifier, RangGameState?>(() {
  return RangNotifier();
});
