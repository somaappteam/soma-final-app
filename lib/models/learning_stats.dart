import 'package:flutter/material.dart';

class LearningAnalytics {
  final String id;
  final String userId;
  final DateTime date;
  int studyTimeMinutes;
  int lessonsCompleted;
  int wordsLearned;
  int wordsReviewed;
  int xpEarned;
  int gemsEarned;
  double? accuracyRate;
  final List<String> weakAreas;
  final List<String> strongAreas;
  final Map<String, int> activitiesBreakdown;
  final DateTime createdAt;

  LearningAnalytics({
    required this.id,
    required this.userId,
    required this.date,
    this.studyTimeMinutes = 0,
    this.lessonsCompleted = 0,
    this.wordsLearned = 0,
    this.wordsReviewed = 0,
    this.xpEarned = 0,
    this.gemsEarned = 0,
    this.accuracyRate,
    this.weakAreas = const [],
    this.strongAreas = const [],
    this.activitiesBreakdown = const {},
    required this.createdAt,
  });

  factory LearningAnalytics.fromJson(Map<String, dynamic> json) {
    return LearningAnalytics(
      id: json['id'],
      userId: json['user_id'],
      date: DateTime.parse(json['date']),
      studyTimeMinutes: json['study_time_minutes'] ?? 0,
      lessonsCompleted: json['lessons_completed'] ?? 0,
      wordsLearned: json['words_learned'] ?? 0,
      wordsReviewed: json['words_reviewed'] ?? 0,
      xpEarned: json['xp_earned'] ?? 0,
      gemsEarned: json['gems_earned'] ?? 0,
      accuracyRate: json['accuracy_rate']?.toDouble(),
      weakAreas: List<String>.from(json['weak_areas'] ?? []),
      strongAreas: List<String>.from(json['strong_areas'] ?? []),
      activitiesBreakdown: Map<String, int>.from(json['activities_breakdown'] ?? {}),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'date': date.toIso8601String(),
      'study_time_minutes': studyTimeMinutes,
      'lessons_completed': lessonsCompleted,
      'words_learned': wordsLearned,
      'words_reviewed': wordsReviewed,
      'xp_earned': xpEarned,
      'gems_earned': gemsEarned,
      'accuracy_rate': accuracyRate,
      'weak_areas': weakAreas,
      'strong_areas': strongAreas,
      'activities_breakdown': activitiesBreakdown,
      'created_at': createdAt.toIso8601String(),
    };
  }

  void addActivity(String activityType, int minutes, int xp, {bool? isCorrect}) {
    studyTimeMinutes += minutes;
    xpEarned += xp;
    
    activitiesBreakdown[activityType] = (activitiesBreakdown[activityType] ?? 0) + 1;
    
    if (activityType == 'lesson') {
      lessonsCompleted++;
    } else if (activityType == 'vocabulary_new') {
      wordsLearned++;
    } else if (activityType == 'vocabulary_review') {
      wordsReviewed++;
    }
    
    // Update accuracy rate
    if (isCorrect != null) {
      final total = activitiesBreakdown.values.fold(0, (sum, val) => sum + val);
      final correct = activitiesBreakdown['correct'] ?? 0;
      accuracyRate = ((isCorrect ? correct + 1 : correct) / total) * 100;
    }
  }
}

class WeeklyReport {
  final String id;
  final String userId;
  final DateTime weekStartDate;
  final DateTime weekEndDate;
  int totalStudyTime;
  int totalLessons;
  int totalWords;
  double? averageAccuracy;
  bool streakMaintained;
  final Map<String, dynamic> goalsAchieved;
  final List<String> recommendations;
  final Map<String, dynamic>? comparisonWithFriends;
  final DateTime generatedAt;
  DateTime? viewedAt;

  WeeklyReport({
    required this.id,
    required this.userId,
    required this.weekStartDate,
    required this.weekEndDate,
    this.totalStudyTime = 0,
    this.totalLessons = 0,
    this.totalWords = 0,
    this.averageAccuracy,
    this.streakMaintained = false,
    this.goalsAchieved = const {},
    this.recommendations = const [],
    this.comparisonWithFriends,
    required this.generatedAt,
    this.viewedAt,
  });

  factory WeeklyReport.fromJson(Map<String, dynamic> json) {
    return WeeklyReport(
      id: json['id'],
      userId: json['user_id'],
      weekStartDate: DateTime.parse(json['week_start_date']),
      weekEndDate: DateTime.parse(json['week_end_date']),
      totalStudyTime: json['total_study_time'] ?? 0,
      totalLessons: json['total_lessons'] ?? 0,
      totalWords: json['total_words'] ?? 0,
      averageAccuracy: json['average_accuracy']?.toDouble(),
      streakMaintained: json['streak_maintained'] ?? false,
      goalsAchieved: json['goals_achieved'] ?? {},
      recommendations: List<String>.from(json['recommendations'] ?? []),
      comparisonWithFriends: json['comparison_with_friends'],
      generatedAt: DateTime.parse(json['generated_at']),
      viewedAt: json['viewed_at'] != null 
          ? DateTime.parse(json['viewed_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'week_start_date': weekStartDate.toIso8601String(),
      'week_end_date': weekEndDate.toIso8601String(),
      'total_study_time': totalStudyTime,
      'total_lessons': totalLessons,
      'total_words': totalWords,
      'average_accuracy': averageAccuracy,
      'streak_maintained': streakMaintained,
      'goals_achieved': goalsAchieved,
      'recommendations': recommendations,
      'comparison_with_friends': comparisonWithFriends,
      'generated_at': generatedAt.toIso8601String(),
      'viewed_at': viewedAt?.toIso8601String(),
    };
  }

  void markAsViewed() {
    viewedAt = DateTime.now();
  }

  String get studyTimeFormatted {
    final hours = totalStudyTime ~/ 60;
    final minutes = totalStudyTime % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  double get goalsCompletionPercentage {
    if (goalsAchieved.isEmpty) return 0.0;
    final achieved = goalsAchieved.values.where((v) => v == true).length;
    return achieved / goalsAchieved.length;
  }
}

class SkillHeatmap {
  final String id;
  final String userId;
  final String skillCategory; // 'vocabulary', 'grammar', 'listening', 'speaking', 'reading', 'writing'
  final String subcategory;
  int masteryPercentage;
  DateTime? lastPracticedAt;
  int practiceCount;
  final DateTime updatedAt;

  SkillHeatmap({
    required this.id,
    required this.userId,
    required this.skillCategory,
    required this.subcategory,
    this.masteryPercentage = 0,
    this.lastPracticedAt,
    this.practiceCount = 0,
    required this.updatedAt,
  });

  factory SkillHeatmap.fromJson(Map<String, dynamic> json) {
    return SkillHeatmap(
      id: json['id'],
      userId: json['user_id'],
      skillCategory: json['skill_category'],
      subcategory: json['subcategory'],
      masteryPercentage: json['mastery_percentage'] ?? 0,
      lastPracticedAt: json['last_practiced_at'] != null 
          ? DateTime.parse(json['last_practiced_at']) 
          : null,
      practiceCount: json['practice_count'] ?? 0,
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'skill_category': skillCategory,
      'subcategory': subcategory,
      'mastery_percentage': masteryPercentage,
      'last_practiced_at': lastPracticedAt?.toIso8601String(),
      'practice_count': practiceCount,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  void updateMastery(int newMastery, bool incrementPractice) {
    masteryPercentage = newMastery.clamp(0, 100);
    lastPracticedAt = DateTime.now();
    if (incrementPractice) {
      practiceCount++;
    }
  }

  Color get heatmapColor {
    if (masteryPercentage >= 80) {
      return Colors.green.shade700;
    } else if (masteryPercentage >= 60) {
      return Colors.green.shade400;
    } else if (masteryPercentage >= 40) {
      return Colors.yellow.shade600;
    } else if (masteryPercentage >= 20) {
      return Colors.orange.shade400;
    } else {
      return Colors.red.shade300;
    }
  }

  String get strengthLevel {
    if (masteryPercentage >= 80) return 'Mastered';
    if (masteryPercentage >= 60) return 'Strong';
    if (masteryPercentage >= 40) return 'Developing';
    if (masteryPercentage >= 20) return 'Needs Work';
    return 'Weak Area';
  }
}

class LearningStats {
  final String userId;
  final int totalStudyTimeMinutes;
  final int totalLessonsCompleted;
  final int totalWordsLearned;
  final int currentStreak;
  final int longestStreak;
  final int totalXPEarned;
  final double averageAccuracy;
  final Map<String, int> skillBreakdown;
  final List<DailyStats> last7Days;
  final DateTime updatedAt;

  LearningStats({
    required this.userId,
    this.totalStudyTimeMinutes = 0,
    this.totalLessonsCompleted = 0,
    this.totalWordsLearned = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.totalXPEarned = 0,
    this.averageAccuracy = 0.0,
    this.skillBreakdown = const {},
    this.last7Days = const [],
    required this.updatedAt,
  });

  factory LearningStats.fromJson(Map<String, dynamic> json) {
    return LearningStats(
      userId: json['user_id'],
      totalStudyTimeMinutes: json['total_study_time_minutes'] ?? 0,
      totalLessonsCompleted: json['total_lessons_completed'] ?? 0,
      totalWordsLearned: json['total_words_learned'] ?? 0,
      currentStreak: json['current_streak'] ?? 0,
      longestStreak: json['longest_streak'] ?? 0,
      totalXPEarned: json['total_xp_earned'] ?? 0,
      averageAccuracy: (json['average_accuracy'] ?? 0.0).toDouble(),
      skillBreakdown: Map<String, int>.from(json['skill_breakdown'] ?? {}),
      last7Days: (json['last_7_days'] as List? ?? [])
          .map((d) => DailyStats.fromJson(d))
          .toList(),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'total_study_time_minutes': totalStudyTimeMinutes,
      'total_lessons_completed': totalLessonsCompleted,
      'total_words_learned': totalWordsLearned,
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'total_xp_earned': totalXPEarned,
      'average_accuracy': averageAccuracy,
      'skill_breakdown': skillBreakdown,
      'last_7_days': last7Days.map((d) => d.toJson()).toList(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get totalStudyTimeFormatted {
    final hours = totalStudyTimeMinutes ~/ 60;
    final minutes = totalStudyTimeMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  int get dailyAverageMinutes {
    if (last7Days.isEmpty) return 0;
    final total = last7Days.fold(0, (sum, day) => sum + day.studyTimeMinutes);
    return (total / last7Days.length).round();
  }
}

class DailyStats {
  final DateTime date;
  int studyTimeMinutes;
  int xpEarned;
  int lessonsCompleted;
  double? accuracy;

  DailyStats({
    required this.date,
    this.studyTimeMinutes = 0,
    this.xpEarned = 0,
    this.lessonsCompleted = 0,
    this.accuracy,
  });

  factory DailyStats.fromJson(Map<String, dynamic> json) {
    return DailyStats(
      date: DateTime.parse(json['date']),
      studyTimeMinutes: json['study_time_minutes'] ?? 0,
      xpEarned: json['xp_earned'] ?? 0,
      lessonsCompleted: json['lessons_completed'] ?? 0,
      accuracy: json['accuracy']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'study_time_minutes': studyTimeMinutes,
      'xp_earned': xpEarned,
      'lessons_completed': lessonsCompleted,
      'accuracy': accuracy,
    };
  }
}

enum SkillCategory {
  vocabulary,
  grammar,
  listening,
  speaking,
  reading,
  writing,
}

extension SkillCategoryExtension on SkillCategory {
  String get displayName {
    switch (this) {
      case SkillCategory.vocabulary:
        return 'Vocabulary';
      case SkillCategory.grammar:
        return 'Grammar';
      case SkillCategory.listening:
        return 'Listening';
      case SkillCategory.speaking:
        return 'Speaking';
      case SkillCategory.reading:
        return 'Reading';
      case SkillCategory.writing:
        return 'Writing';
    }
  }

  IconData get icon {
    switch (this) {
      case SkillCategory.vocabulary:
        return Icons.menu_book;
      case SkillCategory.grammar:
        return Icons.text_fields;
      case SkillCategory.listening:
        return Icons.headphones;
      case SkillCategory.speaking:
        return Icons.mic;
      case SkillCategory.reading:
        return Icons.book;
      case SkillCategory.writing:
        return Icons.edit;
    }
  }

  Color get color {
    switch (this) {
      case SkillCategory.vocabulary:
        return Colors.blue;
      case SkillCategory.grammar:
        return Colors.purple;
      case SkillCategory.listening:
        return Colors.green;
      case SkillCategory.speaking:
        return Colors.orange;
      case SkillCategory.reading:
        return Colors.teal;
      case SkillCategory.writing:
        return Colors.pink;
    }
  }
}
