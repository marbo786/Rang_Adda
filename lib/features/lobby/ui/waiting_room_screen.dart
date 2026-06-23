import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rang_adda/shared/services/firestore_service.dart';
import 'package:rang_adda/shared/services/auth_service.dart';
import 'package:rang_adda/features/lobby/state/online_game_provider.dart';
import 'package:rang_adda/features/thulla/state/online_thulla_provider.dart';
import 'package:rang_adda/shared/models/game_state.dart';

class WaitingRoomScreen extends ConsumerWidget {
  final String gameId;
  const WaitingRoomScreen({super.key, required this.gameId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(onlineGameProvider);
    final user = ref.watch(userProvider).value;

    final isHost =
        stateAsync.value != null &&
        user != null &&
        stateAsync.value!.hostUid == user.uid;

    return Scaffold(
      appBar: AppBar(title: Text('Room Code: $gameId')),
      body: stateAsync.when(
        data: (state) {
          if (state == null) return const Center(child: Text("Room not found"));

          // If the user has been kicked (is no longer in the players list)
          if (user != null && !state.players.any((p) => p.id == user.uid)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref.read(currentGameIdProvider.notifier).setId(null);
              context.go('/');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('You have been kicked from the room.'),
                ),
              );
            });
            return const Center(child: Text("You were kicked..."));
          }

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
                    final player = state.players[index];
                    final isSelf = user?.uid == player.id;
                    return ListTile(
                      leading: Icon(
                        Icons.person,
                        color: isSelf ? Colors.greenAccent : Colors.tealAccent,
                      ),
                      title: Text(player.name + (isSelf ? " (You)" : "")),
                      trailing: (isHost && !isSelf)
                          ? IconButton(
                              icon: const Icon(
                                Icons.person_remove,
                                color: Colors.redAccent,
                              ),
                              onPressed: () async {
                                await ref
                                    .read(firestoreServiceProvider)
                                    .kickPlayer(gameId, player.id);
                              },
                            )
                          : null,
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
      floatingActionButton: isHost
          ? FloatingActionButton.extended(
              onPressed: () async {
                await ref.read(firestoreServiceProvider).startGame(gameId);
              },
              label: const Text('Start Game'),
              icon: const Icon(Icons.play_arrow),
            )
          : null,
    );
  }
}
