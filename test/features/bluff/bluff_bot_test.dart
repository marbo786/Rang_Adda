import 'package:flutter_test/flutter_test.dart';
import 'package:rang_adda/shared/models/card_model.dart';
import 'package:rang_adda/shared/models/player.dart';
import 'package:rang_adda/shared/models/game_state.dart';
import 'package:rang_adda/features/bluff/engine/bluff_game_state.dart';
import 'package:rang_adda/features/bluff/engine/bluff_engine.dart';
import 'package:rang_adda/features/bluff/bot/bluff_bot_strategy.dart';
import 'package:rang_adda/features/bluff/bot/bluff_bot_easy.dart';
import 'package:rang_adda/features/bluff/bot/bluff_bot_medium.dart';
import 'package:rang_adda/features/bluff/bot/bluff_bot_hard.dart';
import 'package:rang_adda/shared/ai/bot_difficulty.dart';

void main() {
  group('Bluff Rule Fixes', () {
    late BluffGameState state;
    late Player p1;
    late Player p2;
    late Player p3;

    setUp(() {
      p1 = Player(id: 'p1', name: 'Player 1');
      p2 = Player(id: 'p2', name: 'Player 2');
      p3 = Player(id: 'p3', name: 'Player 3');
      state = BluffEngine.initializeGame([p1, p2, p3]);
    });

    test(
      'Rule fix: playCards throws if claimed rank doesn\'t match currentRoundRank',
      () {
        final p1Hand = state.players[0].hand;
        // Force p1 to play 2 cards and claim Kings
        final c1 = p1Hand[0];
        final c2 = p1Hand[1];
        state = BluffEngine.playCards(state, 'p1', [c1, c2], Rank.king);

        // Verify currentRoundRank is set
        expect(state.currentRoundRank, equals(Rank.king));

        // Force p2 to try and play claiming Queens
        final p2Hand = state.players[1].hand;
        final p2Card = p2Hand.first;

        expect(
          () => BluffEngine.playCards(state, 'p2', [p2Card], Rank.queen),
          throwsException,
        );
      },
    );

    test('Rule fix: new round resets currentRoundRank to null', () {
      // p1 plays Kings
      final p1Hand = state.players[0].hand;
      state = BluffEngine.playCards(state, 'p1', [
        p1Hand[0],
        p1Hand[1],
      ], Rank.king);
      expect(state.currentRoundRank, equals(Rank.king));

      // p2 passes
      state = BluffEngine.passTurn(state, 'p2');
      // p3 passes
      state = BluffEngine.passTurn(state, 'p3');

      // Round should end because everyone acted (p1 played, p2 passed, p3 passed)
      expect(state.currentRoundRank, isNull);
      expect(state.playersActedThisRound.isEmpty, isTrue);
      // Center pile should be cleared
      expect(state.centerPile.isEmpty, isTrue);
    });
  });

  group('Bluff Bot Easy', () {
    test('Easy bot respects currentRoundRank when set', () {
      final p1 = Player(
        id: 'bot1',
        name: 'Bot 1',
        isBot: true,
        botDifficulty: BotDifficulty.easy,
      );
      final p2 = Player(id: 'p2', name: 'Player 2');
      var state = BluffEngine.initializeGame([p1, p2]);

      // Give bot1 some cards
      state = state.copyWith(
        players: [
          p1.copyWith(
            hand: [const PlayingCard(suit: Suit.hearts, rank: Rank.five)],
          ),
          p2.copyWith(hand: []),
        ],
        currentRoundRank: Rank.seven,
        currentPlayerId: 'bot1',
        lastCardPlayerId:
            'p2', // So it can pass if it wants, but if it plays, it must be 7
      );

      final bot = BluffBotEasy();
      // Test multiple times since it's random
      for (int i = 0; i < 50; i++) {
        final action = bot.chooseAction(state, 'bot1');
        if (action is Play) {
          expect(action.claimedRank, equals(Rank.seven));
        }
      }
    });
  });

  group('Bluff Bot Medium', () {
    test(
      'Medium bot calls bluff when it holds 3 cards of claimed rank (certain bluff)',
      () {
        final p1 = Player(
          id: 'bot_med',
          name: 'Medium Bot',
          isBot: true,
          hand: [
            const PlayingCard(suit: Suit.hearts, rank: Rank.ace),
            const PlayingCard(suit: Suit.diamonds, rank: Rank.ace),
            const PlayingCard(suit: Suit.clubs, rank: Rank.ace),
          ],
        );
        final p2 = Player(id: 'p2', name: 'Player 2', hand: []);

        final state = BluffGameState(
          gameId: 'test',
          players: [p1, p2],
          currentPlayerId: 'bot_med',
          lastPlayerId: 'p2',
          lastCardPlayerId: 'p2',
          lastClaimedRank: Rank.ace,
          lastPlayedCards: [
            const PlayingCard(
              suit: Suit.spades,
              rank: Rank.two,
            ), // 2 cards claimed as Aces
            const PlayingCard(suit: Suit.hearts, rank: Rank.two),
          ],
          status: GameStatus.playing,
          centerPile: [
            const PlayingCard(suit: Suit.spades, rank: Rank.two),
            const PlayingCard(suit: Suit.hearts, rank: Rank.two),
          ],
        );

        final bot = BluffBotMedium();
        final action = bot.chooseAction(state, 'bot_med');

        expect(action, isA<CallBluff>());
      },
    );

    test('Medium bot plays honestly when it has cards of the round rank', () {
      final p1 = Player(
        id: 'bot_med',
        name: 'Medium Bot',
        isBot: true,
        hand: [
          const PlayingCard(
            suit: Suit.hearts,
            rank: Rank.five,
          ), // Has the required rank
          const PlayingCard(suit: Suit.diamonds, rank: Rank.ten),
        ],
      );
      final p2 = Player(id: 'p2', name: 'Player 2', hand: []);

      final state = BluffGameState(
        gameId: 'test',
        players: [p1, p2],
        currentPlayerId: 'bot_med',
        currentRoundRank: Rank.five,
        status: GameStatus.playing,
      );

      final bot = BluffBotMedium();
      final action = bot.chooseAction(state, 'bot_med');

      expect(action, isA<Play>());
      final play = action as Play;
      expect(play.claimedRank, equals(Rank.five));
      // Should play the 5 honestly
      expect(play.cards.first.rank, equals(Rank.five));
    });

    test(
      'Medium bot bluffs with 1 card when it doesn\'t have the round rank',
      () {
        final p1 = Player(
          id: 'bot_med',
          name: 'Medium Bot',
          isBot: true,
          hand: [
            const PlayingCard(suit: Suit.hearts, rank: Rank.two),
            const PlayingCard(suit: Suit.diamonds, rank: Rank.three),
          ],
        );
        final p2 = Player(id: 'p2', name: 'Player 2', hand: []);

        final state = BluffGameState(
          gameId: 'test',
          players: [p1, p2],
          currentPlayerId: 'bot_med',
          currentRoundRank: Rank.nine, // Doesn't have this
          status: GameStatus.playing,
          centerPile: List.generate(
            5,
            (_) => const PlayingCard(suit: Suit.hearts, rank: Rank.four),
          ), // pile is large enough to not just pass
        );

        final bot = BluffBotMedium();
        final action = bot.chooseAction(state, 'bot_med');

        expect(action, isA<Play>());
        final play = action as Play;
        expect(play.claimedRank, equals(Rank.nine));
        expect(
          play.cards.length,
          equals(1),
        ); // Should bluff with minimum exposure
      },
    );
  });

  group('Bluff Bot Hard', () {
    test('Hard bot plays all rank cards in endgame', () {
      final p1 = Player(
        id: 'bot_hard',
        name: 'Hard Bot',
        isBot: true,
        hand: [
          const PlayingCard(suit: Suit.hearts, rank: Rank.jack),
          const PlayingCard(suit: Suit.diamonds, rank: Rank.jack),
          const PlayingCard(suit: Suit.clubs, rank: Rank.jack),
        ], // Only 3 cards left -> Endgame!
      );
      final p2 = Player(
        id: 'p2',
        name: 'Player 2',
        hand: [const PlayingCard(suit: Suit.spades, rank: Rank.two)],
      ); // P2 has 1 card left

      final state = BluffGameState(
        gameId: 'test',
        players: [p1, p2],
        currentPlayerId: 'bot_hard',
        currentRoundRank: null, // New round
        status: GameStatus.playing,
      );

      final bot = BluffBotHard();
      final action = bot.chooseAction(state, 'bot_hard');

      expect(action, isA<Play>());
      final play = action as Play;
      expect(play.claimedRank, equals(Rank.jack));
      expect(play.cards.length, equals(3)); // Should dump everything it can
    });
  });
}
