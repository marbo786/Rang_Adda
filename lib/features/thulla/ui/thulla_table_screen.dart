import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rang_adda/shared/models/game_state.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rang_adda/shared/models/player.dart';
import 'package:rang_adda/features/thulla/state/thulla_provider.dart';
import 'package:rang_adda/shared/ui/playing_card_widget.dart';
import 'package:rang_adda/shared/ui/hand_widget.dart';
import 'package:rang_adda/shared/ui/pass_device_overlay.dart';
import 'package:rang_adda/shared/ui/game_table_background.dart';
import 'package:rang_adda/shared/ui/trick_winner_banner.dart';
import 'package:rang_adda/shared/ui/tuing_rabbit_overlay.dart';

import 'package:rang_adda/shared/ui/game_over_overlay.dart';
import 'package:rang_adda/shared/services/auth_service.dart';
import 'package:rang_adda/shared/services/audio_service.dart';
import 'package:rang_adda/features/thulla/state/online_thulla_provider.dart';
import 'package:rang_adda/features/thulla/engine/thulla_engine.dart';
import 'package:rang_adda/features/thulla/engine/thulla_game_state.dart';
import 'package:rang_adda/shared/ui/theme.dart';
import 'package:go_router/go_router.dart';
import 'package:rang_adda/shared/ui/chat_overlay.dart';
import 'package:rang_adda/shared/ui/round_table_widget.dart';
import 'package:rang_adda/utils/player_session_storage.dart';
import 'dart:math' as math;

class ThullaTableScreen extends ConsumerStatefulWidget {
  final bool isOnline;
  final List<Player>? players;
  const ThullaTableScreen({super.key, this.isOnline = false, this.players});

  @override
  ConsumerState<ThullaTableScreen> createState() => _ThullaTableScreenState();
}

class _ThullaTableScreenState extends ConsumerState<ThullaTableScreen> {
  // ── Trick-winner banner state ────────────────────────────────────────────
  bool _showBanner = false;
  String _bannerWinnerName = '';
  bool _isTochooBanner = false;
  bool _bannerSequenceRunning = false;
  bool _showTuingRabbit = false;

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
    if (!widget.isOnline) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ps = resolvePlayers(widget.players, 'thulla');
        ref.read(thullaProvider.notifier).startGame(ps);
      });
    }
  }

  /// Called (from local playCard path OR online ref.listen) when the state
  /// has just flipped to trickResolving == true.
  /// Shows the banner for 2 s, fades it out, then (local only) resolves trick.
  void _triggerTuing() {
    ref.read(audioServiceProvider).playTuing();
    setState(() => _showTuingRabbit = true);
  }

  Future<void> _runBannerSequence(
    ThullaGameState trickState, {
    required bool resolveLocally,
  }) async {
    if (_bannerSequenceRunning) return;
    _bannerSequenceRunning = true;

    try {
      // 1. Peek at who wins without touching the engine.
      final peek = ThullaEngine.peekTrickWinner(trickState);
      final winnerPlayer = trickState.players.firstWhere(
        (p) => p.id == peek.winnerId,
        orElse: () => trickState.players.first,
      );

      // 2. Show banner.
      if (mounted) {
        setState(() {
          _bannerWinnerName = winnerPlayer.name;
          _isTochooBanner = peek.isTochoo;
          _showBanner = true;
        });
        if (peek.isTochoo) {
          _triggerTuing();
        }
      }

      // 3. Keep banner visible for 2 s.
      await Future.delayed(const Duration(milliseconds: 2000));

      // 4. Trigger exit animation (200 ms fade-out).
      if (mounted) setState(() => _showBanner = false);
      await Future.delayed(const Duration(milliseconds: 200));

      // 5. Resolve trick (local only — online provider handles its own resolve).
      if (resolveLocally && mounted) {
        ref.read(thullaProvider.notifier).resolveTrick();
      }
    } finally {
      _bannerSequenceRunning = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.isOnline
        ? ref.watch(onlineThullaProvider).value
        : ref.watch(thullaProvider);

    // ── Local: watch for trickResolving transition (bot plays or human) ──────
    if (!widget.isOnline) {
      ref.listen<ThullaGameState?>(thullaProvider, (previous, next) {
        if (next != null &&
            next.trickResolving &&
            previous?.trickResolving != true &&
            next.currentTrick.isNotEmpty) {
          _runBannerSequence(next, resolveLocally: true);
        }
      });
    }

    // ── Online: watch for trickResolving transition and show banner ──────────
    if (widget.isOnline) {
      ref.listen<AsyncValue<ThullaGameState?>>(onlineThullaProvider, (
        previous,
        next,
      ) {
        final prev = previous?.value;
        final curr = next.value;
        if (curr != null &&
            curr.trickResolving &&
            prev?.trickResolving != true &&
            curr.currentTrick.isNotEmpty) {
          _runBannerSequence(curr, resolveLocally: false);
        }
      });
    }

    if (state == null || state.players.isEmpty) {
      return const Scaffold(
        backgroundColor: AppTheme.backgroundPrimary,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.accentPrimary),
        ),
      );
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
          isHost:
              !widget.isOnline ||
              FirebaseAuth.instance.currentUser?.uid == state.hostUid,
          onPlayAgain: () {
            ref.read(audioServiceProvider).playClick();
            if (!widget.isOnline) {
              final ps = resolvePlayers(widget.players, 'thulla');
              ref.read(thullaProvider.notifier).startGame(ps);
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
      (p) => p.id == state.currentPlayerId && !p.isBot,
      orElse: () => state.players.firstWhere(
        (p) => !p.isBot,
        orElse: () => state.players.first,
      ),
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

    final isYourTurn =
        state.currentPlayerId == bottomPlayer.id && !state.trickResolving;
    final hasWaste = state.wastePile.isNotEmpty;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: AppBar(
        title: Text(
          'THULLA',
          style: TextStyle(
            color: AppTheme.accentSecondary,
            letterSpacing: 4.0,
            fontWeight: FontWeight.w900,
            shadows: [
              Shadow(
                color: AppTheme.accentSecondary.withValues(alpha: 0.5),
                blurRadius: 12,
              ),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppTheme.accentPrimary,
          ),
          onPressed: () {
            ref.read(audioServiceProvider).playClick();
            context.go('/');
          },
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: hasWaste
                        ? AppTheme.statusError.withValues(alpha: 0.5)
                        : AppTheme.textDisabled,
                    width: 1.5,
                  ),
                  boxShadow: hasWaste
                      ? [
                          BoxShadow(
                            color: AppTheme.statusError.withValues(alpha: 0.2),
                            blurRadius: 12,
                          ),
                        ]
                      : [],
                ),
                child: Text(
                  'WASTE: ${state.wastePile.length}',
                  style: TextStyle(
                    color: hasWaste
                        ? AppTheme.statusError
                        : AppTheme.textSecondary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: GameTableBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final availableHeight = constraints.maxHeight;
              final tableSize = (availableHeight * 0.40).clamp(180.0, 300.0);
              final screenWidth = MediaQuery.of(context).size.width;
              final cardW = screenWidth < 600 ? 55.0 : 70.0;
              final cardH = screenWidth < 600 ? 82.5 : 105.0;

              return Stack(
                children: [
                  Column(
                    children: [
                      SizedBox(
                        height: tableSize,
                        child: Center(
                          child: RoundTableWidget(
                            playerNames: state.players
                                .map((p) => p.name)
                                .toList(),
                            playerIds: state.players.map((p) => p.id).toList(),
                            activePlayerIndex: state.players.indexWhere(
                              (p) => p.id == state.currentPlayerId,
                            ),
                            cardCounts: state.players
                                .map((p) => p.cardCount)
                                .toList(),
                            latestEmojis: state.players
                                .map((p) => p.latestEmoji)
                                .toList(),
                            currentTrickPlays: const {},
                            size: tableSize * 0.90,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isYourTurn
                                    ? AppTheme.accentPrimary.withValues(
                                        alpha: 0.15,
                                      )
                                    : AppTheme.surfaceElevated,
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: isYourTurn
                                      ? AppTheme.accentPrimary
                                      : AppTheme.accentPrimary.withValues(
                                          alpha: 0.1,
                                        ),
                                  width: 1.5,
                                ),
                                boxShadow: isYourTurn
                                    ? [
                                        BoxShadow(
                                          color: AppTheme.neonGlow,
                                          blurRadius: 16,
                                        ),
                                      ]
                                    : [],
                              ),
                              child: Text(
                                bannerText.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 2.0,
                                  color: isYourTurn
                                      ? AppTheme.accentPrimary
                                      : AppTheme.textSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: math.min(availableHeight * 0.22, 160),
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

                                  // Detect Tochoo card (off-suit, not first trick)
                                  final isTochooCard =
                                      state.leadSuit != null &&
                                      !state.isFirstTrick &&
                                      t.card.suit != state.leadSuit;

                                  return AnimatedPositioned(
                                    duration: const Duration(milliseconds: 350),
                                    curve: Curves.easeOutCubic,
                                    left: 115 + offset,
                                    top: 20,
                                    child: Transform.rotate(
                                      angle: rotation,
                                      child: AnimatedScale(
                                        duration: const Duration(
                                          milliseconds: 350,
                                        ),
                                        scale: 1.0,
                                        child: AnimatedOpacity(
                                          opacity: 1.0,
                                          duration: const Duration(
                                            milliseconds: 300,
                                          ),
                                          curve: Curves.easeInCubic,
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                state.players
                                                    .firstWhere(
                                                      (p) => p.id == t.playerId,
                                                      orElse: () =>
                                                          state.players.first,
                                                    )
                                                    .name,
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  color: AppTheme.textSecondary,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              // Wrap tochoo cards with a
                                              // THULLA badge overlay
                                              Stack(
                                                clipBehavior: Clip.none,
                                                children: [
                                                  PlayingCardWidget(
                                                    card: t.card,
                                                    width: cardW,
                                                    height: cardH,
                                                  ),
                                                  if (isTochooCard)
                                                    Positioned(
                                                      top: -8,
                                                      right: -8,
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 6,
                                                              vertical: 2,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: AppTheme
                                                              .statusError,
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color: AppTheme
                                                                  .statusError
                                                                  .withValues(
                                                                    alpha: 0.5,
                                                                  ),
                                                              blurRadius: 6,
                                                            ),
                                                          ],
                                                        ),
                                                        child: const Text(
                                                          'THULLA',
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 8,
                                                            fontWeight:
                                                                FontWeight.w900,
                                                            letterSpacing: 0.5,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ],
                                          ),
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
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceElevated,
                            border: Border(
                              top: BorderSide(
                                color: AppTheme.accentPrimary.withValues(
                                  alpha: 0.3,
                                ),
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
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: 12.0,
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
                                              ),
                                            ]
                                          : [],
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: HandWidget(
                                      hand: bottomPlayer.hand,
                                      isFaceUp: !bottomPlayer.isBot,
                                      isInteractive: !bottomPlayer.isBot,
                                      isCardValid: (card) =>
                                          ThullaEngine.getMoveError(
                                            state,
                                            bottomPlayer.id,
                                            card,
                                          ) ==
                                          null,
                                      onCardTap: (card) async {
                                        if (widget.isOnline) {
                                          final user = ref
                                              .read(userProvider)
                                              .value;
                                          if (user == null ||
                                              user.uid != bottomPlayer.id) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
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

                                        if (error != null) {
                                          if (!context.mounted) return;
                                          ref
                                              .read(audioServiceProvider)
                                              .playError();
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(error),
                                              duration: const Duration(
                                                seconds: 2,
                                              ),
                                              backgroundColor:
                                                  AppTheme.statusError,
                                              behavior:
                                                  SnackBarBehavior.floating,
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (state.passToPlayerId != null && !widget.isOnline)
                    PassDeviceOverlay(
                      playerName: state.players
                          .firstWhere((p) => p.id == state.passToPlayerId)
                          .name,
                      onAcknowledge: () =>
                          ref.read(thullaProvider.notifier).acknowledgePass(),
                    ),
                  if (widget.isOnline)
                    ChatOverlay(messages: state.chatMessages),
                  // ── Trick-winner banner ──────────────────────────────────
                  Positioned(
                    top: 8,
                    left: 16,
                    right: 16,
                    child: TrickWinnerBanner(
                      winnerName: _bannerWinnerName,
                      isTochoo: _isTochooBanner,
                      visible: _showBanner,
                    ),
                  ),
                  if (_showTuingRabbit)
                    Positioned.fill(
                      child: RepaintBoundary(
                        child: TuingRabbitOverlay(
                          onComplete: () {
                            if (mounted) {
                              setState(() => _showTuingRabbit = false);
                            }
                          },
                        ),
                      ),
                    ),
                ],
              );
            },
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
}
