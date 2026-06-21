import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/card_model.dart';
import '../../services/audio_service.dart';
import 'playing_card_widget.dart';

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

    return SizedBox(
      height: containerHeight, // Enough height for the lift and shadow
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        itemCount: hand.length,
        itemBuilder: (context, index) {
          final card = hand[index];
          bool valid = isCardValid == null || isCardValid!(card);

          return Align(
            alignment: Alignment.bottomCenter,
            widthFactor: 0.6, // Clean overlap
            child: GestureDetector(
              onTap: valid ? () {
                HapticFeedback.lightImpact();
                ref.read(audioServiceProvider).playCardFlip();
                onCardTap(card);
              } : () {
                HapticFeedback.vibrate();
                ref.read(audioServiceProvider).playError();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                curve: Curves.easeOutCubic,
                transform: Matrix4.identity()
                  // ignore: deprecated_member_use
                  ..translate(
                    0.0,
                    valid ? -10.0 : 0.0,
                  )
                  // ignore: deprecated_member_use
                  ..scale(valid ? 1.03 : 0.95), // Scale 1.03
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
                  child: PlayingCardWidget(card: card, width: cardW, height: cardH),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
