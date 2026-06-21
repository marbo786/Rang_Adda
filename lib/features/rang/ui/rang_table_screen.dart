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
import 'package:rang_adda/shared/ui/opponent_chip.dart';
import 'package:rang_adda/shared/ui/hand_widget.dart';
import 'package:rang_adda/shared/ui/playing_card_widget.dart';
import 'package:rang_adda/shared/ui/deal_animation_overlay.dart';
import 'package:rang_adda/shared/ui/pass_device_overlay.dart';
import 'package:rang_adda/shared/ui/game_over_overlay.dart'; // For ConfettiWidget
import 'package:rang_adda/shared/ui/theme.dart';

class RangTableScreen extends ConsumerStatefulWidget {
  final List<String>? playerNames;
  const RangTableScreen({super.key, this.playerNames});

  @override
  ConsumerState<RangTableScreen> createState() => _RangTableScreenState();
}

class _RangTableScreenState extends ConsumerState<RangTableScreen> {
  bool _dealAnimationComplete = false; // Track if deal animation has played
  String? _lastGameStartTick; // Track the last game start to detect new games

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
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Reset deal animation when game ID changes (e.g. new game)
    if (_lastGameStartTick != state.gameId) {
      _lastGameStartTick = state.gameId;
      _dealAnimationComplete = false;
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
            final names = widget.playerNames ?? ['Alice', 'Bob', 'Charlie', 'Diana'];
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
    final leftPlayer = state.players[(bottomIndex + 1) % 4];
    final topPlayer = state.players[(bottomIndex + 2) % 4];
    final rightPlayer = state.players[(bottomIndex + 3) % 4];

    final isTrumpSelection = state.phase == RangPhase.trumpSelection;
    final isTrumpCaller = bottomPlayer.id == state.trumpCallerId;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('RANG', style: TextStyle(letterSpacing: 4.0)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'TRUMP: ',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      _getSuitSymbol(state.trumpSuit!),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _getSuitColor(state.trumpSuit!),
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
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                child: Text(
                  'A: ${state.teamASars} — B: ${state.teamBSars}',
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
      body: GameTableBackground(
        child: SafeArea(
          child: Stack(
            children: [
              // 1. Top Opponent (Partner)
              Positioned(
                top: 70,
                left: 0,
                right: 0,
                child: Center(
                  child: OpponentChip(
                    playerName: topPlayer.name,
                    cardCount: topPlayer.hand.length,
                    isActive: topPlayer.id == state.currentPlayerId,
                  ),
                ),
              ),

              // 2. Left Opponent
              Positioned(
                left: 12,
                top: 160,
                bottom: 160,
                child: Center(
                  child: OpponentChip(
                    playerName: leftPlayer.name,
                    cardCount: leftPlayer.hand.length,
                    isActive: leftPlayer.id == state.currentPlayerId,
                  ),
                ),
              ),

              // 3. Right Opponent
              Positioned(
                right: 12,
                top: 160,
                bottom: 160,
                child: Center(
                  child: OpponentChip(
                    playerName: rightPlayer.name,
                    cardCount: rightPlayer.hand.length,
                    isActive: rightPlayer.id == state.currentPlayerId,
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
                        if (state.heap.isNotEmpty)
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white24, width: 1),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black54,
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                  )
                                ],
                              ),
                              child: Text(
                                'HEAP: ${state.heap.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),

                        // Played cards
                        ...state.currentTrick.map((trickPlay) {
                          final slot = _getPlayerSlot(trickPlay.playerId, bottomIndex, state.players);
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

              // 5. Turn / Phase Status Banner
              Positioned(
                bottom: 160,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Text(
                      _getBannerText(state, bottomPlayer),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),

              // 6. Bottom Area: Suit Picker (Trump Selection) or HandWidget
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: isTrumpSelection && isTrumpCaller
                    ? _buildSuitPicker(context, bottomPlayer.id)
                    : HandWidget(
                        hand: bottomPlayer.hand,
                        onCardTap: (card) async {
                          final error = await ref.read(rangProvider.notifier).playCard(bottomPlayer.id, card);
                          if (error != null && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(error),
                                duration: const Duration(seconds: 2),
                                backgroundColor: Theme.of(context).colorScheme.error,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        isCardValid: (card) {
                          if (state.phase != RangPhase.trickPlay) return false;
                          if (state.currentPlayerId != bottomPlayer.id) return false;
                          if (state.passToPlayerId != null) return false;
                          return RangEngine.getMoveError(state, bottomPlayer.id, card) == null;
                        },
                      ),
              ),

              // 7. Pass Device Overlay
              if (_dealAnimationComplete && state.passToPlayerId != null)
                Positioned.fill(
                  child: PassDeviceOverlay(
                    playerName: state.players.firstWhere((p) => p.id == state.passToPlayerId).name,
                    onAcknowledge: () {
                      ref.read(rangProvider.notifier).acknowledgePass();
                    },
                  ),
                ),

              // 8. Deal Animation Overlay
              if (!_dealAnimationComplete)
                Positioned.fill(
                  child: DealAnimationOverlay(
                    players: state.players,
                    playerCount: 4,
                    onAnimationComplete: () {
                      setState(() {
                        _dealAnimationComplete = true;
                      });
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
              color: Colors.white70,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 12),
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
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white24, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _getSuitSymbol(suit),
                      style: TextStyle(
                        fontSize: 48,
                        color: color,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _getSuitSymbol(Suit suit) {
    switch (suit) {
      case Suit.hearts: return '♥';
      case Suit.diamonds: return '♦';
      case Suit.clubs: return '♣';
      case Suit.spades: return '♠';
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

  _TableSlot _getPlayerSlot(String playerId, int bottomIndex, List<Player> players) {
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
        final caller = state.players.firstWhere((p) => p.id == state.trumpCallerId);
        return "Waiting for ${caller.name} to declare Trump...";
      }
    } else {
      if (state.currentPlayerId == bottomPlayer.id) {
        if (state.leadSuit != null) {
          return "Your Turn! Play a ${state.leadSuit!.name.toUpperCase()}.";
        } else {
          return "Your Turn! Lead the trick.";
        }
      } else {
        final activePlayer = state.players.firstWhere((p) => p.id == state.currentPlayerId);
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
        winningMembers = '${widget.players[0].name} & ${widget.players[2].name}';
      } else {
        winningMembers = '${widget.players[1].name} & ${widget.players[3].name}';
      }
    }

    final winningSars = widget.winningTeam == 'A' ? widget.teamASars : widget.teamBSars;
    final losingSars = widget.winningTeam == 'A' ? widget.teamBSars : widget.teamASars;

    return Stack(
      children: [
        ConfettiWidget(controller: _confettiController),
        Container(
          color: Colors.black.withValues(alpha: 0.75),
        ),
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
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'WINS THE HAND!',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                              color: AppTheme.statusSuccess,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  'FINAL SCORE',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white54,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '$winningSars Sars  vs  $losingSars Sars',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          if (widget.kot || widget.bavney)
                            Wrap(
                              spacing: 12,
                              children: [
                                if (widget.kot)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Colors.orangeAccent, Colors.redAccent],
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.redAccent.withValues(alpha: 0.4),
                                          blurRadius: 8,
                                          spreadRadius: 1,
                                        )
                                      ],
                                    ),
                                    child: const Text(
                                      '🔥 KOT',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 16,
                                        color: Colors.white,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                  ),
                                if (widget.bavney)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Colors.amber, Colors.orange],
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.amber.withValues(alpha: 0.4),
                                          blurRadius: 8,
                                          spreadRadius: 1,
                                        )
                                      ],
                                    ),
                                    child: const Text(
                                      '👑 BAVNEY',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 16,
                                        color: Colors.white,
                                        letterSpacing: 1.0,
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
                      position: Tween<Offset>(
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
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 8,
                                shadowColor: AppTheme.statusSuccess.withValues(alpha: 0.5),
                              ),
                              onPressed: widget.onPlayAgain,
                              child: const Text(
                                'PLAY AGAIN',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
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
                                side: BorderSide(
                                  color: AppTheme.statusSuccess,
                                  width: 2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: widget.onBackToLobby,
                              child: const Text(
                                'BACK TO LOBBY',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
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
