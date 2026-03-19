import 'package:flutter/material.dart';
import '../../models/sentence_item.dart';
import '../../services/tts_service.dart';
import 'dart:async';
import '../../services/audio_service.dart';
import '../../widgets/practice_results_screen.dart';
import '../../theme/app_theme.dart';

/// Listening Dictation Mode
/// Listen and type what you hear
class ListeningDictationScreen extends StatefulWidget {
  final List<SentenceItem> sentences;
  final String targetLanguage;
  final String nativeLanguage;

  const ListeningDictationScreen({
    super.key,
    required this.sentences,
    required this.targetLanguage,
    required this.nativeLanguage,
  });

  @override
  State<ListeningDictationScreen> createState() => _ListeningDictationScreenState();
}

class _ListeningDictationScreenState extends State<ListeningDictationScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isPlaying = false;
  bool _showAnswer = false;
  bool _isCorrect = false;
  int _score = 0;
  int _currentIndex = 0;
  int _attempts = 0;
  double _playbackSpeed = 1.0;
  int _totalXP = 0;
  int _streak = 0;
  int _maxStreak = 0;
  bool _isComplete = false;
  Duration _timeElapsed = Duration.zero;
  Timer? _timer;
  final List<SentenceItem> _mistakes = [];
  List<SentenceItem> _quizSentences = [];

  @override
  void initState() {
    super.initState();
    _quizSentences = List.from(widget.sentences);
    if (_quizSentences.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
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
    _controller.dispose();
    super.dispose();
  }

  void _togglePlay() async {
    if (_quizSentences.isEmpty) return;
    
    setState(() => _isPlaying = true);
    
    final currentSentence = _quizSentences[_currentIndex];
    await TtsService().speak(
      currentSentence.text,
      languageCode: widget.targetLanguage,
      rate: _playbackSpeed,
      context: context,
    );
    
    if (mounted) {
      setState(() => _isPlaying = false);
    }
  }

  void _checkAnswer() {
    final userAnswer = _controller.text.trim().toLowerCase();
    final correctAnswer = _quizSentences[_currentIndex].text.toLowerCase();
    
    setState(() {
      _isCorrect = userAnswer == correctAnswer;
      _showAnswer = true;
      _attempts++;
      
      if (_isCorrect) {
        int points = 100 - (_attempts - 1) * 20;
        if (points < 20) points = 20;
        _score += 1;
        _totalXP += points;
        AudioService().playCorrect();
        
        if (_attempts == 1) {
          _streak++;
          if (_streak > _maxStreak) _maxStreak = _streak;
        } else {
          _streak = 0;
        }
      } else {
        _streak = 0;
        final currentSentence = _quizSentences[_currentIndex];
        if (!_mistakes.contains(currentSentence)) {
          _mistakes.add(currentSentence);
          AudioService().playWrong();
        }
      }
    });
  }

  void _nextQuestion() {
    if (_currentIndex < _quizSentences.length - 1) {
      setState(() {
        _controller.clear();
        _showAnswer = false;
        _attempts = 0;
        _currentIndex++;
      });
    } else {
      _timer?.cancel();
      setState(() {
        _isComplete = true;
      });
    }
  }

  void _replayMistakes() {
    setState(() {
      _quizSentences = List.from(_mistakes);
      _mistakes.clear();
      _currentIndex = 0;
      _score = 0;
      _totalXP = 0;
      _streak = 0;
      _maxStreak = 0;
      _attempts = 0;
      _isComplete = false;
      _timeElapsed = Duration.zero;
      _controller.clear();
      _showAnswer = false;
    });
    _startTimer();
  }

  void _restartQuiz() {
    setState(() {
      _quizSentences = List.from(widget.sentences);
      _mistakes.clear();
      _currentIndex = 0;
      _score = 0;
      _totalXP = 0;
      _streak = 0;
      _maxStreak = 0;
      _attempts = 0;
      _isComplete = false;
      _timeElapsed = Duration.zero;
      _controller.clear();
      _showAnswer = false;
    });
    _startTimer();
  }

  Map<String, dynamic> _buildPracticeResult() {
    final length = _quizSentences.length;
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
    if (_quizSentences.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Listening Dictation')),
        body: const Center(child: Text('No sentence data available')),
      );
    }

    if (_isComplete) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: PracticeResultsScreen(
          correctCount: _score,
          totalCount: _quizSentences.length,
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

    final currentDictation = _quizSentences[_currentIndex];
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Listening Dictation'),
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
              // Progress
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: (_currentIndex + 1) / _quizSentences.length,
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryPurple),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Question ${_currentIndex + 1} of ${_quizSentences.length}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  fontSize: 14,
                ),
              ),
              
              const Spacer(),
              
              // Audio player area
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(40),
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
                    // Play button
                    GestureDetector(
                      onTap: _togglePlay,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 3,
                          ),
                        ),
                        child: Icon(
                          _isPlaying ? Icons.stop : Icons.play_arrow,
                          color: Colors.white,
                          size: 50,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _isPlaying ? 'Playing...' : 'Tap to listen',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                    
                    // Audio wave visualization
                    if (_isPlaying)
                      Container(
                        margin: const EdgeInsets.only(top: 24),
                        height: 40,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(20, (index) {
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              width: 4,
                              height: 10 + (index % 5) * 6.0,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            );
                          }),
                        ),
                      ),
                    
                    // Speed toggle
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildSpeedButton('0.5x', _playbackSpeed == 0.5, 0.5),
                        const SizedBox(width: 12),
                        _buildSpeedButton('1.0x', _playbackSpeed == 1.0, 1.0),
                        const SizedBox(width: 12),
                        _buildSpeedButton('0.75x', _playbackSpeed == 0.75, 0.75),
                      ],
                    ),
                  ],
                ),
              ),
              
              const Spacer(),
              
              // Input area
              if (!_showAnswer)
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                  child: TextField(
                    controller: _controller,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 20,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Type what you hear...',
                      hintStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(20),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.clear, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
                        onPressed: () => _controller.clear(),
                      ),
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _isCorrect 
                        ? AppColors.success.withValues(alpha: 0.2) 
                        : AppColors.error.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _isCorrect ? AppColors.success : AppColors.error,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            _isCorrect ? Icons.check_circle : Icons.error,
                            color: _isCorrect ? AppColors.success : AppColors.error,
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isCorrect ? 'Correct!' : 'Not quite...',
                                  style: TextStyle(
                                    color: _isCorrect ? AppColors.success : AppColors.error,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (!_isCorrect)
                                  Text(
                                    currentDictation.text,
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurface,
                                      fontSize: 18,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Translation: ${currentDictation.translation}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              
              const SizedBox(height: 24),
              
              // Action button
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton.icon(
                  onPressed: _showAnswer ? _nextQuestion : _checkAnswer,
                  icon: Icon(_showAnswer ? Icons.arrow_forward : Icons.check),
                  label: Text(
                    _showAnswer ? 'NEXT' : 'CHECK',
                    style: const TextStyle(
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
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpeedButton(String label, bool isActive, double speed) {
    return GestureDetector(
      onTap: () => setState(() => _playbackSpeed = speed),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.white.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
