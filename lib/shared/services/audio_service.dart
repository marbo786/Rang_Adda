import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

final audioServiceProvider = Provider<AudioService>((ref) {
  return AudioService();
});

class AudioService {
  final List<AudioPlayer> _pool = List.generate(8, (_) => AudioPlayer());
  int _poolIndex = 0;
  final AudioPlayer _bgmPlayer = AudioPlayer();

  AudioService() {
    _initBgm();
  }

  Future<void> _initBgm() async {
    try {
      await _bgmPlayer.setAsset('assets/audio/bgm.mp3');
      await _bgmPlayer.setLoopMode(LoopMode.all);
      await _bgmPlayer.setVolume(0.3);
      _bgmPlayer.play();
    } catch (e) {
      // Ignore gracefully
    }
  }

  void stopBgm() {
    _bgmPlayer.stop();
  }

  Future<void> _playSound(String assetPath) async {
    try {
      final player = _pool[_poolIndex];
      _poolIndex = (_poolIndex + 1) % _pool.length;
      await player.setAsset(assetPath);
      await player.play();
    } catch (e) {
      // Ignore audio errors gracefully
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

  void playTrickWin() {
    _playSound('assets/audio/trick_win.wav');
  }

  void playGameOver() {
    _playSound('assets/audio/game_over.wav');
  }

  void playBluffCall() {
    _playSound('assets/audio/bluff_call.wav');
  }
}
