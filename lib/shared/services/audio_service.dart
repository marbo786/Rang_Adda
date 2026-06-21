import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

final audioServiceProvider = Provider<AudioService>((ref) {
  return AudioService();
});

class AudioService {
  final AudioPlayer _player = AudioPlayer();

  AudioService() {
    // Optionally preload if needed, but just_audio is fast enough for local assets
  }

  Future<void> _playSound(String assetPath) async {
    try {
      await _player.setAsset(assetPath);
      await _player.play();
    } catch (e) {
      // Ignore audio errors gracefully (e.g., in tests or missing files)
    }
  }

  void playCardFlip() {
    _playSound('assets/audio/card_flip.wav');
  }

  void playClick() {
    _playSound('assets/audio/click.wav');
  }

  void playError() {
    _playSound('assets/audio/error.wav');
  }

  void playHeavySlam() {
    _playSound('assets/audio/heavy_slam.wav');
  }
}
