import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rang_adda/shared/models/card_model.dart';
import 'package:rang_adda/features/rang/engine/rang_game_state.dart';
import 'package:rang_adda/features/rang/engine/rang_engine.dart';
import 'package:rang_adda/shared/services/firestore_service.dart';
import 'package:rang_adda/features/rang/bot/rang_bot_strategy.dart';
import 'package:rang_adda/features/rang/bot/rang_bot_easy.dart';
import 'package:rang_adda/features/rang/bot/rang_bot_pimc.dart';
import 'package:rang_adda/features/rang/bot/rang_bot_hard.dart';
import 'package:rang_adda/shared/ai/bot_difficulty.dart';
import 'package:rang_adda/shared/ai/bot_delay.dart';
import 'package:shared_preferences/shared_preferences.dart';

final currentRangGameIdProvider = NotifierProvider<CurrentRangGameIdNotifier, String?>(
  () {
    return CurrentRangGameIdNotifier();
  },
);

class CurrentRangGameIdNotifier extends Notifier<String?> {
  @override
  String? build() {
    _loadInitialId();
    return null;
  }

  Future<void> _loadInitialId() async {
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString('currentRangGameId');
    if (savedId != null) {
      state = savedId;
    }
  }

  Future<void> setId(String? id) async {
    state = id;
    final prefs = await SharedPreferences.getInstance();
    if (id == null) {
      await prefs.remove('currentRangGameId');
    } else {
      await prefs.setString('currentRangGameId', id);
    }
  }
}

final onlineRangProvider = StreamProvider<RangGameState?>((ref) {
  final gameId = ref.watch(currentRangGameIdProvider);
  if (gameId == null) return const Stream.empty();

  final firestore = ref.read(firestoreServiceProvider);
  return firestore.streamGame(gameId).cast<RangGameState?>();
});

final onlineRangActionProvider = Provider<OnlineRangActionController>((ref) {
  return OnlineRangActionController(ref);
});

class OnlineRangActionController {
  final Ref ref;
  bool _isProcessing = false;
  final Map<String, RangBotStrategy> _bots = {};
  String? _lastBotTurnId;

  OnlineRangActionController(this.ref) {
    ref.listen<AsyncValue<RangGameState?>>(onlineRangProvider, (
      previous,
      next,
    ) {
      final state = next.value;
      if (state != null) {
        if (state.trickResolving && (previous?.value?.trickResolving != true)) {
          _handleTrickResolution(state);
        } else if (!state.trickResolving) {
          _handleBots(state);
        }
      }
    });
  }

  Future<void> _handleTrickResolution(RangGameState state) async {
    await Future.delayed(const Duration(milliseconds: 1000));

    final resolvedState = RangEngine.resolveTrick(state);
    final currentUser = FirebaseAuth.instance.currentUser;

    // If it's your turn next, you resolve the trick.
    if (currentUser != null &&
        resolvedState.currentPlayerId == currentUser.uid) {
      final firestore = ref.read(firestoreServiceProvider);
      await firestore.runGameTransaction(state.gameId, (latestState) {
        final rangState = latestState as RangGameState;
        if (rangState.trickResolving) {
          return RangEngine.resolveTrick(rangState);
        }
        return rangState;
      });
    } else if (currentUser != null && state.hostUid == currentUser.uid) {
      // If it's a bot's turn after resolution, the host resolves the trick on behalf of the bot
      final nextPlayer = state.players.firstWhere(
        (p) => p.id == resolvedState.currentPlayerId,
      );
      if (nextPlayer.isBot) {
        final firestore = ref.read(firestoreServiceProvider);
        await firestore.runGameTransaction(state.gameId, (latestState) {
          final rangState = latestState as RangGameState;
          if (rangState.trickResolving) {
            return RangEngine.resolveTrick(rangState);
          }
          return rangState;
        });
      }
    }
  }

  void _handleBots(RangGameState state) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || state.hostUid != currentUser.uid) return;

    if (state.phase == RangPhase.trumpSelection) {
      if (state.trumpSuit == null) {
        final caller = state.players.firstWhere((p) => p.id == state.trumpCallerId);
        if (caller.isBot) {
          _handleBotTrumpSelection(state, caller);
        }
      }
      return;
    }

    if (state.currentPlayerId == null) return;

    // Prevent double-triggering the same turn
    if (_lastBotTurnId ==
        '${state.currentTrick.length}_${state.currentPlayerId}') {
      return;
    }

    final currentPlayer = state.players.firstWhere(
      (p) => p.id == state.currentPlayerId,
    );
    if (!currentPlayer.isBot) return;

    _initializeBotsIfNeeded(state);

    if (_bots.containsKey(currentPlayer.id)) {
      _lastBotTurnId = '${state.currentTrick.length}_${state.currentPlayerId}';

      final bot = _bots[currentPlayer.id]!;
      await BotDelay.simulateThinking(currentPlayer.botDifficulty ?? BotDifficulty.easy);

      // Re-fetch latest state
      final latestState = ref.read(onlineRangProvider).value;
      if (latestState == null ||
          latestState.currentPlayerId != currentPlayer.id) {
        return;
      }

      final cardToPlay = bot.chooseCard(latestState, currentPlayer.id);
      await playCard(currentPlayer.id, cardToPlay);
    }
  }
  
  Future<void> _handleBotTrumpSelection(RangGameState state, player) async {
    // Prevent double-triggering
    if (_lastBotTurnId == 'trump_${player.id}') return;
    _lastBotTurnId = 'trump_${player.id}';
    
    _initializeBotsIfNeeded(state);
    final bot = _bots[player.id];
    if (bot == null) return;
    
    await BotDelay.simulateThinking(player.botDifficulty ?? BotDifficulty.easy);
    
    final latestState = ref.read(onlineRangProvider).value;
    if (latestState == null || latestState.trumpSuit != null) return;
    
    final suit = bot.chooseTrump(latestState, player.id);
    await declareTrump(player.id, suit);
  }

  void _initializeBotsIfNeeded(RangGameState state) {
    if (_bots.isEmpty) {
      for (final p in state.players) {
        if (p.isBot) {
          _bots[p.id] = _getBotForDifficulty(p.botDifficulty ?? BotDifficulty.easy);
        }
      }
    }
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

  Future<String?> playCard(String playerId, PlayingCard card) async {
    if (_isProcessing) return "Processing...";
    _isProcessing = true;

    try {
      final state = ref.read(onlineRangProvider).value;
      if (state == null) return "Game not found.";
      if (state.trickResolving) return "Please wait...";

      String? error = RangEngine.getMoveError(state, playerId, card);
      if (error != null) return error;

      final firestore = ref.read(firestoreServiceProvider);
      await firestore.runGameTransaction(state.gameId, (latestState) {
        return RangEngine.playCard(
          latestState as RangGameState,
          playerId,
          card,
        );
      });

      return null;
    } finally {
      _isProcessing = false;
    }
  }
  
  Future<String?> declareTrump(String playerId, Suit suit) async {
    if (_isProcessing) return "Processing...";
    _isProcessing = true;
    
    try {
      final state = ref.read(onlineRangProvider).value;
      if (state == null) return "Game not found";
      
      final firestore = ref.read(firestoreServiceProvider);
      await firestore.runGameTransaction(state.gameId, (latestState) {
        return RangEngine.declareTrump(latestState as RangGameState, playerId, suit);
      });
      return null;
    } finally {
      _isProcessing = false;
    }
  }
}
