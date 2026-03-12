import 'package:flutter/material.dart';
import '../../models/vocabulary_item.dart';
import '../../services/tts_service.dart';

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
  
  @override
  void initState() {
    super.initState();
    // Play initial word if vocabulary is not empty
    if (widget.vocabulary.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _playWord();
      });
    }
  }

  @override
  void dispose() {
    TtsService().stop();
    _controller.dispose();
    super.dispose();
  }

  void _playWord() async {
    if (widget.vocabulary.isEmpty) return;
    final currentWord = widget.vocabulary[_currentIndex];
    await TtsService().speak(
      currentWord.word,
      languageCode: widget.targetLanguage,
      context: context,
    );
  }  void _checkSpelling() {
    final userAnswer = _controller.text.trim().toLowerCase();
    final correctAnswer = widget.vocabulary[_currentIndex].word.toLowerCase();
    
    setState(() {
      _isCorrect = userAnswer == correctAnswer;
      _showResult = true;
      
      if (_isCorrect) {
        _score += 10 + (_streak * 2);
        _streak++;
        _feedback = 'Excellent!';
      } else {
        _streak = 0;
        _feedback = 'The correct spelling is: ${widget.vocabulary[_currentIndex].word}';
      }
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _controller.clear();
          _showResult = false;
          _currentIndex = (_currentIndex + 1) % widget.vocabulary.length;
        });
        _playWord();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.vocabulary.isEmpty) {
      return Scaffold(
         appBar: AppBar(title: const Text('Spelling Bee')),
         body: const Center(child: Text('No vocabulary data available')),
      );
    }
    final currentWord = widget.vocabulary[_currentIndex];
    
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
                    gradient: LinearGradient(
                      colors: [Colors.orange.shade600, Colors.red.shade600],
                    ),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.4),
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
                    // Hint
                    Text(
                      'Hint: ${currentWord.translation}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
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
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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
                          color: Colors.amber,
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
                        ? (_isCorrect ? Colors.green : Colors.red)
                        : Theme.of(context).colorScheme.outline.withOpacity(0.2),
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
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
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
                        ? Colors.green.withOpacity(0.2)
                        : Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isCorrect ? Colors.green : Colors.red,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isCorrect ? Icons.check_circle : Icons.error,
                        color: _isCorrect ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _feedback,
                          style: TextStyle(
                            color: _isCorrect ? Colors.green : Colors.red,
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
                    backgroundColor: const Color(0xFF667eea),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    disabledBackgroundColor: Colors.grey.shade800,
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
