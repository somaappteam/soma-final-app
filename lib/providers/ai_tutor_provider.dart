import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../models/ai_conversation.dart';
import '../services/ai_tutor_service.dart';

/// Controlled AI Tutor Provider
/// Manages AI interactions strictly within app content context
class AITutorProvider extends ChangeNotifier {
  final Logger _logger = Logger();
  final AITutorService _aiService = AITutorService();
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  String? _currentSessionId;
  String? get currentSessionId => _currentSessionId;
  
  List<AIConversation> _messages = [];
  List<AIConversation> get messages => _messages;
  
  String? _error;
  String? get error => _error;
  
  // Current learning context
  String? _currentLessonId;
  String? get currentLessonId => _currentLessonId;
  
  String? _currentVocabularyId;
  String? get currentVocabularyId => _currentVocabularyId;
  
  String? _currentGrammarRuleId;
  String? get currentGrammarRuleId => _currentGrammarRuleId;
  
  // Usage stats
  Map<String, dynamic> _usageStats = {};
  Map<String, dynamic> get usageStats => _usageStats;
  
  bool get hasContext => _aiService.currentLessonId != null ||
                        _aiService.currentVocabularyId != null ||
                        _aiService.currentGrammarRuleId != null;

  /// Initialize provider
  AITutorProvider() {
    _aiService.initialize();
  }
  
  /// Set learning context - REQUIRED before any AI interaction
  void setLearningContext({
    String? lessonId,
    String? vocabularyId,
    String? grammarRuleId,
    Map<String, dynamic>? content,
  }) {
    _currentLessonId = lessonId;
    _currentVocabularyId = vocabularyId;
    _currentGrammarRuleId = grammarRuleId;
    
    _aiService.setLearningContext(
      lessonId: lessonId,
      vocabularyId: vocabularyId,
      grammarRuleId: grammarRuleId,
      content: content,
    );
    
    _error = null;
    notifyListeners();
    
    _logger.i('Learning context set: lesson=$lessonId, vocab=$vocabularyId, grammar=$grammarRuleId');
  }
  
  /// Clear learning context
  void clearLearningContext() {
    _currentLessonId = null;
    _currentVocabularyId = null;
    _currentGrammarRuleId = null;
    _aiService.clearLearningContext();
    _messages = [];
    _error = null;
    notifyListeners();
  }

  /// Ask question with context validation
  Future<void> askQuestion(String message, {String? userProficiencyLevel}) async {
    if (message.trim().isEmpty) return;
    
    // Check if we have context
    if (!hasContext) {
      _error = 'AI Tutor is only available when viewing lessons, vocabulary, or grammar content. Please open a learning activity first.';
      notifyListeners();
      return;
    }
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Build minimal conversation history
      final history = <Map<String, String>>[];
      for (var conv in _messages.take(3)) {
        history.add({
          'user': conv.message,
          'assistant': conv.response,
        });
      }
      
      final request = AITutorRequest(
        message: message,
        contextType: _getContextType(),
        contextId: _currentLessonId ?? _currentVocabularyId ?? _currentGrammarRuleId,
        languageCode: _getLanguageCode(),
        userProficiencyLevel: userProficiencyLevel,
        conversationHistory: history.isNotEmpty ? history : null,
      );
      
      final response = await _aiService.askQuestion(request);
      
      // Create conversation entry
      final conversation = AIConversation(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: '', // Set by service
        sessionId: _currentSessionId ?? '',
        message: message,
        response: response.response,
        contextType: _getContextType(),
        contextId: _currentLessonId ?? _currentVocabularyId ?? _currentGrammarRuleId,
        languageCode: _getLanguageCode(),
        createdAt: DateTime.now(),
      );
      
      _messages.insert(0, conversation);
      
      // Update usage stats
      await _updateUsageStats();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _logger.e('Failed to ask question', error: e);
      _error = 'Unable to get response. Please try again.';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Explain vocabulary word
  Future<void> explainVocabulary(
    String vocabularyId,
    String word,
    String translation,
    String languageCode, {
    String? exampleSentence,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await _aiService.explainVocabulary(
        vocabularyId,
        word,
        translation,
        languageCode,
        exampleSentence: exampleSentence,
      );
      
      // Update context tracking
      _currentVocabularyId = vocabularyId;
      
      final conversation = AIConversation(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: '',
        sessionId: _currentSessionId ?? '',
        message: 'Explain "$word"',
        response: response.response,
        contextType: 'vocabulary_explanation',
        contextId: vocabularyId,
        languageCode: languageCode,
        createdAt: DateTime.now(),
      );
      
      _messages.insert(0, conversation);
      await _updateUsageStats();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to explain vocabulary';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Explain grammar rule
  Future<void> explainGrammarRule(
    String ruleId,
    String ruleTitle,
    String explanation,
    String languageCode,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await _aiService.explainGrammarRule(
        ruleId,
        ruleTitle,
        explanation,
        languageCode,
      );
      
      _currentGrammarRuleId = ruleId;
      
      final conversation = AIConversation(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: '',
        sessionId: _currentSessionId ?? '',
        message: 'Explain rule: $ruleTitle',
        response: response.response,
        contextType: 'grammar_explanation',
        contextId: ruleId,
        languageCode: languageCode,
        createdAt: DateTime.now(),
      );
      
      _messages.insert(0, conversation);
      await _updateUsageStats();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to explain grammar rule';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Get exercise hint
  Future<void> getExerciseHint(
    String lessonId,
    String question,
    String languageCode, {
    String? userAttempt,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await _aiService.getExerciseHint(
        lessonId,
        question,
        languageCode,
        userAttempt: userAttempt,
      );
      
      _currentLessonId = lessonId;
      
      final conversation = AIConversation(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: '',
        sessionId: _currentSessionId ?? '',
        message: userAttempt != null ? 'Hint for my attempt' : 'I need a hint',
        response: response.response,
        contextType: 'exercise_hint',
        contextId: lessonId,
        languageCode: languageCode,
        createdAt: DateTime.now(),
      );
      
      _messages.insert(0, conversation);
      await _updateUsageStats();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to get hint';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Get pronunciation help
  Future<void> getPronunciationHelp(
    String contentId,
    String wordOrPhrase,
    String languageCode,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await _aiService.getPronunciationHelp(
        contentId,
        wordOrPhrase,
        languageCode,
      );
      
      final conversation = AIConversation(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: '',
        sessionId: _currentSessionId ?? '',
        message: 'How to pronounce "$wordOrPhrase"?',
        response: response.response,
        contextType: 'pronunciation_guide',
        contextId: contentId,
        languageCode: languageCode,
        createdAt: DateTime.now(),
      );
      
      _messages.insert(0, conversation);
      await _updateUsageStats();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to get pronunciation help';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Clarify concept
  Future<void> clarifyConcept(
    String lessonId,
    String concept,
    String confusingPart,
    String languageCode,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await _aiService.clarifyConcept(
        lessonId,
        concept,
        confusingPart,
        languageCode,
      );
      
      _currentLessonId = lessonId;
      
      final conversation = AIConversation(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: '',
        sessionId: _currentSessionId ?? '',
        message: 'Confused about: $confusingPart',
        response: response.response,
        contextType: 'concept_clarification',
        contextId: lessonId,
        languageCode: languageCode,
        createdAt: DateTime.now(),
      );
      
      _messages.insert(0, conversation);
      await _updateUsageStats();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to clarify concept';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Get conversation history
  Future<void> loadConversationHistory() async {
    try {
      _messages = await _aiService.getConversationHistory(
        sessionId: _currentSessionId,
        limit: 20,
      );
      notifyListeners();
    } catch (e) {
      _logger.e('Failed to load conversation history', error: e);
    }
  }
  
  /// Update usage stats
  Future<void> _updateUsageStats() async {
    try {
      const userId = ''; // Get from auth
      _usageStats = await _aiService.getUsageStats(userId);
      notifyListeners();
    } catch (e) {
      _logger.e('Failed to get usage stats', error: e);
    }
  }
  
  /// Helper to determine context type
  String _getContextType() {
    if (_currentVocabularyId != null) return 'vocabulary_explanation';
    if (_currentGrammarRuleId != null) return 'grammar_explanation';
    if (_currentLessonId != null) return 'lesson_help';
    return 'lesson_help';
  }
  
  /// Helper to get language code
  String _getLanguageCode() {
    // This should be determined by the current course/lesson
    // For now, return a default
    return 'en';
  }
  
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  void clearMessages() {
    _messages = [];
    notifyListeners();
  }
  
  /// Check if user has reached rate limit
  bool get isRateLimited {
    return _usageStats['limit_reached'] == true;
  }
  
  /// Get remaining requests today
  int get remainingRequests {
    final todayRequests = _usageStats['today_requests'] as int? ?? 0;
    return (100 - todayRequests).clamp(0, 100);
  }
}
