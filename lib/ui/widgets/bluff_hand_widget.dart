import 'package:flutter/material.dart';
import '../../core/models/card_model.dart';
import 'playing_card_widget.dart';

class BluffHandWidget extends StatefulWidget {
  final List<PlayingCard> hand;
  final Function(List<PlayingCard>) onPlayCards;
  final VoidCallback onPass;
  final bool canPass;
  final bool isFirstTurn;

  const BluffHandWidget({
    Key? key,
    required this.hand,
    required this.onPlayCards,
    required this.onPass,
    required this.canPass,
    required this.isFirstTurn,
  }) : super(key: key);

  @override
  State<BluffHandWidget> createState() => _BluffHandWidgetState();
}

class _BluffHandWidgetState extends State<BluffHandWidget> {
  final Set<PlayingCard> _selectedCards = {};

  void _toggleCard(PlayingCard card) {
    setState(() {
      if (_selectedCards.contains(card)) {
        _selectedCards.remove(card);
      } else {
        if (_selectedCards.length < 4) {
          _selectedCards.add(card);
        } else {
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
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
                      side: BorderSide(color: Theme.of(context).primaryColor.withOpacity(0.5)),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    _selectedCards.clear();
                    widget.onPass();
                  },
                  child: const Text('PASS', style: TextStyle(fontWeight: FontWeight.bold)),
                )
              else
                const SizedBox.shrink(),
                
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedCards.length >= (widget.isFirstTurn ? 2 : 1) ? Theme.of(context).primaryColor : Theme.of(context).colorScheme.surface,
                  foregroundColor: _selectedCards.length >= (widget.isFirstTurn ? 2 : 1) ? Colors.white : Colors.white54,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: _selectedCards.length >= (widget.isFirstTurn ? 2 : 1) ? 2 : 0,
                ),
                onPressed: _selectedCards.length >= (widget.isFirstTurn ? 2 : 1) ? () {
                  widget.onPlayCards(_selectedCards.toList());
                  setState(() {
                    _selectedCards.clear();
                  });
                } : null,
                child: Text('PLAY ${_selectedCards.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        
        // Hand
        SizedBox(
          height: 140, // Height for lift and shadow
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            itemCount: widget.hand.length,
            itemBuilder: (context, index) {
              final card = widget.hand[index];
              final isSelected = _selectedCards.contains(card);
              
              return Align(
                alignment: Alignment.bottomCenter,
                widthFactor: 0.6,
                child: GestureDetector(
                  onTap: () => _toggleCard(card),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    curve: Curves.easeOutCubic,
                    transform: Matrix4.identity()
                      ..translate(0.0, isSelected ? -10.0 : 0.0)
                      ..scale(isSelected ? 1.05 : 1.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: isSelected ? [
                        BoxShadow(
                          color: Theme.of(context).primaryColor.withOpacity(0.6),
                          blurRadius: 15,
                          spreadRadius: 2,
                        )
                      ] : null,
                    ),
                    child: PlayingCardWidget(
                      card: card,
                      width: 70,
                      height: 105,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
