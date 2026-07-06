import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rang_adda/shared/services/firestore_service.dart';
import 'package:rang_adda/shared/services/auth_service.dart';
import 'package:rang_adda/features/lobby/state/online_game_provider.dart';
import 'package:rang_adda/features/thulla/state/online_thulla_provider.dart';
import 'package:rang_adda/shared/models/game_state.dart';
import 'package:rang_adda/shared/ui/theme.dart';
import 'package:rang_adda/shared/ui/game_table_background.dart';

class WaitingRoomScreen extends ConsumerStatefulWidget {
  final String gameId;
  const WaitingRoomScreen({super.key, required this.gameId});

  @override
  ConsumerState<WaitingRoomScreen> createState() => _WaitingRoomScreenState();
}

class _WaitingRoomScreenState extends ConsumerState<WaitingRoomScreen> {
  @override
  void initState() {
    super.initState();
    // Sync the gameId from URL into the provider (handles page refresh / direct navigation)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentId = ref.read(currentGameIdProvider);
      if (currentId != widget.gameId) {
        ref.read(currentGameIdProvider.notifier).setId(widget.gameId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final stateAsync = ref.watch(onlineGameProvider);
    final user = ref.watch(userProvider).value;

    final isHost =
        stateAsync.value != null &&
        user != null &&
        stateAsync.value!.hostUid == user.uid;

    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      body: Stack(
        children: [
          const GameTableBackground(child: SizedBox.expand()),
          SafeArea(
            child: stateAsync.when(
              data: (state) {
                if (state == null) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.search_off,
                          color: AppTheme.textDisabled,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Room not found",
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentPrimary,
                            foregroundColor: AppTheme.backgroundPrimary,
                          ),
                          onPressed: () {
                            ref
                                .read(currentGameIdProvider.notifier)
                                .setId(null);
                            context.go('/');
                          },
                          child: const Text('BACK TO LOBBY'),
                        ),
                      ],
                    ),
                  );
                }

                // If the user has been kicked (is no longer in the players list)
                if (user != null &&
                    !state.players.any((p) => p.id == user.uid)) {
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
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          color: AppTheme.accentPrimary,
                        ),
                        SizedBox(height: 16),
                        Text(
                          "Starting game...",
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    // Header with room code
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  color: AppTheme.accentPrimary,
                                ),
                                onPressed: () {
                                  ref
                                      .read(currentGameIdProvider.notifier)
                                      .setId(null);
                                  context.go('/');
                                },
                              ),
                              const Spacer(),
                              Text(
                                state.gameType.toUpperCase(),
                                style: const TextStyle(
                                  color: AppTheme.accentSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 3.0,
                                ),
                              ),
                              const Spacer(),
                              const SizedBox(width: 48),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceElevated,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppTheme.accentPrimary.withValues(
                                  alpha: 0.2,
                                ),
                              ),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  'ROOM CODE',
                                  style: TextStyle(
                                    color: AppTheme.textDisabled,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 3.0,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: () {
                                    Clipboard.setData(
                                      ClipboardData(text: widget.gameId),
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Room code copied!'),
                                        duration: Duration(seconds: 1),
                                      ),
                                    );
                                  },
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        widget.gameId,
                                        style: const TextStyle(
                                          color: AppTheme.accentPrimary,
                                          fontSize: 32,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 8.0,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(
                                        Icons.copy,
                                        color: AppTheme.textDisabled,
                                        size: 18,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Tap to copy • Share with friends!',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Players list
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Row(
                        children: [
                          const Text(
                            'PLAYERS',
                            style: TextStyle(
                              color: AppTheme.textDisabled,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 3.0,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${state.players.length}',
                            style: const TextStyle(
                              color: AppTheme.accentSecondary,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: state.players.length,
                        itemBuilder: (context, index) {
                          final player = state.players[index];
                          final isSelf = user?.uid == player.id;
                          final isPlayerHost = player.id == state.hostUid;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isSelf
                                  ? AppTheme.accentPrimary.withValues(
                                      alpha: 0.08,
                                    )
                                  : AppTheme.surfaceElevated,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelf
                                    ? AppTheme.accentPrimary.withValues(
                                        alpha: 0.3,
                                      )
                                    : Colors.transparent,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isPlayerHost ? Icons.star : Icons.person,
                                  color: isSelf
                                      ? AppTheme.accentPrimary
                                      : isPlayerHost
                                      ? AppTheme.accentSecondary
                                      : AppTheme.textDisabled,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Row(
                                    children: [
                                      Text(
                                        player.name,
                                        style: TextStyle(
                                          color: isSelf
                                              ? AppTheme.accentPrimary
                                              : AppTheme.textPrimary,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                        ),
                                      ),
                                      if (isSelf)
                                        const Padding(
                                          padding: EdgeInsets.only(left: 8),
                                          child: Text(
                                            '(You)',
                                            style: TextStyle(
                                              color: AppTheme.textSecondary,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      if (isPlayerHost)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            left: 8,
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppTheme.accentSecondary
                                                  .withValues(alpha: 0.2),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              'HOST',
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.accentSecondary,
                                                letterSpacing: 1.0,
                                              ),
                                            ),
                                          ),
                                        ),
                                      if (player.isBot)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            left: 8,
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.blueGrey.withValues(
                                                alpha: 0.3,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              'BOT',
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.blueGrey,
                                                letterSpacing: 1.0,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                if (isHost && !isSelf)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.person_remove,
                                      color: AppTheme.statusError,
                                      size: 20,
                                    ),
                                    onPressed: () async {
                                      await ref
                                          .read(firestoreServiceProvider)
                                          .kickPlayer(widget.gameId, player.id);
                                    },
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                    // Start button for host
                    if (isHost)
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accentPrimary,
                              foregroundColor: AppTheme.backgroundPrimary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () async {
                              final messenger =
                                  ScaffoldMessenger.of(context);
                              try {
                                await ref
                                    .read(firestoreServiceProvider)
                                    .startGame(widget.gameId);
                              } catch (e) {
                                if (mounted) {
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text("Error starting game: $e"),
                                    ),
                                  );
                                }
                              }
                            },
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.play_arrow),
                                SizedBox(width: 8),
                                Text(
                                  'START GAME',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 3.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceElevated,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.textDisabled.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          child: const Center(
                            child: Text(
                              'WAITING FOR HOST TO START...',
                              style: TextStyle(
                                color: AppTheme.textDisabled,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2.0,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppTheme.accentPrimary),
              ),
              error: (e, st) => Center(
                child: Text(
                  'Error: $e',
                  style: const TextStyle(color: AppTheme.statusError),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
