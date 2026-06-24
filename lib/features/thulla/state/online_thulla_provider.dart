import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rang_adda/shared/models/card_model.dart';
import 'package:rang_adda/features/thulla/engine/thulla_game_state.dart';
import 'package:rang_adda/features/thulla/engine/thulla_engine.dart';
import 'package:rang_adda/shared/services/firestore_service.dart';
import 'package:rang_adda/shared/ai/bot_observation.dart';
import 'package:rang_adda/features/thulla/ai/thulla_bot.dart';
import 'package:rang_adda/shared/ai/bot_delay.dart';

import 'package:shared_preferences/shared_preferences.dart';

final currentGameIdProvider = NotifierProvider<CurrentGameIdNotifier, String?>(
  () {
    return CurrentGameIdNotifier();
  },
);

class CurrentGameIdNotifier extends Notifier<String?> {
  @override
  String? build() {
    _loadInitialId();
    return null;
  }

  Future<void> _loadInitialId() async {
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString('currentGameId');
    if (savedId != null) {
      state = savedId;
    }
  }

  Future<void> setId(String? id) async {
    state = id;
    final prefs = await SharedPreferences.getInstance();
    if (id == null) {
      await prefs.remove('currentGameId');
    } else {
      await prefs.setString('currentGameId', id);
    }
  }
}

final onlineThullaProvider = StreamProvider<ThullaGameState?>((ref) {
  final gameId = ref.watch(currentGameIdProvider);
  if (gameId == null) return const Stream.empty();

  final firestore = ref.read(firestoreServiceProvider);
  return firestore.streamGame(gameId).cast<ThullaGameState?>();
});

final onlineActionProvider = Provider<OnlineActionController>((ref) {
  return OnlineActionController(ref);
});

class OnlineActionController {
  final Ref ref;
  bool _isProcessing = false;
  final Map<String, ThullaBot> _bots = {};
  String? _lastBotTurnId;

  OnlineActionController(this.ref) {
    ref.listen<AsyncValue<ThullaGameState?>>(onlineThullaProvider, (
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

  Future<void> _handleTrickResolution(ThullaGameState state) async {
    await Future.delayed(const Duration(milliseconds: 1500));

    final resolvedState = ThullaEngine.resolveTrick(state);
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null &&
        resolvedState.currentPlayerId == currentUser.uid) {
      final firestore = ref.read(firestoreServiceProvider);
      await firestore.runGameTransaction(state.gameId, (latestState) {
        final thullaState = latestState as ThullaGameState;
        if (thullaState.trickResolving) {
          return ThullaEngine.resolveTrick(thullaState);
        }
        return thullaState;
      });
    } else if (currentUser != null && state.hostUid == currentUser.uid) {
      // If it's a bot's turn after resolution, the host resolves the trick on behalf of the bot
      final nextPlayer = state.players.firstWhere(
        (p) => p.id == resolvedState.currentPlayerId,
      );
      if (nextPlayer.isBot) {
        final firestore = ref.read(firestoreServiceProvider);
        await firestore.runGameTransaction(state.gameId, (latestState) {
          final thullaState = latestState as ThullaGameState;
          if (thullaState.trickResolving) {
            return ThullaEngine.resolveTrick(thullaState);
          }
          return thullaState;
        });
      }
    }
  }

  void _handleBots(ThullaGameState state) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || state.hostUid != currentUser.uid) return;
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

    // Cache bots
    if (_bots.isEmpty) {
      for (final p in state.players) {
        if (p.isBot && p.botDifficulty != null) {
          _bots[p.id] = ThullaBot.create(p.botDifficulty!, p.name);
        }
      }
    }

    if (_bots.containsKey(currentPlayer.id)) {
      _lastBotTurnId = '${state.currentTrick.length}_${state.currentPlayerId}';

      final bot = _bots[currentPlayer.id]!;
      await BotDelay.simulateThinking(currentPlayer.botDifficulty!);

      // Re-fetch latest state
      final latestState = ref.read(onlineThullaProvider).value;
      if (latestState == null ||
          latestState.currentPlayerId != currentPlayer.id) {
        return;
      }

      final obs = ThullaBotObservation.fromState(latestState, currentPlayer.id);
      final cardToPlay = bot.chooseCard(obs);

      await playCard(currentPlayer.id, cardToPlay);
    }
  }

  Future<String?> playCard(String playerId, PlayingCard card) async {
    if (_isProcessing) return "Processing...";
    _isProcessing = true;

    try {
      final state = ref.read(onlineThullaProvider).value;
      if (state == null) return "Game not found.";
      if (state.trickResolving) return "Please wait...";

      String? error = ThullaEngine.getMoveError(state, playerId, card);
      if (error != null) return error;

      final firestore = ref.read(firestoreServiceProvider);
      await firestore.runGameTransaction(state.gameId, (latestState) {
        return ThullaEngine.playCard(
          latestState as ThullaGameState,
          playerId,
          card,
        );
      });

      return null;
    } finally {
      _isProcessing = false;
    }
  }
}
