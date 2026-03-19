import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/vocabulary_item.dart';
import '../models/sentence_item.dart';
import '../providers/auth_provider.dart';
import '../providers/course_provider.dart';
import '../services/csv_data_service.dart';
import '../services/srs_service.dart';
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
import 'practice_modes/writing_practice_screen.dart';
import 'practice_modes/spelling_bee_screen.dart';
import 'practice_modes/word_association_screen.dart';
import 'practice_modes/listening_dictation_screen.dart';
import 'practice_modes/speed_review_screen.dart';
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
  String _partOfSpeech = 'all';
  int _vocabQuestionCount = 10;
  int _sentenceQuestionCount = 10;
  Map<String, dynamic> _reviewStats = {};
  Map<String, dynamic> _weakFocusStats = {};
  List<Map<String, dynamic>> _sessionHistory = [];
  bool _hasAutoLaunchedInitialMode = false;

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
          limit: 300, // Increase limit for better SRS pool
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
      if (mounted) {
        setState(() {
          _vocabulary = _getDemoVocabulary();
          _isLoading = false;
        });
      }
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
      'practice_session_config_simplified_${courseId}_${targetLanguage}_$nativeLanguage';

  String _reviewStatsKey(String courseId, String targetLanguage, String nativeLanguage) =>
      'practice_review_stats_${courseId}_${targetLanguage}_$nativeLanguage';

  String _lastSessionKey(String courseId, String targetLanguage, String nativeLanguage) =>
      'practice_last_session_${courseId}_${targetLanguage}_$nativeLanguage';

  String _sessionHistoryKey(String courseId, String targetLanguage, String nativeLanguage) =>
      'practice_session_history_${courseId}_${targetLanguage}_$nativeLanguage';


  String _weakFocusKey(String courseId, String targetLanguage, String nativeLanguage) =>
      'practice_weak_focus_${courseId}_${targetLanguage}_$nativeLanguage';

  Future<void> _loadSessionConfiguration(String courseId, String targetLanguage, String nativeLanguage) async {
    final prefs = await SharedPreferences.getInstance();
    final rawConfig = prefs.getString(_sessionConfigKey(courseId, targetLanguage, nativeLanguage));
    final rawDefaultConfig = prefs.getString('practice_session_config_default_${targetLanguage}_$nativeLanguage');
    final rawStats = prefs.getString(_reviewStatsKey(courseId, targetLanguage, nativeLanguage));
    final rawHistory = prefs.getString(_sessionHistoryKey(courseId, targetLanguage, nativeLanguage));
    final rawWeakFocus = prefs.getString(_weakFocusKey(courseId, targetLanguage, nativeLanguage));

    if (rawConfig == null && rawStats == null && rawHistory == null && rawWeakFocus == null) return;

    final config = rawConfig == null ? <String, dynamic>{} : jsonDecode(rawConfig) as Map<String, dynamic>;
    final stats = rawStats == null ? <String, dynamic>{} : jsonDecode(rawStats) as Map<String, dynamic>;
    final history = rawHistory == null
        ? <Map<String, dynamic>>[]
        : (jsonDecode(rawHistory) as List<dynamic>).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    final weakFocus = rawWeakFocus == null ? <String, dynamic>{} : jsonDecode(rawWeakFocus) as Map<String, dynamic>;

    setState(() {
      _partOfSpeech = (config['partOfSpeech'] ?? _partOfSpeech) as String;
      _vocabQuestionCount = (config['vocabQuestionCount'] ?? config['questionCount'] ?? _vocabQuestionCount) as int;
      _sentenceQuestionCount = (config['sentenceQuestionCount'] ?? config['questionCount'] ?? _sentenceQuestionCount) as int;
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
        'partOfSpeech': _partOfSpeech,
        'vocabQuestionCount': _vocabQuestionCount,
        'sentenceQuestionCount': _sentenceQuestionCount,
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

    // Instead of auto-launching or showing a snackbar, the UI will 
    // selectively show a prominent "Start [Mode]" button at the top
    // of the configuration section.
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
      case 'spelling bee':
        await _launchSpellingBee(context);
        break;
      case 'word association':
        await _launchWordAssociation(context);
        break;
      case 'listening dictation':
        await _launchListeningDictation(context);
        break;
      case 'speed review':
        await _launchSpeedReview(context);
        break;
      case 'writing practice':
        await _launchWritingPractice(context);
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
          Text('Last 7 Sessions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 10),
          ...recent.map((entry) {
            final mode = entry['mode']?.toString() ?? 'Practice';
            final duration = (entry['durationSeconds'] ?? 0) as int;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.history, size: 16, color: AppColors.primaryTeal),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$mode • ${duration}s',
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
    final dueCount = _reviewQueueCount('due');
    if (dueCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No due review items right now.'),
          backgroundColor: AppColors.primaryTeal,
        ),
      );
      return;
    }

    await _launchVocabularyQuiz(context);
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
        'accuracy': actualAccuracy,
        'count': totalItems,
        'completedAt': now.toIso8601String(),
        'durationSeconds': duration.inSeconds,
      }),
    );

    if (vocabulary.isNotEmpty) {
      final srsService = SrsService();
      
      // If the quiz provided granular performance data, use it.
      // Format expected: {'wordId1': true, 'wordId2': false, ...}
      final Map<String, dynamic>? wordPerformance = 
          (quizResult is Map && quizResult.containsKey('wordPerformance'))
              ? quizResult['wordPerformance'] as Map<String, dynamic>
              : null;

      for (final item in vocabulary) {
        // If we have specific results for this word, use them. 
        // Otherwise fallback to the overall session success.
        final bool isCorrect = wordPerformance?[item.id] ?? (actualAccuracy != null && actualAccuracy >= 0.7);
        
        await srsService.updateSrsState(
          courseId, 
          item.id, 
          SrsService.fromCorrect(isCorrect),
        );
      }
      
      // Also update the UI's local stats for the queue counters
      final key = _reviewStatsKey(courseId, targetLanguage, nativeLanguage);
      final rawStats = prefs.getString(key);
      final stats = rawStats == null ? <String, dynamic>{} : jsonDecode(rawStats) as Map<String, dynamic>;

      for (final item in vocabulary) {
        final itemStats = (stats[item.id] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
        itemStats['reviewCount'] = (itemStats['reviewCount'] ?? 0) + 1;
        itemStats['lastReviewedAt'] = now.toIso8601String();
        // Note: nextReviewAt is now managed by SrsService, but we keep this for UI counters 
        // until they are fully migrated to check SrsService directly.
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

      if (_partOfSpeech != 'all') {
        final current = (posMap[_partOfSpeech] as num?)?.toDouble() ?? 0;
        posMap[_partOfSpeech] = (current + delta).clamp(0, 20).toDouble();
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


    final historyKey = _sessionHistoryKey(courseId, targetLanguage, nativeLanguage);
    final currentHistoryRaw = prefs.getString(historyKey);
    final history = currentHistoryRaw == null
        ? <Map<String, dynamic>>[]
        : (jsonDecode(currentHistoryRaw) as List<dynamic>)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
    history.insert(0, {
      'mode': mode,
      'durationSeconds': duration.inSeconds,
      'timestamp': now.toIso8601String(),
      'accuracy': actualAccuracy,
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
            'Questions: ${isVocabulary ? _vocabQuestionCount : _sentenceQuestionCount}',
            if (isVocabulary && _partOfSpeech != 'all') 'Filter: $_partOfSpeech',
          ],
          recommendedNextMode: isVocabulary ? 'Fill in the Blank' : 'Vocabulary Quiz',
          adaptiveReason: 'Session completed with ${(actualAccuracy ?? 0 * 100).toStringAsFixed(0)}% accuracy.',
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
      backgroundColor: AppColors.accentCoral,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Practice Modes',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
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
                if (widget.initialMode != null && activeCourse != null)
                  SliverToBoxAdapter(
                    child: _buildInitialModeBanner(context, widget.initialMode!),
                  ),
                if (activeCourse != null)
                  SliverToBoxAdapter(
                    child: _buildPracticeConfigurationSection(),
                  ),
                SliverToBoxAdapter(
                  child: _buildSessionHistoryTimeline(),
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
          Text(
            widget.initialMode != null ? 'Configure Session' : 'Practice Modes',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.initialMode != null ? 'Set your preferences for ${widget.initialMode}' : '${_vocabulary.length} words available',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 16,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY();
  }

  Widget _buildInitialModeBanner(BuildContext context, String modeName) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryTeal.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryTeal.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flash_on, color: AppColors.primaryTeal),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Launch $modeName',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Check your session settings below, then tap start to jump right in!',
            style: TextStyle(color: AppColors.textMedium, fontSize: 13),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _launchModeByName(context, modeName),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryTeal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.play_arrow),
              label: Text('START ${modeName.toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY();
  }

  Widget _buildGuestBanner(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
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
          Text(
            'Session Configuration',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Set defaults for vocabulary and sentence quizzes',
          ),
          _buildConfigBlock(
            title: 'Vocabulary Quiz Defaults',
            icon: Icons.library_books,
            children: [
              _buildChipSelector(
                label: 'Part of Speech',
                value: _partOfSpeech,
                options: ['all', ..._extractPartOfSpeechOptions()],
                onChanged: (value) => _updateSessionConfig(() => _partOfSpeech = value),
              ),
              _buildCountSelector(
                label: 'Questions per session',
                value: _vocabQuestionCount,
                onChanged: (value) => _updateSessionConfig(() => _vocabQuestionCount = value),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _startWeakAreasSession(context),
                  icon: const Icon(Icons.psychology_alt_outlined),
                  label: const Text('Weak Areas Only Quiz'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.secondary,
                    side: BorderSide(color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.45)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildConfigBlock(
            title: 'Sentence Quiz Defaults',
            icon: Icons.short_text,
            children: [
              _buildCountSelector(
                label: 'Questions per session',
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
    final theme = Theme.of(context);
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
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
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
                    color: isSelected ? AppColors.primaryTeal : AppColors.neutralMid,
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
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    const counts = [10, 20, 50, -1];
    return _buildChipSelector(
      label: label,
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


  Future<List<VocabularyItem>> _weakFocusedVocabularyForSession() async {
    final filtered = await _filteredVocabularyForSession();
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
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final courseProvider = context.read<CourseProvider>();
    final activeCourse = courseProvider.activeCourse;
    final targetLanguage = activeCourse?.targetLanguage ?? 'es';
    final nativeLanguage = activeCourse?.nativeLanguage ?? 'en';

    final weakSession = await _weakFocusedVocabularyForSession();
    
    if (!mounted) return;

    if (weakSession.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('No weak-area signals yet. Complete a few sessions first.'),
          backgroundColor: AppColors.primaryTeal,
        ),
      );
      return;
    }

    final stopwatch = Stopwatch()..start();
    final result = await navigator.push(
      MaterialPageRoute(
        builder: (context) => VocabularyQuizScreen(
          vocabulary: weakSession,
          targetLanguage: targetLanguage,
          nativeLanguage: nativeLanguage,
          courseId: activeCourse?.id ?? 'demo',
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

  Future<List<VocabularyItem>> _filteredVocabularyForSession() async {
    final activeCourse = context.read<CourseProvider>().activeCourse;
    if (activeCourse == null || _vocabulary.isEmpty) return [];

    final srsService = SrsService();
    
    // Filter by part of speech if selected
    var pool = _vocabulary;
    if (_partOfSpeech != 'all') {
      pool = pool.where((item) => (item.partOfSpeech ?? '').toLowerCase() == _partOfSpeech.toLowerCase()).toList();
    }

    if (pool.isEmpty) pool = _vocabulary;

    // Use SRS to select the most relevant words
    final count = _vocabQuestionCount == -1 ? 10 : _vocabQuestionCount;
    return await srsService.selectSessionWords(
      courseId: activeCourse.id,
      allVocab: pool,
      count: count,
    );
  }

  List<Map<String, dynamic>> _filteredSentencesForSession(List<Map<String, dynamic>> sentences) {
    var filtered = List<Map<String, dynamic>>.from(sentences);

    if (_sentenceQuestionCount != -1 && filtered.length > _sentenceQuestionCount) {
      filtered = filtered.sublist(0, _sentenceQuestionCount);
    }

    if (filtered.isEmpty) {
      filtered = List<Map<String, dynamic>>.from(sentences.take(_sentenceQuestionCount == -1 ? sentences.length : _sentenceQuestionCount));
    }

    return filtered;
  }


  Future<void> _launchFallingWords(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final courseProvider = context.read<CourseProvider>();
    final activeCourse = courseProvider.activeCourse;
    if (activeCourse == null) return;

    final vocabularyForSession = await _filteredVocabularyForSession();

    if (!mounted) return;

    if (vocabularyForSession.length < 4) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Need at least 4 vocabulary words to play'), backgroundColor: AppColors.accentCoral,),
      );
      return;
    }

    final stopwatch = Stopwatch()..start();
    final result = await navigator.push(MaterialPageRoute(
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
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final courseProvider = context.read<CourseProvider>();
    final activeCourse = courseProvider.activeCourse;
    if (activeCourse == null) return;

    final vocabularyForSession = await _filteredVocabularyForSession();

    if (!mounted) return;

    if (vocabularyForSession.length < 4) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Need at least 4 vocabulary words to play'), backgroundColor: AppColors.accentCoral,),
      );
      return;
    }

    final stopwatch = Stopwatch()..start();
    final result = await navigator.push(MaterialPageRoute(
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
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final courseProvider = context.read<CourseProvider>();
    final activeCourse = courseProvider.activeCourse;
    if (activeCourse == null) return;

    final vocabularyForSession = await _filteredVocabularyForSession();

    if (!mounted) return;

    if (vocabularyForSession.length < 4) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Need at least 4 vocabulary words to play'), backgroundColor: AppColors.accentCoral,),
      );
      return;
    }

    final stopwatch = Stopwatch()..start();
    final result = await navigator.push(MaterialPageRoute(
      builder: (context) => VocabularyQuizScreen(
        vocabulary: vocabularyForSession,
        targetLanguage: activeCourse.targetLanguage,
        nativeLanguage: activeCourse.nativeLanguage,
        courseId: activeCourse.id,
      ),
    ));
    stopwatch.stop();
    await _recordSessionCompletion(mode: 'Vocabulary Quiz', isVocabulary: true, totalItems: vocabularyForSession.length, duration: stopwatch.elapsed, quizResult: result, vocabulary: vocabularyForSession);
  }

  Future<void> _launchFlashcards(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final courseProvider = context.read<CourseProvider>();
    final activeCourse = courseProvider.activeCourse;
    if (activeCourse == null) return;

    final vocabularyForSession = await _filteredVocabularyForSession();

    if (!mounted) return;

    if (vocabularyForSession.length < 4) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Need at least 4 vocabulary words to play'), backgroundColor: AppColors.accentCoral,),
      );
      return;
    }

    final stopwatch = Stopwatch()..start();
    final result = await navigator.push(MaterialPageRoute(
      builder: (context) => FlashcardsScreen(
        vocabulary: vocabularyForSession,
        targetLanguage: activeCourse.targetLanguage,
        nativeLanguage: activeCourse.nativeLanguage,
        courseId: activeCourse.id,
      ),
    ));
    stopwatch.stop();
    await _recordSessionCompletion(mode: 'Flashcards', isVocabulary: true, totalItems: vocabularyForSession.length, duration: stopwatch.elapsed, quizResult: result, vocabulary: vocabularyForSession);
  }

  Future<void> _launchPictureQuiz(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final activeCourse = context.read<CourseProvider>().activeCourse;

    final vocabularyForSession = await _filteredVocabularyForSession();

    if (!mounted) return;

    if (vocabularyForSession.length < 4) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Need at least 4 vocabulary words to play'),
          backgroundColor: AppColors.accentCoral,
        ),
      );
      return;
    }

    final stopwatch = Stopwatch()..start();
    final result = await navigator.push(
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
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final activeCourse = context.read<CourseProvider>().activeCourse;
    if (activeCourse == null) return;

    setState(() { _isLoading = true; });

    final csvService = CsvDataService();
    final sentences = await csvService.getSentences(
      activeCourse.targetLanguage,
      activeCourse.nativeLanguage,
    );

    if (!mounted) return;
    setState(() { _isLoading = false; });

    final filteredSentences = _filteredSentencesForSession(sentences);

    if (filteredSentences.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('No sentences available for Fill in Blank'), backgroundColor: AppColors.accentCoral),
      );
      return;
    }

    final stopwatch = Stopwatch()..start();
    final result = await navigator.push(MaterialPageRoute(
      builder: (context) => FillInBlankScreen(
        sentences: filteredSentences,
        targetLanguage: activeCourse.targetLanguage,
        nativeLanguage: activeCourse.nativeLanguage,
      ),
    ));
    stopwatch.stop();
    await _recordSessionCompletion(mode: 'Fill in the Blank', isVocabulary: false, totalItems: filteredSentences.length, duration: stopwatch.elapsed, quizResult: result);
  }

  Future<void> _launchListeningPractice(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final activeCourse = context.read<CourseProvider>().activeCourse;
    if (activeCourse == null) return;

    final vocabularyForSession = await _filteredVocabularyForSession();

    if (!mounted) return;

    if (vocabularyForSession.length < 4) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Need at least 4 vocabulary words to play'), backgroundColor: AppColors.accentCoral,),
      );
      return;
    }

    final stopwatch = Stopwatch()..start();
    final result = await navigator.push(MaterialPageRoute(
      builder: (context) => ListeningPracticeScreen(
        vocabulary: vocabularyForSession,
        targetLanguage: activeCourse.targetLanguage,
        nativeLanguage: activeCourse.nativeLanguage,
        courseId: activeCourse.id,
      ),
    ));
    stopwatch.stop();
    await _recordSessionCompletion(mode: 'Listening Practice', isVocabulary: true, totalItems: vocabularyForSession.length, duration: stopwatch.elapsed, quizResult: result, vocabulary: vocabularyForSession);
  }

  Future<void> _launchSpeedChallenge(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final activeCourse = context.read<CourseProvider>().activeCourse;
    if (activeCourse == null) return;

    final vocabularyForSession = await _filteredVocabularyForSession();

    if (!mounted) return;

    if (vocabularyForSession.length < 4) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Need at least 4 vocabulary words to play'), backgroundColor: AppColors.accentCoral,),
      );
      return;
    }

    final stopwatch = Stopwatch()..start();
    final result = await navigator.push(MaterialPageRoute(
      builder: (context) => SpeedChallengeScreen(
        vocabulary: vocabularyForSession,
        targetLanguage: activeCourse.targetLanguage,
        nativeLanguage: activeCourse.nativeLanguage,
        courseId: activeCourse.id,
      ),
    ));
    stopwatch.stop();
    await _recordSessionCompletion(mode: 'Speed Challenge', isVocabulary: true, totalItems: vocabularyForSession.length, duration: stopwatch.elapsed, quizResult: result, vocabulary: vocabularyForSession);
  }

  Future<void> _launchPronunciation(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final activeCourse = context.read<CourseProvider>().activeCourse;
    if (activeCourse == null) return;

    final vocabularyForSession = await _filteredVocabularyForSession();

    if (!mounted) return;

    if (vocabularyForSession.length < 4) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Need at least 4 vocabulary words to play'), backgroundColor: AppColors.accentCoral,),
      );
      return;
    }

    final stopwatch = Stopwatch()..start();
    final result = await navigator.push(MaterialPageRoute(
      builder: (context) => PronunciationPracticeScreen(
        vocabulary: vocabularyForSession,
        targetLanguage: activeCourse.targetLanguage,
        nativeLanguage: activeCourse.nativeLanguage,
        courseId: activeCourse.id,
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

  Future<void> _launchWritingPractice(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final activeCourse = context.read<CourseProvider>().activeCourse;
    if (activeCourse == null) return;

    setState(() => _isLoading = true);
    final sentences = await CsvDataService().getSentences(
      activeCourse.targetLanguage, 
      activeCourse.nativeLanguage,
      limit: _sentenceQuestionCount,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);

    final stopwatch = Stopwatch()..start();
    final result = await navigator.push(
      MaterialPageRoute(
        builder: (context) => WritingPracticeScreen(
          sentences: sentences,
          targetLanguage: activeCourse.targetLanguage,
          nativeLanguage: activeCourse.nativeLanguage,
        ),
      ),
    );
    stopwatch.stop();
    
    if (result != null) {
      await _recordSessionCompletion(
        mode: 'Writing Practice',
        isVocabulary: false,
        totalItems: (result['count'] ?? 5) as int,
        duration: stopwatch.elapsed,
        quizResult: result,
      );
    }
  }



  Future<void> _launchSpellingBee(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final activeCourse = context.read<CourseProvider>().activeCourse;
    if (activeCourse == null) return;

    final vocabularyForSession = await _filteredVocabularyForSession();

    if (!mounted) return;

    if (vocabularyForSession.length < 4) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Need at least 4 vocabulary words to play'), backgroundColor: AppColors.accentCoral,),
      );
      return;
    }

    final stopwatch = Stopwatch()..start();
    final result = await navigator.push(MaterialPageRoute(
      builder: (context) => SpellingBeeScreen(
        vocabulary: vocabularyForSession,
        targetLanguage: activeCourse.targetLanguage,
        nativeLanguage: activeCourse.nativeLanguage,
      ),
    ));
    stopwatch.stop();
    await _recordSessionCompletion(mode: 'Spelling Bee', isVocabulary: true, totalItems: vocabularyForSession.length, duration: stopwatch.elapsed, quizResult: result, vocabulary: vocabularyForSession);
  }

  Future<void> _launchWordAssociation(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final activeCourse = context.read<CourseProvider>().activeCourse;
    if (activeCourse == null) return;

    final vocabularyForSession = await _filteredVocabularyForSession();

    if (!mounted) return;

    if (vocabularyForSession.length < 4) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Need at least 4 vocabulary words to play'), backgroundColor: AppColors.accentCoral,),
      );
      return;
    }

    final stopwatch = Stopwatch()..start();
    final result = await navigator.push(MaterialPageRoute(
      builder: (context) => WordAssociationScreen(
        vocabulary: vocabularyForSession,
        targetLanguage: activeCourse.targetLanguage,
        nativeLanguage: activeCourse.nativeLanguage,
      ),
    ));
    stopwatch.stop();
    await _recordSessionCompletion(mode: 'Word Association', isVocabulary: true, totalItems: vocabularyForSession.length, duration: stopwatch.elapsed, quizResult: result, vocabulary: vocabularyForSession);
  }

  Future<void> _launchListeningDictation(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final activeCourse = context.read<CourseProvider>().activeCourse;
    if (activeCourse == null) return;

    setState(() => _isLoading = true);
    final csvService = CsvDataService();
    final sentences = await csvService.getSentences(
      activeCourse.targetLanguage,
      activeCourse.nativeLanguage,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);

    final filteredSentences = _filteredSentencesForSession(sentences);

    if (filteredSentences.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('No sentences available for Listening Dictation'), backgroundColor: AppColors.accentCoral),
      );
      return;
    }

    final List<SentenceItem> sentenceItems = filteredSentences.map((s) => SentenceItem.fromMap(s)).toList();
    final stopwatch = Stopwatch()..start();
    final result = await navigator.push(MaterialPageRoute(
      builder: (context) => ListeningDictationScreen(
        sentences: sentenceItems,
        targetLanguage: activeCourse.targetLanguage,
        nativeLanguage: activeCourse.nativeLanguage,
      ),
    ));
    stopwatch.stop();
    await _recordSessionCompletion(mode: 'Listening Dictation', isVocabulary: false, totalItems: filteredSentences.length, duration: stopwatch.elapsed, quizResult: result);
  }

  Future<void> _launchSpeedReview(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final activeCourse = context.read<CourseProvider>().activeCourse;
    if (activeCourse == null) return;

    final vocabularyForSession = await _filteredVocabularyForSession();

    if (!mounted) return;

    if (vocabularyForSession.length < 4) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Need at least 4 vocabulary words to play'), backgroundColor: AppColors.accentCoral,),
      );
      return;
    }

    final stopwatch = Stopwatch()..start();
    final result = await navigator.push(MaterialPageRoute(
      builder: (context) => SpeedReviewScreen(
        vocabulary: vocabularyForSession,
        targetLanguage: activeCourse.targetLanguage,
        nativeLanguage: activeCourse.nativeLanguage,
      ),
    ));
    stopwatch.stop();
    await _recordSessionCompletion(mode: 'Speed Review', isVocabulary: true, totalItems: vocabularyForSession.length, duration: stopwatch.elapsed, quizResult: result, vocabulary: vocabularyForSession);
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
