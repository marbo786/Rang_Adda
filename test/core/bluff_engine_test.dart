import 'package:flutter_test/flutter_test.dart';
import 'package:rang_adda/shared/models/card_model.dart';
import 'package:rang_adda/features/bluff/engine/bluff_game_state.dart';
import 'package:rang_adda/features/bluff/engine/bluff_engine.dart';

void main() {
  group('BluffEngine Tests', () {
    late BluffGameState state;

    setUp(() {
      state = BluffEngine.initializeGame(
        ['p1', 'p2', 'p3'],
        ['Player 1', 'Player 2', 'Player 3'],
      );
    });

    test('Initialization deals exactly 52 cards', () {
      int totalCards = state.players.fold(0, (sum, p) => sum + p.hand.length);
      expect(totalCards, 52);
      expect(state.players[0].hand.length, 18);
      expect(state.currentPlayerId, 'p1');
    });

    test('Play 2 cards correctly as first player', () {
      final player1 = state.players[0];
      final cardsToPlay = player1.hand.take(2).toList();

      var newState = BluffEngine.playCards(state, 'p1', cardsToPlay, Rank.five);

      expect(newState.centerPile.length, 2);
      expect(newState.lastPlayedCards.length, 2);
      expect(newState.lastClaimedRank, Rank.five);
      expect(newState.currentPlayerId, 'p2');
      expect(newState.lastPlayerId, 'p1');
      expect(newState.passToPlayerId, 'p2');
    });

    test('Playing 1 card on empty pile throws error', () {
      final player1 = state.players[0];
      final cardsToPlay = player1.hand.take(1).toList();

      expect(
        () => BluffEngine.playCards(state, 'p1', cardsToPlay, Rank.ace),
        throwsException,
      );
    });

    test('Subsequent player can play 1 card', () {
      final player1 = state.players[0];
      var s1 = BluffEngine.playCards(
        state,
        'p1',
        player1.hand.take(2).toList(),
        Rank.ten,
      );

      final player2 = s1.players[1];
      var s2 = BluffEngine.playCards(
        s1,
        'p2',
        player2.hand.take(1).toList(),
        Rank.jack,
      );

      expect(s2.centerPile.length, 3);
      expect(s2.lastClaimedRank, Rank.jack);
      expect(s2.lastPlayedCards.length, 1);
    });

    test('Call Bluff successfully (Player Lied)', () {
      final player1 = state.players[0];
      final cardsToPlay = player1.hand.take(2).toList();
      // Lie about rank
      Rank lieRank = cardsToPlay[0].rank == Rank.ace ? Rank.two : Rank.ace;

      var s1 = BluffEngine.playCards(state, 'p1', cardsToPlay, lieRank);
      var s2 = BluffEngine.callBluff(s1, 'p2');

      final p1NewHand = s2.players.firstWhere((p) => p.id == 'p1').hand;
      expect(p1NewHand.contains(cardsToPlay[0]), true);
      expect(s2.centerPile.isEmpty, true);
    });

    test('Pass turn logic', () {
      var s1 = BluffEngine.passTurn(state, 'p1');
      expect(s1.currentPlayerId, 'p2');
      expect(s1.consecutivePasses, 1);

      var s2 = BluffEngine.passTurn(s1, 'p2');
      var s3 = BluffEngine.passTurn(s2, 'p3'); // All 3 passed

      expect(s3.centerPile.isEmpty, true); // Pile cleared
      expect(s3.consecutivePasses, 0); // Reset
      expect(s3.currentPlayerId, 'p1');
    });
  });
}
