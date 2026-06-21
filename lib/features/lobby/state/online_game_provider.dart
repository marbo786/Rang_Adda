import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rang_adda/shared/models/game_state.dart';
import 'package:rang_adda/shared/services/firestore_service.dart';
import 'package:rang_adda/features/thulla/state/online_thulla_provider.dart';

final onlineGameProvider = StreamProvider<GameState?>((ref) {
  final gameId = ref.watch(currentGameIdProvider);
  if (gameId == null) return const Stream.empty();

  final firestore = ref.read(firestoreServiceProvider);
  return firestore.streamGame(gameId);
});
