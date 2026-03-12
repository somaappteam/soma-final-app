import 'package:flutter/material.dart';
import '../../services/tts_service.dart';

/// Sentence Completion Mode
/// Complete sentences with missing words
class SentenceCompletionScreen extends StatefulWidget {
  final List<Map<String, dynamic>> sentences;
  final String targetLanguage;
  final String nativeLanguage;

  const SentenceCompletionScreen({
    super.key,
    required this.sentences,
    required this.targetLanguage,
    required this.nativeLanguage,
  });

  @override
  State<SentenceCompletionScreen> createState() => _SentenceCompletionScreenState();
}

class _SentenceCompletionScreenState extends State<SentenceCompletionScreen> {
  int _score = 0;
  int _currentIndex = 0;
  bool _showResult = false;
  bool _isCorrect = false;
  String? _selectedAnswer;
  
  @override
  void dispose() {
    TtsService().stop();
    super.dispose();
  }
  
  void _playSentence(String sentence) {
    TtsService().speak(sentence, languageCode: widget.targetLanguage, context: context);
  }

  void _checkAnswer(String answer) {
    final isCorrect = answer == widget.sentences[_currentIndex]['blank'];
    
    setState(() {
      _isCorrect = isCorrect;
      _showResult = true;
      _selectedAnswer = answer;
      
      if (isCorrect) {
        _score += 10;
        // Auto-play the full sentence when correct
        final fullSentence = widget.sentences[_currentIndex]['sentence'].toString().replaceAll('___', answer);
        _playSentence(fullSentence);
      }
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showResult = false;
          _selectedAnswer = null;
          _currentIndex = (_currentIndex + 1) % widget.sentences.length;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentSentence = widget.sentences[_currentIndex];
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Complete the Sentence'),
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
                  value: (_currentIndex + 1) / widget.sentences.length,
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF667eea)),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 32),
              
              // Sentence card
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
                    // Sentence with blank
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                              children: _buildSentenceSpans(
                                currentSentence['sentence'],
                                currentSentence['blank'],
                              ),
                            ),
                          ),
                        ),
                        if (_showResult && _isCorrect) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.volume_up, color: Colors.white, size: 28),
                            onPressed: () {
                              final fullSentence = currentSentence['sentence'].toString().replaceAll('___', _selectedAnswer!);
                              _playSentence(fullSentence);
                            },
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Translation
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.translate, 
                            color: Colors.white70, size: 20),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              currentSentence['translation'],
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Hint
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16, 
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.amber.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.lightbulb, 
                            color: Colors.amber, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            currentSentence['hint'],
                            style: const TextStyle(
                              color: Colors.amber,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const Spacer(),
              
              // Options
              Column(
                children: (currentSentence['options'] as List<String>).map((option) {
                  Color? buttonColor;
                  
                  if (_showResult) {
                    if (option == currentSentence['blank']) {
                      buttonColor = Colors.green;
                    } else if (option == _selectedAnswer) {
                      buttonColor = Colors.red;
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
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<InlineSpan> _buildSentenceSpans(String sentence, String blank) {
    final parts = sentence.split('___');
    final spans = <InlineSpan>[];
    
    for (int i = 0; i < parts.length; i++) {
      spans.add(TextSpan(text: parts[i]));
      
      if (i < parts.length - 1) {
        spans.add(
          WidgetSpan(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                  width: 2,
                ),
              ),
              child: Text(
                '___',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      }
    }
    
    return spans;
  }
}
