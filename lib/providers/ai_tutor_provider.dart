import 'package:flutter/material.dart';
import '../models/ai_conversation.dart';
import '../services/ai_tutor_service.dart';

class AITutorProvider extends ChangeNotifier {
  final AITutorService _aiService = AITutorService();
  
  List<AIConversation> _messages = [];
  bool _isLoading = false;
  String? _error;
  
  // Context state
  String? _currentLessonId;
  String? _currentVocabularyId;
  String? _currentGrammarRuleId;

  // Getters
  List<AIConversation> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get remainingRequests => 100; // Mocked for now, integrate with service later
  bool get isRateLimited => false;
  
  String? get currentLessonId => _currentLessonId;
  String? get currentVocabularyId => _currentVocabularyId;
  String? get currentGrammarRuleId => _currentGrammarRuleId;

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
    notifyListeners();
  }

  Future<void> askQuestion(String question, {String? userProficiencyLevel}) async {
    if (question.isEmpty) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Create request object if service expects it
      // Final implementation will depend on AITutorService.askQuestion signature
      final response = await _aiService.sendMessage(question);
      
      final conversation = AIConversation(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: 'current_user', // Should get from AuthProvider
        sessionId: DateTime.now().millisecondsSinceEpoch.toString(), // Added session ID
        message: question,
        response: response,
        createdAt: DateTime.now(),
      );

      _messages.insert(0, conversation);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearMessages() {
    _messages = [];
    notifyListeners();
  }
}
