import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/models/card_model.dart';
import '../core/bluff/bluff_game_state.dart';
import '../core/bluff/bluff_engine.dart';

class BluffNotifier extends Notifier<BluffGameState> {
  @override
  BluffGameState build() {
    // Initial empty state. To start a game, call startGame.
    return const BluffGameState(
      gameId: 'initial',
      players: [],
      currentPlayerId: '',
    );
  }

  void startGame(List<String> playerIds, [List<String>? playerNames]) {
    state = BluffEngine.initializeGame(playerIds, playerNames);
  }

  Future<String?> playCard(
    String playerId,
    List<PlayingCard> cards,
    Rank claimedRank,
  ) async {
    try {
      state = BluffEngine.playCards(state, playerId, cards, claimedRank);
      return null;
    } catch (e) {
      return e.toString().replaceAll("Exception: ", "");
    }
  }

  Future<String?> passTurn(String playerId) async {
    try {
      state = BluffEngine.passTurn(state, playerId);
      return null;
    } catch (e) {
      return e.toString().replaceAll("Exception: ", "");
    }
  }

  Future<String?> callBluff(String callerId) async {
    try {
      state = BluffEngine.callBluff(state, callerId);
      return null;
    } catch (e) {
      return e.toString().replaceAll("Exception: ", "");
    }
  }

  void acknowledgePass() {
    state = state.clearOverlays();
  }

  void declineChallenge() {
    state = state.copyWith(
      lastPlayerId: null,
      lastClaimedRank: null,
      lastPlayedCards: [],
    );
  }

  void acknowledgeResolvingMessage() {
    state = state.setResolvingMessage(
      '',
    ); // Need to support null clearing, wait, the method uses string?
    // Let's modify the engine or state to actually clear it using clearOverlays or similar.
    state = state.clearOverlays();
  }
}

final bluffProvider = NotifierProvider<BluffNotifier, BluffGameState>(() {
  return BluffNotifier();
});
