import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rang_adda/shared/models/card_model.dart';
import 'package:rang_adda/shared/services/audio_service.dart';
import 'package:rang_adda/shared/ui/playing_card_widget.dart';
import 'package:rang_adda/shared/ui/theme.dart';

class BluffHandWidget extends ConsumerStatefulWidget {
  final List<PlayingCard> hand;
  final Function(List<PlayingCard>) onPlayCards;
  final VoidCallback onPass;
  final bool canPass;
  final bool isFirstTurn;
  final bool isFaceUp;
  final bool isInteractive;

  const BluffHandWidget({
    super.key,
    required this.hand,
    required this.onPlayCards,
    required this.onPass,
    required this.canPass,
    required this.isFirstTurn,
    this.isFaceUp = true,
    this.isInteractive = true,
  });

  @override
  ConsumerState<BluffHandWidget> createState() => _BluffHandWidgetState();
}

class _BluffHandWidgetState extends ConsumerState<BluffHandWidget> {
  final Set<PlayingCard> _selectedCards = {};

  void _toggleCard(PlayingCard card) {
    ref.read(audioServiceProvider).playCardFlip();
    setState(() {
      if (_selectedCards.contains(card)) {
        _selectedCards.remove(card);
      } else {
        if (_selectedCards.length < 4) {
          _selectedCards.add(card);
        } else {
          ref.read(audioServiceProvider).playError();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("You can only select up to 4 cards.")),
          );
        }
      }
    });
  }

  @override
  void didUpdateWidget(BluffHandWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Remove cards from selection that are no longer in hand
    _selectedCards.removeWhere((card) => !widget.hand.contains(card));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Action Bar
        if (widget.isInteractive)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 8.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (widget.canPass)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Theme.of(context).primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: AppTheme.accentPrimary.withValues(alpha: 0.5),
                        ),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      ref.read(audioServiceProvider).playClick();
                      _selectedCards.clear();
                      widget.onPass();
                    },
                    child: const Text(
                      'PASS',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  )
                else
                  const SizedBox.shrink(),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _selectedCards.length >= (widget.isFirstTurn ? 2 : 1)
                        ? AppTheme.accentPrimary
                        : AppTheme.surfaceElevated,
                    foregroundColor:
                        _selectedCards.length >= (widget.isFirstTurn ? 2 : 1)
                        ? Colors.white
                        : Colors.white54,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation:
                        _selectedCards.length >= (widget.isFirstTurn ? 2 : 1)
                        ? 2
                        : 0,
                  ),
                  onPressed:
                      _selectedCards.length >= (widget.isFirstTurn ? 2 : 1)
                      ? () {
                          ref.read(audioServiceProvider).playClick();
                          widget.onPlayCards(_selectedCards.toList());
                          setState(() {
                            _selectedCards.clear();
                          });
                        }
                      : null,
                  child: Text(
                    'PLAY ${_selectedCards.length}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

        // Hand
        LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = MediaQuery.of(context).size.width;
            final isSmallScreen = screenWidth < 600;
            final cardW = isSmallScreen ? 55.0 : 70.0;
            final cardH = isSmallScreen ? 82.5 : 105.0;
            final fallbackHeight = isSmallScreen ? 110.0 : 140.0;
            final containerHeight =
                constraints.maxHeight.isFinite && constraints.maxHeight > 0
                ? constraints.maxHeight
                : fallbackHeight;

            return SizedBox(
              height: containerHeight,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 16.0,
                ),
                itemCount: widget.hand.length,
                itemBuilder: (context, index) {
                  final card = widget.hand[index];
                  final isSelected = _selectedCards.contains(card);

                  return Align(
                    alignment: Alignment.bottomCenter,
                    widthFactor: 0.6,
                    child: GestureDetector(
                      onTap: widget.isInteractive
                          ? () => _toggleCard(card)
                          : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 120),
                        curve: Curves.easeOutCubic,
                        transform: Matrix4.identity()
                          // ignore: deprecated_member_use
                          ..translate(0.0, isSelected ? -10.0 : 0.0)
                          // ignore: deprecated_member_use
                          ..scale(isSelected ? 1.05 : 1.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Theme.of(
                                      context,
                                    ).primaryColor.withValues(alpha: 0.6),
                                    blurRadius: 15,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : null,
                        ),
                        child: PlayingCardWidget(
                          card: card,
                          width: cardW,
                          height: cardH,
                          hasShadow: false,
                          isFaceUp: widget.isFaceUp,
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
