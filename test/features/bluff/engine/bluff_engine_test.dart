import 'package:flutter_test/flutter_test.dart';
import 'package:rang_adda/features/bluff/engine/bluff_engine.dart';
import 'package:rang_adda/shared/models/player.dart';
import 'package:rang_adda/shared/models/card_model.dart';
import 'package:rang_adda/shared/models/game_state.dart';

void main() {
  group('BluffEngine', () {
    test('Initialization deals correct number of cards', () {
      final players = [
        const Player(id: 'p1', name: 'Alice'),
        const Player(id: 'p2', name: 'Bob'),
        const Player(id: 'p3', name: 'Charlie'),
        const Player(id: 'p4', name: 'Dave'),
      ];

      final state = BluffEngine.initializeGame(players);
      
      expect(state.players.length, 4);
      for (var player in state.players) {
        expect(player.hand.length, 13);
        expect(player.cardCount, 13);
      }
      expect(state.status, GameStatus.playing);
    });

    test('Validates play amount', () {
      final players = [
        const Player(id: 'p1', name: 'Alice'),
        const Player(id: 'p2', name: 'Bob'),
      ];
      final state = BluffEngine.initializeGame(players);
      final startPlayerId = state.currentPlayerId!;
      final startPlayer = state.players.firstWhere((p) => p.id == startPlayerId);
      
      final emptyCards = <PlayingCard>[];
      final errorEmpty = BluffEngine.getMoveError(state, startPlayerId, emptyCards);
      expect(errorEmpty, "You must select between 1 and 4 cards.");

      final oneCard = [startPlayer.hand.first];
      final errorOneFirst = BluffEngine.getMoveError(state, startPlayerId, oneCard);
      expect(errorOneFirst, "You must play at least 2 cards to start a new pile.");
    });
  });
}
