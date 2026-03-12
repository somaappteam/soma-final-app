import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/haptic_feedback_service.dart';
import '../services/gesture_shortcuts_service.dart';
import '../services/quick_add_widget_service.dart';
import '../theme/app_theme.dart';

/// Comprehensive UX Settings Screen
/// Manages: Dark mode, Font size, Haptic feedback, Gestures, Quick Add Widget
class UXSettingsScreen extends StatefulWidget {
  const UXSettingsScreen({super.key});

  @override
  State<UXSettingsScreen> createState() => _UXSettingsScreenState();
}

class _UXSettingsScreenState extends State<UXSettingsScreen> {
  final HapticFeedbackService _hapticService = HapticFeedbackService();
  final GestureShortcutsService _gestureService = GestureShortcutsService();
  final QuickAddWidgetService _widgetService = QuickAddWidgetService();

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    await _hapticService.initialize();
    await _gestureService.initialize();
    await _widgetService.initialize();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Appearance & UX'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Theme'),
            _buildThemeCard(themeProvider),
            const SizedBox(height: 24),
            
            _buildSectionHeader('Display'),
            _buildDisplayCard(themeProvider),
            const SizedBox(height: 24),
            
            _buildSectionHeader('Haptic Feedback'),
            _buildHapticsCard(),
            const SizedBox(height: 24),
            
            _buildSectionHeader('Gesture Shortcuts'),
            _buildGesturesCard(),
            const SizedBox(height: 24),
            
            _buildSectionHeader('Quick Access'),
            _buildQuickAddCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryTeal,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  // ==================== THEME SECTION ====================

  Widget _buildThemeCard(ThemeProvider themeProvider) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          _buildThemeModeTile(themeProvider),
          const Divider(height: 1),
          _buildTrueBlackTile(themeProvider),
          const Divider(height: 1),
          _buildAccentColorTile(themeProvider),
        ],
      ),
    );
  }

  Widget _buildThemeModeTile(ThemeProvider themeProvider) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primaryTeal.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(themeProvider.getThemeModeIcon(), color: AppColors.primaryTeal),
      ),
      title: const Text('Theme Mode'),
      subtitle: Text(themeProvider.getThemeModeName()),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showThemeModeDialog(themeProvider),
    );
  }

  void _showThemeModeDialog(ThemeProvider themeProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose Theme',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ...AppThemeMode.values.map((mode) => _buildThemeModeOption(mode, themeProvider)),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeModeOption(AppThemeMode mode, ThemeProvider themeProvider) {
    final isSelected = themeProvider.themeMode == mode;
    IconData icon;
    String title;
    String subtitle;

    switch (mode) {
      case AppThemeMode.light:
        icon = Icons.light_mode;
        title = 'Light';
        subtitle = 'Always use light theme';
        break;
      case AppThemeMode.dark:
        icon = Icons.dark_mode;
        title = 'Dark';
        subtitle = 'Always use dark theme';
        break;
      case AppThemeMode.system:
        icon = Icons.brightness_auto;
        title = 'System Default';
        subtitle = 'Follow system settings';
        break;
    }

    return RadioListTile<AppThemeMode>(
      value: mode,
      groupValue: themeProvider.themeMode,
      onChanged: (value) {
        themeProvider.setThemeMode(value!);
        _hapticService.selectionClick();
        Navigator.pop(context);
      },
      title: Text(title),
      subtitle: Text(subtitle),
      secondary: Icon(icon, color: isSelected ? AppColors.primaryTeal : null),
      activeColor: AppColors.primaryTeal,
    );
  }

  Widget _buildTrueBlackTile(ThemeProvider themeProvider) {
    return SwitchListTile(
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.contrast, color: Colors.black),
      ),
      title: const Text('True Black (OLED)'),
      subtitle: const Text('Pure black for OLED displays'),
      value: themeProvider.useTrueBlack,
      onChanged: themeProvider.themeMode == AppThemeMode.light
          ? null
          : (value) {
              themeProvider.setUseTrueBlack(value);
              _hapticService.toggle();
            },
    );
  }

  Widget _buildAccentColorTile(ThemeProvider themeProvider) {
    final colors = [
      const Color(0xFF4DB6AC), // Teal
      const Color(0xFF2196F3), // Blue
      const Color(0xFF9C27B0), // Purple
      const Color(0xFFE91E63), // Pink
      const Color(0xFFFF9800), // Orange
      const Color(0xFF4CAF50), // Green
      const Color(0xFFF44336), // Red
    ];

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: themeProvider.accentColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.color_lens, color: themeProvider.accentColor),
      ),
      title: const Text('Accent Color'),
      onTap: () => _showAccentColorDialog(themeProvider, colors),
    );
  }

  void _showAccentColorDialog(ThemeProvider themeProvider, List<Color> colors) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Accent Color'),
        content: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: colors.map((color) {
            final isSelected = themeProvider.accentColor == color;
            return GestureDetector(
              onTap: () {
                themeProvider.setAccentColor(color);
                _hapticService.selectionClick();
                Navigator.pop(context);
              },
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(color: Colors.white, width: 3)
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.4),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white)
                    : null,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ==================== DISPLAY SECTION ====================

  Widget _buildDisplayCard(ThemeProvider themeProvider) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          _buildFontSizeTile(themeProvider),
          const Divider(height: 1),
          _buildFontPreviewTile(themeProvider),
        ],
      ),
    );
  }

  Widget _buildFontSizeTile(ThemeProvider themeProvider) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.format_size, color: Colors.orange),
      ),
      title: const Text('Font Size'),
      subtitle: Text(themeProvider.getFontSizeName()),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showFontSizeDialog(themeProvider),
    );
  }

  void _showFontSizeDialog(ThemeProvider themeProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Font Size',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Adjust text size throughout the app',
              style: TextStyle(color: AppColors.textMedium),
            ),
            const SizedBox(height: 20),
            ...FontSize.values.map((size) => _buildFontSizeOption(size, themeProvider)),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFontSizeOption(FontSize size, ThemeProvider themeProvider) {
    final isSelected = themeProvider.fontSize == size;
    
    double previewSize;
    switch (size) {
      case FontSize.small:
        previewSize = 14;
        break;
      case FontSize.normal:
        previewSize = 16;
        break;
      case FontSize.large:
        previewSize = 18;
        break;
      case FontSize.extraLarge:
        previewSize = 20;
        break;
    }

    return RadioListTile<FontSize>(
      value: size,
      groupValue: themeProvider.fontSize,
      onChanged: (value) {
        themeProvider.setFontSize(value!);
        _hapticService.selectionClick();
        Navigator.pop(context);
      },
      title: Row(
        children: [
          Text(themeProvider.getFontSizeName()),
          const SizedBox(width: 12),
          Text(
            'Aa',
            style: TextStyle(
              fontSize: previewSize,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryTeal,
            ),
          ),
        ],
      ),
      activeColor: AppColors.primaryTeal,
    );
  }

  Widget _buildFontPreviewTile(ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Preview',
            style: TextStyle(
              fontSize: 12 * themeProvider.fontSizeMultiplier,
              color: AppColors.textMedium,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Hello World',
            style: TextStyle(
              fontSize: 24 * themeProvider.fontSizeMultiplier,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'This is how text will appear throughout the app with your selected font size.',
            style: TextStyle(
              fontSize: 14 * themeProvider.fontSizeMultiplier,
              color: AppColors.textMedium,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== HAPTICS SECTION ====================

  Widget _buildHapticsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          SwitchListTile(
            secondary: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.vibration, color: Colors.purple),
            ),
            title: const Text('Haptic Feedback'),
            subtitle: const Text('Vibration on interactions'),
            value: _hapticService.enabled,
            onChanged: (value) async {
              await _hapticService.setEnabled(value);
              setState(() {});
            },
          ),
          if (_hapticService.enabled) ...[
            const Divider(height: 1),
            _buildHapticIntensityTile(),
            const Divider(height: 1),
            _buildHapticTestTile(),
          ],
        ],
      ),
    );
  }

  Widget _buildHapticIntensityTile() {
    return ListTile(
      leading: const SizedBox(width: 40),
      title: const Text('Intensity'),
      subtitle: Text(_hapticService.intensity.displayName),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showHapticIntensityDialog(),
    );
  }

  void _showHapticIntensityDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Haptic Intensity',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ...HapticIntensity.values.map((intensity) => 
              RadioListTile<HapticIntensity>(
                value: intensity,
                groupValue: _hapticService.intensity,
                onChanged: (value) async {
                  await _hapticService.setIntensity(value!);
                  if (value != HapticIntensity.off) {
                    await _hapticService.lightImpact();
                  }
                  setState(() {});
                  Navigator.pop(context);
                },
                title: Text(intensity.displayName),
                subtitle: Text(intensity.description),
                activeColor: AppColors.primaryTeal,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHapticTestTile() {
    return ListTile(
      leading: const SizedBox(width: 40),
      title: const Text('Test Haptics'),
      trailing: const Icon(Icons.touch_app),
      onTap: () async {
        await _hapticService.success();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Haptic feedback tested!'),
            duration: Duration(seconds: 1),
          ),
        );
      },
    );
  }

  // ==================== GESTURES SECTION ====================

  Widget _buildGesturesCard() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          SwitchListTile(
            secondary: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.teal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.gesture, color: Colors.teal),
            ),
            title: const Text('Gesture Shortcuts'),
            subtitle: const Text('Enable gesture controls'),
            value: _gestureService.enabled,
            onChanged: (value) async {
              await _gestureService.setEnabled(value);
              setState(() {});
            },
          ),
          if (_gestureService.enabled) ...[
            const Divider(height: 1),
            _buildGestureTile(
              'Double Tap to Flip',
              'Double tap flashcards to flip',
              _gestureService.doubleTapToFlip,
              (value) => _gestureService.setDoubleTapToFlip(value),
            ),
            const Divider(height: 1),
            _buildGestureTile(
              'Swipe Navigation',
              'Swipe between screens',
              _gestureService.swipeNavigation,
              (value) => _gestureService.setSwipeNavigation(value),
            ),
            const Divider(height: 1),
            _buildGestureTile(
              'Pinch to Zoom',
              'Zoom on images and text',
              _gestureService.pinchToZoom,
              (value) => _gestureService.setPinchToZoom(value),
            ),
            const Divider(height: 1),
            _buildGestureTile(
              'Long Press Actions',
              'Hold for additional options',
              _gestureService.longPressActions,
              (value) => _gestureService.setLongPressActions(value),
            ),
            const Divider(height: 1),
            _buildGestureTile(
              'Shake to Undo',
              'Shake device to undo',
              _gestureService.shakeToUndo,
              (value) => _gestureService.setShakeToUndo(value),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGestureTile(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: (newValue) async {
        await onChanged(newValue);
        _hapticService.toggle();
        setState(() {});
      },
    );
  }

  // ==================== QUICK ADD SECTION ====================

  Widget _buildQuickAddCard() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          SwitchListTile(
            secondary: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.add_circle, color: Colors.green),
            ),
            title: const Text('Quick Add Widget'),
            subtitle: const Text('Floating action button for quick access'),
            value: _widgetService.enabled,
            onChanged: (value) async {
              await _widgetService.setEnabled(value);
              setState(() {});
            },
          ),
          if (_widgetService.enabled) ...[
            const Divider(height: 1),
            _buildQuickAddTypeTile(),
            const Divider(height: 1),
            _buildQuickAddPositionTile(),
            const Divider(height: 1),
            _buildQuickAddPreviewTile(),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickAddTypeTile() {
    return ListTile(
      leading: const SizedBox(width: 40),
      title: const Text('Widget Type'),
      subtitle: Text(_widgetService.type.displayName),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showQuickAddTypeDialog(),
    );
  }

  void _showQuickAddTypeDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Add Type',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ...QuickAddType.values.map((type) => ListTile(
              leading: QuickAddWidgetPreview(type: type),
              title: Text(type.displayName),
              subtitle: Text(type.description),
              trailing: _widgetService.type == type
                  ? const Icon(Icons.check_circle, color: AppColors.primaryTeal)
                  : null,
              onTap: () async {
                await _widgetService.setType(type);
                _hapticService.selectionClick();
                setState(() {});
                Navigator.pop(context);
              },
            )),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAddPositionTile() {
    return ListTile(
      leading: const SizedBox(width: 40),
      title: const Text('Position'),
      subtitle: Text(_widgetService.position.displayName),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showQuickAddPositionDialog(),
    );
  }

  void _showQuickAddPositionDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Widget Position',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ...WidgetPosition.values.map((position) => RadioListTile<WidgetPosition>(
              value: position,
              groupValue: _widgetService.position,
              onChanged: (value) async {
                await _widgetService.setPosition(value!);
                _hapticService.selectionClick();
                setState(() {});
                Navigator.pop(context);
              },
              title: Text(position.displayName),
              activeColor: AppColors.primaryTeal,
            )),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAddPreviewTile() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Preview',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textMedium,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: QuickAddWidgetPreview(type: _widgetService.type),
          ),
        ],
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
