import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/game_state.dart';
import '../../core/models/player.dart';
import '../../state/thulla_provider.dart';
import '../widgets/playing_card_widget.dart';
import '../widgets/hand_widget.dart';
import '../widgets/pass_device_overlay.dart';
import '../../services/auth_service.dart';
import '../../state/online_thulla_provider.dart';
import '../../core/thulla/thulla_engine.dart';
import 'package:go_router/go_router.dart';

class ThullaTableScreen extends ConsumerStatefulWidget {
  final bool isOnline;
  const ThullaTableScreen({super.key, this.isOnline = false});

  @override
  ConsumerState<ThullaTableScreen> createState() => _ThullaTableScreenState();
}

class _ThullaTableScreenState extends ConsumerState<ThullaTableScreen> {
  @override
  void initState() {
    super.initState();
    if (!widget.isOnline) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(thullaProvider.notifier).startGame([
          'Alice',
          'Bob',
          'Charlie',
        ]);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.isOnline
        ? ref.watch(onlineThullaProvider).value
        : ref.watch(thullaProvider);

    if (state == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (state.status == GameStatus.finished) {
      final loser = state.players.firstWhere(
        (p) => p.hand.isNotEmpty,
        orElse: () => state.players.first,
      );
      return Scaffold(
        appBar: AppBar(title: const Text('Game Over')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${loser.name} lost!',
                style: const TextStyle(fontSize: 32, color: Colors.redAccent),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (!widget.isOnline) {
                    ref.read(thullaProvider.notifier).startGame([
                      'Alice',
                      'Bob',
                      'Charlie',
                    ]);
                  } else {
                    context.go('/');
                  }
                },
                child: const Text('Play Again / Exit'),
              ),
            ],
          ),
        ),
      );
    }

    Player bottomPlayer = state.players.firstWhere(
      (p) => p.id == state.currentPlayerId,
      orElse: () => state.players.first,
    );
    if (widget.isOnline) {
      final user = ref.read(userProvider).value;
      if (user != null) {
        bottomPlayer = state.players.firstWhere(
          (p) => p.id == user.uid,
          orElse: () => state.players.first,
        );
      }
    }

    final activePlayer = state.players.firstWhere(
      (p) => p.id == state.currentPlayerId,
      orElse: () => state.players.first,
    );

    String bannerText = "";
    if (state.trickResolving) {
      if (state.currentTrick.any((t) => t.card.suit != state.leadSuit)) {
        bannerText = "Thulla! The trick is resolving...";
      } else {
        bannerText = "Trick resolving...";
      }
    } else {
      if (state.currentPlayerId == bottomPlayer.id) {
        if (state.leadSuit != null) {
          bannerText = "Your turn! Play a ${state.leadSuit!.name}.";
        } else {
          bannerText = "Your turn! Lead a card.";
        }
      } else {
        bannerText = "Waiting for ${activePlayer.name} to play...";
      }
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('THULLA', style: TextStyle(letterSpacing: 4.0)),
        backgroundColor: Colors.transparent,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                child: Text(
                  'WASTE: ${state.wastePile.length}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Top Opponents
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: state.players
                        .where((p) => p.id != bottomPlayer.id)
                        .map((p) {
                          bool hasPower = p.id == state.powerPlayerId;
                          bool isActive = p.id == state.currentPlayerId;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 20,
                            ),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? Theme.of(context).colorScheme.surface
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isActive
                                    ? Theme.of(context).primaryColor
                                    : Colors.white.withValues(alpha: 0.1),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  p.name.toUpperCase(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.0,
                                    color: hasPower
                                        ? Theme.of(
                                            context,
                                          ).colorScheme.secondary
                                        : Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.style,
                                      size: 16,
                                      color: hasPower
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.secondary
                                          : Colors.white54,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${p.hand.length}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        })
                        .toList(),
                  ),
                ),

                // Arena Center
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Status Banner
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color:
                                state.currentPlayerId == bottomPlayer.id &&
                                    !state.trickResolving
                                ? Theme.of(
                                    context,
                                  ).primaryColor.withValues(alpha: 0.1)
                                : Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color:
                                  state.currentPlayerId == bottomPlayer.id &&
                                      !state.trickResolving
                                  ? Theme.of(context).primaryColor
                                  : Colors.white.withValues(alpha: 0.05),
                            ),
                          ),
                          child: Text(
                            bannerText.toUpperCase(),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.5,
                              color: state.currentPlayerId == bottomPlayer.id
                                  ? Theme.of(context).primaryColor
                                  : Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.color,
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),

                        // Trick Area (Stack for clean positioning)
                        SizedBox(
                          height: 180,
                          width: 300,
                          child: Stack(
                            alignment: Alignment.center,
                            children: List.generate(state.currentTrick.length, (
                              index,
                            ) {
                              final t = state.currentTrick[index];
                              final offset =
                                  (index -
                                      (state.currentTrick.length - 1) / 2) *
                                  35.0;
                              final rotation =
                                  (index -
                                      (state.currentTrick.length - 1) / 2) *
                                  0.1;

                              return AnimatedPositioned(
                                duration: const Duration(milliseconds: 350),
                                curve: Curves.easeOutCubic,
                                left: 115 + offset,
                                top: state.trickResolving ? -50 : 20,
                                child: Transform.rotate(
                                  angle: rotation,
                                  child: AnimatedScale(
                                    duration: const Duration(milliseconds: 350),
                                    scale: state.trickResolving ? 0.8 : 1.0,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          t.playerId,
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Theme.of(
                                              context,
                                            ).textTheme.bodySmall?.color,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        PlayingCardWidget(
                                          card: t.card,
                                          width: 70,
                                          height: 105,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom Player Hand
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    border: Border(
                      top: BorderSide(
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                            top: 16.0,
                            bottom: 4.0,
                          ),
                          child: Text(
                            bottomPlayer.id == state.currentPlayerId
                                ? 'YOUR TURN'
                                : bottomPlayer.name.toUpperCase(),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2.0,
                              color: bottomPlayer.id == state.currentPlayerId
                                  ? Theme.of(context).primaryColor
                                  : Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.color,
                            ),
                          ),
                        ),
                        HandWidget(
                          hand: bottomPlayer.hand,
                          isCardValid: (card) =>
                              ThullaEngine.getMoveError(
                                state,
                                bottomPlayer.id,
                                card,
                              ) ==
                              null,
                          onCardTap: (card) async {
                            if (widget.isOnline) {
                              final user = ref.read(userProvider).value;
                              if (user == null || user.uid != bottomPlayer.id) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "You can only play your own cards!",
                                    ),
                                  ),
                                );
                                return;
                              }
                            }

                            String? error;
                            if (widget.isOnline) {
                              error = await ref
                                  .read(onlineActionProvider)
                                  .playCard(bottomPlayer.id, card);
                            } else {
                              error = await ref
                                  .read(thullaProvider.notifier)
                                  .playCard(bottomPlayer.id, card);
                            }

                            if (error != null && mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(error),
                                  duration: const Duration(seconds: 2),
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.error,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (state.passToPlayerId != null && !widget.isOnline)
              PassDeviceOverlay(
                playerName: state.passToPlayerId!,
                onAcknowledge: () =>
                    ref.read(thullaProvider.notifier).acknowledgePass(),
              ),
          ],
        ),
      ),
    );
  }
}
