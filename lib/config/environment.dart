import 'package:flutter_dotenv/flutter_dotenv.dart';

class Environment {
  // Production Supabase credentials (embedded for security)
  static const String _supabaseUrl = 'https://imyjjyhrqhgyvgpiccbv.supabase.co';
  static const String _supabaseAnonKey = '';

  static String get supabaseUrl =>
      const String.fromEnvironment('SUPABASE_URL', defaultValue: '') != ''
          ? const String.fromEnvironment('SUPABASE_URL')
          : dotenv.env['SUPABASE_URL'] ?? _supabaseUrl;

  static String get supabaseAnonKey =>
      const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '') != ''
          ? const String.fromEnvironment('SUPABASE_ANON_KEY')
          : dotenv.env['SUPABASE_ANON_KEY'] ?? _supabaseAnonKey;

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
      print('ℹ️  Using embedded Supabase credentials');
    }
  }
}
