import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../models/grammar_models.dart';
import '../../../providers/course_provider.dart';
import '../../../services/grammar_service.dart';
import '../../../theme/app_theme.dart';

class ConjugationDrillScreen extends StatefulWidget {
  const ConjugationDrillScreen({super.key});

  @override
  State<ConjugationDrillScreen> createState() => _ConjugationDrillScreenState();
}

class _ConjugationDrillScreenState extends State<ConjugationDrillScreen> {
  final GrammarService _grammarService = GrammarService();
  bool _isLoading = true;
  List<VerbConjugation> _conjugations = [];
  int _currentIndex = 0;
  int _score = 0;
  bool _answered = false;
  int? _selectedAnswer;
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
        final conjugations = await _grammarService.getConjugations(
          activeCourse.courseId,
          activeCourse.targetLanguage,
        );
        setState(() {
          _conjugations = List.from(conjugations)..shuffle();
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

  void _onAnswer(int index, String selectedConjugation, String correctConjugation) {
    if (_answered) return;
    
    HapticFeedback.lightImpact();
    setState(() {
      _answered = true;
      _selectedAnswer = index;
      if (selectedConjugation == correctConjugation) {
        _score += 10;
        HapticFeedback.mediumImpact();
      } else {
        HapticFeedback.heavyImpact();
      }
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        if (_currentIndex < _conjugations.length - 1) {
          setState(() {
            _currentIndex++;
            _answered = false;
            _selectedAnswer = null;
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
        title: const Text('Conjugation Drill'),
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
    if (_conjugations.isEmpty) return const Center(child: Text('No conjugations available'));
    
    final conjugation = _conjugations[_currentIndex];
    final tenses = conjugation.conjugations.keys.toList();
    final firstTense = tenses.first;
    final persons = conjugation.conjugations[firstTense]!.keys.toList();
    final correctConjugation = conjugation.getConjugation(firstTense, persons.first)!;
    
    // Generate options
    final options = [correctConjugation];
    // Add some distractors from other persons/verbs
    for (var i = 1; i < persons.length && options.length < 4; i++) {
        options.add(conjugation.getConjugation(firstTense, persons[i])!);
    }
    options.shuffle();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LinearProgressIndicator(
            value: (_currentIndex + 1) / _conjugations.length,
            backgroundColor: theme.colorScheme.outline.withValues(alpha: 0.1),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryTeal),
          ),
          const SizedBox(height: 32),
          Text(
            'Conjugate: ${conjugation.infinitive}',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Tense: $firstTense | Person: ${persons.first}',
            style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          ...options.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            final isCorrect = option == correctConjugation;
            final isSelected = _selectedAnswer == index;
            
            Color bgColor = Theme.of(context).cardTheme.color ?? Colors.white;
            Color borderColor = Theme.of(context).colorScheme.outline.withValues(alpha: 0.1);
            
            if (_answered) {
              if (isCorrect) bgColor = AppColors.success.withValues(alpha: 0.2);
              if (isSelected && !isCorrect) bgColor = AppColors.error.withValues(alpha: 0.2);
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () => _onAnswer(index, option, correctConjugation),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                  ),
                  child: Text(
                    option,
                    style: const TextStyle(fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
