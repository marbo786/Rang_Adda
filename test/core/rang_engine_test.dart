import 'package:flutter_test/flutter_test.dart';
import 'package:rang_adda/core/models/card_model.dart';
import 'package:rang_adda/core/models/game_state.dart';
import 'package:rang_adda/core/models/player.dart';
import 'package:rang_adda/core/rang/rang_game_state.dart';
import 'package:rang_adda/core/rang/rang_trick_play.dart';
import 'package:rang_adda/core/rang/rang_engine.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Returns a minimal valid 4-player state already in [RangPhase.trickPlay]
/// with trump = spades, p1 leading, no passToPlayerId.
///
/// Team A = p1 (idx 0) & p3 (idx 2).
/// Team B = p2 (idx 1) & p4 (idx 3).
///
/// Default hand size is 1 card per player unless overridden; callers can
/// [copyWith] any field they need.
RangGameState baseState({
  List<Player>? players,
  int teamASars = 0,
  int teamBSars = 0,
  List<PlayingCard> heap = const [],
  String? lastTrickWinnerId,
  int consecutiveWinsByLastWinner = 0,
}) {
  final defaultPlayers = players ??
      [
        Player(
          id: 'p1',
          name: 'p1',
          hand: const [PlayingCard(suit: Suit.hearts, rank: Rank.ace)],
        ),
        Player(
          id: 'p2',
          name: 'p2',
          hand: const [PlayingCard(suit: Suit.hearts, rank: Rank.king)],
        ),
        Player(
          id: 'p3',
          name: 'p3',
          hand: const [PlayingCard(suit: Suit.hearts, rank: Rank.queen)],
        ),
        Player(
          id: 'p4',
          name: 'p4',
          hand: const [PlayingCard(suit: Suit.hearts, rank: Rank.jack)],
        ),
      ];

  return RangGameState(
    gameId: 'test',
    players: defaultPlayers,
    status: GameStatus.playing,
    currentPlayerId: defaultPlayers[0].id,
    dealerId: defaultPlayers[0].id,
    trumpCallerId: defaultPlayers[1].id,
    trumpSuit: Suit.spades, // trump declared
    phase: RangPhase.trickPlay,
    passToPlayerId: null, // no overlay; player can play immediately
    teamASars: teamASars,
    teamBSars: teamBSars,
    heap: heap,
    lastTrickWinnerId: lastTrickWinnerId,
    consecutiveWinsByLastWinner: consecutiveWinsByLastWinner,
  );
}

/// Plays one full trick through the engine.
/// [plays] is a list of (playerId, card) pairs in order.
/// The first play goes through as-is; subsequent plays acknowledge the
/// passToPlayerId by using the next player's id as playerId (which the
/// engine validates against currentPlayerId).
///
/// Since the engine sets passToPlayerId = nextPlayer after each play, and
/// getMoveError rejects moves when passToPlayerId != null, we clear the
/// overlay between plays by using copyWith(clearPassToPlayerId: true).
RangGameState playFullTrick(
  RangGameState state,
  List<(String, PlayingCard)> plays,
) {
  for (final (playerId, card) in plays) {
    // Clear passToPlayerId (simulates the UI acknowledging the pass-device
    // overlay) then play the card.
    state = state.copyWith(clearPassToPlayerId: true);
    state = RangEngine.playCard(state, playerId, card);
  }
  return state;
}

// ─────────────────────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('RangEngine', () {
    // ── 1. initializeGame ────────────────────────────────────────────────────

    group('initializeGame', () {
      test('deals exactly 13 cards to each of 4 players', () {
        final state =
            RangEngine.initializeGame(['Alice', 'Bob', 'Charlie', 'Diana']);

        expect(state.players.length, 4);
        for (final p in state.players) {
          expect(p.hand.length, 13,
              reason: '${p.name} should have 13 cards');
        }
        final total =
            state.players.fold(0, (sum, p) => sum + p.hand.length);
        expect(total, 52);
      });

      test('sets phase = trumpSelection and assigns correct roles', () {
        final state =
            RangEngine.initializeGame(['Alice', 'Bob', 'Charlie', 'Diana']);

        expect(state.phase, RangPhase.trumpSelection);
        expect(state.dealerId, state.players[0].id);
        expect(state.trumpCallerId, state.players[1].id);
        // currentPlayerId points at the trump caller so they can select trump.
        expect(state.currentPlayerId, state.players[1].id);
        // Pass-device overlay is shown before trump caller sees their hand.
        expect(state.passToPlayerId, state.players[1].id);
        // Trump has not been declared yet.
        expect(state.trumpSuit, isNull);
      });

      test('throws ArgumentError for fewer than 4 players', () {
        expect(
          () => RangEngine.initializeGame(['Alice', 'Bob', 'Charlie']),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('throws ArgumentError for more than 4 players', () {
        expect(
          () => RangEngine.initializeGame(
              ['Alice', 'Bob', 'Charlie', 'Diana', 'Eve']),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('all 52 cards are unique (no duplicates)', () {
        final state =
            RangEngine.initializeGame(['p1', 'p2', 'p3', 'p4']);
        final allCards = state.players.expand((p) => p.hand).toList();
        expect(allCards.toSet().length, 52,
            reason: 'Each card must appear exactly once');
      });
    });

    // ── 2 & 3. declareTrump ─────────────────────────────────────────────────

    group('declareTrump', () {
      late RangGameState initState;

      setUp(() {
        initState =
            RangEngine.initializeGame(['p1', 'p2', 'p3', 'p4']);
      });

      test('succeeds for the correct trump caller and transitions to trickPlay',
          () {
        final trumpCallerId = initState.trumpCallerId;
        final result =
            RangEngine.declareTrump(initState, trumpCallerId, Suit.hearts);

        expect(result.trumpSuit, Suit.hearts);
        expect(result.phase, RangPhase.trickPlay);
        // Pass-device overlay is cleared — trump caller leads immediately.
        expect(result.passToPlayerId, isNull);
      });

      test('throws when called by the wrong player', () {
        // p1 is the dealer, not the trump caller (who is p2).
        final wrongCaller = initState.players
            .firstWhere((p) => p.id != initState.trumpCallerId)
            .id;

        expect(
          () => RangEngine.declareTrump(initState, wrongCaller, Suit.clubs),
          throwsA(isA<Exception>()),
        );
      });

      test('throws when called after trump is already declared', () {
        // Declare once (valid).
        final afterFirst = RangEngine.declareTrump(
            initState, initState.trumpCallerId, Suit.diamonds);

        // Declare again on the already-trickPlay state → must throw.
        expect(
          () => RangEngine.declareTrump(
              afterFirst, initState.trumpCallerId, Suit.spades),
          throwsA(isA<Exception>()),
        );
      });
    });

    // ── 4. getMoveError — suit-following ────────────────────────────────────

    group('getMoveError — suit-following', () {
      test('rejects playing off-suit when player holds the led suit', () {
        // p2 holds a heart but tries to play a spade (non-trump) off-suit.
        final state = baseState(
          players: [
            // p1 has already led (hearts); trick has 1 card.
            // We set up mid-trick: leadSuit = hearts, p2's turn.
            Player(
              id: 'p1',
              name: 'p1',
              hand: const [], // p1 already played
            ),
            Player(
              id: 'p2',
              name: 'p2',
              hand: const [
                PlayingCard(suit: Suit.hearts, rank: Rank.two),
                PlayingCard(suit: Suit.clubs, rank: Rank.king),
              ],
            ),
            Player(
              id: 'p3',
              name: 'p3',
              hand: const [PlayingCard(suit: Suit.hearts, rank: Rank.three)],
            ),
            Player(
              id: 'p4',
              name: 'p4',
              hand: const [PlayingCard(suit: Suit.hearts, rank: Rank.four)],
            ),
          ],
        ).copyWith(
          currentPlayerId: 'p2',
          leadSuit: Suit.hearts,
          currentTrick: const [
            RangTrickPlay(
              playerId: 'p1',
              card: PlayingCard(suit: Suit.hearts, rank: Rank.ace),
            ),
          ],
        );

        // p2 tries to play clubs instead of following the heart lead.
        final error = RangEngine.getMoveError(
          state,
          'p2',
          const PlayingCard(suit: Suit.clubs, rank: Rank.king),
        );

        expect(error, isNotNull,
            reason: 'Should reject off-suit play when holding led suit');
        expect(error, contains('follow suit'));
      });

      test('allows any card when player has no card of the led suit', () {
        // p2 has no hearts at all — may play anything (trump or slough).
        final state = baseState(
          players: [
            Player(id: 'p1', name: 'p1', hand: const []),
            Player(
              id: 'p2',
              name: 'p2',
              hand: const [
                // No hearts
                PlayingCard(suit: Suit.spades, rank: Rank.two), // trump
                PlayingCard(suit: Suit.clubs, rank: Rank.king),
              ],
            ),
            Player(
              id: 'p3',
              name: 'p3',
              hand: const [PlayingCard(suit: Suit.hearts, rank: Rank.three)],
            ),
            Player(
              id: 'p4',
              name: 'p4',
              hand: const [PlayingCard(suit: Suit.hearts, rank: Rank.four)],
            ),
          ],
        ).copyWith(
          currentPlayerId: 'p2',
          leadSuit: Suit.hearts,
          currentTrick: const [
            RangTrickPlay(
              playerId: 'p1',
              card: PlayingCard(suit: Suit.hearts, rank: Rank.ace),
            ),
          ],
        );

        // Playing a trump (spades) is legal.
        expect(
          RangEngine.getMoveError(
            state,
            'p2',
            const PlayingCard(suit: Suit.spades, rank: Rank.two),
          ),
          isNull,
          reason: 'Trump is legal when void in led suit',
        );

        // Playing a slough (clubs) is also legal.
        expect(
          RangEngine.getMoveError(
            state,
            'p2',
            const PlayingCard(suit: Suit.clubs, rank: Rank.king),
          ),
          isNull,
          reason: 'Sloughing off-suit is legal when void in led suit',
        );
      });
    });

    // ── 5. getMoveError — phase guard ────────────────────────────────────────

    group('getMoveError — phase guard', () {
      test('rejects any card play during trumpSelection phase', () {
        final state = baseState().copyWith(
          phase: RangPhase.trumpSelection,
          clearTrumpSuit: true,
        );
        final error = RangEngine.getMoveError(
          state,
          'p1',
          const PlayingCard(suit: Suit.hearts, rank: Rank.ace),
        );
        expect(error, isNotNull);
        expect(error, contains('Trump has not been declared yet'));
      });
    });

    // ── 6. Trump beats higher-ranked lead-suit card ──────────────────────────

    group('Trump priority', () {
      test('trick is won by highest trump even when a higher lead-suit card '
          'was played', () {
        // Led suit = hearts. p1 leads Ace of hearts (highest possible).
        // p2 plays Two of spades (trump, lowest trump).
        // p3 plays King of hearts (high lead-suit but not trump).
        // p4 plays Three of hearts.
        //
        // Winner must be p2 (lowest trump beats any non-trump).
        var state = baseState(
          players: [
            Player(
              id: 'p1',
              name: 'p1',
              hand: const [PlayingCard(suit: Suit.hearts, rank: Rank.ace)],
            ),
            Player(
              id: 'p2',
              name: 'p2',
              // Has no hearts, so trump is legal.
              hand: const [PlayingCard(suit: Suit.spades, rank: Rank.two)],
            ),
            Player(
              id: 'p3',
              name: 'p3',
              hand: const [PlayingCard(suit: Suit.hearts, rank: Rank.king)],
            ),
            Player(
              id: 'p4',
              name: 'p4',
              hand: const [PlayingCard(suit: Suit.hearts, rank: Rank.three)],
            ),
          ],
        );

        state = playFullTrick(state, [
          ('p1', const PlayingCard(suit: Suit.hearts, rank: Rank.ace)),
          ('p2', const PlayingCard(suit: Suit.spades, rank: Rank.two)),
          ('p3', const PlayingCard(suit: Suit.hearts, rank: Rank.king)),
          ('p4', const PlayingCard(suit: Suit.hearts, rank: Rank.three)),
        ]);

        // p2 (Team B, index 1) should have won.
        expect(state.lastTrickWinnerId, 'p2',
            reason: 'Lowest trump (2♠) must beat Ace of led suit');
        expect(state.currentPlayerId, 'p2');
      });

      test('without any trump, highest lead-suit card wins', () {
        // No trump (spades) played. Led = hearts. p1: A♥, p2: 2♣, p3: K♥, p4: 3♥.
        // p3 has highest heart → p3 wins.
        var state = baseState(
          players: [
            Player(
              id: 'p1',
              name: 'p1',
              hand: const [PlayingCard(suit: Suit.hearts, rank: Rank.ace)],
            ),
            Player(
              id: 'p2',
              name: 'p2',
              // No hearts, no spades — plays clubs (slough).
              hand: const [PlayingCard(suit: Suit.clubs, rank: Rank.two)],
            ),
            Player(
              id: 'p3',
              name: 'p3',
              hand: const [PlayingCard(suit: Suit.hearts, rank: Rank.king)],
            ),
            Player(
              id: 'p4',
              name: 'p4',
              hand: const [PlayingCard(suit: Suit.hearts, rank: Rank.three)],
            ),
          ],
        );

        state = playFullTrick(state, [
          ('p1', const PlayingCard(suit: Suit.hearts, rank: Rank.ace)),
          ('p2', const PlayingCard(suit: Suit.clubs, rank: Rank.two)),
          ('p3', const PlayingCard(suit: Suit.hearts, rank: Rank.king)),
          ('p4', const PlayingCard(suit: Suit.hearts, rank: Rank.three)),
        ]);

        expect(state.lastTrickWinnerId, 'p1',
            reason: 'Ace of hearts (highest lead-suit) must win when no trump played');
      });
    });

    // ── 7. Single trick does NOT collect the heap ────────────────────────────

    group('Sar scoring', () {
      test('winning one trick accumulates the heap but does NOT award a sar',
          () {
        // Fresh state: each player has 2 cards so hand doesn't empty yet.
        var state = baseState(
          players: [
            Player(
              id: 'p1',
              name: 'p1',
              hand: const [
                PlayingCard(suit: Suit.hearts, rank: Rank.ace),
                PlayingCard(suit: Suit.hearts, rank: Rank.two),
              ],
            ),
            Player(
              id: 'p2',
              name: 'p2',
              hand: const [
                PlayingCard(suit: Suit.hearts, rank: Rank.three),
                PlayingCard(suit: Suit.hearts, rank: Rank.four),
              ],
            ),
            Player(
              id: 'p3',
              name: 'p3',
              hand: const [
                PlayingCard(suit: Suit.hearts, rank: Rank.five),
                PlayingCard(suit: Suit.hearts, rank: Rank.six),
              ],
            ),
            Player(
              id: 'p4',
              name: 'p4',
              hand: const [
                PlayingCard(suit: Suit.hearts, rank: Rank.seven),
                PlayingCard(suit: Suit.hearts, rank: Rank.eight),
              ],
            ),
          ],
        );

        // Play trick 1 — p1 wins with Ace of hearts.
        state = playFullTrick(state, [
          ('p1', const PlayingCard(suit: Suit.hearts, rank: Rank.ace)),
          ('p2', const PlayingCard(suit: Suit.hearts, rank: Rank.three)),
          ('p3', const PlayingCard(suit: Suit.hearts, rank: Rank.five)),
          ('p4', const PlayingCard(suit: Suit.hearts, rank: Rank.seven)),
        ]);

        // After one trick: heap has 4 cards, zero sars scored.
        expect(state.heap.length, 4,
            reason: 'Heap accumulates trick cards without awarding a sar');
        expect(state.teamASars, 0);
        expect(state.teamBSars, 0);
        expect(state.consecutiveWinsByLastWinner, 1);
        expect(state.lastTrickWinnerId, 'p1');
      });

      // ── 8. Two consecutive tricks collect the heap ─────────────────────────

      test('winning two consecutive tricks collects heap and awards sars to '
          'the correct team', () {
        // 4 players, each with 4 cards so hand won't empty after 2 tricks.
        // p1 (Team A) leads and wins trick 1, then trick 2 — should score
        // 2 sars for Team A (2 tricks × 1 sar each).
        var state = baseState(
          players: [
            Player(
              id: 'p1',
              name: 'p1',
              hand: const [
                PlayingCard(suit: Suit.hearts, rank: Rank.ace),   // leads trick 1
                PlayingCard(suit: Suit.diamonds, rank: Rank.ace), // leads trick 2
                PlayingCard(suit: Suit.clubs, rank: Rank.ace),    // spare
                PlayingCard(suit: Suit.clubs, rank: Rank.king),   // spare
              ],
            ),
            Player(
              id: 'p2',
              name: 'p2',
              hand: const [
                PlayingCard(suit: Suit.hearts, rank: Rank.two),
                PlayingCard(suit: Suit.diamonds, rank: Rank.two),
                PlayingCard(suit: Suit.clubs, rank: Rank.two),
                PlayingCard(suit: Suit.clubs, rank: Rank.three),
              ],
            ),
            Player(
              id: 'p3',
              name: 'p3',
              hand: const [
                PlayingCard(suit: Suit.hearts, rank: Rank.three),
                PlayingCard(suit: Suit.diamonds, rank: Rank.three),
                PlayingCard(suit: Suit.clubs, rank: Rank.four),
                PlayingCard(suit: Suit.clubs, rank: Rank.five),
              ],
            ),
            Player(
              id: 'p4',
              name: 'p4',
              hand: const [
                PlayingCard(suit: Suit.hearts, rank: Rank.four),
                PlayingCard(suit: Suit.diamonds, rank: Rank.four),
                PlayingCard(suit: Suit.clubs, rank: Rank.six),
                PlayingCard(suit: Suit.clubs, rank: Rank.seven),
              ],
            ),
          ],
        );

        // Trick 1 — p1 wins with A♥.
        state = playFullTrick(state, [
          ('p1', const PlayingCard(suit: Suit.hearts, rank: Rank.ace)),
          ('p2', const PlayingCard(suit: Suit.hearts, rank: Rank.two)),
          ('p3', const PlayingCard(suit: Suit.hearts, rank: Rank.three)),
          ('p4', const PlayingCard(suit: Suit.hearts, rank: Rank.four)),
        ]);

        expect(state.consecutiveWinsByLastWinner, 1);
        expect(state.heap.length, 4);
        expect(state.teamASars, 0, reason: 'No sar yet after 1 trick');

        // p1 leads trick 2 — wins again with A♦.
        // First, engine set passToPlayerId = 'p1' after trick 1.
        state = playFullTrick(state, [
          ('p1', const PlayingCard(suit: Suit.diamonds, rank: Rank.ace)),
          ('p2', const PlayingCard(suit: Suit.diamonds, rank: Rank.two)),
          ('p3', const PlayingCard(suit: Suit.diamonds, rank: Rank.three)),
          ('p4', const PlayingCard(suit: Suit.diamonds, rank: Rank.four)),
        ]);

        // After 2nd consecutive win: heap (8 cards) collected → 2 sars for Team A.
        expect(state.teamASars, 2,
            reason: '2 tricks × 1 sar = 2 sars for Team A');
        expect(state.teamBSars, 0);
        expect(state.heap.isEmpty, isTrue,
            reason: 'Heap must be cleared after sar collection');
        expect(state.consecutiveWinsByLastWinner, 0,
            reason: 'Streak resets to 0 after sar collection');
      });

      // ── 9. Win condition at 7 sars ────────────────────────────────────────

      test('team reaching 7 sars sets status = finished and winningTeam', () {
        // Shortcut: start with 6 sars for Team A, then give them 2 more
        // (by winning 2 consecutive tricks), pushing them to 8 ≥ 7.
        var state = baseState(
          teamASars: 6,
          teamBSars: 2,
          players: [
            Player(
              id: 'p1',
              name: 'p1',
              hand: const [
                PlayingCard(suit: Suit.hearts, rank: Rank.ace),
                PlayingCard(suit: Suit.diamonds, rank: Rank.ace),
              ],
            ),
            Player(
              id: 'p2',
              name: 'p2',
              hand: const [
                PlayingCard(suit: Suit.hearts, rank: Rank.two),
                PlayingCard(suit: Suit.diamonds, rank: Rank.two),
              ],
            ),
            Player(
              id: 'p3',
              name: 'p3',
              hand: const [
                PlayingCard(suit: Suit.hearts, rank: Rank.three),
                PlayingCard(suit: Suit.diamonds, rank: Rank.three),
              ],
            ),
            Player(
              id: 'p4',
              name: 'p4',
              hand: const [
                PlayingCard(suit: Suit.hearts, rank: Rank.four),
                PlayingCard(suit: Suit.diamonds, rank: Rank.four),
              ],
            ),
          ],
        );

        // Trick 1 — p1 wins.
        state = playFullTrick(state, [
          ('p1', const PlayingCard(suit: Suit.hearts, rank: Rank.ace)),
          ('p2', const PlayingCard(suit: Suit.hearts, rank: Rank.two)),
          ('p3', const PlayingCard(suit: Suit.hearts, rank: Rank.three)),
          ('p4', const PlayingCard(suit: Suit.hearts, rank: Rank.four)),
        ]);

        // Game not finished yet (only 1 consecutive win so far).
        expect(state.status, GameStatus.playing);

        // Trick 2 — p1 wins again; consecutive = 2 → 2 sars scored → total = 8.
        state = playFullTrick(state, [
          ('p1', const PlayingCard(suit: Suit.diamonds, rank: Rank.ace)),
          ('p2', const PlayingCard(suit: Suit.diamonds, rank: Rank.two)),
          ('p3', const PlayingCard(suit: Suit.diamonds, rank: Rank.three)),
          ('p4', const PlayingCard(suit: Suit.diamonds, rank: Rank.four)),
        ]);

        expect(state.status, GameStatus.finished);
        expect(state.winningTeam, 'A');
        expect(state.currentPlayerId, isNull);
        expect(state.passToPlayerId, isNull);
      });

      test('winningTeam is B when Team B reaches 7 sars', () {
        // Give Team B 6 sars; p2 (Team B, idx 1) leads and wins 2 tricks.
        var state = baseState(
          teamASars: 3,
          teamBSars: 6,
          players: [
            Player(
              id: 'p1',
              name: 'p1',
              // No hearts → must discard
              hand: const [
                PlayingCard(suit: Suit.clubs, rank: Rank.two),
                PlayingCard(suit: Suit.clubs, rank: Rank.three),
              ],
            ),
            Player(
              id: 'p2',
              name: 'p2',
              hand: const [
                PlayingCard(suit: Suit.hearts, rank: Rank.ace),
                PlayingCard(suit: Suit.diamonds, rank: Rank.ace),
              ],
            ),
            Player(
              id: 'p3',
              name: 'p3',
              hand: const [
                PlayingCard(suit: Suit.clubs, rank: Rank.four),
                PlayingCard(suit: Suit.clubs, rank: Rank.five),
              ],
            ),
            Player(
              id: 'p4',
              name: 'p4',
              hand: const [
                PlayingCard(suit: Suit.clubs, rank: Rank.six),
                PlayingCard(suit: Suit.clubs, rank: Rank.seven),
              ],
            ),
          ],
        ).copyWith(currentPlayerId: 'p2');

        // Trick 1 — p2 leads A♥; p1 has no hearts, discards ♣.
        state = playFullTrick(state, [
          ('p2', const PlayingCard(suit: Suit.hearts, rank: Rank.ace)),
          ('p3', const PlayingCard(suit: Suit.clubs, rank: Rank.four)),
          ('p4', const PlayingCard(suit: Suit.clubs, rank: Rank.six)),
          ('p1', const PlayingCard(suit: Suit.clubs, rank: Rank.two)),
        ]);

        expect(state.status, GameStatus.playing);

        // Trick 2 — p2 wins again.
        state = playFullTrick(state, [
          ('p2', const PlayingCard(suit: Suit.diamonds, rank: Rank.ace)),
          ('p3', const PlayingCard(suit: Suit.clubs, rank: Rank.five)),
          ('p4', const PlayingCard(suit: Suit.clubs, rank: Rank.seven)),
          ('p1', const PlayingCard(suit: Suit.clubs, rank: Rank.three)),
        ]);

        expect(state.status, GameStatus.finished);
        expect(state.winningTeam, 'B');
      });

      // ── 10. 13th trick force-collects remaining heap ──────────────────────

      test('13th (final) trick force-collects the heap even without 2 '
          'consecutive wins', () {
        // Set up: each player holds exactly 1 card → after this trick
        // all hands empty → isFinalTrick = true.
        //
        // Also seed the heap with 8 cards (= 2 tricks already in it) and
        // consecutiveWinsByLastWinner = 1 (NOT 2) to confirm the streak
        // alone would NOT trigger a sar — only isFinalTrick should.
        //
        // p1 wins with A♥.  They are Team A (idx 0).
        // Expected: heap (8 + 4 = 12 cards) → 3 sars for Team A.
        final heapCards = [
          // 8 previously-accumulated cards (2 tricks worth).
          const PlayingCard(suit: Suit.clubs, rank: Rank.two),
          const PlayingCard(suit: Suit.clubs, rank: Rank.three),
          const PlayingCard(suit: Suit.clubs, rank: Rank.four),
          const PlayingCard(suit: Suit.clubs, rank: Rank.five),
          const PlayingCard(suit: Suit.diamonds, rank: Rank.two),
          const PlayingCard(suit: Suit.diamonds, rank: Rank.three),
          const PlayingCard(suit: Suit.diamonds, rank: Rank.four),
          const PlayingCard(suit: Suit.diamonds, rank: Rank.five),
        ];

        var state = baseState(
          heap: heapCards,
          lastTrickWinnerId: 'p1',       // p1 won the previous trick
          consecutiveWinsByLastWinner: 1, // streak = 1, would need 2 for normal sar
          teamASars: 2,
          teamBSars: 2,
          players: [
            Player(
              id: 'p1',
              name: 'p1',
              hand: const [PlayingCard(suit: Suit.hearts, rank: Rank.ace)],
            ),
            Player(
              id: 'p2',
              name: 'p2',
              hand: const [PlayingCard(suit: Suit.hearts, rank: Rank.two)],
            ),
            Player(
              id: 'p3',
              name: 'p3',
              hand: const [PlayingCard(suit: Suit.hearts, rank: Rank.three)],
            ),
            Player(
              id: 'p4',
              name: 'p4',
              hand: const [PlayingCard(suit: Suit.hearts, rank: Rank.four)],
            ),
          ],
        );

        state = playFullTrick(state, [
          ('p1', const PlayingCard(suit: Suit.hearts, rank: Rank.ace)),
          ('p2', const PlayingCard(suit: Suit.hearts, rank: Rank.two)),
          ('p3', const PlayingCard(suit: Suit.hearts, rank: Rank.three)),
          ('p4', const PlayingCard(suit: Suit.hearts, rank: Rank.four)),
        ]);

        // All hands empty → isFinalTrick forced sar collection.
        // Heap had 8 cards + 4 from this trick = 12 cards → 3 sars.
        expect(state.heap.isEmpty, isTrue,
            reason: 'Heap must be cleared after final-trick collection');
        expect(state.teamASars, 2 + 3,
            reason: 'Team A should get 3 sars from the final heap (12 cards)');
        expect(state.teamBSars, 2, reason: 'Team B sars unchanged');
        expect(state.lastTrickWinnerId, 'p1');
      });
    });

    // ── Kot and Bavney flags ─────────────────────────────────────────────────

    group('Kot and Bavney', () {
      test('kot is true when winning team reaches 7 sars with loser at 0', () {
        // Team A wins, Team B never scored → kot.
        var state = baseState(
          teamASars: 6,
          teamBSars: 0, // Team B has zero sars
          players: [
            Player(
              id: 'p1',
              name: 'p1',
              hand: const [
                PlayingCard(suit: Suit.hearts, rank: Rank.ace),
                PlayingCard(suit: Suit.diamonds, rank: Rank.ace),
              ],
            ),
            Player(
              id: 'p2',
              name: 'p2',
              hand: const [
                PlayingCard(suit: Suit.hearts, rank: Rank.two),
                PlayingCard(suit: Suit.diamonds, rank: Rank.two),
              ],
            ),
            Player(
              id: 'p3',
              name: 'p3',
              hand: const [
                PlayingCard(suit: Suit.hearts, rank: Rank.three),
                PlayingCard(suit: Suit.diamonds, rank: Rank.three),
              ],
            ),
            Player(
              id: 'p4',
              name: 'p4',
              hand: const [
                PlayingCard(suit: Suit.hearts, rank: Rank.four),
                PlayingCard(suit: Suit.diamonds, rank: Rank.four),
              ],
            ),
          ],
        );

        // Two consecutive wins → 2 sars → total 8.
        state = playFullTrick(state, [
          ('p1', const PlayingCard(suit: Suit.hearts, rank: Rank.ace)),
          ('p2', const PlayingCard(suit: Suit.hearts, rank: Rank.two)),
          ('p3', const PlayingCard(suit: Suit.hearts, rank: Rank.three)),
          ('p4', const PlayingCard(suit: Suit.hearts, rank: Rank.four)),
        ]);
        state = playFullTrick(state, [
          ('p1', const PlayingCard(suit: Suit.diamonds, rank: Rank.ace)),
          ('p2', const PlayingCard(suit: Suit.diamonds, rank: Rank.two)),
          ('p3', const PlayingCard(suit: Suit.diamonds, rank: Rank.three)),
          ('p4', const PlayingCard(suit: Suit.diamonds, rank: Rank.four)),
        ]);

        expect(state.status, GameStatus.finished);
        expect(state.kot, isTrue, reason: 'Loser had 0 sars → kot');
        expect(state.bavney, isFalse);
      });

      test('kot is false when loser has at least 1 sar', () {
        var state = baseState(
          teamASars: 6,
          teamBSars: 1, // Team B has 1 sar — no kot
          players: [
            Player(
              id: 'p1',
              name: 'p1',
              hand: const [
                PlayingCard(suit: Suit.hearts, rank: Rank.ace),
                PlayingCard(suit: Suit.diamonds, rank: Rank.ace),
              ],
            ),
            Player(
              id: 'p2',
              name: 'p2',
              hand: const [
                PlayingCard(suit: Suit.hearts, rank: Rank.two),
                PlayingCard(suit: Suit.diamonds, rank: Rank.two),
              ],
            ),
            Player(
              id: 'p3',
              name: 'p3',
              hand: const [
                PlayingCard(suit: Suit.hearts, rank: Rank.three),
                PlayingCard(suit: Suit.diamonds, rank: Rank.three),
              ],
            ),
            Player(
              id: 'p4',
              name: 'p4',
              hand: const [
                PlayingCard(suit: Suit.hearts, rank: Rank.four),
                PlayingCard(suit: Suit.diamonds, rank: Rank.four),
              ],
            ),
          ],
        );

        state = playFullTrick(state, [
          ('p1', const PlayingCard(suit: Suit.hearts, rank: Rank.ace)),
          ('p2', const PlayingCard(suit: Suit.hearts, rank: Rank.two)),
          ('p3', const PlayingCard(suit: Suit.hearts, rank: Rank.three)),
          ('p4', const PlayingCard(suit: Suit.hearts, rank: Rank.four)),
        ]);
        state = playFullTrick(state, [
          ('p1', const PlayingCard(suit: Suit.diamonds, rank: Rank.ace)),
          ('p2', const PlayingCard(suit: Suit.diamonds, rank: Rank.two)),
          ('p3', const PlayingCard(suit: Suit.diamonds, rank: Rank.three)),
          ('p4', const PlayingCard(suit: Suit.diamonds, rank: Rank.four)),
        ]);

        expect(state.status, GameStatus.finished);
        expect(state.kot, isFalse);
      });
    });
  });
}
