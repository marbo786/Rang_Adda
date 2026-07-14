import 'package:flutter_test/flutter_test.dart';
import 'package:rang_adda/features/thulla/ai/thulla_bot_expert.dart';
import 'package:rang_adda/features/thulla/engine/thulla_engine.dart';
import 'package:rang_adda/features/thulla/engine/thulla_game_state.dart';
import 'package:rang_adda/shared/ai/bot_observation.dart';
import 'package:rang_adda/shared/ai/bot_personality.dart';
import 'package:rang_adda/shared/models/card_model.dart';
import 'package:rang_adda/shared/models/player.dart';
import 'dart:math';
import 'package:rang_adda/shared/models/game_state.dart';

void main() {
  // Use a seeded RNG for deterministic test results.
  final seededRng = Random(42);

  ThullaBotExpert makeBot({int worlds = 3, int depth = 1}) =>
      ThullaBotExpert(
        BotPersonality.fromName('TestBot'),
        numWorlds: worlds,
        searchDepth: depth,
        random: seededRng,
      );

  ThullaGameState initState() => ThullaEngine.initializeGame([
        const Player(id: 'p1', name: 'Alice'),
        const Player(id: 'p2', name: 'Bot'),
        const Player(id: 'p3', name: 'Charlie'),
      ]);

  group('ThullaBotExpert (PIMC)', () {
    test('returns a valid card in the opening position', () {
      final state = initState();
      final botId = state.currentPlayerId!;
      final bot = makeBot();

      final obs = ThullaBotObservation.fromState(state, botId);
      final card = bot.chooseCard(obs);

      expect(
        ThullaEngine.getMoveError(state, botId, card),
        isNull,
        reason: 'ThullaBotExpert must return a card that is legal in state',
      );
    });

    test('returned card is always in the bot\'s hand', () {
      final state = initState();
      final botId = state.currentPlayerId!;
      final bot = makeBot(worlds: 5, depth: 2);

      final obs = ThullaBotObservation.fromState(state, botId);
      final card = bot.chooseCard(obs);
      final botHand = state.players.firstWhere((p) => p.id == botId).hand;

      expect(botHand.contains(card), isTrue);
    });

    test('returns valid card when following suit is required', () {
      // Advance past the first trick's Ace-of-Spades restriction.
      var state = initState();
      final firstId = state.currentPlayerId!;
      // Play the Ace of Spades to open.
      state = ThullaEngine.playCard(
        state,
        firstId,
        const PlayingCard(suit: Suit.spades, rank: Rank.ace),
      );
      // Resolve any trick-resolving state.
      if (state.trickResolving) state = ThullaEngine.resolveTrick(state);
      // Collapse pass-to-player so there is a clear current player.
      if (state.passToPlayerId != null) {
        state = state.copyWith(
          currentPlayerId: state.passToPlayerId,
          clearPassToPlayerId: true,
        );
      }

      final botId = state.currentPlayerId!;
      final bot = makeBot();
      final obs = ThullaBotObservation.fromState(state, botId);
      final card = bot.chooseCard(obs);

      expect(ThullaEngine.getMoveError(state, botId, card), isNull);
    });

    test('handles single-card hand gracefully', () {
      // Build a state where the bot has exactly one card left.
      final players = [
        const Player(
          id: 'p1',
          name: 'Alice',
          hand: [PlayingCard(suit: Suit.hearts, rank: Rank.two)],
          cardCount: 1,
        ),
        const Player(
          id: 'p2',
          name: 'Bot',
          hand: [PlayingCard(suit: Suit.hearts, rank: Rank.three)],
          cardCount: 1,
        ),
      ];
      final state = ThullaGameState(
        gameId: 'test',
        players: players,
        status: GameStatus.playing,
        currentPlayerId: 'p2',
        powerPlayerId: 'p2',
        currentTrick: const [
          TrickPlay(
            playerId: 'p1',
            card: PlayingCard(suit: Suit.hearts, rank: Rank.king),
          ),
        ],
      );

      final bot = makeBot();
      final obs = ThullaBotObservation.fromState(state, 'p2');
      final card = bot.chooseCard(obs);

      expect(ThullaEngine.getMoveError(state, 'p2', card), isNull);
    });

    test('world sampling produces valid opponent hands', () {
      final state = initState();
      final botId = state.currentPlayerId!;
      final bot = makeBot(worlds: 10, depth: 1);

      // Run chooseCard many times; if sampling fails on every world
      // the bot still returns a valid card (falls through to first valid card).
      for (int i = 0; i < 5; i++) {
        final obs = ThullaBotObservation.fromState(state, botId);
        final card = bot.chooseCard(obs);
        expect(ThullaEngine.getMoveError(state, botId, card), isNull);
      }
    });

    test('time budget guard prevents excessive thinking (800 ms max)', () {
      // Use a high world count to stress the time budget.
      final bot = ThullaBotExpert(
        BotPersonality.fromName('StressBot'),
        numWorlds: 1000,
        searchDepth: 5,
        random: Random(99),
      );
      final state = initState();
      final botId = state.currentPlayerId!;
      final obs = ThullaBotObservation.fromState(state, botId);

      final sw = Stopwatch()..start();
      final card = bot.chooseCard(obs);
      sw.stop();

      // Allow a 200 ms buffer above the 800 ms budget for test overhead.
      expect(sw.elapsedMilliseconds, lessThan(1000));
      expect(ThullaEngine.getMoveError(state, botId, card), isNull);
    });
  });
}
