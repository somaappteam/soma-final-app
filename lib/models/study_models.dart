import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Represents a story for reading practice
class Story {
  final String id;
  final String title;
  final String? nativeTitle;
  final String? author;
  final String content;
  final String language;
  final String difficulty;
  final List<StoryAnnotation> annotations;
  final int estimatedReadTime;
  final String? coverImageUrl;
  final List<String> tags;
  final int wordCount;
  final List<String> grammarFocus;
  final List<String> vocabularyFocus;
  final List<ComprehensionQuestion> questions;

  const Story({
    required this.id,
    required this.title,
    this.nativeTitle,
    this.author,
    required this.content,
    required this.language,
    this.difficulty = 'beginner',
    this.annotations = const [],
    this.estimatedReadTime = 5,
    this.coverImageUrl,
    this.tags = const [],
    this.wordCount = 0,
    this.grammarFocus = const [],
    this.vocabularyFocus = const [],
    this.questions = const [],
  });

  Color get difficultyColor {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return AppColors.success;
      case 'intermediate':
        return AppColors.accentCoral;
      case 'advanced':
        return AppColors.error;
      default:
        return AppColors.primaryTeal;
    }
  }

  String get difficultyDisplay {
    return difficulty.substring(0, 1).toUpperCase() + difficulty.substring(1);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'nativeTitle': nativeTitle,
      'author': author,
      'content': content,
      'language': language,
      'difficulty': difficulty,
      'annotations': annotations.map((a) => a.toJson()).toList(),
      'estimatedReadTime': estimatedReadTime,
      'coverImageUrl': coverImageUrl,
      'tags': tags,
      'wordCount': wordCount,
      'grammarFocus': grammarFocus,
      'vocabularyFocus': vocabularyFocus,
      'questions': questions.map((q) => q.toJson()).toList(),
    };
  }

  factory Story.fromJson(Map<String, dynamic> json) {
    return Story(
      id: json['id'] as String,
      title: json['title'] as String,
      nativeTitle: json['nativeTitle'] as String?,
      author: json['author'] as String?,
      content: json['content'] as String,
      language: json['language'] as String,
      difficulty: json['difficulty'] as String? ?? 'beginner',
      annotations: (json['annotations'] as List<dynamic>?)
              ?.map((a) => StoryAnnotation.fromJson(a as Map<String, dynamic>))
              .toList() ??
          const [],
      estimatedReadTime: json['estimatedReadTime'] as int? ?? 5,
      coverImageUrl: json['coverImageUrl'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? const [],
      wordCount: json['wordCount'] as int? ?? 0,
      grammarFocus: (json['grammarFocus'] as List<dynamic>?)?.cast<String>() ?? const [],
      vocabularyFocus: (json['vocabularyFocus'] as List<dynamic>?)?.cast<String>() ?? const [],
      questions: (json['questions'] as List<dynamic>?)
              ?.map((q) => ComprehensionQuestion.fromJson(q as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}

/// Represents a user's progress on a story
class UserStoryProgress {
  final String userId;
  final String storyId;
  final double progressPercent;
  final int currentParagraphIndex;
  final int currentPosition;
  final bool isCompleted;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final int timeSpentSeconds;
  final int? comprehensionScore;
  final List<StoryBookmark> bookmarks;
  final List<StoryNote> notes;

  const UserStoryProgress({
    required this.userId,
    required this.storyId,
    this.progressPercent = 0.0,
    this.currentParagraphIndex = 0,
    this.currentPosition = 0,
    this.isCompleted = false,
    this.startedAt,
    this.completedAt,
    this.timeSpentSeconds = 0,
    this.comprehensionScore,
    this.bookmarks = const [],
    this.notes = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'storyId': storyId,
      'progressPercent': progressPercent,
      'currentParagraphIndex': currentParagraphIndex,
      'currentPosition': currentPosition,
      'isCompleted': isCompleted,
      'startedAt': startedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'timeSpentSeconds': timeSpentSeconds,
      'comprehensionScore': comprehensionScore,
      'bookmarks': bookmarks.map((b) => b.toJson()).toList(),
      'notes': notes.map((n) => n.toJson()).toList(),
    };
  }

  factory UserStoryProgress.fromJson(Map<String, dynamic> json) {
    return UserStoryProgress(
      userId: json['userId'] as String,
      storyId: json['storyId'] as String,
      progressPercent: (json['progressPercent'] as num?)?.toDouble() ?? 0.0,
      currentParagraphIndex: json['currentParagraphIndex'] as int? ?? 0,
      currentPosition: json['currentPosition'] as int? ?? 0,
      isCompleted: json['isCompleted'] as bool? ?? false,
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'] as String)
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      timeSpentSeconds: json['timeSpentSeconds'] as int? ?? 0,
      comprehensionScore: json['comprehensionScore'] as int?,
      bookmarks: (json['bookmarks'] as List<dynamic>?)
              ?.map((b) => StoryBookmark.fromJson(b as Map<String, dynamic>))
              .toList() ??
          const [],
      notes: (json['notes'] as List<dynamic>?)
              ?.map((n) => StoryNote.fromJson(n as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}

/// Represents an annotation in a story (word/phrase translation)
class StoryAnnotation {
  final String id;
  final String word;
  final String text;
  final String translation;
  final String? pronunciation;
  final String? definition;
  final String? vocabularyDefinition;
  final String? grammarNote;
  final int startOffset;
  final int endOffset;

  const StoryAnnotation({
    required this.id,
    required this.word,
    required this.text,
    required this.translation,
    this.pronunciation,
    this.definition,
    this.vocabularyDefinition,
    this.grammarNote,
    required this.startOffset,
    required this.endOffset,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'word': word,
      'text': text,
      'translation': translation,
      'pronunciation': pronunciation,
      'definition': definition,
      'vocabularyDefinition': vocabularyDefinition,
      'grammarNote': grammarNote,
      'startOffset': startOffset,
      'endOffset': endOffset,
    };
  }

  factory StoryAnnotation.fromJson(Map<String, dynamic> json) {
    return StoryAnnotation(
      id: json['id'] as String,
      word: json['word'] as String,
      text: json['text'] as String,
      translation: json['translation'] as String,
      pronunciation: json['pronunciation'] as String?,
      definition: json['definition'] as String?,
      vocabularyDefinition: json['vocabularyDefinition'] as String?,
      grammarNote: json['grammarNote'] as String?,
      startOffset: json['startOffset'] as int,
      endOffset: json['endOffset'] as int,
    );
  }
}

/// Represents a bookmark in a story
class StoryBookmark {
  final String id;
  final int paragraphIndex;
  final String? note;
  final DateTime createdAt;

  const StoryBookmark({
    required this.id,
    required this.paragraphIndex,
    this.note,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'paragraphIndex': paragraphIndex,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory StoryBookmark.fromJson(Map<String, dynamic> json) {
    return StoryBookmark(
      id: json['id'] as String,
      paragraphIndex: json['paragraphIndex'] as int,
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

/// Represents a user's note on a story
class StoryNote {
  final String id;
  final int paragraphIndex;
  final String content;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const StoryNote({
    required this.id,
    required this.paragraphIndex,
    required this.content,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'paragraphIndex': paragraphIndex,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory StoryNote.fromJson(Map<String, dynamic> json) {
    return StoryNote(
      id: json['id'] as String,
      paragraphIndex: json['paragraphIndex'] as int,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }
}

/// Represents a comprehension question for a story
class ComprehensionQuestion {
  final String id;
  final String question;
  final List<String> options;
  final int correctOptionIndex;
  final String explanation;

  const ComprehensionQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctOptionIndex,
    required this.explanation,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'options': options,
      'correctOptionIndex': correctOptionIndex,
      'explanation': explanation,
    };
  }

  factory ComprehensionQuestion.fromJson(Map<String, dynamic> json) {
    return ComprehensionQuestion(
      id: json['id'] as String,
      question: json['question'] as String,
      options: (json['options'] as List<dynamic>).cast<String>(),
      correctOptionIndex: json['correctOptionIndex'] as int,
      explanation: json['explanation'] as String,
    );
  }
}

/// Represents a podcast episode
class Podcast {
  final String id;
  final String title;
  final String? description;
  final String language;
  final String difficulty;
  final int durationSeconds;
  final String audioUrl;
  final String? coverImageUrl;
  final List<String> tags;
  final DateTime? publishedAt;

  const Podcast({
    required this.id,
    required this.title,
    this.description,
    required this.language,
    this.difficulty = 'beginner',
    required this.durationSeconds,
    required this.audioUrl,
    this.coverImageUrl,
    this.tags = const [],
    this.publishedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'language': language,
      'difficulty': difficulty,
      'durationSeconds': durationSeconds,
      'audioUrl': audioUrl,
      'coverImageUrl': coverImageUrl,
      'tags': tags,
      'publishedAt': publishedAt?.toIso8601String(),
    };
  }

  factory Podcast.fromJson(Map<String, dynamic> json) {
    return Podcast(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      language: json['language'] as String,
      difficulty: json['difficulty'] as String? ?? 'beginner',
      durationSeconds: json['durationSeconds'] as int,
      audioUrl: json['audioUrl'] as String,
      coverImageUrl: json['coverImageUrl'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? const [],
      publishedAt: json['publishedAt'] != null
          ? DateTime.parse(json['publishedAt'] as String)
          : null,
    );
  }
}

/// Represents user's progress on a podcast
class UserPodcastProgress {
  final String userId;
  final String podcastId;
  final int currentPositionSeconds;
  final bool isCompleted;
  final double? playbackSpeed;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final int totalListeningTimeSeconds;

  const UserPodcastProgress({
    required this.userId,
    required this.podcastId,
    this.currentPositionSeconds = 0,
    this.isCompleted = false,
    this.playbackSpeed,
    this.startedAt,
    this.completedAt,
    this.totalListeningTimeSeconds = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'podcastId': podcastId,
      'currentPositionSeconds': currentPositionSeconds,
      'isCompleted': isCompleted,
      'playbackSpeed': playbackSpeed,
      'startedAt': startedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'totalListeningTimeSeconds': totalListeningTimeSeconds,
    };
  }

  factory UserPodcastProgress.fromJson(Map<String, dynamic> json) {
    return UserPodcastProgress(
      userId: json['userId'] as String,
      podcastId: json['podcastId'] as String,
      currentPositionSeconds: json['currentPositionSeconds'] as int? ?? 0,
      isCompleted: json['isCompleted'] as bool? ?? false,
      playbackSpeed: (json['playbackSpeed'] as num?)?.toDouble(),
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'] as String)
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      totalListeningTimeSeconds: json['totalListeningTimeSeconds'] as int? ?? 0,
    );
  }
}

/// Represents a study schedule
class StudySchedule {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final bool isActive;
  final DateTime startDate;
  final DateTime? endDate;
  final int dailyGoalMinutes;
  final int daysPerWeek;
  final List<String> focusAreas;
  final bool reminderEnabled;
  final String? reminderTime;
  final List<int> reminderDays;

  const StudySchedule({
    required this.id,
    required this.userId,
    this.name = 'My Study Plan',
    this.description,
    this.isActive = true,
    required this.startDate,
    this.endDate,
    this.dailyGoalMinutes = 15,
    this.daysPerWeek = 5,
    this.focusAreas = const ['vocabulary', 'grammar', 'reading'],
    this.reminderEnabled = true,
    this.reminderTime,
    this.reminderDays = const [1, 2, 3, 4, 5],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'description': description,
      'isActive': isActive,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'dailyGoalMinutes': dailyGoalMinutes,
      'daysPerWeek': daysPerWeek,
      'focusAreas': focusAreas,
      'reminderEnabled': reminderEnabled,
      'reminderTime': reminderTime,
      'reminderDays': reminderDays,
    };
  }

  factory StudySchedule.fromJson(Map<String, dynamic> json) {
    return StudySchedule(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String? ?? 'My Study Plan',
      description: json['description'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
      dailyGoalMinutes: json['dailyGoalMinutes'] as int? ?? 15,
      daysPerWeek: json['daysPerWeek'] as int? ?? 5,
      focusAreas: (json['focusAreas'] as List<dynamic>?)?.cast<String>() ??
          const ['vocabulary', 'grammar', 'reading'],
      reminderEnabled: json['reminderEnabled'] as bool? ?? true,
      reminderTime: json['reminderTime'] as String?,
      reminderDays: (json['reminderDays'] as List<dynamic>?)?.cast<int>() ??
          const [1, 2, 3, 4, 5],
    );
  }
}

/// Represents a study session
class StudySession {
  final String id;
  final String userId;
  final String sessionType;
  final String activityId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int durationMinutes;
  final int itemsStudied;
  final int correctCount;
  final int incorrectCount;
  final int xpEarned;
  final String? notes;
  final DateTime createdAt;

  const StudySession({
    required this.id,
    required this.userId,
    required this.sessionType,
    required this.activityId,
    required this.startedAt,
    this.endedAt,
    this.durationMinutes = 0,
    this.itemsStudied = 0,
    this.correctCount = 0,
    this.incorrectCount = 0,
    this.xpEarned = 0,
    this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'sessionType': sessionType,
      'activityId': activityId,
      'startedAt': startedAt.toIso8601String(),
      'endedAt': endedAt?.toIso8601String(),
      'durationMinutes': durationMinutes,
      'itemsStudied': itemsStudied,
      'correctCount': correctCount,
      'incorrectCount': incorrectCount,
      'xpEarned': xpEarned,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory StudySession.fromJson(Map<String, dynamic> json) {
    return StudySession(
      id: json['id'] as String,
      userId: json['userId'] as String,
      sessionType: json['sessionType'] as String,
      activityId: json['activityId'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
      endedAt: json['endedAt'] != null
          ? DateTime.parse(json['endedAt'] as String)
          : null,
      durationMinutes: json['durationMinutes'] as int? ?? 0,
      itemsStudied: json['itemsStudied'] as int? ?? 0,
      correctCount: json['correctCount'] as int? ?? 0,
      incorrectCount: json['incorrectCount'] as int? ?? 0,
      xpEarned: json['xpEarned'] as int? ?? 0,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

/// Represents a study reminder
class StudyReminder {
  final String id;
  final String userId;
  final String title;
  final String message;
  final DateTime scheduledAt;
  final bool isRecurring;
  final RecurrencePattern? recurrencePattern;
  final bool isActive;
  final DateTime createdAt;

  const StudyReminder({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.scheduledAt,
    this.isRecurring = false,
    this.recurrencePattern,
    this.isActive = true,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'message': message,
      'scheduledAt': scheduledAt.toIso8601String(),
      'isRecurring': isRecurring,
      'recurrencePattern': recurrencePattern?.toJson(),
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory StudyReminder.fromJson(Map<String, dynamic> json) {
    return StudyReminder(
      id: json['id'] as String,
      userId: json['userId'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      scheduledAt: DateTime.parse(json['scheduledAt'] as String),
      isRecurring: json['isRecurring'] as bool? ?? false,
      recurrencePattern: json['recurrencePattern'] != null
          ? RecurrencePattern.fromJson(json['recurrencePattern'] as Map<String, dynamic>)
          : null,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

/// Represents a recurrence pattern for reminders
class RecurrencePattern {
  final String frequency;
  final int interval;
  final List<int>? daysOfWeek;
  final int? dayOfMonth;

  const RecurrencePattern({
    required this.frequency,
    this.interval = 1,
    this.daysOfWeek,
    this.dayOfMonth,
  });

  Map<String, dynamic> toJson() {
    return {
      'frequency': frequency,
      'interval': interval,
      'daysOfWeek': daysOfWeek,
      'dayOfMonth': dayOfMonth,
    };
  }

  factory RecurrencePattern.fromJson(Map<String, dynamic> json) {
    return RecurrencePattern(
      frequency: json['frequency'] as String,
      interval: json['interval'] as int? ?? 1,
      daysOfWeek: (json['daysOfWeek'] as List<dynamic>?)?.cast<int>(),
      dayOfMonth: json['dayOfMonth'] as int?,
    );
  }
}

/// Represents study preferences
class StudyPreferences {
  final String userId;
  final int dailyGoalMinutes;
  final int wordsPerSession;
  final bool autoAdvance;
  final bool showRomanization;
  final String fontSize;
  final String difficultyLevel;
  final bool spacedRepetitionEnabled;
  final bool soundEnabled;
  final bool hapticFeedbackEnabled;
  final bool notificationsEnabled;
  final DateTime updatedAt;

  const StudyPreferences({
    required this.userId,
    this.dailyGoalMinutes = 15,
    this.wordsPerSession = 10,
    this.autoAdvance = true,
    this.showRomanization = false,
    this.fontSize = 'medium',
    this.difficultyLevel = 'adaptive',
    this.spacedRepetitionEnabled = true,
    this.soundEnabled = true,
    this.hapticFeedbackEnabled = true,
    this.notificationsEnabled = true,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'dailyGoalMinutes': dailyGoalMinutes,
      'wordsPerSession': wordsPerSession,
      'autoAdvance': autoAdvance,
      'showRomanization': showRomanization,
      'fontSize': fontSize,
      'difficultyLevel': difficultyLevel,
      'spacedRepetitionEnabled': spacedRepetitionEnabled,
      'soundEnabled': soundEnabled,
      'hapticFeedbackEnabled': hapticFeedbackEnabled,
      'notificationsEnabled': notificationsEnabled,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory StudyPreferences.fromJson(Map<String, dynamic> json) {
    return StudyPreferences(
      userId: json['userId'] as String,
      dailyGoalMinutes: json['dailyGoalMinutes'] as int? ?? 15,
      wordsPerSession: json['wordsPerSession'] as int? ?? 10,
      autoAdvance: json['autoAdvance'] as bool? ?? true,
      showRomanization: json['showRomanization'] as bool? ?? false,
      fontSize: json['fontSize'] as String? ?? 'medium',
      difficultyLevel: json['difficultyLevel'] as String? ?? 'adaptive',
      spacedRepetitionEnabled: json['spacedRepetitionEnabled'] as bool? ?? true,
      soundEnabled: json['soundEnabled'] as bool? ?? true,
      hapticFeedbackEnabled: json['hapticFeedbackEnabled'] as bool? ?? true,
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }
}

/// Represents a Pomodoro session
class PomodoroSession {
  final String id;
  final String userId;
  final String? taskId;
  final DateTime startTime;
  final DateTime? endTime;
  final int workDuration;
  final int breakDuration;
  final int totalCycles;
  int completedCycles;
  bool isActive;
  bool isBreak;
  int currentCycle;
  final String? notes;

  PomodoroSession({
    required this.id,
    required this.userId,
    this.taskId,
    required this.startTime,
    this.endTime,
    this.workDuration = 25,
    this.breakDuration = 5,
    this.totalCycles = 4,
    this.completedCycles = 0,
    this.isActive = true,
    this.isBreak = false,
    this.currentCycle = 1,
    this.notes,
  });

  int get currentPhaseDuration => isBreak ? breakDuration : workDuration;
  bool get isComplete => completedCycles >= totalCycles;

  void completeCycle() {
    if (!isBreak) {
      isBreak = true;
    } else {
      completedCycles++;
      isBreak = false;
      currentCycle++;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'taskId': taskId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'workDuration': workDuration,
      'breakDuration': breakDuration,
      'totalCycles': totalCycles,
      'completedCycles': completedCycles,
      'isActive': isActive,
      'isBreak': isBreak,
      'currentCycle': currentCycle,
      'notes': notes,
    };
  }

  factory PomodoroSession.fromJson(Map<String, dynamic> json) {
    return PomodoroSession(
      id: json['id'] as String,
      userId: json['userId'] as String,
      taskId: json['taskId'] as String?,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
      workDuration: json['workDuration'] as int? ?? 25,
      breakDuration: json['breakDuration'] as int? ?? 5,
      totalCycles: json['totalCycles'] as int? ?? 4,
      completedCycles: json['completedCycles'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      isBreak: json['isBreak'] as bool? ?? false,
      currentCycle: json['currentCycle'] as int? ?? 1,
      notes: json['notes'] as String?,
    );
  }
}

/// Represents study analytics data point
class StudyAnalytics {
  final DateTime date;
  final int minutesStudied;

  const StudyAnalytics({
    required this.date,
    required this.minutesStudied,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'minutesStudied': minutesStudied,
    };
  }

  factory StudyAnalytics.fromJson(Map<String, dynamic> json) {
    return StudyAnalytics(
      date: DateTime.parse(json['date'] as String),
      minutesStudied: json['minutesStudied'] as int,
    );
  }
}
