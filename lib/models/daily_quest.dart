import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class DailyQuest {
  final String id;
  final String definitionId;
  final String title;
  final String description;
  final String type; // 'complete_lessons', 'earn_xp', 'practice_vocab', 'streak', 'social'
  final int requirement;
  int progress;
  bool completed;
  final int rewardXP;
  final int rewardGems;
  final String difficulty;

  DailyQuest({
    required this.id,
    required this.definitionId,
    required this.title,
    required this.description,
    required this.type,
    required this.requirement,
    this.progress = 0,
    this.completed = false,
    required this.rewardXP,
    required this.rewardGems,
    required this.difficulty,
  });

  factory DailyQuest.fromJson(Map<String, dynamic> json) {
    return DailyQuest(
      id: json['id'],
      definitionId: json['definition_id'],
      title: json['title'],
      description: json['description'],
      type: json['type'],
      requirement: json['requirement'],
      progress: json['progress'] ?? 0,
      completed: json['completed'] ?? false,
      rewardXP: json['reward_xp'] ?? 0,
      rewardGems: json['reward_gems'] ?? 0,
      difficulty: json['difficulty'] ?? 'easy',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'definition_id': definitionId,
      'title': title,
      'description': description,
      'type': type,
      'requirement': requirement,
      'progress': progress,
      'completed': completed,
      'reward_xp': rewardXP,
      'reward_gems': rewardGems,
      'difficulty': difficulty,
    };
  }

  double get completionPercentage {
    if (requirement == 0) return 0.0;
    return (progress / requirement).clamp(0.0, 1.0);
  }

  void updateProgress(int amount) {
    progress += amount;
    if (progress >= requirement) {
      progress = requirement;
      completed = true;
    }
  }

  IconData get icon {
    switch (type) {
      case 'complete_lessons':
        return Icons.school;
      case 'earn_xp':
        return Icons.emoji_events;
      case 'practice_vocab':
        return Icons.menu_book;
      case 'streak':
        return Icons.local_fire_department;
      case 'social':
        return Icons.people;
      default:
        return Icons.star;
    }
  }

  Color get difficultyColor {
    switch (difficulty) {
      case 'easy':
        return AppColors.success;
      case 'medium':
        return AppColors.accentCoral;
      case 'hard':
        return AppColors.error;
      default:
        return AppColors.primaryTeal;
    }
  }
}

class DailyQuestsData {
  final String id;
  final String userId;
  final DateTime questDate;
  final List<DailyQuest> quests;
  final List<DailyQuest> completedQuests;
  bool claimedRewards;
  int totalXPEarned;
  int totalGemsEarned;

  DailyQuestsData({
    required this.id,
    required this.userId,
    required this.questDate,
    this.quests = const [],
    this.completedQuests = const [],
    this.claimedRewards = false,
    this.totalXPEarned = 0,
    this.totalGemsEarned = 0,
  });

  factory DailyQuestsData.fromJson(Map<String, dynamic> json) {
    var questsList = (json['quests'] as List? ?? [])
        .map((q) => DailyQuest.fromJson(q))
        .toList();
    var completedList = (json['completed_quests'] as List? ?? [])
        .map((q) => DailyQuest.fromJson(q))
        .toList();

    return DailyQuestsData(
      id: json['id'],
      userId: json['user_id'],
      questDate: DateTime.parse(json['quest_date']),
      quests: questsList,
      completedQuests: completedList,
      claimedRewards: json['claimed_rewards'] ?? false,
      totalXPEarned: json['total_xp_earned'] ?? 0,
      totalGemsEarned: json['total_gems_earned'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'quest_date': questDate.toIso8601String(),
      'quests': quests.map((q) => q.toJson()).toList(),
      'completed_quests': completedQuests.map((q) => q.toJson()).toList(),
      'claimed_rewards': claimedRewards,
      'total_xp_earned': totalXPEarned,
      'total_gems_earned': totalGemsEarned,
    };
  }

  int get totalQuests => quests.length;
  int get completedQuestsCount => completedQuests.length;
  
  double get completionPercentage {
    if (totalQuests == 0) return 0.0;
    return completedQuestsCount / totalQuests;
  }

  bool get allQuestsCompleted => completedQuestsCount == totalQuests;

  void claimRewards() {
    if (allQuestsCompleted && !claimedRewards) {
      for (var quest in completedQuests) {
        totalXPEarned += quest.rewardXP;
        totalGemsEarned += quest.rewardGems;
      }
      claimedRewards = true;
    }
  }
}

class Achievement {
  final String id;
  final String achievementId;
  final DateTime unlockedAt;
  final String tier; // 'bronze', 'silver', 'gold', 'platinum'
  final int progressPercentage;
  bool isNew;
  DateTime? viewedAt;

  Achievement({
    required this.id,
    required this.achievementId,
    required this.unlockedAt,
    required this.tier,
    this.progressPercentage = 100,
    this.isNew = true,
    this.viewedAt,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'],
      achievementId: json['achievement_id'],
      unlockedAt: DateTime.parse(json['unlocked_at']),
      tier: json['tier'],
      progressPercentage: json['progress_percentage'] ?? 100,
      isNew: json['is_new'] ?? true,
      viewedAt: json['viewed_at'] != null 
          ? DateTime.parse(json['viewed_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'achievement_id': achievementId,
      'unlocked_at': unlockedAt.toIso8601String(),
      'tier': tier,
      'progress_percentage': progressPercentage,
      'is_new': isNew,
      'viewed_at': viewedAt?.toIso8601String(),
    };
  }

  void markAsViewed() {
    isNew = false;
    viewedAt = DateTime.now();
  }

  Color get tierColor {
    switch (tier) {
      case 'bronze':
        return AppColors.bronze;
      case 'silver':
        return AppColors.silver;
      case 'gold':
        return AppColors.gold;
      case 'platinum':
        return AppColors.platinum;
      default:
        return AppColors.neutralMid;
    }
  }

  int get tierLevel {
    switch (tier) {
      case 'bronze':
        return 1;
      case 'silver':
        return 2;
      case 'gold':
        return 3;
      case 'platinum':
        return 4;
      default:
        return 0;
    }
  }
}

class AchievementDefinition {
  final String id;
  final String title;
  final String description;
  final String category; // 'learning', 'competition', 'social', 'consistency', 'explorer'
  final String? iconUrl;
  final List<AchievementTier> tiers;
  final bool isActive;

  AchievementDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    this.iconUrl,
    required this.tiers,
    this.isActive = true,
  });

  factory AchievementDefinition.fromJson(Map<String, dynamic> json) {
    return AchievementDefinition(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      category: json['category'],
      iconUrl: json['icon_url'],
      tiers: (json['tiers'] as List)
          .map((t) => AchievementTier.fromJson(t))
          .toList(),
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'icon_url': iconUrl,
      'tiers': tiers.map((t) => t.toJson()).toList(),
      'is_active': isActive,
    };
  }

  IconData get categoryIcon {
    switch (category) {
      case 'learning':
        return Icons.school;
      case 'competition':
        return Icons.emoji_events;
      case 'social':
        return Icons.people;
      case 'consistency':
        return Icons.calendar_today;
      case 'explorer':
        return Icons.explore;
      default:
        return Icons.star;
    }
  }
}

class AchievementTier {
  final String tier; // 'bronze', 'silver', 'gold', 'platinum'
  final int requirement;
  final int reward;

  AchievementTier({
    required this.tier,
    required this.requirement,
    required this.reward,
  });

  factory AchievementTier.fromJson(Map<String, dynamic> json) {
    return AchievementTier(
      tier: json['tier'],
      requirement: json['requirement'],
      reward: json['reward'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tier': tier,
      'requirement': requirement,
      'reward': reward,
    };
  }
}

class StreakData {
  final String id;
  final String userId;
  int currentStreak;
  int longestStreak;
  int streakFreezeCount;
  DateTime? lastStreakDate;
  final List<Map<String, dynamic>> streakHistory;
  final List<DateTime> freezeUsedDates;
  bool isWeekendProtectionEnabled;

  StreakData({
    required this.id,
    required this.userId,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.streakFreezeCount = 0,
    this.lastStreakDate,
    this.streakHistory = const [],
    this.freezeUsedDates = const [],
    this.isWeekendProtectionEnabled = false,
  });

  factory StreakData.fromJson(Map<String, dynamic> json) {
    return StreakData(
      id: json['id'],
      userId: json['user_id'],
      currentStreak: json['current_streak'] ?? 0,
      longestStreak: json['longest_streak'] ?? 0,
      streakFreezeCount: json['streak_freeze_count'] ?? 0,
      lastStreakDate: json['last_streak_date'] != null 
          ? DateTime.parse(json['last_streak_date']) 
          : null,
      streakHistory: List<Map<String, dynamic>>.from(json['streak_history'] ?? []),
      freezeUsedDates: (json['freeze_used_dates'] as List? ?? [])
          .map((d) => DateTime.parse(d))
          .toList(),
      isWeekendProtectionEnabled: json['is_weekend_protection_enabled'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'streak_freeze_count': streakFreezeCount,
      'last_streak_date': lastStreakDate?.toIso8601String(),
      'streak_history': streakHistory,
      'freeze_used_dates': freezeUsedDates.map((d) => d.toIso8601String()).toList(),
      'is_weekend_protection_enabled': isWeekendProtectionEnabled,
    };
  }

  bool get hasStreakToday {
    if (lastStreakDate == null) return false;
    final today = DateTime.now();
    return lastStreakDate!.year == today.year &&
           lastStreakDate!.month == today.month &&
           lastStreakDate!.day == today.day;
  }

  bool get isStreakAtRisk {
    if (lastStreakDate == null || currentStreak == 0) return false;
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return lastStreakDate!.year != yesterday.year ||
           lastStreakDate!.month != yesterday.month ||
           lastStreakDate!.day != yesterday.day;
  }

  bool canUseStreakFreeze(DateTime date) {
    return streakFreezeCount > 0 && 
           !freezeUsedDates.any((d) => 
             d.year == date.year && d.month == date.month && d.day == date.day);
  }
}

class StreakRecoveryChallenge {
  final String id;
  final String userId;
  final String challengeType; // 'perfect_lesson', 'xp_marathon', 'vocabulary_sprint'
  final Map<String, dynamic> requirements;
  bool isCompleted;
  DateTime? completedAt;
  bool streakRestored;
  final DateTime createdAt;
  final DateTime expiresAt;

  StreakRecoveryChallenge({
    required this.id,
    required this.userId,
    required this.challengeType,
    required this.requirements,
    this.isCompleted = false,
    this.completedAt,
    this.streakRestored = false,
    required this.createdAt,
    required this.expiresAt,
  });

  factory StreakRecoveryChallenge.fromJson(Map<String, dynamic> json) {
    return StreakRecoveryChallenge(
      id: json['id'],
      userId: json['user_id'],
      challengeType: json['challenge_type'],
      requirements: json['requirements'] ?? {},
      isCompleted: json['is_completed'] ?? false,
      completedAt: json['completed_at'] != null 
          ? DateTime.parse(json['completed_at']) 
          : null,
      streakRestored: json['streak_restored'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      expiresAt: DateTime.parse(json['expires_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'challenge_type': challengeType,
      'requirements': requirements,
      'is_completed': isCompleted,
      'completed_at': completedAt?.toIso8601String(),
      'streak_restored': streakRestored,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
    };
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  String get description {
    switch (challengeType) {
      case 'perfect_lesson':
        return 'Complete a lesson with 100% accuracy';
      case 'xp_marathon':
        return 'Earn ${requirements['xp_amount'] ?? 50} XP today';
      case 'vocabulary_sprint':
        return 'Review ${requirements['vocab_count'] ?? 10} vocabulary words';
      default:
        return 'Complete the challenge to restore your streak!';
    }
  }
}

class WeeklyChallenge {
  final String id;
  final DateTime weekStartDate;
  final DateTime weekEndDate;
  final String title;
  final String? description;
  final String challengeType;
  final Map<String, dynamic> requirements;
  final int? rewardXP;
  final int? rewardGems;
  final String? rewardBadgeId;
  int participantsCount;
  final bool isActive;
  final DateTime createdAt;

  WeeklyChallenge({
    required this.id,
    required this.weekStartDate,
    required this.weekEndDate,
    required this.title,
    this.description,
    required this.challengeType,
    required this.requirements,
    this.rewardXP,
    this.rewardGems,
    this.rewardBadgeId,
    this.participantsCount = 0,
    this.isActive = true,
    required this.createdAt,
  });

  factory WeeklyChallenge.fromJson(Map<String, dynamic> json) {
    return WeeklyChallenge(
      id: json['id'],
      weekStartDate: DateTime.parse(json['week_start_date']),
      weekEndDate: DateTime.parse(json['week_end_date']),
      title: json['title'],
      description: json['description'],
      challengeType: json['challenge_type'],
      requirements: json['requirements'] ?? {},
      rewardXP: json['reward_xp'],
      rewardGems: json['reward_gems'],
      rewardBadgeId: json['reward_badge_id'],
      participantsCount: json['participants_count'] ?? 0,
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'week_start_date': weekStartDate.toIso8601String(),
      'week_end_date': weekEndDate.toIso8601String(),
      'title': title,
      'description': description,
      'challenge_type': challengeType,
      'requirements': requirements,
      'reward_xp': rewardXP,
      'reward_gems': rewardGems,
      'reward_badge_id': rewardBadgeId,
      'participants_count': participantsCount,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isCurrentWeek {
    final now = DateTime.now();
    return now.isAfter(weekStartDate) && now.isBefore(weekEndDate);
  }
}
