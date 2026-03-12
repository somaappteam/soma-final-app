
/// Community features models
class UserDeck {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatarUrl;
  final String title;
  final String description;
  final String language;
  final String? nativeLanguage;
  final List<DeckCard> cards;
  final List<String> tags;
  final bool isPublic;
  final int downloadCount;
  final double? averageRating;
  final int? totalRatings;
  final DateTime createdAt;
  DateTime updatedAt;

  UserDeck({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatarUrl,
    required this.title,
    required this.description,
    required this.language,
    this.nativeLanguage,
    this.cards = const [],
    this.tags = const [],
    this.isPublic = true,
    this.downloadCount = 0,
    this.averageRating,
    this.totalRatings,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserDeck.fromJson(Map<String, dynamic> json) {
    return UserDeck(
      id: json['id'],
      userId: json['user_id'],
      userName: json['user_name'],
      userAvatarUrl: json['user_avatar_url'],
      title: json['title'],
      description: json['description'],
      language: json['language'],
      nativeLanguage: json['native_language'],
      cards: (json['cards'] as List? ?? [])
          .map((c) => DeckCard.fromJson(c))
          .toList(),
      tags: List<String>.from(json['tags'] ?? []),
      isPublic: json['is_public'] ?? true,
      downloadCount: json['download_count'] ?? 0,
      averageRating: json['average_rating']?.toDouble(),
      totalRatings: json['total_ratings'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'user_avatar_url': userAvatarUrl,
      'title': title,
      'description': description,
      'language': language,
      'native_language': nativeLanguage,
      'cards': cards.map((c) => c.toJson()).toList(),
      'tags': tags,
      'is_public': isPublic,
      'download_count': downloadCount,
      'average_rating': averageRating,
      'total_ratings': totalRatings,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  int get cardCount => cards.length;
}

class DeckCard {
  final String id;
  final String front;
  final String back;
  final String? example;
  final String? pronunciation;
  final String? imageUrl;
  final int difficultyLevel;

  DeckCard({
    required this.id,
    required this.front,
    required this.back,
    this.example,
    this.pronunciation,
    this.imageUrl,
    this.difficultyLevel = 1,
  });

  factory DeckCard.fromJson(Map<String, dynamic> json) {
    return DeckCard(
      id: json['id'],
      front: json['front'],
      back: json['back'],
      example: json['example'],
      pronunciation: json['pronunciation'],
      imageUrl: json['image_url'],
      difficultyLevel: json['difficulty_level'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'front': front,
      'back': back,
      'example': example,
      'pronunciation': pronunciation,
      'image_url': imageUrl,
      'difficulty_level': difficultyLevel,
    };
  }
}

class StudyNote {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatarUrl;
  final String title;
  final String content;
  final String? language;
  final List<String> tags;
  final int likesCount;
  final int commentsCount;
  final bool isPublic;
  final DateTime createdAt;
  DateTime updatedAt;

  StudyNote({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatarUrl,
    required this.title,
    required this.content,
    this.language,
    this.tags = const [],
    this.likesCount = 0,
    this.commentsCount = 0,
    this.isPublic = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory StudyNote.fromJson(Map<String, dynamic> json) {
    return StudyNote(
      id: json['id'],
      userId: json['user_id'],
      userName: json['user_name'],
      userAvatarUrl: json['user_avatar_url'],
      title: json['title'],
      content: json['content'],
      language: json['language'],
      tags: List<String>.from(json['tags'] ?? []),
      likesCount: json['likes_count'] ?? 0,
      commentsCount: json['comments_count'] ?? 0,
      isPublic: json['is_public'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'user_avatar_url': userAvatarUrl,
      'title': title,
      'content': content,
      'language': language,
      'tags': tags,
      'likes_count': likesCount,
      'comments_count': commentsCount,
      'is_public': isPublic,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class LanguageExchangePartner {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatarUrl;
  final String nativeLanguage;
  final List<String> learningLanguages;
  final String? bio;
  final List<String> interests;
  final String proficiencyLevel; // 'beginner', 'intermediate', 'advanced'
  final String? timezone;
  final List<String> availability; // e.g., ['weekday_morning', 'weekend_evening']
  final bool isAvailableNow;
  final DateTime? lastActive;
  final int mutualFriends;
  final double? matchScore;

  LanguageExchangePartner({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatarUrl,
    required this.nativeLanguage,
    required this.learningLanguages,
    this.bio,
    this.interests = const [],
    required this.proficiencyLevel,
    this.timezone,
    this.availability = const [],
    this.isAvailableNow = false,
    this.lastActive,
    this.mutualFriends = 0,
    this.matchScore,
  });

  factory LanguageExchangePartner.fromJson(Map<String, dynamic> json) {
    return LanguageExchangePartner(
      id: json['id'],
      userId: json['user_id'],
      userName: json['user_name'],
      userAvatarUrl: json['user_avatar_url'],
      nativeLanguage: json['native_language'],
      learningLanguages: List<String>.from(json['learning_languages'] ?? []),
      bio: json['bio'],
      interests: List<String>.from(json['interests'] ?? []),
      proficiencyLevel: json['proficiency_level'] ?? 'beginner',
      timezone: json['timezone'],
      availability: List<String>.from(json['availability'] ?? []),
      isAvailableNow: json['is_available_now'] ?? false,
      lastActive: json['last_active'] != null
          ? DateTime.parse(json['last_active'])
          : null,
      mutualFriends: json['mutual_friends'] ?? 0,
      matchScore: json['match_score']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'user_avatar_url': userAvatarUrl,
      'native_language': nativeLanguage,
      'learning_languages': learningLanguages,
      'bio': bio,
      'interests': interests,
      'proficiency_level': proficiencyLevel,
      'timezone': timezone,
      'availability': availability,
      'is_available_now': isAvailableNow,
      'last_active': lastActive?.toIso8601String(),
      'mutual_friends': mutualFriends,
      'match_score': matchScore,
    };
  }
}

class CommunityChallenge {
  final String id;
  final String title;
  final String description;
  final String type; // 'streak', 'xp', 'vocabulary', 'grammar', 'social'
  final String difficulty;
  final DateTime startDate;
  final DateTime endDate;
  final int targetValue;
  final int participantCount;
  final int completedCount;
  final int xpReward;
  final String? badgeId;
  final bool isActive;
  final List<ChallengeLeader> leaderboard;

  CommunityChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.difficulty,
    required this.startDate,
    required this.endDate,
    required this.targetValue,
    this.participantCount = 0,
    this.completedCount = 0,
    required this.xpReward,
    this.badgeId,
    this.isActive = true,
    this.leaderboard = const [],
  });

  factory CommunityChallenge.fromJson(Map<String, dynamic> json) {
    return CommunityChallenge(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      type: json['type'],
      difficulty: json['difficulty'],
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      targetValue: json['target_value'],
      participantCount: json['participant_count'] ?? 0,
      completedCount: json['completed_count'] ?? 0,
      xpReward: json['xp_reward'],
      badgeId: json['badge_id'],
      isActive: json['is_active'] ?? true,
      leaderboard: (json['leaderboard'] as List? ?? [])
          .map((l) => ChallengeLeader.fromJson(l))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type,
      'difficulty': difficulty,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'target_value': targetValue,
      'participant_count': participantCount,
      'completed_count': completedCount,
      'xp_reward': xpReward,
      'badge_id': badgeId,
      'is_active': isActive,
      'leaderboard': leaderboard.map((l) => l.toJson()).toList(),
    };
  }

  bool get isOngoing {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate) && isActive;
  }

  String get timeRemaining {
    final now = DateTime.now();
    if (now.isAfter(endDate)) return 'Ended';
    
    final difference = endDate.difference(now);
    if (difference.inDays > 0) {
      return '${difference.inDays}d ${difference.inHours % 24}h';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ${difference.inMinutes % 60}m';
    } else {
      return '${difference.inMinutes}m';
    }
  }
}

class ChallengeLeader {
  final String userId;
  final String userName;
  final String? userAvatarUrl;
  final int rank;
  final int currentValue;
  final double progressPercentage;

  ChallengeLeader({
    required this.userId,
    required this.userName,
    this.userAvatarUrl,
    required this.rank,
    required this.currentValue,
    required this.progressPercentage,
  });

  factory ChallengeLeader.fromJson(Map<String, dynamic> json) {
    return ChallengeLeader(
      userId: json['user_id'],
      userName: json['user_name'],
      userAvatarUrl: json['user_avatar_url'],
      rank: json['rank'],
      currentValue: json['current_value'],
      progressPercentage: (json['progress_percentage'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'user_name': userName,
      'user_avatar_url': userAvatarUrl,
      'rank': rank,
      'current_value': currentValue,
      'progress_percentage': progressPercentage,
    };
  }
}

class UserChallengeProgress {
  final String id;
  final String userId;
  final String challengeId;
  int currentValue;
  bool isCompleted;
  DateTime? completedAt;
  final DateTime joinedAt;
  DateTime updatedAt;

  UserChallengeProgress({
    required this.id,
    required this.userId,
    required this.challengeId,
    this.currentValue = 0,
    this.isCompleted = false,
    this.completedAt,
    required this.joinedAt,
    required this.updatedAt,
  });

  factory UserChallengeProgress.fromJson(Map<String, dynamic> json) {
    return UserChallengeProgress(
      id: json['id'],
      userId: json['user_id'],
      challengeId: json['challenge_id'],
      currentValue: json['current_value'] ?? 0,
      isCompleted: json['is_completed'] ?? false,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      joinedAt: DateTime.parse(json['joined_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'challenge_id': challengeId,
      'current_value': currentValue,
      'is_completed': isCompleted,
      'completed_at': completedAt?.toIso8601String(),
      'joined_at': joinedAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  double get progressPercentage {
    // Will be calculated based on challenge target
    return 0.0;
  }
}
