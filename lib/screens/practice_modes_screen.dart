import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/vocabulary_item.dart';
import '../providers/auth_provider.dart';
import '../providers/course_provider.dart';
import '../services/csv_data_service.dart';
import '../theme/app_theme.dart';
import 'games/falling_words_launcher.dart';
import 'games/word_match_game.dart';
import 'practice/flashcards_screen.dart';
import 'practice/vocabulary_quiz_screen.dart';
import 'practice/fill_in_blank_screen.dart';
import 'practice/listening_practice_screen.dart';
import 'practice/speed_challenge_screen.dart';
import 'practice/pronunciation_practice_screen.dart';
import 'practice_modes/image_recognition_screen.dart';
import 'auth/register_screen.dart';
import 'practice/practice_session_analytics_screen.dart';

class PracticeModesScreen extends StatefulWidget {
  final String? initialMode;

  const PracticeModesScreen({super.key, this.initialMode});

  @override
  State<PracticeModesScreen> createState() => _PracticeModesScreenState();
}

class _PracticeModesScreenState extends State<PracticeModesScreen> {
  bool _isLoading = true;
  List<VocabularyItem> _vocabulary = [];
  List<String> _concepts = [];
  String _vocabPartOfSpeech = 'all';
  String _vocabCategory = 'all';
  String _vocabDifficulty = 'beginner';
  int _vocabQuestionCount = 10;
  String _sentenceCategory = 'all';
  String _sentenceDifficulty = 'beginner';
  int _sentenceQuestionCount = 10;
  String _reviewQueueFilter = 'all';
  Map<String, dynamic> _reviewStats = {};
  Map<String, dynamic> _weakFocusStats = {};
  bool _autoDifficultyEnabled = true;
  List<Map<String, dynamic>> _sessionHistory = [];
  bool _hasAutoLaunchedInitialMode = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadVocabulary();
  }

  Future<void> _loadVocabulary() async {
    try {
      final courseProvider = context.read<CourseProvider>();
      final activeCourse = courseProvider.activeCourse;
      
      if (activeCourse != null) {
        final csvService = CsvDataService();
        
        // Fetch concepts if not already fetched
        if (_concepts.isEmpty) {
          final concepts = await csvService.getConcepts(
            activeCourse.targetLanguage, 
            activeCourse.nativeLanguage,
          );
          _concepts = concepts;
        }

        final vocab = await csvService.getVocabulary(
          activeCourse.targetLanguage, 
          activeCourse.nativeLanguage,
        );

        await _loadSessionConfiguration(activeCourse.id, activeCourse.targetLanguage, activeCourse.nativeLanguage);

        setState(() {
          _vocabulary = vocab;
          _isLoading = false;
        });
      } else {
        await _loadSessionConfiguration('demo', 'es', 'en');
        setState(() {
          _vocabulary = _getDemoVocabulary();
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _vocabulary = _getDemoVocabulary();
        _isLoading = false;
      });
    }
  }

  List<VocabularyItem> _getDemoVocabulary() {
    // Demo vocabulary for testing
    return [
      VocabularyItem(
        id: '1',
        courseId: 'demo',
        word: 'Hello',
        translation: 'Hola',
        difficultyLevel: 1,
        createdAt: DateTime.now(),
      ),
      VocabularyItem(
        id: '2',
        courseId: 'demo',
        word: 'Goodbye',
        translation: 'Adiós',
        difficultyLevel: 1,
        createdAt: DateTime.now(),
      ),
      VocabularyItem(
        id: '3',
        courseId: 'demo',
        word: 'Thank you',
        translation: 'Gracias',
        difficultyLevel: 1,
        createdAt: DateTime.now(),
      ),
      VocabularyItem(
        id: '4',
        courseId: 'demo',
        word: 'Please',
        translation: 'Por favor',
        difficultyLevel: 1,
        createdAt: DateTime.now(),
      ),
      VocabularyItem(
        id: '5',
        courseId: 'demo',
        word: 'Water',
        translation: 'Agua',
        difficultyLevel: 1,
        createdAt: DateTime.now(),
      ),
      VocabularyItem(
        id: '6',
        courseId: 'demo',
        word: 'Food',
        translation: 'Comida',
        difficultyLevel: 1,
        createdAt: DateTime.now(),
      ),
    ];
  }


  String _sessionConfigKey(String courseId, String targetLanguage, String nativeLanguage) =>
      'practice_session_config_${courseId}_$targetLanguage_$nativeLanguage';

  String _reviewStatsKey(String courseId, String targetLanguage, String nativeLanguage) =>
      'practice_review_stats_${courseId}_$targetLanguage_$nativeLanguage';

  String _lastSessionKey(String courseId, String targetLanguage, String nativeLanguage) =>
      'practice_last_session_${courseId}_$targetLanguage_$nativeLanguage';

  String _adaptiveStatsKey(String courseId, String targetLanguage, String nativeLanguage) =>
      'practice_adaptive_stats_${courseId}_$targetLanguage_$nativeLanguage';

  String _sessionHistoryKey(String courseId, String targetLanguage, String nativeLanguage) =>
      'practice_session_history_${courseId}_$targetLanguage_$nativeLanguage';

  String _weakFocusKey(String courseId, String targetLanguage, String nativeLanguage) =>
      'practice_weak_focus_${courseId}_$targetLanguage_$nativeLanguage';

  Future<void> _loadSessionConfiguration(String courseId, String targetLanguage, String nativeLanguage) async {
    final prefs = await SharedPreferences.getInstance();
    final rawConfig = prefs.getString(_sessionConfigKey(courseId, targetLanguage, nativeLanguage));
    final rawDefaultConfig = prefs.getString('practice_session_config_default_${targetLanguage}_$nativeLanguage');
    final rawStats = prefs.getString(_reviewStatsKey(courseId, targetLanguage, nativeLanguage));
    final rawHistory = prefs.getString(_sessionHistoryKey(courseId, targetLanguage, nativeLanguage));
    final rawWeakFocus = prefs.getString(_weakFocusKey(courseId, targetLanguage, nativeLanguage));

    if (rawConfig == null && rawDefaultConfig == null && rawStats == null && rawHistory == null && rawWeakFocus == null) return;

    final config = rawConfig == null
        ? (rawDefaultConfig == null ? <String, dynamic>{} : jsonDecode(rawDefaultConfig) as Map<String, dynamic>)
        : jsonDecode(rawConfig) as Map<String, dynamic>;
    final stats = rawStats == null ? <String, dynamic>{} : jsonDecode(rawStats) as Map<String, dynamic>;
    final history = rawHistory == null
        ? <Map<String, dynamic>>[]
        : (jsonDecode(rawHistory) as List<dynamic>).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    final weakFocus = rawWeakFocus == null ? <String, dynamic>{} : jsonDecode(rawWeakFocus) as Map<String, dynamic>;

    setState(() {
      final vocabConfig = (config['vocabulary'] as Map?)?.cast<String, dynamic>();
      final sentenceConfig = (config['sentences'] as Map?)?.cast<String, dynamic>();

      _vocabPartOfSpeech = (config['vocabPartOfSpeech'] ?? vocabConfig?['partOfSpeech'] ?? _vocabPartOfSpeech) as String;
      _vocabCategory = (config['vocabCategory'] ?? vocabConfig?['category'] ?? _vocabCategory) as String;
      _vocabDifficulty = (config['vocabDifficulty'] ?? vocabConfig?['difficulty'] ?? _vocabDifficulty) as String;
      _vocabQuestionCount = (config['vocabQuestionCount'] ?? vocabConfig?['questionCount'] ?? _vocabQuestionCount) as int;
      _sentenceCategory = (config['sentenceCategory'] ?? sentenceConfig?['category'] ?? _sentenceCategory) as String;
      _sentenceDifficulty = (config['sentenceDifficulty'] ?? sentenceConfig?['difficulty'] ?? _sentenceDifficulty) as String;
      _sentenceQuestionCount = (config['sentenceQuestionCount'] ?? sentenceConfig?['questionCount'] ?? _sentenceQuestionCount) as int;
      _reviewQueueFilter = (config['reviewQueueFilter'] ?? vocabConfig?['reviewQueue'] ?? _reviewQueueFilter) as String;
      _autoDifficultyEnabled = (config['autoDifficultyEnabled'] ?? vocabConfig?['autoDifficultyEnabled'] ?? sentenceConfig?['autoDifficultyEnabled'] ?? _autoDifficultyEnabled) as bool;
      _reviewStats = stats;
      _sessionHistory = history;
      _weakFocusStats = weakFocus;
    });
  }

  Future<void> _persistSessionConfiguration() async {
    final activeCourse = context.read<CourseProvider>().activeCourse;
    final courseId = activeCourse?.id ?? 'demo';
    final targetLanguage = activeCourse?.targetLanguage ?? 'es';
    final nativeLanguage = activeCourse?.nativeLanguage ?? 'en';

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _sessionConfigKey(courseId, targetLanguage, nativeLanguage),
      jsonEncode({
        'vocabPartOfSpeech': _vocabPartOfSpeech,
        'vocabCategory': _vocabCategory,
        'vocabDifficulty': _vocabDifficulty,
        'vocabQuestionCount': _vocabQuestionCount,
        'sentenceCategory': _sentenceCategory,
        'sentenceDifficulty': _sentenceDifficulty,
        'sentenceQuestionCount': _sentenceQuestionCount,
        'reviewQueueFilter': _reviewQueueFilter,
        'autoDifficultyEnabled': _autoDifficultyEnabled,
      }),
    );
  }

  void _updateSessionConfig(VoidCallback updater) {
    setState(updater);
    _persistSessionConfiguration();
  }



  int _reviewQueueCount(String queueType) {
    if (queueType == 'all') return _vocabulary.length;

    final now = DateTime.now();
    return _vocabulary.where((item) {
      final stats = (_reviewStats[item.id] as Map?)?.cast<String, dynamic>();
      final reviewCount = (stats?['reviewCount'] ?? 0) as int;
      final nextReviewAtRaw = stats?['nextReviewAt'] as String?;
      final nextReviewAt = nextReviewAtRaw == null ? null : DateTime.tryParse(nextReviewAtRaw);

      switch (queueType) {
        case 'new':
          return reviewCount == 0;
        case 'due':
          return nextReviewAt != null && !nextReviewAt.isAfter(now);
        case 'overdue':
          return nextReviewAt != null && nextReviewAt.isBefore(now.subtract(const Duration(days: 1)));
        default:
          return false;
      }
    }).length;
  }

  double? _extractActualAccuracy(dynamic quizResult, int totalItems) {
    if (quizResult is Map) {
      if (quizResult['accuracy'] is num) {
        final value = (quizResult['accuracy'] as num).toDouble();
        return value > 1 ? value / 100 : value;
      }
      if (quizResult['correct'] is num) {
        final correct = (quizResult['correct'] as num).toDouble();
        final total = (quizResult['total'] is num)
            ? (quizResult['total'] as num).toDouble()
            : totalItems.toDouble();
        if (total > 0) return (correct / total).clamp(0.0, 1.0);
      }
    }
    return null;
  }

  void _maybeLaunchInitialMode() {
    if (_hasAutoLaunchedInitialMode || widget.initialMode == null || _isLoading) return;
    _hasAutoLaunchedInitialMode = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _launchModeByName(context, widget.initialMode!);
    });
  }

  Future<void> _launchModeByName(BuildContext context, String modeName) async {
    switch (modeName.toLowerCase()) {
      case 'falling words':
        await _launchFallingWords(context);
        break;
      case 'word match':
        await _launchWordMatch(context);
        break;
      case 'vocabulary quiz':
        await _launchVocabularyQuiz(context);
        break;
      case 'weak areas quiz':
        await _startWeakAreasSession(context);
        break;
      case 'flashcards':
        await _launchFlashcards(context);
        break;
      case 'picture quiz':
        await _launchPictureQuiz(context);
        break;
      case 'fill in the blank':
        await _launchFillInBlank(context);
        break;
      case 'listening practice':
        await _launchListeningPractice(context);
        break;
      case 'speed challenge':
        await _launchSpeedChallenge(context);
        break;
      case 'pronunciation practice':
        await _launchPronunciation(context);
        break;
      default:
        break;
    }
  }

  Widget _buildSessionHistoryTimeline() {
    if (_sessionHistory.isEmpty) return const SizedBox.shrink();

    final recent = _sessionHistory.take(7).toList();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Last 7 Sessions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
          const SizedBox(height: 10),
          ...recent.map((entry) {
            final mode = entry['mode']?.toString() ?? 'Practice';
            final difficulty = entry['difficulty']?.toString() ?? 'beginner';
            final duration = (entry['durationSeconds'] ?? 0) as int;
            final movedTo = entry['adaptiveMovedTo']?.toString();
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.history, size: 16, color: AppColors.primaryTeal),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$mode • ${_capitalize(difficulty)} • ${duration}s${movedTo != null ? ' • → ${_capitalize(movedTo)}' : ''}',
                      style: const TextStyle(color: AppColors.textMedium, fontSize: 12),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }


  Future<void> _startDueReviewSession(BuildContext context) async {
    _updateSessionConfig(() => _reviewQueueFilter = 'due');
    final dueCount = _reviewQueueCount('due');
    if (dueCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No due review items right now. Try New or All.'),
          backgroundColor: AppColors.primaryTeal,
        ),
      );
      return;
    }

    await _launchVocabularyQuiz(context);
  }

  String _nextDifficulty(String current, bool increase) {
    const levels = ['beginner', 'intermediate', 'advanced'];
    final index = levels.indexOf(current);
    if (index == -1) return current;
    if (increase && index < levels.length - 1) return levels[index + 1];
    if (!increase && index > 0) return levels[index - 1];
    return current;
  }

  Future<String?> _applyAdaptiveDifficultyTuning({
    required SharedPreferences prefs,
    required String courseId,
    required String targetLanguage,
    required String nativeLanguage,
    required bool isVocabulary,
    required double estimatedAccuracy,
    required double avgResponseSeconds,
  }) async {
    final key = _adaptiveStatsKey(courseId, targetLanguage, nativeLanguage);
    final raw = prefs.getString(key);
    final stats = raw == null ? <String, dynamic>{} : jsonDecode(raw) as Map<String, dynamic>;
    final bucketKey = isVocabulary ? 'vocabulary' : 'sentences';
    final bucket = (stats[bucketKey] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};

    final sessions = (bucket['sessions'] ?? 0) as int;
    final totalAccuracy = ((bucket['totalAccuracy'] ?? 0) as num).toDouble();
    final totalResponse = ((bucket['totalResponse'] ?? 0) as num).toDouble();
    final updatedSessions = sessions + 1;
    final updatedAccuracy = totalAccuracy + estimatedAccuracy;
    final updatedResponse = totalResponse + avgResponseSeconds;
    final rollingAccuracy = updatedAccuracy / updatedSessions;
    final rollingResponse = updatedResponse / updatedSessions;

    String currentDifficulty = isVocabulary ? _vocabDifficulty : _sentenceDifficulty;
    String tunedDifficulty = currentDifficulty;

    final canIncrease = rollingAccuracy >= 0.88 && rollingResponse <= 5.0 && updatedSessions >= 3;
    final shouldDecrease = rollingAccuracy <= 0.68 || rollingResponse >= 10.0;

    if (canIncrease) {
      tunedDifficulty = _nextDifficulty(currentDifficulty, true);
    } else if (shouldDecrease) {
      tunedDifficulty = _nextDifficulty(currentDifficulty, false);
    }

    bucket['sessions'] = updatedSessions;
    bucket['totalAccuracy'] = updatedAccuracy;
    bucket['totalResponse'] = updatedResponse;
    bucket['rollingAccuracy'] = rollingAccuracy;
    bucket['rollingResponse'] = rollingResponse;
    bucket['difficulty'] = tunedDifficulty;
    stats[bucketKey] = bucket;

    await prefs.setString(key, jsonEncode(stats));

    if (tunedDifficulty != currentDifficulty) {
      if (mounted) {
        setState(() {
          if (isVocabulary) {
            _vocabDifficulty = tunedDifficulty;
          } else {
            _sentenceDifficulty = tunedDifficulty;
          }
        });
      }
      await _persistSessionConfiguration();
      return tunedDifficulty;
    }

    return null;
  }

  Future<void> _recordSessionCompletion({
    required String mode,
    required bool isVocabulary,
    required int totalItems,
    required Duration duration,
    dynamic quizResult,
    List<VocabularyItem> vocabulary = const [],
  }) async {
    final activeCourse = context.read<CourseProvider>().activeCourse;
    final courseId = activeCourse?.id ?? 'demo';
    final targetLanguage = activeCourse?.targetLanguage ?? 'es';
    final nativeLanguage = activeCourse?.nativeLanguage ?? 'en';
    final now = DateTime.now();

    final prefs = await SharedPreferences.getInstance();
    final actualAccuracy = _extractActualAccuracy(quizResult, totalItems);
    final avgResponseSeconds = totalItems > 0 ? duration.inSeconds / totalItems : 0.0;

    await prefs.setString(
      _lastSessionKey(courseId, targetLanguage, nativeLanguage),
      jsonEncode({
        'mode': mode,
        'isVocabulary': isVocabulary,
        'difficulty': isVocabulary ? _vocabDifficulty : _sentenceDifficulty,
        'accuracy': actualAccuracy,
        'count': totalItems,
        'completedAt': now.toIso8601String(),
        'durationSeconds': duration.inSeconds,
      }),
    );

    if (vocabulary.isNotEmpty) {
      final key = _reviewStatsKey(courseId, targetLanguage, nativeLanguage);
      final rawStats = prefs.getString(key);
      final stats = rawStats == null ? <String, dynamic>{} : jsonDecode(rawStats) as Map<String, dynamic>;

      final reviewDays = switch (_vocabDifficulty) {
        'beginner' => 1,
        'intermediate' => 3,
        'advanced' => 7,
        _ => 2,
      };

      for (final item in vocabulary) {
        final itemStats = (stats[item.id] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
        final reviewCount = (itemStats['reviewCount'] ?? 0) as int;
        itemStats['reviewCount'] = reviewCount + 1;
        itemStats['lastReviewedAt'] = now.toIso8601String();
        itemStats['nextReviewAt'] = now.add(Duration(days: reviewDays)).toIso8601String();
        stats[item.id] = itemStats;
      }

      await prefs.setString(key, jsonEncode(stats));
      if (mounted) {
        setState(() => _reviewStats = stats);
      }
    }

    if (isVocabulary && actualAccuracy != null) {
      final weakKey = _weakFocusKey(courseId, targetLanguage, nativeLanguage);
      final rawWeak = prefs.getString(weakKey);
      final weakStats = rawWeak == null ? <String, dynamic>{} : jsonDecode(rawWeak) as Map<String, dynamic>;
      final posMap = (weakStats['partOfSpeech'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
      final categoryMap = (weakStats['category'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};

      final isWeakRun = mode.toLowerCase().contains('weak');
      final delta = isWeakRun ? (actualAccuracy < 0.75 ? 2.0 : -1.0) : (actualAccuracy < 0.7 ? 1.0 : -0.5);

      if (_vocabPartOfSpeech != 'all') {
        final current = (posMap[_vocabPartOfSpeech] as num?)?.toDouble() ?? 0;
        posMap[_vocabPartOfSpeech] = (current + delta).clamp(0, 20).toDouble();
      }
      if (_vocabCategory != 'all') {
        final current = (categoryMap[_vocabCategory] as num?)?.toDouble() ?? 0;
        categoryMap[_vocabCategory] = (current + delta).clamp(0, 20).toDouble();
      }

      if (quizResult is Map && quizResult['weakAreas'] is List) {
        final areas = (quizResult['weakAreas'] as List).map((e) => e.toString().toLowerCase());
        for (final area in areas) {
          if (area.startsWith('part_of_speech:')) {
            final keyName = area.replaceFirst('part_of_speech:', '').trim();
            if (keyName.isNotEmpty) {
              final current = (posMap[keyName] as num?)?.toDouble() ?? 0;
              posMap[keyName] = (current + 1).clamp(0, 20).toDouble();
            }
          } else if (area.startsWith('category:')) {
            final keyName = area.replaceFirst('category:', '').trim();
            if (keyName.isNotEmpty) {
              final current = (categoryMap[keyName] as num?)?.toDouble() ?? 0;
              categoryMap[keyName] = (current + 1).clamp(0, 20).toDouble();
            }
          }
        }
      }

      weakStats['partOfSpeech'] = posMap;
      weakStats['category'] = categoryMap;
      weakStats['updatedAt'] = now.toIso8601String();
      await prefs.setString(weakKey, jsonEncode(weakStats));
      if (mounted) {
        setState(() => _weakFocusStats = weakStats);
      }
    }

    String? tunedDifficulty;
    String adaptiveReason = _autoDifficultyEnabled
        ? 'Auto difficulty tracks your real quiz accuracy and response speed over recent sessions.'
        : 'Auto difficulty is currently off.';

    if (_autoDifficultyEnabled && actualAccuracy != null) {
      tunedDifficulty = await _applyAdaptiveDifficultyTuning(
        prefs: prefs,
        courseId: courseId,
        targetLanguage: targetLanguage,
        nativeLanguage: nativeLanguage,
        isVocabulary: isVocabulary,
        estimatedAccuracy: actualAccuracy,
        avgResponseSeconds: avgResponseSeconds,
      );

      if (tunedDifficulty != null) {
        adaptiveReason = 'Difficulty changed after strong/weak recent performance trend (${(actualAccuracy * 100).toStringAsFixed(0)}% this session, ${avgResponseSeconds.toStringAsFixed(1)}s avg).';
      } else {
        adaptiveReason = 'No difficulty change: performance trend stayed within current level thresholds.';
      }

      if (mounted && tunedDifficulty != null) {
        final trackName = isVocabulary ? 'Vocabulary' : 'Sentence';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Adaptive difficulty updated: $trackName is now ${_capitalize(tunedDifficulty)}.'),
            backgroundColor: AppColors.primaryTeal,
          ),
        );
      }
    } else if (_autoDifficultyEnabled && actualAccuracy == null) {
      adaptiveReason = 'No verified score returned by this quiz yet, so difficulty was kept unchanged.';
    }

    final historyKey = _sessionHistoryKey(courseId, targetLanguage, nativeLanguage);
    final currentHistoryRaw = prefs.getString(historyKey);
    final history = currentHistoryRaw == null
        ? <Map<String, dynamic>>[]
        : (jsonDecode(currentHistoryRaw) as List<dynamic>)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
    history.insert(0, {
      'mode': mode,
      'difficulty': isVocabulary ? _vocabDifficulty : _sentenceDifficulty,
      'durationSeconds': duration.inSeconds,
      'timestamp': now.toIso8601String(),
      'accuracy': actualAccuracy,
      if (tunedDifficulty != null) 'adaptiveMovedTo': tunedDifficulty,
    });
    final trimmed = history.take(7).toList();
    await prefs.setString(historyKey, jsonEncode(trimmed));
    if (mounted) {
      setState(() => _sessionHistory = trimmed);
    }

    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PracticeSessionAnalyticsScreen(
          modeName: mode,
          accuracy: actualAccuracy,
          averageResponseSeconds: avgResponseSeconds,
          duration: duration,
          weakAreas: [
            if (isVocabulary) 'Difficulty: $_vocabDifficulty',
            if (!isVocabulary) 'Difficulty: $_sentenceDifficulty',
            if (!isVocabulary) 'Sentence category: $_sentenceCategory',
          ],
          recommendedNextMode: isVocabulary ? 'Fill in the Blank' : 'Vocabulary Quiz',
          adaptiveReason: adaptiveReason,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final activeCourse = context.watch<CourseProvider>().activeCourse;
    final isGuest = authProvider.isGuest;

    _maybeLaunchInitialMode();

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Practice Modes',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _buildHeader(),
                ),
                if (isGuest)
                  SliverToBoxAdapter(
                    child: _buildGuestBanner(context),
                  ),
                if (activeCourse != null)
                  SliverToBoxAdapter(
                    child: _buildPracticeConfigurationSection(),
                  ),
                SliverToBoxAdapter(
                  child: _buildSessionHistoryTimeline(),
                ),
                SliverToBoxAdapter(
                  child: _buildPracticeModesList(context, isGuest),
                ),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.tealGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryTeal.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choose Your Practice',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_vocabulary.length} words available',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 16,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY();
  }

  Widget _buildGuestBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.accentCoral, AppColors.accentOrange],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lock_outline, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Guest Mode Limitations',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Limited to basic practice modes\n• Progress not saved\n• No achievements or leaderboards\n• Create an account to unlock all features!',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 13,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(delay: 100.ms);
  }

  Widget _buildPracticeConfigurationSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Session Configuration',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Set defaults for vocabulary and sentence quizzes',
            style: TextStyle(color: AppColors.textMedium),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _autoDifficultyEnabled,
            onChanged: (value) => _updateSessionConfig(() => _autoDifficultyEnabled = value),
            title: const Text('Auto Difficulty', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark)),
            subtitle: const Text('Automatically tune difficulty based on real quiz performance'),
            activeColor: AppColors.primaryTeal,
          ),
          const SizedBox(height: 8),
          _buildConfigBlock(
            title: 'Vocabulary',
            icon: Icons.library_books,
            children: [
              _buildChipSelector(
                label: 'Part of Speech',
                value: _vocabPartOfSpeech,
                options: ['all', ..._extractPartOfSpeechOptions()],
                onChanged: (value) => _updateSessionConfig(() => _vocabPartOfSpeech = value),
              ),
              _buildChipSelector(
                label: 'Category',
                value: _vocabCategory,
                options: ['all', ..._concepts],
                onChanged: (value) => _updateSessionConfig(() => _vocabCategory = value),
              ),
              _buildChipSelector(
                label: 'Difficulty',
                value: _vocabDifficulty,
                options: const ['beginner', 'intermediate', 'advanced'],
                onChanged: (value) => _updateSessionConfig(() => _vocabDifficulty = value),
              ),
              _buildChipSelector(
                label: 'Review Queue',
                value: _reviewQueueFilter,
                options: const ['all', 'due', 'overdue', 'new'],
                optionLabel: (option) {
                  final label = option == 'all' ? 'All' : _capitalize(option);
                  return '$label (${_reviewQueueCount(option)})';
                },
                onChanged: (value) => _updateSessionConfig(() => _reviewQueueFilter = value),
              ),
              _buildCountSelector(
                value: _vocabQuestionCount,
                onChanged: (value) => _updateSessionConfig(() => _vocabQuestionCount = value),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _startDueReviewSession(context),
                  icon: const Icon(Icons.play_circle_outline),
                  label: Text('Start Due Review Now (${_reviewQueueCount('due')})'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryTeal,
                    side: BorderSide(color: AppColors.primaryTeal.withValues(alpha: 0.35)),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _startWeakAreasSession(context),
                  icon: const Icon(Icons.psychology_alt_outlined),
                  label: const Text('Weak Areas Only Quiz'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accentOrange,
                    side: BorderSide(color: AppColors.accentOrange.withValues(alpha: 0.45)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildConfigBlock(
            title: 'Sentences',
            icon: Icons.notes,
            children: [
              _buildChipSelector(
                label: 'Category',
                value: _sentenceCategory,
                options: ['all', ..._concepts],
                onChanged: (value) => _updateSessionConfig(() => _sentenceCategory = value),
              ),
              _buildChipSelector(
                label: 'Difficulty',
                value: _sentenceDifficulty,
                options: const ['beginner', 'intermediate', 'advanced'],
                onChanged: (value) => _updateSessionConfig(() => _sentenceDifficulty = value),
              ),
              _buildCountSelector(
                value: _sentenceQuestionCount,
                onChanged: (value) => _updateSessionConfig(() => _sentenceQuestionCount = value),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().slideY(delay: 50.ms);
  }

  Widget _buildConfigBlock({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.softWhite,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primaryTeal),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildChipSelector({
    required String label,
    required String value,
    required List<String> options,
    required ValueChanged<String> onChanged,
    String Function(String option)? optionLabel,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textMedium,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: options.map((option) {
              final isSelected = value == option;
              return ChoiceChip(
                label: Text(
                  optionLabel != null
                      ? optionLabel(option)
                      : option == 'all'
                          ? 'All'
                          : _capitalize(option),
                ),
                selected: isSelected,
                onSelected: (_) => onChanged(option),
                selectedColor: AppColors.primaryTeal.withValues(alpha: 0.15),
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.primaryTeal : AppColors.textMedium,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected ? AppColors.primaryTeal : Colors.grey.shade300,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCountSelector({
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    const counts = [10, 20, 50, -1];
    return _buildChipSelector(
      label: 'Questions per session',
      value: value.toString(),
      options: counts.map((e) => e.toString()).toList(),
      onChanged: (selected) => onChanged(int.parse(selected)),
      optionLabel: (option) => option == '-1' ? 'Infinite' : option,
    );
  }

  List<String> _extractPartOfSpeechOptions() {
    final set = <String>{};
    for (final item in _vocabulary) {
      final pos = item.partOfSpeech?.trim().toLowerCase();
      if (pos != null && pos.isNotEmpty) set.add(pos);
    }
    final list = set.toList()..sort();
    if (list.isEmpty) {
      return ['noun', 'verb', 'adjective', 'particle', 'postposition'];
    }
    return list;
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }


  List<VocabularyItem> _weakFocusedVocabularyForSession() {
    final filtered = _filteredVocabularyForSession();
    if (filtered.isEmpty) return filtered;

    final weakPosMap = (_weakFocusStats['partOfSpeech'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    final weakCategoryMap = (_weakFocusStats['category'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};

    String? weakPos;
    String? weakCategory;

    if (weakPosMap.isNotEmpty) {
      weakPos = weakPosMap.entries
          .where((entry) => entry.key != 'all')
          .fold<MapEntry<String, dynamic>?>(null, (best, entry) {
        if (best == null) return entry;
        final bestScore = (best.value as num?)?.toDouble() ?? 0;
        final score = (entry.value as num?)?.toDouble() ?? 0;
        return score > bestScore ? entry : best;
      })
          ?.key;
    }

    if (weakCategoryMap.isNotEmpty) {
      weakCategory = weakCategoryMap.entries
          .where((entry) => entry.key != 'all')
          .fold<MapEntry<String, dynamic>?>(null, (best, entry) {
        if (best == null) return entry;
        final bestScore = (best.value as num?)?.toDouble() ?? 0;
        final score = (entry.value as num?)?.toDouble() ?? 0;
        return score > bestScore ? entry : best;
      })
          ?.key;
    }

    var weakFocused = filtered.where((item) {
      final posMatch = weakPos != null && (item.partOfSpeech ?? '').toLowerCase() == weakPos;
      final category = (item.category ?? '').toLowerCase();
      final tagMatch = weakCategory != null && item.tags.map((tag) => tag.toLowerCase()).contains(weakCategory);
      final categoryMatch = weakCategory != null && (category == weakCategory || tagMatch);
      return posMatch || categoryMatch;
    }).toList();

    if (weakFocused.isEmpty) {
      weakFocused = filtered;
    }

    if (_vocabQuestionCount != -1 && weakFocused.length > _vocabQuestionCount) {
      weakFocused = weakFocused.sublist(0, _vocabQuestionCount);
    }

    return weakFocused;
  }

  Future<void> _startWeakAreasSession(BuildContext context) async {
    final activeCourse = context.read<CourseProvider>().activeCourse;
    final targetLanguage = activeCourse?.targetLanguage ?? 'es';
    final nativeLanguage = activeCourse?.nativeLanguage ?? 'en';

    final weakSession = _weakFocusedVocabularyForSession();
    if (weakSession.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No weak-area signals yet. Complete a few sessions first.'),
          backgroundColor: AppColors.primaryTeal,
        ),
      );
      return;
    }

    final stopwatch = Stopwatch()..start();
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VocabularyQuizScreen(
          vocabulary: weakSession,
          targetLanguage: targetLanguage,
          nativeLanguage: nativeLanguage,
        ),
      ),
    );
    stopwatch.stop();

    if (!mounted) return;
    await _recordSessionCompletion(
      mode: 'Weak Areas Quiz',
      isVocabulary: true,
      totalItems: weakSession.length,
      duration: stopwatch.elapsed,
      quizResult: result,
      vocabulary: weakSession,
    );
  }

  List<VocabularyItem> _filteredVocabularyForSession() {
    var filtered = List<VocabularyItem>.from(_vocabulary);

    if (_vocabPartOfSpeech != 'all') {
      filtered = filtered.where((item) => (item.partOfSpeech ?? '').toLowerCase() == _vocabPartOfSpeech).toList();
    }

    if (_vocabCategory != 'all') {
      filtered = filtered.where((item) {
        final category = (item.category ?? '').toLowerCase();
        return category == _vocabCategory.toLowerCase() ||
            item.tags.map((tag) => tag.toLowerCase()).contains(_vocabCategory.toLowerCase());
      }).toList();
    }

    filtered = filtered.where((item) {
      switch (_vocabDifficulty) {
        case 'beginner':
          return item.difficultyLevel <= 2;
        case 'intermediate':
          return item.difficultyLevel >= 3 && item.difficultyLevel <= 4;
        case 'advanced':
          return item.difficultyLevel >= 5;
        default:
          return true;
      }
    }).toList();

    final now = DateTime.now();
    if (_reviewQueueFilter != 'all') {
      filtered = filtered.where((item) {
        final stats = (_reviewStats[item.id] as Map?)?.cast<String, dynamic>();
        final reviewCount = (stats?['reviewCount'] ?? 0) as int;
        final nextReviewAtRaw = stats?['nextReviewAt'] as String?;
        final nextReviewAt = nextReviewAtRaw == null ? null : DateTime.tryParse(nextReviewAtRaw);

        switch (_reviewQueueFilter) {
          case 'new':
            return reviewCount == 0;
          case 'due':
            return nextReviewAt != null && !nextReviewAt.isAfter(now);
          case 'overdue':
            return nextReviewAt != null && nextReviewAt.isBefore(now.subtract(const Duration(days: 1)));
          default:
            return true;
        }
      }).toList();
    }

    if (filtered.isEmpty) {
      filtered = List<VocabularyItem>.from(_vocabulary);
    }

    if (_vocabQuestionCount != -1 && filtered.length > _vocabQuestionCount) {
      filtered = filtered.sublist(0, _vocabQuestionCount);
    }

    return filtered;
  }

  List<Map<String, dynamic>> _filteredSentencesForSession(List<Map<String, dynamic>> sentences) {
    var filtered = List<Map<String, dynamic>>.from(sentences);

    filtered = filtered.where((sentence) {
      final rawDifficulty = (sentence['difficulty'] ?? sentence['difficulty_level'] ?? sentence['level'] ?? 'beginner').toString().toLowerCase();

      switch (_sentenceDifficulty) {
        case 'beginner':
          return rawDifficulty.contains('beginner') || rawDifficulty.contains('a1') || rawDifficulty.contains('a2') || rawDifficulty == '1' || rawDifficulty == '2';
        case 'intermediate':
          return rawDifficulty.contains('intermediate') || rawDifficulty.contains('b1') || rawDifficulty.contains('b2') || rawDifficulty == '3' || rawDifficulty == '4';
        case 'advanced':
          return rawDifficulty.contains('advanced') || rawDifficulty.contains('c1') || rawDifficulty.contains('c2') || rawDifficulty == '5';
        default:
          return true;
      }
    }).toList();

    if (_sentenceQuestionCount != -1 && filtered.length > _sentenceQuestionCount) {
      filtered = filtered.sublist(0, _sentenceQuestionCount);
    }

    if (filtered.isEmpty) {
      filtered = List<Map<String, dynamic>>.from(sentences.take(_sentenceQuestionCount == -1 ? sentences.length : _sentenceQuestionCount));
    }

    return filtered;
  }

  Widget _buildPracticeModesList(BuildContext context, bool isGuest) {
    final modes = [
      {
        'name': 'Falling Words',
        'description': 'Catch falling words and match translations',
        'icon': Icons.arrow_downward,
        'color': Colors.purple,
        'available': true,
        'isNew': true,
        'onTap': () { _launchFallingWords(context); },
      },
      {
        'name': 'Word Match',
        'description': 'Match words with their translations',
        'icon': Icons.compare_arrows,
        'color': Colors.teal,
        'available': true,
        'isNew': true,
        'onTap': () { _launchWordMatch(context); },
      },
      {
        'name': 'Vocabulary Quiz',
        'description': 'Test your knowledge with multiple choice',
        'icon': Icons.quiz,
        'color': AppColors.primaryTeal,
        'available': true,
        'isNew': false,
        'onTap': () { _launchVocabularyQuiz(context); },
      },
      {
        'name': 'Weak Areas Quiz',
        'description': 'Focus on low-confidence parts of speech and categories',
        'icon': Icons.psychology_alt,
        'color': AppColors.accentOrange,
        'available': true,
        'isNew': true,
        'onTap': () { _startWeakAreasSession(context); },
      },
      {
        'name': 'Picture Quiz',
        'description': 'Identify vocabulary from picture clues',
        'icon': Icons.image,
        'color': Colors.pink,
        'available': true,
        'isNew': true,
        'onTap': () { _launchPictureQuiz(context); },
      },
      {
        'name': 'Flashcards',
        'description': 'Review words with flashcards',
        'icon': Icons.style,
        'color': Colors.orange,
        'available': !isGuest,
        'isNew': false,
        'onTap': isGuest ? () => _showGuestRestriction(context) : () { _launchFlashcards(context); },
      },
      {
        'name': 'Fill in Blank',
        'description': 'Complete sentences with missing words',
        'icon': Icons.edit_note,
        'color': Colors.indigo,
        'available': !isGuest,
        'isNew': false,
        'onTap': isGuest ? () => _showGuestRestriction(context) : () { _launchFillInBlank(context); },
      },
      {
        'name': 'Listening Practice',
        'description': 'Listen and type what you hear',
        'icon': Icons.hearing,
        'color': AppColors.accentOrange,
        'available': !isGuest,
        'isNew': false,
        'onTap': isGuest ? () => _showGuestRestriction(context) : () { _launchListeningPractice(context); },
      },
      {
        'name': 'Pronunciation',
        'description': 'Practice speaking with AI feedback',
        'icon': Icons.mic,
        'color': Colors.blue,
        'available': !isGuest,
        'isNew': false,
        'onTap': isGuest ? () => _showGuestRestriction(context) : () { _launchPronunciation(context); },
      },
      {
        'name': 'Speed Challenge',
        'description': 'Race against time to answer questions',
        'icon': Icons.speed,
        'color': Colors.red,
        'available': !isGuest,
        'isNew': false,
        'onTap': isGuest ? () => _showGuestRestriction(context) : () { _launchSpeedChallenge(context); },
      },
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: modes.map((mode) {
          final index = modes.indexOf(mode);
          return _buildModeCard(mode, index);
        }).toList(),
      ),
    );
  }

  Widget _buildModeCard(Map<String, dynamic> mode, int index) {
    final isAvailable = mode['available'] as bool;
    final isNew = mode['isNew'] as bool;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AnimatedCard(
        delayMs: index * 100,
        onTap: isAvailable ? mode['onTap'] as VoidCallback? : null,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isAvailable ? Colors.white : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isAvailable 
                  ? (mode['color'] as Color).withValues(alpha: 0.3)
                  : Colors.grey.shade300,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isAvailable
                      ? (mode['color'] as Color).withValues(alpha: 0.1)
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  mode['icon'] as IconData,
                  color: isAvailable ? mode['color'] as Color : Colors.grey,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          mode['name'] as String,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isAvailable 
                                ? AppColors.textDark 
                                : Colors.grey,
                          ),
                        ),
                        if (isNew) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'NEW',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      mode['description'] as String,
                      style: TextStyle(
                        fontSize: 14,
                        color: isAvailable 
                            ? AppColors.textMedium 
                            : Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isAvailable)
                const Icon(
                  Icons.lock,
                  color: Colors.grey,
                )
              else
                Icon(
                  Icons.arrow_forward_ios,
                  color: mode['color'] as Color,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchFallingWords(BuildContext context) async {
    final vocabularyForSession = _filteredVocabularyForSession();

    if (vocabularyForSession.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Need at least 4 vocabulary words to play'), backgroundColor: Colors.orange,),
      );
      return;
    }
    final activeCourse = context.read<CourseProvider>().activeCourse;
    if (activeCourse == null) return;

    final stopwatch = Stopwatch()..start();
    final result = await Navigator.push(context, MaterialPageRoute(
      builder: (context) => FallingWordsLauncher(
        vocabulary: vocabularyForSession,
        targetLanguage: activeCourse.targetLanguage,
        nativeLanguage: activeCourse.nativeLanguage,
      ),
    ));
    stopwatch.stop();
    await _recordSessionCompletion(mode: 'Falling Words', isVocabulary: true, totalItems: vocabularyForSession.length, duration: stopwatch.elapsed, quizResult: result, vocabulary: vocabularyForSession);
  }

  Future<void> _launchWordMatch(BuildContext context) async {
    final vocabularyForSession = _filteredVocabularyForSession();

    if (vocabularyForSession.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Need at least 4 vocabulary words to play'), backgroundColor: Colors.orange,),
      );
      return;
    }
    final activeCourse = context.read<CourseProvider>().activeCourse;
    if (activeCourse == null) return;

    final stopwatch = Stopwatch()..start();
    final result = await Navigator.push(context, MaterialPageRoute(
      builder: (context) => WordMatchLauncher(
        vocabulary: vocabularyForSession,
        targetLanguage: activeCourse.targetLanguage,
        nativeLanguage: activeCourse.nativeLanguage,
      ),
    ));
    stopwatch.stop();
    await _recordSessionCompletion(mode: 'Word Match', isVocabulary: true, totalItems: vocabularyForSession.length, duration: stopwatch.elapsed, quizResult: result, vocabulary: vocabularyForSession);
  }

  Future<void> _launchVocabularyQuiz(BuildContext context) async {
    final vocabularyForSession = _filteredVocabularyForSession();

    if (vocabularyForSession.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Need at least 4 vocabulary words to play'), backgroundColor: Colors.orange,),
      );
      return;
    }
    final activeCourse = context.read<CourseProvider>().activeCourse;
    if (activeCourse == null) return;

    final stopwatch = Stopwatch()..start();
    final result = await Navigator.push(context, MaterialPageRoute(
      builder: (context) => VocabularyQuizScreen(
        vocabulary: vocabularyForSession,
        targetLanguage: activeCourse.targetLanguage,
        nativeLanguage: activeCourse.nativeLanguage,
      ),
    ));
    stopwatch.stop();
    await _recordSessionCompletion(mode: 'Vocabulary Quiz', isVocabulary: true, totalItems: vocabularyForSession.length, duration: stopwatch.elapsed, quizResult: result, vocabulary: vocabularyForSession);
  }

  Future<void> _launchFlashcards(BuildContext context) async {
    final vocabularyForSession = _filteredVocabularyForSession();

    if (vocabularyForSession.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Need at least 4 vocabulary words to play'), backgroundColor: Colors.orange,),
      );
      return;
    }
    final activeCourse = context.read<CourseProvider>().activeCourse;
    if (activeCourse == null) return;

    final stopwatch = Stopwatch()..start();
    final result = await Navigator.push(context, MaterialPageRoute(
      builder: (context) => FlashcardsScreen(
        vocabulary: vocabularyForSession,
        targetLanguage: activeCourse.targetLanguage,
        nativeLanguage: activeCourse.nativeLanguage,
      ),
    ));
    stopwatch.stop();
    await _recordSessionCompletion(mode: 'Flashcards', isVocabulary: true, totalItems: vocabularyForSession.length, duration: stopwatch.elapsed, quizResult: result, vocabulary: vocabularyForSession);
  }

  Future<void> _launchPictureQuiz(BuildContext context) async {
    final vocabularyForSession = _filteredVocabularyForSession();

    if (vocabularyForSession.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Need at least 4 vocabulary words to play'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final activeCourse = context.read<CourseProvider>().activeCourse;

    final stopwatch = Stopwatch()..start();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageRecognitionScreen.withVocabulary(
          vocabulary: vocabularyForSession,
          targetLanguage: activeCourse?.targetLanguage ?? 'es',
          nativeLanguage: activeCourse?.nativeLanguage ?? 'en',
        ),
      ),
    );
    stopwatch.stop();
    await _recordSessionCompletion(mode: 'Picture Quiz', isVocabulary: true, totalItems: vocabularyForSession.length, duration: stopwatch.elapsed, quizResult: result, vocabulary: vocabularyForSession);
  }

  Future<void> _launchFillInBlank(BuildContext context) async {
    final activeCourse = context.read<CourseProvider>().activeCourse;
    if (activeCourse == null) return;

    setState(() { _isLoading = true; });

    final csvService = CsvDataService();
    final sentences = await csvService.getSentences(
      activeCourse.targetLanguage,
      activeCourse.nativeLanguage,
      categoryConceptIds: _sentenceCategory == 'all' ? null : _sentenceCategory,
    );

    setState(() { _isLoading = false; });

    final filteredSentences = _filteredSentencesForSession(sentences);

    if (filteredSentences.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No sentences available for Fill in Blank'), backgroundColor: Colors.orange),
        );
      }
      return;
    }

    if (context.mounted) {
      final stopwatch = Stopwatch()..start();
      final result = await Navigator.push(context, MaterialPageRoute(
        builder: (context) => FillInBlankScreen(
          sentences: filteredSentences,
          targetLanguage: activeCourse.targetLanguage,
          nativeLanguage: activeCourse.nativeLanguage,
        ),
      ));
      stopwatch.stop();
      await _recordSessionCompletion(mode: 'Fill in the Blank', isVocabulary: false, totalItems: filteredSentences.length, duration: stopwatch.elapsed, quizResult: result);
    }
  }

  Future<void> _launchListeningPractice(BuildContext context) async {
    final vocabularyForSession = _filteredVocabularyForSession();

    if (vocabularyForSession.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Need at least 4 vocabulary words to play'), backgroundColor: Colors.orange,),
      );
      return;
    }
    final activeCourse = context.read<CourseProvider>().activeCourse;
    if (activeCourse == null) return;

    final stopwatch = Stopwatch()..start();
    final result = await Navigator.push(context, MaterialPageRoute(
      builder: (context) => ListeningPracticeScreen(
        vocabulary: vocabularyForSession,
        targetLanguage: activeCourse.targetLanguage,
        nativeLanguage: activeCourse.nativeLanguage,
      ),
    ));
    stopwatch.stop();
    await _recordSessionCompletion(mode: 'Listening Practice', isVocabulary: true, totalItems: vocabularyForSession.length, duration: stopwatch.elapsed, quizResult: result, vocabulary: vocabularyForSession);
  }

  Future<void> _launchSpeedChallenge(BuildContext context) async {
    final vocabularyForSession = _filteredVocabularyForSession();

    if (vocabularyForSession.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Need at least 4 vocabulary words to play'), backgroundColor: Colors.orange,),
      );
      return;
    }
    final activeCourse = context.read<CourseProvider>().activeCourse;
    if (activeCourse == null) return;

    final stopwatch = Stopwatch()..start();
    final result = await Navigator.push(context, MaterialPageRoute(
      builder: (context) => SpeedChallengeScreen(
        vocabulary: vocabularyForSession,
        targetLanguage: activeCourse.targetLanguage,
        nativeLanguage: activeCourse.nativeLanguage,
      ),
    ));
    stopwatch.stop();
    await _recordSessionCompletion(mode: 'Speed Challenge', isVocabulary: true, totalItems: vocabularyForSession.length, duration: stopwatch.elapsed, quizResult: result, vocabulary: vocabularyForSession);
  }

  Future<void> _launchPronunciation(BuildContext context) async {
    final vocabularyForSession = _filteredVocabularyForSession();

    if (vocabularyForSession.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Need at least 4 vocabulary words to play'), backgroundColor: Colors.orange,),
      );
      return;
    }
    final activeCourse = context.read<CourseProvider>().activeCourse;
    if (activeCourse == null) return;

    final stopwatch = Stopwatch()..start();
    final result = await Navigator.push(context, MaterialPageRoute(
      builder: (context) => PronunciationPracticeScreen(
        vocabulary: vocabularyForSession,
        targetLanguage: activeCourse.targetLanguage,
        nativeLanguage: activeCourse.nativeLanguage,
      ),
    ));
    stopwatch.stop();
    await _recordSessionCompletion(mode: 'Pronunciation Practice', isVocabulary: true, totalItems: vocabularyForSession.length, duration: stopwatch.elapsed, quizResult: result, vocabulary: vocabularyForSession);
  }

  void _showGuestRestriction(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Premium Feature'),
        content: const Text(
          'This practice mode is only available for registered users. '
          'Create a free account to unlock all practice modes and save your progress!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Maybe Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to registration
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RegisterScreen()),
              );
            },
            child: const Text('Create Account'),
          ),
        ],
      ),
    );
  }
}

class AnimatedCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final int delayMs;

  const AnimatedCard({
    super.key,
    required this.child,
    this.onTap,
    this.delayMs = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: child.animate()
        .fadeIn(delay: Duration(milliseconds: delayMs))
        .slideY(begin: 0.2, end: 0, delay: Duration(milliseconds: delayMs)),
    );
  }
}
