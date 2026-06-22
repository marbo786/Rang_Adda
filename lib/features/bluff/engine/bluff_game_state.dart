import 'package:rang_adda/shared/models/card_model.dart';
import 'package:rang_adda/shared/models/player.dart';
import 'package:rang_adda/shared/models/game_state.dart';
import 'package:rang_adda/shared/models/chat_message.dart';

class BluffGameState extends GameState {
  final String? lastPlayerId;
  final List<PlayingCard> centerPile;
  final List<PlayingCard> lastPlayedCards;
  final Rank? lastClaimedRank;
  final int consecutivePasses;
  final String? passToPlayerId;
  final String? resolvingBluffMessage;
  final bool isOnline;

  const BluffGameState({
    required super.gameId,
    super.gameType = 'bluff',
    required super.players,
    super.status = GameStatus.waiting,
    required String currentPlayerId,
    super.chatMessages = const [],
    this.lastPlayerId,
    this.centerPile = const [],
    this.lastPlayedCards = const [],
    this.lastClaimedRank,
    this.consecutivePasses = 0,
    this.passToPlayerId,
    this.resolvingBluffMessage,
    this.isOnline = false,
  }) : super(currentPlayerId: currentPlayerId);

  BluffGameState copyWith({
    String? gameId,
    List<Player>? players,
    GameStatus? status,
    String? currentPlayerId,
    String? lastPlayerId,
    List<PlayingCard>? centerPile,
    List<PlayingCard>? lastPlayedCards,
    Rank? lastClaimedRank,
    int? consecutivePasses,
    String? passToPlayerId,
    String? resolvingBluffMessage,
    bool? isOnline,
    List<ChatMessage>? chatMessages,
  }) {
    return BluffGameState(
      gameId: gameId ?? this.gameId,
      players: players ?? this.players,
      status: status ?? this.status,
      currentPlayerId: (currentPlayerId ?? this.currentPlayerId)!,
      lastPlayerId: lastPlayerId ?? this.lastPlayerId,
      centerPile: centerPile ?? this.centerPile,
      lastPlayedCards: lastPlayedCards ?? this.lastPlayedCards,
      lastClaimedRank: lastClaimedRank ?? this.lastClaimedRank,
      consecutivePasses: consecutivePasses ?? this.consecutivePasses,
      passToPlayerId: passToPlayerId ?? this.passToPlayerId,
      resolvingBluffMessage:
          resolvingBluffMessage ?? this.resolvingBluffMessage,
      isOnline: isOnline ?? this.isOnline,
      chatMessages: chatMessages ?? this.chatMessages,
    );
  }

  BluffGameState clearOverlays() {
    return BluffGameState(
      gameId: gameId,
      players: players,
      status: status,
      currentPlayerId: currentPlayerId!,
      lastPlayerId: lastPlayerId,
      centerPile: centerPile,
      lastPlayedCards: lastPlayedCards,
      lastClaimedRank: lastClaimedRank,
      consecutivePasses: consecutivePasses,
      passToPlayerId: null,
      resolvingBluffMessage: null,
      isOnline: isOnline,
    );
  }

  BluffGameState setPassDevice(String passTo) {
    return BluffGameState(
      gameId: gameId,
      players: players,
      status: status,
      currentPlayerId: currentPlayerId!,
      lastPlayerId: lastPlayerId,
      centerPile: centerPile,
      lastPlayedCards: lastPlayedCards,
      lastClaimedRank: lastClaimedRank,
      consecutivePasses: consecutivePasses,
      passToPlayerId: passTo,
      resolvingBluffMessage: resolvingBluffMessage,
      isOnline: isOnline,
    );
  }

  BluffGameState setResolvingMessage(String message) {
    return BluffGameState(
      gameId: gameId,
      players: players,
      status: status,
      currentPlayerId: currentPlayerId!,
      lastPlayerId: lastPlayerId,
      centerPile: centerPile,
      lastPlayedCards: lastPlayedCards,
      lastClaimedRank: lastClaimedRank,
      consecutivePasses: consecutivePasses,
      passToPlayerId: passToPlayerId,
      resolvingBluffMessage: message,
      isOnline: isOnline,
    );
  }

  @override
  List<Object?> get props => [
    ...super.props,
    lastPlayerId,
    centerPile,
    lastPlayedCards,
    lastClaimedRank,
    consecutivePasses,
    passToPlayerId,
    resolvingBluffMessage,
    isOnline,
  ];

  @override
  Map<String, dynamic> toJson() => {
        'gameId': gameId,
        'gameType': gameType,
        'players': players.map((p) => p.toJson()).toList(),
        'status': status.index,
        'currentPlayerId': currentPlayerId,
        'chatMessages': chatMessages.map((m) => m.toJson()).toList(),
        'lastPlayerId': lastPlayerId,
        'centerPile': centerPile.map((c) => c.toJson()).toList(),
        'lastPlayedCards': lastPlayedCards.map((c) => c.toJson()).toList(),
        'lastClaimedRank': lastClaimedRank?.index,
        'consecutivePasses': consecutivePasses,
        'passToPlayerId': passToPlayerId,
        'resolvingBluffMessage': resolvingBluffMessage,
        'isOnline': isOnline,
      };

  factory BluffGameState.fromJson(Map<String, dynamic> json) {
    return BluffGameState(
      gameId: json['gameId'] as String,
      players: (json['players'] as List)
          .map((p) => Player.fromJson(p as Map<String, dynamic>))
          .toList(),
      status: GameStatus.values[json['status'] as int],
      currentPlayerId: json['currentPlayerId'] as String,
      chatMessages: (json['chatMessages'] as List?)
              ?.map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
              .toList() ??
          const [],
      lastPlayerId: json['lastPlayerId'] as String?,
      centerPile: (json['centerPile'] as List)
          .map((c) => PlayingCard.fromJson(c as Map<String, dynamic>))
          .toList(),
      lastPlayedCards: (json['lastPlayedCards'] as List)
          .map((c) => PlayingCard.fromJson(c as Map<String, dynamic>))
          .toList(),
      lastClaimedRank: json['lastClaimedRank'] != null 
          ? Rank.values[json['lastClaimedRank'] as int] 
          : null,
      consecutivePasses: json['consecutivePasses'] as int? ?? 0,
      passToPlayerId: json['passToPlayerId'] as String?,
      resolvingBluffMessage: json['resolvingBluffMessage'] as String?,
      isOnline: json['isOnline'] as bool? ?? false,
    );
  }
}
