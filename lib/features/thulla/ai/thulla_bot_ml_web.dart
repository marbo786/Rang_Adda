// Web stub for ThullaBotML.
// dart:ffi (required by tflite_flutter) is not available on the Web platform,
// so this stub is used instead. It falls back to the Medium bot logic.
import 'package:flutter/foundation.dart';
import 'package:rang_adda/shared/models/card_model.dart';
import 'package:rang_adda/shared/ai/bot_observation.dart';
import 'thulla_bot.dart';
import 'thulla_bot_medium.dart';

class ThullaBotML extends ThullaBot {
  ThullaBotML(super.personality);

  /// Always false on Web — TFLite (dart:ffi) is not supported.
  static bool get isModelLoaded => false;

  static Future<void> initialize() async {
    debugPrint(
      '[ThullaBotML] Web platform detected — TFLite is not supported. '
      'Using Medium bot as fallback.',
    );
  }

  @override
  PlayingCard chooseCard(ThullaBotObservation obs) {
    // dart:ffi is unavailable on Web, so delegate to the Medium bot.
    return ThullaBotMedium(personality).chooseCard(obs);
  }
}
