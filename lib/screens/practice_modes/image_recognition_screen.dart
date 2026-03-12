import 'package:flutter/material.dart';

/// Image Recognition Mode
/// Identify objects in images
class ImageRecognitionScreen extends StatefulWidget {
  const ImageRecognitionScreen({super.key});

  @override
  State<ImageRecognitionScreen> createState() => _ImageRecognitionScreenState();
}

class _ImageRecognitionScreenState extends State<ImageRecognitionScreen> {
  int _score = 0;
  int _streak = 0;
  int _currentIndex = 0;
  bool _showResult = false;
  bool _isCorrect = false;
  
  final List<Map<String, dynamic>> _images = [
    {
      'emoji': '🍎',
      'word': 'Manzana',
      'translation': 'Apple',
      'options': ['Manzana', 'Naranja', 'Plátano', 'Uva'],
    },
    {
      'emoji': '🚗',
      'word': 'Coche',
      'translation': 'Car',
      'options': ['Coche', 'Bicicleta', 'Avión', 'Barco'],
    },
    {
      'emoji': '🏠',
      'word': 'Casa',
      'translation': 'House',
      'options': ['Casa', 'Edificio', 'Escuela', 'Hospital'],
    },
    {
      'emoji': '🐕',
      'word': 'Perro',
      'translation': 'Dog',
      'options': ['Perro', 'Gato', 'Pájaro', 'Pez'],
    },
    {
      'emoji': '🌳',
      'word': 'Árbol',
      'translation': 'Tree',
      'options': ['Árbol', 'Flor', 'Hierba', 'Planta'],
    },
  ];

  void _checkAnswer(String answer) {
    final isCorrect = answer == _images[_currentIndex]['word'];
    
    setState(() {
      _isCorrect = isCorrect;
      _showResult = true;
      
      if (isCorrect) {
        _streak++;
        _score += 10 + (_streak * 2);
      } else {
        _streak = 0;
      }
    });

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _showResult = false;
          _currentIndex = (_currentIndex + 1) % _images.length;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentImage = _images[_currentIndex];
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Image Recognition'),
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
        child: Column(
          children: [
            // Streak
            if (_streak > 0)
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade600, Colors.red.shade600],
                  ),
                  borderRadius: BorderRadius.circular(25),
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
                      ),
                    ),
                  ],
                ),
              ),
            
            const Spacer(),
            
            // Image display
            Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                ),
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF667eea).withOpacity(0.4),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  currentImage['emoji'],
                  style: const TextStyle(fontSize: 120),
                ),
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Question
            Text(
              'What is this?',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Options
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: (currentImage['options'] as List<String>).map((option) {
                  Color? buttonColor;
                  
                  if (_showResult) {
                    if (option == currentImage['word']) {
                      buttonColor = Colors.green;
                    } else {
                      buttonColor = Colors.red.withOpacity(0.3);
                    }
                  }
                  
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ElevatedButton(
                        onPressed: _showResult ? null : () => _checkAnswer(option),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: buttonColor ?? Theme.of(context).colorScheme.surfaceContainerHighest,
                          foregroundColor: Theme.of(context).colorScheme.onSurface,
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
            
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
