import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
import '../config/environment.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  final Logger _logger = Logger();
  SupabaseClient? _client;

  SupabaseClient get client {
    if (_client == null) {
      throw Exception('Supabase not initialized. Call initialize() first.');
    }
    return _client!;
  }

  Future<void> initialize() async {
    try {
      await Environment.initialize();
      
      await Supabase.initialize(
        url: Environment.supabaseUrl,
        anonKey: Environment.supabaseAnonKey,
        debug: Environment.isDevelopment,
      );
      
      _client = Supabase.instance.client;
      _logger.i('Supabase initialized successfully');
    } catch (e, stackTrace) {
      _logger.e('Failed to initialize Supabase', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  bool get isAuthenticated => client.auth.currentUser != null;

  User? get currentUser => client.auth.currentUser;

  String? get currentUserId => currentUser?.id;

  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? userMetadata,
  }) async {
    try {
      final response = await client.auth.signUp(
        email: email,
        password: password,
        data: userMetadata,
        emailRedirectTo: 'com.amoslanguages.soma://login-callback/',
      );
      _logger.i('User signed up: ${response.user?.id}');
      return response;
    } catch (e) {
      _logger.e('Sign up failed', error: e);
      rethrow;
    }
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      _logger.i('User signed in: ${response.user?.id}');
      return response;
    } catch (e) {
      _logger.e('Sign in failed', error: e);
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await client.auth.signOut();
      _logger.i('User signed out');
    } catch (e) {
      _logger.e('Sign out failed', error: e);
      rethrow;
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await client.auth.resetPasswordForEmail(email);
      _logger.i('Password reset email sent to: $email');
    } catch (e) {
      _logger.e('Password reset failed', error: e);
      rethrow;
    }
  }

  Future<void> updatePassword(String newPassword) async {
    try {
      await client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      _logger.i('Password updated successfully');
    } catch (e) {
      _logger.e('Password update failed', error: e);
      rethrow;
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      final response = await client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'com.amoslanguages.soma://login-callback',
      );
      _logger.i('Google sign in initiated');
      return response;
    } catch (e) {
      _logger.e('Google sign in failed', error: e);
      rethrow;
    }
  }

  RealtimeChannel subscribeToChannel(String channelName) {
    return client.channel(channelName);
  }

  void unsubscribeFromChannel(RealtimeChannel channel) {
    channel.unsubscribe();
  }
}
