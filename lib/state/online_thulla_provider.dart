import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/models/card_model.dart';
import '../core/thulla/thulla_game_state.dart';
import '../core/thulla/thulla_engine.dart';
import '../services/firestore_service.dart';

final currentGameIdProvider = NotifierProvider<CurrentGameIdNotifier, String?>(
  () {
    return CurrentGameIdNotifier();
  },
);

class CurrentGameIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void setId(String? id) => state = id;
}

final onlineThullaProvider = StreamProvider<ThullaGameState?>((ref) {
  final gameId = ref.watch(currentGameIdProvider);
  if (gameId == null) return const Stream.empty();

  final firestore = ref.read(firestoreServiceProvider);
  return firestore.streamGame(gameId);
});

final onlineActionProvider = Provider<OnlineActionController>((ref) {
  return OnlineActionController(ref);
});

class OnlineActionController {
  final Ref ref;
  bool _isProcessing = false;

  OnlineActionController(this.ref);

  Future<String?> playCard(String playerId, PlayingCard card) async {
    if (_isProcessing) return "Processing...";
    _isProcessing = true;

    try {
      final state = ref.read(onlineThullaProvider).value;
      if (state == null) return "Game not found.";
      if (state.trickResolving) return "Please wait...";

      String? error = ThullaEngine.getMoveError(state, playerId, card);
      if (error != null) return error;

      var newState = ThullaEngine.playCard(state, playerId, card);
      final firestore = ref.read(firestoreServiceProvider);

      await firestore.updateGameState(newState);

      if (newState.trickResolving) {
        await Future.delayed(const Duration(milliseconds: 1500));
        final currentState = ref.read(onlineThullaProvider).value;
        if (currentState != null && currentState.trickResolving) {
          final resolvedState = ThullaEngine.resolveTrick(currentState);
          await firestore.updateGameState(resolvedState);
        }
      }
      return null;
    } finally {
      _isProcessing = false;
    }
  }
}
