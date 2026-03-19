import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      textTheme: GoogleFonts.poppinsTextTheme(),
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryTeal,
        primary: AppColors.primaryTeal,
        secondary: AppColors.accentCoral,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppColors.cream,
      cardTheme: const CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primaryTeal,
        unselectedItemColor: AppColors.textLight,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryTeal,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme).apply(
        bodyColor: AppColors.darkTextPrimary,
        displayColor: AppColors.darkTextPrimary,
      ),
      colorScheme: const ColorScheme.dark(
        primary: AppColors.darkAccentTeal,
        secondary: AppColors.darkAccentPurple,
        surface: AppColors.darkSurface,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: AppColors.darkTextPrimary,
        error: AppColors.error,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: AppColors.darkBackground,
      cardTheme: CardThemeData(
        color: AppColors.darkCard,
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.05),
            width: 1,
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.darkTextPrimary,
        ),
        iconTheme: const IconThemeData(
          color: AppColors.darkTextSecondary,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        selectedItemColor: AppColors.darkAccentTeal,
        unselectedItemColor: AppColors.darkTextTertiary,
        selectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 11,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.darkAccentTeal,
          foregroundColor: Colors.black,
          elevation: 4,
          shadowColor: AppColors.darkAccentTeal.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.darkAccentTeal,
          side: const BorderSide(color: AppColors.darkAccentTeal, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.darkAccentTeal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkAccentTeal, width: 2),
        ),
        hintStyle: const TextStyle(color: AppColors.darkTextTertiary),
        labelStyle: const TextStyle(color: AppColors.darkTextSecondary),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.white.withValues(alpha: 0.1),
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.darkElevated,
        contentTextStyle: const TextStyle(color: AppColors.darkTextPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: const TextStyle(
          color: AppColors.darkTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: const TextStyle(
          color: AppColors.darkTextSecondary,
          fontSize: 16,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.darkAccentTeal;
          }
          return AppColors.darkTextTertiary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.darkAccentTeal.withValues(alpha: 0.5);
          }
          return Colors.white.withValues(alpha: 0.1);
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.darkAccentTeal;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.black),
        side: const BorderSide(color: AppColors.darkTextTertiary),
      ),
    );
  }
}

class AppColors {
  // Primary Brand Colors
  static const Color primaryTeal = Color(0xFF4DB6AC);
  static const Color darkTeal = Color(0xFF00695C);
  static const Color lightTeal = Color(0xFFB2DFDB);
  static const Color accentCoral = Color(0xFFFF8A65);
  static const Color accentOrange = Color(0xFFFFB74D);
  
  // Light Theme Colors
  static const Color cream = Color(0xFFFFF8E7);
  static const Color softWhite = Color(0xFFF5F5F5);
  static const Color lightSurface = Colors.white;
  static const Color lightBackground = Color(0xFFFAFAFA);
  
  // Dark Theme Colors - Premium Modern Look
  static const Color darkBackground = Color(0xFF0F0F1B);
  static const Color darkSurface = Color(0xFF1A1A2E);
  static const Color darkCard = Color(0xFF252541);
  static const Color darkElevated = Color(0xFF2D2D4A);
  
  // Dark Theme Text Colors
  static const Color darkTextPrimary = Color(0xFFEAEAEA);
  static const Color darkTextSecondary = Color(0xFFB0B0C3);
  static const Color darkTextTertiary = Color(0xFF6E6E8A);
  
  // Dark Theme Accents
  static const Color darkAccentTeal = Color(0xFF64FFDA);
  static const Color darkAccentPurple = Color(0xFFB388FF);
  static const Color darkAccentPink = Color(0xFFFF80AB);
  
  // Status Colors
  static const Color success = Color(0xFF66BB6A);
  static const Color successLight = Color(0xFFE8F5E9);
  static const Color error = Color(0xFFEF5350);
  static const Color danger = Color(0xFFE53935);
  static const Color warning = Color(0xFFFFCA28);
  static const Color warningLight = Color(0xFFFFF8E1);
  
  // Light Theme Text Colors
  static const Color textDark = Color(0xFF263238);
  static const Color textMedium = Color(0xFF546E7A);
  static const Color textLight = Color(0xFF78909C);
  static const Color textOnDark = Colors.white;
  static const Color surface = Colors.white;
  
  // Neutral Shades (replaces raw Colors.grey)
  static const Color neutralLight = Color(0xFFF5F5F5);
  static const Color neutralMid = Color(0xFFBDBDBD);
  static const Color neutralDark = Color(0xFF757575);

  // Additional Brand Accents
  static const Color primaryPurple = Color(0xFF667eea);
  static const Color secondaryPurple = Color(0xFF764ba2);
  static const Color brandOrange = Color(0xFFFF8F00);
  static const Color brandTeal = Color(0xFF20B2AA);
  static const Color lightGreyBackground = Color(0xFFF8F9FA);

  // Achievement/Metallic Colors
  static const Color bronze = Color(0xFFCD7F32);
  static const Color silver = Color(0xFFC0C0C0);
  static const Color gold = Color(0xFFFFD700);
  static const Color platinum = Color(0xFFE5E4E2);
  static const Color diamond = Color(0xFFB9F2FF);
  static const Color vibrantOrange = Color(0xFFFF6B35);

  // Chart/Level Colors
  static const Color chartLevel0 = Color(0xFFE0E0E0);
  static const Color chartLevel1 = Color(0xFF9BE9A8);
  static const Color chartLevel2 = Color(0xFF40C463);
  static const Color chartLevel3 = Color(0xFF30A14E);
  static const Color chartLevel4 = Color(0xFF216E39);

  // Gradient Shades
  static const Color goldDark = Color(0xFFFFA000);
  static const Color vividPurple = Color(0xFF9C27B0);
  static const Color vividPurpleDark = Color(0xFF7B1FA2);

  // Default Accents
  static const Color brandingAccent = Color(0xFF4DB6AC);

  // Gradients
  static const LinearGradient tealGradient = LinearGradient(
    colors: [primaryTeal, darkTeal],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient coralGradient = LinearGradient(
    colors: [accentCoral, accentOrange],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient goldGradient = LinearGradient(
    colors: [gold, goldDark],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient brandPurpleGradient = LinearGradient(
    colors: [primaryPurple, secondaryPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient purpleGradient = LinearGradient(
    colors: [vividPurple, vividPurpleDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Dark Theme Gradients
  static const LinearGradient darkSurfaceGradient = LinearGradient(
    colors: [darkSurface, darkBackground],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [darkCard, darkElevated],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

