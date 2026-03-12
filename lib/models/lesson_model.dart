import 'package:flutter/material.dart';

class LessonModel {
  final String id;
  final String courseId;
  final String title;
  final String? description;
  final Map<String, dynamic> content;
  final int difficultyLevel;
  final List<String> prerequisites;
  final int estimatedDuration; // in minutes
  final String lessonType; // 'vocabulary', 'grammar', 'conversation', 'listening', 'reading', 'writing', 'mixed'
  final int xpReward;
  final int gemReward;
  final int orderIndex;
  final bool isActive;
  final String? culturalNotes;
  final DateTime createdAt;
  final DateTime updatedAt;

  LessonModel({
    required this.id,
    required this.courseId,
    required this.title,
    this.description,
    required this.content,
    this.difficultyLevel = 1,
    this.prerequisites = const [],
    this.estimatedDuration = 5,
    this.lessonType = 'mixed',
    this.xpReward = 10,
    this.gemReward = 0,
    required this.orderIndex,
    this.isActive = true,
    this.culturalNotes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LessonModel.fromJson(Map<String, dynamic> json) {
    return LessonModel(
      id: json['id'],
      courseId: json['course_id'],
      title: json['title'],
      description: json['description'],
      content: json['content'] ?? {},
      difficultyLevel: json['difficulty_level'] ?? 1,
      prerequisites: List<String>.from(json['prerequisites'] ?? []),
      estimatedDuration: json['estimated_duration'] ?? 5,
      lessonType: json['lesson_type'] ?? 'mixed',
      xpReward: json['xp_reward'] ?? 10,
      gemReward: json['gem_reward'] ?? 0,
      orderIndex: json['order_index'],
      isActive: json['is_active'] ?? true,
      culturalNotes: json['cultural_notes'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'course_id': courseId,
      'title': title,
      'description': description,
      'content': content,
      'difficulty_level': difficultyLevel,
      'prerequisites': prerequisites,
      'estimated_duration': estimatedDuration,
      'lesson_type': lessonType,
      'xp_reward': xpReward,
      'gem_reward': gemReward,
      'order_index': orderIndex,
      'is_active': isActive,
      'cultural_notes': culturalNotes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class UserLessonProgress {
  final String id;
  final String userId;
  final String lessonId;
  final int progressPercentage;
  final bool isCompleted;
  final int? score;
  final int attempts;
  final int timeSpentSeconds;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime lastAccessedAt;
  final List<Map<String, dynamic>> mistakesMade;
  final List<String> strengthsShown;

  UserLessonProgress({
    required this.id,
    required this.userId,
    required this.lessonId,
    this.progressPercentage = 0,
    this.isCompleted = false,
    this.score,
    this.attempts = 0,
    this.timeSpentSeconds = 0,
    this.startedAt,
    this.completedAt,
    required this.lastAccessedAt,
    this.mistakesMade = const [],
    this.strengthsShown = const [],
  });

  factory UserLessonProgress.fromJson(Map<String, dynamic> json) {
    return UserLessonProgress(
      id: json['id'],
      userId: json['user_id'],
      lessonId: json['lesson_id'],
      progressPercentage: json['progress_percentage'] ?? 0,
      isCompleted: json['is_completed'] ?? false,
      score: json['score'],
      attempts: json['attempts'] ?? 0,
      timeSpentSeconds: json['time_spent_seconds'] ?? 0,
      startedAt: json['started_at'] != null ? DateTime.parse(json['started_at']) : null,
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at']) : null,
      lastAccessedAt: DateTime.parse(json['last_accessed_at']),
      mistakesMade: List<Map<String, dynamic>>.from(json['mistakes_made'] ?? []),
      strengthsShown: List<String>.from(json['strengths_shown'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'lesson_id': lessonId,
      'progress_percentage': progressPercentage,
      'is_completed': isCompleted,
      'score': score,
      'attempts': attempts,
      'time_spent_seconds': timeSpentSeconds,
      'started_at': startedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'last_accessed_at': lastAccessedAt.toIso8601String(),
      'mistakes_made': mistakesMade,
      'strengths_shown': strengthsShown,
    };
  }
}

class LearningPath {
  final String userId;
  final String courseId;
  final List<LearningPathNode> nodes;
  final int currentLevel;
  final String learningStyle;
  final DateTime generatedAt;

  LearningPath({
    required this.userId,
    required this.courseId,
    required this.nodes,
    required this.currentLevel,
    this.learningStyle = 'mixed',
    required this.generatedAt,
  });

  factory LearningPath.fromJson(Map<String, dynamic> json) {
    return LearningPath(
      userId: json['user_id'],
      courseId: json['course_id'],
      nodes: (json['nodes'] as List? ?? [])
          .map((n) => LearningPathNode.fromJson(n))
          .toList(),
      currentLevel: json['current_level'] ?? 1,
      learningStyle: json['learning_style'] ?? 'mixed',
      generatedAt: DateTime.parse(json['generated_at']),
    );
  }
}

class LearningPathNode {
  final String lessonId;
  final String title;
  final bool isUnlocked;
  final bool isCompleted;
  final int difficultyLevel;
  final List<String> nextNodes;
  final String? recommendationReason;
  final Color? nodeColor;

  LearningPathNode({
    required this.lessonId,
    required this.title,
    this.isUnlocked = false,
    this.isCompleted = false,
    this.difficultyLevel = 1,
    this.nextNodes = const [],
    this.recommendationReason,
    this.nodeColor,
  });

  factory LearningPathNode.fromJson(Map<String, dynamic> json) {
    return LearningPathNode(
      lessonId: json['lesson_id'],
      title: json['title'],
      isUnlocked: json['is_unlocked'] ?? false,
      isCompleted: json['is_completed'] ?? false,
      difficultyLevel: json['difficulty_level'] ?? 1,
      nextNodes: List<String>.from(json['next_nodes'] ?? []),
      recommendationReason: json['recommendation_reason'],
      nodeColor: json['node_color'] != null 
          ? Color(json['node_color']) 
          : null,
    );
  }
}

enum LearningStyle {
  visual,
  auditory,
  kinesthetic,
  readingWriting,
  mixed,
}

extension LearningStyleExtension on LearningStyle {
  String get displayName {
    switch (this) {
      case LearningStyle.visual:
        return 'Visual Learner';
      case LearningStyle.auditory:
        return 'Auditory Learner';
      case LearningStyle.kinesthetic:
        return 'Kinesthetic Learner';
      case LearningStyle.readingWriting:
        return 'Reading/Writing Learner';
      case LearningStyle.mixed:
        return 'Mixed Style';
    }
  }

  String get description {
    switch (this) {
      case LearningStyle.visual:
        return 'Learn best with images, diagrams, and visual aids';
      case LearningStyle.auditory:
        return 'Learn best through listening and speaking';
      case LearningStyle.kinesthetic:
        return 'Learn best by doing and practicing';
      case LearningStyle.readingWriting:
        return 'Learn best through reading and taking notes';
      case LearningStyle.mixed:
        return 'Benefit from multiple learning approaches';
    }
  }
}
