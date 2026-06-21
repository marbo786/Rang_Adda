import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/firestore_service.dart';
import '../../state/online_game_provider.dart';
import '../../core/models/game_state.dart';

class WaitingRoomScreen extends ConsumerWidget {
  final String gameId;
  const WaitingRoomScreen({super.key, required this.gameId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(onlineGameProvider);

    return Scaffold(
      appBar: AppBar(title: Text('Room Code: $gameId')),
      body: stateAsync.when(
        data: (state) {
          if (state == null) return const Center(child: Text("Room not found"));

          if (state.status == GameStatus.playing) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (state.gameType == 'bluff') {
                context.go('/online_bluff');
              } else {
                context.go('/online_thulla');
              }
            });
            return const Center(child: Text("Starting game..."));
          }

          return Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Share this code with your friends to let them join!',
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: state.players.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: const Icon(
                        Icons.person,
                        color: Colors.tealAccent,
                      ),
                      title: Text(state.players[index].name),
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await ref.read(firestoreServiceProvider).startGame(gameId);
        },
        label: const Text('Start Game'),
        icon: const Icon(Icons.play_arrow),
      ),
    );
  }
}
