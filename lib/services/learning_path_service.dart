import 'package:logger/logger.dart';
import '../models/lesson_model.dart';
import '../models/story_model.dart';
import 'supabase_service.dart';

class LearningPathService {
  static final LearningPathService _instance = LearningPathService._internal();
  factory LearningPathService() => _instance;
  LearningPathService._internal();

  final Logger _logger = Logger();
  final SupabaseService _supabase = SupabaseService();

  // Get stories for a course
  Future<List<StoryModel>> getStories(String courseId) async {
    try {
      if (_supabase.currentUserId == null) {
        return _getDemoStories(courseId);
      }

      final response = await _supabase.client
          .from('stories')
          .select()
          .eq('course_id', courseId);

      return (response as List)
          .map((json) => StoryModel.fromJson(json))
          .toList();
    } catch (e) {
      _logger.e('Failed to get stories', error: e);
      return [];
    }
  }

  // Get the complete learning path for a user in a course
  Future<LearningPath?> getLearningPath(String userId, String courseId) async {
    try {
      if (_supabase.currentUserId == null) {
        return _getDemoLearningPath(userId, courseId);
      }

      // Get all lessons for the course
      final lessonsResponse = await _supabase.client
          .from('lessons')
          .select()
          .eq('course_id', courseId)
          .eq('is_active', true)
          .order('order_index', ascending: true);

      if (lessonsResponse.isEmpty) {
        return null;
      }

      final lessons = (lessonsResponse as List)
          .map((json) => LessonModel.fromJson(json))
          .toList();

      // Get user's progress on these lessons
      final progressResponse = await _supabase.client
          .from('user_lessons')
          .select()
          .eq('user_id', userId)
          .inFilter('lesson_id', lessons.map((l) => l.id).toList());

      final progressMap = <String, UserLessonProgress>{};
      for (var json in progressResponse) {
        final progress = UserLessonProgress.fromJson(json);
        progressMap[progress.lessonId] = progress;
      }
    
      // Get user's learning profile for adaptive difficulty
      final profileResponse = await _supabase.client
          .from('user_learning_profiles')
          .select()
          .eq('user_id', userId)
          .single();

      int currentLevel = 1;
      String learningStyle = 'mixed';
      currentLevel = profileResponse['adaptive_difficulty_level'] ?? 1;
      learningStyle = profileResponse['learning_style'] ?? 'mixed';
    
      // Build learning path nodes
      final nodes = _buildLearningPathNodes(lessons, progressMap);

      return LearningPath(
        userId: userId,
        courseId: courseId,
        nodes: nodes,
        currentLevel: currentLevel,
        learningStyle: learningStyle,
        generatedAt: DateTime.now(),
      );
    } catch (e) {
      _logger.e('Failed to get learning path', error: e);
      return null;
    }
  }

  List<LearningPathNode> _buildLearningPathNodes(
    List<LessonModel> lessons,
    Map<String, UserLessonProgress> progressMap,
  ) {
    final nodes = <LearningPathNode>[];
    final completedLessons = <String>{};

    // First pass: identify completed lessons
    for (var lesson in lessons) {
      final progress = progressMap[lesson.id];
      if (progress != null && progress.isCompleted) {
        completedLessons.add(lesson.id);
      }
    }

    // Second pass: build nodes with unlock status
    for (var i = 0; i < lessons.length; i++) {
      final lesson = lessons[i];
      final progress = progressMap[lesson.id];

      // Determine if lesson is unlocked
      bool isUnlocked = false;
      if (i == 0) {
        // First lesson is always unlocked
        isUnlocked = true;
      } else if (lesson.prerequisites.isEmpty) {
        // No prerequisites = unlocked
        isUnlocked = true;
      } else {
        // Check if all prerequisites are completed
        isUnlocked = lesson.prerequisites.every((prereq) => 
          completedLessons.contains(prereq));
      }

      // Generate recommendation reason
      String? recommendationReason;
      if (!isUnlocked) {
        final incompletePrereqs = lesson.prerequisites
            .where((p) => !completedLessons.contains(p))
            .toList();
        if (incompletePrereqs.isNotEmpty) {
          recommendationReason = 'Complete ${incompletePrereqs.length} prerequisite lesson(s) to unlock';
        }
      } else if (progress == null) {
        recommendationReason = 'New lesson available!';
      } else if (!progress.isCompleted) {
        recommendationReason = 'Continue where you left off';
      }

      // Find next nodes
      final nextNodes = <String>[];
      if (i < lessons.length - 1) {
        // Next sequential lesson
        nextNodes.add(lessons[i + 1].id);
      }

      nodes.add(LearningPathNode(
        lessonId: lesson.id,
        title: lesson.title,
        isUnlocked: isUnlocked,
        isCompleted: progress?.isCompleted ?? false,
        difficultyLevel: lesson.difficultyLevel,
        nextNodes: nextNodes,
        recommendationReason: recommendationReason,
      ));
    }

    return nodes;
  }

  // Get recommended next lessons for a user
  Future<List<LessonModel>> getRecommendedLessons(String userId, String courseId, {int limit = 3}) async {
    try {
      if (_supabase.currentUserId == null) {
        return _getDemoRecommendedLessons(courseId);
      }

      final path = await getLearningPath(userId, courseId);
      if (path == null) return [];

      // Find unlocked but not completed lessons
      final recommendedNodes = path.nodes
          .where((n) => n.isUnlocked && !n.isCompleted)
          .take(limit)
          .toList();

      if (recommendedNodes.isEmpty) return [];

      // Fetch full lesson details
      final lessonIds = recommendedNodes.map((n) => n.lessonId).toList();
      final response = await _supabase.client
          .from('lessons')
          .select()
          .inFilter('id', lessonIds);

      return (response as List)
          .map((json) => LessonModel.fromJson(json))
          .toList();
    } catch (e) {
      _logger.e('Failed to get recommended lessons', error: e);
      return [];
    }
  }

  // Get weak areas for targeted practice
  Future<List<Map<String, dynamic>>> getWeakAreas(String userId, String courseId) async {
    try {
      if (_supabase.currentUserId == null) {
        return [
          {'category': 'Grammar', 'concept': 'Verbs', 'mistake_count': 5, 'related_lessons': ['l1']},
          {'category': 'Vocabulary', 'concept': 'Food', 'mistake_count': 3, 'related_lessons': ['l3']},
        ];
      }

      // Get user's lesson attempts with mistakes
      final response = await _supabase.client
          .from('user_lessons')
          .select('''
            lesson_id,
            mistakes_made,
            lessons!inner(course_id, lesson_type)
          ''')
          .eq('user_id', userId)
          .eq('lessons.course_id', courseId)
          .not('mistakes_made', 'is', null);

      final mistakeCounts = <String, int>{};
      final categoryMistakes = <String, List<Map<String, dynamic>>>{};

      for (var item in response) {
        final mistakes = item['mistakes_made'] as List? ?? [];
        final lessonType = item['lessons']['lesson_type'] as String? ?? 'general';

        for (var mistake in mistakes) {
          final category = mistake['category'] as String? ?? lessonType;
          final concept = mistake['concept'] as String? ?? 'general';
          
          final key = '$category:$concept';
          mistakeCounts[key] = (mistakeCounts[key] ?? 0) + 1;

          categoryMistakes.putIfAbsent(category, () => []);
          categoryMistakes[category]!.add({
            'concept': concept,
            'lesson_id': item['lesson_id'],
          });
        }
      }

      // Sort by mistake count and return top weak areas
      final sortedKeys = mistakeCounts.keys.toList()
        ..sort((a, b) => mistakeCounts[b]!.compareTo(mistakeCounts[a]!));

      return sortedKeys.take(5).map((key) {
        final parts = key.split(':');
        final category = parts[0];
        final concept = parts[1];
        
        return {
          'category': category,
          'concept': concept,
          'mistake_count': mistakeCounts[key],
          'related_lessons': categoryMistakes[category]
              ?.where((m) => m['concept'] == concept)
              .map((m) => m['lesson_id'])
              .toSet()
              .toList(),
        };
      }).toList();
    } catch (e) {
      _logger.e('Failed to get weak areas', error: e);
      return [];
    }
  }

  // Update lesson progress
  Future<void> updateLessonProgress(
    String userId,
    String lessonId, {
    int? progressPercentage,
    bool? isCompleted,
    int? score,
    int? timeSpentSeconds,
    List<Map<String, dynamic>>? mistakes,
    List<String>? strengths,
  }) async {
    try {
      if (_supabase.currentUserId == null) {
        return; // Offline progress not persisted for now
      }

      final existingResponse = await _supabase.client
          .from('user_lessons')
          .select()
          .eq('user_id', userId)
          .eq('lesson_id', lessonId)
          .single();

      final now = DateTime.now();
      
      // Update existing record
      final updates = <String, dynamic>{
        'last_accessed_at': now.toIso8601String(),
      };

      if (progressPercentage != null) {
        updates['progress_percentage'] = progressPercentage;
      }
      if (isCompleted != null && isCompleted) {
        updates['is_completed'] = true;
        updates['completed_at'] = now.toIso8601String();
      }
      if (score != null) {
        updates['score'] = score;
      }
      if (timeSpentSeconds != null) {
        final currentTime = existingResponse['time_spent_seconds'] ?? 0;
        updates['time_spent_seconds'] = currentTime + timeSpentSeconds;
      }
      if (mistakes != null && mistakes.isNotEmpty) {
        final currentMistakes = existingResponse['mistakes_made'] as List? ?? [];
        updates['mistakes_made'] = [...currentMistakes, ...mistakes];
      }
      if (strengths != null && strengths.isNotEmpty) {
        final currentStrengths = existingResponse['strengths_shown'] as List? ?? [];
        updates['strengths_shown'] = {...currentStrengths, ...strengths}.toList();
      }

      updates['attempts'] = (existingResponse['attempts'] ?? 0) + 1;

      await _supabase.client
          .from('user_lessons')
          .update(updates)
          .eq('user_id', userId)
          .eq('lesson_id', lessonId);
    
      // If lesson completed, update user XP and check for streak
      if (isCompleted == true) {
        await _updateUserProgress(userId, lessonId);
      }
    } catch (e) {
      _logger.e('Failed to update lesson progress', error: e);
      rethrow;
    }
  }

  Future<void> _updateUserProgress(String userId, String lessonId) async {
    try {
      // Get lesson XP reward
      final lessonResponse = await _supabase.client
          .from('lessons')
          .select('xp_reward')
          .eq('id', lessonId)
          .single();

      final xpReward = lessonResponse['xp_reward'] ?? 10;

      // Update user's total XP
      await _supabase.client.rpc('increment_user_xp', params: {
        'user_id': userId,
        'xp_amount': xpReward,
      });

      // Update streak
      await _supabase.client.rpc('update_user_streak', params: {
        'p_user_id': userId,
      });
    } catch (e) {
      _logger.e('Failed to update user progress', error: e);
    }
  }

  // Detect user's learning style based on their behavior
  Future<String> detectLearningStyle(String userId) async {
    try {
      if (_supabase.currentUserId == null) return 'visual';

      // Get user's lesson history with types
      final response = await _supabase.client
          .from('user_lessons')
          .select('''
            lessons!inner(lesson_type, content),
            time_spent_seconds,
            score
          ''')
          .eq('user_id', userId)
          .eq('is_completed', true);

      if (response.isEmpty) {
        return 'mixed';
      }

      // Analyze performance by lesson type
      final typeStats = <String, List<double>>{};

      for (var item in response) {
        final lessonType = item['lessons']['lesson_type'] as String? ?? 'mixed';
        final score = (item['score'] ?? 0).toDouble();
        final timeSpent = (item['time_spent_seconds'] ?? 0).toDouble();

        // Calculate efficiency score (higher score in less time = better)
        final efficiency = score > 0 ? score / (timeSpent / 60 + 1) : 0;

        typeStats.putIfAbsent(lessonType, () => []);
        typeStats[lessonType]!.add(efficiency);
      }

      // Calculate average efficiency for each type
      final typeAverages = <String, double>{};
      typeStats.forEach((type, scores) {
        if (scores.isNotEmpty) {
          typeAverages[type] = scores.reduce((a, b) => a + b) / scores.length;
        }
      });

      // Map lesson types to learning styles
      final styleScores = <String, double>{
        'visual': 0,
        'auditory': 0,
        'kinesthetic': 0,
        'reading_writing': 0,
      };

      typeAverages.forEach((type, score) {
        switch (type) {
          case 'vocabulary':
          case 'reading':
            styleScores['reading_writing'] = styleScores['reading_writing']! + score;
            break;
          case 'listening':
          case 'conversation':
            styleScores['auditory'] = styleScores['auditory']! + score;
            break;
          case 'grammar':
            styleScores['reading_writing'] = styleScores['reading_writing']! + score * 0.5;
            styleScores['visual'] = styleScores['visual']! + score * 0.5;
            break;
          case 'writing':
            styleScores['kinesthetic'] = styleScores['kinesthetic']! + score;
            break;
        }
      });

      // Find dominant style
      final dominantStyle = styleScores.entries
          .reduce((a, b) => a.value > b.value ? a : b);

      if (dominantStyle.value > 0) {
        return dominantStyle.key;
      }

      return 'mixed';
    } catch (e) {
      _logger.e('Failed to detect learning style', error: e);
      return 'mixed';
    }
  }

  // Update user's learning style
  Future<void> updateLearningStyle(String userId, String learningStyle) async {
    try {
      if (_supabase.currentUserId == null) return;

      await _supabase.client
          .from('user_learning_profiles')
          .upsert({
            'user_id': userId,
            'learning_style': learningStyle,
            'updated_at': DateTime.now().toIso8601String(),
          });
    } catch (e) {
      _logger.e('Failed to update learning style', error: e);
    }
  }

  // Get adaptive difficulty level recommendation
  Future<int> getRecommendedDifficulty(String userId, String courseId) async {
    try {
      if (_supabase.currentUserId == null) return 1;

      // Get recent lesson scores
      final response = await _supabase.client
          .from('user_lessons')
          .select('score')
          .eq('user_id', userId)
          .eq('is_completed', true)
          .order('completed_at', ascending: false)
          .limit(10);

      if (response.isEmpty) {
        return 1; // Start at level 1
      }

      final scores = (response as List)
          .map((item) => item['score'] as int? ?? 0)
          .toList();

      if (scores.isEmpty) return 1;

      final averageScore = scores.reduce((a, b) => a + b) / scores.length;

      // Adjust difficulty based on average score
      if (averageScore >= 90) {
        return 4; // Advanced
      } else if (averageScore >= 75) {
        return 3; // Intermediate-Advanced
      } else if (averageScore >= 60) {
        return 2; // Intermediate
      } else {
        return 1; // Beginner
      }
    } catch (e) {
      _logger.e('Failed to get recommended difficulty', error: e);
      return 1;
    }
  }

  // --- Offline Demo Data Fallbacks ---

  List<StoryModel> _getDemoStories(String courseId) {
    return [
      StoryModel(
        id: 's1',
        courseId: courseId,
        title: 'The Lost Keys',
        description: 'A beginner story about finding lost items.',
        difficultyLevel: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      StoryModel(
        id: 's2',
        courseId: courseId,
        title: 'A Trip to the Market',
        description: 'Learn food vocabulary in context.',
        difficultyLevel: 2,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
  }

  LearningPath _getDemoLearningPath(String userId, String courseId) {
    final nodes = [
      LearningPathNode(lessonId: 'l1', title: 'Basics 1', isUnlocked: true, isCompleted: true, difficultyLevel: 1, nextNodes: ['l2']),
      LearningPathNode(lessonId: 'l2', title: 'Greetings', isUnlocked: true, isCompleted: false, difficultyLevel: 1, nextNodes: ['l3'], recommendationReason: 'Continue where you left off'),
      LearningPathNode(lessonId: 'l3', title: 'Food', isUnlocked: false, isCompleted: false, difficultyLevel: 1, nextNodes: [], recommendationReason: 'Complete previous lessons to unlock'),
    ];
    return LearningPath(userId: userId, courseId: courseId, nodes: nodes, currentLevel: 1, learningStyle: 'visual', generatedAt: DateTime.now());
  }

  List<LessonModel> _getDemoRecommendedLessons(String courseId) {
    return [
      LessonModel(
        id: 'l2',
        courseId: courseId,
        title: 'Greetings',
        description: 'Learn how to say hello.',
        content: {},
        lessonType: 'vocabulary',
        difficultyLevel: 1,
        orderIndex: 1,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
  }
}
