import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import '../../models/vocabulary_item.dart';
import '../../theme/app_theme.dart';

/// Speed Review Mode - Fast-paced flashcard sprint
/// Race against the clock to review as many cards as possible
class SpeedReviewScreen extends StatefulWidget {
  final List<VocabularyItem> vocabulary;
  final String targetLanguage;
  final String nativeLanguage;

  const SpeedReviewScreen({
    super.key,
    required this.vocabulary,
    required this.targetLanguage,
    required this.nativeLanguage,
  });

  @override
  State<SpeedReviewScreen> createState() => _SpeedReviewScreenState();
}

class _SpeedReviewScreenState extends State<SpeedReviewScreen> 
    with SingleTickerProviderStateMixin {
  late AnimationController _cardController;
  late Timer _gameTimer;
  late Timer _comboTimer;
  
  int _timeRemaining = 60;
  int _score = 0;
  int _streak = 0;
  int _maxStreak = 0;
  int _cardsReviewed = 0;
  int _correctAnswers = 0;
  bool _isGameActive = false;
  final bool _isPaused = false;
  bool _showAnswer = false;
  
  late List<VocabularyItem> _vocabulary;
  late VocabularyItem _currentCard;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _vocabulary = List.from(widget.vocabulary);
    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    if (_vocabulary.isNotEmpty) {
      _shuffleCards();
      _currentCard = _vocabulary[0];
    }
  }

  @override
  void dispose() {
    _cardController.dispose();
    if (_isGameActive) {
      _gameTimer.cancel();
    }
    super.dispose();
  }

  void _shuffleCards() {
    _vocabulary.shuffle(Random());
  }

  void _startGame() {
    setState(() {
      _isGameActive = true;
      _timeRemaining = 60;
      _score = 0;
      _streak = 0;
      _cardsReviewed = 0;
      _correctAnswers = 0;
      _currentIndex = 0;
      _shuffleCards();
      _currentCard = _vocabulary[0];
    });

    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeRemaining > 0 && !_isPaused) {
        setState(() => _timeRemaining--);
      } else if (_timeRemaining == 0) {
        _endGame();
      }
    });
  }

  void _endGame() {
    _gameTimer.cancel();
    setState(() => _isGameActive = false);
    _showResults();
  }

  void _showResults() {
    final accuracy = _cardsReviewed > 0 
        ? (_correctAnswers / _cardsReviewed * 100).round() 
        : 0;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Center(
          child: Text(
            'Time\'s Up!',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildResultStat('Score', '$_score', Icons.star, AppColors.accentOrange),
            const SizedBox(height: 16),
            _buildResultStat('Cards', '$_cardsReviewed', Icons.style, AppColors.primaryTeal),
            const SizedBox(height: 16),
            _buildResultStat('Accuracy', '$accuracy%', Icons.check_circle, AppColors.success),
            const SizedBox(height: 16),
            _buildResultStat('Best Streak', '$_maxStreak', Icons.local_fire_department, AppColors.accentCoral),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Exit'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _startGame();
            },
            child: const Text('Play Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildResultStat(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: AppColors.neutralDark)),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onAnswer(bool knewIt) {
    if (!_isGameActive) return;

    setState(() {
      _cardsReviewed++;
      
      if (knewIt) {
        _correctAnswers++;
        _streak++;
        if (_streak > _maxStreak) _maxStreak = _streak;
        
        // Score calculation: base + streak bonus
        int points = 10 + (_streak * 2);
        if (_currentCard.difficultyLevel >= 3) points += 5;
        _score += points;
      } else {
        _streak = 0;
      }

      // Move to next card
      _currentIndex = (_currentIndex + 1) % _vocabulary.length;
      _currentCard = _vocabulary[_currentIndex];
      _showAnswer = false;
    });

    _cardController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: _isGameActive ? _buildGameScreen() : _buildStartScreen(),
      ),
    );
  }

  Widget _buildStartScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.accentCoral, AppColors.error],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentCoral.withValues(alpha: 0.4),
                  blurRadius: 30,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: const Icon(
              Icons.bolt,
              color: Colors.white,
              size: 80,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Speed Review',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '60 seconds • As many cards as you can!',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 48),
          ElevatedButton.icon(
            onPressed: _startGame,
            icon: const Icon(Icons.play_arrow, size: 28),
            label: const Text(
              'START',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentCoral,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameScreen() {
    return Column(
      children: [
        // Top bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Timer
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _timeRemaining <= 10 
                    ? AppColors.error.withValues(alpha: 0.2) 
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
                border: _timeRemaining <= 10
                    ? Border.all(color: AppColors.error)
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.timer,
                    color: _timeRemaining <= 10 ? AppColors.error : Theme.of(context).colorScheme.onSurface,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$_timeRemaining',
                    style: TextStyle(
                      color: _timeRemaining <= 10 ? AppColors.error : Theme.of(context).colorScheme.onSurface,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              ),
              // Score
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.accentOrange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, color: AppColors.accentOrange, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '$_score',
                      style: const TextStyle(
                        color: AppColors.accentOrange,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Streak indicator
        if (_streak > 1)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  AppColors.accentCoral,
                  AppColors.error,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentCoral.withValues(alpha: 0.4),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.local_fire_department, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  '$_streak STREAK!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

        // Card
        Expanded(
          child: AnimatedBuilder(
            animation: _cardController,
            builder: (context, child) {
              return Transform.scale(
                scale: 1 - (_cardController.value * 0.1),
                child: child,
              );
            },
            child: GestureDetector(
              onTap: () => setState(() => _showAnswer = true),
              child: Container(
                margin: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
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
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _currentCard.word,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_showAnswer) ...[
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            _currentCard.translation,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 28,
                            ),
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 24),
                        Text(
                          'Tap to reveal',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // Answer buttons
        if (_showAnswer)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _onAnswer(false),
                    icon: const Icon(Icons.close),
                    label: const Text('AGAIN'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _onAnswer(true),
                    icon: const Icon(Icons.check),
                    label: const Text('KNOW IT'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          const SizedBox(height: 100),
      ],
    );
  }
}
