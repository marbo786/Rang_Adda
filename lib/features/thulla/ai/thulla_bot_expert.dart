import 'dart:math';
import 'package:rang_adda/shared/models/card_model.dart';
import 'package:rang_adda/shared/models/player.dart';
import 'package:rang_adda/shared/models/deck.dart';
import 'package:rang_adda/shared/models/game_state.dart';
import 'package:rang_adda/features/thulla/engine/thulla_game_state.dart';
import 'package:rang_adda/features/thulla/engine/thulla_engine.dart';
import 'package:rang_adda/shared/ai/bot_observation.dart';
import 'thulla_bot.dart';

/// Perfect Information Monte Carlo (PIMC) bot for Thulla.
///
/// Algorithm:
///  1. Sample [numWorlds] possible "worlds" — randomly deal the cards that are
///     not in our hand and not in the waste pile to opponents, consistent with
///     their known card counts.
///  2. For each world, run a depth-limited minimax search ([searchDepth] tricks
///     ahead) as if all information is now visible.
///  3. For each candidate card, accumulate scores across all sampled worlds.
///  4. Play the card with the highest average score.
///
/// Pure Dart — no packages beyond what the project already uses.
/// Works identically on web, mobile, and desktop.
class ThullaBotExpert extends ThullaBot {
  final int numWorlds;
  final int searchDepth;
  final Random _rng;

  ThullaBotExpert(
    super.personality, {
    this.numWorlds = 20,
    this.searchDepth = 3,
    Random? random,
  }) : _rng = random ?? Random();

  // ── Public interface (matches ThullaBot contract) ─────────────────────────

  @override
  PlayingCard chooseCard(ThullaBotObservation obs) {
    // Reconstruct a minimal ThullaGameState from the observation so the
    // minimax search can call ThullaEngine methods directly.
    final syntheticState = _buildStateFromObs(obs);
    return _pimcChoose(syntheticState, obs.myId);
  }

  // ── Core PIMC search ──────────────────────────────────────────────────────

  PlayingCard _pimcChoose(ThullaGameState state, String botId) {
    final player = state.players.firstWhere((p) => p.id == botId);

    // All cards this bot is legally allowed to play right now.
    final validCards = List<PlayingCard>.from(
      player.hand.where(
        (c) => ThullaEngine.getMoveError(state, botId, c) == null,
      ),
    );

    if (validCards.isEmpty) {
      // Should never happen — safety fallback to first card.
      return player.hand.first;
    }
    if (validCards.length == 1) return validCards.first;

    // Accumulate scores per candidate card across all sampled worlds.
    final cardScores = <PlayingCard, double>{
      for (final c in validCards) c: 0.0,
    };

    final stopwatch = Stopwatch()..start();
    const timeBudgetMs = 800; // never block the thread for more than 800 ms

    int worldsCompleted = 0;
    for (int w = 0; w < numWorlds; w++) {
      if (stopwatch.elapsedMilliseconds > timeBudgetMs) break;

      final world = _sampleWorld(state, botId);
      if (world == null) continue;

      for (final card in validCards) {
        final score = _minimaxScore(world, botId, card, searchDepth);
        cardScores[card] = cardScores[card]! + score;
      }
      worldsCompleted++;
    }

    // Avoid div-by-zero if every world sample failed.
    if (worldsCompleted == 0) {
      return validCards.first;
    }

    validCards.sort((a, b) => (cardScores[b]!).compareTo(cardScores[a]!));
    return validCards.first;
  }

  // ── World sampling ────────────────────────────────────────────────────────

  /// Builds a complete ThullaGameState where unknown opponent cards are filled
  /// in randomly but consistently with the known public information:
  ///  - We know our own exact hand.
  ///  - We know the waste pile (gone).
  ///  - We know the current trick cards (gone).
  ///  - We know how many cards each opponent holds (p.cardCount).
  ThullaGameState? _sampleWorld(ThullaGameState state, String botId) {
    try {
      // Cards that are definitively accounted for.
      final knownGone = <PlayingCard>{
        ...state.wastePile,
        ...state.currentTrick.map((tp) => tp.card),
      };

      final myPlayer = state.players.firstWhere((p) => p.id == botId);
      final myHand = myPlayer.hand.toSet();

      // Unknown = full deck minus our hand minus known-gone cards.
      final unknownCards = List<PlayingCard>.from(
        Deck.standard().cards.where(
          (c) => !myHand.contains(c) && !knownGone.contains(c),
        ),
      )..shuffle(_rng);

      // Deal to opponents proportionally to their known card count.
      int deckIdx = 0;
      final newPlayers = <Player>[];

      for (final p in state.players) {
        if (p.id == botId) {
          newPlayers.add(p); // keep our own hand exactly
        } else {
          // Use cardCount (the public information) not hand.length
          // (which may be 0 in online mode where hands are hidden).
          final count = p.cardCount > 0 ? p.cardCount : p.hand.length;
          if (deckIdx + count > unknownCards.length) return null;
          final dealtHand = unknownCards.sublist(deckIdx, deckIdx + count);
          deckIdx += count;
          newPlayers.add(p.copyWith(hand: dealtHand, cardCount: count));
        }
      }

      return state.copyWith(players: newPlayers);
    } catch (_) {
      return null;
    }
  }

  // ── Minimax tree search ───────────────────────────────────────────────────

  /// Entry point: evaluate playing [card] from [state] for [botId].
  double _minimaxScore(
    ThullaGameState state,
    String botId,
    PlayingCard card,
    int depth,
  ) {
    final next = _simulatePlay(state, state.currentPlayerId!, card);
    if (next == null) return 0.0;

    if (next.status == GameStatus.finished || depth == 0) {
      return _evaluate(next, botId);
    }

    if (next.currentPlayerId == botId) {
      return _maximizing(next, botId, depth - 1);
    }
    return _minimizing(next, botId, depth - 1);
  }

  double _maximizing(ThullaGameState state, String botId, int depth) {
    if (depth == 0 || state.status == GameStatus.finished) {
      return _evaluate(state, botId);
    }
    final player = state.players.firstWhere((p) => p.id == botId);
    final validCards = player.hand
        .where((c) => ThullaEngine.getMoveError(state, botId, c) == null)
        .toList();
    if (validCards.isEmpty) return _evaluate(state, botId);

    double best = double.negativeInfinity;
    for (final card in validCards) {
      final next = _simulatePlay(state, botId, card);
      if (next == null) continue;
      final score = next.currentPlayerId == botId
          ? _maximizing(next, botId, depth - 1)
          : _minimizing(next, botId, depth - 1);
      if (score > best) best = score;
    }
    return best.isInfinite ? _evaluate(state, botId) : best;
  }

  double _minimizing(ThullaGameState state, String botId, int depth) {
    if (depth == 0 || state.status == GameStatus.finished) {
      return _evaluate(state, botId);
    }
    final currentId = state.currentPlayerId;
    if (currentId == null) return _evaluate(state, botId);

    final opponent = state.players.firstWhere((p) => p.id == currentId);
    final validCards = opponent.hand
        .where((c) => ThullaEngine.getMoveError(state, currentId, c) == null)
        .toList();
    if (validCards.isEmpty) return _evaluate(state, botId);

    double worst = double.infinity;
    for (final card in validCards) {
      final next = _simulatePlay(state, currentId, card);
      if (next == null) continue;
      final score = next.currentPlayerId == botId
          ? _maximizing(next, botId, depth - 1)
          : _minimizing(next, botId, depth - 1);
      if (score < worst) worst = score;
    }
    return worst.isInfinite ? _evaluate(state, botId) : worst;
  }

  // ── Card play simulation ──────────────────────────────────────────────────

  /// Simulates one card play through the engine, auto-resolves the trick when
  /// it's complete, and collapses any pass-to-player state so minimax always
  /// has a clean next state to recurse into.
  ThullaGameState? _simulatePlay(
    ThullaGameState state,
    String playerId,
    PlayingCard card,
  ) {
    try {
      if (ThullaEngine.getMoveError(state, playerId, card) != null) return null;

      ThullaGameState next = ThullaEngine.playCard(state, playerId, card);

      // Auto-resolve trick if the engine flagged it.
      if (next.trickResolving) {
        next = ThullaEngine.resolveTrick(next);
      }

      // Collapse pass-device flow — in simulation there is no human to tap
      // "Pass Device", so we skip straight to the next active player.
      if (next.passToPlayerId != null) {
        next = next.copyWith(
          currentPlayerId: next.passToPlayerId,
          clearPassToPlayerId: true,
        );
      }

      return next;
    } catch (_) {
      return null;
    }
  }

  // ── Evaluation function ───────────────────────────────────────────────────

  /// Scores a game state from [botId]'s perspective.
  /// Called at leaf nodes (depth == 0) and terminal states.
  ///
  /// In Thulla (Getaway) the goal is to be the FIRST to empty your hand.
  /// The loser is whoever is last to still hold cards.
  double _evaluate(ThullaGameState state, String botId) {
    final myPlayer = state.players.firstWhere((p) => p.id == botId);

    // Terminal state: game is over.
    if (state.status == GameStatus.finished) {
      return myPlayer.hand.isEmpty ? 100.0 : -100.0;
    }

    // ── Heuristic components ───────────────────────────────────────────────
    // 1. Fewer cards in hand is always better — primary objective.
    final handScore = -myPlayer.hand.length.toDouble() * 3.0;

    // 2. High-rank cards (King, Ace) are dangerous:
    //    they force us to win tricks, picking up the current trick or (in
    //    Tochoo) getting cards dumped on us.
    //    Exception: if we are the power player, holding high cards gives us
    //    more control over the lead — so they're less of a liability.
    final isPowerPlayer = state.powerPlayerId == botId;
    final highCards = myPlayer.hand
        .where((c) => _rankValue(c.rank) >= 13)
        .length;
    final highCardScore = isPowerPlayer ? highCards * 1.0 : -highCards * 1.5;

    // 3. Holding cards in fewer suits = better Tochoo opportunities.
    final suitCount = myPlayer.hand.map((c) => c.suit).toSet().length;
    final suitScore = (4 - suitCount) * 1.0;

    // 4. A larger waste pile = fewer dangerous cards still in circulation.
    final wasteScore = state.wastePile.length * 0.1;

    return handScore + highCardScore + suitScore + wasteScore;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static const _rankValues = {
    Rank.ace: 14,
    Rank.king: 13,
    Rank.queen: 12,
    Rank.jack: 11,
    Rank.ten: 10,
    Rank.nine: 9,
    Rank.eight: 8,
    Rank.seven: 7,
    Rank.six: 6,
    Rank.five: 5,
    Rank.four: 4,
    Rank.three: 3,
    Rank.two: 2,
  };

  int _rankValue(Rank rank) => _rankValues[rank] ?? 0;

  /// Reconstructs a minimal ThullaGameState from a ThullaBotObservation.
  ///
  /// The observation has:
  ///  - Our exact hand (myHand)
  ///  - Opponent card COUNTS (not suits/ranks)
  ///  - Waste pile, current trick, lead suit, isFirstTrick
  ///
  /// We build placeholder players for opponents with empty hands but correct
  /// cardCounts; the world-sampling step will fill the hands in.
  ThullaGameState _buildStateFromObs(ThullaBotObservation obs) {
    // We can't perfectly reconstruct the full player list from an observation
    // alone — we only know opponent IDs and counts. Build minimal players.
    final myPlayer = Player(
      id: obs.myId,
      name: obs.myId,
      hand: List<PlayingCard>.from(obs.myHand),
      cardCount: obs.myHand.length,
    );

    final opponentPlayers = obs.opponentCardCounts.entries.map((e) {
      return Player(id: e.key, name: e.key, hand: const [], cardCount: e.value);
    }).toList();

    // Place myself first so currentPlayerId = myId is consistent.
    final players = [myPlayer, ...opponentPlayers];

    // Reconstruct power player heuristic:
    // If the trick is empty and it's our turn, we must be the power player.
    final powerPlayerId = obs.currentTrick.isEmpty
        ? obs.myId
        : obs.currentTrick.first.playerId;

    return ThullaGameState(
      gameId: 'pimc-sim',
      players: players,
      status: GameStatus.playing,
      currentPlayerId: obs.myId,
      powerPlayerId: powerPlayerId,
      currentTrick: List.from(obs.currentTrick),
      wastePile: List.from(obs.wastePile),
      isOnline: false,
    );
  }
}
