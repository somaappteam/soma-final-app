class GrammarLesson {
  final String id;
  final String courseId;
  final String title;
  final String explanation;
  final String ruleCategory; // e.g., 'tenses', 'cases', 'articles'
  final int difficultyLevel;
  final Map<String, dynamic>? visualDiagram;
  final List<GrammarExample> examples;
  final List<GrammarException> exceptions;
  final List<GrammarExercise> exercises;
  final List<String> relatedLessons;
  final DateTime createdAt;
  final DateTime updatedAt;

  GrammarLesson({
    required this.id,
    required this.courseId,
    required this.title,
    required this.explanation,
    required this.ruleCategory,
    this.difficultyLevel = 1,
    this.visualDiagram,
    this.examples = const [],
    this.exceptions = const [],
    this.exercises = const [],
    this.relatedLessons = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory GrammarLesson.fromJson(Map<String, dynamic> json) {
    return GrammarLesson(
      id: json['id'],
      courseId: json['course_id'],
      title: json['title'],
      explanation: json['explanation'],
      ruleCategory: json['rule_category'],
      difficultyLevel: json['difficulty_level'] ?? 1,
      visualDiagram: json['visual_diagram'],
      examples: (json['examples'] as List? ?? [])
          .map((e) => GrammarExample.fromJson(e))
          .toList(),
      exceptions: (json['exceptions'] as List? ?? [])
          .map((e) => GrammarException.fromJson(e))
          .toList(),
      exercises: (json['exercises'] as List? ?? [])
          .map((e) => GrammarExercise.fromJson(e))
          .toList(),
      relatedLessons: List<String>.from(json['related_lessons'] ?? []),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'course_id': courseId,
      'title': title,
      'explanation': explanation,
      'rule_category': ruleCategory,
      'difficulty_level': difficultyLevel,
      'visual_diagram': visualDiagram,
      'examples': examples.map((e) => e.toJson()).toList(),
      'exceptions': exceptions.map((e) => e.toJson()).toList(),
      'exercises': exercises.map((e) => e.toJson()).toList(),
      'related_lessons': relatedLessons,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class GrammarExample {
  final String correct;
  final String? incorrect;
  final String? explanation;
  final String? translation;

  GrammarExample({
    required this.correct,
    this.incorrect,
    this.explanation,
    this.translation,
  });

  factory GrammarExample.fromJson(Map<String, dynamic> json) {
    return GrammarExample(
      correct: json['correct'],
      incorrect: json['incorrect'],
      explanation: json['explanation'],
      translation: json['translation'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'correct': correct,
      'incorrect': incorrect,
      'explanation': explanation,
      'translation': translation,
    };
  }
}

class GrammarException {
  final String exception;
  final String explanation;
  final String? example;

  GrammarException({
    required this.exception,
    required this.explanation,
    this.example,
  });

  factory GrammarException.fromJson(Map<String, dynamic> json) {
    return GrammarException(
      exception: json['exception'],
      explanation: json['explanation'],
      example: json['example'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exception': exception,
      'explanation': explanation,
      'example': example,
    };
  }
}

class GrammarExercise {
  final String id;
  final String type; // 'fill_blank', 'multiple_choice', 'sentence_correction', 'reordering'
  final String question;
  final String? correctAnswer;
  final List<String>? options;
  final String? hint;
  final String? explanation;
  final int points;

  GrammarExercise({
    required this.id,
    required this.type,
    required this.question,
    this.correctAnswer,
    this.options,
    this.hint,
    this.explanation,
    this.points = 10,
  });

  factory GrammarExercise.fromJson(Map<String, dynamic> json) {
    return GrammarExercise(
      id: json['id'],
      type: json['type'],
      question: json['question'],
      correctAnswer: json['correct_answer'],
      options: json['options'] != null ? List<String>.from(json['options']) : null,
      hint: json['hint'],
      explanation: json['explanation'],
      points: json['points'] ?? 10,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'question': question,
      'correct_answer': correctAnswer,
      'options': options,
      'hint': hint,
      'explanation': explanation,
      'points': points,
    };
  }
}

class UserGrammarProgress {
  final String id;
  final String userId;
  final String grammarRuleId;
  int masteryPercentage;
  bool isMastered;
  int exercisesCompleted;
  int exercisesCorrect;
  final List<Map<String, dynamic>> mistakes;
  DateTime? lastPracticedAt;
  DateTime? masteredAt;
  final DateTime createdAt;
  DateTime updatedAt;

  UserGrammarProgress({
    required this.id,
    required this.userId,
    required this.grammarRuleId,
    this.masteryPercentage = 0,
    this.isMastered = false,
    this.exercisesCompleted = 0,
    this.exercisesCorrect = 0,
    this.mistakes = const [],
    this.lastPracticedAt,
    this.masteredAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserGrammarProgress.fromJson(Map<String, dynamic> json) {
    return UserGrammarProgress(
      id: json['id'],
      userId: json['user_id'],
      grammarRuleId: json['grammar_rule_id'],
      masteryPercentage: json['mastery_percentage'] ?? 0,
      isMastered: json['is_mastered'] ?? false,
      exercisesCompleted: json['exercises_completed'] ?? 0,
      exercisesCorrect: json['exercises_correct'] ?? 0,
      mistakes: List<Map<String, dynamic>>.from(json['mistakes'] ?? []),
      lastPracticedAt: json['last_practiced_at'] != null 
          ? DateTime.parse(json['last_practiced_at']) 
          : null,
      masteredAt: json['mastered_at'] != null 
          ? DateTime.parse(json['mastered_at']) 
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'grammar_rule_id': grammarRuleId,
      'mastery_percentage': masteryPercentage,
      'is_mastered': isMastered,
      'exercises_completed': exercisesCompleted,
      'exercises_correct': exercisesCorrect,
      'mistakes': mistakes,
      'last_practiced_at': lastPracticedAt?.toIso8601String(),
      'mastered_at': masteredAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  void updateProgress(bool isCorrect) {
    exercisesCompleted++;
    if (isCorrect) {
      exercisesCorrect++;
    }
    
    // Calculate mastery percentage
    if (exercisesCompleted > 0) {
      double accuracy = exercisesCorrect / exercisesCompleted;
      masteryPercentage = (accuracy * 100).round();
      
      // Mastered if >= 80% accuracy and at least 5 exercises
      if (masteryPercentage >= 80 && exercisesCompleted >= 5 && !isMastered) {
        isMastered = true;
        masteredAt = DateTime.now();
      }
    }
    
    lastPracticedAt = DateTime.now();
    updatedAt = DateTime.now();
  }

  double get accuracyRate {
    if (exercisesCompleted == 0) return 0.0;
    return exercisesCorrect / exercisesCompleted;
  }
}

enum GrammarRuleCategory {
  tenses,
  articles,
  prepositions,
  pronouns,
  adjectives,
  adverbs,
  conjunctions,
  cases,
  wordOrder,
  negation,
  questions,
  conditionals,
  passiveVoice,
  reportedSpeech,
  relativeClauses,
}

extension GrammarRuleCategoryExtension on GrammarRuleCategory {
  String get displayName {
    switch (this) {
      case GrammarRuleCategory.tenses:
        return 'Tenses';
      case GrammarRuleCategory.articles:
        return 'Articles';
      case GrammarRuleCategory.prepositions:
        return 'Prepositions';
      case GrammarRuleCategory.pronouns:
        return 'Pronouns';
      case GrammarRuleCategory.adjectives:
        return 'Adjectives';
      case GrammarRuleCategory.adverbs:
        return 'Adverbs';
      case GrammarRuleCategory.conjunctions:
        return 'Conjunctions';
      case GrammarRuleCategory.cases:
        return 'Grammatical Cases';
      case GrammarRuleCategory.wordOrder:
        return 'Word Order';
      case GrammarRuleCategory.negation:
        return 'Negation';
      case GrammarRuleCategory.questions:
        return 'Questions';
      case GrammarRuleCategory.conditionals:
        return 'Conditionals';
      case GrammarRuleCategory.passiveVoice:
        return 'Passive Voice';
      case GrammarRuleCategory.reportedSpeech:
        return 'Reported Speech';
      case GrammarRuleCategory.relativeClauses:
        return 'Relative Clauses';
    }
  }
}
