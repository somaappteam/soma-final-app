import 'dart:ui';
import '../theme/app_theme.dart';

/// Progress Analytics Dashboard Models
class UserAnalytics {
  final String userId;
  final DateTime dateRangeStart;
  final DateTime dateRangeEnd;
  final StudyTimeAnalytics studyTime;
  final VocabularyAnalytics vocabulary;
  final GrammarAnalytics grammar;
  final SkillBreakdown skillBreakdown;
  final List<WeakArea> weakAreas;
  final List<DailyProgress> dailyProgress;
  final ComparisonStats? friendComparison;
  final ComparisonStats? globalComparison;
  final HeatmapData heatmapData;
  final List<Achievement> recentAchievements;
  final LearningVelocity learningVelocity;

  UserAnalytics({
    required this.userId,
    required this.dateRangeStart,
    required this.dateRangeEnd,
    required this.studyTime,
    required this.vocabulary,
    required this.grammar,
    required this.skillBreakdown,
    required this.weakAreas,
    required this.dailyProgress,
    this.friendComparison,
    this.globalComparison,
    required this.heatmapData,
    required this.recentAchievements,
    required this.learningVelocity,
  });

  factory UserAnalytics.fromJson(Map<String, dynamic> json) {
    return UserAnalytics(
      userId: json['user_id'],
      dateRangeStart: DateTime.parse(json['date_range_start']),
      dateRangeEnd: DateTime.parse(json['date_range_end']),
      studyTime: StudyTimeAnalytics.fromJson(json['study_time']),
      vocabulary: VocabularyAnalytics.fromJson(json['vocabulary']),
      grammar: GrammarAnalytics.fromJson(json['grammar']),
      skillBreakdown: SkillBreakdown.fromJson(json['skill_breakdown']),
      weakAreas: (json['weak_areas'] as List? ?? [])
          .map((w) => WeakArea.fromJson(w))
          .toList(),
      dailyProgress: (json['daily_progress'] as List? ?? [])
          .map((d) => DailyProgress.fromJson(d))
          .toList(),
      friendComparison: json['friend_comparison'] != null
          ? ComparisonStats.fromJson(json['friend_comparison'])
          : null,
      globalComparison: json['global_comparison'] != null
          ? ComparisonStats.fromJson(json['global_comparison'])
          : null,
      heatmapData: HeatmapData.fromJson(json['heatmap_data']),
      recentAchievements: (json['recent_achievements'] as List? ?? [])
          .map((a) => Achievement.fromJson(a))
          .toList(),
      learningVelocity: LearningVelocity.fromJson(json['learning_velocity']),
    );
  }
}

class StudyTimeAnalytics {
  final int totalMinutes;
  final int dailyAverage;
  final int weeklyTotal;
  final int monthlyTotal;
  final int streakDays;
  final int longestStreak;
  final List<TimeDistribution> timeDistribution; // By hour of day
  final List<DayDistribution> dayDistribution; // By day of week
  final int sessionsCompleted;
  final double averageSessionLength;

  StudyTimeAnalytics({
    required this.totalMinutes,
    required this.dailyAverage,
    required this.weeklyTotal,
    required this.monthlyTotal,
    required this.streakDays,
    required this.longestStreak,
    required this.timeDistribution,
    required this.dayDistribution,
    required this.sessionsCompleted,
    required this.averageSessionLength,
  });

  factory StudyTimeAnalytics.fromJson(Map<String, dynamic> json) {
    return StudyTimeAnalytics(
      totalMinutes: json['total_minutes'] ?? 0,
      dailyAverage: json['daily_average'] ?? 0,
      weeklyTotal: json['weekly_total'] ?? 0,
      monthlyTotal: json['monthly_total'] ?? 0,
      streakDays: json['streak_days'] ?? 0,
      longestStreak: json['longest_streak'] ?? 0,
      timeDistribution: (json['time_distribution'] as List? ?? [])
          .map((t) => TimeDistribution.fromJson(t))
          .toList(),
      dayDistribution: (json['day_distribution'] as List? ?? [])
          .map((d) => DayDistribution.fromJson(d))
          .toList(),
      sessionsCompleted: json['sessions_completed'] ?? 0,
      averageSessionLength: (json['average_session_length'] ?? 0).toDouble(),
    );
  }
}

class TimeDistribution {
  final int hour; // 0-23
  final int minutes;
  final double percentage;

  TimeDistribution({
    required this.hour,
    required this.minutes,
    required this.percentage,
  });

  factory TimeDistribution.fromJson(Map<String, dynamic> json) {
    return TimeDistribution(
      hour: json['hour'],
      minutes: json['minutes'],
      percentage: (json['percentage'] ?? 0).toDouble(),
    );
  }
}

class DayDistribution {
  final String day; // 'Monday', 'Tuesday', etc.
  final int minutes;
  final double percentage;

  DayDistribution({
    required this.day,
    required this.minutes,
    required this.percentage,
  });

  factory DayDistribution.fromJson(Map<String, dynamic> json) {
    return DayDistribution(
      day: json['day'],
      minutes: json['minutes'],
      percentage: (json['percentage'] ?? 0).toDouble(),
    );
  }
}

class VocabularyAnalytics {
  final int totalWordsLearned;
  final int wordsInProgress;
  final int wordsMastered;
  final int wordsForReview;
  final double retentionRate;
  final List<CategoryStats> categoryBreakdown;
  final List<WordStrength> wordStrengthDistribution;
  final List<WordMistake> commonlyMissedWords;

  VocabularyAnalytics({
    required this.totalWordsLearned,
    required this.wordsInProgress,
    required this.wordsMastered,
    required this.wordsForReview,
    required this.retentionRate,
    required this.categoryBreakdown,
    required this.wordStrengthDistribution,
    required this.commonlyMissedWords,
  });

  factory VocabularyAnalytics.fromJson(Map<String, dynamic> json) {
    return VocabularyAnalytics(
      totalWordsLearned: json['total_words_learned'] ?? 0,
      wordsInProgress: json['words_in_progress'] ?? 0,
      wordsMastered: json['words_mastered'] ?? 0,
      wordsForReview: json['words_for_review'] ?? 0,
      retentionRate: (json['retention_rate'] ?? 0).toDouble(),
      categoryBreakdown: (json['category_breakdown'] as List? ?? [])
          .map((c) => CategoryStats.fromJson(c))
          .toList(),
      wordStrengthDistribution: (json['word_strength_distribution'] as List? ?? [])
          .map((w) => WordStrength.fromJson(w))
          .toList(),
      commonlyMissedWords: (json['commonly_missed_words'] as List? ?? [])
          .map((w) => WordMistake.fromJson(w))
          .toList(),
    );
  }
}

class CategoryStats {
  final String category;
  final int wordsLearned;
  final int totalWords;
  final double masteryPercentage;

  CategoryStats({
    required this.category,
    required this.wordsLearned,
    required this.totalWords,
    required this.masteryPercentage,
  });

  factory CategoryStats.fromJson(Map<String, dynamic> json) {
    return CategoryStats(
      category: json['category'],
      wordsLearned: json['words_learned'] ?? 0,
      totalWords: json['total_words'] ?? 0,
      masteryPercentage: (json['mastery_percentage'] ?? 0).toDouble(),
    );
  }
}

class WordStrength {
  final String strength; // 'weak', 'medium', 'strong', 'mastered'
  final int count;
  final double percentage;

  WordStrength({
    required this.strength,
    required this.count,
    required this.percentage,
  });

  factory WordStrength.fromJson(Map<String, dynamic> json) {
    return WordStrength(
      strength: json['strength'],
      count: json['count'] ?? 0,
      percentage: (json['percentage'] ?? 0).toDouble(),
    );
  }
}

class WordMistake {
  final String word;
  final String translation;
  final int mistakeCount;
  final double accuracyRate;
  final String? category;

  WordMistake({
    required this.word,
    required this.translation,
    required this.mistakeCount,
    required this.accuracyRate,
    this.category,
  });

  factory WordMistake.fromJson(Map<String, dynamic> json) {
    return WordMistake(
      word: json['word'],
      translation: json['translation'],
      mistakeCount: json['mistake_count'] ?? 0,
      accuracyRate: (json['accuracy_rate'] ?? 0).toDouble(),
      category: json['category'],
    );
  }
}

class GrammarAnalytics {
  final int rulesLearned;
  final int rulesMastered;
  final double overallAccuracy;
  final List<GrammarCategoryStats> categoryStats;
  final List<GrammarErrorPattern> commonErrors;
  final int exercisesCompleted;
  final int exercisesCorrect;

  GrammarAnalytics({
    required this.rulesLearned,
    required this.rulesMastered,
    required this.overallAccuracy,
    required this.categoryStats,
    required this.commonErrors,
    required this.exercisesCompleted,
    required this.exercisesCorrect,
  });

  factory GrammarAnalytics.fromJson(Map<String, dynamic> json) {
    return GrammarAnalytics(
      rulesLearned: json['rules_learned'] ?? 0,
      rulesMastered: json['rules_mastered'] ?? 0,
      overallAccuracy: (json['overall_accuracy'] ?? 0).toDouble(),
      categoryStats: (json['category_stats'] as List? ?? [])
          .map((c) => GrammarCategoryStats.fromJson(c))
          .toList(),
      commonErrors: (json['common_errors'] as List? ?? [])
          .map((e) => GrammarErrorPattern.fromJson(e))
          .toList(),
      exercisesCompleted: json['exercises_completed'] ?? 0,
      exercisesCorrect: json['exercises_correct'] ?? 0,
    );
  }
}

class GrammarCategoryStats {
  final String category;
  final int exercisesCompleted;
  final double accuracyRate;
  final bool isMastered;

  GrammarCategoryStats({
    required this.category,
    required this.exercisesCompleted,
    required this.accuracyRate,
    required this.isMastered,
  });

  factory GrammarCategoryStats.fromJson(Map<String, dynamic> json) {
    return GrammarCategoryStats(
      category: json['category'],
      exercisesCompleted: json['exercises_completed'] ?? 0,
      accuracyRate: (json['accuracy_rate'] ?? 0).toDouble(),
      isMastered: json['is_mastered'] ?? false,
    );
  }
}

class GrammarErrorPattern {
  final String errorType;
  final String description;
  final int occurrenceCount;
  final String? example;

  GrammarErrorPattern({
    required this.errorType,
    required this.description,
    required this.occurrenceCount,
    this.example,
  });

  factory GrammarErrorPattern.fromJson(Map<String, dynamic> json) {
    return GrammarErrorPattern(
      errorType: json['error_type'],
      description: json['description'],
      occurrenceCount: json['occurrence_count'] ?? 0,
      example: json['example'],
    );
  }
}

class SkillBreakdown {
  final double vocabulary;
  final double grammar;
  final double reading;
  final double listening;
  final double speaking;
  final double writing;

  SkillBreakdown({
    required this.vocabulary,
    required this.grammar,
    required this.reading,
    required this.listening,
    required this.speaking,
    required this.writing,
  });

  factory SkillBreakdown.fromJson(Map<String, dynamic> json) {
    return SkillBreakdown(
      vocabulary: (json['vocabulary'] ?? 0).toDouble(),
      grammar: (json['grammar'] ?? 0).toDouble(),
      reading: (json['reading'] ?? 0).toDouble(),
      listening: (json['listening'] ?? 0).toDouble(),
      speaking: (json['speaking'] ?? 0).toDouble(),
      writing: (json['writing'] ?? 0).toDouble(),
    );
  }

  double get average => 
      (vocabulary + grammar + reading + listening + speaking + writing) / 6;

  String get strongestSkill {
    final skills = {
      'Vocabulary': vocabulary,
      'Grammar': grammar,
      'Reading': reading,
      'Listening': listening,
      'Speaking': speaking,
      'Writing': writing,
    };
    return skills.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  String get weakestSkill {
    final skills = {
      'Vocabulary': vocabulary,
      'Grammar': grammar,
      'Reading': reading,
      'Listening': listening,
      'Speaking': speaking,
      'Writing': writing,
    };
    return skills.entries.reduce((a, b) => a.value < b.value ? a : b).key;
  }
}

class WeakArea {
  final String skill;
  final String description;
  final double currentLevel;
  final double targetLevel;
  final List<String> recommendedExercises;
  final String? relatedLessonId;

  WeakArea({
    required this.skill,
    required this.description,
    required this.currentLevel,
    required this.targetLevel,
    required this.recommendedExercises,
    this.relatedLessonId,
  });

  factory WeakArea.fromJson(Map<String, dynamic> json) {
    return WeakArea(
      skill: json['skill'],
      description: json['description'],
      currentLevel: (json['current_level'] ?? 0).toDouble(),
      targetLevel: (json['target_level'] ?? 0).toDouble(),
      recommendedExercises: List<String>.from(json['recommended_exercises'] ?? []),
      relatedLessonId: json['related_lesson_id'],
    );
  }

  double get improvementNeeded => targetLevel - currentLevel;
}

class DailyProgress {
  final DateTime date;
  final int minutesStudied;
  final int xpEarned;
  final int lessonsCompleted;
  final bool dailyGoalMet;

  DailyProgress({
    required this.date,
    required this.minutesStudied,
    required this.xpEarned,
    required this.lessonsCompleted,
    required this.dailyGoalMet,
  });

  factory DailyProgress.fromJson(Map<String, dynamic> json) {
    return DailyProgress(
      date: DateTime.parse(json['date']),
      minutesStudied: json['minutes_studied'] ?? 0,
      xpEarned: json['xp_earned'] ?? 0,
      lessonsCompleted: json['lessons_completed'] ?? 0,
      dailyGoalMet: json['daily_goal_met'] ?? false,
    );
  }
}

class ComparisonStats {
  final int rank;
  final int totalParticipants;
  final double percentile;
  final int xpDifference; // Compared to average
  final int streakDifference;

  ComparisonStats({
    required this.rank,
    required this.totalParticipants,
    required this.percentile,
    required this.xpDifference,
    required this.streakDifference,
  });

  factory ComparisonStats.fromJson(Map<String, dynamic> json) {
    return ComparisonStats(
      rank: json['rank'] ?? 0,
      totalParticipants: json['total_participants'] ?? 0,
      percentile: (json['percentile'] ?? 0).toDouble(),
      xpDifference: json['xp_difference'] ?? 0,
      streakDifference: json['streak_difference'] ?? 0,
    );
  }
}

class HeatmapData {
  final List<HeatmapDay> days;
  final int maxActivity;
  final int totalDays;
  final int activeDays;

  HeatmapData({
    required this.days,
    required this.maxActivity,
    required this.totalDays,
    required this.activeDays,
  });

  factory HeatmapData.fromJson(Map<String, dynamic> json) {
    return HeatmapData(
      days: (json['days'] as List? ?? [])
          .map((d) => HeatmapDay.fromJson(d))
          .toList(),
      maxActivity: json['max_activity'] ?? 0,
      totalDays: json['total_days'] ?? 0,
      activeDays: json['active_days'] ?? 0,
    );
  }

  double get consistencyRate {
    if (totalDays == 0) return 0.0;
    return activeDays / totalDays;
  }
}

class HeatmapDay {
  final DateTime date;
  final int activityLevel; // 0-4
  final int minutesStudied;
  final int xpEarned;

  HeatmapDay({
    required this.date,
    required this.activityLevel,
    required this.minutesStudied,
    required this.xpEarned,
  });

  factory HeatmapDay.fromJson(Map<String, dynamic> json) {
    return HeatmapDay(
      date: DateTime.parse(json['date']),
      activityLevel: json['activity_level'] ?? 0,
      minutesStudied: json['minutes_studied'] ?? 0,
      xpEarned: json['xp_earned'] ?? 0,
    );
  }

  Color getColor() {
    switch (activityLevel) {
      case 0:
        return AppColors.neutralLight;
      case 1:
        return AppColors.chartLevel1;
      case 2:
        return AppColors.chartLevel2;
      case 3:
        return AppColors.chartLevel3;
      case 4:
        return AppColors.chartLevel4;
      default:
        return AppColors.neutralLight;
    }
  }
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final DateTime earnedAt;
  final int? xpReward;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.earnedAt,
    this.xpReward,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      icon: json['icon'],
      earnedAt: DateTime.parse(json['earned_at']),
      xpReward: json['xp_reward'],
    );
  }
}

class LearningVelocity {
  final double wordsPerWeek;
  final double grammarRulesPerWeek;
  final double xpPerWeek;
  final double hoursPerWeek;
  final String trend; // 'increasing', 'stable', 'decreasing'
  final double? trendPercentage;

  LearningVelocity({
    required this.wordsPerWeek,
    required this.grammarRulesPerWeek,
    required this.xpPerWeek,
    required this.hoursPerWeek,
    required this.trend,
    this.trendPercentage,
  });

  factory LearningVelocity.fromJson(Map<String, dynamic> json) {
    return LearningVelocity(
      wordsPerWeek: (json['words_per_week'] ?? 0).toDouble(),
      grammarRulesPerWeek: (json['grammar_rules_per_week'] ?? 0).toDouble(),
      xpPerWeek: (json['xp_per_week'] ?? 0).toDouble(),
      hoursPerWeek: (json['hours_per_week'] ?? 0).toDouble(),
      trend: json['trend'] ?? 'stable',
      trendPercentage: json['trend_percentage']?.toDouble(),
    );
  }

  String get estimatedTimeToFluency {
    // Simplified calculation
    if (wordsPerWeek < 5) return '2+ years';
    if (wordsPerWeek < 15) return '1-2 years';
    if (wordsPerWeek < 30) return '6-12 months';
    return '3-6 months';
  }
}
