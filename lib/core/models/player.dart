import 'package:equatable/equatable.dart';
import 'card_model.dart';

class Player extends Equatable {
  final String id;
  final String name;
  final List<PlayingCard> hand;

  const Player({
    required this.id,
    required this.name,
    this.hand = const [],
  });

  Player copyWith({
    String? id,
    String? name,
    List<PlayingCard>? hand,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      hand: hand ?? this.hand,
    );
  }

  @override
  List<Object?> get props => [id, name, hand];
}
