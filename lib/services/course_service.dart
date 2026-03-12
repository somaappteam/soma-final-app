import '../models/course_model.dart';
import 'supabase_service.dart';

class CourseService {
  final SupabaseService _supabase = SupabaseService();
  final String _table = 'user_courses';

  Future<List<CourseModel>> getUserCourses() async {
    final userId = _supabase.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _supabase.client
        .from(_table)
        .select()
        .eq('user_id', userId)
        .order('last_accessed_at', ascending: false);

    return (response as List)
        .map((course) => CourseModel.fromJson(course))
        .toList();
  }

  Future<List<CourseModel>> searchCourses(String query) async {
    final userId = _supabase.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _supabase.client
        .from(_table)
        .select()
        .eq('user_id', userId)
        .or('target_language_name.ilike.%$query%,native_language_name.ilike.%$query%')
        .order('last_accessed_at', ascending: false);

    return (response as List)
        .map((course) => CourseModel.fromJson(course))
        .toList();
  }

  Future<CourseModel> addCourse({
    required String nativeLanguage,
    required String targetLanguage,
  }) async {
    final userId = _supabase.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

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

    // Find the master course ID for this language
    final langPrefix = targetLanguage.split('-')[0].toLowerCase();
    final masterCourse = await _supabase.client
        .from('courses')
        .select('id')
        .eq('language_code', langPrefix)
        .maybeSingle();

    final response = await _supabase.client
        .from(_table)
        .insert({
          'user_id': userId,
          'course_id': masterCourse?['id'],
          'native_language': nativeLanguage,
          'native_language_name': nativeLang.name,
          'native_language_flag': nativeLang.flag,
          'target_language': targetLanguage,
          'target_language_name': targetLang.name,
          'target_language_flag': targetLang.flag,
          'current_level': 1,
          'total_xp': 0,
          'progress': 0.0,
          'is_active': true,
        })
        .select()
        .single();

    return CourseModel.fromJson(response);
  }

  Future<void> deleteCourse(String courseId) async {
    final userId = _supabase.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    await _supabase.client
        .from(_table)
        .delete()
        .eq('id', courseId)
        .eq('user_id', userId);
  }

  Future<void> setActiveCourse(String courseId) async {
    final userId = _supabase.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

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
    if (userId == null) return null;
    return getUserActiveCourse(userId);
  }

  Future<CourseModel?> getUserActiveCourse(String userId) async {
    final response = await _supabase.client
        .from(_table)
        .select()
        .eq('user_id', userId)
        .eq('is_active', true)
        .maybeSingle();

    if (response == null) return null;
    return CourseModel.fromJson(response);
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
}
