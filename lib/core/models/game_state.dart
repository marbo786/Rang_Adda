import 'package:equatable/equatable.dart';
import 'player.dart';
import '../thulla/thulla_game_state.dart';
import '../bluff/bluff_game_state.dart';

enum GameStatus { waiting, playing, finished }

abstract class GameState extends Equatable {
  final String gameId;
  final String gameType;
  final List<Player> players;
  final GameStatus status;
  final String? currentPlayerId;

  const GameState({
    required this.gameId,
    required this.gameType,
    required this.players,
    required this.status,
    this.currentPlayerId,
  });

  @override
  List<Object?> get props => [gameId, gameType, players, status, currentPlayerId];

  Map<String, dynamic> toJson();

  factory GameState.fromJson(Map<String, dynamic> json) {
    final type = json['gameType'] as String?;
    if (type == 'bluff') {
      return BluffGameState.fromJson(json);
    } else {
      // Default to thulla for backward compatibility
      return ThullaGameState.fromJson(json);
    }
  }
}
