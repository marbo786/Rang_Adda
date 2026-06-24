import 'package:equatable/equatable.dart';
import 'package:rang_adda/shared/models/card_model.dart';
import 'package:rang_adda/shared/ai/bot_difficulty.dart';

class Player extends Equatable {
  final String id;
  final String name;
  final List<PlayingCard> hand;
  final int cardCount;
  final String? latestEmoji;
  final bool isBot;
  final BotDifficulty? botDifficulty;

  const Player({
    required this.id,
    required this.name,
    this.hand = const [],
    this.cardCount = 0,
    this.latestEmoji,
    this.isBot = false,
    this.botDifficulty,
  });

  Player copyWith({
    String? id,
    String? name,
    List<PlayingCard>? hand,
    int? cardCount,
    String? latestEmoji,
    bool? isBot,
    BotDifficulty? botDifficulty,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      hand: hand ?? this.hand,
      cardCount: cardCount ?? this.cardCount,
      latestEmoji: latestEmoji ?? this.latestEmoji,
      isBot: isBot ?? this.isBot,
      botDifficulty: botDifficulty ?? this.botDifficulty,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    hand,
    cardCount,
    latestEmoji,
    isBot,
    botDifficulty,
  ];

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'hand': hand.map((c) => c.toJson()).toList(),
    'cardCount': cardCount,
    'latestEmoji': latestEmoji,
    'isBot': isBot,
    'botDifficulty': botDifficulty?.name,
  };

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'] as String,
      name: json['name'] as String,
      hand:
          (json['hand'] as List?)
              ?.map((c) => PlayingCard.fromJson(c as Map<String, dynamic>))
              .toList() ??
          const [],
      cardCount: json['cardCount'] as int? ?? 0,
      latestEmoji: json['latestEmoji'] as String?,
      isBot: json['isBot'] as bool? ?? false,
      botDifficulty: json['botDifficulty'] != null
          ? BotDifficulty.values.firstWhere(
              (e) => e.name == json['botDifficulty'],
              orElse: () => BotDifficulty.easy,
            )
          : null,
    );
  }
}
