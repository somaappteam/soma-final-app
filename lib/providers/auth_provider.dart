import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../models/premium_model.dart';
import '../services/supabase_service.dart';
import '../services/user_service.dart';
import '../services/premium_service.dart';
import '../services/course_service.dart';
import '../utils/guest_user.dart';

class AuthProvider extends ChangeNotifier {
  final SupabaseService _supabase = SupabaseService();
  final UserService _userService = UserService();
  final PremiumService _premiumService = PremiumService();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;
  bool _isPremium = false;
  SubscriptionInfo? _subscription;
  bool _isGuest = false;
  GuestUser? _guestUser;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isPremium => _isPremium;
  SubscriptionInfo? get subscription => _subscription;
  bool get isAuthenticated => _supabase.isAuthenticated;
  bool get isGuest => _isGuest;
  GuestUser? get guestUser => _guestUser;

  AuthProvider() {
    _init();
  }

  void _init() {
    _supabase.authStateChanges.listen((event) async {
      if (event.event == AuthChangeEvent.signedIn) {
        // Before loading cloud data, check if guest data should be synced
        await _syncGuestProgressIfNeeded();
        await _loadUserData();
      } else if (event.event == AuthChangeEvent.signedOut) {
        _currentUser = null;
        _isPremium = false;
        _subscription = null;
        _isGuest = false;
        _guestUser = null;
        notifyListeners();
      }
    });

    if (_supabase.isAuthenticated) {
      _loadUserData();
    } else {
      _checkGuestMode();
    }
  }

  /// Called when a guest signs into a real account — migrates their local
  /// courses and XP to Supabase, then clears guest storage.
  Future<void> _syncGuestProgressIfNeeded() async {
    try {
      final guest = await GuestUser.load();
      if (guest == null) return; // nothing to sync

      final courseService = CourseService();

      // Migrate every language course the guest was studying
      await courseService.migrateGuestCourses(guest);

      // Sync XP from guest to Supabase user
      if (guest.totalXP > 0) {
        await _userService.addXP(guest.totalXP);
      }

      // Clear guest data so it doesn't linger
      await GuestUser.clear();
    } catch (e) {
      debugPrint('Guest sync error (non-fatal): $e');
    }
  }

  Future<void> _checkGuestMode() async {
    final guest = await GuestUser.load();
    if (guest != null) {
      _isGuest = true;
      _guestUser = guest;
      notifyListeners();
    }
  }

  Future<void> _loadUserData() async {
    try {
      _isLoading = true;
      notifyListeners();

      _currentUser = await _userService.getCurrentUser();
      _isPremium = await _premiumService.isPremium();
      _subscription = await _premiumService.getCurrentSubscription();
      _isGuest = false;
      _guestUser = null;

      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refreshes the subscription status from Supabase.
  /// Call this after the user completes a purchase or restores purchases.
  Future<void> refreshSubscriptionStatus() async {
    if (!_supabase.isAuthenticated) return;
    try {
      _isPremium = await _premiumService.isPremium();
      _subscription = await _premiumService.getCurrentSubscription();
      notifyListeners();
    } catch (e) {
      debugPrint('Subscription refresh error: $e');
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String username,
    String? nativeLanguage,
    List<String>? learningLanguages,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _supabase.signUp(
        email: email,
        password: password,
        userMetadata: {
          'username': username,
          'native_language': nativeLanguage ?? 'en',
          'learning_languages': learningLanguages ?? ['es'],
        },
      );

      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _supabase.signIn(email: email, password: password);
      _error = null;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();

      await _supabase.signOut();
      await GuestUser.clear();
      _isGuest = false;
      _guestUser = null;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      _isLoading = true;
      notifyListeners();

      await _supabase.signInWithGoogle();
      _error = null;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> continueAsGuest() async {
    try {
      _isLoading = true;
      notifyListeners();

      final guest = GuestUser.create();
      _guestUser = guest;
      await guest.save();
      
      _isGuest = true;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> convertGuestToUser({
    required String email,
    required String password,
    required String username,
  }) async {
    if (!_isGuest || _guestUser == null) return;

    try {
      _isLoading = true;
      notifyListeners();

      await _supabase.signUp(
        email: email,
        password: password,
        userMetadata: {
          'username': username,
          'native_language': _guestUser!.nativeLanguage,
          'learning_languages': _guestUser!.learningLanguages,
          'total_xp': _guestUser!.totalXP,
          'current_level': _guestUser!.currentLevel,
          'streak_days': _guestUser!.streakDays,
          'imported_from_guest': true,
        },
      );

      await GuestUser.clear();
      _isGuest = false;
      _guestUser = null;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _supabase.resetPassword(email);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile({
    String? displayName,
    String? avatarUrl,
    String? bio,
    String? country,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      if (_isGuest && _guestUser != null) {
        _guestUser = _guestUser!.copyWith(
          displayName: displayName,
          avatarUrl: avatarUrl,
          bio: bio,
          country: country,
        );
        await _guestUser!.save();
      } else {
        _currentUser = await _userService.updateUserProfile(
          displayName: displayName,
          avatarUrl: avatarUrl,
          bio: bio,
          country: country,
        );
      }

      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateLanguages({
    required String nativeLanguage,
    required List<String> learningLanguages,
    String? activeLanguage,
  }) async {
    try {
      if (_isGuest) {
        _guestUser ??= GuestUser.create();
        _guestUser = _guestUser!.copyWith(
          nativeLanguage: nativeLanguage,
          learningLanguages: learningLanguages,
          activeLanguage: activeLanguage ?? (learningLanguages.isNotEmpty ? learningLanguages.first : null),
        );
        await _guestUser!.save();
      } else {
        await _userService.updateUserLanguages(
          nativeLanguage: nativeLanguage,
          learningLanguages: learningLanguages,
        );

        _currentUser = _currentUser?.copyWith(
          nativeLanguage: nativeLanguage,
          learningLanguages: learningLanguages,
        );
      }

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> addXP(int points) async {
    try {
      if (_isGuest) {
        _guestUser ??= GuestUser.create();
        _guestUser = _guestUser!.copyWith(
          totalXP: _guestUser!.totalXP + points,
        );
        await _guestUser!.save();
      } else {
        await _userService.addXP(points);

        if (_currentUser != null) {
          _currentUser = _currentUser!.copyWith(
            totalXP: _currentUser!.totalXP + points,
          );
        }
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> refreshGuestUser() async {
    if (_isGuest) {
      final guest = await GuestUser.load();
      if (guest != null) {
        _guestUser = guest;
        notifyListeners();
      }
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
