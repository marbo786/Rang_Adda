import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rang_adda/shared/models/card_model.dart';
import 'package:rang_adda/shared/models/game_state.dart';
import 'package:rang_adda/features/bluff/engine/bluff_game_state.dart';
import 'package:rang_adda/features/bluff/engine/bluff_engine.dart';
import 'package:rang_adda/shared/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rang_adda/features/thulla/state/online_thulla_provider.dart';
import 'package:rang_adda/shared/ai/bot_observation.dart';
import 'package:rang_adda/features/bluff/ai/bluff_bot.dart';
import 'package:rang_adda/shared/ai/bot_delay.dart';

final onlineBluffProvider = StreamProvider<BluffGameState?>((ref) {
  final gameId = ref.watch(currentGameIdProvider);
  if (gameId == null) return const Stream.empty();

  final firestore = ref.read(firestoreServiceProvider);
  return firestore.streamGame(gameId).map((state) => state as BluffGameState?);
});

final onlineBluffActionProvider = Provider<OnlineBluffActionController>((ref) {
  return OnlineBluffActionController(ref);
});

class OnlineBluffActionController {
  final Ref ref;
  bool _isProcessing = false;
  final Map<String, BluffBot> _bots = {};
  String? _lastBotTurnId;
  int _lastCenterPileCount = 0;

  OnlineBluffActionController(this.ref) {
    ref.listen<AsyncValue<BluffGameState?>>(onlineBluffProvider, (
      previous,
      next,
    ) {
      final state = next.value;
      if (state != null) {
        if (state.pendingBluffCallerId != null &&
            previous?.value?.pendingBluffCallerId == null) {
          _handleBluffResolution(state);
        } else {
          _handleBots(state);
        }
      }
    });
  }

  Future<void> _handleBluffResolution(BluffGameState state) async {
    final callerId = state.pendingBluffCallerId!;
    bool isBluff = false;
    for (var card in state.lastPlayedCards) {
      if (card.rank != state.lastClaimedRank) {
        isBluff = true;
        break;
      }
    }

    final loserId = isBluff ? state.lastPlayerId! : callerId;
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null && loserId == currentUser.uid) {
      final firestore = ref.read(firestoreServiceProvider);
      await firestore.runGameTransaction(state.gameId, (latestState) {
        final bluffState = latestState as BluffGameState;
        if (bluffState.pendingBluffCallerId != null) {
          return BluffEngine.resolveBluffCall(bluffState);
        }
        return bluffState;
      });
    } else if (currentUser != null && state.hostUid == currentUser.uid) {
      // Host handles resolution if loser is a bot
      final loser = state.players.firstWhere((p) => p.id == loserId);
      if (loser.isBot) {
        final firestore = ref.read(firestoreServiceProvider);
        await firestore.runGameTransaction(state.gameId, (latestState) {
          final bluffState = latestState as BluffGameState;
          if (bluffState.pendingBluffCallerId != null) {
            return BluffEngine.resolveBluffCall(bluffState);
          }
          return bluffState;
        });
      }
    }
  }

  void _handleBots(BluffGameState state) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || state.hostUid != currentUser.uid) return;
    if (state.status == GameStatus.finished) return;
    if (state.resolvingBluffMessage != null) return;

    // Cache bots
    if (_bots.isEmpty) {
      for (final p in state.players) {
        if (p.isBot && p.botDifficulty != null) {
          _bots[p.id] = BluffBot.create(p.botDifficulty!, p.name);
        }
      }
    }

    // 1. Check if any bot wants to call a bluff on a new play
    if (state.centerPile.length > _lastCenterPileCount &&
        state.lastPlayerId != null &&
        state.lastClaimedRank != null) {
      _lastCenterPileCount = state.centerPile.length;

      for (final botId in _bots.keys) {
        if (botId == state.lastPlayerId) continue;
        final bot = _bots[botId]!;
        final botPlayer = state.players.firstWhere((p) => p.id == botId);
        final obs = BluffBotObservation.fromState(state, botId);

        final decision = bot.respondToPlay(obs);
        if (decision == BluffChallengeDecision.callBluff) {
          // Add artificial delay before calling bluff
          await BotDelay.simulateThinking(botPlayer.botDifficulty!);
          final latestState = ref.read(onlineBluffProvider).value;
          if (latestState != null &&
              latestState.pendingBluffCallerId == null &&
              latestState.centerPile.length == _lastCenterPileCount) {
            callBluff(botId);
            return;
          }
        }
      }
    } else if (state.centerPile.length < _lastCenterPileCount) {
      _lastCenterPileCount = state.centerPile.length;
    }

    // 2. Play Turn
    if (state.currentPlayerId?.isEmpty ?? true) return;

    final turnId =
        '${state.centerPile.length}_${state.consecutivePasses}_${state.currentPlayerId}';
    if (_lastBotTurnId == turnId) return;

    final currentPlayer = state.players.firstWhere(
      (p) => p.id == state.currentPlayerId,
    );
    if (!currentPlayer.isBot) return;

    if (_bots.containsKey(currentPlayer.id)) {
      _lastBotTurnId = turnId;

      final bot = _bots[currentPlayer.id]!;
      await BotDelay.simulateThinking(currentPlayer.botDifficulty!);

      final latestState = ref.read(onlineBluffProvider).value;
      if (latestState == null ||
          latestState.currentPlayerId != currentPlayer.id ||
          latestState.pendingBluffCallerId != null) {
        return;
      }

      final obs = BluffBotObservation.fromState(latestState, currentPlayer.id);

      if (latestState.centerPile.isNotEmpty) {
        // Did we want to pass? In our simple integration, if choosePlay returns cards we play them.
        // BluffBot does not explicitly pass right now except if forced (it shouldn't be).
      }

      final decision = bot.choosePlay(obs);
      if (decision.cards.isNotEmpty) {
        await playCard(currentPlayer.id, decision.cards, decision.claimedRank);
      } else {
        await passTurn(currentPlayer.id);
      }
    }
  }

  Future<String?> playCard(
    String playerId,
    List<PlayingCard> cards,
    Rank claimedRank,
  ) async {
    if (_isProcessing) return "Processing...";
    _isProcessing = true;

    try {
      final state = ref.read(onlineBluffProvider).value;
      if (state == null) return "Game not found.";

      String? error = BluffEngine.getMoveError(state, playerId, cards);
      if (error != null) return error;

      final firestore = ref.read(firestoreServiceProvider);
      await firestore.runGameTransaction(state.gameId, (latestState) {
        return BluffEngine.playCards(
          latestState as BluffGameState,
          playerId,
          cards,
          claimedRank,
        );
      });
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> passTurn(String playerId) async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final state = ref.read(onlineBluffProvider).value;
      if (state == null) return;

      final firestore = ref.read(firestoreServiceProvider);
      await firestore.runGameTransaction(state.gameId, (latestState) {
        var newState = BluffEngine.passTurn(
          latestState as BluffGameState,
          playerId,
        );
        return newState.copyWith(passToPlayerId: null);
      });
    } catch (e) {
      // ignore
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> callBluff(String callerId) async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final state = ref.read(onlineBluffProvider).value;
      if (state == null) return;

      final firestore = ref.read(firestoreServiceProvider);
      await firestore.runGameTransaction(state.gameId, (latestState) {
        return BluffEngine.callBluff(latestState as BluffGameState, callerId);
      });
    } catch (e) {
      // ignore
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> acknowledgeResolvingMessage() async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final state = ref.read(onlineBluffProvider).value;
      if (state == null) return;

      final firestore = ref.read(firestoreServiceProvider);
      await firestore.runGameTransaction(state.gameId, (latestState) {
        return (latestState as BluffGameState).copyWith(
          resolvingBluffMessage: null,
        );
      });
    } catch (e) {
      // ignore
    } finally {
      _isProcessing = false;
    }
  }
}
