import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

enum AppThemeMode {
  light,
  dark,
  system,
}

enum FontSize {
  small,    // 0.85x
  normal,   // 1.0x (default)
  large,    // 1.15x
  extraLarge, // 1.3x
}

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'app_theme_mode';
  static const String _fontSizeKey = 'app_font_size';
  static const String _useTrueBlackKey = 'use_true_black';
  static const String _accentColorKey = 'accent_color';
  
  AppThemeMode _themeMode = AppThemeMode.system;
  FontSize _fontSize = FontSize.normal;
  bool _useTrueBlack = false;
  Color _accentColor = AppColors.brandingAccent;
  
  AppThemeMode get themeMode => _themeMode;
  FontSize get fontSize => _fontSize;
  bool get useTrueBlack => _useTrueBlack;
  Color get accentColor => _accentColor;
  
  // Font size multiplier
  double get fontSizeMultiplier {
    switch (_fontSize) {
      case FontSize.small:
        return 0.85;
      case FontSize.normal:
        return 1.0;
      case FontSize.large:
        return 1.15;
      case FontSize.extraLarge:
        return 1.3;
    }
  }
  
  ThemeMode get flutterThemeMode {
    switch (_themeMode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }
  
  bool isDarkMode(BuildContext context) {
    if (_themeMode == AppThemeMode.dark) return true;
    if (_themeMode == AppThemeMode.light) return false;
    return MediaQuery.of(context).platformBrightness == Brightness.dark;
  }
  
  ThemeProvider() {
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load theme mode
    final themeIndex = prefs.getInt(_themeKey);
    if (themeIndex != null && themeIndex < AppThemeMode.values.length) {
      _themeMode = AppThemeMode.values[themeIndex];
    }
    
    // Load font size
    final fontSizeIndex = prefs.getInt(_fontSizeKey);
    if (fontSizeIndex != null && fontSizeIndex < FontSize.values.length) {
      _fontSize = FontSize.values[fontSizeIndex];
    }
    
    // Load true black setting
    _useTrueBlack = prefs.getBool(_useTrueBlackKey) ?? false;
    
    // Load accent color
    final accentColorValue = prefs.getInt(_accentColorKey);
    if (accentColorValue != null) {
      _accentColor = Color(accentColorValue);
    }
    
    notifyListeners();
  }
  
  // Theme Mode
  Future<void> setThemeMode(AppThemeMode mode) async {
    if (_themeMode == mode) return;
    
    _themeMode = mode;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, mode.index);
    
    notifyListeners();
  }
  
  // Font Size
  Future<void> setFontSize(FontSize size) async {
    if (_fontSize == size) return;
    
    _fontSize = size;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_fontSizeKey, size.index);
    
    notifyListeners();
  }
  
  // True Black (OLED)
  Future<void> setUseTrueBlack(bool value) async {
    if (_useTrueBlack == value) return;
    
    _useTrueBlack = value;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_useTrueBlackKey, value);
    
    notifyListeners();
  }
  
  // Accent Color
  Future<void> setAccentColor(Color color) async {
    if (_accentColor == color) return;
    
    _accentColor = color;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_accentColorKey, color.toARGB32());
    
    notifyListeners();
  }
  
  // Helper methods
  String getThemeModeName() {
    switch (_themeMode) {
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.dark:
        return 'Dark';
      case AppThemeMode.system:
        return 'System Default';
    }
  }
  
  IconData getThemeModeIcon() {
    switch (_themeMode) {
      case AppThemeMode.light:
        return Icons.light_mode;
      case AppThemeMode.dark:
        return Icons.dark_mode;
      case AppThemeMode.system:
        return Icons.brightness_auto;
    }
  }
  
  String getFontSizeName() {
    switch (_fontSize) {
      case FontSize.small:
        return 'Small';
      case FontSize.normal:
        return 'Normal';
      case FontSize.large:
        return 'Large';
      case FontSize.extraLarge:
        return 'Extra Large';
    }
  }
  
  // Apply font scaling to text theme
  TextTheme getScaledTextTheme(TextTheme baseTheme) {
    final multiplier = fontSizeMultiplier;
    
    return baseTheme.copyWith(
      displayLarge: baseTheme.displayLarge?.copyWith(
        fontSize: (baseTheme.displayLarge?.fontSize ?? 96) * multiplier,
      ),
      displayMedium: baseTheme.displayMedium?.copyWith(
        fontSize: (baseTheme.displayMedium?.fontSize ?? 60) * multiplier,
      ),
      displaySmall: baseTheme.displaySmall?.copyWith(
        fontSize: (baseTheme.displaySmall?.fontSize ?? 48) * multiplier,
      ),
      headlineLarge: baseTheme.headlineLarge?.copyWith(
        fontSize: (baseTheme.headlineLarge?.fontSize ?? 40) * multiplier,
      ),
      headlineMedium: baseTheme.headlineMedium?.copyWith(
        fontSize: (baseTheme.headlineMedium?.fontSize ?? 34) * multiplier,
      ),
      headlineSmall: baseTheme.headlineSmall?.copyWith(
        fontSize: (baseTheme.headlineSmall?.fontSize ?? 24) * multiplier,
      ),
      titleLarge: baseTheme.titleLarge?.copyWith(
        fontSize: (baseTheme.titleLarge?.fontSize ?? 22) * multiplier,
      ),
      titleMedium: baseTheme.titleMedium?.copyWith(
        fontSize: (baseTheme.titleMedium?.fontSize ?? 16) * multiplier,
      ),
      titleSmall: baseTheme.titleSmall?.copyWith(
        fontSize: (baseTheme.titleSmall?.fontSize ?? 14) * multiplier,
      ),
      bodyLarge: baseTheme.bodyLarge?.copyWith(
        fontSize: (baseTheme.bodyLarge?.fontSize ?? 16) * multiplier,
      ),
      bodyMedium: baseTheme.bodyMedium?.copyWith(
        fontSize: (baseTheme.bodyMedium?.fontSize ?? 14) * multiplier,
      ),
      bodySmall: baseTheme.bodySmall?.copyWith(
        fontSize: (baseTheme.bodySmall?.fontSize ?? 12) * multiplier,
      ),
      labelLarge: baseTheme.labelLarge?.copyWith(
        fontSize: (baseTheme.labelLarge?.fontSize ?? 14) * multiplier,
      ),
      labelMedium: baseTheme.labelMedium?.copyWith(
        fontSize: (baseTheme.labelMedium?.fontSize ?? 12) * multiplier,
      ),
      labelSmall: baseTheme.labelSmall?.copyWith(
        fontSize: (baseTheme.labelSmall?.fontSize ?? 11) * multiplier,
      ),
    );
  }
}

