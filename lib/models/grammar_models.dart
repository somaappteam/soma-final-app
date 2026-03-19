import 'package:flutter/material.dart';

/// Types of grammar skills
enum GrammarSkillType {
  conjugation,
  pattern,
  rule,
  exercise,
  quiz,
  mastery,
}

/// Represents a node in the grammar skill tree
class GrammarSkillNode {
  final String id;
  final String title;
  final String description;
  final GrammarSkillType type;
  final double x;
  final double y;
  final Color? color;
  final bool isUnlocked;
  final bool isCompleted;
  final double progress;
  final List<String> unlocks;
  final List<String> requires;
  final int xpReward;
  final int estimatedMinutes;
  final int difficultyLevel;
  final int totalLessons;
  final int completedLessons;
  final DateTime? completedAt;
  final IconData? icon;

  const GrammarSkillNode({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.x,
    required this.y,
    this.color,
    this.isUnlocked = false,
    this.isCompleted = false,
    this.progress = 0.0,
    this.unlocks = const [],
    this.requires = const [],
    this.xpReward = 10,
    this.estimatedMinutes = 5,
    this.difficultyLevel = 1,
    this.totalLessons = 1,
    this.completedLessons = 0,
    this.completedAt,
    this.icon,
  });

  // Alias getters
  List<String> get prerequisiteIds => requires;
  List<String> get unlocksIds => unlocks;
  bool get isLocked => !isUnlocked;
  bool get isInProgress => progress > 0 && !isCompleted;
  double get progressPercentage => progress;

  GrammarSkillNode copyWith({
    String? id,
    String? title,
    String? description,
    GrammarSkillType? type,
    double? x,
    double? y,
    Color? color,
    bool? isUnlocked,
    bool? isCompleted,
    double? progress,
    List<String>? unlocks,
    List<String>? requires,
    int? xpReward,
    int? estimatedMinutes,
    int? difficultyLevel,
    int? totalLessons,
    int? completedLessons,
    DateTime? completedAt,
    IconData? icon,
  }) {
    return GrammarSkillNode(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      x: x ?? this.x,
      y: y ?? this.y,
      color: color ?? this.color,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      isCompleted: isCompleted ?? this.isCompleted,
      progress: progress ?? this.progress,
      unlocks: unlocks ?? this.unlocks,
      requires: requires ?? this.requires,
      xpReward: xpReward ?? this.xpReward,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      totalLessons: totalLessons ?? this.totalLessons,
      completedLessons: completedLessons ?? this.completedLessons,
      completedAt: completedAt ?? this.completedAt,
      icon: icon ?? this.icon,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.name,
      'x': x,
      'y': y,
      'color': color?.toARGB32(),
      'isUnlocked': isUnlocked,
      'isCompleted': isCompleted,
      'progress': progress,
      'unlocks': unlocks,
      'requires': requires,
      'xpReward': xpReward,
      'estimatedMinutes': estimatedMinutes,
      'difficultyLevel': difficultyLevel,
      'totalLessons': totalLessons,
      'completedLessons': completedLessons,
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory GrammarSkillNode.fromJson(Map<String, dynamic> json) {
    return GrammarSkillNode(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      type: GrammarSkillType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => GrammarSkillType.rule,
      ),
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      color: json['color'] != null ? Color(json['color'] as int) : null,
      isUnlocked: json['isUnlocked'] as bool? ?? false,
      isCompleted: json['isCompleted'] as bool? ?? false,
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      unlocks: (json['unlocks'] as List<dynamic>?)?.cast<String>() ?? const [],
      requires: (json['requires'] as List<dynamic>?)?.cast<String>() ?? const [],
      xpReward: json['xpReward'] as int? ?? 10,
      estimatedMinutes: json['estimatedMinutes'] as int? ?? 5,
      difficultyLevel: json['difficultyLevel'] as int? ?? 1,
      totalLessons: json['totalLessons'] as int? ?? 1,
      completedLessons: json['completedLessons'] as int? ?? 0,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
    );
  }
}

/// User statistics for grammar learning
class UserGrammarStats {
  final String userId;
  final String language;
  final int totalSkills;
  final int completedSkills;
  final int unlockedSkills;
  final int totalLessonsCompleted;
  final int exercisesCompleted;
  final int correctExercises;
  final int streakDays;
  final DateTime? lastPracticeDate;
  final Map<String, double> skillProgress;

  const UserGrammarStats({
    required this.userId,
    required this.language,
    this.totalSkills = 0,
    this.completedSkills = 0,
    this.unlockedSkills = 1,
    this.totalLessonsCompleted = 0,
    this.exercisesCompleted = 0,
    this.correctExercises = 0,
    this.streakDays = 0,
    this.lastPracticeDate,
    this.skillProgress = const {},
  });

  // Alias getters
  int get currentStreak => streakDays;
  
  double get completionRate => totalSkills > 0 ? completedSkills / totalSkills : 0.0;
  
  double get accuracyRate => exercisesCompleted > 0 
      ? correctExercises / exercisesCompleted 
      : 0.0;
  
  double get overallMastery {
    if (skillProgress.isEmpty) return 0.0;
    final totalProgress = skillProgress.values.fold(0.0, (sum, progress) => sum + progress);
    return totalProgress / skillProgress.length;
  }
  
  String get masteryLevel {
    final mastery = overallMastery;
    if (mastery >= 0.9) return 'Master';
    if (mastery >= 0.75) return 'Expert';
    if (mastery >= 0.5) return 'Intermediate';
    if (mastery >= 0.25) return 'Beginner';
    return 'Novice';
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'language': language,
      'totalSkills': totalSkills,
      'completedSkills': completedSkills,
      'unlockedSkills': unlockedSkills,
      'totalLessonsCompleted': totalLessonsCompleted,
      'exercisesCompleted': exercisesCompleted,
      'correctExercises': correctExercises,
      'streakDays': streakDays,
      'lastPracticeDate': lastPracticeDate?.toIso8601String(),
      'skillProgress': skillProgress,
    };
  }

  factory UserGrammarStats.fromJson(Map<String, dynamic> json) {
    return UserGrammarStats(
      userId: json['userId'] as String,
      language: json['language'] as String,
      totalSkills: json['totalSkills'] as int? ?? 0,
      completedSkills: json['completedSkills'] as int? ?? 0,
      unlockedSkills: json['unlockedSkills'] as int? ?? 1,
      totalLessonsCompleted: json['totalLessonsCompleted'] as int? ?? 0,
      exercisesCompleted: json['exercisesCompleted'] as int? ?? 0,
      correctExercises: json['correctExercises'] as int? ?? 0,
      streakDays: json['streakDays'] as int? ?? 0,
      lastPracticeDate: json['lastPracticeDate'] != null 
          ? DateTime.parse(json['lastPracticeDate'] as String)
          : null,
      skillProgress: (json['skillProgress'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, (v as num).toDouble()),
          ) ?? const {},
    );
  }
}

/// Represents a grammar exercise
class GrammarExercise {
  final String id;
  final String skillId;
  final String question;
  final String correctAnswer;
  final List<String> options;
  final String explanation;
  final int difficulty;

  const GrammarExercise({
    required this.id,
    required this.skillId,
    required this.question,
    required this.correctAnswer,
    this.options = const [],
    this.explanation = '',
    this.difficulty = 1,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'skillId': skillId,
      'question': question,
      'correctAnswer': correctAnswer,
      'options': options,
      'explanation': explanation,
      'difficulty': difficulty,
    };
  }

  factory GrammarExercise.fromJson(Map<String, dynamic> json) {
    return GrammarExercise(
      id: json['id'] as String,
      skillId: json['skillId'] as String,
      question: json['question'] as String,
      correctAnswer: json['correctAnswer'] as String,
      options: (json['options'] as List<dynamic>?)?.cast<String>() ?? const [],
      explanation: json['explanation'] as String? ?? '',
      difficulty: json['difficulty'] as int? ?? 1,
    );
  }
}

/// Represents a grammar lesson
class GrammarLesson {
  final String id;
  final String skillId;
  final String title;
  final String content;
  final int orderIndex;
  final List<GrammarExercise> exercises;

  const GrammarLesson({
    required this.id,
    required this.skillId,
    required this.title,
    required this.content,
    this.orderIndex = 0,
    this.exercises = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'skillId': skillId,
      'title': title,
      'content': content,
      'orderIndex': orderIndex,
      'exercises': exercises.map((e) => e.toJson()).toList(),
    };
  }

  factory GrammarLesson.fromJson(Map<String, dynamic> json) {
    return GrammarLesson(
      id: json['id'] as String,
      skillId: json['skillId'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      orderIndex: json['orderIndex'] as int? ?? 0,
      exercises: (json['exercises'] as List<dynamic>?)
              ?.map((e) => GrammarExercise.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}

/// Represents verb conjugation data
class VerbConjugation {
  final String infinitive;
  final String language;
  final Map<String, Map<String, String>> conjugations;
  final bool isIrregular;
  final String tense;
  final String mood;

  const VerbConjugation({
    required this.infinitive,
    required this.language,
    required this.conjugations,
    this.isIrregular = false,
    this.tense = 'present',
    this.mood = 'indicative',
  });

  // Alias getters
  bool get isRegular => !isIrregular;
  
  List<String> get allPersons {
    final persons = <String>{};
    for (final tenseConjugations in conjugations.values) {
      persons.addAll(tenseConjugations.keys);
    }
    return persons.toList();
  }

  String? getConjugation(String tense, String person) {
    return conjugations[tense]?[person];
  }

  Map<String, dynamic> toJson() {
    return {
      'infinitive': infinitive,
      'language': language,
      'conjugations': conjugations,
      'isIrregular': isIrregular,
      'tense': tense,
      'mood': mood,
    };
  }

  factory VerbConjugation.fromJson(Map<String, dynamic> json) {
    return VerbConjugation(
      infinitive: json['infinitive'] as String,
      language: json['language'] as String,
      conjugations: (json['conjugations'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(
          key,
          (value as Map<String, dynamic>).map(
            (k, v) => MapEntry(k, v as String),
          ),
        ),
      ),
      isIrregular: json['isIrregular'] as bool? ?? false,
      tense: json['tense'] as String? ?? 'present',
      mood: json['mood'] as String? ?? 'indicative',
    );
  }
}

/// Represents a sentence pattern for grammar learning
class SentencePattern {
  final String id;
  final String title;
  final String pattern;
  final String explanation;
  final List<String> examples;
  final String difficulty;

  const SentencePattern({
    required this.id,
    required this.title,
    required this.pattern,
    required this.explanation,
    this.examples = const [],
    this.difficulty = 'beginner',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'pattern': pattern,
      'explanation': explanation,
      'examples': examples,
      'difficulty': difficulty,
    };
  }

  factory SentencePattern.fromJson(Map<String, dynamic> json) {
    return SentencePattern(
      id: json['id'] as String,
      title: json['title'] as String,
      pattern: json['pattern'] as String,
      explanation: json['explanation'] as String,
      examples: (json['examples'] as List<dynamic>?)?.cast<String>() ?? const [],
      difficulty: json['difficulty'] as String? ?? 'beginner',
    );
  }
}

/// Represents grammar lesson content
class GrammarLessonContent {
  final String id;
  final String title;
  final String body;
  final List<String> examples;
  final List<String> tips;
  final String? imageUrl;

  const GrammarLessonContent({
    required this.id,
    required this.title,
    required this.body,
    this.examples = const [],
    this.tips = const [],
    this.imageUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'examples': examples,
      'tips': tips,
      'imageUrl': imageUrl,
    };
  }

  factory GrammarLessonContent.fromJson(Map<String, dynamic> json) {
    return GrammarLessonContent(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      examples: (json['examples'] as List<dynamic>?)?.cast<String>() ?? const [],
      tips: (json['tips'] as List<dynamic>?)?.cast<String>() ?? const [],
      imageUrl: json['imageUrl'] as String?,
    );
  }
}

/// Represents a grammar error pattern for error correction
class GrammarErrorPattern {
  final String id;
  final String errorType;
  final String incorrectPattern;
  final String correctPattern;
  final String explanation;
  final String difficulty;

  const GrammarErrorPattern({
    required this.id,
    required this.errorType,
    required this.incorrectPattern,
    required this.correctPattern,
    required this.explanation,
    this.difficulty = 'beginner',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'errorType': errorType,
      'incorrectPattern': incorrectPattern,
      'correctPattern': correctPattern,
      'explanation': explanation,
      'difficulty': difficulty,
    };
  }

  factory GrammarErrorPattern.fromJson(Map<String, dynamic> json) {
    return GrammarErrorPattern(
      id: json['id'] as String,
      errorType: json['errorType'] as String,
      incorrectPattern: json['incorrectPattern'] as String,
      correctPattern: json['correctPattern'] as String,
      explanation: json['explanation'] as String,
      difficulty: json['difficulty'] as String? ?? 'beginner',
    );
  }
}

