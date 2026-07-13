import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:rang_adda/shared/models/card_model.dart';
import 'package:rang_adda/shared/ai/bot_observation.dart';
import 'thulla_bot.dart';
import 'thulla_bot_medium.dart';

class ThullaBotML extends ThullaBot {
  static Interpreter? _interpreter;

  ThullaBotML(super.personality);

  /// Returns true if the TFLite model was loaded successfully.
  static bool get isModelLoaded => _interpreter != null;

  static Future<void> initialize() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/ml/thulla_bot.tflite');
      debugPrint('[ThullaBotML] TFLite model loaded successfully.');
    } catch (e) {
      debugPrint('[ThullaBotML] Failed to load TFLite model: $e');
    }
  }

  @override
  PlayingCard chooseCard(ThullaBotObservation obs) {
    if (_interpreter == null) {
      debugPrint('[ThullaBotML] Model not loaded — falling back to Medium bot.');
      return ThullaBotMedium(personality).chooseCard(obs);
    }

    final inputFeatures = _encodeState(obs);
    final outputTensor = [List.filled(52, 0.0)];

    try {
      _interpreter!.run([inputFeatures], outputTensor);
    } catch (e) {
      debugPrint('[ThullaBotML] Inference failed — falling back to Medium bot: $e');
      return ThullaBotMedium(personality).chooseCard(obs);
    }

    final probabilities = outputTensor[0];
    final validCards = _getValidCards(obs);
    final validSet = validCards.toSet();

    final scoredCards = <MapEntry<double, PlayingCard>>[];

    for (int s = 0; s < 4; s++) {
      for (int r = 0; r < 13; r++) {
        final card = PlayingCard(suit: Suit.values[s], rank: Rank.values[r]);
        if (validSet.contains(card)) {
          final cardIdx = s * 13 + r;
          scoredCards.add(MapEntry(probabilities[cardIdx], card));
        }
      }
    }

    if (scoredCards.isEmpty) {
      return ThullaBotMedium(personality).chooseCard(obs);
    }

    scoredCards.sort((a, b) => b.key.compareTo(a.key));
    return scoredCards.first.value;
  }

  List<PlayingCard> _getValidCards(ThullaBotObservation obs) {
    if (obs.currentTrick.isEmpty) {
      if (obs.isFirstTrick) {
        final aceSpades = obs.myHand.where(
          (c) => c.suit == Suit.spades && c.rank == Rank.ace,
        );
        if (aceSpades.isNotEmpty) return aceSpades.toList();
      }
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

  List<double> _encodeState(ThullaBotObservation obs) {
    final features = List<double>.filled(165, 0.0);
    int offset = 0;

    void setCard(Iterable<PlayingCard> cards) {
      for (final c in cards) {
        features[offset + c.suit.index * 13 + c.rank.index] = 1.0;
      }
    }

    // 1. Hand (52)
    setCard(obs.myHand);
    offset += 52;

    // 2. Waste (52)
    setCard(obs.wastePile);
    offset += 52;

    // 3. Trick (52)
    setCard(obs.currentTrick.map((t) => t.card));
    offset += 52;

    // 4. Lead suit (4)
    if (obs.leadSuit != null) {
      features[offset + obs.leadSuit!.index] = 1.0;
    }
    offset += 4;

    // 5. Is Power Player (1)
    features[offset++] = obs.currentTrick.isEmpty ? 1.0 : 0.0;

    // 6. Is First Trick (1)
    features[offset++] = obs.isFirstTrick ? 1.0 : 0.0;

    // 7. Opponents normalized (3)
    final oppCounts = obs.opponentCardCounts.values.toList();
    for (int i = 0; i < 3; i++) {
      if (i < oppCounts.length) {
        features[offset++] = oppCounts[i] / 18.0;
      } else {
        features[offset++] = 0.0;
      }
    }

    return features;
  }
}
