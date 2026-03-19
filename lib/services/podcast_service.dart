import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/study_models.dart';
import 'supabase_service.dart';

class PodcastService {
  final SupabaseClient _client = SupabaseService().client;

  Future<List<Podcast>> getAllPodcasts() async {
    try {
      final response = await _client
          .from('podcasts')
          .select()
          .order('published_at', ascending: false);
      
      return (response as List).map((json) => Podcast.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching podcasts: $e');
      return [];
    }
  }

  Future<UserPodcastProgress?> getUserProgress(String userId, String podcastId) async {
    try {
      final response = await _client
          .from('user_podcast_progress')
          .select()
          .eq('user_id', userId)
          .eq('podcast_id', podcastId)
          .maybeSingle();

      if (response == null) return null;
      return UserPodcastProgress.fromJson(response);
    } catch (e) {
      debugPrint('Error fetching user podcast progress: $e');
      return null;
    }
  }

  Future<void> updateProgress(UserPodcastProgress progress) async {
    try {
      await _client.from('user_podcast_progress').upsert(progress.toJson());
    } catch (e) {
      debugPrint('Error updating user podcast progress: $e');
    }
  }

  Future<List<Podcast>> getRecommendedPodcasts(String userId) async {
    // For now, justReturn top 3 recent podcasts as recommendations
    try {
      final response = await _client
          .from('podcasts')
          .select()
          .limit(3)
          .order('published_at', ascending: false);
      
      return (response as List).map((json) => Podcast.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching recommended podcasts: $e');
      return [];
    }
  }
}
