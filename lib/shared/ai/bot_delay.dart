import 'dart:math';
import 'package:rang_adda/shared/ai/bot_difficulty.dart';

/// Generates a natural "thinking" delay before a bot makes a move.
class BotDelay {
  static final _random = Random();

  static Future<void> simulateThinking(BotDifficulty difficulty) async {
    int delayMs;

    switch (difficulty) {
      case BotDifficulty.easy:
        // Easy bots are fast but still take a moment (1500ms - 2500ms)
        delayMs = 1500 + _random.nextInt(1000);
      case BotDifficulty.medium:
        // Medium bots take a bit more time to "think" (2000ms - 3000ms)
        delayMs = 2000 + _random.nextInt(1000);
      case BotDifficulty.hard:
        // Hard bots appear to think carefully (2500ms - 4000ms)
        delayMs = 2500 + _random.nextInt(1500);
      case BotDifficulty.ml:
        // AI bot mirrors the hard delay for a natural feel (2500ms - 4000ms)
        delayMs = 2500 + _random.nextInt(1500);
    }

    await Future.delayed(Duration(milliseconds: delayMs));
  }
}
