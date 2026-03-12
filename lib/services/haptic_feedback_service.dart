import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Haptic feedback intensity levels
enum HapticIntensity {
  off,
  light,
  medium,
  heavy;

  String get displayName {
    switch (this) {
      case HapticIntensity.off:
        return 'Off';
      case HapticIntensity.light:
        return 'Light';
      case HapticIntensity.medium:
        return 'Medium';
      case HapticIntensity.heavy:
        return 'Heavy';
    }
  }

  String get description {
    switch (this) {
      case HapticIntensity.off:
        return 'No haptic feedback';
      case HapticIntensity.light:
        return 'Subtle feedback';
      case HapticIntensity.medium:
        return 'Standard feedback';
      case HapticIntensity.heavy:
        return 'Strong feedback';
    }
  }
}

/// Service for managing haptic feedback
class HapticFeedbackService extends ChangeNotifier {
  static final HapticFeedbackService _instance = HapticFeedbackService._internal();
  factory HapticFeedbackService() => _instance;
  HapticFeedbackService._internal();

  bool _enabled = true;
  HapticIntensity _intensity = HapticIntensity.medium;
  bool _isInitialized = false;

  bool get enabled => _enabled;
  HapticIntensity get intensity => _intensity;
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    _isInitialized = true;
    notifyListeners();
  }

  void toggle() {
    _enabled = !_enabled;
    notifyListeners();
  }

  Future<void> setEnabled(bool value) async {
    _enabled = value;
    notifyListeners();
  }

  Future<void> setIntensity(HapticIntensity intensity) async {
    _intensity = intensity;
    notifyListeners();
  }

  /// Light impact feedback
  Future<void> lightImpact() async {
    if (!_enabled) return;
    await HapticFeedback.lightImpact();
  }

  /// Medium impact feedback
  Future<void> mediumImpact() async {
    if (!_enabled) return;
    await HapticFeedback.mediumImpact();
  }

  /// Heavy impact feedback
  Future<void> heavyImpact() async {
    if (!_enabled) return;
    await HapticFeedback.heavyImpact();
  }

  /// Selection click feedback
  Future<void> selectionClick() async {
    if (!_enabled) return;
    await HapticFeedback.selectionClick();
  }

  /// Vibrate feedback
  Future<void> vibrate() async {
    if (!_enabled) return;
    await HapticFeedback.vibrate();
  }

  /// Success feedback - double light tap
  Future<void> success() async {
    if (!_enabled) return;
    await HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.lightImpact();
  }

  /// Error feedback - heavy double tap
  Future<void> error() async {
    if (!_enabled) return;
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.heavyImpact();
  }

  /// Warning feedback - medium tap
  Future<void> warning() async {
    if (!_enabled) return;
    await HapticFeedback.mediumImpact();
  }

  /// Button press feedback
  Future<void> buttonPress() async {
    if (!_enabled) return;
    await HapticFeedback.selectionClick();
  }

  /// Achievement unlocked feedback
  Future<void> achievementUnlocked() async {
    if (!_enabled) return;
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.lightImpact();
  }
}
