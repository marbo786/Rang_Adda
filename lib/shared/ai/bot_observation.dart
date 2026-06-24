import 'package:equatable/equatable.dart';
import 'package:rang_adda/shared/models/card_model.dart';
import 'package:rang_adda/features/thulla/engine/thulla_game_state.dart';
import 'package:rang_adda/features/rang/engine/rang_game_state.dart';
import 'package:rang_adda/features/rang/engine/rang_trick_play.dart';
import 'package:rang_adda/features/bluff/engine/bluff_game_state.dart';

/// Base class for all bot observations to ensure bots cannot access hidden state.
sealed class BotObservation extends Equatable {
  final List<PlayingCard> myHand;
  final String myId;
  final Map<String, int> opponentCardCounts;

  const BotObservation({
    required this.myHand,
    required this.myId,
    required this.opponentCardCounts,
  });

  @override
  List<Object?> get props => [myHand, myId, opponentCardCounts];
}

class ThullaBotObservation extends BotObservation {
  final List<TrickPlay> currentTrick;
  final Suit? leadSuit;
  final List<PlayingCard> wastePile;
  final bool isFirstTrick;

  const ThullaBotObservation({
    required super.myHand,
    required super.myId,
    required super.opponentCardCounts,
    required this.currentTrick,
    required this.leadSuit,
    required this.wastePile,
    required this.isFirstTrick,
  });

  @override
  List<Object?> get props => [
    ...super.props,
    currentTrick,
    leadSuit,
    wastePile,
    isFirstTrick,
  ];

  factory ThullaBotObservation.fromState(ThullaGameState state, String myId) {
    final me = state.players.firstWhere((p) => p.id == myId);
    final opponentCardCounts = {
      for (final p in state.players)
        if (p.id != myId) p.id: p.cardCount,
    };

    return ThullaBotObservation(
      myHand: List.unmodifiable(me.hand),
      myId: myId,
      opponentCardCounts: Map.unmodifiable(opponentCardCounts),
      currentTrick: List.unmodifiable(state.currentTrick),
      leadSuit: state.leadSuit,
      wastePile: List.unmodifiable(state.wastePile),
      isFirstTrick: state.isFirstTrick,
    );
  }
}

class BluffBotObservation extends BotObservation {
  final int centerPileCount;
  final Rank? lastClaimedRank;
  final int lastPlayedCount;
  final String? lastPlayerId;
  final int consecutivePasses;

  const BluffBotObservation({
    required super.myHand,
    required super.myId,
    required super.opponentCardCounts,
    required this.centerPileCount,
    required this.lastClaimedRank,
    required this.lastPlayedCount,
    required this.lastPlayerId,
    required this.consecutivePasses,
  });

  @override
  List<Object?> get props => [
    ...super.props,
    centerPileCount,
    lastClaimedRank,
    lastPlayedCount,
    lastPlayerId,
    consecutivePasses,
  ];

  factory BluffBotObservation.fromState(BluffGameState state, String myId) {
    final me = state.players.firstWhere((p) => p.id == myId);
    final opponentCardCounts = {
      for (final p in state.players)
        if (p.id != myId) p.id: p.cardCount,
    };

    return BluffBotObservation(
      myHand: List.unmodifiable(me.hand),
      myId: myId,
      opponentCardCounts: Map.unmodifiable(opponentCardCounts),
      centerPileCount: state.centerPile.length,
      lastClaimedRank: state.lastClaimedRank,
      lastPlayedCount: state.lastPlayedCards.length,
      lastPlayerId: state.lastPlayerId,
      consecutivePasses: state.consecutivePasses,
    );
  }
}

class RangBotObservation extends BotObservation {
  final String? partnerId;
  final Suit? trumpSuit;
  final List<RangTrickPlay> currentTrick;
  final Suit? leadSuit;
  final int teamASars;
  final int teamBSars;

  const RangBotObservation({
    required super.myHand,
    required super.myId,
    required super.opponentCardCounts,
    required this.partnerId,
    required this.trumpSuit,
    required this.currentTrick,
    required this.leadSuit,
    required this.teamASars,
    required this.teamBSars,
  });

  @override
  List<Object?> get props => [
    ...super.props,
    partnerId,
    trumpSuit,
    currentTrick,
    leadSuit,
    teamASars,
    teamBSars,
  ];

  factory RangBotObservation.fromState(RangGameState state, String myId) {
    final me = state.players.firstWhere((p) => p.id == myId);
    final opponentCardCounts = {
      for (final p in state.players)
        if (p.id != myId) p.id: p.cardCount,
    };

    // Determine partner
    final myIndex = state.players.indexWhere((p) => p.id == myId);
    final partnerIndex = (myIndex + 2) % 4;
    final partnerId = state.players[partnerIndex].id;

    return RangBotObservation(
      myHand: List.unmodifiable(me.hand),
      myId: myId,
      opponentCardCounts: Map.unmodifiable(opponentCardCounts),
      partnerId: partnerId,
      trumpSuit: state.trumpSuit,
      currentTrick: List.unmodifiable(state.currentTrick),
      leadSuit: state.leadSuit,
      teamASars: state.teamASars,
      teamBSars: state.teamBSars,
    );
  }
}
