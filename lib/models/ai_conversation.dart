import 'package:flutter/material.dart';

class AIConversation {
  final String id;
  final String userId;
  final String sessionId;
  final String message;
  final String response;
  final String? contextType; // 'lesson_help', 'grammar_explanation', 'conversation_practice', 'writing_feedback'
  final String? contextId; // Reference to lesson/grammar rule/etc
  final String? languageCode;
  final int? messageTokens;
  final int? responseTokens;
  final DateTime createdAt;

  AIConversation({
    required this.id,
    required this.userId,
    required this.sessionId,
    required this.message,
    required this.response,
    this.contextType,
    this.contextId,
    this.languageCode,
    this.messageTokens,
    this.responseTokens,
    required this.createdAt,
  });

  factory AIConversation.fromJson(Map<String, dynamic> json) {
    return AIConversation(
      id: json['id'],
      userId: json['user_id'],
      sessionId: json['session_id'],
      message: json['message'],
      response: json['response'],
      contextType: json['context_type'],
      contextId: json['context_id'],
      languageCode: json['language_code'],
      messageTokens: json['message_tokens'],
      responseTokens: json['response_tokens'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'session_id': sessionId,
      'message': message,
      'response': response,
      'context_type': contextType,
      'context_id': contextId,
      'language_code': languageCode,
      'message_tokens': messageTokens,
      'response_tokens': responseTokens,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class AIConversationSession {
  final String id;
  final String userId;
  final String sessionId;
  final String sessionType; // 'lesson_assist', 'free_chat', 'writing_practice'
  final Map<String, dynamic>? context;
  int messageCount;
  final DateTime startedAt;
  DateTime lastMessageAt;
  bool isActive;

  AIConversationSession({
    required this.id,
    required this.userId,
    required this.sessionId,
    required this.sessionType,
    this.context,
    this.messageCount = 0,
    required this.startedAt,
    required this.lastMessageAt,
    this.isActive = true,
  });

  factory AIConversationSession.fromJson(Map<String, dynamic> json) {
    return AIConversationSession(
      id: json['id'],
      userId: json['user_id'],
      sessionId: json['session_id'],
      sessionType: json['session_type'],
      context: json['context'],
      messageCount: json['message_count'] ?? 0,
      startedAt: DateTime.parse(json['started_at']),
      lastMessageAt: DateTime.parse(json['last_message_at']),
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'session_id': sessionId,
      'session_type': sessionType,
      'context': context,
      'message_count': messageCount,
      'started_at': startedAt.toIso8601String(),
      'last_message_at': lastMessageAt.toIso8601String(),
      'is_active': isActive,
    };
  }

  void addMessage() {
    messageCount++;
    lastMessageAt = DateTime.now();
  }

  void endSession() {
    isActive = false;
  }

  String get sessionTypeDisplay {
    switch (sessionType) {
      case 'lesson_assist':
        return 'Lesson Help';
      case 'free_chat':
        return 'Practice Chat';
      case 'writing_practice':
        return 'Writing Practice';
      default:
        return 'AI Tutor';
    }
  }

  IconData get sessionIcon {
    switch (sessionType) {
      case 'lesson_assist':
        return Icons.school;
      case 'free_chat':
        return Icons.chat;
      case 'writing_practice':
        return Icons.edit;
      default:
        return Icons.smart_toy;
    }
  }
}

class AITutorRequest {
  final String message;
  final String? contextType;
  final String? contextId;
  final String? languageCode;
  final String? currentLessonContent;
  final String? userProficiencyLevel;
  final List<Map<String, String>>? conversationHistory;

  AITutorRequest({
    required this.message,
    this.contextType,
    this.contextId,
    this.languageCode,
    this.currentLessonContent,
    this.userProficiencyLevel,
    this.conversationHistory,
  });

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'context_type': contextType,
      'context_id': contextId,
      'language_code': languageCode,
      'current_lesson_content': currentLessonContent,
      'user_proficiency_level': userProficiencyLevel,
      'conversation_history': conversationHistory,
    };
  }
}

class AITutorResponse {
  final String response;
  final String? explanation;
  final List<String>? examples;
  final String? pronunciationGuide;
  final List<String>? followUpQuestions;
  final bool isComplete;
  final int? tokensUsed;

  AITutorResponse({
    required this.response,
    this.explanation,
    this.examples,
    this.pronunciationGuide,
    this.followUpQuestions,
    this.isComplete = true,
    this.tokensUsed,
  });

  factory AITutorResponse.fromJson(Map<String, dynamic> json) {
    return AITutorResponse(
      response: json['response'] ?? '',
      explanation: json['explanation'],
      examples: json['examples'] != null 
          ? List<String>.from(json['examples']) 
          : null,
      pronunciationGuide: json['pronunciation_guide'],
      followUpQuestions: json['follow_up_questions'] != null 
          ? List<String>.from(json['follow_up_questions']) 
          : null,
      isComplete: json['is_complete'] ?? true,
      tokensUsed: json['tokens_used'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'response': response,
      'explanation': explanation,
      'examples': examples,
      'pronunciation_guide': pronunciationGuide,
      'follow_up_questions': followUpQuestions,
      'is_complete': isComplete,
      'tokens_used': tokensUsed,
    };
  }
}
