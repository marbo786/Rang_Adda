import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/card_model.dart';
import '../../core/bluff/bluff_game_state.dart';
import '../../state/bluff_provider.dart';
import '../widgets/bluff_hand_widget.dart';
import '../widgets/pass_device_overlay.dart';

class BluffTableScreen extends ConsumerStatefulWidget {
  const BluffTableScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<BluffTableScreen> createState() => _BluffTableScreenState();
}

class _BluffTableScreenState extends ConsumerState<BluffTableScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Initialize local game with 4 players for now
      ref.read(bluffProvider.notifier).startGame(
        ['p1', 'p2', 'p3', 'p4'],
        ['Alice', 'Bob', 'Charlie', 'Diana']
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bluffProvider);
    if (state.players.isEmpty) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final bottomPlayer = state.players.firstWhere((p) => p.id == state.currentPlayerId, orElse: () => state.players.first);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('BLUFF', style: TextStyle(letterSpacing: 4.0)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/'),
        ),
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
                    children: state.players.where((p) => p.id != bottomPlayer.id).map((p) {
                      bool isActive = p.id == state.currentPlayerId;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                        decoration: BoxDecoration(
                           color: isActive ? Theme.of(context).colorScheme.surface : Colors.transparent,
                           borderRadius: BorderRadius.circular(16),
                           border: Border.all(color: isActive ? Theme.of(context).primaryColor : Colors.white.withOpacity(0.1), width: 1.5),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              p.name.toUpperCase(), 
                              style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1.0, color: Colors.white)
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.style, size: 16, color: Colors.white54),
                                const SizedBox(width: 6),
                                Text('${p.hand.length}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              ],
                            )
                          ],
                        ),
                      );
                    }).toList(),
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
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                             color: Theme.of(context).primaryColor.withOpacity(0.1),
                             borderRadius: BorderRadius.circular(30),
                             border: Border.all(color: Theme.of(context).primaryColor),
                          ),
                          child: Text(
                            'CHOOSE YOUR BLUFF!', 
                            style: TextStyle(
                              fontSize: 16, 
                              fontWeight: FontWeight.w800, 
                              letterSpacing: 2.0,
                              color: Theme.of(context).primaryColor,
                            )
                          ),
                        ),
                        const SizedBox(height: 40),
                        
                        // Center Pile visualization
                        if (state.centerPile.isNotEmpty)
                           Container(
                             padding: const EdgeInsets.all(24),
                             decoration: BoxDecoration(
                               shape: BoxShape.circle,
                               color: Theme.of(context).colorScheme.surface,
                               border: Border.all(color: Colors.white.withOpacity(0.1)),
                             ),
                             child: Column(
                               mainAxisSize: MainAxisSize.min,
                               children: [
                                 Text('${state.centerPile.length}', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white)),
                                 const Text('CARDS IN PILE', style: TextStyle(fontSize: 12, color: Colors.white54, letterSpacing: 1.5)),
                               ]
                             )
                           )
                        else
                           const Text('PILE IS EMPTY', style: TextStyle(color: Colors.white24, letterSpacing: 2.0, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                
                // Bottom Player Hand
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0, bottom: 4.0),
                          child: Text(
                            "${bottomPlayer.name.toUpperCase()}'S TURN", 
                            style: TextStyle(
                              fontSize: 16, 
                              fontWeight: FontWeight.w800, 
                              letterSpacing: 2.0,
                              color: Theme.of(context).primaryColor,
                            )
                          ),
                        ),
                        BluffHandWidget(
                          hand: bottomPlayer.hand,
                          isFirstTurn: state.centerPile.isEmpty,
                          canPass: true,
                          onPass: () async {
                            String? error = await ref.read(bluffProvider.notifier).passTurn(bottomPlayer.id);
                            if (error != null && mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: Theme.of(context).colorScheme.error));
                            }
                          },
                          onPlayCards: (cards) {
                            _showRankSelectorDialog(context, cards, bottomPlayer.id);
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
                playerName: state.players.firstWhere((p) => p.id == state.passToPlayerId).name,
                onAcknowledge: () => ref.read(bluffProvider.notifier).acknowledgePass(),
              ),

            // Challenge Bluff Overlay
            if (state.passToPlayerId == null && state.lastPlayerId != null && state.lastPlayedCards.isNotEmpty && state.status == BluffGameStatus.playing)
              _buildChallengeOverlay(context, state),

            // Resolving Result Overlay
            if (state.resolvingBluffMessage != null)
              _buildResultOverlay(context, state.resolvingBluffMessage!),
          ],
        ),
      ),
    );
  }

  void _showRankSelectorDialog(BuildContext context, List<PlayingCard> cards, String playerId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Dialog(
            backgroundColor: Theme.of(context).colorScheme.surface.withOpacity(0.9),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.white.withOpacity(0.08)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('WHAT RANK ARE YOU CLAIMING?', 
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0),
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
                          Navigator.of(dialogContext).pop();
                          String? error = await ref.read(bluffProvider.notifier).playCard(playerId, cards, rank);
                          if (error != null && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: Theme.of(context).colorScheme.error));
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withOpacity(0.1),
                            border: Border.all(color: Theme.of(context).primaryColor),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(rank.name.toUpperCase(), style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
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
    String pName = state.players.firstWhere((p) => p.id == state.lastPlayerId).name;
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Container(
        color: Colors.black.withOpacity(0.4),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.warning_amber_rounded, size: 48, color: Colors.orangeAccent),
                const SizedBox(height: 24),
                Text(
                  '$pName claims they played:',
                  style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  '${state.lastPlayedCards.length} ${state.lastClaimedRank?.name.toUpperCase()}S',
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1.5),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      ref.read(bluffProvider.notifier).callBluff(state.currentPlayerId);
                    },
                    child: const Text('CALL BLUFF!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).primaryColor,
                      side: BorderSide(color: Theme.of(context).primaryColor.withOpacity(0.5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      ref.read(bluffProvider.notifier).declineChallenge();
                    },
                    child: const Text('ACCEPT & PLAY', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
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
        color: Colors.black.withOpacity(0.4),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withOpacity(0.95),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.3), width: 1.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.gavel, size: 48, color: Colors.white),
                const SizedBox(height: 24),
                Text(
                  message,
                  style: const TextStyle(color: Colors.white, fontSize: 18, height: 1.5),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      ref.read(bluffProvider.notifier).acknowledgeResolvingMessage();
                    },
                    child: const Text('CONTINUE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
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
