import 'package:equatable/equatable.dart';
import 'package:rang_adda/shared/models/card_model.dart';

/// Represents a single card played by one player within a Rang trick.
/// Mirrors [TrickPlay] from [ThullaGameState] for consistency.
class RangTrickPlay extends Equatable {
  final String playerId;
  final PlayingCard card;

  const RangTrickPlay({required this.playerId, required this.card});

  @override
  List<Object?> get props => [playerId, card];

  Map<String, dynamic> toJson() => {
        'playerId': playerId,
        'card': card.toJson(),
      };

  factory RangTrickPlay.fromJson(Map<String, dynamic> json) {
    return RangTrickPlay(
      playerId: json['playerId'] as String,
      card: PlayingCard.fromJson(json['card'] as Map<String, dynamic>),
    );
  }
}
