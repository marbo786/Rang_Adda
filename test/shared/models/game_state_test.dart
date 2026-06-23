import 'package:flutter_test/flutter_test.dart';
import 'package:rang_adda/features/thulla/engine/thulla_game_state.dart';
import 'package:rang_adda/shared/models/card_model.dart';
import 'package:rang_adda/shared/models/game_state.dart';
import 'package:rang_adda/shared/models/player.dart';

void main() {
  group('ThullaGameState Serialization', () {
    test('toJson and fromJson work correctly', () {
      final state = ThullaGameState(
        gameId: 'test_game',
        hostUid: 'host123',
        status: GameStatus.playing,
        players: [
          Player(
            id: 'p1',
            name: 'Player 1',
            hand: [const PlayingCard(suit: Suit.hearts, rank: Rank.ace)],
            cardCount: 1,
          )
        ],
        currentPlayerId: 'p1',
        currentTrick: [const TrickPlay(playerId: 'p1', card: PlayingCard(suit: Suit.spades, rank: Rank.king))],
      );

      final json = state.toJson();
      final decodedState = ThullaGameState.fromJson(json);

      expect(decodedState.gameId, 'test_game');
      expect(decodedState.hostUid, 'host123');
      expect(decodedState.status, GameStatus.playing);
      expect(decodedState.players.length, 1);
      expect(decodedState.players[0].id, 'p1');
      expect(decodedState.players[0].hand.length, 1);
      expect(decodedState.currentTrick.length, 1);
      expect(decodedState.leadSuit, Suit.spades);
    });

    test('fromJson handles null hostUid gracefully', () {
      final json = {
        'gameId': 'test_game',
        'status': GameStatus.waiting.index,
        'players': [],
        'currentTrick': [],
        'wastePile': [],
        'createdAt': DateTime.now().toIso8601String(),
        'lastUpdatedAt': DateTime.now().toIso8601String(),
      };

      final decodedState = ThullaGameState.fromJson(json);
      expect(decodedState.hostUid, null);
    });
  });
}
