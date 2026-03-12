import 'package:flutter/material.dart';
import 'dart:async';

/// Listening Dictation Mode
/// Listen and type what you hear
class ListeningDictationScreen extends StatefulWidget {
  const ListeningDictationScreen({super.key});

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
  
  final List<Map<String, dynamic>> _dictations = [
    {
      'text': 'Hola, ¿cómo estás?',
      'translation': 'Hello, how are you?',
      'difficulty': 1,
      'slowVersion': true,
    },
    {
      'text': 'Me llamo María y soy de España.',
      'translation': 'My name is Maria and I am from Spain.',
      'difficulty': 2,
      'slowVersion': true,
    },
    {
      'text': 'El clima está muy bonito hoy.',
      'translation': 'The weather is very nice today.',
      'difficulty': 2,
      'slowVersion': true,
    },
    {
      'text': 'Me gustaría pedir un café, por favor.',
      'translation': 'I would like to order a coffee, please.',
      'difficulty': 3,
      'slowVersion': true,
    },
    {
      'text': '¿Dónde está la estación de tren?',
      'translation': 'Where is the train station?',
      'difficulty': 3,
      'slowVersion': true,
    },
  ];

  void _togglePlay() {
    setState(() => _isPlaying = !_isPlaying);
    
    if (_isPlaying) {
      // Simulate audio playback duration
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _isPlaying = false);
      });
    }
  }

  void _checkAnswer() {
    final userAnswer = _controller.text.trim().toLowerCase();
    final correctAnswer = _dictations[_currentIndex]['text'].toString().toLowerCase();
    
    setState(() {
      _isCorrect = userAnswer == correctAnswer;
      _showAnswer = true;
      _attempts++;
      
      if (_isCorrect) {
        int points = 100 - (_attempts - 1) * 20;
        if (points < 20) points = 20;
        _score += points;
      }
    });
  }

  void _nextQuestion() {
    setState(() {
      _controller.clear();
      _showAnswer = false;
      _attempts = 0;
      _currentIndex = (_currentIndex + 1) % _dictations.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentDictation = _dictations[_currentIndex];
    
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
                  value: (_currentIndex + 1) / _dictations.length,
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF667eea)),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Question ${_currentIndex + 1} of ${_dictations.length}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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
                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF667eea).withOpacity(0.4),
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
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
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
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
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
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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
                        _buildSpeedButton('0.5x', false),
                        const SizedBox(width: 12),
                        _buildSpeedButton('1.0x', true),
                        const SizedBox(width: 12),
                        _buildSpeedButton('0.75x', false),
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
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
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
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(20),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white54),
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
                        ? Colors.green.withOpacity(0.2) 
                        : Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _isCorrect ? Colors.green : Colors.red,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            _isCorrect ? Icons.check_circle : Icons.error,
                            color: _isCorrect ? Colors.green : Colors.red,
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
                                    color: _isCorrect ? Colors.green : Colors.red,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (!_isCorrect)
                                  Text(
                                    currentDictation['text'],
                                    style: const TextStyle(
                                      color: Colors.white,
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
                        'Translation: ${currentDictation['translation']}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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
                    backgroundColor: const Color(0xFF667eea),
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

  Widget _buildSpeedButton(String label, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? Theme.of(context).colorScheme.surfaceContainerHighest : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isActive ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
