import 'package:rang_adda/shared/models/card_model.dart';
import 'package:rang_adda/features/rang/engine/rang_game_state.dart';
import 'package:rang_adda/features/rang/engine/rang_engine.dart';
import 'package:rang_adda/features/rang/bot/rang_bot_pimc.dart';

class RangBotHard extends RangBotPIMC {
  RangBotHard() : super(numWorlds: 30, searchDepth: 4);

  @override
  Suit chooseTrump(RangGameState state, String botId) {
    // Same as PIMC trump choice but additionally prefer suits where
    // we have the Ace or King (strongest control)
    final player = state.players.firstWhere((p) => p.id == botId);
    final suitScores = <Suit, double>{};

    for (final suit in Suit.values) {
      final cards = player.hand.where((c) => c.suit == suit).toList();
      double score = cards.length * 1.5;
      if (cards.any((c) => c.rank == Rank.ace)) score += 5.0;
      if (cards.any((c) => c.rank == Rank.king)) score += 3.0;
      if (cards.any((c) => c.rank == Rank.queen)) score += 1.5;
      suitScores[suit] = score;
    }

    return suitScores.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  @override
  PlayingCard chooseCard(RangGameState state, String botId) {
    final player = state.players.firstWhere((p) => p.id == botId);
    final validCards = List<PlayingCard>.from(
      player.hand.where(
        (c) => RangEngine.getMoveError(state, botId, c) == null,
      ),
    );
    if (validCards.length == 1) return validCards.first;

    final botIndex = state.players.indexWhere((p) => p.id == botId);
    final partnerIndex = (botIndex + 2) % 4;
    final partner = state.players[partnerIndex];

    // ── Rule: Don't trump if partner is currently winning the trick ──────
    if (state.currentTrick.isNotEmpty && state.trumpSuit != null) {
      final partnerPlay = state.currentTrick
          .where((tp) => tp.playerId == partner.id)
          .firstOrNull;

      if (partnerPlay != null) {
        // Is partner currently winning?
        final isPartnerWinning = _isCardWinning(partnerPlay.card, state);
        if (isPartnerWinning) {
          // Don't play trump — filter out trump cards if we have alternatives
          final nonTrump = validCards
              .where((c) => c.suit != state.trumpSuit)
              .toList();
          if (nonTrump.isNotEmpty) {
            // Among non-trump valid cards, dump the weakest
            return nonTrump.reduce(
              (a, b) => _rankValue(a.rank) < _rankValue(b.rank) ? a : b,
            );
          }
        }
      }
    }

    // ── Rule: Lead trump when holding 3+ trump cards ─────────────────────
    if (state.currentTrick.isEmpty && state.trumpSuit != null) {
      final myTrump = validCards
          .where((c) => c.suit == state.trumpSuit)
          .toList();
      if (myTrump.length >= 3) {
        // Lead highest trump to draw out opponents
        return myTrump.reduce(
          (a, b) => _rankValue(a.rank) > _rankValue(b.rank) ? a : b,
        );
      }
    }

    // ── Rule: Endgame aggression — 1 sar away from winning ──────────────
    final botTeam = botIndex % 2 == 0 ? 'A' : 'B';
    final ourSars = botTeam == 'A' ? state.teamASars : state.teamBSars;
    if (ourSars >= 6) {
      // One more heap collection wins — lead our strongest card
      if (state.currentTrick.isEmpty) {
        return validCards.reduce(
          (a, b) => _rankValue(a.rank) > _rankValue(b.rank) ? a : b,
        );
      }
    }

    // Fall through to PIMC for everything else
    return super.chooseCard(state, botId);
  }

  bool _isCardWinning(PlayingCard card, RangGameState state) {
    final trumpSuit = state.trumpSuit;
    final leadSuit = state.leadSuit;

    // A card wins if:
    // 1. It's the highest trump played (if any trump is in the trick)
    // 2. It's the highest lead-suit card (if no trump in trick)
    final trickCards = state.currentTrick.map((tp) => tp.card).toList();
    final trumpCards = trickCards.where((c) => c.suit == trumpSuit).toList();

    if (trumpCards.isNotEmpty && trumpSuit != null) {
      if (card.suit != trumpSuit) return false;
      final highestTrump = trumpCards.reduce(
        (a, b) => _rankValue(a.rank) > _rankValue(b.rank) ? a : b,
      );
      return _rankValue(card.rank) >= _rankValue(highestTrump.rank);
    }

    // No trump played yet
    if (card.suit != leadSuit) return false;
    final leadCards = trickCards.where((c) => c.suit == leadSuit).toList();
    if (leadCards.isEmpty) return true;
    final highestLead = leadCards.reduce(
      (a, b) => _rankValue(a.rank) > _rankValue(b.rank) ? a : b,
    );
    return _rankValue(card.rank) >= _rankValue(highestLead.rank);
  }

  int _rankValue(Rank rank) {
    const v = {
      Rank.two: 2,
      Rank.three: 3,
      Rank.four: 4,
      Rank.five: 5,
      Rank.six: 6,
      Rank.seven: 7,
      Rank.eight: 8,
      Rank.nine: 9,
      Rank.ten: 10,
      Rank.jack: 11,
      Rank.queen: 12,
      Rank.king: 13,
      Rank.ace: 14,
    };
    return v[rank]!;
  }
}
