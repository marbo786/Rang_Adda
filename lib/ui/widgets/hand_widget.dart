import 'package:flutter/material.dart';
import '../../core/models/card_model.dart';
import 'playing_card_widget.dart';

class HandWidget extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140, // Enough height for the 6px lift and shadow
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
              onTap: valid ? () => onCardTap(card) : null,
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
                  child: PlayingCardWidget(card: card, width: 70, height: 105),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
