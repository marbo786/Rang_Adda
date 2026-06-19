import 'package:equatable/equatable.dart';
import '../models/card_model.dart';
import '../models/player.dart';

enum BluffGameStatus { initial, playing, finished }

class BluffGameState extends Equatable {
  final String gameId;
  final List<Player> players;
  final BluffGameStatus status;
  final String currentPlayerId;
  final String? lastPlayerId;
  final List<PlayingCard> centerPile;
  final List<PlayingCard> lastPlayedCards;
  final Rank? lastClaimedRank;
  final int consecutivePasses;
  final String? passToPlayerId;
  final String? resolvingBluffMessage;

  const BluffGameState({
    required this.gameId,
    required this.players,
    this.status = BluffGameStatus.initial,
    required this.currentPlayerId,
    this.lastPlayerId,
    this.centerPile = const [],
    this.lastPlayedCards = const [],
    this.lastClaimedRank,
    this.consecutivePasses = 0,
    this.passToPlayerId,
    this.resolvingBluffMessage,
  });

  BluffGameState copyWith({
    String? gameId,
    List<Player>? players,
    BluffGameStatus? status,
    String? currentPlayerId,
    String? lastPlayerId,
    List<PlayingCard>? centerPile,
    List<PlayingCard>? lastPlayedCards,
    Rank? lastClaimedRank,
    int? consecutivePasses,
    String? passToPlayerId,
    String? resolvingBluffMessage,
  }) {
    return BluffGameState(
      gameId: gameId ?? this.gameId,
      players: players ?? this.players,
      status: status ?? this.status,
      currentPlayerId: currentPlayerId ?? this.currentPlayerId,
      lastPlayerId: lastPlayerId ?? this.lastPlayerId,
      centerPile: centerPile ?? this.centerPile,
      lastPlayedCards: lastPlayedCards ?? this.lastPlayedCards,
      lastClaimedRank: lastClaimedRank ?? this.lastClaimedRank,
      consecutivePasses: consecutivePasses ?? this.consecutivePasses,
      passToPlayerId: passToPlayerId ?? this.passToPlayerId,
      resolvingBluffMessage: resolvingBluffMessage ?? this.resolvingBluffMessage,
    );
  }

  BluffGameState clearOverlays() {
     return BluffGameState(
       gameId: gameId,
       players: players,
       status: status,
       currentPlayerId: currentPlayerId,
       lastPlayerId: lastPlayerId,
       centerPile: centerPile,
       lastPlayedCards: lastPlayedCards,
       lastClaimedRank: lastClaimedRank,
       consecutivePasses: consecutivePasses,
       passToPlayerId: null,
       resolvingBluffMessage: null,
     );
  }
  
  BluffGameState setPassDevice(String passTo) {
     return BluffGameState(
       gameId: gameId,
       players: players,
       status: status,
       currentPlayerId: currentPlayerId,
       lastPlayerId: lastPlayerId,
       centerPile: centerPile,
       lastPlayedCards: lastPlayedCards,
       lastClaimedRank: lastClaimedRank,
       consecutivePasses: consecutivePasses,
       passToPlayerId: passTo,
       resolvingBluffMessage: resolvingBluffMessage,
     );
  }

  BluffGameState setResolvingMessage(String message) {
     return BluffGameState(
       gameId: gameId,
       players: players,
       status: status,
       currentPlayerId: currentPlayerId,
       lastPlayerId: lastPlayerId,
       centerPile: centerPile,
       lastPlayedCards: lastPlayedCards,
       lastClaimedRank: lastClaimedRank,
       consecutivePasses: consecutivePasses,
       passToPlayerId: passToPlayerId,
       resolvingBluffMessage: message,
     );
  }

  @override
  List<Object?> get props => [
        gameId,
        players,
        status,
        currentPlayerId,
        lastPlayerId,
        centerPile,
        lastPlayedCards,
        lastClaimedRank,
        consecutivePasses,
        passToPlayerId,
        resolvingBluffMessage,
      ];
}
