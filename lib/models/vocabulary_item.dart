import 'package:flutter/material.dart';

class VocabularyItem {
  final String id;
  final String courseId;
  final String word;
  final String translation;
  final String? pronunciationIpa;
  final String? partOfSpeech;
  final String? gender; // For languages with gender
  final int difficultyLevel;
  final List<String> exampleSentences;
  final String? mnemonic;
  final String? etymology;
  final String? imageUrl;
  final String? audioUrl;
  final List<String> tags;
  final String? category;
  final int? frequencyRank;
  final DateTime createdAt;

  VocabularyItem({
    required this.id,
    required this.courseId,
    required this.word,
    required this.translation,
    this.pronunciationIpa,
    this.partOfSpeech,
    this.gender,
    this.difficultyLevel = 1,
    this.exampleSentences = const [],
    this.mnemonic,
    this.etymology,
    this.imageUrl,
    this.audioUrl,
    this.tags = const [],
    this.category,
    this.frequencyRank,
    required this.createdAt,
  });

  factory VocabularyItem.fromJson(Map<String, dynamic> json) {
    return VocabularyItem(
      id: json['id'],
      courseId: json['course_id'],
      word: json['word'],
      translation: json['translation'],
      pronunciationIpa: json['pronunciation_ipa'],
      partOfSpeech: json['part_of_speech'],
      gender: json['gender'],
      difficultyLevel: json['difficulty_level'] ?? 1,
      exampleSentences: List<String>.from(json['example_sentences'] ?? []),
      mnemonic: json['mnemonic'],
      etymology: json['etymology'],
      imageUrl: json['image_url'],
      audioUrl: json['audio_url'],
      tags: List<String>.from(json['tags'] ?? []),
      category: json['category'],
      frequencyRank: json['frequency_rank'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'course_id': courseId,
      'word': word,
      'translation': translation,
      'pronunciation_ipa': pronunciationIpa,
      'part_of_speech': partOfSpeech,
      'gender': gender,
      'difficulty_level': difficultyLevel,
      'example_sentences': exampleSentences,
      'mnemonic': mnemonic,
      'etymology': etymology,
      'image_url': imageUrl,
      'audio_url': audioUrl,
      'tags': tags,
      'category': category,
      'frequency_rank': frequencyRank,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class UserVocabulary {
  final String id;
  final String userId;
  final String vocabularyId;
  int masteryLevel; // 0=new, 5=mastered
  DateTime? nextReviewAt;
  DateTime? lastReviewedAt;
  int reviewCount;
  int correctCount;
  int incorrectCount;
  double easeFactor; // SM-2 algorithm
  int intervalDays;
  bool isLearned;
  DateTime? learnedAt;
  final DateTime createdAt;
  DateTime updatedAt;

  UserVocabulary({
    required this.id,
    required this.userId,
    required this.vocabularyId,
    this.masteryLevel = 0,
    this.nextReviewAt,
    this.lastReviewedAt,
    this.reviewCount = 0,
    this.correctCount = 0,
    this.incorrectCount = 0,
    this.easeFactor = 2.5,
    this.intervalDays = 1,
    this.isLearned = false,
    this.learnedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserVocabulary.fromJson(Map<String, dynamic> json) {
    return UserVocabulary(
      id: json['id'],
      userId: json['user_id'],
      vocabularyId: json['vocabulary_id'],
      masteryLevel: json['mastery_level'] ?? 0,
      nextReviewAt: json['next_review_at'] != null 
          ? DateTime.parse(json['next_review_at']) 
          : null,
      lastReviewedAt: json['last_reviewed_at'] != null 
          ? DateTime.parse(json['last_reviewed_at']) 
          : null,
      reviewCount: json['review_count'] ?? 0,
      correctCount: json['correct_count'] ?? 0,
      incorrectCount: json['incorrect_count'] ?? 0,
      easeFactor: (json['ease_factor'] ?? 2.5).toDouble(),
      intervalDays: json['interval_days'] ?? 1,
      isLearned: json['is_learned'] ?? false,
      learnedAt: json['learned_at'] != null 
          ? DateTime.parse(json['learned_at']) 
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'vocabulary_id': vocabularyId,
      'mastery_level': masteryLevel,
      'next_review_at': nextReviewAt?.toIso8601String(),
      'last_reviewed_at': lastReviewedAt?.toIso8601String(),
      'review_count': reviewCount,
      'correct_count': correctCount,
      'incorrect_count': incorrectCount,
      'ease_factor': easeFactor,
      'interval_days': intervalDays,
      'is_learned': isLearned,
      'learned_at': learnedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Calculate SM-2 spaced repetition
  void calculateNextReview(int quality) {
    // quality: 0-5 rating (0=complete blackout, 5=perfect response)
    if (quality < 0 || quality > 5) return;

    reviewCount++;
    
    if (quality < 3) {
      // Failed response - reset interval
      intervalDays = 1;
    } else {
      // Successful response
      correctCount++;
      
      if (reviewCount == 1) {
        intervalDays = 1;
      } else if (reviewCount == 2) {
        intervalDays = 6;
      } else {
        intervalDays = (intervalDays * easeFactor).round();
      }
    }

    // Update ease factor
    easeFactor = easeFactor + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
    if (easeFactor < 1.3) easeFactor = 1.3;

    // Calculate mastery level based on review count and success
    if (reviewCount >= 5 && correctCount / reviewCount > 0.8) {
      masteryLevel = 5; // Mastered
      if (!isLearned) {
        isLearned = true;
        learnedAt = DateTime.now();
      }
    } else if (reviewCount >= 3 && correctCount / reviewCount > 0.7) {
      masteryLevel = 4;
    } else if (reviewCount >= 2 && correctCount / reviewCount > 0.6) {
      masteryLevel = 3;
    } else if (reviewCount >= 1) {
      masteryLevel = 2;
    } else {
      masteryLevel = 1;
    }

    // Set next review date
    lastReviewedAt = DateTime.now();
    nextReviewAt = DateTime.now().add(Duration(days: intervalDays));
    updatedAt = DateTime.now();
  }

  double get accuracyRate {
    if (reviewCount == 0) return 0.0;
    return correctCount / reviewCount;
  }

  bool get isDueForReview {
    if (nextReviewAt == null) return true;
    return DateTime.now().isAfter(nextReviewAt!);
  }

  int get daysUntilReview {
    if (nextReviewAt == null) return 0;
    return nextReviewAt!.difference(DateTime.now()).inDays;
  }
}

class FlashcardSet {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final List<String> vocabularyIds;
  final String? courseId;
  final DateTime createdAt;
  DateTime updatedAt;
  int totalCards;
  int masteredCards;

  FlashcardSet({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    this.vocabularyIds = const [],
    this.courseId,
    required this.createdAt,
    required this.updatedAt,
    this.totalCards = 0,
    this.masteredCards = 0,
  });

  factory FlashcardSet.fromJson(Map<String, dynamic> json) {
    return FlashcardSet(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      description: json['description'],
      vocabularyIds: List<String>.from(json['vocabulary_ids'] ?? []),
      courseId: json['course_id'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      totalCards: json['total_cards'] ?? 0,
      masteredCards: json['mastered_cards'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'description': description,
      'vocabulary_ids': vocabularyIds,
      'course_id': courseId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'total_cards': totalCards,
      'mastered_cards': masteredCards,
    };
  }

  double get masteryProgress {
    if (totalCards == 0) return 0.0;
    return masteredCards / totalCards;
  }
}

enum VocabularyCategory {
  greetings,
  numbers,
  colors,
  food,
  travel,
  family,
  work,
  hobbies,
  emotions,
  weather,
  time,
  animals,
  nature,
  technology,
  health,
  shopping,
  education,
  transportation,
  house,
  clothing,
}

extension VocabularyCategoryExtension on VocabularyCategory {
  String get displayName {
    switch (this) {
      case VocabularyCategory.greetings:
        return 'Greetings';
      case VocabularyCategory.numbers:
        return 'Numbers';
      case VocabularyCategory.colors:
        return 'Colors';
      case VocabularyCategory.food:
        return 'Food & Drinks';
      case VocabularyCategory.travel:
        return 'Travel';
      case VocabularyCategory.family:
        return 'Family';
      case VocabularyCategory.work:
        return 'Work';
      case VocabularyCategory.hobbies:
        return 'Hobbies';
      case VocabularyCategory.emotions:
        return 'Emotions';
      case VocabularyCategory.weather:
        return 'Weather';
      case VocabularyCategory.time:
        return 'Time';
      case VocabularyCategory.animals:
        return 'Animals';
      case VocabularyCategory.nature:
        return 'Nature';
      case VocabularyCategory.technology:
        return 'Technology';
      case VocabularyCategory.health:
        return 'Health';
      case VocabularyCategory.shopping:
        return 'Shopping';
      case VocabularyCategory.education:
        return 'Education';
      case VocabularyCategory.transportation:
        return 'Transportation';
      case VocabularyCategory.house:
        return 'House';
      case VocabularyCategory.clothing:
        return 'Clothing';
    }
  }

  IconData get icon {
    switch (this) {
      case VocabularyCategory.greetings:
        return Icons.waving_hand;
      case VocabularyCategory.numbers:
        return Icons.format_list_numbered;
      case VocabularyCategory.colors:
        return Icons.palette;
      case VocabularyCategory.food:
        return Icons.restaurant;
      case VocabularyCategory.travel:
        return Icons.flight;
      case VocabularyCategory.family:
        return Icons.family_restroom;
      case VocabularyCategory.work:
        return Icons.work;
      case VocabularyCategory.hobbies:
        return Icons.sports_esports;
      case VocabularyCategory.emotions:
        return Icons.sentiment_satisfied;
      case VocabularyCategory.weather:
        return Icons.wb_sunny;
      case VocabularyCategory.time:
        return Icons.access_time;
      case VocabularyCategory.animals:
        return Icons.pets;
      case VocabularyCategory.nature:
        return Icons.park;
      case VocabularyCategory.technology:
        return Icons.computer;
      case VocabularyCategory.health:
        return Icons.favorite;
      case VocabularyCategory.shopping:
        return Icons.shopping_cart;
      case VocabularyCategory.education:
        return Icons.school;
      case VocabularyCategory.transportation:
        return Icons.directions_car;
      case VocabularyCategory.house:
        return Icons.home;
      case VocabularyCategory.clothing:
        return Icons.checkroom;
    }
  }
}
