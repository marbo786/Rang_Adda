import 'package:flutter_test/flutter_test.dart';
import 'package:rang_adda/features/thulla/engine/thulla_engine.dart';
import 'package:rang_adda/shared/models/card_model.dart';
import 'package:rang_adda/shared/models/player.dart';

void main() {
  group('ThullaEngine Initialization', () {
    test('distributes exactly 52 cards among players', () {
      final state = ThullaEngine.initializeGame([
        const Player(id: 'p1', name: 'p1'),
        const Player(id: 'p2', name: 'p2'),
        const Player(id: 'p3', name: 'p3'),
        const Player(id: 'p4', name: 'p4'),
      ]);

      int totalCards = 0;
      for (var player in state.players) {
        totalCards += player.hand.length;
      }

      expect(totalCards, 52);
      expect(state.players[0].hand.length, 13);
      expect(state.players[1].hand.length, 13);
      expect(state.players[2].hand.length, 13);
      expect(state.players[3].hand.length, 13);
    });

    test('distributes remainder cards fairly if not divisible by players', () {
      final state = ThullaEngine.initializeGame([
        const Player(id: 'p1', name: 'p1'),
        const Player(id: 'p2', name: 'p2'),
        const Player(id: 'p3', name: 'p3'),
      ]);

      // 52 / 3 = 17, with 1 remainder
      expect(state.players[0].hand.length, 18);
      expect(state.players[1].hand.length, 17);
      expect(state.players[2].hand.length, 17);
    });

    test('player with Ace of Spades starts the game', () {
      final state = ThullaEngine.initializeGame([
        const Player(id: 'p1', name: 'p1'),
        const Player(id: 'p2', name: 'p2'),
        const Player(id: 'p3', name: 'p3'),
        const Player(id: 'p4', name: 'p4'),
      ]);

      // Find the player with Ace of Spades
      String aceOfSpadesOwnerId = '';
      for (var p in state.players) {
        bool hasAceSpades = p.hand.any(
          (c) => c.suit == Suit.spades && c.rank == Rank.ace,
        );
        if (hasAceSpades) {
          aceOfSpadesOwnerId = p.id;
          break;
        }
      }

      expect(state.currentPlayerId, aceOfSpadesOwnerId);
    });
  });
}
