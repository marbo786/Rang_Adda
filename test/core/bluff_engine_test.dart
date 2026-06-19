import 'package:flutter_test/flutter_test.dart';
import 'package:rang_adda/core/models/card_model.dart';
import 'package:rang_adda/core/bluff/bluff_game_state.dart';
import 'package:rang_adda/core/bluff/bluff_engine.dart';

void main() {
  group('BluffEngine Tests', () {
    late BluffGameState state;

    setUp(() {
      state = BluffEngine.initializeGame(['p1', 'p2', 'p3'], ['Player 1', 'Player 2', 'Player 3']);
    });

    test('Initialization deals exactly 52 cards', () {
      int totalCards = state.players.fold(0, (sum, p) => sum + p.hand.length);
      expect(totalCards, 52);
      expect(state.players[0].hand.length, 18); // 52 / 3 = 17 or 18
      expect(state.currentRequiredRank, Rank.ace);
      expect(state.currentPlayerId, 'p1');
    });

    test('Play 1 card correctly', () {
      final player1 = state.players[0];
      final cardToPlay = player1.hand.first;
      
      var newState = BluffEngine.playCards(state, 'p1', [cardToPlay]);
      
      expect(newState.centerPile.length, 1);
      expect(newState.lastPlayedCards.length, 1);
      expect(newState.lastClaimedRank, Rank.ace);
      expect(newState.currentRequiredRank, Rank.two);
      expect(newState.currentPlayerId, 'p2');
      expect(newState.lastPlayerId, 'p1');
      expect(newState.passToPlayerId, 'p2');
    });

    test('Call Bluff successfully (Player Lied)', () {
      final player1 = state.players[0];
      // Pick a card that is definitely NOT an Ace (since required rank is Ace)
      final cardToPlay = player1.hand.firstWhere((c) => c.rank != Rank.ace);
      
      var s1 = BluffEngine.playCards(state, 'p1', [cardToPlay]);
      var s2 = BluffEngine.callBluff(s1, 'p2');
      
      // Since p1 lied, p1 picks up the pile
      final p1NewHand = s2.players.firstWhere((p) => p.id == 'p1').hand;
      expect(p1NewHand.contains(cardToPlay), true);
      expect(s2.centerPile.isEmpty, true);
      
      // The current player remains what it was supposed to be (p2),
      // as play continues normally
      expect(s2.currentPlayerId, 'p2');
    });

    test('Call Bluff fails (Player told Truth)', () {
      final player1 = state.players[0];
      // Try to find an Ace. If p1 has an Ace, they play it.
      final aceCard = player1.hand.cast<PlayingCard?>().firstWhere((c) => c!.rank == Rank.ace, orElse: () => null);
      
      if (aceCard != null) {
        var s1 = BluffEngine.playCards(state, 'p1', [aceCard]);
        var s2 = BluffEngine.callBluff(s1, 'p2');
        
        // p1 told truth. Caller (p2) picks up pile.
        final p2NewHand = s2.players.firstWhere((p) => p.id == 'p2').hand;
        expect(p2NewHand.contains(aceCard), true);
      }
    });

    test('Pass turn logic', () {
      var s1 = BluffEngine.passTurn(state, 'p1');
      expect(s1.currentPlayerId, 'p2');
      expect(s1.currentRequiredRank, Rank.two);
      expect(s1.consecutivePasses, 1);
      
      var s2 = BluffEngine.passTurn(s1, 'p2');
      var s3 = BluffEngine.passTurn(s2, 'p3'); // All 3 passed
      
      expect(s3.centerPile.isEmpty, true); // Pile cleared
      expect(s3.consecutivePasses, 0); // Reset
      expect(s3.currentPlayerId, 'p1');
    });
  });
}
