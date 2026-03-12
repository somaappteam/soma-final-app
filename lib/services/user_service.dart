import '../models/user_model.dart';
import '../models/leaderboard_model.dart';
import 'supabase_service.dart';

class UserService {
  final SupabaseService _supabase = SupabaseService();
  final String _table = 'users';

  Future<UserModel?> getCurrentUser() async {
    final userId = _supabase.currentUserId;
    if (userId == null) return null;

    final response = await _supabase.client
        .from(_table)
        .select()
        .eq('id', userId)
        .single();

    return UserModel.fromJson(response);
  }

  Future<UserModel?> getUserById(String userId) async {
    final response = await _supabase.client
        .from(_table)
        .select()
        .eq('id', userId)
        .single();

    return UserModel.fromJson(response);
  }

  Future<UserModel?> getUserByUsername(String username) async {
    final response = await _supabase.client
        .from(_table)
        .select()
        .eq('username', username)
        .single();

    return UserModel.fromJson(response);
  }

  Future<UserModel> updateUserProfile({
    String? displayName,
    String? avatarUrl,
    String? bio,
    String? country,
    Map<String, dynamic>? settings,
  }) async {
    final userId = _supabase.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (displayName != null) updates['display_name'] = displayName;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
    if (bio != null) updates['bio'] = bio;
    if (country != null) updates['country'] = country;
    if (settings != null) updates['settings'] = settings;

    final response = await _supabase.client
        .from(_table)
        .update(updates)
        .eq('id', userId)
        .select()
        .single();

    return UserModel.fromJson(response);
  }

  Future<void> updateUserLanguages({
    required String nativeLanguage,
    required List<String> learningLanguages,
  }) async {
    final userId = _supabase.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    await _supabase.client.from(_table).update({
      'native_language': nativeLanguage,
      'learning_languages': learningLanguages,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', userId);
  }

  Future<void> updatePrivacyLevel(String privacyLevel) async {
    final userId = _supabase.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    await _supabase.client.from(_table).update({
      'privacy_level': privacyLevel,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', userId);
  }

  Future<void> addXP(int points) async {
    final userId = _supabase.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    await _supabase.client.rpc('add_user_xp', params: {
      'user_id': userId,
      'xp_points': points,
    });
  }

  Future<void> updateStreak() async {
    final userId = _supabase.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    await _supabase.client.rpc('update_user_streak', params: {
      'user_id': userId,
    });
  }

  Future<UserStats?> getUserStats(String userId) async {
    final response = await _supabase.client
        .from('user_stats')
        .select()
        .eq('user_id', userId)
        .single();

    return UserStats.fromJson(response);
  }

  Future<List<LeaderboardEntry>> getGlobalLeaderboard({
    int limit = 100,
    int offset = 0,
  }) async {
    final response = await _supabase.client
        .from('profiles')
        .select()
        .order('total_xp', ascending: false)
        .range(offset, offset + limit - 1);

    int rank = offset + 1;
    return (response as List).map((entry) {
      final totalPlayed = entry['total_games_played'] ?? 0;
      final totalWon = entry['total_games_won'] ?? 0;
      final winRate = totalPlayed > 0 ? (totalWon / totalPlayed) * 100.0 : 0.0;
      return LeaderboardEntry(
        userId: entry['id'] ?? '',
        username: entry['username'] ?? 'Unknown',
        avatarUrl: entry['avatar_url'],
        rank: rank++,
        totalXP: entry['total_xp'] ?? 0,
        currentLevel: entry['level'] ?? 1,
        gamesPlayed: totalPlayed,
        gamesWon: totalWon,
        winRate: winRate,
        isPremium: entry['is_premium'] ?? false,
      );
    }).toList();
  }

  Future<List<LeaderboardEntry>> getFriendsLeaderboard() async {
    final userId = _supabase.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _supabase.client
        .from('leaderboard_friends')
        .select()
        .eq('user_id', userId)
        .order('rank', ascending: true);

    return (response as List)
        .map((entry) => LeaderboardEntry.fromJson(entry))
        .toList();
  }

  Future<List<LeaderboardEntry>> getLanguageLeaderboard(
    String languageCode, {
    int limit = 100,
  }) async {
    final response = await _supabase.client
        .from('leaderboard_language')
        .select()
        .eq('language_code', languageCode)
        .order('rank', ascending: true)
        .limit(limit);

    return (response as List)
        .map((entry) => LeaderboardEntry.fromJson(entry))
        .toList();
  }

  Future<List<LeaderboardEntry>> getWeeklyLeaderboard({
    int limit = 100,
  }) async {
    final response = await _supabase.client
        .from('leaderboard_weekly')
        .select()
        .order('rank', ascending: true)
        .limit(limit);

    return (response as List)
        .map((entry) => LeaderboardEntry.fromJson(entry))
        .toList();
  }

  Future<List<UserModel>> searchUsers(
    String query, {
    int limit = 20,
  }) async {
    final response = await _supabase.client
        .from(_table)
        .select()
        .or('username.ilike.%$query%,display_name.ilike.%$query%')
        .eq('is_active', true)
        .limit(limit);

    return (response as List)
        .map((user) => UserModel.fromJson(user))
        .toList();
  }

  Future<void> reportUser(String reportedUserId, String reason) async {
    final reporterId = _supabase.currentUserId;
    if (reporterId == null) throw Exception('User not authenticated');
    
    await _supabase.client.from('user_reports').insert({
      'reporter_id': reporterId,
      'reported_id': reportedUserId,
      'reason': reason,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> saveOnboardingData(Map<String, dynamic> data) async {
    final userId = _supabase.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final nativeLanguage = data['native_language'] ?? 'en';
    final targetLanguage = data['target_language'] ?? 'es';
    final proficiencyLevel = data['proficiency_level'] ?? 'beginner';
    final dailyGoalMinutes = data['daily_goal_minutes'] ?? 15;

    await _supabase.client.from(_table).update({
      'native_language': nativeLanguage,
      'learning_languages': [targetLanguage],
      'settings': {
        'proficiency_level': proficiencyLevel,
        'daily_goal_minutes': dailyGoalMinutes,
        'onboarding_completed': true,
      },
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', userId);
  }

  Stream<UserModel> subscribeToUserUpdates(String userId) {
    return _supabase.client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .map((data) => UserModel.fromJson(data.first));
  }
}
