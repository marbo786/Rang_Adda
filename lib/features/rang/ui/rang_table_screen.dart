import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rang_adda/shared/models/card_model.dart';
import 'package:rang_adda/shared/models/game_state.dart';
import 'package:rang_adda/shared/models/player.dart';
import 'package:rang_adda/features/rang/engine/rang_game_state.dart';
import 'package:rang_adda/features/rang/engine/rang_engine.dart';
import 'package:rang_adda/features/rang/state/rang_provider.dart';
import 'package:rang_adda/shared/services/audio_service.dart';
import 'package:rang_adda/shared/ui/game_table_background.dart';
import 'package:rang_adda/shared/ui/hand_widget.dart';
import 'package:rang_adda/shared/ui/playing_card_widget.dart';

import 'package:rang_adda/shared/ui/pass_device_overlay.dart';
import 'package:rang_adda/shared/ui/game_over_overlay.dart';
import 'package:rang_adda/shared/ui/theme.dart';
import 'package:rang_adda/shared/ui/round_table_widget.dart';
import 'dart:math' as math;

class RangTableScreen extends ConsumerStatefulWidget {
  final List<String>? playerNames;
  const RangTableScreen({super.key, this.playerNames});

  @override
  ConsumerState<RangTableScreen> createState() => _RangTableScreenState();
}

class _RangTableScreenState extends ConsumerState<RangTableScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final names = widget.playerNames ?? ['Alice', 'Bob', 'Charlie', 'Diana'];
      ref.read(rangProvider.notifier).startGame(names);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(rangProvider);

    if (state == null) {
      return const Scaffold(
        backgroundColor: AppTheme.backgroundPrimary,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.accentPrimary),
        ),
      );
    }

    // Handle Game Over Screen
    if (state.status == GameStatus.finished) {
      return Scaffold(
        body: RangGameOverOverlay(
          winningTeam: state.winningTeam ?? 'A',
          teamASars: state.teamASars,
          teamBSars: state.teamBSars,
          kot: state.kot,
          bavney: state.bavney,
          players: state.players,
          onPlayAgain: () {
            ref.read(audioServiceProvider).playClick();
            final names =
                widget.playerNames ?? ['Alice', 'Bob', 'Charlie', 'Diana'];
            ref.read(rangProvider.notifier).startGame(names);
          },
          onBackToLobby: () {
            ref.read(audioServiceProvider).playClick();
            context.go('/');
          },
        ),
      );
    }

    // Determine bottom player (active player holding device)
    final bottomPlayer = state.players.firstWhere(
      (p) => p.id == state.currentPlayerId,
      orElse: () => state.players.first,
    );

    final bottomIndex = state.players.indexOf(bottomPlayer);

    final isTrumpSelection = state.phase == RangPhase.trumpSelection;
    final isTrumpCaller = bottomPlayer.id == state.trumpCallerId;
    final isYourTurn =
        state.currentPlayerId == bottomPlayer.id && !isTrumpSelection;
    final hasHeap = state.heap.isNotEmpty;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: AppBar(
        title: Text(
          'RANG',
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
          // Trump suit badge
          if (state.trumpSuit != null)
            Center(
              child: Container(
                margin: const EdgeInsets.only(right: 8.0),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.accentPrimary.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accentPrimary.withValues(alpha: 0.2),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'TRUMP: ',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textSecondary,
                        letterSpacing: 1.0,
                      ),
                    ),
                    Text(
                      _getSuitSymbol(state.trumpSuit!),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _getSuitColor(state.trumpSuit!),
                        shadows: [
                          Shadow(
                            color: _getSuitColor(
                              state.trumpSuit!,
                            ).withValues(alpha: 0.5),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Sars Score Readout
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
                  border: Border.all(color: AppTheme.textDisabled, width: 1.5),
                ),
                child: Text(
                  'A: ${state.teamASars}  B: ${state.teamBSars}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    fontSize: 12,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: GameTableBackground(
        child: SafeArea(
          child: Stack(
            children: [
              // Round Table
              Positioned(
                top: 40,
                left: 0,
                right: 0,
                child: Center(
                  child: RoundTableWidget(
                    playerNames: state.players.map((p) => p.name).toList(),
                    playerIds: state.players.map((p) => p.id).toList(),
                    activePlayerIndex: state.players.indexWhere(
                      (p) => p.id == state.currentPlayerId,
                    ),
                    cardCounts: state.players
                        .map((p) => p.hand.length)
                        .toList(),
                    trumpSuit: state.trumpSuit != null
                        ? _getSuitSymbol(state.trumpSuit!)
                        : null,
                    currentTrickPlays: Map.fromEntries(
                      state.currentTrick.map(
                        (play) => MapEntry(play.playerId, play.card),
                      ),
                    ),
                    size: math.min(
                      MediaQuery.of(context).size.width * 0.75,
                      300,
                    ),
                  ),
                ),
              ),

              // 4. Center Trick Cards & Heap
              Positioned(
                top: 180,
                bottom: 180,
                left: 80,
                right: 80,
                child: Center(
                  child: SizedBox(
                    width: 220,
                    height: 220,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Heap counter in center
                        if (hasHeap)
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceElevated,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppTheme.statusError.withValues(
                                    alpha: 0.5,
                                  ),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.statusError.withValues(
                                      alpha: 0.2,
                                    ),
                                    blurRadius: 16,
                                  ),
                                ],
                              ),
                              child: Text(
                                'HEAP: ${state.heap.length}',
                                style: const TextStyle(
                                  color: AppTheme.statusError,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                          ),

                        // Played cards
                        ...state.currentTrick.map((trickPlay) {
                          final slot = _getPlayerSlot(
                            trickPlay.playerId,
                            bottomIndex,
                            state.players,
                          );
                          double? topVal;
                          double? bottomVal;
                          double? leftVal;
                          double? rightVal;

                          switch (slot) {
                            case _TableSlot.bottom:
                              bottomVal = 25;
                              leftVal = 80;
                              rightVal = 80;
                              break;
                            case _TableSlot.top:
                              topVal = 25;
                              leftVal = 80;
                              rightVal = 80;
                              break;
                            case _TableSlot.left:
                              leftVal = 25;
                              topVal = 65;
                              bottomVal = 65;
                              break;
                            case _TableSlot.right:
                              rightVal = 25;
                              topVal = 65;
                              bottomVal = 65;
                              break;
                          }

                          return Positioned(
                            top: topVal,
                            bottom: bottomVal,
                            left: leftVal,
                            right: rightVal,
                            child: Center(
                              child: PlayingCardWidget(
                                card: trickPlay.card,
                                width: 60,
                                height: 90,
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),

              // 5 & 6. Turn Banner and Bottom Area
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Turn / Phase Status Banner
                    Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isYourTurn || (isTrumpSelection && isTrumpCaller)
                              ? AppTheme.accentPrimary.withValues(alpha: 0.15)
                              : AppTheme.surfaceElevated,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color:
                                isYourTurn ||
                                    (isTrumpSelection && isTrumpCaller)
                                ? AppTheme.accentPrimary
                                : AppTheme.accentPrimary.withValues(alpha: 0.1),
                            width: 1.5,
                          ),
                          boxShadow:
                              isYourTurn || (isTrumpSelection && isTrumpCaller)
                              ? [
                                  BoxShadow(
                                    color: AppTheme.neonGlow,
                                    blurRadius: 16,
                                  ),
                                ]
                              : [],
                        ),
                        child: Text(
                          _getBannerText(state, bottomPlayer).toUpperCase(),
                          style: TextStyle(
                            color:
                                isYourTurn ||
                                    (isTrumpSelection && isTrumpCaller)
                                ? AppTheme.accentPrimary
                                : AppTheme.textSecondary,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            letterSpacing: 2.0,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Bottom Area: Suit Picker (Trump Selection) or HandWidget
                    Container(
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
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 16.0,
                                bottom: 4.0,
                              ),
                              child: Text(
                                (isYourTurn ||
                                        (isTrumpSelection && isTrumpCaller))
                                    ? 'YOUR TURN'
                                    : bottomPlayer.name.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 3.0,
                                  color:
                                      (isYourTurn ||
                                          (isTrumpSelection && isTrumpCaller))
                                      ? AppTheme.accentPrimary
                                      : AppTheme.textSecondary,
                                  shadows:
                                      (isYourTurn ||
                                          (isTrumpSelection && isTrumpCaller))
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
                            if (isTrumpSelection && isTrumpCaller)
                              _buildSuitPicker(context, bottomPlayer.id)
                            else
                              HandWidget(
                                hand: bottomPlayer.hand,
                                onCardTap: (card) async {
                                  final error = await ref
                                      .read(rangProvider.notifier)
                                      .playCard(bottomPlayer.id, card);
                                  if (error != null && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(error),
                                        duration: const Duration(seconds: 2),
                                        backgroundColor: AppTheme.statusError,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                },
                                isCardValid: (card) {
                                  if (state.phase != RangPhase.trickPlay) {
                                    return false;
                                  }
                                  if (state.currentPlayerId !=
                                      bottomPlayer.id) {
                                    return false;
                                  }
                                  if (state.passToPlayerId != null) {
                                    return false;
                                  }
                                  return RangEngine.getMoveError(
                                        state,
                                        bottomPlayer.id,
                                        card,
                                      ) ==
                                      null;
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 7. Pass Device Overlay
              if (state.passToPlayerId != null)
                Positioned.fill(
                  child: PassDeviceOverlay(
                    playerName: state.players
                        .firstWhere((p) => p.id == state.passToPlayerId)
                        .name,
                    onAcknowledge: () {
                      ref.read(rangProvider.notifier).acknowledgePass();
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuitPicker(BuildContext context, String callerId) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'CHOOSE TRUMP SUIT',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppTheme.textSecondary,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: Suit.values.map((suit) {
              final isRed = suit == Suit.hearts || suit == Suit.diamonds;
              final color = isRed ? Colors.redAccent : Colors.white;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  ref.read(audioServiceProvider).playClick();
                  ref.read(rangProvider.notifier).declareTrump(callerId, suit);
                },
                child: Container(
                  width: 75,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundPrimary.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: color.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.2),
                        blurRadius: 16,
                        spreadRadius: -4,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _getSuitSymbol(suit),
                      style: TextStyle(
                        fontSize: 48,
                        color: color,
                        shadows: [
                          Shadow(
                            color: color.withValues(alpha: 0.5),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  String _getSuitSymbol(Suit suit) {
    switch (suit) {
      case Suit.hearts:
        return '♥';
      case Suit.diamonds:
        return '♦';
      case Suit.clubs:
        return '♣';
      case Suit.spades:
        return '♠';
    }
  }

  Color _getSuitColor(Suit suit) {
    switch (suit) {
      case Suit.hearts:
      case Suit.diamonds:
        return Colors.redAccent;
      case Suit.clubs:
      case Suit.spades:
        return Colors.white;
    }
  }

  _TableSlot _getPlayerSlot(
    String playerId,
    int bottomIndex,
    List<Player> players,
  ) {
    if (playerId == players[bottomIndex].id) return _TableSlot.bottom;
    if (playerId == players[(bottomIndex + 1) % 4].id) return _TableSlot.left;
    if (playerId == players[(bottomIndex + 2) % 4].id) return _TableSlot.top;
    if (playerId == players[(bottomIndex + 3) % 4].id) return _TableSlot.right;
    return _TableSlot.bottom;
  }

  String _getBannerText(RangGameState state, Player bottomPlayer) {
    if (state.phase == RangPhase.trumpSelection) {
      if (bottomPlayer.id == state.trumpCallerId) {
        return "Your Turn! Declare Trump Suit.";
      } else {
        final caller = state.players.firstWhere(
          (p) => p.id == state.trumpCallerId,
        );
        return "Waiting for ${caller.name} to declare Trump...";
      }
    } else {
      if (state.currentPlayerId == bottomPlayer.id) {
        if (state.leadSuit != null) {
          return "Your Turn! Play a ${state.leadSuit!.name}.";
        } else {
          return "Your Turn! Lead the trick.";
        }
      } else {
        final activePlayer = state.players.firstWhere(
          (p) => p.id == state.currentPlayerId,
        );
        return "Waiting for ${activePlayer.name}...";
      }
    }
  }
}

enum _TableSlot { bottom, left, top, right }

class RangGameOverOverlay extends StatefulWidget {
  final String winningTeam;
  final int teamASars;
  final int teamBSars;
  final bool kot;
  final bool bavney;
  final List<Player> players;
  final VoidCallback onPlayAgain;
  final VoidCallback onBackToLobby;

  const RangGameOverOverlay({
    super.key,
    required this.winningTeam,
    required this.teamASars,
    required this.teamBSars,
    required this.kot,
    required this.bavney,
    required this.players,
    required this.onPlayAgain,
    required this.onBackToLobby,
  });

  @override
  State<RangGameOverOverlay> createState() => _RangGameOverOverlayState();
}

class _RangGameOverOverlayState extends State<RangGameOverOverlay>
    with TickerProviderStateMixin {
  late AnimationController _confettiController;
  late AnimationController _titleController;
  late AnimationController _buttonsController;

  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..forward();

    _titleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();

    _buttonsController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward(from: 0.3);
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _titleController.dispose();
    _buttonsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String winningMembers = '';
    if (widget.players.length == 4) {
      if (widget.winningTeam == 'A') {
        winningMembers =
            '${widget.players[0].name} & ${widget.players[2].name}';
      } else {
        winningMembers =
            '${widget.players[1].name} & ${widget.players[3].name}';
      }
    }

    final winningSars = widget.winningTeam == 'A'
        ? widget.teamASars
        : widget.teamBSars;
    final losingSars = widget.winningTeam == 'A'
        ? widget.teamBSars
        : widget.teamASars;

    return Stack(
      children: [
        ConfettiWidget(controller: _confettiController),
        Container(color: AppTheme.backgroundPrimary.withValues(alpha: 0.85)),
        Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ScaleTransition(
                    scale: Tween<double>(begin: 0.5, end: 1.0).animate(
                      CurvedAnimation(
                        parent: _titleController,
                        curve: Curves.elasticOut,
                      ),
                    ),
                    child: FadeTransition(
                      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                        CurvedAnimation(
                          parent: _titleController,
                          curve: Curves.easeInOut,
                        ),
                      ),
                      child: Column(
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) {
                              return LinearGradient(
                                colors: [
                                  AppTheme.statusSuccess,
                                  AppTheme.accentPrimary,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ).createShader(bounds);
                            },
                            child: const Icon(
                              Icons.emoji_events_rounded,
                              size: 100,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ShaderMask(
                            shaderCallback: (bounds) {
                              return LinearGradient(
                                colors: [
                                  AppTheme.statusSuccess,
                                  AppTheme.accentPrimary,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ).createShader(bounds);
                            },
                            child: Text(
                              'TEAM ${widget.winningTeam}',
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 2.0,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            winningMembers,
                            style: const TextStyle(
                              fontSize: 18,
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.0,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'WINS THE HAND!',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.0,
                              color: AppTheme.statusSuccess,
                              shadows: [
                                Shadow(
                                  color: AppTheme.statusSuccess.withValues(
                                    alpha: 0.5,
                                  ),
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 24,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceElevated,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: AppTheme.accentPrimary.withValues(
                                  alpha: 0.3,
                                ),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.accentPrimary.withValues(
                                    alpha: 0.15,
                                  ),
                                  blurRadius: 24,
                                  spreadRadius: -4,
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  'FINAL SCORE',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.textSecondary,
                                    letterSpacing: 2.0,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  '$winningSars Sars  vs  $losingSars Sars',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.textPrimary,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          if (widget.kot || widget.bavney)
                            Wrap(
                              spacing: 16,
                              children: [
                                if (widget.kot)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.orangeAccent.withValues(
                                        alpha: 0.1,
                                      ),
                                      border: Border.all(
                                        color: Colors.orangeAccent.withValues(
                                          alpha: 0.5,
                                        ),
                                        width: 1.5,
                                      ),
                                      borderRadius: BorderRadius.circular(24),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.orangeAccent.withValues(
                                            alpha: 0.2,
                                          ),
                                          blurRadius: 16,
                                          spreadRadius: -4,
                                        ),
                                      ],
                                    ),
                                    child: const Text(
                                      '🔥 KOT',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 18,
                                        color: Colors.orangeAccent,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                  ),
                                if (widget.bavney)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withValues(
                                        alpha: 0.1,
                                      ),
                                      border: Border.all(
                                        color: Colors.amber.withValues(
                                          alpha: 0.5,
                                        ),
                                        width: 1.5,
                                      ),
                                      borderRadius: BorderRadius.circular(24),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.amber.withValues(
                                            alpha: 0.2,
                                          ),
                                          blurRadius: 16,
                                          spreadRadius: -4,
                                        ),
                                      ],
                                    ),
                                    child: const Text(
                                      '👑 BAVNEY',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 18,
                                        color: Colors.amber,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                  FadeTransition(
                    opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                      CurvedAnimation(
                        parent: _buttonsController,
                        curve: Curves.easeInOut,
                      ),
                    ),
                    child: SlideTransition(
                      position:
                          Tween<Offset>(
                            begin: const Offset(0, 0.3),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: _buttonsController,
                              curve: Curves.easeOutCubic,
                            ),
                          ),
                      child: Column(
                        children: [
                          SizedBox(
                            width: 280,
                            height: 56,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.statusSuccess,
                                foregroundColor: AppTheme.backgroundPrimary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              onPressed: widget.onPlayAgain,
                              child: const Text(
                                'PLAY AGAIN',
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
                            width: 280,
                            height: 56,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.statusSuccess,
                                side: const BorderSide(
                                  color: AppTheme.statusSuccess,
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: widget.onBackToLobby,
                              child: const Text(
                                'BACK TO LOBBY',
                                style: TextStyle(
                                  fontSize: 18,
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
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
