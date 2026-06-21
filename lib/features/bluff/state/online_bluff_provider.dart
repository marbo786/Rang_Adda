import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rang_adda/shared/models/card_model.dart';
import 'package:rang_adda/features/bluff/engine/bluff_game_state.dart';
import 'package:rang_adda/features/bluff/engine/bluff_engine.dart';
import 'package:rang_adda/shared/services/firestore_service.dart';
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

  OnlineBluffActionController(this.ref);

  Future<String?> playCard(String playerId, List<PlayingCard> cards, Rank claimedRank) async {
    if (_isProcessing) return "Processing...";
    _isProcessing = true;

    try {
      final state = ref.read(onlineBluffProvider).value;
      if (state == null) return "Game not found.";

      String? error = BluffEngine.getMoveError(state, playerId, cards);
      if (error != null) return error;

      var newState = BluffEngine.playCards(state, playerId, cards, claimedRank);
      final firestore = ref.read(firestoreServiceProvider);

      await firestore.updateGameState(newState);
      return null;
    } catch(e) {
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

      var newState = BluffEngine.passTurn(state, playerId);
      // Online doesn't need "pass device" so we instantly acknowledge
      newState = newState.copyWith(passToPlayerId: null);
      
      final firestore = ref.read(firestoreServiceProvider);
      await firestore.updateGameState(newState);
    } catch (e) {
      print("Error passing turn: $e");
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

      var newState = BluffEngine.callBluff(state, callerId);
      final firestore = ref.read(firestoreServiceProvider);
      await firestore.updateGameState(newState);
    } catch (e) {
      print("Error calling bluff: $e");
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
      print("Error acknowledging message: $e");
    } finally {
      _isProcessing = false;
    }
  }
}
