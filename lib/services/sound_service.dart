import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  final AudioPlayer _player = AudioPlayer();
  
  // High-quality placeholder sounds
  static const String popSound = 'https://assets.mixkit.co/active_storage/sfx/2571/2571-preview.mp3';
  static const String successSound = 'https://assets.mixkit.co/active_storage/sfx/1435/1435-preview.mp3';
  static const String shimmerSound = 'https://assets.mixkit.co/active_storage/sfx/2014/2014-preview.mp3';

  bool _isMuted = false;

  Future<void> initialize() async {
    // Pre-load sounds to ensure low-latency
    try {
      await _player.setSource(UrlSource(popSound));
      await _player.setSource(UrlSource(successSound));
      await _player.setSource(UrlSource(shimmerSound));
    } catch (e) {
      debugPrint('Error initializing SoundService: $e');
    }
  }

  void toggleMute() {
    _isMuted = !_isMuted;
  }

  Future<void> playPop() async {
    if (_isMuted) return;
    await _player.play(UrlSource(popSound), mode: PlayerMode.lowLatency);
  }

  Future<void> playSuccess() async {
    if (_isMuted) return;
    await _player.play(UrlSource(successSound), mode: PlayerMode.lowLatency);
  }

  Future<void> playShimmer() async {
    if (_isMuted) return;
    await _player.play(UrlSource(shimmerSound), mode: PlayerMode.lowLatency);
  }

  void dispose() {
    _player.dispose();
  }
}
