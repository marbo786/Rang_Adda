import 'package:flutter_test/flutter_test.dart';
import 'package:rang_adda/core/models/card_model.dart';
import 'package:rang_adda/core/models/game_state.dart';
import 'package:rang_adda/core/models/player.dart';
import 'package:rang_adda/core/thulla/thulla_game_state.dart';
import 'package:rang_adda/core/thulla/thulla_engine.dart';

void main() {
  group('ThullaEngine', () {
    test('Initialization deals 52 cards and gives Ace of Spades to start', () {
      final state = ThullaEngine.initializeGame(['p1', 'p2', 'p3']);
      expect(state.players.length, 3);
      
      int totalCards = state.players.fold(0, (sum, p) => sum + p.hand.length);
      expect(totalCards, 52);

      final starter = state.players.firstWhere((p) => p.id == state.currentPlayerId);
      expect(starter.hand.contains(const PlayingCard(suit: Suit.spades, rank: Rank.ace)), isTrue);
    });

    ThullaGameState getTestState() {
       return ThullaGameState(
          gameId: 'test',
          players: [
             Player(id: 'p1', name: 'p1', hand: const [
                PlayingCard(suit: Suit.spades, rank: Rank.ace),
                PlayingCard(suit: Suit.hearts, rank: Rank.two),
             ]),
             Player(id: 'p2', name: 'p2', hand: const [
                PlayingCard(suit: Suit.spades, rank: Rank.king),
                PlayingCard(suit: Suit.diamonds, rank: Rank.two),
             ]),
             Player(id: 'p3', name: 'p3', hand: const [
                PlayingCard(suit: Suit.clubs, rank: Rank.king),
                PlayingCard(suit: Suit.hearts, rank: Rank.ace),
             ]),
          ],
          status: GameStatus.playing,
          currentPlayerId: 'p1',
          passToPlayerId: null,
          isFirstTrick: true,
          powerPlayerId: 'p1',
          isOnline: true,
       );
    }

    test('First trick ignores Tochoo and routes to Waste Pile', () {
       var state = getTestState();
       
       // p1 plays Ace of Spades
       state = ThullaEngine.playCard(state, 'p1', const PlayingCard(suit: Suit.spades, rank: Rank.ace));
       expect(state.trickResolving, isFalse);
       expect(state.currentPlayerId, 'p2');
       
       // p2 plays King of Spades
       state = ThullaEngine.playCard(state, 'p2', const PlayingCard(suit: Suit.spades, rank: Rank.king));
       expect(state.trickResolving, isFalse);
       
       // p3 does NOT have spades, plays King of Clubs
       state = ThullaEngine.playCard(state, 'p3', const PlayingCard(suit: Suit.clubs, rank: Rank.king));
       
       // Trick should resolve normally (First Trick rule)
       expect(state.trickResolving, isTrue);
       
       state = ThullaEngine.resolveTrick(state);
       expect(state.isFirstTrick, isFalse);
       expect(state.wastePile.length, 3);
       expect(state.currentPlayerId, 'p1'); // p1 had highest spade (Ace)
    });

    test('Tochoo logic forces highest lead player to pick up cards', () {
       var state = getTestState().copyWith(isFirstTrick: false); // Bypass first trick
       
       // Change hands to force a Tochoo
       state = state.copyWith(players: [
          Player(id: 'p1', name: 'p1', hand: const [PlayingCard(suit: Suit.hearts, rank: Rank.king)]),
          Player(id: 'p2', name: 'p2', hand: const [PlayingCard(suit: Suit.diamonds, rank: Rank.two)]), // No hearts!
          Player(id: 'p3', name: 'p3', hand: const [PlayingCard(suit: Suit.clubs, rank: Rank.two)]), // Keep p3 alive
       ], currentPlayerId: 'p1');

       state = ThullaEngine.playCard(state, 'p1', const PlayingCard(suit: Suit.hearts, rank: Rank.king));
       state = ThullaEngine.playCard(state, 'p2', const PlayingCard(suit: Suit.diamonds, rank: Rank.two));
       
       expect(state.trickResolving, isTrue);
       
       state = ThullaEngine.resolveTrick(state);
       
       final p1 = state.players.firstWhere((p) => p.id == 'p1');
       expect(p1.hand.length, 2); // Picked up both cards
       expect(state.wastePile.length, 0); // Nothing to waste
       expect(state.currentPlayerId, 'p1'); // p1 has to lead again
    });

    test('Empty Hand Draw logic (Winning a trick with 0 cards forces draw)', () {
       var state = getTestState().copyWith(isFirstTrick: false, wastePile: const [PlayingCard(suit: Suit.clubs, rank: Rank.two)]);
       
       state = state.copyWith(players: [
          Player(id: 'p1', name: 'p1', hand: const [PlayingCard(suit: Suit.hearts, rank: Rank.ace)]), // 1 card left
          Player(id: 'p2', name: 'p2', hand: const [PlayingCard(suit: Suit.hearts, rank: Rank.two)]),
       ], currentPlayerId: 'p1');

       state = ThullaEngine.playCard(state, 'p1', const PlayingCard(suit: Suit.hearts, rank: Rank.ace));
       state = ThullaEngine.playCard(state, 'p2', const PlayingCard(suit: Suit.hearts, rank: Rank.two));
       
       state = ThullaEngine.resolveTrick(state);
       
       final p1 = state.players.firstWhere((p) => p.id == 'p1');
       expect(p1.hand.length, 1); // Drew 1 card from waste pile
       
       // Because it's a random draw, it could be the Two of Clubs (from initial waste) or Ace/Two of Hearts (from trick)
       final possibleDraws = [
          const PlayingCard(suit: Suit.clubs, rank: Rank.two),
          const PlayingCard(suit: Suit.hearts, rank: Rank.ace),
          const PlayingCard(suit: Suit.hearts, rank: Rank.two),
       ];
       expect(possibleDraws.contains(p1.hand.first), isTrue);
       expect(state.wastePile.length, 2); // 3 total - 1 drawn = 2
    });

    test('End Game Win Condition triggers when 1 player left', () {
       var state = getTestState().copyWith(players: [
          Player(id: 'p1', name: 'p1', hand: const []),
          Player(id: 'p2', name: 'p2', hand: const []),
          Player(id: 'p3', name: 'p3', hand: const [PlayingCard(suit: Suit.spades, rank: Rank.two)]),
       ]);
       
       // Resolving a trick checks win condition (make p3 win it so p1/p2 don't draw from waste pile)
       state = ThullaEngine.resolveTrick(state.copyWith(trickResolving: true, currentTrick: [TrickPlay(playerId: 'p3', card: const PlayingCard(suit: Suit.hearts, rank: Rank.two))]));
       
       expect(state.status, GameStatus.finished);
       expect(state.currentPlayerId, isNull);
    });
  });
}
