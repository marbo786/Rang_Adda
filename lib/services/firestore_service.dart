import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/models/player.dart';
import '../core/models/game_state.dart';
import '../core/thulla/thulla_game_state.dart';
import '../core/thulla/thulla_engine.dart';
import '../core/bluff/bluff_game_state.dart';
import '../core/bluff/bluff_engine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<GameState?> streamGame(String gameId) {
    return _db.collection('games').doc(gameId).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      try {
        return GameState.fromJson(snapshot.data()!);
      } catch (e) {
        print("Error parsing game state: $e");
        return null;
      }
    });
  }

  Future<String> createWaitingRoom(String hostId, String hostName, String gameType) async {
    final gameId = DateTime.now().millisecondsSinceEpoch.toString().substring(
      7,
    ); // e.g. "456789"
    
    GameState state;
    if (gameType == 'bluff') {
      state = BluffGameState(
        gameId: gameId,
        players: [Player(id: hostId, name: hostName)],
        status: GameStatus.waiting,
        currentPlayerId: hostId,
      );
    } else {
      state = ThullaGameState(
        gameId: gameId,
        players: [Player(id: hostId, name: hostName)],
        status: GameStatus.waiting,
      );
    }
    
    await _db.collection('games').doc(gameId).set(state.toJson());
    return gameId;
  }

  Future<void> joinWaitingRoom(
    String gameId,
    String playerId,
    String playerName,
  ) async {
    final doc = await _db.collection('games').doc(gameId).get();
    if (!doc.exists) throw Exception("Game not found");

    final state = GameState.fromJson(doc.data()!);
    if (state.status != GameStatus.waiting) {
      throw Exception("Game already started");
    }

    if (!state.players.any((p) => p.id == playerId)) {
      final newPlayers = [
        ...state.players,
        Player(id: playerId, name: playerName),
      ];
      await _db.collection('games').doc(gameId).update({
        'players': newPlayers.map((p) => p.toJson()).toList(),
      });
    }
  }

  Future<void> startGame(String gameId) async {
    final doc = await _db.collection('games').doc(gameId).get();
    if (!doc.exists) return;

    final state = GameState.fromJson(doc.data()!);
    GameState playingState;
    
    if (state.gameType == 'bluff') {
      // In a real app we'd want a separate initializeOnlineGame.
      // But for now, we can just use the initializeGame and copy the players to maintain their Firebase UIDs.
      final playerIds = state.players.map((p) => p.id).toList();
      final playerNames = state.players.map((p) => p.name).toList();
      final initialized = BluffEngine.initializeGame(playerIds, playerNames);
      playingState = initialized.copyWith(
        gameId: state.gameId, 
        status: GameStatus.playing,
        isOnline: true
      );
    } else {
      playingState = ThullaEngine.startGameFromWaitingRoom(state as ThullaGameState);
      // Ensure online flag is set
      playingState = (playingState as ThullaGameState).copyWith(isOnline: true);
    }
    
    await updateGameState(playingState);
  }

  Future<void> updateGameState(GameState state) async {
    await _db.collection('games').doc(state.gameId).set(state.toJson());
  }
}
