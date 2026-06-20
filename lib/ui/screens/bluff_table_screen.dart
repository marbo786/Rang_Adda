import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/card_model.dart';
import '../../core/bluff/bluff_game_state.dart';
import '../../state/bluff_provider.dart';
import '../../services/audio_service.dart';
import 'package:flutter/services.dart';
import '../widgets/bluff_hand_widget.dart';
import '../widgets/pass_device_overlay.dart';
import '../widgets/game_table_background.dart';
import '../widgets/opponent_chip.dart';
import '../widgets/deal_animation_overlay.dart';
import '../widgets/winner_pulse_glow.dart';
import '../widgets/game_over_overlay.dart';

class BluffTableScreen extends ConsumerStatefulWidget {
  final List<String>? playerNames;
  const BluffTableScreen({super.key, this.playerNames});

  @override
  ConsumerState<BluffTableScreen> createState() => _BluffTableScreenState();
}

class _BluffTableScreenState extends ConsumerState<BluffTableScreen> {
  bool _dealAnimationComplete = true; // Track if deal animation has played
  int? _lastGameStartTick; // Track the last game start to detect new games

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final names = widget.playerNames ?? ['Alice', 'Bob', 'Charlie', 'Diana'];
      final ids = List.generate(names.length, (i) => 'p${i + 1}');
      ref.read(bluffProvider.notifier).startGame(ids, names);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bluffProvider);
    if (state.players.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Check if game is finished
    if (state.status == BluffGameStatus.finished) {
      // Find the winner (last remaining player with cards)
      final winner = state.players.isNotEmpty
          ? state.players.reduce((a, b) =>
              a.hand.length > b.hand.length ? a : b)
          : state.players.first;
      return Scaffold(
        body: GameOverOverlay(
          winnerName: winner.name,
          onPlayAgain: () {
            ref.read(audioServiceProvider).playClick();
            final names =
                widget.playerNames ?? ['Alice', 'Bob', 'Charlie', 'Diana'];
            final ids = List.generate(names.length, (i) => 'p${i + 1}');
            ref.read(bluffProvider.notifier).startGame(ids, names);
          },
          onBackToLobby: () {
            ref.read(audioServiceProvider).playClick();
            context.go('/');
          },
        ),
      );
    }

    // Detect new game start
    if (_lastGameStartTick != state.hashCode && state.status == BluffGameStatus.playing) {
      _lastGameStartTick = state.hashCode;
      _dealAnimationComplete = false;
    }

    final bottomPlayer = state.players.firstWhere(
      (p) => p.id == state.currentPlayerId,
      orElse: () => state.players.first,
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('BLUFF', style: TextStyle(letterSpacing: 4.0)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/'),
        ),
      ),
      body: GameTableBackground(
        child: SafeArea(
          child: Stack(
            children: [
            Column(
              children: [
                // Top Opponents
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: state.players
                          .where((p) => p.id != bottomPlayer.id)
                          .map((p) {
                            bool isActive = p.id == state.currentPlayerId;
                            // Show pulse glow when player won the last bluff challenge
                            final isWinner = state.resolvingBluffMessage != null &&
                                state.lastPlayerId == p.id;

                            return Stack(
                              alignment: Alignment.center,
                              children: [
                                OpponentChip(
                                  playerName: p.name,
                                  cardCount: p.hand.length,
                                  isActive: isActive,
                                  hasPower: false,
                                ),
                                // Winner pulse glow
                                if (isWinner)
                                  WinnerPulseGlow(
                                    show: isWinner,
                                  ),
                              ],
                            );
                          })
                          .toList(),
                    ),
                  ),
                ),

                // Arena Center
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Status Banner
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          child: Text(
                            'CHOOSE YOUR BLUFF!',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2.0,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),

                        // Center Pile visualization
                        if (state.centerPile.isNotEmpty)
                          AnimatedOpacity(
                            opacity: state.resolvingBluffMessage != null ? 0.0 : 1.0,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInCubic,
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Theme.of(context).colorScheme.surface,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.1),
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${state.centerPile.length}',
                                    style: const TextStyle(
                                      fontSize: 48,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const Text(
                                    'CARDS IN PILE',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white54,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          const Text(
                            'PILE IS EMPTY',
                            style: TextStyle(
                              color: Colors.white24,
                              letterSpacing: 2.0,
                              fontWeight: FontWeight.bold,
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
                            "${bottomPlayer.name.toUpperCase()}'S TURN",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2.0,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                        BluffHandWidget(
                          hand: bottomPlayer.hand,
                          isFirstTurn: state.centerPile.isEmpty,
                          canPass: true,
                          onPass: () async {
                            String? error = await ref
                                .read(bluffProvider.notifier)
                                .passTurn(bottomPlayer.id);
                            if (error != null && mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(error),
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.error,
                                ),
                              );
                            }
                          },
                          onPlayCards: (cards) {
                            _showRankSelectorDialog(
                              context,
                              cards,
                              bottomPlayer.id,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Pass Device Overlay
            if (state.passToPlayerId != null)
              PassDeviceOverlay(
                playerName: state.players
                    .firstWhere((p) => p.id == state.passToPlayerId)
                    .name,
                onAcknowledge: () =>
                    ref.read(bluffProvider.notifier).acknowledgePass(),
              ),

            // Challenge Bluff Overlay
            if (state.passToPlayerId == null &&
                state.lastPlayerId != null &&
                state.lastPlayedCards.isNotEmpty &&
                state.status == BluffGameStatus.playing)
              _buildChallengeOverlay(context, state),

            // Resolving Result Overlay
            if (state.resolvingBluffMessage != null)
              _buildResultOverlay(context, state.resolvingBluffMessage!),

            // Deal animation overlay (plays once at game start)
            if (!_dealAnimationComplete)
              DealAnimationOverlay(
                players: state.players,
                playerCount: state.players.length,
                onAnimationComplete: () {
                  if (mounted) {
                    setState(() {
                      _dealAnimationComplete = true;
                    });
                  }
                },
              ),
          ],
        ),
      ),
    ),
    );
  }

  void _showRankSelectorDialog(
    BuildContext context,
    List<PlayingCard> cards,
    String playerId,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Dialog(
            backgroundColor: Theme.of(
              context,
            ).colorScheme.surface.withValues(alpha: 0.9),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'WHAT RANK ARE YOU CLAIMING?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: Rank.values.map((rank) {
                      return InkWell(
                        onTap: () async {
                          HapticFeedback.mediumImpact();
                          ref.read(audioServiceProvider).playClick();
                          Navigator.of(dialogContext).pop();
                          String? error = await ref
                              .read(bluffProvider.notifier)
                              .playCard(playerId, cards, rank);
                          if (error != null && mounted) {
                            HapticFeedback.vibrate();
                            ref.read(audioServiceProvider).playError();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(error),
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.error,
                              ),
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).primaryColor.withValues(alpha: 0.1),
                            border: Border.all(
                              color: Theme.of(context).primaryColor,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            rank.name.toUpperCase(),
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildChallengeOverlay(BuildContext context, BluffGameState state) {
    String pName = state.players
        .firstWhere((p) => p.id == state.lastPlayerId)
        .name;
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Container(
        color: Colors.black.withValues(alpha: 0.4),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surface.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 48,
                  color: Colors.orangeAccent,
                ),
                const SizedBox(height: 24),
                Text(
                  '$pName claims they played:',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${state.lastPlayedCards.length} ${state.lastClaimedRank?.name.toUpperCase()}S',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      HapticFeedback.heavyImpact();
                      ref.read(audioServiceProvider).playHeavySlam();
                      ref
                          .read(bluffProvider.notifier)
                          .callBluff(state.currentPlayerId);
                    },
                    child: const Text(
                      'CALL BLUFF!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).primaryColor,
                      side: BorderSide(
                        color: Theme.of(
                          context,
                        ).primaryColor.withValues(alpha: 0.5),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      ref.read(audioServiceProvider).playClick();
                      ref.read(bluffProvider.notifier).declineChallenge();
                    },
                    child: const Text(
                      'ACCEPT & PLAY',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultOverlay(BuildContext context, String message) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Container(
        color: Colors.black.withValues(alpha: 0.4),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surface.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.gavel, size: 48, color: Colors.white),
                const SizedBox(height: 24),
                Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      ref.read(audioServiceProvider).playClick();
                      ref
                          .read(bluffProvider.notifier)
                          .acknowledgeResolvingMessage();
                    },
                    child: const Text(
                      'CONTINUE',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
