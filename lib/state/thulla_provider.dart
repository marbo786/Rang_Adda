import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/models/card_model.dart';
import '../core/thulla/thulla_game_state.dart';
import '../core/thulla/thulla_engine.dart';

final thullaProvider = NotifierProvider<ThullaNotifier, ThullaGameState?>(() {
  return ThullaNotifier();
});

class ThullaNotifier extends Notifier<ThullaGameState?> {
  @override
  ThullaGameState? build() {
    return null;
  }

  void startGame(List<String> playerNames) {
    state = ThullaEngine.initializeGame(playerNames);
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
      }
    }
    return null;
  }

  void acknowledgePass() {
    if (state == null) return;
    state = state!.copyWith(clearPassToPlayerId: true);
  }
}
