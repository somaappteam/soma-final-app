class FriendModel {
  final String id;
  final String userId;
  final String friendId;
  final String friendUsername;
  final String? friendDisplayName;
  final String? friendAvatarUrl;
  final DateTime createdAt;
  final String status;
  final DateTime? acceptedAt;
  final bool isFavorite;
  final bool isMuted;
  final String? nickname;
  final DateTime? lastInteractionAt;
  final FriendActivity? lastActivity;

  FriendModel({
    required this.id,
    required this.userId,
    required this.friendId,
    required this.friendUsername,
    this.friendDisplayName,
    this.friendAvatarUrl,
    required this.createdAt,
    required this.status,
    this.acceptedAt,
    this.isFavorite = false,
    this.isMuted = false,
    this.nickname,
    this.lastInteractionAt,
    this.lastActivity,
  });

  factory FriendModel.fromJson(Map<String, dynamic> json) {
    return FriendModel(
      id: json['id'],
      userId: json['user_id'],
      friendId: json['friend_id'],
      friendUsername: json['friend_username'],
      friendDisplayName: json['friend_display_name'],
      friendAvatarUrl: json['friend_avatar_url'],
      createdAt: DateTime.parse(json['created_at']),
      status: json['status'],
      acceptedAt: json['accepted_at'] != null
          ? DateTime.parse(json['accepted_at'])
          : null,
      isFavorite: json['is_favorite'] ?? false,
      isMuted: json['is_muted'] ?? false,
      nickname: json['nickname'],
      lastInteractionAt: json['last_interaction_at'] != null
          ? DateTime.parse(json['last_interaction_at'])
          : null,
      lastActivity: json['last_activity'] != null
          ? FriendActivity.fromJson(json['last_activity'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'friend_id': friendId,
      'friend_username': friendUsername,
      'friend_display_name': friendDisplayName,
      'friend_avatar_url': friendAvatarUrl,
      'created_at': createdAt.toIso8601String(),
      'status': status,
      'accepted_at': acceptedAt?.toIso8601String(),
      'is_favorite': isFavorite,
      'is_muted': isMuted,
      'nickname': nickname,
      'last_interaction_at': lastInteractionAt?.toIso8601String(),
    };
  }
}

class FriendRequest {
  final String id;
  final String senderId;
  final String senderUsername;
  final String? senderDisplayName;
  final String? senderAvatarUrl;
  final String receiverId;
  final DateTime createdAt;
  final String status;
  final String? message;
  final DateTime? respondedAt;

  FriendRequest({
    required this.id,
    required this.senderId,
    required this.senderUsername,
    this.senderDisplayName,
    this.senderAvatarUrl,
    required this.receiverId,
    required this.createdAt,
    this.status = 'pending',
    this.message,
    this.respondedAt,
  });

  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    return FriendRequest(
      id: json['id'],
      senderId: json['sender_id'],
      senderUsername: json['sender_username'],
      senderDisplayName: json['sender_display_name'],
      senderAvatarUrl: json['sender_avatar_url'],
      receiverId: json['receiver_id'],
      createdAt: DateTime.parse(json['created_at']),
      status: json['status'] ?? 'pending',
      message: json['message'],
      respondedAt: json['responded_at'] != null
          ? DateTime.parse(json['responded_at'])
          : null,
    );
  }
}

class FriendActivity {
  final String type;
  final String description;
  final DateTime timestamp;
  final String? competitionId;
  final String? achievementId;

  FriendActivity({
    required this.type,
    required this.description,
    required this.timestamp,
    this.competitionId,
    this.achievementId,
  });

  factory FriendActivity.fromJson(Map<String, dynamic> json) {
    return FriendActivity(
      type: json['type'],
      description: json['description'],
      timestamp: DateTime.parse(json['timestamp']),
      competitionId: json['competition_id'],
      achievementId: json['achievement_id'],
    );
  }
}

class BlockedUser {
  final String id;
  final String blockerId;
  final String blockedId;
  final String blockedUsername;
  final String? blockedAvatarUrl;
  final DateTime blockedAt;
  final String? reason;

  BlockedUser({
    required this.id,
    required this.blockerId,
    required this.blockedId,
    required this.blockedUsername,
    this.blockedAvatarUrl,
    required this.blockedAt,
    this.reason,
  });

  factory BlockedUser.fromJson(Map<String, dynamic> json) {
    return BlockedUser(
      id: json['id'],
      blockerId: json['blocker_id'],
      blockedId: json['blocked_id'],
      blockedUsername: json['blocked_username'],
      blockedAvatarUrl: json['blocked_avatar_url'],
      blockedAt: DateTime.parse(json['blocked_at']),
      reason: json['reason'],
    );
  }
}
