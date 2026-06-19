import 'package:equatable/equatable.dart';

enum Suit { hearts, diamonds, clubs, spades }
enum Rank { ace, two, three, four, five, six, seven, eight, nine, ten, jack, queen, king }

class PlayingCard extends Equatable {
  final Suit suit;
  final Rank rank;

  const PlayingCard({required this.suit, required this.rank});

  @override
  List<Object?> get props => [suit, rank];

  @override
  String toString() => '${rank.name} of ${suit.name}';

  Map<String, dynamic> toJson() => {
        'suit': suit.index,
        'rank': rank.index,
      };

  factory PlayingCard.fromJson(Map<String, dynamic> json) {
    return PlayingCard(
      suit: Suit.values[json['suit'] as int],
      rank: Rank.values[json['rank'] as int],
    );
  }
}
