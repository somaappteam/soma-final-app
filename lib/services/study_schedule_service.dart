import 'dart:async';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../models/study_models.dart';
import 'supabase_service.dart';

/// Comprehensive Study Reminders & Scheduling Service
/// Manages notifications, calendar integration, and Pomodoro timer
class StudyScheduleService {
  static final StudyScheduleService _instance = StudyScheduleService._internal();
  factory StudyScheduleService() => _instance;
  StudyScheduleService._internal();

  final _logger = Logger();
  final _supabase = SupabaseService();

  StudySchedule? _currentSchedule;
  StudyPreferences? _currentPreferences;
  List<StudySession> _sessions = [];
  List<StudyReminder> _reminders = [];
  PomodoroSession? _activePomodoro;
  Timer? _pomodoroTimer;

  // Callbacks for UI updates
  Function(Duration remaining, bool isBreak)? onPomodoroTick;
  Function()? onPomodoroComplete;
  Function()? onPomodoroCycleComplete;

  /// Initialize service with user's schedule
  Future<void> initialize(String userId) async {
    _logger.i('Initializing StudyScheduleService for user: $userId');
    await _loadSchedule(userId);
    await _loadPreferences(userId);
    await _loadSessions(userId);
    await _loadReminders(userId);
    _scheduleAllReminders();
  }

  Future<void> _loadPreferences(String userId) async {
    try {
      final response = await _supabase.client
          .from('study_preferences')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      
      if (response != null) {
        _currentPreferences = StudyPreferences.fromJson(response);
      } else {
        _currentPreferences = _createDefaultPreferences(userId);
        await updatePreferences(_currentPreferences!);
      }
    } catch (e) {
      _logger.e('Error loading preferences: $e');
      _currentPreferences = _createDefaultPreferences(userId);
    }
  }

  Future<void> _loadSessions(String userId) async {
    try {
      final response = await _supabase.client
          .from('study_sessions')
          .select()
          .eq('user_id', userId)
          .order('started_at', ascending: false);
      
      _sessions = (response as List)
          .map((s) => StudySession.fromJson(s))
          .toList();
    } catch (e) {
      _logger.e('Error loading sessions: $e');
      _sessions = [];
    }
  }

  Future<void> _loadReminders(String userId) async {
    try {
      final response = await _supabase.client
          .from('study_reminders')
          .select()
          .eq('user_id', userId);
      
      _reminders = (response as List)
          .map((r) => StudyReminder.fromJson(r))
          .toList();
    } catch (e) {
      _logger.e('Error loading reminders: $e');
      _reminders = _createDefaultReminders(userId);
    }
  }

  // ==================== SCHEDULE MANAGEMENT ====================

  Future<StudySchedule?> _loadSchedule(String userId) async {
    try {
      final response = await _supabase.client
          .from('study_plans')
          .select()
          .eq('user_id', userId)
          .eq('is_active', true)
          .maybeSingle();

      if (response != null) {
        _currentSchedule = StudySchedule.fromJson(response);
      } else {
        _currentSchedule = _createDefaultSchedule(userId);
        await saveSchedule(_currentSchedule!);
      }
      return _currentSchedule;
    } catch (e) {
      _logger.e('Error loading schedule: $e');
      return null;
    }
  }

  StudySchedule _createDefaultSchedule(String userId) {
    return StudySchedule(
      id: 'schedule_$userId',
      userId: userId,
      name: 'My Study Plan',
      startDate: DateTime.now(),
      dailyGoalMinutes: 30,
      daysPerWeek: 5,
    );
  }

  StudyPreferences _createDefaultPreferences(String userId) {
    return StudyPreferences(
      userId: userId,
      dailyGoalMinutes: 30,
      updatedAt: DateTime.now(),
    );
  }

  List<StudyReminder> _createDefaultReminders(String userId) {
    return [
      StudyReminder(
        id: 'rem_morning_$userId',
        userId: userId,
        title: 'Morning Study',
        message: 'Time for your morning study session!',
        scheduledAt: DateTime.now().copyWith(hour: 9, minute: 0),
        isActive: true,
        createdAt: DateTime.now(),
      ),
      StudyReminder(
        id: 'rem_evening_$userId',
        userId: userId,
        title: 'Daily Review',
        message: 'Don\'t forget to review what you learned today!',
        scheduledAt: DateTime.now().copyWith(hour: 20, minute: 0),
        isActive: true,
        createdAt: DateTime.now(),
      ),
    ];
  }

  /// Get user's current schedule
  StudySchedule? get currentSchedule => _currentSchedule;

  /// Add a new study session
  Future<StudySession> addStudySession({
    required String activityId,
    required String sessionType,
    required int durationMinutes,
    int itemsStudied = 0,
    int correctCount = 0,
    int xpEarned = 0,
    String? notes,
  }) async {
    final userId = _currentSchedule?.userId ?? '';
    final session = StudySession(
      id: 'session_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      activityId: activityId,
      sessionType: sessionType,
      startedAt: DateTime.now(),
      durationMinutes: durationMinutes,
      itemsStudied: itemsStudied,
      correctCount: correctCount,
      xpEarned: xpEarned,
      notes: notes,
      createdAt: DateTime.now(),
    );

    _sessions.add(session);
    try {
      await _supabase.client
          .from('study_sessions')
          .insert(session.toJson());
    } catch (e) {
      _logger.e('Error saving session: $e');
    }
    
    return session;
  }

  /// Add a custom reminder
  Future<StudyReminder> addReminder({
    required String title,
    required String message,
    required TimeOfDay time,
    List<int> daysOfWeek = const [1, 2, 3, 4, 5, 6, 7],
    String reminderType = 'custom', // This field is no longer in StudyReminder model
  }) async {
    final now = DateTime.now();
    final reminderDateTime = DateTime(now.year, now.month, now.day, time.hour, time.minute);
        
    final newReminder = StudyReminder(
        id: 'rem_${DateTime.now().millisecondsSinceEpoch}',
        userId: _currentSchedule?.userId ?? 'unknown',
        title: title,
        message: message,
        scheduledAt: reminderDateTime,
        isActive: true,
        createdAt: DateTime.now(),
      );

    _reminders.add(newReminder);
    try {
      await _supabase.client
          .from('study_reminders')
          .insert(newReminder.toJson());
    } catch (e) {
      _logger.e('Error saving reminder: $e');
    }
    _scheduleReminder(newReminder);
    
    return newReminder;
  }

  /// Remove a reminder
  Future<void> removeReminder(String reminderId) async {
    _reminders.removeWhere((r) => r.id == reminderId);
    try {
      await _supabase.client
          .from('study_reminders')
          .delete()
          .eq('id', reminderId);
    } catch (e) {
      _logger.e('Error deleting reminder: $e');
    }
    await _cancelReminder(reminderId);
  }

  /// Toggle reminder on/off
  Future<void> toggleReminder(String reminderId, bool isActive) async {
    final reminderIndex = _reminders.indexWhere((r) => r.id == reminderId);
    if (reminderIndex != -1) {
      final oldReminder = _reminders[reminderIndex];
      final updatedReminder = StudyReminder(
        id: oldReminder.id,
        userId: oldReminder.userId,
        title: oldReminder.title,
        message: oldReminder.message,
        scheduledAt: oldReminder.scheduledAt,
        isActive: isActive,
        createdAt: oldReminder.createdAt,
      );
      _reminders[reminderIndex] = updatedReminder;
      try {
        await _supabase.client
            .from('study_reminders')
            .update({'isActive': isActive})
            .eq('id', reminderId);
      } catch (e) {
        _logger.e('Error toggling reminder: $e');
      }
      
      if (isActive) {
        _scheduleReminder(updatedReminder);
      } else {
        await _cancelReminder(reminderId);
      }
    }
  }

  /// Update study preferences
  Future<void> updatePreferences(StudyPreferences preferences) async {
    _currentPreferences = preferences;
    await _savePreferences();
  }

  Future<void> _savePreferences() async {
    if (_currentPreferences == null) return;
    await updatePreferences(_currentPreferences!);
  }

  Future<void> saveSchedule(StudySchedule schedule) async {
    try {
      await _supabase.client
          .from('study_plans')
          .upsert(schedule.toJson());
    } catch (e) {
      _logger.e('Error saving schedule: $e');
    }
  }

  /// Calculate optimal study time based on user's history
  TimeOfDay calculateOptimalStudyTime() {
    // Analyze past study sessions to find patterns
    if (_sessions.isEmpty) {
      return TimeOfDay(
        hour: _currentSchedule?.reminderTime != null 
            ? int.parse(_currentSchedule!.reminderTime!.split(':')[0]) 
            : 9,
        minute: 0,
      );
    }

    // Group by hour and find peak
    final hourCounts = <int, int>{};
    for (final session in _sessions) {
      if (session.endedAt != null) {
        final hour = session.endedAt!.hour;
        hourCounts[hour] = (hourCounts[hour] ?? 0) + session.durationMinutes;
      }
    }

    if (hourCounts.isEmpty) {
      return const TimeOfDay(hour: 9, minute: 0);
    }

    final optimalHour = hourCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    return TimeOfDay(hour: optimalHour, minute: 0);
  }

  // ==================== NOTIFICATION SCHEDULING ====================

  void _scheduleAllReminders() {
    for (var reminder in _reminders) {
      if (reminder.isActive) {
        _scheduleReminder(reminder);
      }
    }
  }

  void _scheduleReminder(StudyReminder reminder) {
    // TODO: Implement using flutter_local_notifications
    _logger.i('Scheduled reminder ${reminder.id} for ${reminder.scheduledAt}');
  }

  Future<void> _cancelReminder(String reminderId) async {
    // TODO: Cancel scheduled notification
    _logger.i('Cancelled reminder: $reminderId');
  }

  // ==================== POMODORO TIMER ====================

  /// Start a new Pomodoro session
  PomodoroSession startPomodoroSession({
    String? taskId,
    Duration workDuration = const Duration(minutes: 25),
    Duration breakDuration = const Duration(minutes: 5),
    int totalCycles = 4,
  }) {
    // Cancel any existing session
    stopPomodoroSession();

    _activePomodoro = PomodoroSession(
      id: 'pomodoro_${DateTime.now().millisecondsSinceEpoch}',
      userId: _currentSchedule?.userId ?? 'unknown',
      taskId: taskId,
      startTime: DateTime.now(),
      workDuration: workDuration.inMinutes,
      breakDuration: breakDuration.inMinutes,
      totalCycles: totalCycles,
      isActive: true,
      isBreak: false,
      currentCycle: 1,
    );

    _startPomodoroTimer();
    return _activePomodoro!;
  }

  void _startPomodoroTimer() {
    if (_activePomodoro == null) return;

    _pomodoroTimer?.cancel();
    _pomodoroTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_activePomodoro == null || !_activePomodoro!.isActive) {
        timer.cancel();
        return;
      }

      final remaining = getPomodoroRemainingTime();
      onPomodoroTick?.call(remaining, _activePomodoro!.isBreak);

      if (remaining.inSeconds <= 0) {
        _completeCurrentPhase();
      }
    });
  }

  /// Get remaining time in current phase
  Duration getPomodoroRemainingTime() {
    if (_activePomodoro == null) return Duration.zero;

    final elapsed = DateTime.now().difference(_activePomodoro!.startTime);
    final phaseDurationMinutes = _activePomodoro!.isBreak 
        ? _activePomodoro!.breakDuration 
        : _activePomodoro!.workDuration;
    final phaseDuration = Duration(minutes: phaseDurationMinutes);
    final remaining = phaseDuration - elapsed;

    return remaining.isNegative ? Duration.zero : remaining;
  }

  void _completeCurrentPhase() {
    if (_activePomodoro == null) return;

    _activePomodoro!.completeCycle();
    
    if (_activePomodoro!.isComplete) {
      onPomodoroComplete?.call();
      stopPomodoroSession();
    } else {
      onPomodoroCycleComplete?.call();
      // Reset start time for next phase
      _activePomodoro = PomodoroSession(
        id: _activePomodoro!.id,
        userId: _activePomodoro!.userId,
        taskId: _activePomodoro!.taskId,
        startTime: DateTime.now(),
        workDuration: _activePomodoro!.workDuration,
        breakDuration: _activePomodoro!.breakDuration,
        totalCycles: _activePomodoro!.totalCycles,
        completedCycles: _activePomodoro!.completedCycles,
        isActive: true,
        isBreak: _activePomodoro!.isBreak,
        currentCycle: _activePomodoro!.currentCycle,
      );
    }
  }

  /// Skip current phase (break or work)
  void skipPomodoroPhase() {
    _completeCurrentPhase();
  }

  /// Pause/Resume Pomodoro
  void togglePomodoroPause() {
    if (_activePomodoro == null) return;
    
    _activePomodoro!.isActive = !_activePomodoro!.isActive;
    
    if (_activePomodoro!.isActive) {
      _startPomodoroTimer();
    } else {
      _pomodoroTimer?.cancel();
    }
  }

  /// Stop current Pomodoro session
  void stopPomodoroSession() {
    _pomodoroTimer?.cancel();
    if (_activePomodoro != null) {
      _activePomodoro = PomodoroSession(
        id: _activePomodoro!.id,
        userId: _activePomodoro!.userId,
        taskId: _activePomodoro!.taskId,
        startTime: _activePomodoro!.startTime,
        endTime: DateTime.now(),
        workDuration: _activePomodoro!.workDuration,
        breakDuration: _activePomodoro!.breakDuration,
        totalCycles: _activePomodoro!.totalCycles,
        completedCycles: _activePomodoro!.completedCycles,
        isActive: false,
        isBreak: _activePomodoro!.isBreak,
        currentCycle: _activePomodoro!.currentCycle,
      );
      // TODO: Save session to database
    }
    _activePomodoro = null;
  }

  /// Get active Pomodoro session
  PomodoroSession? get activePomodoro => _activePomodoro;

  /// Check if Pomodoro is active
  bool get isPomodoroActive => _activePomodoro?.isActive ?? false;

  // ==================== SMART REMINDERS ====================

  /// Analyze user's patterns and create smart reminders
  Future<void> generateSmartReminders() async {
    if (_currentPreferences?.notificationsEnabled != true) return;

    final optimalTime = calculateOptimalStudyTime();
    
    // Update or create optimal time reminder
    final existingReminderIndex = _reminders.indexWhere(
      (r) => r.title == 'Optimal Study Time 📈', // Using title as a proxy for type
    );

    if (existingReminderIndex == -1) {
      // Create new smart reminder
      await addReminder(
        title: 'Optimal Study Time 📈',
        message: 'Based on your patterns, this is your best time to study!',
        time: optimalTime,
        // reminderType: 'smart_optimal', // This field is no longer in StudyReminder model
      );
    } else {
      // Update existing smart reminder
      final oldReminder = _reminders[existingReminderIndex];
      final now = DateTime.now();
      final updatedScheduledAt = DateTime(now.year, now.month, now.day, optimalTime.hour, optimalTime.minute);
      final updatedReminder = StudyReminder(
        id: oldReminder.id,
        userId: oldReminder.userId,
        title: oldReminder.title,
        message: oldReminder.message,
        scheduledAt: updatedScheduledAt,
        isActive: oldReminder.isActive,
        createdAt: oldReminder.createdAt,
      );
      _reminders[existingReminderIndex] = updatedReminder;
      await _saveSchedule();
      _scheduleReminder(updatedReminder);
    }

    // Generate review reminders for weak areas
    await _generateReviewReminders();
  }

  Future<void> _generateReviewReminders() async {
    // This would analyze user's weak words/grammar and create targeted reminders
    _logger.i('Generating review reminders for weak areas');
  }

  // ==================== CALENDAR INTEGRATION ====================

  /// Sync study sessions to device calendar
  Future<void> syncToCalendar() async {
    // TODO: Implement using device_calendar or add_2_calendar package
    _logger.i('Syncing study sessions to calendar');
  }

  /// Import events from device calendar
  Future<List<StudySession>> importFromCalendar() async {
    // TODO: Import study-related events from calendar
    return [];
  }

  // ==================== ANALYTICS & INSIGHTS ====================

  /// Get study streak information
  Map<String, dynamic> getStudyStreakInfo() {
    final today = DateTime.now();
    final completedSessions = _sessions.where(
      (s) => s.endedAt != null,
    ).toList();

    if (completedSessions.isEmpty) {
      return {
        'currentStreak': 0,
        'longestStreak': 0,
        'lastStudyDate': null,
      };
    }

    // Sort by completion date in descending order
    completedSessions.sort((a, b) => b.endedAt!.compareTo(a.endedAt!));

    int currentStreak = 0;
    int longestStreak = 0;
    DateTime? lastDate;

    for (final session in completedSessions) {
      final sessionDate = DateTime(
        session.endedAt!.year,
        session.endedAt!.month,
        session.endedAt!.day,
      );

      if (lastDate == null) {
        currentStreak = 1;
      } else {
        final difference = lastDate.difference(sessionDate).inDays;
        if (difference == 1) {
          currentStreak++;
        } else if (difference > 1) {
          if (currentStreak > longestStreak) longestStreak = currentStreak;
          currentStreak = 1;
        }
      }
      lastDate = sessionDate;
    }
    if (currentStreak > longestStreak) longestStreak = currentStreak; // Update longest streak one last time

    // Calculate current streak relative to today
    currentStreak = 0;
    DateTime checkDate = DateTime(today.year, today.month, today.day);
    for (final session in completedSessions) {
      final sessionDate = DateTime(
        session.endedAt!.year,
        session.endedAt!.month,
        session.endedAt!.day,
      );

      if (sessionDate == checkDate) {
        currentStreak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else if (sessionDate.isBefore(checkDate)) {
        break;
      }
    }

    return {
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastStudyDate': completedSessions.isNotEmpty ? DateTime(completedSessions.first.endedAt!.year, completedSessions.first.endedAt!.month, completedSessions.first.endedAt!.day) : null,
    };
  }

  /// Get upcoming sessions
  List<StudySession> getUpcomingSessions() {
    final now = DateTime.now();
    return _sessions
        .where((s) => s.endedAt == null && s.startedAt.isAfter(now))
        .toList()
      ..sort((a, b) => a.startedAt.compareTo(b.startedAt));
  }

  /// Complete a study session
  Future<void> completeSession(String sessionId, {int? xpEarned, int? itemsStudied, int? correctCount, String? notes}) async {
    final index = _sessions.indexWhere((s) => s.id == sessionId);
    if (index != -1) {
      final updatedSession = StudySession(
        id: _sessions[index].id,
        userId: _sessions[index].userId,
        activityId: _sessions[index].activityId,
        sessionType: _sessions[index].sessionType,
        startedAt: _sessions[index].startedAt,
        endedAt: DateTime.now(),
        durationMinutes: _sessions[index].durationMinutes,
        itemsStudied: itemsStudied ?? _sessions[index].itemsStudied,
        correctCount: correctCount ?? _sessions[index].correctCount,
        xpEarned: xpEarned ?? _sessions[index].xpEarned,
        notes: notes ?? _sessions[index].notes,
        createdAt: _sessions[index].createdAt,
      );
      _sessions[index] = updatedSession;
      try {
        await _supabase.client
            .from('study_sessions')
            .upsert(updatedSession.toJson());
      } catch (e) {
        _logger.e('Error updating session: $e');
      }
    }
  }

  // ==================== PRIVATE METHODS ====================

  Future<void> _saveSchedule() async {
    if (_currentSchedule == null) return;
    await saveSchedule(_currentSchedule!);
  }

  void dispose() {
    _pomodoroTimer?.cancel();
    stopPomodoroSession();
  }
}
