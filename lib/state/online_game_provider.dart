import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/models/game_state.dart';
import '../services/firestore_service.dart';
import 'online_thulla_provider.dart';

final onlineGameProvider = StreamProvider<GameState?>((ref) {
  final gameId = ref.watch(currentGameIdProvider);
  if (gameId == null) return const Stream.empty();

  final firestore = ref.read(firestoreServiceProvider);
  return firestore.streamGame(gameId);
});
