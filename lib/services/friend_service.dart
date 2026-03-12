import '../models/friend_model.dart';
import '../constants/app_constants.dart';
import 'supabase_service.dart';

class FriendService {
  final SupabaseService _supabase = SupabaseService();
  final String _table = 'friends';
  final String _requestsTable = 'friend_requests';
  final String _blocksTable = 'blocked_users';

  Future<List<FriendModel>> getFriends() async {
    final userId = _supabase.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _supabase.client
        .from(_table)
        .select()
        .eq('user_id', userId)
        .eq('status', AppConstants.friendStatusAccepted)
        .order('last_interaction_at', ascending: false);

    return (response as List)
        .map((friend) => FriendModel.fromJson(friend))
        .toList();
  }

  Future<List<FriendModel>> getFavoriteFriends() async {
    final userId = _supabase.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _supabase.client
        .from(_table)
        .select()
        .eq('user_id', userId)
        .eq('status', AppConstants.friendStatusAccepted)
        .eq('is_favorite', true)
        .order('last_interaction_at', ascending: false);

    return (response as List)
        .map((friend) => FriendModel.fromJson(friend))
        .toList();
  }

  Future<List<FriendRequest>> getPendingRequests() async {
    final userId = _supabase.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _supabase.client
        .from(_requestsTable)
        .select()
        .eq('receiver_id', userId)
        .eq('status', 'pending')
        .order('created_at', ascending: false);

    return (response as List)
        .map((request) => FriendRequest.fromJson(request))
        .toList();
  }

  Future<List<FriendRequest>> getSentRequests() async {
    final userId = _supabase.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _supabase.client
        .from(_requestsTable)
        .select()
        .eq('sender_id', userId)
        .eq('status', 'pending')
        .order('created_at', ascending: false);

    return (response as List)
        .map((request) => FriendRequest.fromJson(request))
        .toList();
  }

  Future<void> sendFriendRequest({
    required String receiverId,
    String? message,
  }) async {
    final userId = _supabase.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    if (userId == receiverId) {
      throw Exception('Cannot send friend request to yourself');
    }

    final existingRequest = await _supabase.client
        .from(_requestsTable)
        .select()
        .or('and(sender_id.eq.$userId,receiver_id.eq.$receiverId),and(sender_id.eq.$receiverId,receiver_id.eq.$userId)')
        .eq('status', 'pending')
        .maybeSingle();

    if (existingRequest != null) {
      throw Exception('Friend request already pending');
    }

    final existingFriend = await _supabase.client
        .from(_table)
        .select()
        .eq('user_id', userId)
        .eq('friend_id', receiverId)
        .eq('status', AppConstants.friendStatusAccepted)
        .maybeSingle();

    if (existingFriend != null) {
      throw Exception('Already friends with this user');
    }

    final blocked = await _supabase.client
        .from(_blocksTable)
        .select()
        .or('and(blocker_id.eq.$receiverId,blocked_id.eq.$userId),and(blocker_id.eq.$userId,blocked_id.eq.$receiverId)')
        .maybeSingle();

    if (blocked != null) {
      throw Exception('Unable to send friend request');
    }

    final user = await _supabase.client
        .from('users')
        .select('username, display_name, avatar_url')
        .eq('id', userId)
        .single();

    await _supabase.client.from(_requestsTable).insert({
      'sender_id': userId,
      'sender_username': user['username'],
      'sender_display_name': user['display_name'],
      'sender_avatar_url': user['avatar_url'],
      'receiver_id': receiverId,
      'message': message,
    });
  }

  Future<void> acceptFriendRequest(String requestId) async {
    final userId = _supabase.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final request = await _supabase.client
        .from(_requestsTable)
        .select()
        .eq('id', requestId)
        .eq('receiver_id', userId)
        .single();

    await _supabase.client.from(_requestsTable).update({
      'status': 'accepted',
      'responded_at': DateTime.now().toIso8601String(),
    }).eq('id', requestId);

    final senderInfo = await _supabase.client
        .from('users')
        .select('username, display_name, avatar_url')
        .eq('id', request['sender_id'])
        .single();

    final receiverInfo = await _supabase.client
        .from('users')
        .select('username, display_name, avatar_url')
        .eq('id', userId)
        .single();

    final now = DateTime.now().toIso8601String();

    await _supabase.client.from(_table).insert([
      {
        'user_id': userId,
        'friend_id': request['sender_id'],
        'friend_username': senderInfo['username'],
        'friend_display_name': senderInfo['display_name'],
        'friend_avatar_url': senderInfo['avatar_url'],
        'status': AppConstants.friendStatusAccepted,
        'accepted_at': now,
      },
      {
        'user_id': request['sender_id'],
        'friend_id': userId,
        'friend_username': receiverInfo['username'],
        'friend_display_name': receiverInfo['display_name'],
        'friend_avatar_url': receiverInfo['avatar_url'],
        'status': AppConstants.friendStatusAccepted,
        'accepted_at': now,
      },
    ]);

    await _supabase.client.rpc('increment_friend_count', params: {
      'user_id': userId,
    });

    await _supabase.client.rpc('increment_friend_count', params: {
      'user_id': request['sender_id'],
    });
  }

  Future<void> rejectFriendRequest(String requestId) async {
    final userId = _supabase.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    await _supabase.client.from(_requestsTable).update({
      'status': 'rejected',
      'responded_at': DateTime.now().toIso8601String(),
    })
        .eq('id', requestId)
        .eq('receiver_id', userId);
  }

  Future<void> cancelFriendRequest(String requestId) async {
    final userId = _supabase.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    await _supabase.client
        .from(_requestsTable)
        .delete()
        .eq('id', requestId)
        .eq('sender_id', userId);
  }

  Future<void> removeFriend(String friendId) async {
    final userId = _supabase.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    await _supabase.client
        .from(_table)
        .delete()
        .or('and(user_id.eq.$userId,friend_id.eq.$friendId),and(user_id.eq.$friendId,friend_id.eq.$userId)');

    await _supabase.client.rpc('decrement_friend_count', params: {
      'user_id': userId,
    });

    await _supabase.client.rpc('decrement_friend_count', params: {
      'user_id': friendId,
    });
  }

  Future<void> toggleFavorite(String friendId, bool isFavorite) async {
    final userId = _supabase.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    await _supabase.client
        .from(_table)
        .update({'is_favorite': isFavorite})
        .eq('user_id', userId)
        .eq('friend_id', friendId);
  }

  Future<void> toggleMute(String friendId, bool isMuted) async {
    final userId = _supabase.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    await _supabase.client
        .from(_table)
        .update({'is_muted': isMuted})
        .eq('user_id', userId)
        .eq('friend_id', friendId);
  }

  Future<void> blockUser({
    required String blockedId,
    String? reason,
  }) async {
    final userId = _supabase.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final blockedUser = await _supabase.client
        .from('users')
        .select('username, avatar_url')
        .eq('id', blockedId)
        .single();

    await _supabase.client.from(_blocksTable).insert({
      'blocker_id': userId,
      'blocked_id': blockedId,
      'blocked_username': blockedUser['username'],
      'blocked_avatar_url': blockedUser['avatar_url'],
      'reason': reason,
    });

    await _supabase.client
        .from(_table)
        .delete()
        .or('and(user_id.eq.$userId,friend_id.eq.$blockedId),and(user_id.eq.$blockedId,friend_id.eq.$userId)');

    await _supabase.client
        .from(_requestsTable)
        .delete()
        .or('and(sender_id.eq.$userId,receiver_id.eq.$blockedId),and(sender_id.eq.$blockedId,receiver_id.eq.$userId)');
  }

  Future<void> unblockUser(String blockedId) async {
    final userId = _supabase.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    await _supabase.client
        .from(_blocksTable)
        .delete()
        .eq('blocker_id', userId)
        .eq('blocked_id', blockedId);
  }

  Future<List<BlockedUser>> getBlockedUsers() async {
    final userId = _supabase.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _supabase.client
        .from(_blocksTable)
        .select()
        .eq('blocker_id', userId)
        .order('blocked_at', ascending: false);

    return (response as List)
        .map((user) => BlockedUser.fromJson(user))
        .toList();
  }

  Stream<List<FriendModel>> subscribeToFriends() {
    final userId = _supabase.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    return _supabase.client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((data) => data
            .where((friend) => friend['status'] == AppConstants.friendStatusAccepted)
            .map((friend) => FriendModel.fromJson(friend))
            .toList());
  }

  Stream<List<FriendRequest>> subscribeToPendingRequests() {
    final userId = _supabase.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    return _supabase.client
        .from(_requestsTable)
        .stream(primaryKey: ['id'])
        .eq('receiver_id', userId)
        .map((data) => data
            .where((request) => request['status'] == 'pending')
            .map((request) => FriendRequest.fromJson(request))
            .toList());
  }
}
