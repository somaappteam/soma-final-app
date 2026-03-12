import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../services/tts_service.dart';

class ClozeQuestion {
  final Map<String, dynamic> sentenceData;
  final String fullSentence;
  final String sentenceWithBlank;
  final List<String> options;
  final String correctAnswer;
  
  ClozeQuestion({
    required this.sentenceData,
    required this.fullSentence,
    required this.sentenceWithBlank,
    required this.options,
    required this.correctAnswer,
  });
}

class FillInBlankScreen extends StatefulWidget {
  final List<Map<String, dynamic>> sentences;
  final String targetLanguage;
  final String nativeLanguage;

  const FillInBlankScreen({
    super.key,
    required this.sentences,
    required this.targetLanguage,
    required this.nativeLanguage,
  });

  @override
  State<FillInBlankScreen> createState() => _FillInBlankScreenState();
}

class _FillInBlankScreenState extends State<FillInBlankScreen>
    with TickerProviderStateMixin {
  late List<ClozeQuestion> _questions;
  int _currentQuestionIndex = 0;
  int _score = 0;
  int _totalXP = 0;
  int _streak = 0;
  int _maxStreak = 0;
  String? _selectedAnswer;
  bool _answered = false;
  bool _isCorrect = false;
  bool _isComplete = false;
  bool _showHint = false;

  Map<String, dynamic> _buildPracticeResult() {
    final accuracy = (_questions.isNotEmpty ? _score / _questions.length : 0).clamp(0.0, 1.0);
    return {
      'correct': _score,
      'total': _questions.length,
      'accuracy': accuracy,
      'avgResponseSeconds': 0.0,
    };
  }
  int _hintsUsed = 0;
  Duration _timeElapsed = Duration.zero;
  Timer? _timer;
  
  late AnimationController _shakeController;
  late AnimationController _celebrationController;

  @override
  void initState() {
    super.initState();
    _prepareQuiz();
    _startTimer();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 600),
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

  void _prepareQuiz() {
    final shuffledSentences = List<Map<String, dynamic>>.from(widget.sentences)..shuffle();
    final quizSentences = shuffledSentences.length > 15 
        ? shuffledSentences.sublist(0, 15) 
        : shuffledSentences;

    _questions = quizSentences.map((sentence) => _createClozeQuestion(sentence)).toList();
  }

  ClozeQuestion _createClozeQuestion(Map<String, dynamic> sentence) {
    return ClozeQuestion(
      sentenceData: sentence,
      fullSentence: sentence['full_sentence'] as String? ?? '',
      sentenceWithBlank: sentence['sentence'] as String? ?? '',
      options: List<String>.from(sentence['options'] as List? ?? []),
      correctAnswer: sentence['blank'] as String? ?? '',
    );
  }



  void _onOptionSelected(String option) {
    if (_answered) return;
    
    HapticFeedback.mediumImpact();
    
    final currentQuestion = _questions[_currentQuestionIndex];
    final isCorrect = option.toLowerCase() == currentQuestion.correctAnswer.toLowerCase();

    setState(() {
      _answered = true;
      _isCorrect = isCorrect;
      _selectedAnswer = option;
      
      if (isCorrect) {
        _streak++;
        if (_streak > _maxStreak) _maxStreak = _streak;
        
        const baseXP = 15;
        final streakBonus = _streak > 2 ? (_streak - 2) * 2 : 0;
        final hintPenalty = _showHint ? 3 : 0;
        final earnedXP = baseXP + streakBonus - hintPenalty;
        
        _score++;
        _totalXP += earnedXP > 0 ? earnedXP : 1;
        
        _celebrationController.forward(from: 0);
        // Auto-play the full sentence when correct
        TtsService().speak(
          currentQuestion.fullSentence,
          languageCode: widget.targetLanguage,
          context: context,
        );
      } else {
        _streak = 0;
        _shakeController.forward(from: 0);
      }
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (_currentQuestionIndex < _questions.length - 1) {
        setState(() {
          _currentQuestionIndex++;
          _answered = false;
          _isCorrect = false;
          _selectedAnswer = null;
          _showHint = false;
        });
      } else {
        _timer?.cancel();
        setState(() {
          _isComplete = true;
        });
      }
    });
  }

  void _showHintDialog() {
    setState(() {
      _showHint = true;
      _hintsUsed++;
    });
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Icon(Icons.lightbulb, color: Colors.amber, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Hint',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _questions[_currentQuestionIndex].sentenceData['hint']?.toString().isNotEmpty == true
                  ? _questions[_currentQuestionIndex].sentenceData['hint'].toString()
                  : 'The missing word has ${_questions[_currentQuestionIndex].correctAnswer.length} letters',
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            if (_questions[_currentQuestionIndex].sentenceData['hint']?.toString().isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Text(
                'The missing word has ${_questions[_currentQuestionIndex].correctAnswer.length} letters',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textMedium,
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, _buildPracticeResult()),
                child: const Text('Got it!'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _restartQuiz() {
    setState(() {
      _currentQuestionIndex = 0;
      _score = 0;
      _totalXP = 0;
      _streak = 0;
      _maxStreak = 0;
      _selectedAnswer = null;
      _answered = false;
      _isCorrect = false;
      _isComplete = false;
      _showHint = false;
      _hintsUsed = 0;
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
      body: _isComplete ? _buildResultsScreen() : _buildQuizScreen(),
    );
  }

  Widget _buildQuizScreen() {
    final question = _questions[_currentQuestionIndex];
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
                  _buildSentenceCard(question),
                  const SizedBox(height: 40),
                  _buildOptionsGrid(question),
                  const SizedBox(height: 24),
                  _buildFeedbackCard(question),
                  const SizedBox(height: 24),
                  _buildHintButton(),
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
      child: Column(
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
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
                        const Text(
                          'Fill in the Blank',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
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
                        backgroundColor: Colors.grey.shade200,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryTeal),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
        color: Colors.white,
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
            color: Colors.orange,
            isActive: _streak > 0,
          ),
          _buildStatItem(
            icon: Icons.timer,
            value: '${_timeElapsed.inMinutes}:${(_timeElapsed.inSeconds % 60).toString().padLeft(2, '0')}',
            label: 'Time',
            color: AppColors.textMedium,
            isActive: false,
          ),
          _buildStatItem(
            icon: Icons.lightbulb_outline,
            value: '$_hintsUsed',
            label: 'Hints',
            color: Colors.amber,
            isActive: _hintsUsed > 0,
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
                  color: isActive ? color : AppColors.textDark,
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

  Widget _buildSentenceCard(ClozeQuestion question) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryTeal,
            AppColors.darkTeal,
          ],
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
          const Icon(
            Icons.format_quote,
            color: Colors.white54,
            size: 32,
          ),
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: _shakeController,
            builder: (context, child) {
              final shakeOffset = _answered && !_isCorrect
                  ? sin(_shakeController.value * pi * 4) * 4
                  : 0.0;
              
              return Transform.translate(
                offset: Offset(shakeOffset, 0),
                child: child,
              );
            },
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 22,
                  color: Colors.white,
                  height: 1.6,
                ),
                children: _buildSentenceSpans(question),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.translate, color: AppColors.textMedium, size: 18),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    question.sentenceData['translation']?.toString() ?? '',
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          if (_showHint) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lightbulb, color: Colors.amber, size: 20),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      question.sentenceData['hint']?.toString().isNotEmpty == true
                          ? question.sentenceData['hint'].toString()
                          : 'The missing word has ${question.correctAnswer.length} letters',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0);
  }

  List<InlineSpan> _buildSentenceSpans(ClozeQuestion question) {
    final parts = question.sentenceWithBlank.split('___');
    final spans = <InlineSpan>[];
    
    for (int i = 0; i < parts.length; i++) {
      spans.add(TextSpan(text: parts[i]));
      
      if (i < parts.length - 1) {
        if (_answered) {
          spans.add(
            TextSpan(
              text: question.correctAnswer,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
                decorationThickness: 3,
                decorationColor: _isCorrect ? Colors.green.shade300 : Colors.red.shade300,
                color: _isCorrect ? Colors.green.shade300 : Colors.red.shade300,
              ),
            ),
          );
        } else {
          spans.add(
            WidgetSpan(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: const Text(
                  '___',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
            ),
          );
        }
      }
    }
    
    return spans;
  }

  Widget _buildOptionsGrid(ClozeQuestion question) {
    return Column(
      children: [
        const Text(
          'Select the missing word:',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 20),
        ...question.options.map((option) => _buildOptionButton(option, question)),
      ],
    );
  }

  Widget _buildOptionButton(String option, ClozeQuestion question) {
    Color backgroundColor = Colors.white;
    Color borderColor = AppColors.primaryTeal.withValues(alpha: 0.3);
    Color textColor = AppColors.textDark;
    
    if (_answered) {
      if (option.toLowerCase() == question.correctAnswer.toLowerCase()) {
        backgroundColor = Colors.green.shade50;
        borderColor = Colors.green;
        textColor = Colors.green.shade700;
      } else if (option == _selectedAnswer) {
        backgroundColor = Colors.red.shade50;
        borderColor = Colors.red;
        textColor = Colors.red.shade700;
      } else {
        backgroundColor = Colors.grey.shade100;
        borderColor = Colors.grey.shade300;
        textColor = AppColors.textMedium;
      }
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      child: ElevatedButton(
        onPressed: _answered ? null : () => _onOptionSelected(option),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          elevation: _answered ? 0 : 4,
          shadowColor: _answered ? Colors.transparent : AppColors.primaryTeal.withValues(alpha: 0.2),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: borderColor, width: 2),
          ),
        ),
        child: Row(
          children: [
            if (_answered && option.toLowerCase() == question.correctAnswer.toLowerCase())
              Icon(Icons.check_circle, color: Colors.green.shade600, size: 24)
            else if (_answered && option == _selectedAnswer && !_isCorrect)
              Icon(Icons.cancel, color: Colors.red.shade600, size: 24)
            else
              Icon(Icons.radio_button_unchecked, color: borderColor, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                option,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackCard(ClozeQuestion question) {
    if (!_answered) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _celebrationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _isCorrect 
              ? 1.0 + (_celebrationController.value * 0.1 * sin(_celebrationController.value * pi * 4))
              : 1.0,
          child: child,
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _isCorrect ? Colors.green.shade50 : Colors.red.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isCorrect ? Colors.green.shade200 : Colors.red.shade200,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              _isCorrect ? Icons.check_circle : Icons.error,
              color: _isCorrect ? Colors.green.shade600 : Colors.red.shade600,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isCorrect ? 'Correct!' : 'Incorrect',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _isCorrect ? Colors.green.shade700 : Colors.red.shade700,
                    ),
                  ),
                  if (!_isCorrect)
                    Text(
                      'The correct answer is: ${question.correctAnswer}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.red.shade600,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildHintButton() {
    if (_answered) return const SizedBox.shrink();
    
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton.icon(
        onPressed: _showHintDialog,
        icon: const Icon(Icons.lightbulb_outline),
        label: const Text(
          'Need a hint?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.amber.shade700,
          side: BorderSide(color: Colors.amber.shade300, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildResultsScreen() {
    final accuracy = (_score / _questions.length * 100).round();
    final isPerfect = _score == _questions.length;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isPerfect
              ? [Colors.amber.shade100, Colors.white]
              : [AppColors.primaryTeal.withValues(alpha: 0.1), Colors.white],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              _buildAchievementBadge(isPerfect),
              const SizedBox(height: 32),
              _buildResultsStats(),
              const SizedBox(height: 40),
              _buildActionButtonsResults(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAchievementBadge(bool isPerfect) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    isPerfect
                        ? Colors.amber.withValues(alpha: 0.3)
                        : AppColors.primaryTeal.withValues(alpha: 0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                gradient: isPerfect
                    ? const LinearGradient(
                        colors: [Colors.amber, Colors.orange],
                      )
                    : const LinearGradient(
                        colors: [AppColors.primaryTeal, AppColors.darkTeal],
                      ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (isPerfect ? Colors.amber : AppColors.primaryTeal)
                        .withValues(alpha: 0.4),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(
                isPerfect ? Icons.emoji_events : Icons.edit_note,
                color: Colors.white,
                size: 70,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          isPerfect ? 'Perfect Score!' : 'Quiz Complete!',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: isPerfect ? Colors.amber.shade700 : AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isPerfect
              ? 'You completed all sentences flawlessly!'
              : 'Great effort! Keep practicing to improve.',
          style: const TextStyle(
            fontSize: 16,
            color: AppColors.textMedium,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildResultsStats() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildResultStatCard(
                  icon: Icons.check_circle,
                  value: '$_score/${_questions.length}',
                  label: 'Correct',
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildResultStatCard(
                  icon: Icons.star,
                  value: '$_totalXP',
                  label: 'XP Earned',
                  color: Colors.amber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildResultStatCard(
                  icon: Icons.local_fire_department,
                  value: '$_maxStreak',
                  label: 'Best Streak',
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildResultStatCard(
                  icon: Icons.lightbulb,
                  value: '$_hintsUsed',
                  label: 'Hints Used',
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Accuracy',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${(_score / _questions.length * 100).round()}%',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryTeal,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: _score / _questions.length,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _score == _questions.length
                        ? Colors.amber
                        : AppColors.primaryTeal,
                  ),
                  minHeight: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtonsResults() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _restartQuiz,
            icon: const Icon(Icons.replay),
            label: const Text(
              'Play Again',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryTeal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 8,
              shadowColor: AppColors.primaryTeal.withValues(alpha: 0.4),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context, _buildPracticeResult()),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textMedium,
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Back to Practice',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
