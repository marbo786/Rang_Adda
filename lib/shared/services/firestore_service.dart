import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:rang_adda/shared/models/player.dart';
import 'package:rang_adda/shared/models/game_state.dart';
import 'package:rang_adda/features/thulla/engine/thulla_game_state.dart';
import 'package:rang_adda/features/thulla/engine/thulla_engine.dart';
import 'package:rang_adda/features/bluff/engine/bluff_game_state.dart';
import 'package:rang_adda/features/bluff/engine/bluff_engine.dart';
import 'package:rang_adda/shared/models/user_model.dart';
import 'package:rang_adda/shared/models/chat_message.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

class FirestoreService {
  FirebaseFirestore? get _db => Firebase.apps.isNotEmpty ? FirebaseFirestore.instance : null;

  Stream<GameState?> streamGame(String gameId) {
    if (_db == null) return const Stream.empty();
    return _db!.collection('games').doc(gameId).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      try {
        return GameState.fromJson(snapshot.data()!);
      } catch (e) {
        return null;
      }
    });
  }

  Future<String> createWaitingRoom(String hostId, String hostName, String gameType) async {
    if (_db == null) throw Exception("Firebase not initialized");
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
    
    await _db!.collection('games').doc(gameId).set(state.toJson());
    return gameId;
  }

  Future<void> joinWaitingRoom(
    String gameId,
    String playerId,
    String playerName,
  ) async {
    if (_db == null) throw Exception("Firebase not initialized");
    final doc = await _db!.collection('games').doc(gameId).get();
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
      await _db!.collection('games').doc(gameId).update({
        'players': newPlayers.map((p) => p.toJson()).toList(),
      });
    }
  }

  Future<void> startGame(String gameId) async {
    if (_db == null) throw Exception("Firebase not initialized");
    final doc = await _db!.collection('games').doc(gameId).get();
    if (!doc.exists) return;

    final state = GameState.fromJson(doc.data()!);
    GameState playingState;
    
    if (state.gameType == 'bluff') {
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
      playingState = (playingState as ThullaGameState).copyWith(isOnline: true);
    }
    
    await updateGameState(playingState);
  }

  Future<void> updateGameState(GameState state) async {
    if (_db == null) return;
    await _db!.collection('games').doc(state.gameId).set(state.toJson());
  }

  Future<void> kickPlayer(String gameId, String playerIdToKick) async {
    if (_db == null) return;
    final doc = await _db!.collection('games').doc(gameId).get();
    if (!doc.exists) return;

    final state = GameState.fromJson(doc.data()!);
    final newPlayers = state.players.where((p) => p.id != playerIdToKick).toList();
    
    await _db!.collection('games').doc(gameId).update({
      'players': newPlayers.map((p) => p.toJson()).toList(),
    });
  }

  // ── Profiles & Leaderboards ────────────────────────────────────────────────

  Future<List<UserModel>> getLeaderboard() async {
    if (_db == null) return [];
    final snapshot = await _db!
        .collection('users')
        .orderBy('wins', descending: true)
        .limit(50)
        .get();
    return snapshot.docs.map((doc) => UserModel.fromJson(doc.data())).toList();
  }

  Future<void> updateUserStats(String uid, {required bool isWin}) async {
    if (_db == null) return;
    final userRef = _db!.collection('users').doc(uid);
    await _db!.runTransaction((transaction) async {
      final doc = await transaction.get(userRef);
      if (!doc.exists) return;
      final user = UserModel.fromJson(doc.data()!);
      final updatedUser = user.copyWith(
        wins: user.wins + (isWin ? 1 : 0),
        losses: user.losses + (isWin ? 0 : 1),
        gamesPlayed: user.gamesPlayed + 1,
      );
      transaction.update(userRef, updatedUser.toJson());
    });
  }

  // ── Chat & Emojis ──────────────────────────────────────────────────────────

  Future<void> sendChatMessage(String gameId, ChatMessage message) async {
    if (_db == null) return;
    final docRef = _db!.collection('games').doc(gameId);
    await _db!.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;
      final state = GameState.fromJson(snapshot.data()!);
      
      final updatedMessages = List<ChatMessage>.from(state.chatMessages)..add(message);
      if (updatedMessages.length > 50) {
        updatedMessages.removeAt(0);
      }
      
      transaction.update(docRef, {
        'chatMessages': updatedMessages.map((m) => m.toJson()).toList(),
      });
    });
  }

  Future<void> sendEmoji(String gameId, String playerId, String emoji) async {
    if (_db == null) return;
    final docRef = _db!.collection('games').doc(gameId);
    await _db!.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;
      
      final state = GameState.fromJson(snapshot.data()!);
      final updatedPlayers = state.players.map((p) {
        if (p.id == playerId) {
          return p.copyWith(latestEmoji: emoji);
        }
        return p;
      }).toList();
      
      transaction.update(docRef, {
        'players': updatedPlayers.map((p) => p.toJson()).toList(),
      });
    });
  }
}
