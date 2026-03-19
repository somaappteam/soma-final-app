import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../models/grammar_models.dart';
import '../../../providers/course_provider.dart';
import '../../../services/grammar_service.dart';
import '../../../theme/app_theme.dart';

class SentenceStructureScreen extends StatefulWidget {
  const SentenceStructureScreen({super.key});

  @override
  State<SentenceStructureScreen> createState() => _SentenceStructureScreenState();
}

class _SentenceStructureScreenState extends State<SentenceStructureScreen> {
  final GrammarService _grammarService = GrammarService();
  bool _isLoading = true;
  List<SentencePattern> _patterns = [];
  int _currentIndex = 0;
  int _score = 0;
  bool _answered = false;
  List<String> _userOrder = [];
  List<String> _shuffledWords = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final courseProvider = context.read<CourseProvider>();
      final activeCourse = courseProvider.activeCourse;
      if (activeCourse != null) {
        final patterns = await _grammarService.getSentencePatterns(
          activeCourse.courseId,
          activeCourse.targetLanguage,
          activeCourse.nativeLanguage,
        );
        setState(() {
          _patterns = List.from(patterns)..shuffle();
          if (_patterns.isNotEmpty) _prepareQuestion();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Please select a course first';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _prepareQuestion() {
    final pattern = _patterns[_currentIndex];
    final example = pattern.examples.first;
    _shuffledWords = example.split(' ')..shuffle();
    _userOrder = [];
    _answered = false;
  }

  void _onWordTap(String word) {
    if (_answered) return;
    
    HapticFeedback.lightImpact();
    setState(() {
      _userOrder.add(word);
      _shuffledWords.remove(word);
      
      if (_shuffledWords.isEmpty) {
        _checkAnswer();
      }
    });
  }

  void _onRemoveWord(String word) {
    if (_answered) return;
    
    HapticFeedback.lightImpact();
    setState(() {
      _userOrder.remove(word);
      _shuffledWords.add(word);
    });
  }

  void _checkAnswer() {
    final pattern = _patterns[_currentIndex];
    final example = pattern.examples.first;
    final userSentence = _userOrder.join(' ');
    
    setState(() {
      _answered = true;
      if (userSentence.toLowerCase() == example.toLowerCase()) {
        _score += 15;
        HapticFeedback.mediumImpact();
      } else {
        HapticFeedback.heavyImpact();
      }
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        if (_currentIndex < _patterns.length - 1) {
          setState(() {
            _currentIndex++;
            _prepareQuestion();
          });
        } else {
          _showResults();
        }
      }
    });
  }

  void _showResults() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Practice Complete!'),
        content: Text('Your score: $_score'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Pop dialog
              Navigator.pop(context); // Pop screen
            },
            child: const Text('Finish'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Sentence Structure'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _buildDrillContent(),
    );
  }

  Widget _buildDrillContent() {
    final theme = Theme.of(context);
    if (_patterns.isEmpty) return const Center(child: Text('No patterns available'));
    
    final pattern = _patterns[_currentIndex];
    final example = pattern.examples.first;
    final isCorrect = _userOrder.join(' ').toLowerCase() == example.toLowerCase();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LinearProgressIndicator(
            value: (_currentIndex + 1) / _patterns.length,
            backgroundColor: theme.colorScheme.outline.withValues(alpha: 0.1),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryTeal),
          ),
          const SizedBox(height: 32),
          Text(
            pattern.title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            pattern.explanation,
            style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          
          // Answer Area
          Container(
            padding: const EdgeInsets.all(16),
            constraints: const BoxConstraints(minHeight: 100),
            decoration: BoxDecoration(
              color: theme.cardTheme.color?.withValues(alpha: 0.5) ?? AppColors.neutralLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _answered 
                  ? (isCorrect ? AppColors.success : AppColors.error)
                  : theme.colorScheme.outline.withValues(alpha: 0.2),
                width: 2,
              ),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _userOrder.map((word) => _buildWordChip(word, true)).toList(),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Words Pool
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: _shuffledWords.map((word) => _buildWordChip(word, false)).toList(),
          ),
          
          const Spacer(),
          
          if (_answered)
            Text(
              isCorrect ? 'Excellent!' : 'Correct: $example',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isCorrect ? AppColors.success : AppColors.error,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn().shake(),
        ],
      ),
    );
  }

  Widget _buildWordChip(String word, bool isInAnswer) {
    return GestureDetector(
      onTap: isInAnswer ? () => _onRemoveWord(word) : () => _onWordTap(word),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color ?? Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          word,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
