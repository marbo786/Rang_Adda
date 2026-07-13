import 'package:rang_adda/shared/models/card_model.dart';
import 'package:rang_adda/shared/ai/bot_observation.dart';
import 'package:rang_adda/shared/ai/bot_difficulty.dart';
import 'package:rang_adda/shared/ai/bot_personality.dart';
import 'rang_bot_easy.dart';
import 'rang_bot_medium.dart';
import 'rang_bot_hard.dart';

abstract class RangBot {
  final BotPersonality personality;

  const RangBot(this.personality);

  /// Chooses a card to play.
  PlayingCard chooseCard(RangBotObservation obs);

  /// Chooses a trump suit when asked (Sir).
  Suit chooseTrump(RangBotObservation obs);

  static RangBot create(BotDifficulty difficulty, String botName) {
    final personality = BotPersonality.fromName(botName);
    switch (difficulty) {
      case BotDifficulty.easy:
        return RangBotEasy(personality);
      case BotDifficulty.medium:
        return RangBotMedium(personality);
      case BotDifficulty.hard:
        return RangBotHard(personality);
      case BotDifficulty.ml:
        // ML difficulty is Thulla-only; fall back to hard for Rang.
        return RangBotHard(personality);
    }
  }
}
