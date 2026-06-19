import 'package:equatable/equatable.dart';
import 'player.dart';

enum GameStatus { waiting, playing, finished }

abstract class GameState extends Equatable {
  final String gameId;
  final List<Player> players;
  final GameStatus status;
  final String? currentPlayerId;

  const GameState({
    required this.gameId,
    required this.players,
    required this.status,
    this.currentPlayerId,
  });

  @override
  List<Object?> get props => [gameId, players, status, currentPlayerId];
}
