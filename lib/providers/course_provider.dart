import 'package:flutter/material.dart';
import '../models/course_model.dart';
import '../services/course_service.dart';
import '../services/asset_cache_service.dart';

class CourseProvider extends ChangeNotifier {
  final CourseService _service = CourseService();
  final AssetCacheService _assetCache = AssetCacheService();

  List<CourseModel> _courses = [];
  CourseModel? _activeCourse;
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';

  List<CourseModel> get courses => _searchQuery.isEmpty 
      ? _courses 
      : _courses.where((c) => 
          c.targetLanguageName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          c.nativeLanguageName.toLowerCase().contains(_searchQuery.toLowerCase())
        ).toList();
  CourseModel? get activeCourse => _activeCourse;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  int get courseCount => _courses.length;

  Future<void> loadCourses() async {
    try {
      _isLoading = true;
      notifyListeners();

      _courses = await _service.getUserCourses();
      _activeCourse = await _service.getActiveCourse();
      
      if (_activeCourse == null && _courses.isNotEmpty) {
        await setActiveCourse(_courses.first.id);
      } else if (_activeCourse != null) {
        // Pre-cache assets for the returning active course
        _assetCache.cacheCourseAssets(_activeCourse!);
      }

      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> addCourse({
    required String nativeLanguage,
    required String targetLanguage,
    int currentLevel = 1,
    int totalXP = 0,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final course = await _service.addCourse(
        nativeLanguage: nativeLanguage,
        targetLanguage: targetLanguage,
        currentLevel: currentLevel,
        totalXP: totalXP,
      );

      _courses.insert(0, course);
      
      // Always set the newly added course as active
      _activeCourse = course;
      await _service.setActiveCourse(course.id);
      
      // Cache assets for new course
      _assetCache.cacheCourseAssets(course);

      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteCourse(String courseId) async {
    try {
      await _service.deleteCourse(courseId);
      _courses.removeWhere((c) => c.id == courseId);
      
      // If deleted course was active, set new active course
      if (_activeCourse?.id == courseId && _courses.isNotEmpty) {
        await setActiveCourse(_courses.first.id);
      } else if (_courses.isEmpty) {
        _activeCourse = null;
      }

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> setActiveCourse(String courseId) async {
    try {
      await _service.setActiveCourse(courseId);
      
      // Try to find in local list first
      final index = _courses.indexWhere((c) => c.id == courseId);
      if (index != -1) {
        _activeCourse = _courses[index];
        // Cache assets when switching
        _assetCache.cacheCourseAssets(_activeCourse!);
      } else {
        // If not found, reload all to be safe
        await loadCourses();
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateProgress(String courseId, int xp, double progress) async {
    try {
      await _service.updateCourseProgress(
        courseId: courseId,
        xp: xp,
        progress: progress,
      );

      final index = _courses.indexWhere((c) => c.id == courseId);
      if (index != -1) {
        _courses[index] = _courses[index].copyWith(
          totalXP: xp,
          progress: progress,
        );
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
