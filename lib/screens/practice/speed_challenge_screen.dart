import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/vocabulary_item.dart';
import '../../theme/app_theme.dart';

/// Premium Speed Challenge - Racing-style Quiz
/// Fast-paced vocabulary challenge with racing theme
class SpeedChallengeScreen extends StatefulWidget {
  final List<VocabularyItem> vocabulary;
  final String targetLanguage;
  final String nativeLanguage;

  const SpeedChallengeScreen({
    super.key,
    required this.vocabulary,
    required this.targetLanguage,
    required this.nativeLanguage,
  });

  @override
  State<SpeedChallengeScreen> createState() => _SpeedChallengeScreenState();
}

class _SpeedChallengeScreenState extends State<SpeedChallengeScreen>
    with TickerProviderStateMixin {
  // Game Data
  late List<VocabularyItem> _quizVocabulary;
  late List<Map<String, dynamic>> _questions;
  
  // Game State
  int _currentQuestionIndex = 0;
  int _score = 0;
  int _totalXP = 0;
  int _correctAnswers = 0;
  int _wrongAnswers = 0;
  int _streak = 0;
  int _maxStreak = 0;
  int _comboMultiplier = 1;
  int _questionsAnswered = 0;
  bool _answered = false;
  int? _selectedAnswer;
  bool _isComplete = false;
  bool _isPaused = false;
  
  // Timer
  double _timeLeft = 60.0;
  Timer? _timer;
  Timer? _countdownTimer;
  bool _showCountdown = true;
  int _countdownValue = 3;
  
  // Speed tracking
  DateTime? _questionStartTime;
  double _avgResponseTime = 0;
  int _fastAnswers = 0; // Under 2 seconds
  
  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _shakeController;
  late AnimationController _countdownController;

  @override
  void initState() {
    super.initState();
    _prepareQuiz();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..repeat(reverse: true);
    
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _countdownController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _startCountdown();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _shakeController.dispose();
    _countdownController.dispose();
    _timer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    setState(() {
      _countdownValue = 3;
      _showCountdown = true;
    });
    
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _countdownValue--;
      });
      
      _countdownController.forward(from: 0);
      
      if (_countdownValue <= 0) {
        timer.cancel();
        setState(() {
          _showCountdown = false;
        });
        _startGame();
      }
    });
  }

  void _prepareQuiz() {
    _quizVocabulary = List.from(widget.vocabulary)..shuffle();
    if (_quizVocabulary.length > 30) {
      _quizVocabulary = _quizVocabulary.sublist(0, 30);
    }

    _questions = _quizVocabulary.map((word) {
      final correctAnswer = word.translation;
      final options = _generateOptions(word);
      
      return {
        'word': word,
        'question': word.word,
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

  void _startGame() {
    setState(() {
      _timeLeft = 60;
      _questionStartTime = DateTime.now();
    });
    
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!_isPaused && _timeLeft > 0) {
        setState(() {
          _timeLeft = (_timeLeft - 0.1).clamp(0, 60);
        });
        
        if (_timeLeft <= 0) {
          timer.cancel();
          _endGame();
        }
      }
    });
  }

  void _selectAnswer(int index) {
    if (_answered || _isComplete || _isPaused) return;

    HapticFeedback.mediumImpact();
    
    final currentQuestion = _questions[_currentQuestionIndex];
    final isCorrect = index == currentQuestion['correctIndex'];
    
    // Calculate response time
    final now = DateTime.now();
    final responseTime = _questionStartTime != null
        ? (now.difference(_questionStartTime!).inMilliseconds / 1000).toDouble()
        : 0.0;
    
    // Update average response time
    if (_questionsAnswered == 0) {
      _avgResponseTime = responseTime;
    } else {
      _avgResponseTime = (_avgResponseTime * _questionsAnswered + responseTime) / (_questionsAnswered + 1);
    }
    
    if (responseTime < 2.0) {
      _fastAnswers++;
    }

    setState(() {
      _answered = true;
      _selectedAnswer = index;
      _questionsAnswered++;
      
      if (isCorrect) {
        _correctAnswers++;
        _streak++;
        if (_streak > _maxStreak) _maxStreak = _streak;
        
        // Speed bonus
        final speedBonus = responseTime < 2.0 ? 10 : responseTime < 4.0 ? 5 : 0;
        
        // Combo multiplier
        _comboMultiplier = 1 + (_streak ~/ 3);
        final baseXP = 10 + speedBonus;
        final earnedXP = baseXP * _comboMultiplier;
        
        _score += baseXP + speedBonus;
        _totalXP += earnedXP;
      } else {
        _wrongAnswers++;
        _streak = 0;
        _comboMultiplier = 1;
        _shakeController.forward(from: 0);
      }
    });

    Future.delayed(const Duration(milliseconds: 400), () {
      if (_currentQuestionIndex < _questions.length - 1 && _timeLeft > 0) {
        setState(() {
          _currentQuestionIndex++;
          _answered = false;
          _selectedAnswer = null;
          _questionStartTime = DateTime.now();
        });
      } else {
        _endGame();
      }
    });
  }

  void _endGame() {
    _timer?.cancel();
    setState(() {
      _isComplete = true;
    });
  }

  void _restartGame() {
    _timer?.cancel();
    setState(() {
      _currentQuestionIndex = 0;
      _score = 0;
      _totalXP = 0;
      _correctAnswers = 0;
      _wrongAnswers = 0;
      _streak = 0;
      _maxStreak = 0;
      _comboMultiplier = 1;
      _questionsAnswered = 0;
      _avgResponseTime = 0;
      _fastAnswers = 0;
      _answered = false;
      _selectedAnswer = null;
      _isComplete = false;
      _isPaused = false;
      _showCountdown = true;
      _countdownValue = 3;
    });
    _prepareQuiz();
    _startCountdown();
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (_showCountdown) {
      return _buildCountdownScreen();
    }
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: _isComplete ? _buildResultsScreen() : _buildGameScreen(),
    );
  }

  Widget _buildCountdownScreen() {
    return Container(
      color: Colors.black.withValues(alpha: 0.9),
      child: Center(
        child: AnimatedBuilder(
          animation: _countdownController,
          builder: (context, child) {
            final scale = 1 + (_countdownController.value * 0.3);
            
            return Transform.scale(
              scale: scale,
              child: Text(
                _countdownValue > 0 ? '$_countdownValue' : 'GO!',
                style: TextStyle(
                  fontSize: _countdownValue > 0 ? 120 : 80,
                  fontWeight: FontWeight.bold,
                  color: _countdownValue > 0
                      ? (_countdownValue == 3 ? Colors.red : _countdownValue == 2 ? Colors.orange : Colors.green)
                      : const Color(0xFF00FF00),
                  shadows: [
                    Shadow(
                      color: (_countdownValue > 0
                              ? (_countdownValue == 3 ? Colors.red : _countdownValue == 2 ? Colors.orange : Colors.green)
                              : const Color(0xFF00FF00))
                          .withValues(alpha: 0.5),
                      blurRadius: 20,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    ).animate().fadeIn(duration: 200.ms);
  }

  Widget _buildGameScreen() {
    final question = _questions[_currentQuestionIndex];

    return SafeArea(
      child: Stack(
        children: [
          Column(
            children: [
              _buildRacingHeader(),
              _buildSpeedometer(),
              _buildStreakBanner(),
              Expanded(
                child: _buildQuestionArea(question),
              ),
              _buildOptionsPanel(question),
            ],
          ),
          if (_isPaused)
            _buildPauseOverlay(),
        ],
      ),
    );
  }

  Widget _buildRacingHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.red.shade700.withValues(alpha: 0.2),
            Colors.orange.withValues(alpha: 0.1),
          ],
        ),
      ),
      child: Row(
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
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.red, Colors.orange],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.timer, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        _timeLeft.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withValues(alpha: 0.3),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '$_totalXP',
                        style: const TextStyle(
                          color: Colors.amber,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _togglePause,
            icon: const Icon(Icons.pause, size: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedometer() {
    final progress = 1 - (_timeLeft / 60);
    final isDanger = _timeLeft <= 10;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDanger ? Colors.red.withValues(alpha: 0.1) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDanger ? Colors.red.withValues(alpha: 0.5) : Colors.transparent,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.speed,
                    color: isDanger ? Colors.red : AppColors.textMedium,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Time Pressure',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDanger ? Colors.red : AppColors.textDark,
                    ),
                  ),
                ],
              ),
              if (_streak > 2)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.orange, Colors.red],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_fire_department, color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '$_streak',
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
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(
                isDanger
                    ? Colors.red
                    : progress > 0.7
                        ? Colors.orange
                        : progress > 0.4
                            ? Colors.yellow
                            : Colors.green,
              ),
              minHeight: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakBanner() {
    if (_streak <= 2) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.orange, Colors.red, Colors.purple],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.4),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.local_fire_department, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            '$_streak STREAK!',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'x$_comboMultiplier XP',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    ).animate().shake(hz: 3);
  }

  Widget _buildQuestionArea(Map<String, dynamic> question) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Text(
              'What does this mean?',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textMedium,
              ),
            ),
          ),
          const SizedBox(height: 24),
          AnimatedBuilder(
            animation: _shakeController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(sin(_shakeController.value * pi * 4) * 5, 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 28),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.red, Colors.orange],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withValues(alpha: 0.4),
                        blurRadius: 25,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Text(
                    question['question'],
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            '$_questionsAnswered/${_questions.length} answered',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsPanel(Map<String, dynamic> question) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 30,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.2,
              physics: const NeverScrollableScrollPhysics(),
              children: (question['options'] as List).asMap().entries.map((entry) {
                final index = entry.key;
                final option = entry.value;
                final isCorrect = index == question['correctIndex'];
                final isSelected = _selectedAnswer == index;
                
                Color bgColor = Colors.grey.shade50;
                Color borderColor = Colors.grey.shade300;
                Color textColor = AppColors.textDark;
                
                if (_answered) {
                  if (isCorrect) {
                    bgColor = Colors.green.shade50;
                    borderColor = Colors.green;
                    textColor = Colors.green.shade700;
                  } else if (isSelected) {
                    bgColor = Colors.red.shade50;
                    borderColor = Colors.red;
                    textColor = Colors.red.shade700;
                  }
                } else if (isSelected) {
                  bgColor = Colors.red.withValues(alpha: 0.1);
                  borderColor = Colors.red;
                  textColor = Colors.red;
                }

                return GestureDetector(
                  onTap: () => _selectAnswer(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: borderColor,
                        width: 2,
                      ),
                      boxShadow: [
                        if (!_answered)
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        option,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPauseOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.85),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.pause,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'PAUSED',
              style: TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _togglePause,
              icon: const Icon(Icons.play_arrow),
              label: const Text('RESUME'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsScreen() {
    final accuracy = _questionsAnswered > 0
        ? (_correctAnswers / _questionsAnswered * 100).round()
        : 0;
    final isSpeedDemon = _fastAnswers >= _correctAnswers ~/ 2 && _correctAnswers > 5;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isSpeedDemon
              ? [Colors.red.shade100, Colors.white]
              : [Colors.orange.shade100, Colors.white],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              _buildResultsBadge(isSpeedDemon, accuracy),
              const SizedBox(height: 32),
              _buildResultsStats(accuracy),
              const SizedBox(height: 40),
              _buildResultsActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultsBadge(bool isSpeedDemon, int accuracy) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Glow effect
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    isSpeedDemon
                        ? Colors.red.withValues(alpha: 0.3)
                        : Colors.orange.withValues(alpha: 0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            
            // Main badge
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                gradient: isSpeedDemon
                    ? const LinearGradient(
                        colors: [Colors.red, Colors.orange],
                      )
                    : const LinearGradient(
                        colors: [Colors.orange, Colors.amber],
                      ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (isSpeedDemon ? Colors.red : Colors.orange)
                        .withValues(alpha: 0.4),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(
                isSpeedDemon ? Icons.speed : Icons.timer,
                color: Colors.white,
                size: 70,
              ),
            )
            .animate()
            .scale(duration: 600.ms, curve: Curves.elasticOut),
          ],
        ),
        
        const SizedBox(height: 24),
        
        Text(
          isSpeedDemon ? 'Speed Demon!' : 'Time\'s Up!',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: isSpeedDemon ? Colors.red.shade700 : AppColors.textDark,
          ),
        )
        .animate()
        .fadeIn(delay: 300.ms)
        .slideY(begin: 0.2, end: 0),
        
        const SizedBox(height: 8),
        
        Text(
          isSpeedDemon
              ? 'Lightning fast reflexes! Amazing!'
              : 'Great effort! Keep pushing your speed!',
          style: const TextStyle(
            fontSize: 16,
            color: AppColors.textMedium,
          ),
          textAlign: TextAlign.center,
        )
        .animate()
        .fadeIn(delay: 400.ms),
      ],
    );
  }

  Widget _buildResultsStats(int accuracy) {
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
                  icon: Icons.star,
                  value: '$_totalXP',
                  label: 'Total XP',
                  color: Colors.amber,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildResultStatCard(
                  icon: Icons.check_circle,
                  value: '$_correctAnswers',
                  label: 'Correct',
                  color: Colors.green,
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
                  icon: Icons.bolt,
                  value: '$_fastAnswers',
                  label: 'Fast (<2s)',
                  color: Colors.red,
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
                    '$accuracy%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: accuracy >= 80 ? Colors.green : AppColors.textDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: accuracy / 100,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    accuracy >= 80 ? Colors.green : Colors.orange,
                  ),
                  minHeight: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    )
    .animate()
    .fadeIn(delay: 500.ms)
    .slideY(begin: 0.1, end: 0);
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


  Map<String, dynamic> _buildPracticeResult() {
    final accuracy = (_questionsAnswered > 0 ? _correctAnswers / _questionsAnswered : 0).clamp(0.0, 1.0);
    return {
      'correct': _correctAnswers,
      'total': _questionsAnswered > 0 ? _questionsAnswered : _questions.length,
      'accuracy': accuracy,
      'avgResponseSeconds': 0.0,
    };
  }

  Widget _buildResultsActions() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _restartGame,
            icon: const Icon(Icons.replay),
            label: const Text(
              'Race Again',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 8,
              shadowColor: Colors.red.withValues(alpha: 0.4),
            ),
          ),
        )
        .animate()
        .fadeIn(delay: 700.ms)
        .slideY(begin: 0.2, end: 0),
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
        )
        .animate()
        .fadeIn(delay: 800.ms),
      ],
    );
  }
}

