import 'package:rang_adda/shared/models/card_model.dart';
import 'package:rang_adda/shared/ai/bot_observation.dart';
import 'package:rang_adda/shared/ai/bot_difficulty.dart';
import 'package:rang_adda/shared/ai/bot_personality.dart';
import 'thulla_bot_easy.dart';
import 'thulla_bot_medium.dart';
import 'thulla_bot_hard.dart';
import 'thulla_bot_ml.dart';

abstract class ThullaBot {
  final BotPersonality personality;

  const ThullaBot(this.personality);

  /// Chooses a valid card to play based on the current observation.
  PlayingCard chooseCard(ThullaBotObservation obs);

  /// Creates a Thulla bot of the specified difficulty.
  static ThullaBot create(BotDifficulty difficulty, String botName) {
    final personality = BotPersonality.fromName(botName);
    switch (difficulty) {
      case BotDifficulty.easy:
        return ThullaBotEasy(personality);
      case BotDifficulty.medium:
        return ThullaBotMedium(personality);
      case BotDifficulty.hard:
        return ThullaBotHard(personality);
      case BotDifficulty.ml:
        return ThullaBotML(personality);
    }
  }
}
