import '../models/course_model.dart';
import 'supabase_service.dart';
import '../utils/guest_user.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // Required for jsonEncode/jsonDecode

class CourseService {
  final SupabaseService _supabase = SupabaseService();
  final String _table = 'user_courses';
  static const String _cachedCoursesKey = 'cached_user_courses';
  static const String _cachedActiveCourseKey = 'cached_active_course';

  Future<List<CourseModel>> getUserCourses() async {
    final userId = _supabase.currentUserId;
    if (userId == null) {
      final guest = await GuestUser.load();
      if (guest != null) {
        final nativeLang = LanguageModel.getByCode(guest.nativeLanguage) ?? LanguageModel(code: guest.nativeLanguage, name: guest.nativeLanguage, flag: '', nativeName: guest.nativeLanguage);
        return guest.learningLanguages.map((lang) {
          final targetLang = LanguageModel.getByCode(lang) ?? LanguageModel(code: lang, name: lang, flag: '', nativeName: lang);
          return CourseModel(
             id: 'guest_${lang}_${guest.id}',
             courseId: 'master_$lang',
             userId: guest.id,
             nativeLanguage: guest.nativeLanguage,
             nativeLanguageName: nativeLang.name,
             nativeLanguageFlag: nativeLang.flag,
             targetLanguage: targetLang.code,
             targetLanguageName: targetLang.name,
             targetLanguageFlag: targetLang.flag,
             isActive: (guest.activeLanguage ?? guest.learningLanguages.firstOrNull) == lang,
             createdAt: guest.createdAt,
             lastAccessedAt: guest.lastActiveAt,
          );
        }).toList();
      }
      return [];
    }

    try {
      final response = await _supabase.client
          .from(_table)
          .select()
          .eq('user_id', userId)
          .order('last_accessed_at', ascending: false);

      final courses = (response as List)
          .map((course) => CourseModel.fromJson(course))
          .toList();
      await _cacheCourses(courses); // Cache courses on successful fetch
      return courses;
    } catch (e) {
      // Fallback to local cache if network request fails
      return await _getCachedCourses();
    }
  }

  Future<List<CourseModel>> searchCourses(String query) async {
    final userId = _supabase.currentUserId;
    if (userId == null) return [];
    try {
      final response = await _supabase.client
          .from(_table)
          .select()
          .eq('user_id', userId)
          .or('target_language_name.ilike.%$query%,native_language_name.ilike.%$query%')
          .order('last_accessed_at', ascending: false);

      final courses = (response as List)
          .map((course) => CourseModel.fromJson(course))
          .toList();
          
      // Cache the courses for offline use
      if (query.isEmpty) {
        await _cacheCourses(courses);
      }
      return courses;
    } catch (e) {
      // Fallback to local cache if offline
      final cached = await _getCachedCourses();
      if (query.isNotEmpty) {
        return cached.where((c) => 
          c.targetLanguageName.toLowerCase().contains(query.toLowerCase()) || 
          c.nativeLanguageName.toLowerCase().contains(query.toLowerCase())
        ).toList();
      }
      return cached;
    }
  }

  Future<CourseModel> addCourse({
    required String nativeLanguage,
    required String targetLanguage,
    int currentLevel = 1,
    int totalXP = 0,
  }) async {
    final userId = _supabase.currentUserId;
    if (userId == null) {
      final nativeLang = LanguageModel.getByCode(nativeLanguage) ?? LanguageModel(code: nativeLanguage, name: nativeLanguage, flag: '', nativeName: nativeLanguage);
      final targetLang = LanguageModel.getByCode(targetLanguage) ?? LanguageModel(code: targetLanguage, name: targetLanguage, flag: '', nativeName: targetLanguage);
      var guest = await GuestUser.load();
      if (guest != null) {
        if (!guest.learningLanguages.contains(targetLanguage)) {
          final updatedLanguages = List<String>.from(guest.learningLanguages)..add(targetLanguage);
          final updatedGuest = guest.copyWith(
            nativeLanguage: nativeLanguage,
            learningLanguages: updatedLanguages,
            activeLanguage: targetLanguage, // Set as active
            currentLevel: currentLevel,
            totalXP: totalXP,
          );
          await updatedGuest.save();
          guest = updatedGuest;
        } else {
          // If already in learning languages, just make it active
          final updatedGuest = guest.copyWith(
            nativeLanguage: nativeLanguage,
            activeLanguage: targetLanguage,
            currentLevel: currentLevel,
            totalXP: totalXP,
          );
          await updatedGuest.save();
          guest = updatedGuest;
        }
      } else {
        // Create new guest user and save it
        final newGuest = GuestUser.create().copyWith(
          nativeLanguage: nativeLanguage,
          learningLanguages: [targetLanguage],
          activeLanguage: targetLanguage, // Set as active
          currentLevel: currentLevel,
          totalXP: totalXP,
        );
        await newGuest.save();
        guest = newGuest;
      }
      
      final guestId = guest.id;

      return CourseModel(
        id: 'guest_${targetLanguage}_$guestId',
        courseId: 'master_$targetLanguage',
        userId: guestId,
        nativeLanguage: nativeLanguage,
        nativeLanguageName: nativeLang.name,
        nativeLanguageFlag: nativeLang.flag,
        targetLanguage: targetLanguage,
        targetLanguageName: targetLang.name,
        targetLanguageFlag: targetLang.flag,
        currentLevel: currentLevel,
        totalXP: totalXP,
        isActive: true, // Force active when adding
        createdAt: DateTime.now(),
        lastAccessedAt: DateTime.now(),
      );
    }

    final nativeLang = LanguageModel.getByCode(nativeLanguage);
    final targetLang = LanguageModel.getByCode(targetLanguage);

    if (nativeLang == null || targetLang == null) {
      throw Exception('Invalid language code');
    }

    // Check if course already exists
    final existing = await _supabase.client
        .from(_table)
        .select()
        .eq('user_id', userId)
        .eq('native_language', nativeLanguage)
        .eq('target_language', targetLanguage)
        .maybeSingle();

    if (existing != null) {
      throw Exception('You already have this course');
    }

    // First, deactivate all other courses for this user
    await _supabase.client
        .from(_table)
        .update({'is_active': false})
        .eq('user_id', userId);

    final response = await _supabase.client
        .from(_table)
        .insert({
          'user_id': userId,
          'native_language': nativeLanguage,
          'native_language_name': nativeLang.name,
          'native_language_flag': nativeLang.flag,
          'target_language': targetLanguage,
          'target_language_name': targetLang.name,
          'target_language_flag': targetLang.flag,
          'current_level': currentLevel,
          'total_xp': totalXP,
          'progress': 0.0,
          'is_active': true,
        })
        .select()
        .single();

    final course = CourseModel.fromJson(response);
    
    // Update local caches
    try {
      final cached = await _getCachedCourses();
      // Remove any existing course with the same target language
      cached.removeWhere((c) => c.targetLanguage == targetLanguage);
      for (var c in cached) {
        // Since we insert a new active course, the rest become inactive
        c = CourseModel(
          id: c.id, courseId: c.courseId, userId: c.userId, 
          nativeLanguage: c.nativeLanguage, nativeLanguageName: c.nativeLanguageName, nativeLanguageFlag: c.nativeLanguageFlag,
          targetLanguage: c.targetLanguage, targetLanguageName: c.targetLanguageName, targetLanguageFlag: c.targetLanguageFlag,
          currentLevel: c.currentLevel, totalXP: c.totalXP, progress: c.progress, isActive: false, createdAt: c.createdAt, lastAccessedAt: c.lastAccessedAt
        );
      }
      cached.insert(0, course);
      await _cacheCourses(cached);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cachedActiveCourseKey, jsonEncode(course.toJson()));
    } catch (_) {}

    return course;
  }

  /// Migrates all courses from a guest user into Supabase for a signed-in user.
  /// Call this immediately after sign-in if a GuestUser was previously active.
  Future<void> migrateGuestCourses(GuestUser guest) async {
    final userId = _supabase.currentUserId;
    if (userId == null) return;

    for (final lang in guest.learningLanguages) {
      try {
        // Check for duplicate
        final existing = await _supabase.client
            .from(_table)
            .select('id')
            .eq('user_id', userId)
            .eq('native_language', guest.nativeLanguage)
            .eq('target_language', lang)
            .maybeSingle();
        if (existing != null) continue; // already exists, skip

        final nativeLang = LanguageModel.getByCode(guest.nativeLanguage) ??
            LanguageModel(code: guest.nativeLanguage, name: guest.nativeLanguage, flag: '', nativeName: guest.nativeLanguage);
        final targetLang = LanguageModel.getByCode(lang) ??
            LanguageModel(code: lang, name: lang, flag: '', nativeName: lang);

        await _supabase.client.from(_table).insert({
          'user_id': userId,
          'native_language': guest.nativeLanguage,
          'native_language_name': nativeLang.name,
          'native_language_flag': nativeLang.flag,
          'target_language': lang,
          'target_language_name': targetLang.name,
          'target_language_flag': targetLang.flag,
          'current_level': guest.currentLevel,
          'total_xp': guest.totalXP,
          'progress': 0.0,
          'is_active': lang == guest.learningLanguages.first,
        });
      } catch (_) {
        // Don't fail the whole migration if one course fails
      }
    }
  }

  Future<void> deleteCourse(String courseId) async {
    final userId = _supabase.currentUserId;
    if (userId == null) {
      final guest = await GuestUser.load();
      if (guest != null && courseId.startsWith('guest_')) {
        final parts = courseId.split('_');
        if (parts.length >= 2) {
          final lang = parts[1];
          final updatedLanguages = List<String>.from(guest.learningLanguages)..remove(lang);
          await guest.copyWith(learningLanguages: updatedLanguages).save();
        }
      }
      return;
    }

    await _supabase.client
        .from(_table)
        .delete()
        .eq('id', courseId)
        .eq('user_id', userId);
  }

  Future<void> setActiveCourse(String courseId) async {
    final userId = _supabase.currentUserId;
    if (userId == null) {
      // For guest users, persist the active language code from the courseId
      // courseId format: 'guest_{targetLanguage}_{guestId}'
      final guest = await GuestUser.load();
      if (guest != null && courseId.startsWith('guest_')) {
        final parts = courseId.split('_');
        if (parts.length >= 2) {
          final lang = parts[1];
          await guest.copyWith(activeLanguage: lang).save();
        }
      }
      return;
    }

    // First, deactivate all courses
    await _supabase.client
        .from(_table)
        .update({'is_active': false})
        .eq('user_id', userId);

    // Then activate the selected course
    await _supabase.client
        .from(_table)
        .update({
          'is_active': true,
          'last_accessed_at': DateTime.now().toIso8601String(),
        })
        .eq('id', courseId)
        .eq('user_id', userId);
  }

  Future<CourseModel?> getActiveCourse() async {
    final userId = _supabase.currentUserId;
    if (userId == null) {
      // For guests, derive the active course from the saved activeLanguage
      final guest = await GuestUser.load();
      if (guest == null) return null;
      final activeLang = guest.activeLanguage ?? guest.learningLanguages.firstOrNull;
      if (activeLang == null) return null;
      final nativeLang = LanguageModel.getByCode(guest.nativeLanguage) ?? LanguageModel(code: guest.nativeLanguage, name: guest.nativeLanguage, flag: '', nativeName: guest.nativeLanguage);
      final targetLang = LanguageModel.getByCode(activeLang) ?? LanguageModel(code: activeLang, name: activeLang, flag: '', nativeName: activeLang);
      return CourseModel(
        id: 'guest_${activeLang}_${guest.id}',
        courseId: 'master_$activeLang',
        userId: guest.id,
        nativeLanguage: guest.nativeLanguage,
        nativeLanguageName: nativeLang.name,
        nativeLanguageFlag: nativeLang.flag,
        targetLanguage: targetLang.code,
        targetLanguageName: targetLang.name,
        targetLanguageFlag: targetLang.flag,
        isActive: true,
        createdAt: guest.createdAt,
        lastAccessedAt: guest.lastActiveAt,
      );
    }
    return getUserActiveCourse(userId);
  }

  Future<CourseModel?> getUserActiveCourse(String userId) async {
    try {
      final response = await _supabase.client
          .from(_table)
          .select()
          .eq('user_id', userId)
          .eq('is_active', true)
          .maybeSingle();

      if (response == null) {
        // Try fallback to cache
        final prefs = await SharedPreferences.getInstance();
        final str = prefs.getString(_cachedActiveCourseKey);
        if (str != null) return CourseModel.fromJson(jsonDecode(str));
        return null;
      }
      
      final course = CourseModel.fromJson(response);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cachedActiveCourseKey, jsonEncode(course.toJson()));
      return course;
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_cachedActiveCourseKey);
      if (str != null) return CourseModel.fromJson(jsonDecode(str));
      return null;
    }
  }

  Future<void> updateCourseProgress({
    required String courseId,
    required int xp,
    required double progress,
  }) async {
    final userId = _supabase.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    await _supabase.client
        .from(_table)
        .update({
          'total_xp': xp,
          'progress': progress,
          'last_accessed_at': DateTime.now().toIso8601String(),
        })
        .eq('id', courseId)
        .eq('user_id', userId);
  }

  Future<int> getCourseCount() async {
    final userId = _supabase.currentUserId;
    if (userId == null) return 0;

    final response = await _supabase.client
        .from(_table)
        .select()
        .eq('user_id', userId);

    return (response as List).length;
  }

  // Helper methods for caching
  Future<void> _cacheCourses(List<CourseModel> courses) async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(courses.map((c) => c.toJson()).toList());
    await prefs.setString(_cachedCoursesKey, encoded);
  }

  Future<List<CourseModel>> _getCachedCourses() async {
    final prefs = await SharedPreferences.getInstance();
    final String? encoded = prefs.getString(_cachedCoursesKey);
    if (encoded == null) return [];
    final List<dynamic> decoded = jsonDecode(encoded);
    return decoded.map((c) => CourseModel.fromJson(c)).toList();
  }
}
