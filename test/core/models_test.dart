import 'package:flutter_test/flutter_test.dart';
import 'package:rang_adda/core/models/card_model.dart';
import 'package:rang_adda/core/models/deck.dart';
import 'package:rang_adda/core/models/player.dart';

void main() {
  group('Models Test', () {
    test('Standard deck should have 52 unique cards', () {
      final deck = Deck.standard();
      expect(deck.length, 52);
      expect(deck.cards.toSet().length, 52); // All unique
    });

    test('PlayingCard equality works', () {
      const card1 = PlayingCard(suit: Suit.hearts, rank: Rank.ace);
      const card2 = PlayingCard(suit: Suit.hearts, rank: Rank.ace);
      const card3 = PlayingCard(suit: Suit.spades, rank: Rank.ace);

      expect(card1, equals(card2));
      expect(card1, isNot(equals(card3)));
    });

    test('Player creation and copyWith works', () {
      const p1 = Player(id: '1', name: 'Mohsin');
      expect(p1.hand, isEmpty);

      final p2 = p1.copyWith(hand: [const PlayingCard(suit: Suit.clubs, rank: Rank.king)]);
      expect(p2.id, '1');
      expect(p2.name, 'Mohsin');
      expect(p2.hand.length, 1);
    });
  });
}
