import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/models/player.dart';
import '../core/models/game_state.dart';
import '../core/thulla/thulla_game_state.dart';
import '../core/thulla/thulla_engine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<ThullaGameState?> streamGame(String gameId) {
    return _db.collection('games').doc(gameId).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      try {
         return ThullaGameState.fromJson(snapshot.data()!);
      } catch (e) {
         print("Error parsing game state: $e");
         return null;
      }
    });
  }

  Future<String> createWaitingRoom(String hostId, String hostName) async {
    final gameId = DateTime.now().millisecondsSinceEpoch.toString().substring(7); // e.g. "456789"
    final state = ThullaGameState(
      gameId: gameId,
      players: [Player(id: hostId, name: hostName)],
      status: GameStatus.waiting,
    );
    await _db.collection('games').doc(gameId).set(state.toJson());
    return gameId;
  }

  Future<void> joinWaitingRoom(String gameId, String playerId, String playerName) async {
    final doc = await _db.collection('games').doc(gameId).get();
    if (!doc.exists) throw Exception("Game not found");
    
    final state = ThullaGameState.fromJson(doc.data()!);
    if (state.status != GameStatus.waiting) throw Exception("Game already started");
    
    if (!state.players.any((p) => p.id == playerId)) {
       final newPlayers = [...state.players, Player(id: playerId, name: playerName)];
       await _db.collection('games').doc(gameId).update({
         'players': newPlayers.map((p) => p.toJson()).toList()
       });
    }
  }

  Future<void> startGame(String gameId) async {
    final doc = await _db.collection('games').doc(gameId).get();
    if (!doc.exists) return;
    
    final state = ThullaGameState.fromJson(doc.data()!);
    final playingState = ThullaEngine.startGameFromWaitingRoom(state);
    await updateGameState(playingState);
  }

  Future<void> updateGameState(ThullaGameState state) async {
    await _db.collection('games').doc(state.gameId).set(state.toJson());
  }
}
