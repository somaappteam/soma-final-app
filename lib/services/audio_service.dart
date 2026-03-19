import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  
  final AudioPlayer _correctPlayer = AudioPlayer();
  final AudioPlayer _wrongPlayer = AudioPlayer();
  
  bool _isInitialized = false;

  AudioService._internal();

  /// Initialize players by preloading the assets
  Future<void> init() async {
    if (_isInitialized) return;
    try {
      await _correctPlayer.setAsset('assets/sounds/correct.wav');
      await _wrongPlayer.setAsset('assets/sounds/wrong.wav');
      _isInitialized = true;
    } catch (e) {
      debugPrint('Failed to initialize AudioService: $e');
    }
  }

  /// Play the correct answer sound
  Future<void> playCorrect() async {
    if (!_isInitialized) await init();
    try {
      await _correctPlayer.seek(Duration.zero);
      await _correctPlayer.play();
    } catch (e) {
      debugPrint('Failed to play correct sound: $e');
    }
  }

  /// Play the wrong answer sound
  Future<void> playWrong() async {
    if (!_isInitialized) await init();
    try {
      await _wrongPlayer.seek(Duration.zero);
      await _wrongPlayer.play();
    } catch (e) {
      debugPrint('Failed to play wrong sound: $e');
    }
  }

  /// Dispose players when no longer needed
  void dispose() {
    _correctPlayer.dispose();
    _wrongPlayer.dispose();
    _isInitialized = false;
  }
}
