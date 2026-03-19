import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Environment {
  // Production Supabase credentials (embedded for security)
  static const String _supabaseUrl = '';
  static const String _supabaseAnonKey = '';

  static String get supabaseUrl {
    const fromEnv = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
    if (fromEnv.isNotEmpty) return fromEnv;
    final fromDotEnv = dotenv.env['SUPABASE_URL'];
    if (fromDotEnv != null && fromDotEnv.isNotEmpty) return fromDotEnv;
    return _supabaseUrl;
  }

  static String get supabaseAnonKey {
    const fromEnv = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
    if (fromEnv.isNotEmpty) return fromEnv;
    final fromDotEnv = dotenv.env['SUPABASE_ANON_KEY'];
    if (fromDotEnv != null && fromDotEnv.isNotEmpty) return fromDotEnv;
    return _supabaseAnonKey;
  }

  static String get revenueCatApiKey =>
      const String.fromEnvironment('REVENUECAT_API_KEY', defaultValue: '') != ''
          ? const String.fromEnvironment('REVENUECAT_API_KEY')
          : dotenv.env['REVENUECAT_API_KEY'] ?? '';

  static bool get isDevelopment =>
      const bool.fromEnvironment('DEV', defaultValue: false);

  static String get aiTutorApiKey =>
      const String.fromEnvironment('AI_TUTOR_API_KEY', defaultValue: '') != ''
          ? const String.fromEnvironment('AI_TUTOR_API_KEY')
          : dotenv.env['AI_TUTOR_API_KEY'] ?? '';

  static Future<void> initialize() async {
    try {
      await dotenv.load(fileName: ".env");
    } catch (e) {
      debugPrint('ℹ️  Using embedded Supabase credentials');
    }
  }
}
