import 'package:logger/logger.dart';
import '../models/learning_stats.dart';
import 'supabase_service.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final Logger _logger = Logger();
  final SupabaseService _supabase = SupabaseService();

  // Get learning statistics for a date range
  Future<List<LearningAnalytics>> getLearningAnalytics(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _supabase.client
          .from('learning_analytics')
          .select()
          .eq('user_id', userId);

      if (startDate != null) {
        query = query.gte('date', startDate.toIso8601String().split('T')[0]);
      }
      if (endDate != null) {
        query = query.lte('date', endDate.toIso8601String().split('T')[0]);
      }

      final response = await query.order('date', ascending: false);

      return (response as List)
          .map((json) => LearningAnalytics.fromJson(json))
          .toList();
    } catch (e) {
      _logger.e('Failed to get learning analytics', error: e);
      return [];
    }
  }

  // Get today's analytics
  Future<LearningAnalytics?> getTodayAnalytics(String userId) async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      
      final response = await _supabase.client
          .from('learning_analytics')
          .select()
          .eq('user_id', userId)
          .eq('date', today)
          .maybeSingle();

      if (response != null) {
        return LearningAnalytics.fromJson(response);
      }
    
      // Create new record for today
      final newAnalytics = LearningAnalytics(
        id: 'analytics_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        date: DateTime.now(),
        createdAt: DateTime.now(),
      );

      await _supabase.client.from('learning_analytics').insert(newAnalytics.toJson());
      return newAnalytics;
    } catch (e) {
      _logger.e('Failed to get today analytics', error: e);
      return null;
    }
  }

  // Record learning activity
  Future<void> recordActivity(
    String userId,
    String activityType, {
    int minutes = 0,
    int xpEarned = 0,
    int lessonsCompleted = 0,
    int wordsLearned = 0,
    int wordsReviewed = 0,
    bool? isCorrect,
    String? weakArea,
    String? strongArea,
  }) async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      
      // Get or create today's analytics
      var analytics = await getTodayAnalytics(userId);
      
      analytics ??= LearningAnalytics(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: userId,
          date: DateTime.now(),
          createdAt: DateTime.now(),
        );

      // Update analytics
      analytics.studyTimeMinutes += minutes;
      analytics.xpEarned += xpEarned;
      
      if (lessonsCompleted > 0) {
        analytics.lessonsCompleted += lessonsCompleted;
      }
      if (wordsLearned > 0) {
        analytics.wordsLearned += wordsLearned;
      }
      if (wordsReviewed > 0) {
        analytics.wordsReviewed += wordsReviewed;
      }

      // Update activities breakdown
      analytics.activitiesBreakdown[activityType] = 
          (analytics.activitiesBreakdown[activityType] ?? 0) + 1;

      // Update accuracy
      if (isCorrect != null) {
        final total = analytics.activitiesBreakdown.values.fold(0, (sum, val) => sum + val);
        final correct = analytics.activitiesBreakdown['correct'] ?? 0;
        analytics.accuracyRate = ((isCorrect ? correct + 1 : correct) / total) * 100;
      }

      // Update weak/strong areas
      if (weakArea != null && !analytics.weakAreas.contains(weakArea)) {
        analytics.weakAreas.add(weakArea);
      }
      if (strongArea != null && !analytics.strongAreas.contains(strongArea)) {
        analytics.strongAreas.add(strongArea);
      }

      // Upsert to database
      await _supabase.client.from('learning_analytics').upsert({
        'user_id': userId,
        'date': today,
        'study_time_minutes': analytics.studyTimeMinutes,
        'lessons_completed': analytics.lessonsCompleted,
        'words_learned': analytics.wordsLearned,
        'words_reviewed': analytics.wordsReviewed,
        'xp_earned': analytics.xpEarned,
        'accuracy_rate': analytics.accuracyRate,
        'weak_areas': analytics.weakAreas,
        'strong_areas': analytics.strongAreas,
        'activities_breakdown': analytics.activitiesBreakdown,
      });
    } catch (e) {
      _logger.e('Failed to record activity', error: e);
    }
  }

  // Get weekly report
  Future<WeeklyReport?> getWeeklyReport(String userId, DateTime weekStart) async {
    try {
      final response = await _supabase.client
          .from('weekly_reports')
          .select()
          .eq('user_id', userId)
          .eq('week_start_date', weekStart.toIso8601String().split('T')[0])
          .single();

      return WeeklyReport.fromJson(response);
    } catch (e) {
      _logger.e('Failed to get weekly report', error: e);
      return null;
    }
  }

  // Generate weekly report
  Future<WeeklyReport?> generateWeeklyReport(String userId, DateTime weekStart) async {
    try {
      final weekEnd = weekStart.add(const Duration(days: 6));
      
      // Get analytics for the week
      final analytics = await getLearningAnalytics(
        userId,
        startDate: weekStart,
        endDate: weekEnd,
      );

      if (analytics.isEmpty) return null;

      // Calculate totals
      int totalStudyTime = 0;
      int totalLessons = 0;
      int totalWords = 0;
      double totalAccuracy = 0;
      int accuracyCount = 0;

      for (var day in analytics) {
        totalStudyTime += day.studyTimeMinutes;
        totalLessons += day.lessonsCompleted;
        totalWords += day.wordsLearned;
        if (day.accuracyRate != null) {
          totalAccuracy += day.accuracyRate!;
          accuracyCount++;
        }
      }

      final averageAccuracy = accuracyCount > 0 ? totalAccuracy / accuracyCount : 0.0;

      // Get streak data
      final streakResponse = await _supabase.client
          .from('user_streaks')
          .select('current_streak')
          .eq('user_id', userId)
          .single();

      final streakMaintained = (streakResponse['current_streak'] ?? 0) >= 7;

      // Generate recommendations
      final recommendations = _generateRecommendations(analytics);

      // Create report
      final report = WeeklyReport(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        weekStartDate: weekStart,
        weekEndDate: weekEnd,
        totalStudyTime: totalStudyTime,
        totalLessons: totalLessons,
        totalWords: totalWords,
        averageAccuracy: averageAccuracy,
        streakMaintained: streakMaintained,
        goalsAchieved: {
          'study_goal': totalStudyTime >= 150, // 2.5 hours
          'lessons_goal': totalLessons >= 5,
          'accuracy_goal': averageAccuracy >= 75,
        },
        recommendations: recommendations,
        generatedAt: DateTime.now(),
      );

      // Save report
      await _supabase.client.from('weekly_reports').upsert(report.toJson());

      return report;
    } catch (e) {
      _logger.e('Failed to generate weekly report', error: e);
      return null;
    }
  }

  List<String> _generateRecommendations(List<LearningAnalytics> analytics) {
    final recommendations = <String>[];
    
    // Calculate daily average
    final avgStudyTime = analytics.isEmpty 
        ? 0 
        : analytics.fold(0, (sum, a) => sum + a.studyTimeMinutes) / analytics.length;
    
    if (avgStudyTime < 15) {
      recommendations.add('Try to study at least 15 minutes per day for better retention.');
    }

    // Check weak areas
    final allWeakAreas = analytics.expand((a) => a.weakAreas).toList();
    if (allWeakAreas.isNotEmpty) {
      final topWeak = _getMostFrequent(allWeakAreas);
      recommendations.add('Focus on improving your $topWeak - practice these concepts more.');
    }

    // Check accuracy trend
    final accuracies = analytics
        .where((a) => a.accuracyRate != null)
        .map((a) => a.accuracyRate!)
        .toList();
    
    if (accuracies.length >= 3) {
      final recent = accuracies.take(3).reduce((a, b) => a + b) / 3;
      final older = accuracies.skip(accuracies.length - 3).take(3).reduce((a, b) => a + b) / 3;
      
      if (recent < older - 10) {
        recommendations.add('Your accuracy has dropped recently. Consider reviewing previous lessons.');
      } else if (recent > older + 10) {
        recommendations.add('Great improvement! Keep up the good work.');
      }
    }

    if (recommendations.isEmpty) {
      recommendations.add('Keep maintaining your consistent study habits!');
    }

    return recommendations;
  }

  String _getMostFrequent(List<String> items) {
    final counts = <String, int>{};
    for (var item in items) {
      counts[item] = (counts[item] ?? 0) + 1;
    }
    return counts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  // Get skill heatmap
  Future<List<SkillHeatmap>> getSkillHeatmap(String userId) async {
    try {
      final response = await _supabase.client
          .from('skill_heatmap')
          .select()
          .eq('user_id', userId)
          .order('last_practiced_at', ascending: false);

      return (response as List)
          .map((json) => SkillHeatmap.fromJson(json))
          .toList();
    } catch (e) {
      _logger.e('Failed to get skill heatmap', error: e);
      return [];
    }
  }

  // Update skill mastery
  Future<void> updateSkillMastery(
    String userId,
    String skillCategory,
    String subcategory,
    int masteryPercentage, {
    bool incrementPractice = true,
  }) async {
    try {
      final existing = await _supabase.client
          .from('skill_heatmap')
          .select()
          .eq('user_id', userId)
          .eq('skill_category', skillCategory)
          .eq('subcategory', subcategory)
          .single();

      final heatmap = SkillHeatmap.fromJson(existing);
      heatmap.updateMastery(masteryPercentage, incrementPractice);
      
      await _supabase.client
          .from('skill_heatmap')
          .update(heatmap.toJson())
          .eq('id', heatmap.id);
        } catch (e) {
      _logger.e('Failed to update skill mastery', error: e);
    }
  }

  // Get comprehensive learning stats
  Future<LearningStats?> getLearningStats(String userId) async {
    try {
      // Get user data
      final userResponse = await _supabase.client
          .from('users')
          .select('total_xp, streak_days, total_games_won, total_games_played, total_friends')
          .eq('id', userId)
          .single();

      // Get last 7 days of analytics
      final lastWeek = await getLearningAnalytics(
        userId,
        startDate: DateTime.now().subtract(const Duration(days: 7)),
      );

      final dailyStats = lastWeek.map((a) => DailyStats(
        date: a.date,
        studyTimeMinutes: a.studyTimeMinutes,
        xpEarned: a.xpEarned,
        lessonsCompleted: a.lessonsCompleted,
        accuracy: a.accuracyRate,
      )).toList();

      // Calculate skill breakdown
      final heatmap = await getSkillHeatmap(userId);
      final skillBreakdown = <String, int>{};
      for (var skill in heatmap) {
        skillBreakdown[skill.skillCategory] = 
            (skillBreakdown[skill.skillCategory] ?? 0) + skill.masteryPercentage;
      }

      return LearningStats(
        userId: userId,
        totalStudyTimeMinutes: lastWeek.fold(0, (sum, a) => sum + a.studyTimeMinutes),
        totalLessonsCompleted: lastWeek.fold(0, (sum, a) => sum + a.lessonsCompleted),
        totalWordsLearned: lastWeek.fold(0, (sum, a) => sum + a.wordsLearned),
        currentStreak: userResponse['streak_days'] ?? 0,
        longestStreak: userResponse['longest_streak'] ?? 0,
        totalXPEarned: userResponse['total_xp'] ?? 0,
        averageAccuracy: lastWeek.isEmpty 
            ? 0.0 
            : lastWeek.where((a) => a.accuracyRate != null)
                      .map((a) => a.accuracyRate!)
                      .fold(0.0, (sum, a) => sum + a) / lastWeek.length,
        skillBreakdown: skillBreakdown,
        last7Days: dailyStats,
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      _logger.e('Failed to get learning stats', error: e);
      return null;
    }
  }

  // Get words learned this week
  Future<int> getWordsLearnedThisWeek(String userId) async {
    try {
      final weekStart = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
      
      final response = await _supabase.client
          .from('user_vocabulary')
          .select('id')
          .eq('user_id', userId)
          .eq('is_learned', true)
          .gte('learned_at', weekStart.toIso8601String());

      return response.length;
    } catch (e) {
      return 0;
    }
  }

  // Get study streak calendar
  Future<List<Map<String, dynamic>>> getStudyCalendar(String userId, int month, int year) async {
    try {
      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 0);

      final response = await _supabase.client
          .from('learning_analytics')
          .select('date, study_time_minutes, xp_earned')
          .eq('user_id', userId)
          .gte('date', startDate.toIso8601String().split('T')[0])
          .lte('date', endDate.toIso8601String().split('T')[0]);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      _logger.e('Failed to get study calendar', error: e);
      return [];
    }
  }
}
