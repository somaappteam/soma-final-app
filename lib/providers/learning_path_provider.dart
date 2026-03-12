import 'package:flutter/material.dart';
import '../models/lesson_model.dart';
import '../services/learning_path_service.dart';

class LearningPathProvider extends ChangeNotifier {
  final LearningPathService _service = LearningPathService();
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  LearningPath? _currentPath;
  LearningPath? get currentPath => _currentPath;
  
  List<LessonModel> _recommendedLessons = [];
  List<LessonModel> get recommendedLessons => _recommendedLessons;
  
  List<Map<String, dynamic>> _weakAreas = [];
  List<Map<String, dynamic>> get weakAreas => _weakAreas;
  
  String? _learningStyle;
  String? get learningStyle => _learningStyle;
  
  String? _error;
  String? get error => _error;

  Future<void> loadLearningPath(String userId, String courseId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      _currentPath = await _service.getLearningPath(userId, courseId);
      if (_currentPath != null) {
        _learningStyle = _currentPath!.learningStyle;
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load learning path';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadRecommendedLessons(String userId, String courseId) async {
    try {
      _recommendedLessons = await _service.getRecommendedLessons(userId, courseId);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load recommended lessons';
      notifyListeners();
    }
  }

  Future<void> loadWeakAreas(String userId, String courseId) async {
    try {
      _weakAreas = await _service.getWeakAreas(userId, courseId);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load weak areas';
      notifyListeners();
    }
  }

  Future<void> completeLesson(
    String userId,
    String lessonId, {
    int? score,
    int? timeSpentSeconds,
    List<Map<String, dynamic>>? mistakes,
  }) async {
    try {
      await _service.updateLessonProgress(
        userId,
        lessonId,
        isCompleted: true,
        score: score,
        timeSpentSeconds: timeSpentSeconds,
        mistakes: mistakes,
      );
      
      // Reload path to update status
      if (_currentPath != null) {
        await loadLearningPath(userId, _currentPath!.courseId);
      }
    } catch (e) {
      _error = 'Failed to complete lesson';
      notifyListeners();
    }
  }

  Future<void> updateLessonProgress(
    String userId,
    String lessonId,
    int progressPercentage, {
    int? timeSpentSeconds,
  }) async {
    try {
      await _service.updateLessonProgress(
        userId,
        lessonId,
        progressPercentage: progressPercentage,
        timeSpentSeconds: timeSpentSeconds,
      );
    } catch (e) {
      _error = 'Failed to update progress';
      notifyListeners();
    }
  }

  Future<void> detectAndUpdateLearningStyle(String userId) async {
    try {
      _learningStyle = await _service.detectLearningStyle(userId);
      await _service.updateLearningStyle(userId, _learningStyle!);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to detect learning style';
      notifyListeners();
    }
  }

  Future<int> getRecommendedDifficulty(String userId, String courseId) async {
    try {
      return await _service.getRecommendedDifficulty(userId, courseId);
    } catch (e) {
      return 1;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
