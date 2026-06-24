import 'dart:math';
import 'package:rang_adda/shared/models/card_model.dart';
import 'package:rang_adda/shared/ai/bot_observation.dart';
import 'rang_bot.dart';

class RangBotEasy extends RangBot {
  final _random = Random();

  RangBotEasy(super.personality);

  @override
  PlayingCard chooseCard(RangBotObservation obs) {
    final validCards = _getValidCards(obs);
    return validCards[_random.nextInt(validCards.length)];
  }

  @override
  Suit chooseTrump(RangBotObservation obs) {
    // Easy bot just picks a random suit.
    return Suit.values[_random.nextInt(Suit.values.length)];
  }

  List<PlayingCard> _getValidCards(RangBotObservation obs) {
    if (obs.currentTrick.isEmpty) {
      return obs.myHand;
    }

    final leadSuit = obs.leadSuit;
    if (leadSuit != null) {
      final matchingSuitCards = obs.myHand
          .where((c) => c.suit == leadSuit)
          .toList();
      if (matchingSuitCards.isNotEmpty) {
        return matchingSuitCards;
      }
    }
    return obs.myHand;
  }
}
