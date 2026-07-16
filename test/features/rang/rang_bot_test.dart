import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rang_adda/shared/models/card_model.dart';
import 'package:rang_adda/shared/models/player.dart';
import 'package:rang_adda/shared/models/game_state.dart';
import 'package:rang_adda/features/rang/engine/rang_game_state.dart';
import 'package:rang_adda/features/rang/engine/rang_engine.dart';
import 'package:rang_adda/features/rang/engine/rang_trick_play.dart';
import 'package:rang_adda/features/rang/bot/rang_bot_easy.dart';
import 'package:rang_adda/features/rang/bot/rang_bot_pimc.dart';
import 'package:rang_adda/features/rang/bot/rang_bot_hard.dart';
import 'package:rang_adda/features/rang/state/rang_provider.dart';
import 'package:rang_adda/shared/ai/bot_difficulty.dart';

void main() {
  group('Rang Bot Easy', () {
    test('Easy bot always returns a valid card', () {
      final p1 = Player(id: 'p1', name: 'Bot 1', isBot: true, hand: [const PlayingCard(suit: Suit.hearts, rank: Rank.two)]);
      final p2 = Player(id: 'p2', name: 'Player 2', hand: []);
      final p3 = Player(id: 'p3', name: 'Player 3', hand: []);
      final p4 = Player(id: 'p4', name: 'Player 4', hand: []);
      
      var state = RangEngine.initializeGame([p1, p2, p3, p4]);
      // Force trick play phase and make it p1's turn
      state = state.copyWith(
          phase: RangPhase.trickPlay, 
          trumpSuit: Suit.hearts, 
          currentPlayerId: 'p1',
          clearPassToPlayerId: true);

      final bot = RangBotEasy();
      final card = bot.chooseCard(state, 'p1');

      final error = RangEngine.getMoveError(state, 'p1', card);
      expect(error, isNull);
    });

    test('Easy bot returns a valid trump suit choice', () {
      final p1 = Player(id: 'p1', name: 'Bot 1', isBot: true);
      var state = RangEngine.initializeGame([p1, Player(id: 'p2', name: 'p2'), Player(id: 'p3', name: 'p3'), Player(id: 'p4', name: 'p4')]);
      
      final bot = RangBotEasy();
      final trump = bot.chooseTrump(state, 'p1');
      expect(Suit.values.contains(trump), isTrue);
    });
  });

  group('Rang Bot PIMC (Medium)', () {
    test('PIMC bot returns a valid card in opening position', () {
      final p1 = Player(id: 'p1', name: 'Bot 1', isBot: true, hand: [const PlayingCard(suit: Suit.hearts, rank: Rank.two)]);
      final p2 = Player(id: 'p2', name: 'Player 2', hand: []);
      final p3 = Player(id: 'p3', name: 'Player 3', hand: []);
      final p4 = Player(id: 'p4', name: 'Player 4', hand: []);
      
      var state = RangEngine.initializeGame([p1, p2, p3, p4]);
      state = state.copyWith(
          phase: RangPhase.trickPlay, 
          trumpSuit: Suit.hearts, 
          currentPlayerId: 'p1',
          clearPassToPlayerId: true);

      final bot = RangBotPIMC(numWorlds: 5, searchDepth: 1); // small params for fast test
      final card = bot.chooseCard(state, 'p1');

      final error = RangEngine.getMoveError(state, 'p1', card);
      expect(error, isNull);
    });

    test('PIMC bot returns a valid trump suit choice', () {
      final p1 = Player(id: 'p1', name: 'Bot 1', isBot: true);
      var state = RangEngine.initializeGame([p1, Player(id: 'p2', name: 'p2'), Player(id: 'p3', name: 'p3'), Player(id: 'p4', name: 'p4')]);
      
      final bot = RangBotPIMC(numWorlds: 1, searchDepth: 1);
      final trump = bot.chooseTrump(state, 'p1');
      expect(Suit.values.contains(trump), isTrue);
    });
  });

  group('Rang Bot Hard', () {
    test('Hard bot does NOT play trump when partner is winning the trick (non-trump available)', () {
      final p1 = Player(
        id: 'bot_hard', 
        name: 'Bot 1', 
        isBot: true,
        hand: [
          const PlayingCard(suit: Suit.hearts, rank: Rank.two), // Trump
          const PlayingCard(suit: Suit.diamonds, rank: Rank.two), // Non-trump
        ]
      );
      final p2 = Player(id: 'p2', name: 'Player 2', hand: []);
      final p3 = Player(id: 'p3', name: 'Partner', hand: []);
      final p4 = Player(id: 'p4', name: 'Player 4', hand: []);

      var state = RangGameState(
        gameId: 'test',
        dealerId: 'p4',
        players: [p1, p2, p3, p4], // p1 and p3 are partners
        currentPlayerId: 'bot_hard',
        trumpCallerId: 'p2',
        trumpSuit: Suit.hearts,
        leadSuit: Suit.clubs, // p3 lead with clubs
        status: GameStatus.playing,
        phase: RangPhase.trickPlay,
        currentTrick: [
          RangTrickPlay(playerId: 'p3', card: const PlayingCard(suit: Suit.clubs, rank: Rank.king)), // Partner played winning card
          RangTrickPlay(playerId: 'p4', card: const PlayingCard(suit: Suit.clubs, rank: Rank.two)), // Opponent played low
        ],
        teamASars: 0,
        teamBSars: 0,
        heap: []
      );

      final bot = RangBotHard();
      final card = bot.chooseCard(state, 'bot_hard');

      // Bot has no clubs (lead suit), so it can play anything.
      // But partner is winning with King of Clubs, so it should NOT play trump (Hearts).
      // It should dump the Diamond 2.
      expect(card.suit, equals(Suit.diamonds));
    });

    test('Hard bot leads trump when holding 3+ trump cards', () {
      final p1 = Player(
        id: 'bot_hard', 
        name: 'Bot 1', 
        isBot: true,
        hand: [
          const PlayingCard(suit: Suit.hearts, rank: Rank.ace),
          const PlayingCard(suit: Suit.hearts, rank: Rank.king),
          const PlayingCard(suit: Suit.hearts, rank: Rank.two),
          const PlayingCard(suit: Suit.diamonds, rank: Rank.ace),
        ]
      );
      
      var state = RangGameState(
        gameId: 'test',
        dealerId: 'bot_hard',
        players: [p1, Player(id: 'p2', name: 'p2'), Player(id: 'p3', name: 'p3'), Player(id: 'p4', name: 'p4')],
        currentPlayerId: 'bot_hard',
        trumpCallerId: 'bot_hard',
        trumpSuit: Suit.hearts,
        leadSuit: null,
        status: GameStatus.playing,
        phase: RangPhase.trickPlay,
        currentTrick: [], // Bot is leading
        teamASars: 0,
        teamBSars: 0,
        heap: []
      );

      final bot = RangBotHard();
      final card = bot.chooseCard(state, 'bot_hard');

      // Should lead highest trump (Ace of Hearts)
      expect(card.suit, equals(Suit.hearts));
      expect(card.rank, equals(Rank.ace));
    });
  });

  group('Rang Bot Stuck Fix', () {
    test('Provider handles startGame with bot trump caller without throwing', () {
      final p1 = Player(id: 'bot_caller', name: 'Bot 1', isBot: true, botDifficulty: BotDifficulty.easy, hand: []);
      final p2 = Player(id: 'p2', name: 'Player 2', hand: []);
      final p3 = Player(id: 'p3', name: 'Player 3', hand: []);
      final p4 = Player(id: 'p4', name: 'Player 4', hand: []);

      final container = ProviderContainer();
      final notifier = container.read(rangProvider.notifier);

      expect(() => notifier.startGame([p1, p2, p3, p4]), returnsNormally);
      
      final state = container.read(rangProvider);
      expect(state, isNotNull);
      // Wait for async operations to complete
    });
  });
}
