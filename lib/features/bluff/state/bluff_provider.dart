import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rang_adda/shared/models/card_model.dart';
import 'package:rang_adda/shared/models/player.dart';
import 'package:rang_adda/shared/models/game_state.dart';
import 'package:rang_adda/features/bluff/engine/bluff_game_state.dart';
import 'package:rang_adda/features/bluff/engine/bluff_engine.dart';
import 'package:rang_adda/shared/ai/bot_observation.dart';
import 'package:rang_adda/features/bluff/ai/bluff_bot.dart';
import 'package:rang_adda/shared/ai/bot_delay.dart';

class BluffNotifier extends Notifier<BluffGameState> {
  final Map<String, BluffBot> _bots = {};

  @override
  BluffGameState build() {
    return const BluffGameState(
      gameId: 'initial',
      players: [],
      currentPlayerId: '',
    );
  }

  void startGame(List<Player> players) {
    _bots.clear();
    for (final p in players) {
      if (p.isBot && p.botDifficulty != null) {
        _bots[p.id] = BluffBot.create(p.botDifficulty!, p.name);
      }
    }
    state = BluffEngine.initializeGame(players);
    _triggerBotTurnIfNeeded();
  }

  Future<String?> playCard(
    String playerId,
    List<PlayingCard> cards,
    Rank claimedRank,
  ) async {
    try {
      state = BluffEngine.playCards(state, playerId, cards, claimedRank);
      _triggerBotTurnIfNeeded();
      return null;
    } catch (e) {
      return e.toString().replaceAll("Exception: ", "");
    }
  }

  Future<String?> passTurn(String playerId) async {
    try {
      state = BluffEngine.passTurn(state, playerId);
      _triggerBotTurnIfNeeded();
      return null;
    } catch (e) {
      return e.toString().replaceAll("Exception: ", "");
    }
  }

  Future<String?> callBluff(String callerId) async {
    try {
      state = BluffEngine.callBluff(state, callerId);

      // Fix local resolution gap:
      if (state.pendingBluffCallerId != null) {
        // Give UI time to show "XYZ Called Bluff!"
        await Future.delayed(const Duration(milliseconds: 1500));
        state = BluffEngine.resolveBluffCall(state);
        _triggerBotTurnIfNeeded();
      }

      return null;
    } catch (e) {
      return e.toString().replaceAll("Exception: ", "");
    }
  }

  void acknowledgePass() {
    state = state.clearOverlays();
    _triggerBotTurnIfNeeded();
  }

  void declineChallenge() {
    state = state.copyWith(
      lastPlayerId: null,
      lastClaimedRank: null,
      lastPlayedCards: [],
    );
    _triggerBotTurnIfNeeded();
  }

  void acknowledgeResolvingMessage() {
    state = state.clearOverlays();
    _triggerBotTurnIfNeeded();
  }

  void _triggerBotTurnIfNeeded() async {
    if (state.status == GameStatus.finished) return;

    // Auto-acknowledge overlays for bots
    if (state.resolvingBluffMessage != null) {
      // It's a global message. Wait a bit, then if it's still there and it's a bot's turn next...
      // Actually, resolving message blocks everything. Let's just say if the NEXT player is a bot,
      // or if ANY player is a bot... let's just auto-clear it after a delay if the next player is a bot.
      // Better: we can wait 3 seconds and auto-clear it for everyone if it's local.
      return;
    }

    if (state.passToPlayerId != null) {
      final passingToPlayer = state.players.firstWhere(
        (p) => p.id == state.passToPlayerId,
      );
      if (passingToPlayer.isBot) {
        acknowledgePass();
        return;
      }
      return;
    }

    if (state.currentPlayerId?.isEmpty ?? true) return;

    final currentPlayer = state.players.firstWhere(
      (p) => p.id == state.currentPlayerId,
    );
    if (currentPlayer.isBot && _bots.containsKey(currentPlayer.id)) {
      final bot = _bots[currentPlayer.id]!;

      await BotDelay.simulateThinking(currentPlayer.botDifficulty!);

      if (state.currentPlayerId != currentPlayer.id) return;

      final obs = BluffBotObservation.fromState(state, currentPlayer.id);

      // Does the bot want to challenge the previous play?
      if (state.lastPlayerId != null &&
          state.lastClaimedRank != null &&
          state.lastPlayerId != currentPlayer.id) {
        final challengeDecision = bot.respondToPlay(obs);
        if (challengeDecision == BluffChallengeDecision.callBluff) {
          await callBluff(currentPlayer.id);
          return;
        }
      }

      // If no challenge, make a play or pass
      if (state.centerPile.isNotEmpty) {
        // Sometimes bots might just pass if they can't bluff safely, but choosePlay handles whether it plays or passes?
        // Wait, choosePlay only returns BluffPlayDecision. We need to decide if bot passes or plays.
        // Actually, if bot.choosePlay returns cards, it plays.
        // What if bot wants to pass? The interface I wrote didn't have a pass option in BluffPlayDecision.
        // If center pile is not empty and bot doesn't want to play, it should pass.
        // Let's check choosePlay logic. Right now choosePlay ALWAYS returns a play.
        // To be safe, if choosePlay returns cards, we play them.
      }

      final decision = bot.choosePlay(obs);
      if (decision.cards.isNotEmpty) {
        await playCard(currentPlayer.id, decision.cards, decision.claimedRank);
      } else {
        await passTurn(currentPlayer.id);
      }
    }
  }
}

final bluffProvider = NotifierProvider<BluffNotifier, BluffGameState>(() {
  return BluffNotifier();
});
