import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Gesture shortcuts configuration and service
class GestureShortcutsService {
  static final GestureShortcutsService _instance = GestureShortcutsService._internal();
  factory GestureShortcutsService() => _instance;
  GestureShortcutsService._internal();

  static const String _gesturesEnabledKey = 'gestures_enabled';
  static const String _doubleTapToFlipKey = 'double_tap_to_flip';
  static const String _swipeNavigationKey = 'swipe_navigation';
  static const String _pinchToZoomKey = 'pinch_to_zoom';
  static const String _longPressActionsKey = 'long_press_actions';
  static const String _shakeToUndoKey = 'shake_to_undo';

  bool _enabled = true;
  bool _doubleTapToFlip = true;
  bool _swipeNavigation = true;
  bool _pinchToZoom = true;
  bool _longPressActions = true;
  bool _shakeToUndo = false;

  bool get enabled => _enabled;
  bool get doubleTapToFlip => _doubleTapToFlip;
  bool get swipeNavigation => _swipeNavigation;
  bool get pinchToZoom => _pinchToZoom;
  bool get longPressActions => _longPressActions;
  bool get shakeToUndo => _shakeToUndo;

  Future<void> initialize() async {
    await _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_gesturesEnabledKey) ?? true;
    _doubleTapToFlip = prefs.getBool(_doubleTapToFlipKey) ?? true;
    _swipeNavigation = prefs.getBool(_swipeNavigationKey) ?? true;
    _pinchToZoom = prefs.getBool(_pinchToZoomKey) ?? true;
    _longPressActions = prefs.getBool(_longPressActionsKey) ?? true;
    _shakeToUndo = prefs.getBool(_shakeToUndoKey) ?? false;
  }

  Future<void> setEnabled(bool value) async {
    if (_enabled == value) return;
    
    _enabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_gesturesEnabledKey, value);
  }

  Future<void> setDoubleTapToFlip(bool value) async {
    if (_doubleTapToFlip == value) return;
    
    _doubleTapToFlip = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_doubleTapToFlipKey, value);
  }

  Future<void> setSwipeNavigation(bool value) async {
    if (_swipeNavigation == value) return;
    
    _swipeNavigation = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_swipeNavigationKey, value);
  }

  Future<void> setPinchToZoom(bool value) async {
    if (_pinchToZoom == value) return;
    
    _pinchToZoom = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pinchToZoomKey, value);
  }

  Future<void> setLongPressActions(bool value) async {
    if (_longPressActions == value) return;
    
    _longPressActions = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_longPressActionsKey, value);
  }

  Future<void> setShakeToUndo(bool value) async {
    if (_shakeToUndo == value) return;
    
    _shakeToUndo = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_shakeToUndoKey, value);
  }

  // Helper to check if a specific gesture is active
  bool isGestureActive(GestureType type) {
    if (!_enabled) return false;
    
    switch (type) {
      case GestureType.doubleTapToFlip:
        return _doubleTapToFlip;
      case GestureType.swipeNavigation:
        return _swipeNavigation;
      case GestureType.pinchToZoom:
        return _pinchToZoom;
      case GestureType.longPressActions:
        return _longPressActions;
      case GestureType.shakeToUndo:
        return _shakeToUndo;
    }
  }
}

enum GestureType {
  doubleTapToFlip,
  swipeNavigation,
  pinchToZoom,
  longPressActions,
  shakeToUndo,
}

extension GestureTypeExtension on GestureType {
  String get displayName {
    switch (this) {
      case GestureType.doubleTapToFlip:
        return 'Double Tap to Flip';
      case GestureType.swipeNavigation:
        return 'Swipe Navigation';
      case GestureType.pinchToZoom:
        return 'Pinch to Zoom';
      case GestureType.longPressActions:
        return 'Long Press Actions';
      case GestureType.shakeToUndo:
        return 'Shake to Undo';
    }
  }

  String get description {
    switch (this) {
      case GestureType.doubleTapToFlip:
        return 'Double tap flashcards to flip them';
      case GestureType.swipeNavigation:
        return 'Swipe between screens and cards';
      case GestureType.pinchToZoom:
        return 'Pinch to zoom on images and text';
      case GestureType.longPressActions:
        return 'Hold for additional options';
      case GestureType.shakeToUndo:
        return 'Shake device to undo last action';
    }
  }

  IconData get icon {
    switch (this) {
      case GestureType.doubleTapToFlip:
        return Icons.touch_app;
      case GestureType.swipeNavigation:
        return Icons.swipe;
      case GestureType.pinchToZoom:
        return Icons.zoom_in;
      case GestureType.longPressActions:
        return Icons.fingerprint;
      case GestureType.shakeToUndo:
        return Icons.vibration;
    }
  }
}

/// Widget that wraps content with gesture support
class GestureEnabledWidget extends StatelessWidget {
  final Widget child;
  final GestureType? gestureType;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onLongPress;
  final Function(DragUpdateDetails)? onHorizontalDrag;
  final Function(DragUpdateDetails)? onVerticalDrag;

  const GestureEnabledWidget({
    super.key,
    required this.child,
    this.gestureType,
    this.onDoubleTap,
    this.onLongPress,
    this.onHorizontalDrag,
    this.onVerticalDrag,
  });

  @override
  Widget build(BuildContext context) {
    final service = GestureShortcutsService();
    
    Widget content = child;

    // Add gesture detectors based on type and settings
    if (gestureType == GestureType.doubleTapToFlip && 
        service.doubleTapToFlip && 
        onDoubleTap != null) {
      content = GestureDetector(
        onDoubleTap: onDoubleTap,
        child: content,
      );
    }

    if (gestureType == GestureType.longPressActions && 
        service.longPressActions && 
        onLongPress != null) {
      content = GestureDetector(
        onLongPress: onLongPress,
        child: content,
      );
    }

    if (gestureType == GestureType.swipeNavigation && 
        service.swipeNavigation) {
      content = GestureDetector(
        onHorizontalDragUpdate: onHorizontalDrag,
        onVerticalDragUpdate: onVerticalDrag,
        child: content,
      );
    }

    return content;
  }
}

/// Gesture shortcut help dialog
class GestureHelpDialog extends StatelessWidget {
  const GestureHelpDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.gesture, color: Colors.blue),
          SizedBox(width: 8),
          Text('Gesture Shortcuts'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: GestureType.values.map((gesture) {
            return ListTile(
              leading: Icon(gesture.icon, color: Colors.grey),
              title: Text(gesture.displayName),
              subtitle: Text(gesture.description),
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Got it'),
        ),
      ],
    );
  }
}
