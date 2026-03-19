import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/vocabulary_item.dart';
import '../../theme/app_theme.dart';
import '../../services/tts_service.dart';
import '../../services/audio_service.dart';
import '../../widgets/practice_results_screen.dart';

class VocabularyQuizScreen extends StatefulWidget {
  final List<VocabularyItem> vocabulary;
  final String targetLanguage;
  final String nativeLanguage;
  final String courseId;

  const VocabularyQuizScreen({
    super.key,
    required this.vocabulary,
    required this.targetLanguage,
    required this.nativeLanguage,
    this.courseId = 'demo',
  });

  @override
  State<VocabularyQuizScreen> createState() => _VocabularyQuizScreenState();
}

class _VocabularyQuizScreenState extends State<VocabularyQuizScreen>
    with TickerProviderStateMixin {
  late List<VocabularyItem> _quizVocabulary;
  late List<Map<String, dynamic>> _questions;
  int _currentQuestionIndex = 0;
  int _score = 0;
  int _totalXP = 0;
  int _streak = 0;
  int _maxStreak = 0;
  int _comboMultiplier = 1;
  bool _answered = false;
  int? _selectedAnswer;
  bool _isQuizComplete = false;
  final List<VocabularyItem> _mistakes = [];
  Duration _timeElapsed = Duration.zero;
  Timer? _timer;
  
  // Animation controllers
  late AnimationController _shakeController;
  late AnimationController _celebrationController;

  @override
  void initState() {
    super.initState();
    _loadQuestionsAndStart();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
  }

  @override
  void dispose() {
    TtsService().stop();
    _timer?.cancel();
    _shakeController.dispose();
    _celebrationController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _timeElapsed = Duration(seconds: _timeElapsed.inSeconds + 1);
      });
    });
  }

  void _loadQuestionsAndStart() {
    _quizVocabulary = List<VocabularyItem>.from(widget.vocabulary)..shuffle();
    if (_quizVocabulary.length > 15) {
      _quizVocabulary = _quizVocabulary.sublist(0, 15);
    }
    _buildQuestions();
    _startTimer();
    if (mounted) setState(() {});
  }

  void _prepareQuiz() {
    _quizVocabulary = List<VocabularyItem>.from(widget.vocabulary)..shuffle();
    if (_quizVocabulary.length > 15) {
      _quizVocabulary = _quizVocabulary.sublist(0, 15);
    }
    _buildQuestions();
  }

  void _buildQuestions() {
    _questions = _quizVocabulary.map((word) {
      final correctAnswer = word.translation;
      final options = _generateOptions(word);
      
      return {
        'word': word,
        'question': word.word,
        'context': _generateContext(word),
        'options': options,
        'correctIndex': options.indexOf(correctAnswer),
      };
    }).toList();
  }

  List<String> _generateOptions(VocabularyItem correctWord) {
    final options = <String>[correctWord.translation];
    final otherWords = widget.vocabulary
        .where((w) => w.id != correctWord.id)
        .toList();
    
    otherWords.shuffle();
    
    for (var word in otherWords.take(3)) {
      options.add(word.translation);
    }
    
    while (options.length < 4) {
      options.add('Option ${options.length}');
    }
    
    options.shuffle();
    return options;
  }

  String _generateContext(VocabularyItem word) {
    if (word.exampleSentences.isNotEmpty) {
      return word.exampleSentences.first;
    }
    
    final contexts = [
      'I need to learn "${word.word}" for my trip.',
      'Can you help me understand "${word.word}"?',
      '"${word.word}" is a useful word to know.',
      'Practice saying "${word.word}" out loud.',
    ];
    return contexts[Random().nextInt(contexts.length)];
  }

  void _selectAnswer(int index) {
    if (_answered) return;
    
    HapticFeedback.mediumImpact();
    
    final isCorrect = index == _questions[_currentQuestionIndex]['correctIndex'];
    
    setState(() {
      _answered = true;
      _selectedAnswer = index;
      
      if (isCorrect) {
        AudioService().playCorrect();
        _streak++;
        if (_streak > _maxStreak) _maxStreak = _streak;
        
        _comboMultiplier = 1 + (_streak ~/ 3);
        const baseXP = 10;
        final earnedXP = baseXP * _comboMultiplier;
        _score++;
        _totalXP += earnedXP;
        
        _celebrationController.forward(from: 0);
      } else {
        AudioService().playWrong();
        _streak = 0;
        _comboMultiplier = 1;
        _shakeController.forward(from: 0);
        
        final currentWord = _questions[_currentQuestionIndex]['word'] as VocabularyItem;
        if (!_mistakes.contains(currentWord)) {
          _mistakes.add(currentWord);
        }
      }
    });

    // Note: SRS updates are now handled centrally by PracticeModesScreen

    Future.delayed(const Duration(seconds: 1, milliseconds: 500), () {
      if (!mounted) return;
      if (_currentQuestionIndex < _questions.length - 1) {
        setState(() {
          _currentQuestionIndex++;
          _answered = false;
          _selectedAnswer = null;
        });
      } else {
        _timer?.cancel();
        setState(() {
          _isQuizComplete = true;
        });
      }
    });
  }

  void _replayMistakes() {
    setState(() {
      _quizVocabulary = List.from(_mistakes);
      _mistakes.clear();
      _questions = _quizVocabulary.map((word) {
        final correctAnswer = word.translation;
        final options = _generateOptions(word);
        
        return {
          'word': word,
          'question': word.word,
          'context': _generateContext(word),
          'options': options,
          'correctIndex': options.indexOf(correctAnswer),
        };
      }).toList();
      _currentQuestionIndex = 0;
      _score = 0;
      _answered = false;
      _selectedAnswer = null;
      _isQuizComplete = false;
      _timeElapsed = Duration.zero;
    });
    _startTimer();
  }

  void _restartQuiz() {
    setState(() {
      _currentQuestionIndex = 0;
      _score = 0;
      _totalXP = 0;
      _streak = 0;
      _maxStreak = 0;
      _comboMultiplier = 1;
      _answered = false;
      _selectedAnswer = null;
      _mistakes.clear();
      _isQuizComplete = false;
      _timeElapsed = Duration.zero;
    });
    _prepareQuiz();
    _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: _isQuizComplete ? _buildResultsScreen() : _buildQuizScreen(),
    );
  }

  Widget _buildQuizScreen() {
    final question = _questions[_currentQuestionIndex];
    final word = question['word'] as VocabularyItem;
    final progress = (_currentQuestionIndex + 1) / _questions.length;

    return SafeArea(
      child: Column(
        children: [
          _buildPremiumAppBar(progress),
          _buildGameStatsBar(),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildWordCard(word, question),
                  const SizedBox(height: 32),
                  _buildOptionsGrid(question),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumAppBar(double progress) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryTeal.withValues(alpha: 0.1),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context, _buildPracticeResult()),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Question ${_currentQuestionIndex + 1}/${_questions.length}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: AppColors.tealGradient,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, color: Colors.white, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '$_totalXP',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryTeal),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameStatsBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: Icons.local_fire_department,
            value: '$_streak',
            label: 'Streak',
            color: AppColors.accentCoral,
            isActive: _streak > 0,
          ),
          if (_comboMultiplier > 1)
            _buildStatItem(
              icon: Icons.flash_on,
              value: 'x$_comboMultiplier',
              label: 'Combo',
              color: AppColors.darkAccentPurple,
              isActive: true,
            ),
          _buildStatItem(
            icon: Icons.timer,
            value: '${_timeElapsed.inMinutes}:${(_timeElapsed.inSeconds % 60).toString().padLeft(2, '0')}',
            label: 'Time',
            color: AppColors.textMedium,
            isActive: false,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required bool isActive,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? color.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isActive ? Border.all(color: color.withValues(alpha: 0.3), width: 2) : null,
      ),
      child: Row(
        children: [
          Icon(icon, color: isActive ? color : AppColors.textMedium, size: 20),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isActive ? color : Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                label,
                style: const TextStyle(fontSize: 10, color: AppColors.textMedium),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWordCard(VocabularyItem word, Map<String, dynamic> question) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryTeal, AppColors.darkTeal],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryTeal.withValues(alpha: 0.4),
            blurRadius: 30,
            offset: const Offset(0, 12),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  word.word,
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.volume_up, color: Colors.white, size: 28),
                onPressed: () {
                  TtsService().speak(word.word, languageCode: widget.targetLanguage, context: context);
                },
              ),
            ],
          ),
          if (word.pronunciationIpa != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                word.pronunciationIpa!,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.9),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
            ),
            child: Column(
              children: [
                const Icon(Icons.format_quote, color: Colors.white54, size: 24),
                const SizedBox(height: 8),
                Text(
                  question['context'],
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.signal_cellular_alt, color: Colors.white.withValues(alpha: 0.7), size: 16),
              const SizedBox(width: 6),
              Text(
                'Level ${word.difficultyLevel}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsGrid(Map<String, dynamic> question) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choose the correct translation:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        ...List.generate((question['options'] as List).length, (index) {
          final option = (question['options'] as List)[index];
          final isCorrect = index == question['correctIndex'];
          final isSelected = _selectedAnswer == index;
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildOptionButton(
              option: option,
              index: index,
              isCorrect: isCorrect,
              isSelected: isSelected,
              onTap: () => _selectAnswer(index),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildOptionButton({
    required String option,
    required int index,
    required bool isCorrect,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    Color backgroundColor = Theme.of(context).cardTheme.color ?? Colors.white;
    Color borderColor = Theme.of(context).colorScheme.outline.withValues(alpha: 0.1);
    Color textColor = Theme.of(context).colorScheme.onSurface;
    IconData? trailingIcon;
    Color? trailingColor;

    if (_answered) {
      if (isCorrect) {
        backgroundColor = AppColors.success;
        borderColor = AppColors.success;
        textColor = AppColors.success;
        trailingIcon = Icons.check_circle;
        trailingColor = AppColors.success;
      } else if (isSelected) {
        backgroundColor = AppColors.error;
        borderColor = AppColors.error;
        textColor = AppColors.error;
        trailingIcon = Icons.cancel;
        trailingColor = AppColors.error;
      }
    } else if (isSelected) {
      backgroundColor = AppColors.primaryTeal.withValues(alpha: 0.1);
      borderColor = AppColors.primaryTeal;
      textColor = AppColors.primaryTeal;
    }

    return GestureDetector(
      onTap: _answered ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 2),
          boxShadow: [
            if (!_answered)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected
                    ? (_answered ? (isCorrect ? AppColors.success : AppColors.error) : AppColors.primaryTeal)
                    : AppColors.primaryTeal.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  String.fromCharCode(65 + index),
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.primaryTeal,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                option,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor),
              ),
            ),
            if (trailingIcon != null)
              Icon(trailingIcon, color: trailingColor, size: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsScreen() {
    return PracticeResultsScreen(
      correctCount: _score,
      totalCount: _questions.length,
      xpEarned: _totalXP,
      timeElapsed: _timeElapsed,
      bestStreak: _maxStreak,
      hasMistakes: _mistakes.isNotEmpty,
      onReplayMistakes: _replayMistakes,
      onContinueToNext: () => Navigator.pop(context, _buildPracticeResult()),
      onBackToHome: () => Navigator.of(context).popUntil((route) => route.isFirst),
    );
  }

  Map<String, dynamic> _buildPracticeResult() {
    final accuracy = _questions.isEmpty ? 0.0 : (_score / _questions.length).clamp(0.0, 1.0);
    
    // Build word-level performance map
    final Map<String, bool> wordPerformance = {};
    for (final question in _questions) {
      final wordId = (question['word'] as VocabularyItem).id;
      // If the word isn't in mistakes, they got it right.
      wordPerformance[wordId] = !_mistakes.any((m) => m.id == wordId);
    }
    
    return {
      'correct': _score,
      'total': _questions.length,
      'accuracy': accuracy,
      'avgResponseSeconds': 0.0,
      'wordPerformance': wordPerformance,
    };
  }
}

