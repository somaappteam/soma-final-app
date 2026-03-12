import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/competition_model.dart';
import '../constants/app_constants.dart';
import 'supabase_service.dart';

class CompetitionService {
  final SupabaseService _supabase = SupabaseService();
  final String _table = 'competitions';
  final String _playersTable = 'competition_players';
  final String _invitesTable = 'game_invites';

  Future<List<ActiveGame>> getActiveGames({
    String? language,
    String? difficulty,
    bool? isPrivate,
    int limit = 20,
    int offset = 0,
  }) async {
    PostgrestFilterBuilder query = _supabase.client
        .from(_table)
        .select()
        .eq('status', AppConstants.gameStatusWaiting);

    if (language != null) {
      query = query.eq('language', language);
    }
    if (difficulty != null) {
      query = query.eq('difficulty', difficulty);
    }
    if (isPrivate != null) {
      query = query.eq('is_private', isPrivate);
    }

    final response = await query
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List)
        .map((game) => ActiveGame.fromJson(game))
        .toList();
  }

  Future<List<ActiveGame>> getMyActiveGames() async {
    final userId = _supabase.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _supabase.client
        .from(_playersTable)
        .select('competition:$_table(*)')
        .eq('user_id', userId)
        .inFilter('competition.status', [
          AppConstants.gameStatusWaiting,
          AppConstants.gameStatusActive,
        ]);

    return (response as List)
        .map((item) => ActiveGame.fromJson(item['competition']))
        .toList();
  }

  Future<CompetitionModel> createCompetition({
    required String title,
    String? description,
    required String gameType,
    required String language,
    required String difficulty,
    required int maxPlayers,
    required DateTime scheduledStart,
    int durationMinutes = 30,
    bool isPrivate = false,
    bool isPremiumOnly = false,
    int entryFee = 0,
    int prizeXP = 100,
    List<String>? allowedCategories,
    Map<String, dynamic>? gameSettings,
    bool allowSpectators = false,
  }) async {
    final userId = _supabase.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final user = await _supabase.client
        .from('users')
        .select('username, avatar_url')
        .eq('id', userId)
        .single();

    final inviteCode = isPrivate
        ? _generateInviteCode()
        : null;

    final response = await _supabase.client
        .from(_table)
        .insert({
          'host_id': userId,
          'host_name': user['username'],
          'host_avatar_url': user['avatar_url'],
          'title': title,
          'description': description,
          'game_type': gameType,
          'language': language,
          'difficulty': difficulty,
          'max_players': maxPlayers,
          'current_players': 1,
          'status': AppConstants.gameStatusWaiting,
          'scheduled_start': scheduledStart.toIso8601String(),
          'duration_minutes': durationMinutes,
          'is_private': isPrivate,
          'invite_code': inviteCode,
          'is_premium_only': isPremiumOnly,
          'entry_fee': entryFee,
          'prize_xp': prizeXP,
          'allowed_categories': allowedCategories,
          'game_settings': gameSettings,
          'allow_spectators': allowSpectators,
        })
        .select()
        .single();

    await _supabase.client.from(_playersTable).insert({
      'competition_id': response['id'],
      'user_id': userId,
      'username': user['username'],
      'avatar_url': user['avatar_url'],
      'joined_at': DateTime.now().toIso8601String(),
      'is_host': true,
      'is_ready': false,
    });

    return CompetitionModel.fromJson(response);
  }

  Future<CompetitionModel> joinCompetition(
    String competitionId, {
    String? inviteCode,
  }) async {
    final userId = _supabase.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final user = await _supabase.client
        .from('users')
        .select('username, avatar_url')
        .eq('id', userId)
        .single();

    final competition = await _supabase.client
        .from(_table)
        .select()
        .eq('id', competitionId)
        .single();

    if (competition['is_private'] == true &&
        competition['invite_code'] != inviteCode) {
      throw Exception('Invalid invite code');
    }

    if (competition['current_players'] >= competition['max_players']) {
      throw Exception('Game is full');
    }

    if (competition['is_premium_only'] == true) {
      final userData = await _supabase.client
          .from('users')
          .select('is_premium')
          .eq('id', userId)
          .single();

      if (userData['is_premium'] != true) {
        throw Exception('Premium subscription required');
      }
    }

    await _supabase.client.from(_playersTable).insert({
      'competition_id': competitionId,
      'user_id': userId,
      'username': user['username'],
      'avatar_url': user['avatar_url'],
      'joined_at': DateTime.now().toIso8601String(),
      'is_host': false,
      'is_ready': false,
    });

    await _supabase.client.rpc('increment_player_count', params: {
      'comp_id': competitionId,
    });

    final updatedCompetition = await _supabase.client
        .from(_table)
        .select()
        .eq('id', competitionId)
        .single();

    return CompetitionModel.fromJson(updatedCompetition);
  }

  Future<void> leaveCompetition(String competitionId) async {
    final userId = _supabase.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final competition = await _supabase.client
        .from(_table)
        .select('host_id, current_players')
        .eq('id', competitionId)
        .single();

    if (competition['host_id'] == userId) {
      await _supabase.client
          .from(_table)
          .update({'status': AppConstants.gameStatusCancelled})
          .eq('id', competitionId);
    } else {
      await _supabase.client
          .from(_playersTable)
          .delete()
          .eq('competition_id', competitionId)
          .eq('user_id', userId);

      await _supabase.client.rpc('decrement_player_count', params: {
        'comp_id': competitionId,
      });
    }
  }

  Future<void> setPlayerReady(String competitionId, bool isReady) async {
    final userId = _supabase.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    await _supabase.client
        .from(_playersTable)
        .update({'is_ready': isReady})
        .eq('competition_id', competitionId)
        .eq('user_id', userId);
  }

  Future<GameInvite> inviteFriendToGame({
    required String competitionId,
    required String friendId,
  }) async {
    final userId = _supabase.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final user = await _supabase.client
        .from('users')
        .select('username, avatar_url')
        .eq('id', userId)
        .single();

    final competition = await _supabase.client
        .from(_table)
        .select('title')
        .eq('id', competitionId)
        .single();

    final response = await _supabase.client
        .from(_invitesTable)
        .insert({
          'competition_id': competitionId,
          'inviter_id': userId,
          'inviter_name': user['username'],
          'inviter_avatar_url': user['avatar_url'],
          'invitee_id': friendId,
          'competition_title': competition['title'],
        })
        .select()
        .single();

    return GameInvite.fromJson(response);
  }

  Future<void> respondToInvite({
    required String inviteId,
    required bool accept,
  }) async {
    await _supabase.client
        .from(_invitesTable)
        .update({
          'status': accept ? 'accepted' : 'rejected',
          'responded_at': DateTime.now().toIso8601String(),
        })
        .eq('id', inviteId);

    if (accept) {
      final invite = await _supabase.client
          .from(_invitesTable)
          .select('competition_id')
          .eq('id', inviteId)
          .single();

      await joinCompetition(invite['competition_id']);
    }
  }

  Future<List<GameInvite>> getPendingInvites() async {
    final userId = _supabase.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _supabase.client
        .from(_invitesTable)
        .select()
        .eq('invitee_id', userId)
        .eq('status', 'pending')
        .order('created_at', ascending: false);

    return (response as List)
        .map((invite) => GameInvite.fromJson(invite))
        .toList();
  }

  Future<CompetitionModel?> getCompetitionDetails(String competitionId) async {
    final response = await _supabase.client
        .from(_table)
        .select('*, players:$_playersTable(*)')
        .eq('id', competitionId)
        .single();

    return CompetitionModel.fromJson(response);
  }

  Stream<List<CompetitionPlayer>> subscribeToGamePlayers(
    String competitionId,
  ) {
    return _supabase.client
        .from(_playersTable)
        .stream(primaryKey: ['competition_id', 'user_id'])
        .eq('competition_id', competitionId)
        .order('joined_at', ascending: true)
        .map((data) => data
            .map((player) => CompetitionPlayer.fromJson(player))
            .toList());
  }

  Stream<CompetitionModel> subscribeToCompetition(String competitionId) {
    return _supabase.client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('id', competitionId)
        .map((data) => CompetitionModel.fromJson(data.first));
  }

  String _generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final code = StringBuffer();
    for (var i = 0; i < 6; i++) {
      code.write(chars[(DateTime.now().millisecond + i) % chars.length]);
    }
    return code.toString();
  }
}
