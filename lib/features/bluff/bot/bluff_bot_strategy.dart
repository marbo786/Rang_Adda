import 'package:rang_adda/shared/models/card_model.dart';
import 'package:rang_adda/features/bluff/engine/bluff_game_state.dart';

abstract class BluffBotStrategy {
  BluffBotAction chooseAction(BluffGameState state, String botId);
}

sealed class BluffBotAction {
  const BluffBotAction();
  factory BluffBotAction.callBluff() = CallBluff;
  factory BluffBotAction.pass() = Pass;
  factory BluffBotAction.play({
    required List<PlayingCard> cards,
    required Rank claimedRank,
  }) = Play;
}

class CallBluff extends BluffBotAction {
  const CallBluff();
}

class Pass extends BluffBotAction {
  const Pass();
}

class Play extends BluffBotAction {
  final List<PlayingCard> cards;
  final Rank claimedRank;
  const Play({required this.cards, required this.claimedRank});
}
