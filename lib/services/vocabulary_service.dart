import 'package:logger/logger.dart';
import '../models/vocabulary_item.dart';
import 'supabase_service.dart';

class VocabularyService {
  static final VocabularyService _instance = VocabularyService._internal();
  factory VocabularyService() => _instance;
  VocabularyService._internal();

  final Logger _logger = Logger();
  final SupabaseService _supabase = SupabaseService();

  Future<List<VocabularyItem>> getVocabularyByCourse(String courseId) async {
    try {
      final response = await _supabase.client
          .from('vocabulary')
          .select()
          .eq('course_id', courseId)
          .order('difficulty_level', ascending: true);

      return (response as List)
          .map((json) => VocabularyItem.fromJson(json))
          .toList();
    } catch (e) {
      _logger.e('Failed to get vocabulary', error: e);
      return [];
    }
  }

  Future<List<VocabularyItem>> getVocabularyByCategory(String courseId, String category) async {
    try {
      final response = await _supabase.client
          .from('vocabulary')
          .select()
          .eq('course_id', courseId)
          .eq('category', category)
          .order('difficulty_level', ascending: true);

      return (response as List)
          .map((json) => VocabularyItem.fromJson(json))
          .toList();
    } catch (e) {
      _logger.e('Failed to get vocabulary by category', error: e);
      return [];
    }
  }

  Future<List<VocabularyItem>> getRandomVocabulary(String courseId, {int count = 10}) async {
    try {
      final response = await _supabase.client
          .from('vocabulary')
          .select()
          .eq('course_id', courseId)
          .limit(count);

      final items = (response as List)
          .map((json) => VocabularyItem.fromJson(json))
          .toList();
      
      items.shuffle();
      return items.take(count).toList();
    } catch (e) {
      _logger.e('Failed to get random vocabulary', error: e);
      return [];
    }
  }
}
