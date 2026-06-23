import 'package:equatable/equatable.dart';
import 'package:rang_adda/shared/models/card_model.dart';
import 'package:rang_adda/shared/models/game_state.dart';
import 'package:rang_adda/shared/models/player.dart';
import 'package:rang_adda/shared/models/chat_message.dart';

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
  final String? passToPlayerId;
  final bool trickResolving;
  final bool isOnline;

  const ThullaGameState({
    required super.gameId,
    super.gameType = 'thulla',
    required super.players,
    super.status = GameStatus.waiting,
    super.currentPlayerId,
    super.chatMessages = const [],
    this.wastePile = const [],
    this.currentTrick = const [],
    this.powerPlayerId,
    this.passToPlayerId,
    this.trickResolving = false,
    this.isOnline = false,
    super.participantIds = const [],
    super.hostUid,
  });

  bool get isFirstTrick => wastePile.isEmpty;

  Suit? get leadSuit =>
      currentTrick.isNotEmpty ? currentTrick.first.card.suit : null;

  ThullaGameState copyWith({
    String? gameId,
    List<Player>? players,
    GameStatus? status,
    String? currentPlayerId,
    bool clearCurrentPlayerId = false,
    List<PlayingCard>? wastePile,
    List<TrickPlay>? currentTrick,
    String? powerPlayerId,
    bool clearPowerPlayerId = false,
    String? passToPlayerId,
    bool clearPassToPlayerId = false,
    bool? trickResolving,
    bool? isOnline,
    List<ChatMessage>? chatMessages,
    List<String>? participantIds,
    String? hostUid,
  }) {
    return ThullaGameState(
      gameId: gameId ?? this.gameId,
      players: players ?? this.players,
      status: status ?? this.status,
      currentPlayerId: clearCurrentPlayerId
          ? null
          : (currentPlayerId ?? this.currentPlayerId),
      wastePile: wastePile ?? this.wastePile,
      currentTrick: currentTrick ?? this.currentTrick,
      powerPlayerId: clearPowerPlayerId
          ? null
          : (powerPlayerId ?? this.powerPlayerId),
      passToPlayerId: clearPassToPlayerId
          ? null
          : (passToPlayerId ?? this.passToPlayerId),
      trickResolving: trickResolving ?? this.trickResolving,
      isOnline: isOnline ?? this.isOnline,
      chatMessages: chatMessages ?? this.chatMessages,
      participantIds: participantIds ?? this.participantIds,
      hostUid: hostUid ?? this.hostUid,
    );
  }

  @override
  List<Object?> get props => [
        ...super.props,
        wastePile,
        currentTrick,
        powerPlayerId,
        passToPlayerId,
        trickResolving,
        isOnline,
        hostUid,
      ];

  @override
  Map<String, dynamic> toJson() => {
    'gameId': gameId,
    'gameType': gameType,
    'players': players.map((p) => p.toJson()).toList(),
    'status': status.index,
    'currentPlayerId': currentPlayerId,
    'chatMessages': chatMessages.map((m) => m.toJson()).toList(),
    'wastePile': wastePile.map((c) => c.toJson()).toList(),
    'currentTrick': currentTrick.map((t) => t.toJson()).toList(),
    'powerPlayerId': powerPlayerId,
    'passToPlayerId': passToPlayerId,
    'trickResolving': trickResolving,
    'isOnline': isOnline,
    'participantIds': participantIds,
    'hostUid': hostUid,
  };

  factory ThullaGameState.fromJson(Map<String, dynamic> json) {
    return ThullaGameState(
      gameId: json['gameId'] as String,
      players: (json['players'] as List)
          .map((p) => Player.fromJson(p as Map<String, dynamic>))
          .toList(),
      status: GameStatus.values[json['status'] as int],
      currentPlayerId: json['currentPlayerId'] as String?,
      chatMessages: (json['chatMessages'] as List?)
              ?.map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
              .toList() ??
          const [],
      wastePile: (json['wastePile'] as List)
          .map((c) => PlayingCard.fromJson(c as Map<String, dynamic>))
          .toList(),
      currentTrick: (json['currentTrick'] as List)
          .map((t) => TrickPlay.fromJson(t as Map<String, dynamic>))
          .toList(),
      powerPlayerId: json['powerPlayerId'] as String?,
      passToPlayerId: json['passToPlayerId'] as String?,
      trickResolving: json['trickResolving'] as bool? ?? false,
      isOnline: json['isOnline'] as bool? ?? false,
      participantIds: (json['participantIds'] as List?)?.map((e) => e as String).toList() ?? const [],
      hostUid: json['hostUid'] as String?,
    );
  }
}
