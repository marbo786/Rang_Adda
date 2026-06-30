import 'package:flutter_test/flutter_test.dart';
import 'package:rang_adda/features/rang/engine/rang_engine.dart';
import 'package:rang_adda/features/rang/engine/rang_game_state.dart';
import 'package:rang_adda/shared/models/player.dart';
import 'package:rang_adda/shared/models/card_model.dart';
import 'package:rang_adda/shared/models/game_state.dart';

void main() {
  group('RangEngine', () {
    test('Initialization deals correct number of cards and sets up Trump Caller', () {
      final players = [
        const Player(id: 'p1', name: 'Alice'),
        const Player(id: 'p2', name: 'Bob'),
        const Player(id: 'p3', name: 'Charlie'),
        const Player(id: 'p4', name: 'Dave'),
      ];

      final state = RangEngine.initializeGame(players);
      
      expect(state.players.length, 4);
      for (var player in state.players) {
        expect(player.hand.length, 13);
        expect(player.cardCount, 13);
      }

      // Dealer is p1, Trump caller should be p2
      expect(state.dealerId, 'p1');
      expect(state.trumpCallerId, 'p2');
      expect(state.phase, RangPhase.trumpSelection);
      expect(state.currentPlayerId, 'p2');
    });

    test('Trump declaration starts Trick Play', () {
      final players = [
        const Player(id: 'p1', name: 'Alice'),
        const Player(id: 'p2', name: 'Bob'),
        const Player(id: 'p3', name: 'Charlie'),
        const Player(id: 'p4', name: 'Dave'),
      ];
      var state = RangEngine.initializeGame(players);
      
      state = RangEngine.declareTrump(state, 'p2', Suit.spades);
      
      expect(state.phase, RangPhase.trickPlay);
      expect(state.trumpSuit, Suit.spades);
      // Trump caller gets to lead the first trick
      expect(state.currentPlayerId, 'p2');
      expect(state.passToPlayerId, isNull);
    });

    test('Validates following suit', () {
      final players = [
        const Player(id: 'p1', name: 'Alice'),
        const Player(id: 'p2', name: 'Bob'),
        const Player(id: 'p3', name: 'Charlie'),
        const Player(id: 'p4', name: 'Dave'),
      ];
      var state = RangEngine.initializeGame(players);
      state = RangEngine.declareTrump(state, 'p2', Suit.spades);
      
      // Force Bob's hand to have hearts and spades
      final bobId = 'p2';
      final bob = state.players.firstWhere((p) => p.id == bobId);
      final newBob = bob.copyWith(hand: const [
        PlayingCard(suit: Suit.hearts, rank: Rank.ace),
        PlayingCard(suit: Suit.spades, rank: Rank.ace),
      ]);
      
      state = state.copyWith(
        players: state.players.map((p) => p.id == bobId ? newBob : p).toList(),
        leadSuit: Suit.hearts, // Pretend Hearts was led
      );

      final wrongCard = const PlayingCard(suit: Suit.spades, rank: Rank.ace);
      final error = RangEngine.getMoveError(state, bobId, wrongCard);
      
      expect(error, "You must follow suit! Play a hearts.");
      
      final correctCard = const PlayingCard(suit: Suit.hearts, rank: Rank.ace);
      final correctError = RangEngine.getMoveError(state, bobId, correctCard);
      expect(correctError, isNull);
    });
  });
}
