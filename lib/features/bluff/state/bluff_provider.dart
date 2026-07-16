import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rang_adda/shared/models/card_model.dart';
import 'package:rang_adda/shared/models/player.dart';
import 'package:rang_adda/shared/models/game_state.dart';
import 'package:rang_adda/features/bluff/engine/bluff_game_state.dart';
import 'package:rang_adda/features/bluff/engine/bluff_engine.dart';
import 'package:rang_adda/shared/ai/bot_difficulty.dart';
import 'package:rang_adda/features/bluff/bot/bluff_bot_strategy.dart';
import 'package:rang_adda/features/bluff/bot/bluff_bot_easy.dart';
import 'package:rang_adda/features/bluff/bot/bluff_bot_medium.dart';
import 'package:rang_adda/features/bluff/bot/bluff_bot_hard.dart';

class BluffNotifier extends Notifier<BluffGameState> {
  bool _botMovePending = false;

  @override
  BluffGameState build() {
    return const BluffGameState(
      gameId: 'initial',
      players: [],
      currentPlayerId: '',
    );
  }

  void startGame(List<Player> players) {
    state = BluffEngine.initializeGame(players);
    _checkAndScheduleBotMove();
  }

  Future<String?> playCard(
    String playerId,
    List<PlayingCard> cards,
    Rank claimedRank,
  ) async {
    try {
      state = BluffEngine.playCards(state, playerId, cards, claimedRank);
      _checkAndScheduleBotMove();
      _checkAutoAckPass();
      return null;
    } catch (e) {
      return e.toString().replaceAll("Exception: ", "");
    }
  }

  Future<String?> passTurn(String playerId) async {
    try {
      state = BluffEngine.passTurn(state, playerId);
      _checkAndScheduleBotMove();
      _checkAutoAckPass();
      return null;
    } catch (e) {
      return e.toString().replaceAll("Exception: ", "");
    }
  }

  Future<String?> callBluff(String callerId) async {
    try {
      state = BluffEngine.callBluff(state, callerId);

      // Fix local resolution gap:
      if (state.pendingBluffCallerId != null) {
        await Future.delayed(const Duration(milliseconds: 1500));
        state = BluffEngine.resolveBluffCall(state);
        _checkAndScheduleBotMove();
        _checkAutoAckPass();
      }

      return null;
    } catch (e) {
      return e.toString().replaceAll("Exception: ", "");
    }
  }

  void acknowledgePass() {
    state = state.clearOverlays();
    _checkAndScheduleBotMove();
    _checkAutoAckPass();
  }

  void declineChallenge() {
    state = state.copyWith(
      lastPlayerId: null,
      lastClaimedRank: null,
      lastPlayedCards: [],
    );
    _checkAndScheduleBotMove();
    _checkAutoAckPass();
  }

  void acknowledgeResolvingMessage() {
    state = state.clearOverlays();
    _checkAndScheduleBotMove();
    _checkAutoAckPass();
  }

  bool _isBotPlayer(String? id) {
    if (id == null) return false;
    final p = state.players.firstWhere(
      (p) => p.id == id,
      orElse: () => state.players.first,
    );
    return p.id == id && p.isBot;
  }

  void _checkAutoAckPass() async {
    if (_isBotPlayer(state.passToPlayerId)) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (state.passToPlayerId != null) {
        acknowledgePass();
      }
    }
  }

  void _checkAndScheduleBotMove() {
    if (state.status != GameStatus.playing) return;
    if (state.passToPlayerId != null) return; // waiting for pass ack
    if (state.resolvingBluffMessage != null) return;
    if (!_isBotPlayer(state.currentPlayerId)) return; // human's turn

    _scheduleBotMove();
  }

  void _scheduleBotMove() {
    if (_botMovePending) return;
    _botMovePending = true;
    Future.delayed(const Duration(milliseconds: 900), () {
      if (state.status == GameStatus.playing &&
          _isBotPlayer(state.currentPlayerId) &&
          state.passToPlayerId == null &&
          state.resolvingBluffMessage == null) {
        _executeBotMove();
      }
      _botMovePending = false;
    });
  }

  void _executeBotMove() {
    final botId = state.currentPlayerId!;
    final player = state.players.firstWhere((p) => p.id == botId);
    final bot = _getBotForDifficulty(
      player.botDifficulty ?? BotDifficulty.easy,
    );
    final action = bot.chooseAction(state, botId);

    switch (action) {
      case CallBluff():
        callBluff(botId);
        break;
      case Pass():
        passTurn(botId);
        break;
      case Play(cards: final cards, claimedRank: final rank):
        playCard(botId, cards, rank);
        break;
    }
  }

  BluffBotStrategy _getBotForDifficulty(BotDifficulty diff) {
    switch (diff) {
      case BotDifficulty.easy:
        return BluffBotEasy();
      case BotDifficulty.medium:
        return BluffBotMedium();
      case BotDifficulty.hard:
      case BotDifficulty.expert:
      case BotDifficulty.ml:
        return BluffBotHard();
    }
  }
}

final bluffProvider = NotifierProvider<BluffNotifier, BluffGameState>(() {
  return BluffNotifier();
});
