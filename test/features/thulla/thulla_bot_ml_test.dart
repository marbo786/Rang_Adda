import 'package:flutter_test/flutter_test.dart';
import 'package:rang_adda/features/thulla/ai/thulla_bot_ml.dart';
import 'package:rang_adda/features/thulla/engine/thulla_engine.dart';
import 'package:rang_adda/shared/ai/bot_observation.dart';
import 'package:rang_adda/shared/ai/bot_personality.dart';
import 'package:rang_adda/shared/models/player.dart';

void main() {
  group('ThullaBotML', () {
    test('ML bot returns a valid card when model loaded', () async {
      await ThullaBotML.initialize();

      final state = ThullaEngine.initializeGame([
        const Player(id: 'p1', name: 'Alice'),
        const Player(id: 'p2', name: 'Bob'),
        const Player(id: 'p3', name: 'Charlie'),
      ]);

      final botId = state.currentPlayerId!;

      // Build the observation the same way the provider does.
      final obs = ThullaBotObservation.fromState(state, botId);

      final bot = ThullaBotML(BotPersonality.fromName('TestBot'));
      final card = bot.chooseCard(obs);

      // The chosen card must be playable — getMoveError returns null for valid moves.
      expect(
        ThullaEngine.getMoveError(state, botId, card),
        isNull,
        reason:
            'ThullaBotML must return a card that is legal in the current state',
      );
    });
  });
}
