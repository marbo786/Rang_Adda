import 'package:equatable/equatable.dart';
import 'package:rang_adda/shared/models/card_model.dart';

class Player extends Equatable {
  final String id;
  final String name;
  final List<PlayingCard> hand;
  final String? latestEmoji;

  const Player({
    required this.id,
    required this.name,
    this.hand = const [],
    this.latestEmoji,
  });

  Player copyWith({
    String? id,
    String? name,
    List<PlayingCard>? hand,
    String? latestEmoji,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      hand: hand ?? this.hand,
      latestEmoji: latestEmoji ?? this.latestEmoji,
    );
  }

  @override
  List<Object?> get props => [id, name, hand, latestEmoji];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'hand': hand.map((c) => c.toJson()).toList(),
        'latestEmoji': latestEmoji,
      };

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'] as String,
      name: json['name'] as String,
      hand: (json['hand'] as List)
          .map((c) => PlayingCard.fromJson(c as Map<String, dynamic>))
          .toList(),
      latestEmoji: json['latestEmoji'] as String?,
    );
  }
}
