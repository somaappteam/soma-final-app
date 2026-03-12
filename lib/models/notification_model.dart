class NotificationModel {
  final String id;
  final String userId;
  final String type;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;
  final DateTime? readAt;
  final bool isArchived;
  final Map<String, dynamic>? data;
  final String? imageUrl;
  final String? actionUrl;
  final String? senderId;
  final String? senderName;
  final String? senderAvatarUrl;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.isRead = false,
    this.readAt,
    this.isArchived = false,
    this.data,
    this.imageUrl,
    this.actionUrl,
    this.senderId,
    this.senderName,
    this.senderAvatarUrl,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      userId: json['user_id'],
      type: json['type'],
      title: json['title'],
      body: json['body'],
      createdAt: DateTime.parse(json['created_at']),
      isRead: json['is_read'] ?? false,
      readAt: json['read_at'] != null
          ? DateTime.parse(json['read_at'])
          : null,
      isArchived: json['is_archived'] ?? false,
      data: json['data'],
      imageUrl: json['image_url'],
      actionUrl: json['action_url'],
      senderId: json['sender_id'],
      senderName: json['sender_name'],
      senderAvatarUrl: json['sender_avatar_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type,
      'title': title,
      'body': body,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead,
      'read_at': readAt?.toIso8601String(),
      'is_archived': isArchived,
      'data': data,
      'image_url': imageUrl,
      'action_url': actionUrl,
      'sender_id': senderId,
      'sender_name': senderName,
      'sender_avatar_url': senderAvatarUrl,
    };
  }
}

class NotificationPreferences {
  final bool gameInvites;
  final bool friendRequests;
  final bool messages;
  final bool gameStarted;
  final bool gameEnded;
  final bool achievements;
  final bool leaderboard;
  final bool dailyReminders;
  final bool appUpdates;
  final bool promotional;
  final bool emailNotifications;
  final bool pushNotifications;
  final bool inAppNotifications;

  NotificationPreferences({
    this.gameInvites = true,
    this.friendRequests = true,
    this.messages = true,
    this.gameStarted = true,
    this.gameEnded = true,
    this.achievements = true,
    this.leaderboard = true,
    this.dailyReminders = true,
    this.appUpdates = true,
    this.promotional = true,
    this.emailNotifications = true,
    this.pushNotifications = true,
    this.inAppNotifications = true,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      gameInvites: json['game_invites'] ?? true,
      friendRequests: json['friend_requests'] ?? true,
      messages: json['messages'] ?? true,
      gameStarted: json['game_started'] ?? true,
      gameEnded: json['game_ended'] ?? true,
      achievements: json['achievements'] ?? true,
      leaderboard: json['leaderboard'] ?? true,
      dailyReminders: json['daily_reminders'] ?? true,
      appUpdates: json['app_updates'] ?? true,
      promotional: json['promotional'] ?? true,
      emailNotifications: json['email_notifications'] ?? true,
      pushNotifications: json['push_notifications'] ?? true,
      inAppNotifications: json['in_app_notifications'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'game_invites': gameInvites,
      'friend_requests': friendRequests,
      'messages': messages,
      'game_started': gameStarted,
      'game_ended': gameEnded,
      'achievements': achievements,
      'leaderboard': leaderboard,
      'daily_reminders': dailyReminders,
      'app_updates': appUpdates,
      'promotional': promotional,
      'email_notifications': emailNotifications,
      'push_notifications': pushNotifications,
      'in_app_notifications': inAppNotifications,
    };
  }
}

class NotificationCount {
  final int total;
  final int unread;
  final Map<String, int> byType;

  NotificationCount({
    required this.total,
    required this.unread,
    required this.byType,
  });

  factory NotificationCount.fromJson(Map<String, dynamic> json) {
    return NotificationCount(
      total: json['total'],
      unread: json['unread'],
      byType: Map<String, int>.from(json['by_type'] ?? {}),
    );
  }
}
