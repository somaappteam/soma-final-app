import 'package:flutter/material.dart';
import '../models/daily_quest.dart';
import '../services/gamification_service.dart';

class GamificationProvider extends ChangeNotifier {
  final GamificationService _service = GamificationService();
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  DailyQuestsData? _dailyQuests;
  DailyQuestsData? get dailyQuests => _dailyQuests;
  
  List<Achievement> _achievements = [];
  List<Achievement> get achievements => _achievements;
  
  List<AchievementDefinition> _achievementDefinitions = [];
  List<AchievementDefinition> get achievementDefinitions => _achievementDefinitions;
  
  List<Achievement> _newAchievements = [];
  List<Achievement> get newAchievements => _newAchievements;
  
  StreakData? _streakData;
  StreakData? get streakData => _streakData;
  
  Map<String, int> _levelProgress = {};
  Map<String, int> get levelProgress => _levelProgress;
  
  String? _error;
  String? get error => _error;

  // Daily Quests
  Future<void> loadDailyQuests(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      _dailyQuests = await _service.getDailyQuests(userId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load daily quests';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateQuestProgress(String userId, String questType, int amount) async {
    try {
      await _service.updateQuestProgress(userId, questType, amount);
      await loadDailyQuests(userId); // Reload to get updated progress
    } catch (e) {
      _error = 'Failed to update quest progress';
      notifyListeners();
    }
  }

  Future<Map<String, int>?> claimQuestRewards(String userId) async {
    try {
      final rewards = await _service.claimQuestRewards(userId);
      if (rewards != null) {
        await loadDailyQuests(userId);
        notifyListeners();
      }
      return rewards;
    } catch (e) {
      _error = 'Failed to claim rewards';
      notifyListeners();
      return null;
    }
  }

  // Achievements
  Future<void> loadAchievements(String userId) async {
    try {
      _achievements = await _service.getUserAchievements(userId);
      _newAchievements = _achievements.where((a) => a.isNew).toList();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load achievements';
      notifyListeners();
    }
  }

  Future<void> loadAchievementDefinitions() async {
    try {
      _achievementDefinitions = await _service.getAchievementDefinitions();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load achievement definitions';
      notifyListeners();
    }
  }

  Future<List<Achievement>> checkNewAchievements(String userId) async {
    try {
      final newUnlocks = await _service.checkAndUnlockAchievements(userId);
      if (newUnlocks.isNotEmpty) {
        await loadAchievements(userId);
        _newAchievements.addAll(newUnlocks);
        notifyListeners();
      }
      return newUnlocks;
    } catch (e) {
      _error = 'Failed to check achievements';
      notifyListeners();
      return [];
    }
  }

  Future<void> markAchievementAsViewed(String achievementId) async {
    try {
      await _service.markAchievementAsViewed(achievementId);
      final achievement = _achievements.firstWhere((a) => a.id == achievementId);
      achievement.markAsViewed();
      _newAchievements.removeWhere((a) => a.id == achievementId);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to mark achievement as viewed';
      notifyListeners();
    }
  }

  // Streaks
  Future<void> loadStreakData(String userId) async {
    try {
      _streakData = await _service.getStreakData(userId);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load streak data';
      notifyListeners();
    }
  }

  Future<void> updateStreak(String userId) async {
    try {
      await _service.updateStreak(userId);
      await loadStreakData(userId);
    } catch (e) {
      _error = 'Failed to update streak';
      notifyListeners();
    }
  }

  Future<bool> useStreakFreeze(String userId) async {
    try {
      final success = await _service.useStreakFreeze(userId);
      if (success) {
        await loadStreakData(userId);
      }
      return success;
    } catch (e) {
      _error = 'Failed to use streak freeze';
      notifyListeners();
      return false;
    }
  }

  Future<bool> purchaseStreakFreeze(String userId, int count, int gemCost) async {
    try {
      final success = await _service.purchaseStreakFreeze(userId, count, gemCost);
      if (success) {
        await loadStreakData(userId);
      }
      return success;
    } catch (e) {
      _error = 'Failed to purchase streak freeze';
      notifyListeners();
      return false;
    }
  }

  Future<void> toggleWeekendProtection(String userId, bool enabled) async {
    try {
      await _service.toggleWeekendProtection(userId, enabled);
      await loadStreakData(userId);
    } catch (e) {
      _error = 'Failed to toggle weekend protection';
      notifyListeners();
    }
  }

  // XP and Levels
  Future<void> calculateLevelProgress(int totalXP) async {
    _levelProgress = _service.getLevelProgress(totalXP);
    notifyListeners();
  }

  int calculateLevel(int totalXP) {
    return _service.calculateLevel(totalXP);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearNewAchievements() {
    _newAchievements = [];
    notifyListeners();
  }

  // Getters for convenience
  bool get hasNewAchievements => _newAchievements.isNotEmpty;
  int get newAchievementsCount => _newAchievements.length;
  bool get hasDailyQuests => _dailyQuests != null;
  bool get allQuestsCompleted => _dailyQuests?.allQuestsCompleted ?? false;
  bool get hasStreak => (_streakData?.currentStreak ?? 0) > 0;
  bool get isStreakAtRisk => _streakData?.isStreakAtRisk ?? false;
}
