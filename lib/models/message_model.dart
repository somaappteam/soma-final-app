class MessageModel {
  final String id;
  final String senderId;
  final String senderUsername;
  final String? senderAvatarUrl;
  final String receiverId;
  final String content;
  final DateTime createdAt;
  final bool isRead;
  final DateTime? readAt;
  final bool isDeleted;
  final bool isEdited;
  final DateTime? editedAt;
  final String? replyToMessageId;
  final String? replyToContent;
  final List<MessageAttachment>? attachments;
  final List<MessageReaction>? reactions;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.senderUsername,
    this.senderAvatarUrl,
    required this.receiverId,
    required this.content,
    required this.createdAt,
    this.isRead = false,
    this.readAt,
    this.isDeleted = false,
    this.isEdited = false,
    this.editedAt,
    this.replyToMessageId,
    this.replyToContent,
    this.attachments,
    this.reactions,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'],
      senderId: json['sender_id'],
      senderUsername: json['sender_username'],
      senderAvatarUrl: json['sender_avatar_url'],
      receiverId: json['receiver_id'],
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']),
      isRead: json['is_read'] ?? false,
      readAt: json['read_at'] != null
          ? DateTime.parse(json['read_at'])
          : null,
      isDeleted: json['is_deleted'] ?? false,
      isEdited: json['is_edited'] ?? false,
      editedAt: json['edited_at'] != null
          ? DateTime.parse(json['edited_at'])
          : null,
      replyToMessageId: json['reply_to_message_id'],
      replyToContent: json['reply_to_content'],
      attachments: json['attachments'] != null
          ? (json['attachments'] as List)
              .map((a) => MessageAttachment.fromJson(a))
              .toList()
          : null,
      reactions: json['reactions'] != null
          ? (json['reactions'] as List)
              .map((r) => MessageReaction.fromJson(r))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'sender_username': senderUsername,
      'sender_avatar_url': senderAvatarUrl,
      'receiver_id': receiverId,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead,
      'read_at': readAt?.toIso8601String(),
      'is_deleted': isDeleted,
      'is_edited': isEdited,
      'edited_at': editedAt?.toIso8601String(),
      'reply_to_message_id': replyToMessageId,
      'reply_to_content': replyToContent,
    };
  }
}

class MessageAttachment {
  final String id;
  final String type;
  final String url;
  final String? filename;
  final int? fileSize;
  final String? mimeType;

  MessageAttachment({
    required this.id,
    required this.type,
    required this.url,
    this.filename,
    this.fileSize,
    this.mimeType,
  });

  factory MessageAttachment.fromJson(Map<String, dynamic> json) {
    return MessageAttachment(
      id: json['id'],
      type: json['type'],
      url: json['url'],
      filename: json['filename'],
      fileSize: json['file_size'],
      mimeType: json['mime_type'],
    );
  }
}

class MessageReaction {
  final String userId;
  final String emoji;
  final DateTime createdAt;

  MessageReaction({
    required this.userId,
    required this.emoji,
    required this.createdAt,
  });

  factory MessageReaction.fromJson(Map<String, dynamic> json) {
    return MessageReaction(
      userId: json['user_id'],
      emoji: json['emoji'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class ConversationModel {
  final String id;
  final String participant1Id;
  final String participant2Id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final MessageModel? lastMessage;
  final int unreadCount;
  final bool isArchived;
  final bool isMuted;
  final UserInfo? otherUser;

  ConversationModel({
    required this.id,
    required this.participant1Id,
    required this.participant2Id,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessage,
    this.unreadCount = 0,
    this.isArchived = false,
    this.isMuted = false,
    this.otherUser,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'],
      participant1Id: json['participant1_id'],
      participant2Id: json['participant2_id'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      lastMessage: json['last_message'] != null
          ? MessageModel.fromJson(json['last_message'])
          : null,
      unreadCount: json['unread_count'] ?? 0,
      isArchived: json['is_archived'] ?? false,
      isMuted: json['is_muted'] ?? false,
      otherUser: json['other_user'] != null
          ? UserInfo.fromJson(json['other_user'])
          : null,
    );
  }
}

class UserInfo {
  final String id;
  final String username;
  final String? displayName;
  final String? avatarUrl;
  final bool isOnline;
  final DateTime? lastSeenAt;

  UserInfo({
    required this.id,
    required this.username,
    this.displayName,
    this.avatarUrl,
    this.isOnline = false,
    this.lastSeenAt,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: json['id'],
      username: json['username'],
      displayName: json['display_name'],
      avatarUrl: json['avatar_url'],
      isOnline: json['is_online'] ?? false,
      lastSeenAt: json['last_seen_at'] != null
          ? DateTime.parse(json['last_seen_at'])
          : null,
    );
  }
}

class InboxSummary {
  final int totalConversations;
  final int totalUnread;
  final List<ConversationModel> conversations;
  final DateTime lastUpdated;

  InboxSummary({
    required this.totalConversations,
    required this.totalUnread,
    required this.conversations,
    required this.lastUpdated,
  });

  factory InboxSummary.fromJson(Map<String, dynamic> json) {
    return InboxSummary(
      totalConversations: json['total_conversations'],
      totalUnread: json['total_unread'],
      conversations: (json['conversations'] as List)
          .map((c) => ConversationModel.fromJson(c))
          .toList(),
      lastUpdated: DateTime.parse(json['last_updated']),
    );
  }
}
