import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rang_adda/shared/models/card_model.dart';
import 'package:rang_adda/features/bluff/engine/bluff_game_state.dart';
import 'package:rang_adda/features/bluff/state/bluff_provider.dart';
import 'package:rang_adda/shared/services/audio_service.dart';
import 'package:flutter/services.dart';
import 'package:rang_adda/features/bluff/ui/bluff_hand_widget.dart';
import 'package:rang_adda/features/bluff/state/online_bluff_provider.dart';
import 'package:rang_adda/shared/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rang_adda/shared/ui/pass_device_overlay.dart';
import 'package:rang_adda/shared/ui/game_table_background.dart';
import 'package:rang_adda/shared/ui/deal_animation_overlay.dart';
import 'package:rang_adda/shared/ui/game_over_overlay.dart';
import 'package:rang_adda/shared/models/game_state.dart';
import 'package:rang_adda/shared/models/player.dart';
import 'package:rang_adda/shared/ui/theme.dart';
import 'package:rang_adda/shared/ui/chat_overlay.dart';
import 'package:rang_adda/shared/ui/round_table_widget.dart';
import 'dart:math' as math;

class BluffTableScreen extends ConsumerStatefulWidget {
  final List<String>? playerNames;
  final bool isOnline;
  const BluffTableScreen({super.key, this.playerNames, this.isOnline = false});

  @override
  ConsumerState<BluffTableScreen> createState() => _BluffTableScreenState();
}

class _BluffTableScreenState extends ConsumerState<BluffTableScreen> {

  void _showChatModal(String gameId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ChatInputModal(gameId: gameId),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!widget.isOnline) {
        final names = widget.playerNames ?? ['Alice', 'Bob', 'Charlie', 'Diana'];
        final ids = List.generate(names.length, (i) => 'p${i + 1}');
        ref.read(bluffProvider.notifier).startGame(ids, names);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.isOnline
        ? ref.watch(onlineBluffProvider).value
        : ref.watch(bluffProvider);
        
    if (state == null || state.players.isEmpty) {
      return const Scaffold(
          backgroundColor: AppTheme.backgroundPrimary,
          body: Center(child: CircularProgressIndicator(color: AppTheme.accentPrimary)));
    }
    
    if (state.status == GameStatus.finished) {
      // Find the winner (player without remaining cards)
      final winner = state.players.firstWhere(
        (p) => p.hand.isEmpty,
        orElse: () => state.players.last,
      );
      return Scaffold(
        body: GameOverOverlay(
          winnerName: winner.name,
          isHost: !widget.isOnline || FirebaseAuth.instance.currentUser?.uid == state.hostUid,
          onPlayAgain: () {
            ref.read(audioServiceProvider).playClick();
            if (!widget.isOnline) {
              ref.read(bluffProvider.notifier).startGame(
                    ['p1', 'p2', 'p3', 'p4'],
                    widget.playerNames ?? ['Alice', 'Bob', 'Charlie', 'Diana'],
                  );
            } else {
              context.go('/');
            }
          },
          onBackToLobby: () {
            ref.read(audioServiceProvider).playClick();
            context.go('/');
          },
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

    final isYourTurn = state.currentPlayerId == bottomPlayer.id;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: AppBar(
        title: Text(
          'BLUFF',
          style: TextStyle(
            color: AppTheme.accentSecondary,
            letterSpacing: 4.0,
            fontWeight: FontWeight.w900,
            shadows: [
              Shadow(
                color: AppTheme.accentSecondary.withValues(alpha: 0.5),
                blurRadius: 12,
              )
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.accentPrimary),
          onPressed: () => context.go('/'),
        ),
      ),
      body: GameTableBackground(
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  // Round Table
                  Padding(
                    padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
                    child: RoundTableWidget(
                      playerNames: state.players.map((p) => p.name).toList(),
                      playerIds: state.players.map((p) => p.id).toList(),
                      activePlayerIndex: state.players.indexWhere((p) => p.id == state.currentPlayerId),
                      cardCounts: state.players.map((p) => p.hand.length).toList(),
                      currentTrickPlays: const {},
                      size: math.min(MediaQuery.of(context).size.width * 0.75, 300),
                    ),
                  ),

                  // Arena Center
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
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
                              color: isYourTurn
                                  ? AppTheme.accentPrimary.withValues(alpha: 0.15)
                                  : AppTheme.surfaceElevated,
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: isYourTurn
                                    ? AppTheme.accentPrimary
                                    : AppTheme.accentPrimary.withValues(alpha: 0.1),
                                width: 1.5,
                              ),
                              boxShadow: isYourTurn
                                  ? [
                                      BoxShadow(
                                        color: AppTheme.neonGlow,
                                        blurRadius: 16,
                                      )
                                    ]
                                  : [],
                            ),
                            child: Text(
                              isYourTurn
                                  ? 'CHOOSE YOUR BLUFF!'
                                  : 'WAITING FOR ${state.players.firstWhere((p) => p.id == state.currentPlayerId).name.toUpperCase()}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2.0,
                                color: isYourTurn
                                    ? AppTheme.accentPrimary
                                    : AppTheme.textSecondary,
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
                                padding: const EdgeInsets.all(28),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.surfaceElevated,
                                  border: Border.all(
                                    color: AppTheme.accentSecondary.withValues(alpha: 0.5),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.accentSecondary.withValues(alpha: 0.3),
                                      blurRadius: 24,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${state.centerPile.length}',
                                      style: TextStyle(
                                        fontSize: 48,
                                        fontWeight: FontWeight.w900,
                                        color: AppTheme.textPrimary,
                                        shadows: [
                                          Shadow(
                                            color: AppTheme.accentSecondary.withValues(alpha: 0.5),
                                            blurRadius: 12,
                                          )
                                        ],
                                      ),
                                    ),
                                    const Text(
                                      'CARDS IN PILE',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.textSecondary,
                                        letterSpacing: 2.0,
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
                                color: AppTheme.textDisabled,
                                letterSpacing: 2.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    ),
                    ),
                  ),

                  // Bottom Player Hand
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceElevated,
                      border: Border(
                        top: BorderSide(
                          color: AppTheme.accentPrimary.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.neonGlow,
                          blurRadius: 24,
                          offset: const Offset(0, -8),
                        ),
                      ],
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
                              isYourTurn
                                  ? 'YOUR TURN'
                                  : bottomPlayer.name.toUpperCase(),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 3.0,
                                color: isYourTurn
                                    ? AppTheme.accentPrimary
                                    : AppTheme.textSecondary,
                                shadows: isYourTurn
                                    ? [
                                        Shadow(
                                          color: AppTheme.neonGlow,
                                          blurRadius: 8,
                                        )
                                      ]
                                    : [],
                              ),
                            ),
                          ),
                          BluffHandWidget(
                              hand: bottomPlayer.hand,
                              isFirstTurn: state.centerPile.isEmpty,
                            canPass: true,
                            onPass: () async {
                              if (widget.isOnline) {
                                final user = ref.read(userProvider).value;
                                if (user == null || user.uid != bottomPlayer.id) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("You can only play your own hand!"),
                                    ),
                                  );
                                  return;
                                }
                              }
                              
                              String? error;
                              if (widget.isOnline) {
                                await ref.read(onlineBluffActionProvider).passTurn(bottomPlayer.id);
                              } else {
                                error = await ref
                                    .read(bluffProvider.notifier)
                                    .passTurn(bottomPlayer.id);
                              }
                              if (error != null && mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(error),
                                    backgroundColor: AppTheme.statusError,
                                  ),
                                );
                              }
                            },
                            onPlayCards: (cards) {
                              if (widget.isOnline) {
                                final user = ref.read(userProvider).value;
                                if (user == null || user.uid != bottomPlayer.id) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("You can only play your own hand!"),
                                    ),
                                  );
                                  return;
                                }
                              }
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
              if (state.passToPlayerId != null && !widget.isOnline)
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
                  state.status == GameStatus.playing)
                _buildChallengeOverlay(context, state, bottomPlayer),

              // Resolving Result Overlay
              if (state.resolvingBluffMessage != null)
                _buildResultOverlay(context, state.resolvingBluffMessage!),

              if (widget.isOnline)
                ChatOverlay(messages: state.chatMessages),
            ],
          ),
        ),
      ),
      floatingActionButton: widget.isOnline
          ? FloatingActionButton(
              onPressed: () => _showChatModal(state.gameId),
              backgroundColor: AppTheme.accentPrimary,
              foregroundColor: AppTheme.backgroundPrimary,
              child: const Icon(Icons.chat),
            )
          : null,
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
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Dialog(
            backgroundColor: AppTheme.surfaceElevated.withValues(alpha: 0.9),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(
                color: AppTheme.accentPrimary.withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
            elevation: 0,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.neonGlow,
                    blurRadius: 32,
                    spreadRadius: -8,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(28.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'WHAT RANK ARE YOU CLAIMING?',
                    style: TextStyle(
                      color: AppTheme.accentSecondary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.0,
                      shadows: [
                        Shadow(
                          color: AppTheme.accentSecondary.withValues(alpha: 0.5),
                          blurRadius: 8,
                        )
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: Rank.values.map((rank) {
                      return InkWell(
                        onTap: () async {
                          HapticFeedback.mediumImpact();
                          ref.read(audioServiceProvider).playClick();
                          Navigator.of(dialogContext).pop();
                          
                          String? error;
                          if (widget.isOnline) {
                            error = await ref
                                .read(onlineBluffActionProvider)
                                .playCard(playerId, cards, rank);
                          } else {
                            error = await ref
                                .read(bluffProvider.notifier)
                                .playCard(playerId, cards, rank);
                          }
                          
                          if (error != null && mounted) {
                            HapticFeedback.vibrate();
                            ref.read(audioServiceProvider).playError();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(error),
                                backgroundColor: AppTheme.statusError,
                              ),
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.accentPrimary.withValues(alpha: 0.1),
                            border: Border.all(
                              color: AppTheme.accentPrimary.withValues(alpha: 0.5),
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            rank.name.toUpperCase(),
                            style: const TextStyle(
                              color: AppTheme.accentPrimary,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text(
                      'CANCEL',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildChallengeOverlay(BuildContext context, BluffGameState state, Player bottomPlayer) {
    String pName = state.players
        .firstWhere((p) => p.id == state.lastPlayerId)
        .name;
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Container(
        color: AppTheme.backgroundPrimary.withValues(alpha: 0.6),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.surfaceElevated.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppTheme.statusWarning.withValues(alpha: 0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.statusWarning.withValues(alpha: 0.2),
                  blurRadius: 32,
                  spreadRadius: -8,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.statusWarning.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    size: 48,
                    color: AppTheme.statusWarning,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  '$pName claims they played:',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 16,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${state.lastPlayedCards.length} ${state.lastClaimedRank?.name.toUpperCase()}S',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                    shadows: [
                      Shadow(
                        color: AppTheme.statusWarning.withValues(alpha: 0.5),
                        blurRadius: 8,
                      )
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.statusError,
                      foregroundColor: AppTheme.textPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      HapticFeedback.heavyImpact();
                      ref.read(audioServiceProvider).playHeavySlam();
                      if (widget.isOnline) {
                        ref.read(onlineBluffActionProvider).callBluff(bottomPlayer.id);
                      } else {
                        ref
                            .read(bluffProvider.notifier)
                            .callBluff(state.currentPlayerId!);
                      }
                    },
                    child: const Text(
                      'CALL BLUFF!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.accentPrimary,
                      side: const BorderSide(
                        color: AppTheme.accentPrimary,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      ref.read(audioServiceProvider).playClick();
                      if (widget.isOnline) {
                        // Online decline means pass turn implicitly
                        ref.read(onlineBluffActionProvider).passTurn(bottomPlayer.id);
                      } else {
                        ref.read(bluffProvider.notifier).declineChallenge();
                      }
                    },
                    child: const Text(
                      'ACCEPT & PLAY',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
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
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Container(
        color: AppTheme.backgroundPrimary.withValues(alpha: 0.6),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.surfaceElevated.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppTheme.accentSecondary.withValues(alpha: 0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accentSecondary.withValues(alpha: 0.2),
                  blurRadius: 32,
                  spreadRadius: -8,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.accentSecondary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.gavel_rounded, size: 48, color: AppTheme.accentSecondary),
                ),
                const SizedBox(height: 24),
                Text(
                  message,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentPrimary,
                      foregroundColor: AppTheme.backgroundPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      ref.read(audioServiceProvider).playClick();
                      if (widget.isOnline) {
                        ref.read(onlineBluffActionProvider).acknowledgeResolvingMessage();
                      } else {
                        ref
                            .read(bluffProvider.notifier)
                            .acknowledgeResolvingMessage();
                      }
                    },
                    child: const Text(
                      'CONTINUE',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2.0,
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
