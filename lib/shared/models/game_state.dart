import 'package:equatable/equatable.dart';
import 'package:rang_adda/shared/models/player.dart';
import 'package:rang_adda/features/thulla/engine/thulla_game_state.dart';
import 'package:rang_adda/features/bluff/engine/bluff_game_state.dart';
import 'package:rang_adda/features/rang/engine/rang_game_state.dart';

import 'package:rang_adda/shared/models/chat_message.dart';

enum GameStatus { waiting, playing, finished }

abstract class GameState extends Equatable {
  final String gameId;
  final String gameType;
  final List<Player> players;
  final GameStatus status;
  final String? currentPlayerId;
  final List<ChatMessage> chatMessages;
  final List<String> participantIds;
  final String? hostUid;

  const GameState({
    required this.gameId,
    required this.gameType,
    required this.players,
    required this.status,
    this.currentPlayerId,
    this.chatMessages = const [],
    this.participantIds = const [],
    this.hostUid,
  });

  @override
  List<Object?> get props => [
    gameId,
    gameType,
    players,
    status,
    currentPlayerId,
    chatMessages,
    participantIds,
    hostUid,
  ];

  Map<String, dynamic> toJson();

  factory GameState.fromJson(Map<String, dynamic> json) {
    final type = json['gameType'] as String?;
    if (type == 'bluff') {
      return BluffGameState.fromJson(json);
    } else if (type == 'rang') {
      return RangGameState.fromJson(json);
    } else {
      // Default to thulla for backward compatibility
      return ThullaGameState.fromJson(json);
    }
  }
}
