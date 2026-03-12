import 'package:flutter/material.dart';

class StoryModel {
  final String id;
  final String courseId;
  final String title;
  final String? description;
  final List<StoryScene> scenes;
  final int difficultyLevel;
  final String storyType; // 'interactive', 'dialogue', 'cultural', 'comic'
  final String? culturalContext;
  final List<StoryCharacter> characters;
  final List<String> vocabularyFocus;
  final List<String> grammarFocus;
  final int? estimatedDuration;
  final String? thumbnailUrl;
  final bool isBranching;
  final DateTime createdAt;
  final DateTime updatedAt;

  StoryModel({
    required this.id,
    required this.courseId,
    required this.title,
    this.description,
    this.scenes = const [],
    this.difficultyLevel = 1,
    this.storyType = 'interactive',
    this.culturalContext,
    this.characters = const [],
    this.vocabularyFocus = const [],
    this.grammarFocus = const [],
    this.estimatedDuration,
    this.thumbnailUrl,
    this.isBranching = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory StoryModel.fromJson(Map<String, dynamic> json) {
    return StoryModel(
      id: json['id'],
      courseId: json['course_id'],
      title: json['title'],
      description: json['description'],
      scenes: (json['scenes'] as List? ?? [])
          .map((s) => StoryScene.fromJson(s))
          .toList(),
      difficultyLevel: json['difficulty_level'] ?? 1,
      storyType: json['story_type'] ?? 'interactive',
      culturalContext: json['cultural_context'],
      characters: (json['characters'] as List? ?? [])
          .map((c) => StoryCharacter.fromJson(c))
          .toList(),
      vocabularyFocus: List<String>.from(json['vocabulary_focus'] ?? []),
      grammarFocus: List<String>.from(json['grammar_focus'] ?? []),
      estimatedDuration: json['estimated_duration'],
      thumbnailUrl: json['thumbnail_url'],
      isBranching: json['is_branching'] ?? false,
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
      'scenes': scenes.map((s) => s.toJson()).toList(),
      'difficulty_level': difficultyLevel,
      'story_type': storyType,
      'cultural_context': culturalContext,
      'characters': characters.map((c) => c.toJson()).toList(),
      'vocabulary_focus': vocabularyFocus,
      'grammar_focus': grammarFocus,
      'estimated_duration': estimatedDuration,
      'thumbnail_url': thumbnailUrl,
      'is_branching': isBranching,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class StoryScene {
  final String id;
  final int orderIndex;
  final String? backgroundImage;
  final List<StoryDialogue> dialogues;
  final String? narration;
  final String? culturalNote;
  final List<StoryChoice>? choices; // For branching stories
  final String? nextSceneId; // For linear stories
  final bool isEnding;
  final String? endingTitle;
  final Map<String, dynamic>? vocabularyHighlights;

  StoryScene({
    required this.id,
    required this.orderIndex,
    this.backgroundImage,
    this.dialogues = const [],
    this.narration,
    this.culturalNote,
    this.choices,
    this.nextSceneId,
    this.isEnding = false,
    this.endingTitle,
    this.vocabularyHighlights,
  });

  factory StoryScene.fromJson(Map<String, dynamic> json) {
    return StoryScene(
      id: json['id'],
      orderIndex: json['order_index'],
      backgroundImage: json['background_image'],
      dialogues: (json['dialogues'] as List? ?? [])
          .map((d) => StoryDialogue.fromJson(d))
          .toList(),
      narration: json['narration'],
      culturalNote: json['cultural_note'],
      choices: json['choices'] != null 
          ? (json['choices'] as List).map((c) => StoryChoice.fromJson(c)).toList()
          : null,
      nextSceneId: json['next_scene_id'],
      isEnding: json['is_ending'] ?? false,
      endingTitle: json['ending_title'],
      vocabularyHighlights: json['vocabulary_highlights'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_index': orderIndex,
      'background_image': backgroundImage,
      'dialogues': dialogues.map((d) => d.toJson()).toList(),
      'narration': narration,
      'cultural_note': culturalNote,
      'choices': choices?.map((c) => c.toJson()).toList(),
      'next_scene_id': nextSceneId,
      'is_ending': isEnding,
      'ending_title': endingTitle,
      'vocabulary_highlights': vocabularyHighlights,
    };
  }
}

class StoryDialogue {
  final String characterId;
  final String text;
  final String? translation;
  final String? audioUrl;
  final Map<String, dynamic>? emotion; // For comic-style expressions
  final bool isUser;
  final List<String>? vocabularyToHighlight;

  StoryDialogue({
    required this.characterId,
    required this.text,
    this.translation,
    this.audioUrl,
    this.emotion,
    this.isUser = false,
    this.vocabularyToHighlight,
  });

  factory StoryDialogue.fromJson(Map<String, dynamic> json) {
    return StoryDialogue(
      characterId: json['character_id'],
      text: json['text'],
      translation: json['translation'],
      audioUrl: json['audio_url'],
      emotion: json['emotion'],
      isUser: json['is_user'] ?? false,
      vocabularyToHighlight: json['vocabulary_to_highlight'] != null 
          ? List<String>.from(json['vocabulary_to_highlight'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'character_id': characterId,
      'text': text,
      'translation': translation,
      'audio_url': audioUrl,
      'emotion': emotion,
      'is_user': isUser,
      'vocabulary_to_highlight': vocabularyToHighlight,
    };
  }
}

class StoryCharacter {
  final String id;
  final String name;
  final String? avatarUrl;
  final String? description;
  final Color? color;
  final bool isNativeSpeaker;

  StoryCharacter({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.description,
    this.color,
    this.isNativeSpeaker = false,
  });

  factory StoryCharacter.fromJson(Map<String, dynamic> json) {
    return StoryCharacter(
      id: json['id'],
      name: json['name'],
      avatarUrl: json['avatar_url'],
      description: json['description'],
      color: json['color'] != null ? Color(json['color']) : null,
      isNativeSpeaker: json['is_native_speaker'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar_url': avatarUrl,
      'description': description,
      'color': color?.value,
      'is_native_speaker': isNativeSpeaker,
    };
  }
}

class StoryChoice {
  final String id;
  final String text;
  final String nextSceneId;
  final String? consequence; // Text explaining what happens
  final int? xpReward;
  final List<String>? vocabularyUnlocks;

  StoryChoice({
    required this.id,
    required this.text,
    required this.nextSceneId,
    this.consequence,
    this.xpReward,
    this.vocabularyUnlocks,
  });

  factory StoryChoice.fromJson(Map<String, dynamic> json) {
    return StoryChoice(
      id: json['id'],
      text: json['text'],
      nextSceneId: json['next_scene_id'],
      consequence: json['consequence'],
      xpReward: json['xp_reward'],
      vocabularyUnlocks: json['vocabulary_unlocks'] != null 
          ? List<String>.from(json['vocabulary_unlocks'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'next_scene_id': nextSceneId,
      'consequence': consequence,
      'xp_reward': xpReward,
      'vocabulary_unlocks': vocabularyUnlocks,
    };
  }
}

class UserStoryProgress {
  final String id;
  final String userId;
  final String storyId;
  final Map<String, dynamic> progress;
  bool isCompleted;
  int? score;
  final List<Map<String, dynamic>> choicesMade;
  String? endingReached;
  int timeSpentSeconds;
  DateTime? completedAt;
  final DateTime createdAt;
  DateTime updatedAt;

  UserStoryProgress({
    required this.id,
    required this.userId,
    required this.storyId,
    this.progress = const {},
    this.isCompleted = false,
    this.score,
    this.choicesMade = const [],
    this.endingReached,
    this.timeSpentSeconds = 0,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserStoryProgress.fromJson(Map<String, dynamic> json) {
    return UserStoryProgress(
      id: json['id'],
      userId: json['user_id'],
      storyId: json['story_id'],
      progress: json['progress'] ?? {},
      isCompleted: json['is_completed'] ?? false,
      score: json['score'],
      choicesMade: List<Map<String, dynamic>>.from(json['choices_made'] ?? []),
      endingReached: json['ending_reached'],
      timeSpentSeconds: json['time_spent_seconds'] ?? 0,
      completedAt: json['completed_at'] != null 
          ? DateTime.parse(json['completed_at']) 
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'story_id': storyId,
      'progress': progress,
      'is_completed': isCompleted,
      'score': score,
      'choices_made': choicesMade,
      'ending_reached': endingReached,
      'time_spent_seconds': timeSpentSeconds,
      'completed_at': completedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  void recordChoice(String choiceId, String sceneId) {
    choicesMade.add({
      'choice_id': choiceId,
      'scene_id': sceneId,
      'timestamp': DateTime.now().toIso8601String(),
    });
    updatedAt = DateTime.now();
  }

  void completeStory(int finalScore, String ending) {
    isCompleted = true;
    score = finalScore;
    endingReached = ending;
    completedAt = DateTime.now();
    updatedAt = DateTime.now();
  }
}

enum StoryType {
  interactive,
  dialogue,
  cultural,
  comic,
}

extension StoryTypeExtension on StoryType {
  String get displayName {
    switch (this) {
      case StoryType.interactive:
        return 'Interactive Story';
      case StoryType.dialogue:
        return 'Dialogue Practice';
      case StoryType.cultural:
        return 'Cultural Story';
      case StoryType.comic:
        return 'Comic Story';
    }
  }

  IconData get icon {
    switch (this) {
      case StoryType.interactive:
        return Icons.auto_stories;
      case StoryType.dialogue:
        return Icons.chat;
      case StoryType.cultural:
        return Icons.public;
      case StoryType.comic:
        return Icons.animation;
    }
  }
}
