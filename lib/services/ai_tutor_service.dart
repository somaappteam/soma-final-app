import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../models/ai_conversation.dart';
import '../config/environment.dart';
import 'supabase_service.dart';

/// Controlled AI Tutor Service
/// This service restricts AI usage to app content only
/// - No general chat allowed
/// - Context must be provided
/// - Rate limited per user
/// - Content validated before sending to AI
class AITutorService {
  static final AITutorService _instance = AITutorService._internal();
  factory AITutorService() => _instance;
  AITutorService._internal();

  final Logger _logger = Logger();
  final SupabaseService _supabase = SupabaseService();
  
  String? _currentSessionId;
  final Map<String, DateTime> _lastRequestTime = {};
  
  // OpenAI API Configuration (read from Environment)
  static final String _apiKey = Environment.aiTutorApiKey;
  static const String _apiUrl = 'https://api.openai.com/v1/chat/completions';
  static const String _model = 'gpt-4-turbo-preview';
  
  // Rate limiting configuration
  static const int _maxRequestsPerMinute = 10;
  static const int _maxRequestsPerHour = 50;
  static const int _maxRequestsPerDay = 100;
  
  // Content validation - allowed contexts only
  static const List<String> _allowedContextTypes = [
    'lesson_help',           // Help with current lesson
    'vocabulary_explanation', // Explain specific word
    'grammar_explanation',   // Explain grammar rule
    'pronunciation_guide',   // Pronunciation help
    'exercise_hint',         // Give hint for exercise
    'concept_clarification', // Clarify confusing concept
  ];
  
  // Blocked keywords for off-topic detection
  static const List<String> _blockedKeywords = [
    'weather', 'news', 'sports', 'politics', 'gaming', 'movie', 'music',
    'recipe', 'coding', 'programming', 'math', 'science', 'history',
    'philosophy', 'religion', 'personal', 'advice', 'relationship',
    'job', 'work', 'money', 'investment', 'crypto', 'stock',
  ];
  
  // Required context - AI will not respond without this
  String? _currentLessonId;
  String? _currentVocabularyId;
  String? _currentGrammarRuleId;
  Map<String, dynamic>? _currentContent;

  Future<void> initialize() async {
    _logger.i('Controlled AI Tutor service initialized');
  }
  
  /// Set the current learning context - REQUIRED for AI to respond
  void setLearningContext({
    String? lessonId,
    String? vocabularyId,
    String? grammarRuleId,
    Map<String, dynamic>? content,
  }) {
    _currentLessonId = lessonId;
    _currentVocabularyId = vocabularyId;
    _currentGrammarRuleId = grammarRuleId;
    _currentContent = content;
    _logger.i('AI context set: lesson=$lessonId, vocab=$vocabularyId, grammar=$grammarRuleId');
  }
  
  /// Clear the learning context
  void clearLearningContext() {
    _currentLessonId = null;
    _currentVocabularyId = null;
    _currentGrammarRuleId = null;
    _currentContent = null;
  }

  /// Send a simple message to the AI tutor
  /// This is a simplified wrapper around askQuestion for basic text queries
  Future<String> sendMessage(String prompt) async {
    try {
      final request = AITutorRequest(
        message: prompt,
        contextType: 'lesson_help',
        currentLessonContent: _currentContent?.toString(),
      );
      
      final response = await askQuestion(request);
      return response.response;
    } catch (e) {
      _logger.e('Error sending message to AI: $e');
      return 'Sorry, I couldn\'t process your message. Please try again.';
    }
  }

  /// Controlled AI query - validates context and content before processing
  Future<AITutorResponse> askQuestion(AITutorRequest request) async {
    try {
      final userId = _supabase.currentUserId;
      if (userId == null) {
        return AITutorResponse(
          response: 'Please log in to use the AI tutor.',
          isComplete: true,
        );
      }

      // 1. VALIDATE CONTEXT - Must have learning context
      if (!_hasValidContext()) {
        return AITutorResponse(
          response: 'AI Tutor is available only when viewing lessons, vocabulary, or grammar content. Please open a learning activity first.',
          isComplete: true,
        );
      }

      // 2. VALIDATE CONTEXT TYPE - Only allowed types
      if (request.contextType != null && !_allowedContextTypes.contains(request.contextType)) {
        return AITutorResponse(
          response: 'AI Tutor can only help with lesson content, vocabulary, and grammar explanations.',
          isComplete: true,
        );
      }

      // 3. RATE LIMITING - Check user limits
      if (!_checkRateLimit(userId)) {
        return AITutorResponse(
          response: 'You\'ve reached the daily limit for AI questions. Please try again tomorrow.',
          isComplete: true,
        );
      }

      // 4. CONTENT VALIDATION - Block off-topic questions
      if (_isOffTopic(request.message)) {
        _logger.w('Blocked off-topic question from user $userId: ${request.message}');
        return AITutorResponse(
          response: 'I can only help with the language content you\'re currently studying. Please ask about the lesson, vocabulary word, or grammar rule on your screen.',
          isComplete: true,
        );
      }

      // 5. ENRICH REQUEST with current context
      final enrichedRequest = _enrichRequestWithContext(request);

      // 6. Build controlled prompt
      final messages = _buildControlledMessages(enrichedRequest);
      
      // 7. Call OpenAI API
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': _model,
          'messages': messages,
          'temperature': 0.3, // Lower temperature for more controlled responses
          'max_tokens': 500,  // Limit response length
          'response_format': {'type': 'json_object'},
        }),
      );

      // 8. Track request
      _trackRequest(userId);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        final tokensUsed = data['usage']['total_tokens'];
        
        final structuredResponse = _parseResponse(content);
        await _saveConversation(enrichedRequest, content, tokensUsed);
        
        return structuredResponse;
      } else {
        _logger.e('OpenAI API error: ${response.statusCode}');
        return AITutorResponse(
          response: 'I\'m having trouble connecting. Please try again in a moment.',
          isComplete: true,
        );
      }
    } catch (e) {
      _logger.e('AI Tutor error', error: e);
      return AITutorResponse(
        response: 'Something went wrong. Please try again.',
        isComplete: true,
      );
    }
  }

  /// Check if we have valid learning context
  bool _hasValidContext() {
    return _currentLessonId != null || 
           _currentVocabularyId != null || 
           _currentGrammarRuleId != null ||
           (_currentContent != null && _currentContent!.isNotEmpty);
  }

  /// Check rate limits for user
  bool _checkRateLimit(String userId) {
    final now = DateTime.now();
    
    // Clean old entries
    _lastRequestTime.removeWhere((key, time) => 
      now.difference(time).inHours > 24);
    
    // Count recent requests
    final recentRequests = _lastRequestTime.entries
        .where((entry) => entry.key.startsWith(userId))
        .toList();
    
    final lastMinute = recentRequests
        .where((e) => now.difference(e.value).inMinutes < 1)
        .length;
    final lastHour = recentRequests
        .where((e) => now.difference(e.value).inHours < 1)
        .length;
    final lastDay = recentRequests.length;
    
    return lastMinute < _maxRequestsPerMinute &&
           lastHour < _maxRequestsPerHour &&
           lastDay < _maxRequestsPerDay;
  }

  /// Track request for rate limiting
  void _trackRequest(String userId) {
    final key = '${userId}_${DateTime.now().millisecondsSinceEpoch}';
    _lastRequestTime[key] = DateTime.now();
  }

  /// Check if question is off-topic
  bool _isOffTopic(String message) {
    final lowerMessage = message.toLowerCase();
    
    // Check for blocked keywords
    for (var keyword in _blockedKeywords) {
      if (lowerMessage.contains(keyword)) {
        return true;
      }
    }
    
    // Check message length - very short or very long might be off-topic
    if (message.length < 5 || message.length > 500) {
      return true;
    }
    
    return false;
  }

  /// Enrich request with current learning context
  AITutorRequest _enrichRequestWithContext(AITutorRequest original) {
    String enrichedContent = original.currentLessonContent ?? '';
    
    if (_currentContent != null) {
      enrichedContent = jsonEncode(_currentContent);
    }
    
    return AITutorRequest(
      message: original.message,
      contextType: original.contextType,
      contextId: _currentLessonId ?? _currentVocabularyId ?? _currentGrammarRuleId,
      languageCode: original.languageCode,
      userProficiencyLevel: original.userProficiencyLevel,
      currentLessonContent: enrichedContent,
      conversationHistory: original.conversationHistory,
    );
  }

  List<Map<String, dynamic>> _buildControlledMessages(AITutorRequest request) {
    final messages = <Map<String, dynamic>>[];
    
    // Strict system prompt
    messages.add({
      'role': 'system',
      'content': _buildStrictSystemPrompt(request),
    });
    
    // Add conversation history (limited to last 3 exchanges)
    if (request.conversationHistory != null && request.conversationHistory!.isNotEmpty) {
      final recentHistory = request.conversationHistory!.take(3);
      for (var entry in recentHistory) {
        if (entry['user'] != null) {
          messages.add({'role': 'user', 'content': entry['user']!});
        }
        if (entry['assistant'] != null) {
          messages.add({'role': 'assistant', 'content': entry['assistant']!});
        }
      }
    }
    
    // Current question
    messages.add({
      'role': 'user',
      'content': request.message,
    });
    
    return messages;
  }

  String _buildStrictSystemPrompt(AITutorRequest request) {
    return '''You are a STRICTLY CONTROLLED AI Tutor for Soma language learning app.

CRITICAL RULES:
1. ONLY answer questions about the provided language learning content
2. If asked anything outside the lesson/vocabulary/grammar context, respond: "I can only help with your current learning content."
3. Keep responses under 3 sentences maximum
4. Be encouraging but concise
5. Always stay focused on helping with the specific content provided
6. Do NOT engage in general conversation
7. Do NOT provide information outside the scope of language learning

CURRENT CONTENT CONTEXT:
${_currentContent != null ? jsonEncode(_currentContent) : 'Lesson/Vocabulary/Grammar content'}

${request.languageCode != null ? 'Target Language: ${request.languageCode}' : ''}
${request.userProficiencyLevel != null ? 'User Level: ${request.userProficiencyLevel}' : ''}

You MUST respond in this JSON format:
{
  "response": "Your focused, brief response about the learning content only (max 3 sentences)",
  "explanation": null,
  "examples": ["brief example if relevant"],
  "pronunciation_guide": null,
  "follow_up_questions": [],
  "common_mistakes": []
}

Remember: You are ONLY for language learning help. No general chat.''';  }

  AITutorResponse _parseResponse(String responseText) {
    try {
      final json = jsonDecode(responseText) as Map<String, dynamic>;
      
      return AITutorResponse(
        response: json['response'] ?? responseText,
        explanation: json['explanation'],
        examples: json['examples'] != null ? List<String>.from(json['examples']) : null,
        pronunciationGuide: json['pronunciation_guide'],
        followUpQuestions: json['follow_up_questions'] != null 
            ? List<String>.from(json['follow_up_questions'])
            : null,
        isComplete: true,
      );
    } catch (e) {
      return AITutorResponse(
        response: responseText,
        isComplete: true,
      );
    }
  }

  Future<void> _saveConversation(AITutorRequest request, String response, int? tokensUsed) async {
    try {
      final userId = _supabase.currentUserId;
      if (userId == null) return;

      final sessionId = _currentSessionId ?? DateTime.now().millisecondsSinceEpoch.toString();
      _currentSessionId = sessionId;

      await _supabase.client.from('ai_conversations').insert({
        'user_id': userId,
        'session_id': sessionId,
        'message': request.message,
        'response': response,
        'context_type': request.contextType,
        'context_id': request.contextId,
        'language_code': request.languageCode,
        'message_tokens': tokensUsed,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      _logger.e('Failed to save conversation', error: e);
    }
  }

  // CONTEXT-SPECIFIC HELPER METHODS ONLY
  // These automatically set context and validate

  /// Explain a vocabulary word - ONLY when viewing vocabulary
  Future<AITutorResponse> explainVocabulary(
    String vocabularyId,
    String word,
    String translation,
    String languageCode, {
    String? exampleSentence,
  }) async {
    setLearningContext(
      vocabularyId: vocabularyId,
      content: {
        'type': 'vocabulary',
        'word': word,
        'translation': translation,
        'example': exampleSentence,
      },
    );

    return askQuestion(AITutorRequest(
      message: 'Explain the word "$word"',
      contextType: 'vocabulary_explanation',
      languageCode: languageCode,
      currentLessonContent: jsonEncode({
        'word': word,
        'translation': translation,
        'example': exampleSentence,
      }),
    ));
  }

  /// Explain grammar rule - ONLY when viewing grammar
  Future<AITutorResponse> explainGrammarRule(
    String ruleId,
    String ruleTitle,
    String explanation,
    String languageCode,
  ) async {
    setLearningContext(
      grammarRuleId: ruleId,
      content: {
        'type': 'grammar',
        'rule': ruleTitle,
        'explanation': explanation,
      },
    );

    return askQuestion(AITutorRequest(
      message: 'Explain the rule: $ruleTitle',
      contextType: 'grammar_explanation',
      languageCode: languageCode,
      currentLessonContent: explanation,
    ));
  }

  /// Get hint for exercise - ONLY when in lesson
  Future<AITutorResponse> getExerciseHint(
    String lessonId,
    String question,
    String languageCode, {
    String? userAttempt,
  }) async {
    setLearningContext(
      lessonId: lessonId,
      content: {
        'type': 'exercise',
        'question': question,
        'attempt': userAttempt,
      },
    );

    return askQuestion(AITutorRequest(
      message: userAttempt != null 
          ? 'I tried "$userAttempt" but I\'m not sure. Can you give me a hint?'
          : 'Can you give me a hint for this question?',
      contextType: 'exercise_hint',
      languageCode: languageCode,
      currentLessonContent: question,
    ));
  }

  /// Pronunciation help - ONLY for specific words in content
  Future<AITutorResponse> getPronunciationHelp(
    String contentId,
    String wordOrPhrase,
    String languageCode,
  ) async {
    setLearningContext(
      vocabularyId: contentId,
      content: {
        'type': 'pronunciation',
        'word': wordOrPhrase,
      },
    );

    return askQuestion(AITutorRequest(
      message: 'How do I pronounce "$wordOrPhrase"?',
      contextType: 'pronunciation_guide',
      languageCode: languageCode,
      currentLessonContent: wordOrPhrase,
    ));
  }

  /// Clarify concept from lesson - ONLY for current lesson content
  Future<AITutorResponse> clarifyConcept(
    String lessonId,
    String concept,
    String confusingPart,
    String languageCode,
  ) async {
    setLearningContext(
      lessonId: lessonId,
      content: {
        'type': 'concept',
        'concept': concept,
        'confusion': confusingPart,
      },
    );

    return askQuestion(AITutorRequest(
      message: 'I\'m confused about $concept: $confusingPart',
      contextType: 'concept_clarification',
      languageCode: languageCode,
      currentLessonContent: concept,
    ));
  }

  // Legacy methods - DEPRECATED, use context-specific methods above
  @Deprecated('Use explainVocabulary() with proper context.')
  Future<AITutorResponse> explainWordOrPhrase(String wordOrPhrase, String languageCode, {String? context}) async {
    return AITutorResponse(
      response: 'Please use explainVocabulary() with proper context.',
      isComplete: true,
    );
  }

  @Deprecated('Grammar checking is only available within lesson context.')
  Future<AITutorResponse> checkGrammar(String text, String languageCode) async {
    return AITutorResponse(
      response: 'Grammar checking is only available within lesson context.',
      isComplete: true,
    );
  }

  @Deprecated('Free conversation is not available. Please use the learning content features.')
  Future<AITutorResponse> practiceConversation(String userMessage, String languageCode, {List<Map<String, String>>? history}) async {
    return AITutorResponse(
      response: 'Free conversation is not available. Please use the learning content features.',
      isComplete: true,
    );
  }

  @Deprecated('Writing feedback is only available within writing exercises.')
  Future<AITutorResponse> getWritingFeedback(String text, String languageCode) async {
    return AITutorResponse(
      response: 'Writing feedback is only available within writing exercises.',
      isComplete: true,
    );
  }

  // Admin methods
  Future<Map<String, dynamic>> getUsageStats(String userId) async {
    final today = DateTime.now();
    final recentRequests = _lastRequestTime.entries
        .where((entry) => 
          entry.key.startsWith(userId) &&
          today.difference(entry.value).inHours < 24)
        .toList();
    
    return {
      'today_requests': recentRequests.length,
      'last_request': recentRequests.isNotEmpty 
          ? recentRequests.last.value.toIso8601String()
          : null,
      'limit_reached': !_checkRateLimit(userId),
    };
  }

  void startNewSession(String sessionType) {
    _currentSessionId = '${sessionType}_${DateTime.now().millisecondsSinceEpoch}';
  }

  String? get currentSessionId => _currentSessionId;
  String? get currentLessonId => _currentLessonId;
  String? get currentVocabularyId => _currentVocabularyId;
  String? get currentGrammarRuleId => _currentGrammarRuleId;

  Future<List<AIConversation>> getConversationHistory({String? sessionId, int limit = 50}) async {
    try {
      final userId = _supabase.currentUserId;
      if (userId == null) return [];

      var query = _supabase.client
          .from('ai_conversations')
          .select()
          .eq('user_id', userId);

      if (sessionId != null) {
        query = query.eq('session_id', sessionId);
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);
      return (response as List)
          .map((json) => AIConversation.fromJson(json))
          .toList();
    } catch (e) {
      _logger.e('Failed to get conversation history', error: e);
      return [];
    }
  }

  Future<List<AIConversationSession>> getActiveSessions() async {
    try {
      final userId = _supabase.currentUserId;
      if (userId == null) return [];

      final response = await _supabase.client
          .from('ai_conversation_sessions')
          .select()
          .eq('user_id', userId)
          .eq('is_active', true)
          .order('last_message_at', ascending: false);

      return (response as List)
          .map((json) => AIConversationSession.fromJson(json))
          .toList();
    } catch (e) {
      _logger.e('Failed to get active sessions', error: e);
      return [];
    }
  }
}
