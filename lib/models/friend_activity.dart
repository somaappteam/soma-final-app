import 'package:flutter/material.dart';

class FriendActivity {
  final String id;
  final String userId;
  final String activityType; // 'lesson_completed', 'achievement_unlocked', 'streak_milestone', 'level_up', 'competition_won'
  final Map<String, dynamic> activityData;
  final bool isPublic;
  final DateTime createdAt;
  
  // Aggregated fields (not from DB)
  int likesCount;
  int commentsCount;
  bool isLikedByCurrentUser;

  FriendActivity({
    required this.id,
    required this.userId,
    required this.activityType,
    required this.activityData,
    this.isPublic = true,
    required this.createdAt,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.isLikedByCurrentUser = false,
  });

  factory FriendActivity.fromJson(Map<String, dynamic> json) {
    return FriendActivity(
      id: json['id'],
      userId: json['user_id'],
      activityType: json['activity_type'],
      activityData: json['activity_data'] ?? {},
      isPublic: json['is_public'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      likesCount: json['likes_count'] ?? 0,
      commentsCount: json['comments_count'] ?? 0,
      isLikedByCurrentUser: json['is_liked_by_current_user'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'activity_type': activityType,
      'activity_data': activityData,
      'is_public': isPublic,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get activityMessage {
    switch (activityType) {
      case 'lesson_completed':
        final lessonTitle = activityData['lesson_title'] ?? 'a lesson';
        final score = activityData['score'];
        return score != null 
            ? 'Completed "$lessonTitle" with $score% accuracy'
            : 'Completed "$lessonTitle"';
      
      case 'achievement_unlocked':
        final achievementTitle = activityData['achievement_title'] ?? 'an achievement';
        final tier = activityData['tier'];
        return tier != null 
            ? 'Unlocked $tier achievement: $achievementTitle'
            : 'Unlocked achievement: $achievementTitle';
      
      case 'streak_milestone':
        final streakDays = activityData['streak_days'] ?? 0;
        return 'Reached a $streakDays-day streak! 🔥';
      
      case 'level_up':
        final newLevel = activityData['new_level'] ?? 0;
        return 'Leveled up to Level $newLevel!';
      
      case 'competition_won':
        final competitionName = activityData['competition_name'] ?? 'a competition';
        final rank = activityData['rank'];
        return rank != null 
            ? 'Won $competitionName (Rank #$rank)'
            : 'Won $competitionName';
      
      case 'vocabulary_milestone':
        final wordCount = activityData['word_count'] ?? 0;
        return 'Learned $wordCount words!';
      
      case 'story_completed':
        final storyTitle = activityData['story_title'] ?? 'a story';
        return 'Completed "$storyTitle"';
      
      default:
        return 'Made progress in learning!';
    }
  }

  IconData get activityIcon {
    switch (activityType) {
      case 'lesson_completed':
        return Icons.school;
      case 'achievement_unlocked':
        return Icons.emoji_events;
      case 'streak_milestone':
        return Icons.local_fire_department;
      case 'level_up':
        return Icons.trending_up;
      case 'competition_won':
        return Icons.military_tech;
      case 'vocabulary_milestone':
        return Icons.menu_book;
      case 'story_completed':
        return Icons.auto_stories;
      default:
        return Icons.star;
    }
  }

  Color get activityColor {
    switch (activityType) {
      case 'lesson_completed':
        return Colors.blue;
      case 'achievement_unlocked':
        return Colors.amber;
      case 'streak_milestone':
        return Colors.orange;
      case 'level_up':
        return Colors.green;
      case 'competition_won':
        return Colors.purple;
      case 'vocabulary_milestone':
        return Colors.teal;
      case 'story_completed':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }
}

class ActivityLike {
  final String id;
  final String activityId;
  final String userId;
  final DateTime createdAt;

  ActivityLike({
    required this.id,
    required this.activityId,
    required this.userId,
    required this.createdAt,
  });

  factory ActivityLike.fromJson(Map<String, dynamic> json) {
    return ActivityLike(
      id: json['id'],
      activityId: json['activity_id'],
      userId: json['user_id'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'activity_id': activityId,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class ActivityComment {
  final String id;
  final String activityId;
  final String userId;
  String comment;
  final DateTime createdAt;
  DateTime updatedAt;

  ActivityComment({
    required this.id,
    required this.activityId,
    required this.userId,
    required this.comment,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ActivityComment.fromJson(Map<String, dynamic> json) {
    return ActivityComment(
      id: json['id'],
      activityId: json['activity_id'],
      userId: json['user_id'],
      comment: json['comment'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'activity_id': activityId,
      'user_id': userId,
      'comment': comment,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  void updateComment(String newComment) {
    comment = newComment;
    updatedAt = DateTime.now();
  }
}

class ActivityFeedFilter {
  final List<String>? activityTypes;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool? onlyFriends;
  final int limit;

  ActivityFeedFilter({
    this.activityTypes,
    this.startDate,
    this.endDate,
    this.onlyFriends = true,
    this.limit = 20,
  });

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{
      'limit': limit,
    };

    if (activityTypes != null && activityTypes!.isNotEmpty) {
      params['activity_types'] = activityTypes;
    }

    if (startDate != null) {
      params['start_date'] = startDate!.toIso8601String();
    }

    if (endDate != null) {
      params['end_date'] = endDate!.toIso8601String();
    }

    if (onlyFriends != null) {
      params['only_friends'] = onlyFriends;
    }

    return params;
  }
}
