import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import '../../services/tts_service.dart';

/// Translation Challenge Mode
/// Race against the clock to translate words and phrases
class TranslationChallengeScreen extends StatefulWidget {
  final List<Map<String, dynamic>> sentences;
  final String targetLanguage;
  final String nativeLanguage;

  const TranslationChallengeScreen({
    super.key,
    required this.sentences,
    required this.targetLanguage,
    required this.nativeLanguage,
  });

  @override
  State<TranslationChallengeScreen> createState() => _TranslationChallengeScreenState();
}

class _TranslationChallengeScreenState extends State<TranslationChallengeScreen> {
  int _currentLevel = 1;
  int _score = 0;
  int _lives = 3;
  int _timeBonus = 0;
  bool _isGameActive = false;
  bool _showResult = false;
  bool _isCorrect = false;
  
  String _currentPrompt = '';
  String _correctAnswer = '';
  List<String> _options = [];

  @override
  void dispose() {
    TtsService().stop();
    super.dispose();
  }
  void _startGame() {
    setState(() {
      _isGameActive = true;
      _currentLevel = 1;
      _score = 0;
      _lives = 3;
      _timeBonus = 0;
    });
    _loadNextChallenge();
  }

  void _loadNextChallenge() {
    if (widget.sentences.isEmpty) return;
    
    final sentence = widget.sentences[Random().nextInt(widget.sentences.length)];
    setState(() {
      _currentPrompt = sentence['translation'] as String? ?? '';
      _correctAnswer = sentence['full_sentence'] as String? ?? '';
      
      // Generate some options around the correct answer (using other full sentences)
      final options = <String>[_correctAnswer];
      final others = widget.sentences
          .where((s) => s['full_sentence'] != _correctAnswer)
          .map((s) => s['full_sentence'] as String)
          .toList()
        ..shuffle();
      
      options.addAll(others.take(3));
      options.shuffle();
      
      _options = options;
      _showResult = false;
    });
  }

  void _checkAnswer(String selectedAnswer) {
    final isCorrect = selectedAnswer == _correctAnswer;
    
    setState(() {
      _isCorrect = isCorrect;
      _showResult = true;
      
      if (isCorrect) {
        _score += 10 * _currentLevel;
        _currentLevel++;
        if (_currentLevel % 5 == 0) {
          _lives = min(5, _lives + 1);
        }
        // Auto-play the correct answer in target language
        TtsService().speak(_correctAnswer, languageCode: widget.targetLanguage, context: context);
      } else {
        _lives--;
      }
    });

    if (_lives <= 0) {
      Future.delayed(const Duration(milliseconds: 500), _showGameOver);
    } else {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted && _lives > 0) {
          _loadNextChallenge();
        }
      });
    }
  }

  void _showGameOver() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Game Over!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Final Score: $_score'),
            const SizedBox(height: 8),
            Text('Level Reached: $_currentLevel'),
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
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  int min(int a, int b) => a < b ? a : b;

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
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF667eea).withOpacity(0.5),
                  blurRadius: 30,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: const Icon(
              Icons.translate,
              color: Colors.white,
              size: 70,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Translation Challenge',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Translate as many words as you can!\nDon\'t lose all your lives!',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 48),
          ElevatedButton.icon(
            onPressed: _startGame,
            icon: const Icon(Icons.play_arrow, size: 28),
            label: const Text(
              'START CHALLENGE',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667eea),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
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
        // Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Level
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF667eea).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Level $_currentLevel',
                  style: const TextStyle(
                    color: Color(0xFF667eea),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Lives
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < _lives ? Icons.favorite : Icons.favorite_border,
                    color: index < _lives ? Colors.red : Colors.grey,
                    size: 24,
                  );
                }),
              ),
              // Score
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$_score',
                  style: const TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Progress bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: LinearProgressIndicator(
            value: (_currentLevel % 5) / 5,
            backgroundColor: Colors.grey.shade800,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF667eea)),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ),

        const Spacer(),

        // Prompt card
        Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _showResult
                  ? (_isCorrect
                      ? [Colors.green.shade400, Colors.green.shade600]
                      : [Colors.red.shade400, Colors.red.shade600])
                  : [const Color(0xFF667eea), const Color(0xFF764ba2)],
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: (_showResult
                        ? (_isCorrect ? Colors.green : Colors.red)
                        : const Color(0xFF667eea))
                    .withOpacity(0.4),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Center(
            child: Column(
              children: [
                const Text(
                  'Translate this:',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        _currentPrompt,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (!_showResult)
                      IconButton(
                        icon: const Icon(Icons.volume_up, color: Colors.white, size: 28),
                        onPressed: () {
                          TtsService().speak(_currentPrompt, languageCode: widget.nativeLanguage, context: context);
                        },
                      ),
                  ],
                ),
                if (_showResult) ...[
                  const SizedBox(height: 16),
                  Icon(
                    _isCorrect ? Icons.check_circle : Icons.cancel,
                    color: Colors.white,
                    size: 48,
                  ),
                  if (!_isCorrect) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Correct: $_correctAnswer',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),

        const Spacer(),

        // Answer buttons
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: _options.map((option) {
              Color buttonColor = Theme.of(context).colorScheme.surfaceContainerHighest;
              
              if (_showResult) {
                if (option == _correctAnswer) {
                  buttonColor = Colors.green;
                } else if (option != _correctAnswer) {
                  buttonColor = Colors.red.withOpacity(0.3);
                }
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ElevatedButton(
                  onPressed: _showResult ? null : () => _checkAnswer(option),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 60),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    option,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
