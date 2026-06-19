import 'package:equatable/equatable.dart';
import '../models/card_model.dart';
import '../models/game_state.dart';
import '../models/player.dart';

class TrickPlay extends Equatable {
  final String playerId;
  final PlayingCard card;

  const TrickPlay({required this.playerId, required this.card});

  @override
  List<Object?> get props => [playerId, card];

  Map<String, dynamic> toJson() => {
        'playerId': playerId,
        'card': card.toJson(),
      };

  factory TrickPlay.fromJson(Map<String, dynamic> json) {
    return TrickPlay(
      playerId: json['playerId'] as String,
      card: PlayingCard.fromJson(json['card'] as Map<String, dynamic>),
    );
  }
}

class ThullaGameState extends GameState {
  final List<PlayingCard> wastePile;
  final List<TrickPlay> currentTrick;
  final String? powerPlayerId;
  final bool isFirstTrick;
  final String? passToPlayerId; 
  final bool trickResolving;
  final bool isOnline;

  const ThullaGameState({
    required String gameId,
    required List<Player> players,
    required GameStatus status,
    String? currentPlayerId,
    this.wastePile = const [],
    this.currentTrick = const [],
    this.powerPlayerId,
    this.isFirstTrick = true,
    this.passToPlayerId,
    this.trickResolving = false,
    this.isOnline = false,
  }) : super(
          gameId: gameId,
          players: players,
          status: status,
          currentPlayerId: currentPlayerId,
        );

  Suit? get leadSuit => currentTrick.isNotEmpty ? currentTrick.first.card.suit : null;

  ThullaGameState copyWith({
    String? gameId,
    List<Player>? players,
    GameStatus? status,
    String? currentPlayerId,
    bool clearCurrentPlayerId = false,
    List<PlayingCard>? wastePile,
    List<TrickPlay>? currentTrick,
    String? powerPlayerId,
    bool? isFirstTrick,
    String? passToPlayerId,
    bool clearPassToPlayerId = false,
    bool? trickResolving,
    bool? isOnline,
  }) {
    return ThullaGameState(
      gameId: gameId ?? this.gameId,
      players: players ?? this.players,
      status: status ?? this.status,
      currentPlayerId: clearCurrentPlayerId ? null : (currentPlayerId ?? this.currentPlayerId),
      wastePile: wastePile ?? this.wastePile,
      currentTrick: currentTrick ?? this.currentTrick,
      powerPlayerId: powerPlayerId ?? this.powerPlayerId,
      isFirstTrick: isFirstTrick ?? this.isFirstTrick,
      passToPlayerId: clearPassToPlayerId ? null : (passToPlayerId ?? this.passToPlayerId),
      trickResolving: trickResolving ?? this.trickResolving,
      isOnline: isOnline ?? this.isOnline,
    );
  }

  @override
  List<Object?> get props => [
        ...super.props,
        wastePile,
        currentTrick,
        powerPlayerId,
        isFirstTrick,
        passToPlayerId,
        trickResolving,
        isOnline,
      ];

  Map<String, dynamic> toJson() => {
        'gameId': gameId,
        'players': players.map((p) => p.toJson()).toList(),
        'status': status.index,
        'currentPlayerId': currentPlayerId,
        'wastePile': wastePile.map((c) => c.toJson()).toList(),
        'currentTrick': currentTrick.map((t) => t.toJson()).toList(),
        'powerPlayerId': powerPlayerId,
        'isFirstTrick': isFirstTrick,
        'passToPlayerId': passToPlayerId,
        'trickResolving': trickResolving,
      };

  factory ThullaGameState.fromJson(Map<String, dynamic> json) {
    return ThullaGameState(
      gameId: json['gameId'] as String,
      players: (json['players'] as List).map((p) => Player.fromJson(p as Map<String, dynamic>)).toList(),
      status: GameStatus.values[json['status'] as int],
      currentPlayerId: json['currentPlayerId'] as String?,
      wastePile: (json['wastePile'] as List).map((c) => PlayingCard.fromJson(c as Map<String, dynamic>)).toList(),
      currentTrick: (json['currentTrick'] as List).map((t) => TrickPlay.fromJson(t as Map<String, dynamic>)).toList(),
      powerPlayerId: json['powerPlayerId'] as String?,
      isFirstTrick: json['isFirstTrick'] as bool? ?? true,
      passToPlayerId: json['passToPlayerId'] as String?,
      trickResolving: json['trickResolving'] as bool? ?? false,
    );
  }
}
