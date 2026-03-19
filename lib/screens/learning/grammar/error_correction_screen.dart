import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../models/grammar_models.dart';
import '../../../services/grammar_service.dart';
import '../../../theme/app_theme.dart';

class ErrorCorrectionScreen extends StatefulWidget {
  const ErrorCorrectionScreen({super.key});

  @override
  State<ErrorCorrectionScreen> createState() => _ErrorCorrectionScreenState();
}

class _ErrorCorrectionScreenState extends State<ErrorCorrectionScreen> {
  final GrammarService _grammarService = GrammarService();
  bool _isLoading = true;
  List<GrammarErrorPattern> _errors = [];
  int _currentIndex = 0;
  int _score = 0;
  bool _answered = false;
  String? _selectedCorrection;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // In a real app, we'd fetch errors based on user level/course
      // here we use the service's demo patterns as a base
      final errors = await _grammarService.checkGrammar("dummy text to trigger demo");
      setState(() {
        _errors = List.from(errors)..shuffle();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onAnswer(String correction) {
    if (_answered) return;
    
    HapticFeedback.lightImpact();
    setState(() {
      _answered = true;
      _selectedCorrection = correction;
      if (correction == _errors[_currentIndex].correctPattern) {
        _score += 20;
        HapticFeedback.mediumImpact();
      } else {
        HapticFeedback.heavyImpact();
      }
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        if (_currentIndex < _errors.length - 1) {
          setState(() {
            _currentIndex++;
            _answered = false;
            _selectedCorrection = null;
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
        title: const Text('Error Correction'),
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
    if (_errors.isEmpty) return const Center(child: Text('No exercises available'));
    
    final errorPattern = _errors[_currentIndex];
    final isCorrect = _selectedCorrection == errorPattern.correctPattern;

    // Distractors
    final options = [errorPattern.correctPattern, errorPattern.incorrectPattern];
    // Add more distractors if available in future
    options.shuffle();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LinearProgressIndicator(
            value: (_currentIndex + 1) / _errors.length,
            backgroundColor: theme.colorScheme.outline.withValues(alpha: 0.1),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryTeal),
          ),
          const SizedBox(height: 32),
          Text(
            'Identify the correct version:',
            style: TextStyle(
              fontSize: 16,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.3)),
            ),
            child: Text(
              errorPattern.incorrectPattern,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.lineThrough,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 48),
          
          ...options.map((option) {
            final isOptionSelected = _selectedCorrection == option;
            final isOptionCorrect = option == errorPattern.correctPattern;
            
            Color bgColor = Theme.of(context).cardTheme.color ?? Colors.white;
            if (_answered) {
              if (isOptionCorrect) bgColor = AppColors.success.withValues(alpha: 0.2);
              if (isOptionSelected && !isOptionCorrect) bgColor = AppColors.error.withValues(alpha: 0.2);
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () => _onAnswer(option),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Text(
                    option,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          }),
          
          const Spacer(),
          
          if (_answered)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    isCorrect ? 'Correct!' : 'Incorrect',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isCorrect ? AppColors.success : AppColors.error,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    errorPattern.explanation,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ).animate().slideY(begin: 0.2),
        ],
      ),
    );
  }
}
