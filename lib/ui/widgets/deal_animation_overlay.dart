import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/player.dart';
import '../../services/audio_service.dart';

/// A one-time deal animation that plays when a local game starts.
/// Cards animate from center deck to each player's hand position.
/// Blocks user interaction until animation completes.
class DealAnimationOverlay extends ConsumerStatefulWidget {
  final List<Player> players;
  final int playerCount;
  final VoidCallback onAnimationComplete;

  const DealAnimationOverlay({
    super.key,
    required this.players,
    required this.playerCount,
    required this.onAnimationComplete,
  });

  @override
  ConsumerState<DealAnimationOverlay> createState() => _DealAnimationOverlayState();
}

class _DealAnimationOverlayState extends ConsumerState<DealAnimationOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _mainController;
  late final List<AnimationController> _cardControllers;

  // Constants for animation timing
  static const int totalDurationMs = 800;
  static const int cardDelayMs = 100;
  static const int cardDurationMs = 400;

  @override
  void initState() {
    super.initState();
    
    // Main controller to sequence the animation
    _mainController = AnimationController(
      duration: const Duration(milliseconds: totalDurationMs),
      vsync: this,
    );

    // Card controllers for staggered animations
    _cardControllers = List.generate(
      widget.players.fold<int>(0, (sum, p) => sum + p.hand.length),
      (index) => AnimationController(
        duration: const Duration(milliseconds: cardDurationMs),
        vsync: this,
      ),
    );

    _playDealAnimation();
  }

  Future<void> _playDealAnimation() async {
    final audioService = ref.read(audioServiceProvider);
    int cardIndex = 0;

    for (int playerIndex = 0; playerIndex < widget.players.length; playerIndex++) {
      final player = widget.players[playerIndex];
      final cardCountForPlayer = player.hand.length;

      for (int cardIdx = 0; cardIdx < cardCountForPlayer; cardIdx++) {
        final delay = playerIndex * cardDelayMs + (cardIdx * (cardDelayMs ~/ 2));
        final currentCardIndex = cardIndex; // Capture for closure
        
        Future.delayed(Duration(milliseconds: delay), () {
          if (mounted && currentCardIndex < _cardControllers.length) {
            audioService.playCardFlip();
            _cardControllers[currentCardIndex].forward();
          }
        });

        cardIndex++;
      }
    }

    // Wait for all animations to complete
    await Future.delayed(
      Duration(milliseconds: totalDurationMs + (cardDelayMs * widget.playerCount * 2)),
    );

    if (mounted) {
      widget.onAnimationComplete();
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    for (final controller in _cardControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Semi-transparent overlay to block interaction
        Container(
          color: Colors.black.withValues(alpha: 0.3),
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),

        // Animated cards
        ..._buildAnimatedCards(context),
      ],
    );
  }

  List<Widget> _buildAnimatedCards(BuildContext context) {
    final List<Widget> cards = [];
    final screenSize = MediaQuery.of(context).size;
    final centerX = screenSize.width / 2;
    final centerY = screenSize.height / 2;

    int cardIndex = 0;

    for (int playerIndex = 0; playerIndex < widget.players.length; playerIndex++) {
      final player = widget.players[playerIndex];
      final cardCountForPlayer = player.hand.length;

      // Calculate target position for this player
      final targetPos = _getPlayerTargetPosition(
        playerIndex,
        widget.playerCount,
        screenSize,
      );

      for (int cardIdx = 0; cardIdx < cardCountForPlayer; cardIdx++) {
        if (cardIndex >= _cardControllers.length) break;

        final currentCardIndex = cardIndex; // Capture for closure
        final animation = Tween<Offset>(
          begin: Offset(centerX, centerY),
          end: targetPos,
        ).animate(
          CurvedAnimation(curve: Curves.easeOut, parent: _cardControllers[currentCardIndex]),
        );

        cards.add(
          AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              final offset = animation.value;
              return Positioned(
                left: offset.dx - 30,
                top: offset.dy - 45,
                child: Opacity(
                  opacity: 1.0,
                  child: child!,
                ),
              );
            },
            child: _buildCardWidget(),
          ),
        );

        cardIndex++;
      }
    }

    return cards;
  }

  /// Build a simple card representation for animation
  Widget _buildCardWidget() {
    return Container(
      width: 60,
      height: 90,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.style,
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          size: 32,
        ),
      ),
    );
  }

  /// Calculate the target position for a player based on their index.
  /// Assumes players are arranged around a table:
  /// - Player 0 (bottom): center-bottom
  /// - Player 1 (top-left): top-left
  /// - Player 2 (top): top-center
  /// - Player 3 (top-right): top-right
  Offset _getPlayerTargetPosition(
    int playerIndex,
    int totalPlayers,
    Size screenSize,
  ) {
    const handAreaHeight = 120.0;
    const topAreaHeight = 120.0;
    const topAreaMargin = 20.0;

    switch (totalPlayers) {
      case 3:
        // 3-player layout: bottom, top-left, top-right
        if (playerIndex == 0) {
          // Bottom player
          return Offset(screenSize.width / 2, screenSize.height - handAreaHeight);
        } else if (playerIndex == 1) {
          // Top-left
          return Offset(screenSize.width / 4, topAreaMargin + topAreaHeight / 2);
        } else {
          // Top-right
          return Offset((screenSize.width * 3) / 4, topAreaMargin + topAreaHeight / 2);
        }

      case 4:
        // 4-player layout: bottom, top-left, top-center, top-right
        if (playerIndex == 0) {
          // Bottom player
          return Offset(screenSize.width / 2, screenSize.height - handAreaHeight);
        } else if (playerIndex == 1) {
          // Top-left
          return Offset(screenSize.width / 5, topAreaMargin + topAreaHeight / 2);
        } else if (playerIndex == 2) {
          // Top-center
          return Offset(screenSize.width / 2, topAreaMargin + topAreaHeight / 2);
        } else {
          // Top-right
          return Offset((screenSize.width * 4) / 5, topAreaMargin + topAreaHeight / 2);
        }

      default:
        // Fallback for other player counts
        return Offset(screenSize.width / 2, screenSize.height / 2);
    }
  }
}
