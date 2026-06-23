import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rang_adda/shared/models/card_model.dart';
import 'package:rang_adda/shared/services/audio_service.dart';
import 'package:rang_adda/shared/ui/playing_card_widget.dart';

class HandWidget extends ConsumerWidget {
  final List<PlayingCard> hand;
  final Function(PlayingCard) onCardTap;
  final bool Function(PlayingCard)? isCardValid;

  const HandWidget({
    super.key,
    required this.hand,
    required this.onCardTap,
    this.isCardValid,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final cardW = isSmallScreen ? 55.0 : 70.0;
    final cardH = isSmallScreen ? 82.5 : 105.0;
    final containerHeight = isSmallScreen ? 110.0 : 140.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth =
            constraints.maxWidth - 48.0; // 24.0 padding on each side

        // Calculate the maximum widthFactor that allows all cards to fit
        double dynamicWidthFactor = 0.6;
        if (hand.length > 1) {
          final requiredWidth = cardW + (cardW * 0.6 * (hand.length - 1));
          if (requiredWidth > availableWidth) {
            dynamicWidthFactor =
                (availableWidth - cardW) / (cardW * (hand.length - 1));
            if (dynamicWidthFactor < 0.2) {
              dynamicWidthFactor = 0.2; // Don't let them overlap entirely
            }
          }
        }

        return SizedBox(
          height: containerHeight,
          width: constraints.maxWidth,
          child: Stack(
            clipBehavior: Clip.none,
            children: List.generate(hand.length, (index) {
              final card = hand[index];
              bool valid = isCardValid == null || isCardValid!(card);

              // Calculate horizontal position
              // Center the hand if it doesn't take up the full width
              double totalRequiredWidth =
                  cardW + (cardW * dynamicWidthFactor * (hand.length - 1));
              double startOffset =
                  (constraints.maxWidth - totalRequiredWidth) / 2;
              if (startOffset < 24.0) startOffset = 24.0;

              double leftPosition =
                  startOffset + (index * cardW * dynamicWidthFactor);

              return AnimatedPositioned(
                key: ValueKey(card),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                left: leftPosition,
                bottom: 16.0,
                child: GestureDetector(
                  onTap: valid
                      ? () {
                          // HapticFeedback.lightImpact();
                          ref.read(audioServiceProvider).playCardFlip();
                          onCardTap(card);
                        }
                      : () {
                          // HapticFeedback.vibrate();
                          ref.read(audioServiceProvider).playError();
                        },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    curve: Curves.easeOutCubic,
                    transform: Matrix4.identity()..scale(valid ? 1.0 : 0.92),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: valid
                          ? [
                              BoxShadow(
                                color: Theme.of(
                                  context,
                                ).primaryColor.withValues(alpha: 0.4),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: Opacity(
                      opacity: valid ? 1.0 : 0.5,
                      child: PlayingCardWidget(
                        card: card,
                        width: cardW,
                        height: cardH,
                        hasShadow: false,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
