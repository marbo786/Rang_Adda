import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rang_adda/shared/models/card_model.dart';
import 'package:rang_adda/features/rang/engine/rang_game_state.dart';
import 'package:rang_adda/features/rang/engine/rang_engine.dart';

final rangProvider = NotifierProvider<RangNotifier, RangGameState?>(() {
  return RangNotifier();
});

class RangNotifier extends Notifier<RangGameState?> {
  @override
  RangGameState? build() {
    return null;
  }

  void startGame(List<String> playerNames) {
    state = RangEngine.initializeGame(playerNames);
  }

  void declareTrump(String callerId, Suit suit) {
    if (state == null) return;
    try {
      state = RangEngine.declareTrump(state!, callerId, suit);
    } catch (e) {
      // Ignore or let error propagate? The engine throws an Exception on failure.
      // We catch it so it doesn't crash the UI layer if called invalidly.
    }
  }

  Future<String?> playCard(String playerId, PlayingCard card) async {
    if (state == null) return "Game not ready.";
    
    // Note: RangEngine resolves the trick instantly upon the 4th card being played.
    String? error = RangEngine.getMoveError(state!, playerId, card);
    if (error != null) return error;

    state = RangEngine.playCard(state!, playerId, card);
    return null;
  }

  void acknowledgePass() {
    if (state == null) return;
    state = state!.copyWith(clearPassToPlayerId: true);
  }
}
