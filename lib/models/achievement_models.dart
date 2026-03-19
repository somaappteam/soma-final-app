import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Achievement categories
enum AchievementCategory {
  general,
  streak,
  vocabulary,
  grammar,
  reading,
  listening,
  speaking,
  writing,
  social,
  mastery;

  Color get color {
    switch (this) {
      case AchievementCategory.general:
        return AppColors.primaryTeal;
      case AchievementCategory.streak:
        return AppColors.accentCoral;
      case AchievementCategory.vocabulary:
        return AppColors.success;
      case AchievementCategory.grammar:
        return AppColors.darkAccentPurple;
      case AchievementCategory.reading:
        return Colors.teal;
      case AchievementCategory.listening:
        return Colors.indigo;
      case AchievementCategory.speaking:
        return AppColors.error;
      case AchievementCategory.writing:
        return Colors.brown;
      case AchievementCategory.social:
        return Colors.pink;
      case AchievementCategory.mastery:
        return AppColors.accentOrange;
    }
  }

  IconData get icon {
    switch (this) {
      case AchievementCategory.general:
        return Icons.star;
      case AchievementCategory.streak:
        return Icons.local_fire_department;
      case AchievementCategory.vocabulary:
        return Icons.book;
      case AchievementCategory.grammar:
        return Icons.school;
      case AchievementCategory.reading:
        return Icons.menu_book;
      case AchievementCategory.listening:
        return Icons.headphones;
      case AchievementCategory.speaking:
        return Icons.mic;
      case AchievementCategory.writing:
        return Icons.edit;
      case AchievementCategory.social:
        return Icons.people;
      case AchievementCategory.mastery:
        return Icons.emoji_events;
    }
  }

  String get displayName {
    switch (this) {
      case AchievementCategory.general:
        return 'General';
      case AchievementCategory.streak:
        return 'Streak';
      case AchievementCategory.vocabulary:
        return 'Vocabulary';
      case AchievementCategory.grammar:
        return 'Grammar';
      case AchievementCategory.reading:
        return 'Reading';
      case AchievementCategory.listening:
        return 'Listening';
      case AchievementCategory.speaking:
        return 'Speaking';
      case AchievementCategory.writing:
        return 'Writing';
      case AchievementCategory.social:
        return 'Social';
      case AchievementCategory.mastery:
        return 'Mastery';
    }
  }
}

/// Achievement tiers with properties
enum AchievementTier {
  bronze,
  silver,
  gold,
  platinum,
  diamond,
  legendary;

  Color get color {
    switch (this) {
      case AchievementTier.bronze:
        return AppColors.bronze;
      case AchievementTier.silver:
        return AppColors.silver;
      case AchievementTier.gold:
        return AppColors.gold;
      case AchievementTier.platinum:
        return AppColors.platinum;
      case AchievementTier.diamond:
        return AppColors.diamond;
      case AchievementTier.legendary:
        return AppColors.vibrantOrange;
    }
  }

  String get displayName {
    switch (this) {
      case AchievementTier.bronze:
        return 'Bronze';
      case AchievementTier.silver:
        return 'Silver';
      case AchievementTier.gold:
        return 'Gold';
      case AchievementTier.platinum:
        return 'Platinum';
      case AchievementTier.diamond:
        return 'Diamond';
      case AchievementTier.legendary:
        return 'Legendary';
    }
  }
}

/// Represents an achievement
class Achievement {
  final String id;
  final String title;
  final String description;
  final AchievementCategory category;
  final AchievementTier tier;
  final String icon; // Emoji or icon identifier as string
  final Color color;
  final int requirement;
  final int progress;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final int xpReward;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.tier,
    required this.icon,
    required this.color,
    required this.requirement,
    this.progress = 0,
    this.isUnlocked = false,
    this.unlockedAt,
    this.xpReward = 0,
  });

  /// Get IconData from string icon name
  IconData get iconData {
    // Map of common icon names to IconData
    final iconMap = {
      'star': Icons.star,
      'local_fire_department': Icons.local_fire_department,
      'book': Icons.book,
      'school': Icons.school,
      'menu_book': Icons.menu_book,
      'headphones': Icons.headphones,
      'mic': Icons.mic,
      'edit': Icons.edit,
      'people': Icons.people,
      'emoji_events': Icons.emoji_events,
      'bolt': Icons.bolt,
      'trending_up': Icons.trending_up,
      'schedule': Icons.schedule,
      'flag': Icons.flag,
      'diamond': Icons.diamond,
      'crown': Icons.emoji_events,
    };
    return iconMap[icon] ?? Icons.star;
  }

  // Alias getters for screen compatibility
  int get currentValue => progress;
  int get targetValue => requirement;
  double get progressPercentage => requirement > 0 ? progress / requirement : 0.0;
  String get displayDescription => description;

  bool get isNearCompletion => progressPercentage >= 0.8 && !isUnlocked;

  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    AchievementCategory? category,
    AchievementTier? tier,
    String? icon,
    Color? color,
    int? requirement,
    int? progress,
    bool? isUnlocked,
    DateTime? unlockedAt,
    int? xpReward,
  }) {
    return Achievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      tier: tier ?? this.tier,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      requirement: requirement ?? this.requirement,
      progress: progress ?? this.progress,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      xpReward: xpReward ?? this.xpReward,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category.name,
      'tier': tier.name,
      'icon': icon,
      'color': color.toARGB32(),
      'requirement': requirement,
      'progress': progress,
      'isUnlocked': isUnlocked,
      'unlockedAt': unlockedAt?.toIso8601String(),
      'xpReward': xpReward,
    };
  }

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: AchievementCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => AchievementCategory.general,
      ),
      tier: AchievementTier.values.firstWhere(
        (e) => e.name == json['tier'],
        orElse: () => AchievementTier.bronze,
      ),
      icon: json['icon'] as String? ?? 'star',
      color: Color(json['color'] as int),
      requirement: json['requirement'] as int,
      progress: json['progress'] as int? ?? 0,
      isUnlocked: json['isUnlocked'] as bool? ?? false,
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.parse(json['unlockedAt'] as String)
          : null,
      xpReward: json['xpReward'] as int? ?? 0,
    );
  }
}

/// User achievement progress
class UserAchievement {
  final String userId;
  final String achievementId;
  final int progress;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  const UserAchievement({
    required this.userId,
    required this.achievementId,
    this.progress = 0,
    this.isUnlocked = false,
    this.unlockedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'achievementId': achievementId,
      'progress': progress,
      'isUnlocked': isUnlocked,
      'unlockedAt': unlockedAt?.toIso8601String(),
    };
  }

  factory UserAchievement.fromJson(Map<String, dynamic> json) {
    return UserAchievement(
      userId: json['userId'] as String,
      achievementId: json['achievementId'] as String,
      progress: json['progress'] as int? ?? 0,
      isUnlocked: json['isUnlocked'] as bool? ?? false,
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.parse(json['unlockedAt'] as String)
          : null,
    );
  }
}

/// Badge rarity levels
enum BadgeRarity {
  common,
  rare,
  epic,
  legendary,
  limited,
}

/// Represents a badge
class Badge {
  final String id;
  final String title;
  final String description;
  final BadgeRarity rarity;
  final IconData icon;
  final Color color;
  final String? animationUrl;
  final String criteria;
  final bool isLimitedTime;
  final DateTime? availableUntil;

  const Badge({
    required this.id,
    required this.title,
    required this.description,
    required this.rarity,
    required this.icon,
    required this.color,
    this.animationUrl,
    required this.criteria,
    this.isLimitedTime = false,
    this.availableUntil,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'rarity': rarity.name,
      'icon': icon.codePoint,
      'color': color.toARGB32(),
      'animationUrl': animationUrl,
      'criteria': criteria,
      'isLimitedTime': isLimitedTime,
      'availableUntil': availableUntil?.toIso8601String(),
    };
  }

  factory Badge.fromJson(Map<String, dynamic> json) {
    return Badge(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      rarity: BadgeRarity.values.firstWhere(
        (e) => e.name == json['rarity'],
        orElse: () => BadgeRarity.common,
      ),
      icon: IconData(json['icon'] as int, fontFamily: 'MaterialIcons'),
      color: Color(json['color'] as int),
      animationUrl: json['animationUrl'] as String?,
      criteria: json['criteria'] as String,
      isLimitedTime: json['isLimitedTime'] as bool? ?? false,
      availableUntil: json['availableUntil'] != null
          ? DateTime.parse(json['availableUntil'] as String)
          : null,
    );
  }
}

/// User's earned badge
class UserBadge {
  final String userId;
  final String badgeId;
  final DateTime earnedAt;
  final bool isEquipped;

  const UserBadge({
    required this.userId,
    required this.badgeId,
    required this.earnedAt,
    this.isEquipped = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'badgeId': badgeId,
      'earnedAt': earnedAt.toIso8601String(),
      'isEquipped': isEquipped,
    };
  }

  factory UserBadge.fromJson(Map<String, dynamic> json) {
    return UserBadge(
      userId: json['userId'] as String,
      badgeId: json['badgeId'] as String,
      earnedAt: DateTime.parse(json['earnedAt'] as String),
      isEquipped: json['isEquipped'] as bool? ?? false,
    );
  }
}

/// Default achievement definitions
class AchievementDefinitions {
  static List<Achievement> get defaultAchievements => [
    // Streak achievements
    const Achievement(
      id: 'streak_7',
      title: 'Week Warrior',
      description: 'Maintain a 7-day study streak',
      category: AchievementCategory.streak,
      tier: AchievementTier.bronze,
      icon: 'local_fire_department',
      color: AppColors.accentCoral,
      requirement: 7,
      xpReward: 50,
    ),
    const Achievement(
      id: 'streak_30',
      title: 'Monthly Master',
      description: 'Maintain a 30-day study streak',
      category: AchievementCategory.streak,
      tier: AchievementTier.silver,
      icon: 'local_fire_department',
      color: AppColors.accentCoral,
      requirement: 30,
      xpReward: 200,
    ),
    const Achievement(
      id: 'streak_100',
      title: 'Century Streak',
      description: 'Maintain a 100-day study streak',
      category: AchievementCategory.streak,
      tier: AchievementTier.gold,
      icon: 'local_fire_department',
      color: AppColors.accentCoral,
      requirement: 100,
      xpReward: 1000,
    ),
    // Vocabulary achievements
    const Achievement(
      id: 'vocab_100',
      title: 'Century Club',
      description: 'Learn 100 vocabulary words',
      category: AchievementCategory.vocabulary,
      tier: AchievementTier.bronze,
      icon: 'book',
      color: AppColors.primaryTeal,
      requirement: 100,
      xpReward: 100,
    ),
    const Achievement(
      id: 'vocab_500',
      title: 'Word Hoarder',
      description: 'Learn 500 vocabulary words',
      category: AchievementCategory.vocabulary,
      tier: AchievementTier.silver,
      icon: 'book',
      color: AppColors.primaryTeal,
      requirement: 500,
      xpReward: 500,
    ),
    // Grammar achievements
    const Achievement(
      id: 'grammar_10',
      title: 'Grammar Master',
      description: 'Complete 10 grammar lessons',
      category: AchievementCategory.grammar,
      tier: AchievementTier.silver,
      icon: 'school',
      color: AppColors.darkAccentPurple,
      requirement: 10,
      xpReward: 150,
    ),
    // Speed achievements
    const Achievement(
      id: 'speed_demon',
      title: 'Speed Demon',
      description: 'Complete a speed review with 95% accuracy',
      category: AchievementCategory.general,
      tier: AchievementTier.gold,
      icon: 'bolt',
      color: Colors.yellow,
      requirement: 1,
      xpReward: 200,
    ),
    // Reading achievements
    const Achievement(
      id: 'bookworm',
      title: 'Bookworm',
      description: 'Read 50 stories to completion',
      category: AchievementCategory.reading,
      tier: AchievementTier.platinum,
      icon: 'menu_book',
      color: Colors.teal,
      requirement: 50,
      xpReward: 1000,
    ),
    // Mastery achievements
    const Achievement(
      id: 'legendary',
      title: 'Legendary Learner',
      description: 'Reach 10,000 XP',
      category: AchievementCategory.mastery,
      tier: AchievementTier.legendary,
      icon: 'emoji_events',
      color: AppColors.accentOrange,
      requirement: 10000,
      xpReward: 5000,
    ),
  ];
}

