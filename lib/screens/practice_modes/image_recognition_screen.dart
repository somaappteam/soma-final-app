import 'package:flutter/material.dart';
import '../../models/vocabulary_item.dart';
import '../../theme/app_theme.dart';

/// Image Recognition Mode
/// Identify objects in images
class ImageRecognitionScreen extends StatefulWidget {
  final List<VocabularyItem> vocabulary;
  final String targetLanguage;
  final String nativeLanguage;

  const ImageRecognitionScreen({
    super.key,
    this.vocabulary = const [],
    this.targetLanguage = 'es',
    this.nativeLanguage = 'en',
  });

  const ImageRecognitionScreen.withVocabulary({
    super.key,
    required this.vocabulary,
    required this.targetLanguage,
    required this.nativeLanguage,
  });

  @override
  State<ImageRecognitionScreen> createState() => _ImageRecognitionScreenState();
}

class _ImageRecognitionScreenState extends State<ImageRecognitionScreen> {
  int _score = 0;
  int _streak = 0;
  int _currentIndex = 0;
  bool _showResult = false;
  bool _isCorrect = false;

  Map<String, dynamic> _buildPracticeResult() {
    final total = _images.length;
    final correct = (_score / 10).round();
    final accuracy = (total > 0 ? correct / total : 0).clamp(0.0, 1.0);
    return {
      'correct': correct,
      'total': total,
      'accuracy': accuracy,
      'avgResponseSeconds': 0.0,
    };
  }
  
  final List<Map<String, dynamic>> _defaultImages = [
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

  late List<Map<String, dynamic>> _images;

  @override
  void initState() {
    super.initState();
    _images = _buildImagesFromVocabulary();
  }

  List<Map<String, dynamic>> _buildImagesFromVocabulary() {
    if (widget.vocabulary.length < 4) {
      return _defaultImages;
    }

    final words = List<VocabularyItem>.from(widget.vocabulary)..shuffle();
    final selected = words.take(words.length > 12 ? 12 : words.length).toList();

    return selected.map((item) {
      final distractors = words
          .where((w) => w.id != item.id)
          .map((w) => w.word)
          .toList()
        ..shuffle();

      final options = <String>[item.word, ...distractors.take(3)]..shuffle();

      return {
        'emoji': _emojiForWord(item.word, item.translation),
        'word': item.word,
        'translation': item.translation,
        'options': options,
      };
    }).toList();
  }

  String _emojiForWord(String word, String translation) {
    final source = '${word.toLowerCase()} ${translation.toLowerCase()}';
    final map = <String, String>{
      'apple': '🍎',
      'banana': '🍌',
      'orange': '🍊',
      'bread': '🍞',
      'water': '💧',
      'coffee': '☕',
      'milk': '🥛',
      'car': '🚗',
      'bus': '🚌',
      'train': '🚆',
      'house': '🏠',
      'home': '🏠',
      'school': '🏫',
      'book': '📚',
      'phone': '📱',
      'computer': '💻',
      'dog': '🐕',
      'cat': '🐈',
      'bird': '🐦',
      'fish': '🐟',
      'tree': '🌳',
      'flower': '🌸',
      'sun': '☀️',
      'moon': '🌙',
      'star': '⭐',
      'heart': '❤️',
      'manzana': '🍎',
      'plátano': '🍌',
      'naranja': '🍊',
      'agua': '💧',
      'coche': '🚗',
      'casa': '🏠',
      'escuela': '🏫',
      'libro': '📚',
      'perro': '🐕',
      'gato': '🐈',
      'árbol': '🌳',
      'flor': '🌸',
      'sol': '☀️',
      'luna': '🌙',
    };

    for (final entry in map.entries) {
      if (source.contains(entry.key)) return entry.value;
    }

    return '🖼️';
  }

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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, _buildPracticeResult()),
        ),
        title: const Text('Picture Vocabulary Quiz'),
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
                  gradient: const LinearGradient(
                    colors: [AppColors.accentCoral, AppColors.error],
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
                  colors: [AppColors.primaryTeal, AppColors.darkTeal],
                ),
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryTeal.withValues(alpha: 0.4),
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
              'Select the matching word',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
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
                      buttonColor = AppColors.success;
                    } else {
                      buttonColor = AppColors.error.withValues(alpha: 0.3);
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
