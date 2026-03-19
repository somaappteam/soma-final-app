import 'package:flutter/material.dart';
import '../../models/vocabulary_item.dart';
import '../../services/tts_service.dart';
import '../../services/audio_service.dart';
import 'dart:async';
import '../../widgets/practice_results_screen.dart';
import '../../theme/app_theme.dart';

/// Spelling Bee Mode
/// Practice spelling words correctly
class SpellingBeeScreen extends StatefulWidget {
  final List<VocabularyItem> vocabulary;
  final String targetLanguage;
  final String nativeLanguage;

  const SpellingBeeScreen({
    super.key,
    required this.vocabulary,
    required this.targetLanguage,
    required this.nativeLanguage,
  });

  @override
  State<SpellingBeeScreen> createState() => _SpellingBeeScreenState();
}

class _SpellingBeeScreenState extends State<SpellingBeeScreen> {
  final TextEditingController _controller = TextEditingController();
  int _score = 0;
  int _currentIndex = 0;
  int _streak = 0;
  bool _showResult = false;
  bool _isCorrect = false;
  String _feedback = '';
  int _totalXP = 0;
  int _maxStreak = 0;
  bool _isComplete = false;
  Duration _timeElapsed = Duration.zero;
  Timer? _timer;
  final List<VocabularyItem> _mistakes = [];
  List<VocabularyItem> _quizVocabulary = [];
  
  @override
  void initState() {
    super.initState();
    _quizVocabulary = List.from(widget.vocabulary);
    if (_quizVocabulary.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _playWord();
        _startTimer();
      });
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && !_isComplete) {
        setState(() {
          _timeElapsed = Duration(seconds: _timeElapsed.inSeconds + 1);
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    TtsService().stop();
    _controller.dispose();
    super.dispose();
  }

  void _playWord() async {
    if (_quizVocabulary.isEmpty) return;
    final currentWord = _quizVocabulary[_currentIndex];
    await TtsService().speak(
      currentWord.word,
      languageCode: widget.targetLanguage,
      context: context,
    );
  }  

  void _checkSpelling() {
    final userAnswer = _controller.text.trim().toLowerCase();
    final correctAnswer = _quizVocabulary[_currentIndex].word.toLowerCase();
    
    setState(() {
      _isCorrect = userAnswer == correctAnswer;
      _showResult = true;
      
      if (_isCorrect) {
        final earnedXP = 10 + (_streak * 2);
        _score += 1;
        _totalXP += earnedXP;
        _streak++;
        if (_streak > _maxStreak) _maxStreak = _streak;
        _feedback = 'Excellent!';
        AudioService().playCorrect();
      } else {
        _streak = 0;
        final currentWord = _quizVocabulary[_currentIndex];
        if (!_mistakes.contains(currentWord)) {
          _mistakes.add(currentWord);
        }
        _feedback = 'The correct spelling is: ${_quizVocabulary[_currentIndex].word}';
        AudioService().playWrong();
      }
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        if (_currentIndex < _quizVocabulary.length - 1) {
          setState(() {
            _controller.clear();
            _showResult = false;
            _currentIndex++;
          });
          _playWord();
        } else {
          _timer?.cancel();
          setState(() {
             _isComplete = true;
          });
        }
      }
    });
  }

  void _replayMistakes() {
    setState(() {
      _quizVocabulary = List.from(_mistakes);
      _mistakes.clear();
      _currentIndex = 0;
      _score = 0;
      _totalXP = 0;
      _streak = 0;
      _maxStreak = 0;
      _isComplete = false;
      _timeElapsed = Duration.zero;
      _controller.clear();
      _showResult = false;
    });
    _playWord();
    _startTimer();
  }

  void _restartQuiz() {
    setState(() {
      _quizVocabulary = List.from(widget.vocabulary);
      _mistakes.clear();
      _currentIndex = 0;
      _score = 0;
      _totalXP = 0;
      _streak = 0;
      _maxStreak = 0;
      _isComplete = false;
      _timeElapsed = Duration.zero;
      _controller.clear();
      _showResult = false;
    });
    _playWord();
    _startTimer();
  }

  Map<String, dynamic> _buildPracticeResult() {
    final length = _quizVocabulary.length;
    final accuracy = (length > 0 ? _score / length : 0.0).clamp(0.0, 1.0);
    return {
      'correct': _score,
      'total': length,
      'accuracy': accuracy,
      'avgResponseSeconds': 0.0,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_quizVocabulary.isEmpty) {
      return Scaffold(
         appBar: AppBar(title: const Text('Spelling Bee')),
         body: const Center(child: Text('No vocabulary data available')),
      );
    }

    if (_isComplete) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: PracticeResultsScreen(
          correctCount: _score,
          totalCount: _quizVocabulary.length,
          xpEarned: _totalXP,
          timeElapsed: _timeElapsed,
          bestStreak: _maxStreak,
          hasMistakes: _mistakes.isNotEmpty,
          onReplayMistakes: _replayMistakes,
          onContinueToNext: () => Navigator.pop(context, _buildPracticeResult()),
          onBackToHome: () => Navigator.of(context).popUntil((route) => route.isFirst),
        ),
      );
    }

    final currentWord = _quizVocabulary[_currentIndex];
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Spelling Bee'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                'Score: $_score',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Streak indicator
              if (_streak > 0)
                Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.accentCoral, AppColors.error],
                    ),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentCoral.withValues(alpha: 0.4),
                        blurRadius: 15,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_fire_department, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        '$_streak streak!',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),

              // Word card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryPurple, AppColors.secondaryPurple],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryPurple.withValues(alpha: 0.4),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Hint
                    Text(
                      'Hint: ${currentWord.translation}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Pronunciation
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.record_voice_over,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            currentWord.pronunciationIpa ?? currentWord.word,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.volume_up, color: Colors.indigo),
                            onPressed: _playWord,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Difficulty stars
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        currentWord.difficultyLevel,
                        (index) => const Icon(
                          Icons.star,
                          color: AppColors.accentOrange,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Input field
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _showResult
                        ? (_isCorrect ? AppColors.success : AppColors.error)
                        : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                    width: 2,
                  ),
                ),
                child: TextField(
                  controller: _controller,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: 'Type the word...',
                    hintStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(20),
                  ),
                  onSubmitted: (_) => _checkSpelling(),
                ),
              ),

              const SizedBox(height: 16),

              // Feedback
              if (_showResult)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _isCorrect
                        ? AppColors.success.withValues(alpha: 0.2)
                        : AppColors.error.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isCorrect ? AppColors.success : AppColors.error,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isCorrect ? Icons.check_circle : Icons.error,
                        color: _isCorrect ? AppColors.success : AppColors.error,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _feedback,
                          style: TextStyle(
                            color: _isCorrect ? AppColors.success : AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              // Submit button
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton.icon(
                  onPressed: _showResult ? null : _checkSpelling,
                  icon: const Icon(Icons.check),
                  label: const Text(
                    'CHECK SPELLING',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    disabledBackgroundColor: AppColors.neutralDark,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
