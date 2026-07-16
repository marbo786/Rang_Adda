import 'package:rang_adda/shared/models/card_model.dart';
import 'package:rang_adda/features/rang/engine/rang_game_state.dart';

abstract class RangBotStrategy {
  /// Choose a card to play during trick play phase.
  /// Must return a card where RangEngine.getMoveError() == null.
  PlayingCard chooseCard(RangGameState state, String botId);

  /// Choose the trump suit during trump selection phase.
  /// Called only for the trumpCallerId bot.
  Suit chooseTrump(RangGameState state, String botId);
}
