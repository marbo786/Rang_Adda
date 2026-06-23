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
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 16.0,
            ),
            itemCount: hand.length,
            itemBuilder: (context, index) {
              final card = hand[index];
              bool valid = isCardValid == null || isCardValid!(card);

              return Align(
                alignment: Alignment.bottomCenter,
                widthFactor: dynamicWidthFactor,
                child: GestureDetector(
                  onTap: valid
                      ? () {
                          HapticFeedback.lightImpact();
                          ref.read(audioServiceProvider).playCardFlip();
                          onCardTap(card);
                        }
                      : () {
                          HapticFeedback.vibrate();
                          ref.read(audioServiceProvider).playError();
                        },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    curve: Curves.easeOutCubic,
                    transform: Matrix4.identity()
                      // ignore: deprecated_member_use
                      ..scale(valid ? 1.0 : 0.92),
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
            },
          ),
        );
      },
    );
  }
}
