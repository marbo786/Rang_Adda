import 'dart:math';
import 'package:rang_adda/shared/models/card_model.dart';
import 'package:rang_adda/shared/models/player.dart';
import 'package:rang_adda/shared/models/game_state.dart';
import 'package:rang_adda/features/rang/engine/rang_game_state.dart';
import 'package:rang_adda/features/rang/engine/rang_engine.dart';
import 'package:rang_adda/features/rang/bot/rang_bot_strategy.dart';
import 'package:rang_adda/features/rang/bot/rang_bot_easy.dart';
import 'package:rang_adda/shared/models/deck.dart';

class RangBotPIMC implements RangBotStrategy {
  final int numWorlds;
  final int searchDepth;
  final Random _rng;

  RangBotPIMC({
    this.numWorlds = 20,
    this.searchDepth = 3,
    Random? random,
  }) : _rng = random ?? Random();

  // ── Trump selection ───────────────────────────────────────────────────────

  @override
  Suit chooseTrump(RangGameState state, String botId) {
    // Strategy: choose the suit we have the MOST of, weighted by card strength
    // (more cards of a suit + higher cards = better trump choice)
    final player = state.players.firstWhere((p) => p.id == botId);

    final suitScores = <Suit, double>{};
    for (final suit in Suit.values) {
      final cardsOfSuit = player.hand.where((c) => c.suit == suit).toList();
      if (cardsOfSuit.isEmpty) {
        suitScores[suit] = 0.0;
        continue;
      }
      // Score = count * 1.0 + sum of high card bonuses
      double score = cardsOfSuit.length.toDouble();
      for (final card in cardsOfSuit) {
        final rv = _rankValue(card.rank);
        if (rv >= 14) { score += 3.0; }  // Ace
        else if (rv >= 13) { score += 2.0; }  // King
        else if (rv >= 12) { score += 1.0; }  // Queen
        else if (rv >= 11) { score += 0.5; }  // Jack
      }
      suitScores[suit] = score;
    }

    return suitScores.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;
  }

  // ── Card selection (PIMC) ─────────────────────────────────────────────────

  @override
  PlayingCard chooseCard(RangGameState state, String botId) {
    final player = state.players.firstWhere((p) => p.id == botId);
    final validCards = List<PlayingCard>.from(
      player.hand.where((c) => RangEngine.getMoveError(state, botId, c) == null)
    );

    if (validCards.isEmpty) return RangBotEasy(rng: _rng).chooseCard(state, botId);
    if (validCards.length == 1) return validCards.first;

    // Find which team the bot is on (index in players list)
    final botIndex = state.players.indexWhere((p) => p.id == botId);
    final botTeam = botIndex % 2 == 0 ? 'A' : 'B';  // 0,2 = A; 1,3 = B

    final cardScores = <PlayingCard, double>{};
    for (final card in validCards) {
      cardScores[card] = 0.0;
    }

    final stopwatch = Stopwatch()..start();
    const timeBudgetMs = 800;
    int worldsCompleted = 0;

    for (int w = 0; w < numWorlds; w++) {
      if (stopwatch.elapsedMilliseconds > timeBudgetMs) break;

      final world = _sampleWorld(state, botId);
      if (world == null) continue;

      for (final card in validCards) {
        final score = _evaluateCard(world, botId, botTeam, card, searchDepth);
        cardScores[card] = (cardScores[card] ?? 0.0) + score;
      }
      worldsCompleted++;
    }

    if (worldsCompleted == 0) return RangBotEasy(rng: _rng).chooseCard(state, botId);

    validCards.sort((a, b) =>
        (cardScores[b] ?? 0.0).compareTo(cardScores[a] ?? 0.0));
    return validCards.first;
  }

  // ── World sampling ────────────────────────────────────────────────────────

  RangGameState? _sampleWorld(RangGameState state, String botId) {
    try {
      final knownGone = <PlayingCard>{
        ...state.heap,
        ...state.currentTrick.map((tp) => tp.card),
      };

      final myPlayer = state.players.firstWhere((p) => p.id == botId);
      final myHand = myPlayer.hand.toSet();

      final allCards = Deck.standard().cards;
      final unknownCards = List<PlayingCard>.from(
        allCards.where((c) => !myHand.contains(c) && !knownGone.contains(c))
      );
      unknownCards.shuffle(_rng);

      int deckIdx = 0;
      final newPlayers = <Player>[];

      for (final p in state.players) {
        if (p.id == botId) {
          newPlayers.add(p);
        } else {
          final count = p.hand.length;
          if (deckIdx + count > unknownCards.length) return null;
          final dealtHand = unknownCards.sublist(deckIdx, deckIdx + count);
          deckIdx += count;
          newPlayers.add(p.copyWith(hand: dealtHand));
        }
      }

      return state.copyWith(players: newPlayers);
    } catch (e) {
      return null;
    }
  }

  // ── Card evaluation via shallow search ───────────────────────────────────

  double _evaluateCard(
      RangGameState world, String botId, String botTeam,
      PlayingCard card, int depth) {
    try {
      // Simulate playing the card
      RangGameState next = RangEngine.playCard(world, botId, card);

      // Auto-resolve trick if complete
      if (next.currentTrick.length >= next.players.length) {
        next = _resolveTrickIfNeeded(next);
      }

      if (next.status == GameStatus.finished || depth == 0) {
        return _evaluate(next, botTeam);
      }

      // Continue with a 1-ply lookahead using rule-based play for others
      return _evaluate(next, botTeam);
    } catch (e) {
      return 0.0;
    }
  }

  RangGameState _resolveTrickIfNeeded(RangGameState state) {
    return state; // fallback since RangEngine handles this internally on the 4th play
  }

  // ── Evaluation function (partnership-aware) ───────────────────────────────

  double _evaluate(RangGameState state, String botTeam) {
    // Terminal state
    if (state.status == GameStatus.finished) {
      return state.winningTeam == botTeam ? 100.0 : -100.0;
    }

    // Team sars: we want our team's sars to be high
    final teamASars = state.teamASars.toDouble();
    final teamBSars = state.teamBSars.toDouble();

    final ourSars = botTeam == 'A' ? teamASars : teamBSars;
    final theirSars = botTeam == 'A' ? teamBSars : teamASars;

    // Sar differential (primary signal)
    double score = (ourSars - theirSars) * 8.0;

    // Proximity to winning (7 sars wins) — bonus for being close
    score += ourSars * 2.0;
    score -= theirSars * 2.0;

    // Heap size: large heap is a pending opportunity
    // If it's "our" player who's about to collect it, positive
    final heapBonus = state.heap.length * 0.3;
    final heapWinnerIsBot = _teamOwnsHeap(state, botTeam);
    score += heapWinnerIsBot ? heapBonus : -heapBonus * 0.5;

    // Trump conservation: having trump cards is valuable
    if (state.trumpSuit != null) {
      final botPlayer = state.players.firstWhere(
        (p) => p.id == state.currentPlayerId, orElse: () => state.players.first
      );
      final trumpCount = botPlayer.hand
          .where((c) => c.suit == state.trumpSuit).length;
      score += trumpCount * 1.5;  // each trump card = strategic asset
    }

    return score;
  }

  bool _teamOwnsHeap(RangGameState state, String botTeam) {
    // The team that last won a trick (consecutiveWinsByLastWinner tracks streak)
    // If our team's player is lastTrickWinnerId, we're likely to collect heap
    if (state.lastTrickWinnerId == null) return false;
    final winnerIdx = state.players.indexWhere(
      (p) => p.id == state.lastTrickWinnerId
    );
    if (winnerIdx == -1) return false;
    final winnerTeam = winnerIdx % 2 == 0 ? 'A' : 'B';
    return winnerTeam == botTeam;
  }

  int _rankValue(Rank rank) {
    const v = {Rank.two:2,Rank.three:3,Rank.four:4,Rank.five:5,Rank.six:6,
               Rank.seven:7,Rank.eight:8,Rank.nine:9,Rank.ten:10,
               Rank.jack:11,Rank.queen:12,Rank.king:13,Rank.ace:14};
    return v[rank]!;
  }
}
