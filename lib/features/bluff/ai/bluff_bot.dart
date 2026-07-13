import 'package:rang_adda/shared/models/card_model.dart';
import 'package:rang_adda/shared/ai/bot_observation.dart';
import 'package:rang_adda/shared/ai/bot_difficulty.dart';
import 'package:rang_adda/shared/ai/bot_personality.dart';
import 'bluff_bot_easy.dart';
import 'bluff_bot_medium.dart';
import 'bluff_bot_hard.dart';

class BluffPlayDecision {
  final List<PlayingCard> cards;
  final Rank claimedRank;

  const BluffPlayDecision({required this.cards, required this.claimedRank});
}

enum BluffChallengeDecision { callBluff, pass }

abstract class BluffBot {
  final BotPersonality personality;

  const BluffBot(this.personality);

  /// Chooses cards to play and the rank to claim.
  BluffPlayDecision choosePlay(BluffBotObservation obs);

  /// Decides whether to call a bluff or pass when challenged.
  BluffChallengeDecision respondToPlay(BluffBotObservation obs);

  static BluffBot create(BotDifficulty difficulty, String botName) {
    final personality = BotPersonality.fromName(botName);
    switch (difficulty) {
      case BotDifficulty.easy:
        return BluffBotEasy(personality);
      case BotDifficulty.medium:
        return BluffBotMedium(personality);
      case BotDifficulty.hard:
        return BluffBotHard(personality);
      case BotDifficulty.ml:
        // ML difficulty is Thulla-only; fall back to hard for Bluff.
        return BluffBotHard(personality);
    }
  }
}
