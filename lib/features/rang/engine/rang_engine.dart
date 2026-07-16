import 'dart:math';
import 'package:rang_adda/shared/models/card_model.dart';
import 'package:rang_adda/shared/models/deck.dart';
import 'package:rang_adda/shared/models/player.dart';
import 'package:rang_adda/shared/models/game_state.dart';
import 'package:rang_adda/features/rang/engine/rang_game_state.dart';
import 'package:rang_adda/features/rang/engine/rang_trick_play.dart';

/// Pure stateless game-logic engine for Rang (Double-Sar Court Piece).
///
/// All methods are static and free of side-effects. They take the current
/// [RangGameState] and return a *new* immutable state — no mutation.
/// No Flutter imports; safe to unit-test in pure Dart.
class RangEngine {
  // ── Public API ─────────────────────────────────────────────────────────────

  /// Creates a brand-new game state.
  ///
  /// Exactly 4 [playerNames] are required; throws [ArgumentError] otherwise.
  ///
  /// Deal: a shuffled standard 52-card deck is distributed 13 cards each.
  /// Hands are sorted by suit then rank (highest first) for display convenience.
  ///
  /// * [dealerId]      = players[0].id
  /// * [trumpCallerId] = players[1].id  (the player to the dealer's left)
  /// * [phase]         = [RangPhase.trumpSelection]
  /// * [currentPlayerId] = [trumpCallerId]
  /// * [passToPlayerId]  = [trumpCallerId]  (pass-device overlay shown first,
  ///   so the other three players cannot see the trump caller's hand during
  ///   trump selection on a shared device)
  static RangGameState initializeGame(List<Player> playersInput) {
    if (playersInput.length != 4) {
      throw ArgumentError(
        'Rang requires exactly 4 players, '
        'but ${playersInput.length} were provided.',
      );
    }

    final deck = Deck.standard().cards..shuffle(Random());

    // Build players with empty hands, then deal round-robin.
    List<Player> players = playersInput
        .map((p) => p.copyWith(hand: const []))
        .toList();

    int pIndex = 0;
    for (final card in deck) {
      players[pIndex] = players[pIndex].copyWith(
        hand: [...players[pIndex].hand, card],
      );
      pIndex = (pIndex + 1) % players.length;
    }

    // Sort each hand: group by suit, then highest rank first (mirrors ThullaEngine).
    players = players.map((p) {
      final sorted = List<PlayingCard>.from(p.hand)
        ..sort((a, b) {
          final suitCmp = a.suit.index.compareTo(b.suit.index);
          if (suitCmp != 0) return suitCmp;
          return _rankValue(b.rank).compareTo(_rankValue(a.rank));
        });
      return p.copyWith(hand: sorted, cardCount: sorted.length);
    }).toList();

    final dealerId = players[0].id;
    final trumpCallerId = players[1].id;

    return RangGameState(
      gameId: DateTime.now().millisecondsSinceEpoch.toString(),
      players: players,
      status: GameStatus.playing,
      currentPlayerId: trumpCallerId,
      dealerId: dealerId,
      trumpCallerId: trumpCallerId,
      phase: RangPhase.trumpSelection,
      passToPlayerId: trumpCallerId,
    );
  }

  /// Starts a game from the waiting room (online multiplayer).
  /// Re-deals a shuffled deck and sets the game to trick-play,
  /// skipping the device pass overlays (isOnline = true).
  static RangGameState startGameFromWaitingRoom(RangGameState state) {
    final deck = Deck.standard().cards..shuffle(Random());
    var players = List<Player>.from(state.players);

    int pIndex = 0;
    for (var card in deck) {
      players[pIndex] = players[pIndex].copyWith(
        hand: [...players[pIndex].hand, card],
      );
      pIndex = (pIndex + 1) % players.length;
    }

    players = players.map((p) {
      final sorted = List<PlayingCard>.from(p.hand)
        ..sort((a, b) {
          final suitCmp = a.suit.index.compareTo(b.suit.index);
          if (suitCmp != 0) return suitCmp;
          return _rankValue(b.rank).compareTo(_rankValue(a.rank));
        });
      return p.copyWith(hand: sorted, cardCount: sorted.length);
    }).toList();

    final dealerId = players[0].id;
    final trumpCallerId = players[1].id;

    return state.copyWith(
      players: players,
      status: GameStatus.playing,
      currentPlayerId: trumpCallerId,
      dealerId: dealerId,
      trumpCallerId: trumpCallerId,
      phase: RangPhase.trumpSelection,
      passToPlayerId: null, // Online games do not need pass device screens!
      trickResolving: false,
      isOnline: true,
    );
  }

  /// Declares the trump suit and advances the game to [RangPhase.trickPlay].
  ///
  /// The trump caller leads the first trick immediately (no pass-device after
  /// declaration — they are already holding the device from trump selection).
  ///
  /// Throws [Exception] if:
  /// * the game is not in [RangPhase.trumpSelection], or
  /// * [callerId] is not [state.trumpCallerId].
  static RangGameState declareTrump(
    RangGameState state,
    String callerId,
    Suit suit,
  ) {
    if (state.phase != RangPhase.trumpSelection) {
      throw Exception('Trump has already been declared.');
    }
    if (callerId != state.trumpCallerId) {
      throw Exception(
        'Only ${state.trumpCallerId} may declare trump, not $callerId.',
      );
    }

    return state.copyWith(
      trumpSuit: suit,
      phase: RangPhase.trickPlay,
      // Trump caller leads first; they are already holding the device.
      clearPassToPlayerId: true,
    );
  }

  /// Returns a user-facing error string if the move is illegal, or null if
  /// the move is valid.  Mirrors ThullaEngine's style exactly.
  static String? getMoveError(
    RangGameState state,
    String playerId,
    PlayingCard card,
  ) {
    if (state.status != GameStatus.playing) return 'Game is over.';
    if (state.phase != RangPhase.trickPlay) {
      return 'Trump has not been declared yet.';
    }
    if (state.currentPlayerId != playerId) return 'Not your turn.';
    if (state.passToPlayerId != null) return 'Waiting for next player.';

    final player = state.players.firstWhere((p) => p.id == playerId);
    if (!player.hand.contains(card)) return 'You do not have this card.';

    // Suit-following rule: if you hold a card of the led suit you must play it.
    // (You may NOT trump or slough while holding the led suit.)
    if (state.leadSuit != null && card.suit != state.leadSuit) {
      final hasSuit = player.hand.any((c) => c.suit == state.leadSuit);
      if (hasSuit) {
        return 'You must follow suit! Play a ${state.leadSuit!.name}.';
      }
    }

    return null; // Valid move.
  }

  /// Applies a card play and returns the new state.
  ///
  /// If [getMoveError] returns a non-null string, the state is returned
  /// unchanged (defensive guard, matching ThullaEngine's pattern).
  ///
  /// When all 4 players have played, the trick is resolved inline:
  ///   • Winner determined by trump priority then lead-suit rank.
  ///   • Heap updated.
  ///   • Sar awarded on 2 consecutive wins by the same team OR on the final trick.
  ///   • Win condition checked after each sar award.
  static RangGameState playCard(
    RangGameState state,
    String playerId,
    PlayingCard card,
  ) {
    if (getMoveError(state, playerId, card) != null) return state;

    // ── 1. Remove card from hand ────────────────────────────────────────────
    final updatedPlayers = state.players.map((p) {
      if (p.id == playerId) {
        final newHand = p.hand.where((c) => c != card).toList();
        return p.copyWith(hand: newHand, cardCount: newHand.length);
      }
      return p;
    }).toList();

    // ── 2. Append to current trick ──────────────────────────────────────────
    final updatedTrick = [
      ...state.currentTrick,
      RangTrickPlay(playerId: playerId, card: card),
    ];

    // Set leadSuit on the first card played in this trick.
    final newLeadSuit = updatedTrick.length == 1 ? card.suit : state.leadSuit;

    // ── 3. Mid-trick: more players still to play ────────────────────────────
    if (updatedTrick.length < 4) {
      final nextPlayerId = _getNextPlayerId(updatedPlayers, playerId);
      return state.copyWith(
        players: updatedPlayers,
        currentTrick: updatedTrick,
        leadSuit: newLeadSuit,
        currentPlayerId: nextPlayerId,
        passToPlayerId: state.isOnline ? null : nextPlayerId,
      );
    }

    // ── 4. All 4 played — wait for resolution ───────────────────────────────
    return state.copyWith(
      players: updatedPlayers,
      currentTrick: updatedTrick,
      leadSuit: newLeadSuit,
      trickResolving: true,
      clearCurrentPlayerId: true,
    );
  }

  // ── Public Trick Resolution ───────────────────────────────────────────────

  /// Resolves a completed 4-card trick, updates heap / sars, and checks
  /// the win condition.
  static RangGameState resolveTrick(RangGameState state) {
    if (!state.trickResolving || state.currentTrick.length < 4) return state;

    final players = state.players;
    final trick = state.currentTrick;
    final leadSuit = state.leadSuit!;
    final trumpSuit = state.trumpSuit; // non-null; declareTrump already set it.

    // ── 4a. Determine winner ────────────────────────────────────────────────
    final winnerId = _getTrickWinner(trick, leadSuit, trumpSuit!);

    // ── 4b. Append trick cards to heap ──────────────────────────────────────
    final newHeap = [...state.heap, ...trick.map((t) => t.card)];

    // ── 4c. Update consecutive-wins counter ─────────────────────────────────
    final bool sameWinnerAsLast = winnerId == state.lastTrickWinnerId;
    final int newConsecutive = sameWinnerAsLast
        ? state.consecutiveWinsByLastWinner + 1
        : 1;

    // ── 4d. Check whether a sar should be scored ────────────────────────────
    // A sar is scored when:
    //   • the same team wins 2 tricks in a row (consecutiveWins == 2), OR
    //   • this was the 13th (final) trick of the hand.
    final bool isFinalTrick = players.every((p) => p.cardCount == 0);
    final bool sarScored = newConsecutive == 2 || isFinalTrick;

    int newTeamASars = state.teamASars;
    int newTeamBSars = state.teamBSars;
    List<PlayingCard> newHeapAfterScore = newHeap;
    int newConsecutiveAfterScore = newConsecutive;

    if (sarScored) {
      // Each trick in the heap contributes one sar to the winning team.
      // heap.length is always a multiple of 4 (4 cards per trick).
      final sarsEarned = newHeap.length ~/ 4;
      if (_isTeamA(winnerId, players)) {
        newTeamASars += sarsEarned;
      } else {
        newTeamBSars += sarsEarned;
      }
      newHeapAfterScore = const []; // Heap is cleared after awarding.
      newConsecutiveAfterScore = 0; // Reset streak after a sar is collected.
    }

    // ── 4e. Base state after trick resolution ────────────────────────────────
    final resolvedState = state.copyWith(
      players: players,
      currentTrick: const [],
      clearLeadSuit: true,
      heap: newHeapAfterScore,
      lastTrickWinnerId: winnerId,
      consecutiveWinsByLastWinner: newConsecutiveAfterScore,
      teamASars: newTeamASars,
      teamBSars: newTeamBSars,
      trickResolving: false,
      currentPlayerId: winnerId,
      passToPlayerId: state.isOnline
          ? null
          : winnerId, // Trick winner leads next
    );

    // ── 4f. Win condition check ──────────────────────────────────────────────
    return _checkWinCondition(resolvedState);
  }

  /// Sets the game to [GameStatus.finished] if either team has reached 7 sars.
  static RangGameState _checkWinCondition(RangGameState state) {
    if (state.teamASars >= 7 || state.teamBSars >= 7) {
      final teamAWon = state.teamASars >= 7;
      final winningTeam = teamAWon ? 'A' : 'B';
      final loserSars = teamAWon ? state.teamBSars : state.teamASars;
      final winnerSars = teamAWon ? state.teamASars : state.teamBSars;

      return state.copyWith(
        status: GameStatus.finished,
        winningTeam: winningTeam,
        kot: loserSars == 0, // Kot: losers scored zero sars.
        bavney: winnerSars == 13, // Bavney: winners took all 13 tricks.
        clearCurrentPlayerId: true,
        clearPassToPlayerId: true,
      );
    }
    return state;
  }

  /// Determines which player wins the trick.
  ///
  /// Priority: highest trump card > highest lead-suit card.
  /// If no trump was played, highest lead-suit card wins.
  static String _getTrickWinner(
    List<RangTrickPlay> trick,
    Suit leadSuit,
    Suit trumpSuit,
  ) {
    // Partition plays into trump plays and lead-suit plays.
    final trumpPlays = trick.where((t) => t.card.suit == trumpSuit).toList();

    if (trumpPlays.isNotEmpty) {
      // Highest trump wins.
      return _highestCardPlay(trumpPlays).playerId;
    }

    // No trump played — highest lead-suit card wins.
    final leadPlays = trick.where((t) => t.card.suit == leadSuit).toList();
    return _highestCardPlay(leadPlays).playerId;
  }

  /// Returns the play with the highest rank from a non-empty list.
  static RangTrickPlay _highestCardPlay(List<RangTrickPlay> plays) {
    return plays.reduce((best, play) {
      return _rankValue(play.card.rank) > _rankValue(best.card.rank)
          ? play
          : best;
    });
  }

  /// Returns true if [playerId] belongs to Team A (players[0] or players[2]).
  static bool _isTeamA(String playerId, List<Player> players) {
    final idx = players.indexWhere((p) => p.id == playerId);
    return idx == 0 || idx == 2;
  }

  /// Returns the next active player in clockwise (list) order.
  /// In Rang all 4 players always have cards until the hand ends, so this
  /// is a simple modular increment — kept consistent with ThullaEngine.
  static String _getNextPlayerId(List<Player> players, String currentPlayerId) {
    final idx = players.indexWhere((p) => p.id == currentPlayerId);
    for (int i = 1; i < players.length; i++) {
      final nextIdx = (idx + i) % players.length;
      if (players[nextIdx].cardCount > 0) return players[nextIdx].id;
    }
    return currentPlayerId; // Fallback (should never occur mid-hand).
  }

  /// Ace-high rank ordering, identical to ThullaEngine._rankValue.
  static int _rankValue(Rank rank) {
    if (rank == Rank.ace) return 14;
    return rank.index + 1;
  }
}
