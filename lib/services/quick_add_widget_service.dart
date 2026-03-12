import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Quick Add Widget configuration for home screen
class QuickAddWidgetService {
  static final QuickAddWidgetService _instance = QuickAddWidgetService._internal();
  factory QuickAddWidgetService() => _instance;
  QuickAddWidgetService._internal();

  static const String _widgetEnabledKey = 'quick_add_widget_enabled';
  static const String _widgetTypeKey = 'quick_add_widget_type';
  static const String _widgetPositionKey = 'quick_add_widget_position';

  bool _enabled = true;
  QuickAddType _type = QuickAddType.quickSession;
  WidgetPosition _position = WidgetPosition.bottomRight;

  bool get enabled => _enabled;
  QuickAddType get type => _type;
  WidgetPosition get position => _position;

  Future<void> initialize() async {
    await _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_widgetEnabledKey) ?? true;
    
    final typeIndex = prefs.getInt(_widgetTypeKey);
    if (typeIndex != null && typeIndex < QuickAddType.values.length) {
      _type = QuickAddType.values[typeIndex];
    }
    
    final positionIndex = prefs.getInt(_widgetPositionKey);
    if (positionIndex != null && positionIndex < WidgetPosition.values.length) {
      _position = WidgetPosition.values[positionIndex];
    }
  }

  Future<void> setEnabled(bool value) async {
    if (_enabled == value) return;
    
    _enabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_widgetEnabledKey, value);
  }

  Future<void> setType(QuickAddType type) async {
    if (_type == type) return;
    
    _type = type;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_widgetTypeKey, type.index);
  }

  Future<void> setPosition(WidgetPosition position) async {
    if (_position == position) return;
    
    _position = position;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_widgetPositionKey, position.index);
  }

  // Get widget configuration for Android/iOS home screen
  Map<String, dynamic> getWidgetConfiguration() {
    return {
      'enabled': _enabled,
      'type': _type.name,
      'position': _position.name,
      'title': _type.displayName,
      'icon': _type.iconName,
    };
  }

  // Handle widget tap action
  void handleWidgetTap(BuildContext context) {
    switch (_type) {
      case QuickAddType.quickSession:
        _navigateToQuickSession(context);
        break;
      case QuickAddType.addVocabulary:
        _navigateToAddVocabulary(context);
        break;
      case QuickAddType.startLesson:
        _navigateToStartLesson(context);
        break;
      case QuickAddType.practiceMode:
        _navigateToPracticeMode(context);
        break;
    }
  }

  void _navigateToQuickSession(BuildContext context) {
    // Navigate to quick session screen
    // For now, show a dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quick Study Session'),
        content: const Text('Start a quick 5-minute study session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Start quick session
            },
            child: const Text('Start'),
          ),
        ],
      ),
    );
  }

  void _navigateToAddVocabulary(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Vocabulary'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Word',
                hintText: 'Enter word in target language',
              ),
            ),
            SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(
                labelText: 'Translation',
                hintText: 'Enter translation',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Save vocabulary
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _navigateToStartLesson(BuildContext context) {
    // Navigate to lesson selection or continue last lesson
  }

  void _navigateToPracticeMode(BuildContext context) {
    // Navigate to practice modes screen
  }
}

enum QuickAddType {
  quickSession,
  addVocabulary,
  startLesson,
  practiceMode,
}

extension QuickAddTypeExtension on QuickAddType {
  String get displayName {
    switch (this) {
      case QuickAddType.quickSession:
        return 'Quick Session';
      case QuickAddType.addVocabulary:
        return 'Add Word';
      case QuickAddType.startLesson:
        return 'Start Lesson';
      case QuickAddType.practiceMode:
        return 'Practice';
    }
  }

  String get description {
    switch (this) {
      case QuickAddType.quickSession:
        return 'Start a quick study session';
      case QuickAddType.addVocabulary:
        return 'Add a new vocabulary word';
      case QuickAddType.startLesson:
        return 'Continue or start a lesson';
      case QuickAddType.practiceMode:
        return 'Jump to practice mode';
    }
  }

  IconData get icon {
    switch (this) {
      case QuickAddType.quickSession:
        return Icons.play_arrow;
      case QuickAddType.addVocabulary:
        return Icons.add;
      case QuickAddType.startLesson:
        return Icons.school;
      case QuickAddType.practiceMode:
        return Icons.sports_esports;
    }
  }

  String get iconName {
    switch (this) {
      case QuickAddType.quickSession:
        return 'play_arrow';
      case QuickAddType.addVocabulary:
        return 'add';
      case QuickAddType.startLesson:
        return 'school';
      case QuickAddType.practiceMode:
        return 'sports_esports';
    }
  }

  Color get color {
    switch (this) {
      case QuickAddType.quickSession:
        return Colors.green;
      case QuickAddType.addVocabulary:
        return Colors.blue;
      case QuickAddType.startLesson:
        return Colors.orange;
      case QuickAddType.practiceMode:
        return Colors.purple;
    }
  }
}

enum WidgetPosition {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
}

extension WidgetPositionExtension on WidgetPosition {
  String get displayName {
    switch (this) {
      case WidgetPosition.topLeft:
        return 'Top Left';
      case WidgetPosition.topRight:
        return 'Top Right';
      case WidgetPosition.bottomLeft:
        return 'Bottom Left';
      case WidgetPosition.bottomRight:
        return 'Bottom Right';
    }
  }
}

/// Floating quick add button widget
class QuickAddButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const QuickAddButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final service = QuickAddWidgetService();
    
    if (!service.enabled) return const SizedBox.shrink();

    return Positioned(
      right: service.position == WidgetPosition.bottomRight || 
             service.position == WidgetPosition.topRight ? 16 : null,
      left: service.position == WidgetPosition.bottomLeft || 
            service.position == WidgetPosition.topLeft ? 16 : null,
      bottom: service.position == WidgetPosition.bottomRight || 
              service.position == WidgetPosition.bottomLeft ? 100 : null,
      top: service.position == WidgetPosition.topRight || 
           service.position == WidgetPosition.topLeft ? 100 : null,
      child: FloatingActionButton.extended(
        onPressed: onPressed ?? () => service.handleWidgetTap(context),
        backgroundColor: service.type.color,
        icon: Icon(service.type.icon),
        label: Text(service.type.displayName),
      ),
    );
  }
}

/// Quick add widget preview
class QuickAddWidgetPreview extends StatelessWidget {
  final QuickAddType type;

  const QuickAddWidgetPreview({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: type.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: type.color.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(type.icon, color: Colors.white, size: 32),
          const SizedBox(height: 4),
          Text(
            type.displayName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
