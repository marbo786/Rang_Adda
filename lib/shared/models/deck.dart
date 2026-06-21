import 'package:equatable/equatable.dart';
import 'package:rang_adda/shared/models/card_model.dart';

class Deck extends Equatable {
  final List<PlayingCard> cards;

  const Deck({required this.cards});

  factory Deck.standard() {
    final cards = <PlayingCard>[];
    for (var suit in Suit.values) {
      for (var rank in Rank.values) {
        cards.add(PlayingCard(suit: suit, rank: rank));
      }
    }
    return Deck(cards: cards);
  }

  Deck copyWith({List<PlayingCard>? cards}) {
    return Deck(cards: cards ?? this.cards);
  }

  bool get isEmpty => cards.isEmpty;
  int get length => cards.length;

  @override
  List<Object?> get props => [cards];
}
