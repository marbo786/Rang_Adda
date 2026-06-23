import 'package:flutter_test/flutter_test.dart';
import 'package:rang_adda/features/bluff/engine/bluff_engine.dart';
import 'package:rang_adda/shared/models/card_model.dart';
import 'package:rang_adda/shared/models/game_state.dart';

void main() {
  group('BluffEngine Game Logic', () {
    test('calling bluff on yourself throws exception', () {
      final state = BluffEngine.initializeGame(['p1', 'p2']);
      
      // Simulate p1 played cards
      final stateAfterPlay = state.copyWith(
        lastPlayerId: 'p1',
        lastPlayedCards: [const PlayingCard(suit: Suit.hearts, rank: Rank.ace)],
        lastClaimedRank: Rank.ace,
        centerPile: [const PlayingCard(suit: Suit.hearts, rank: Rank.ace)],
      );

      expect(
        () => BluffEngine.callBluff(stateAfterPlay, 'p1'),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains("can't call bluff on yourself"))),
      );
    });

    test('calling bluff with empty pile throws exception', () {
      final state = BluffEngine.initializeGame(['p1', 'p2']);
      
      expect(
        () => BluffEngine.callBluff(state, 'p2'),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains("No cards to call bluff on"))),
      );
    });

    test('passTurn skips players with 0 cards', () {
      final state = BluffEngine.initializeGame(['p1', 'p2', 'p3']);
      
      // Simulate p2 having 0 cards
      final players = state.players.toList();
      players[1] = players[1].copyWith(hand: [], cardCount: 0);
      
      final modifiedState = state.copyWith(players: players, currentPlayerId: 'p1');
      
      final nextState = BluffEngine.passTurn(modifiedState, 'p1');
      
      // Since p2 has 0 cards, turn should pass to p3
      expect(nextState.currentPlayerId, 'p3');
    });
  });
}
