import 'package:flutter_test/flutter_test.dart';
import 'package:rang_adda/features/thulla/engine/thulla_engine.dart';
import 'package:rang_adda/shared/models/player.dart';
import 'package:rang_adda/shared/models/card_model.dart';
import 'package:rang_adda/shared/models/game_state.dart';

void main() {
  group('ThullaEngine', () {
    test('Initialization deals correct number of cards and sets starting player', () {
      final players = [
        const Player(id: 'p1', name: 'Alice'),
        const Player(id: 'p2', name: 'Bob'),
        const Player(id: 'p3', name: 'Charlie'),
        const Player(id: 'p4', name: 'Dave'),
      ];

      final state = ThullaEngine.initializeGame(players);
      
      expect(state.players.length, 4);
      for (var player in state.players) {
        expect(player.hand.length, 13);
        expect(player.cardCount, 13);
      }

      // Start player should have Ace of Spades
      final startPlayer = state.players.firstWhere((p) => p.id == state.currentPlayerId);
      expect(startPlayer.hand.contains(const PlayingCard(suit: Suit.spades, rank: Rank.ace)), isTrue);
      
      expect(state.status, GameStatus.playing);
    });

    test('Validates first trick requires Ace of Spades', () {
      final players = [
        const Player(id: 'p1', name: 'Alice'),
        const Player(id: 'p2', name: 'Bob'),
      ];
      final state = ThullaEngine.initializeGame(players);
      final startPlayerId = state.currentPlayerId!;
      final startPlayer = state.players.firstWhere((p) => p.id == startPlayerId);
      
      final wrongCard = startPlayer.hand.firstWhere((c) => c != const PlayingCard(suit: Suit.spades, rank: Rank.ace));
      
      final error = ThullaEngine.getMoveError(state, startPlayerId, wrongCard);
      expect(error, "First trick MUST start with the Ace of Spades!");
      
      final correctError = ThullaEngine.getMoveError(state, startPlayerId, const PlayingCard(suit: Suit.spades, rank: Rank.ace));
      expect(correctError, isNull);
    });
  });
}
