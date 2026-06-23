import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rang_adda/shared/models/card_model.dart';
import 'package:rang_adda/features/bluff/engine/bluff_game_state.dart';
import 'package:rang_adda/features/bluff/engine/bluff_engine.dart';
import 'package:rang_adda/shared/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rang_adda/features/thulla/state/online_thulla_provider.dart';

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

  OnlineBluffActionController(this.ref) {
    ref.listen<AsyncValue<BluffGameState?>>(onlineBluffProvider, (
      previous,
      next,
    ) {
      final state = next.value;
      if (state != null &&
          state.pendingBluffCallerId != null &&
          previous?.value?.pendingBluffCallerId == null) {
        _handleBluffResolution(state);
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

    // Only the loser who picks up the pile runs the transaction
    if (currentUser != null && loserId == currentUser.uid) {
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

      var newState = state.copyWith(resolvingBluffMessage: null);
      final firestore = ref.read(firestoreServiceProvider);
      await firestore.updateGameState(newState);
    } catch (e) {
      // ignore
    } finally {
      _isProcessing = false;
    }
  }
}
