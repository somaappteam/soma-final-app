import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/vocabulary_item.dart';
import '../../theme/app_theme.dart';
import '../../services/tts_service.dart';

/// Premium Listening Practice - Visual Audio Recognition
/// Users see visual audio representation and select the word
class ListeningPracticeScreen extends StatefulWidget {
  final List<VocabularyItem> vocabulary;
  final String targetLanguage;
  final String nativeLanguage;

  const ListeningPracticeScreen({
    super.key,
    required this.vocabulary,
    required this.targetLanguage,
    required this.nativeLanguage,
  });

  @override
  State<ListeningPracticeScreen> createState() => _ListeningPracticeScreenState();
}

class _ListeningPracticeScreenState extends State<ListeningPracticeScreen>
    with TickerProviderStateMixin {
  // Game Data
  late List<VocabularyItem> _quizVocabulary;
  late List<Map<String, dynamic>> _questions;
  
  // Game State
  int _currentQuestionIndex = 0;
  int _score = 0;
  int _totalXP = 0;
  int _correctCount = 0;
  int _streak = 0;
  int _maxStreak = 0;
  int _comboMultiplier = 1;
  bool _answered = false;
  int? _selectedAnswer;
  bool _isComplete = false;
  bool _isPlaying = false;
  bool _showWaveform = false;
  
  // Waveform animation
  late AnimationController _waveController;
  List<double> _waveformBars = [];
  Timer? _playTimer;
  
  // Achievement tracking
  int _perfectListens = 0; // Answered correctly on first play

  @override
  void initState() {
    super.initState();
    _prepareQuiz();
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
    _generateWaveform();
  }

  @override
  void dispose() {
    _waveController.dispose();
    _playTimer?.cancel();
    TtsService().stop();
    super.dispose();
  }

  void _generateWaveform() {
    _waveformBars = List.generate(20, (index) {
      return 0.3 + (Random().nextDouble() * 0.7);
    });
  }

  void _prepareQuiz() {
    _quizVocabulary = List.from(widget.vocabulary)..shuffle();
    if (_quizVocabulary.length > 20) {
      _quizVocabulary = _quizVocabulary.sublist(0, 20);
    }

    _questions = _quizVocabulary.map((word) {
      final options = _generateOptions(word);
      
      return {
        'word': word,
        'wordText': word.word,
        'options': options,
        'correctIndex': options.indexOf(word.word),
      };
    }).toList();
  }

  List<String> _generateOptions(VocabularyItem correctWord) {
    final options = <String>[correctWord.word];
    final otherWords = widget.vocabulary
        .where((w) => w.id != correctWord.id)
        .toList();
    
    otherWords.shuffle();
    
    for (var word in otherWords.take(3)) {
      options.add(word.word);
    }
    
    while (options.length < 4) {
      options.add('Word ${options.length}');
    }
    
    options.shuffle();
    return options;
  }

  void _playWord() async {
    if (_isPlaying) return;
    
    HapticFeedback.lightImpact();
    
    setState(() {
      _isPlaying = true;
      _showWaveform = true;
    });
    
    final currentQuestion = _questions[_currentQuestionIndex];
    
    // Play audio via TTS
    await TtsService().speak(
      currentQuestion['wordText'],
      languageCode: widget.targetLanguage,
      context: context,
    );
    
    // End visualizer state after simulated or actual playback finishes
    _playTimer?.cancel();
    _playTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
      }
    });
  }

  void _selectAnswer(int index) {
    if (_answered || _isComplete) return;

    HapticFeedback.mediumImpact();
    
    final currentQuestion = _questions[_currentQuestionIndex];
    final isCorrect = index == currentQuestion['correctIndex'];

    setState(() {
      _answered = true;
      _selectedAnswer = index;
      
      if (isCorrect) {
        _correctCount++;
        _streak++;
        if (_streak > _maxStreak) _maxStreak = _streak;
        
        // Combo multiplier
        _comboMultiplier = 1 + (_streak ~/ 3);
        const baseXP = 15;
        final earnedXP = baseXP * _comboMultiplier;
        
        _score += baseXP;
        _totalXP += earnedXP;
        
        // Check for perfect listen (answered on first play)
        if (_showWaveform) {
          _perfectListens++;
        }
      } else {
        _streak = 0;
        _comboMultiplier = 1;
        HapticFeedback.heavyImpact();
      }
    });

    Future.delayed(const Duration(milliseconds: 800), () {
      if (_currentQuestionIndex < _questions.length - 1) {
        setState(() {
          _currentQuestionIndex++;
          _answered = false;
          _selectedAnswer = null;
          _isPlaying = false;
          _showWaveform = false;
        });
        _generateWaveform();
      } else {
        setState(() {
          _isComplete = true;
        });
      }
    });
  }

  void _restartQuiz() {
    setState(() {
      _currentQuestionIndex = 0;
      _score = 0;
      _totalXP = 0;
      _correctCount = 0;
      _streak = 0;
      _maxStreak = 0;
      _comboMultiplier = 1;
      _perfectListens = 0;
      _answered = false;
      _selectedAnswer = null;
      _isComplete = false;
      _isPlaying = false;
      _showWaveform = false;
    });
    _prepareQuiz();
    _generateWaveform();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: _isComplete ? _buildResultsScreen() : _buildQuizScreen(),
    );
  }

  Widget _buildQuizScreen() {
    final question = _questions[_currentQuestionIndex];
    final progress = (_currentQuestionIndex + 1) / _questions.length;

    return SafeArea(
      child: Column(
        children: [
          _buildHeader(progress),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildAudioVisualizer(question['wordText']),
                  const SizedBox(height: 40),
                  _buildPlayButton(),
                  const SizedBox(height: 40),
                  _buildQuestionText(),
                  const SizedBox(height: 24),
                  _buildOptionsPanel(question),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(double progress) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryTeal.withValues(alpha: 0.15),
            AppColors.darkTeal.withValues(alpha: 0.05),
          ],
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context, _buildPracticeResult()),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Listening Practice',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Question ${_currentQuestionIndex + 1} of ${_questions.length}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textMedium,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.amber, Colors.orange],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withValues(alpha: 0.3),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '$_totalXP',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryTeal),
              minHeight: 8,
            ),
          ),
          if (_streak > 2)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.orange, Colors.red],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_fire_department, 
                      color: Colors.white, 
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$_streak STREAK! x$_comboMultiplier',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().shake(hz: 3),
        ],
      ),
    );
  }

  Widget _buildAudioVisualizer(String wordText) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: _showWaveform
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryTeal,
                  AppColors.darkTeal,
                ],
              )
            : LinearGradient(
                colors: [
                  Colors.grey.shade100,
                  Colors.grey.shade50,
                ],
              ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: (_showWaveform ? AppColors.primaryTeal : Colors.grey)
                .withValues(alpha: 0.3),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Waveform visualization
          SizedBox(
            height: 100,
            child: AnimatedBuilder(
              animation: _waveController,
              builder: (context, child) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _waveformBars.asMap().entries.map((entry) {
                    final index = entry.key;
                    final baseHeight = entry.value;
                    
                    // Animate bars when playing
                    double animatedHeight = baseHeight;
                    if (_isPlaying) {
                      final phase = (_waveController.value * 2 * pi) + (index * 0.3);
                      animatedHeight = baseHeight * (0.5 + 0.5 * sin(phase));
                    } else if (!_showWaveform) {
                      animatedHeight = 0.2;
                    }
                    
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 100),
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      width: 8,
                      height: 20 + (animatedHeight * 60),
                      decoration: BoxDecoration(
                        color: _showWaveform
                            ? Colors.white.withValues(alpha: 0.9)
                            : Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          // Word reveal (only when playing)
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            crossFadeState: _isPlaying
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                wordText,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ).animate().fadeIn().scale(),
            secondChild: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Text(
                _showWaveform ? 'Tap play to listen again' : 'Ready to listen?',
                style: TextStyle(
                  fontSize: 16,
                  color: _showWaveform
                      ? AppColors.primaryTeal
                      : AppColors.textMedium,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms);
  }

  Widget _buildPlayButton() {
    return GestureDetector(
      onTap: _playWord,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primaryTeal, AppColors.darkTeal],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryTeal.withValues(alpha: 0.4),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _isPlaying
              ? const SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 50,
                ),
        ),
      ),
    )
    .animate()
    .scale(duration: 400.ms, curve: Curves.elasticOut)
    .then()
    .animate(onComplete: (controller) => controller.repeat(reverse: true))
    .scale(duration: 1000.ms, begin: const Offset(1, 1), end: const Offset(1.05, 1.05));
  }

  Widget _buildQuestionText() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'What word did you hear?',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.textDark,
        ),
      ),
    );
  }

  Widget _buildOptionsPanel(Map<String, dynamic> question) {
    return Column(
      children: (question['options'] as List).asMap().entries.map((entry) {
        final index = entry.key;
        final option = entry.value;
        final isCorrect = index == question['correctIndex'];
        final isSelected = _selectedAnswer == index;
        
        Color bgColor = Colors.white;
        Color borderColor = Colors.grey.shade300;
        Color textColor = AppColors.textDark;
        
        if (_answered) {
          if (isCorrect) {
            bgColor = Colors.green.shade50;
            borderColor = Colors.green;
            textColor = Colors.green.shade700;
          } else if (isSelected && !isCorrect) {
            bgColor = Colors.red.shade50;
            borderColor = Colors.red;
            textColor = Colors.red.shade700;
          }
        } else if (isSelected) {
          bgColor = AppColors.primaryTeal.withValues(alpha: 0.1);
          borderColor = AppColors.primaryTeal;
          textColor = AppColors.primaryTeal;
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: () => _selectAnswer(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: borderColor,
                  width: 2,
                ),
                boxShadow: [
                  if (!_answered)
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _answered && isCorrect
                          ? Colors.green
                          : _answered && isSelected && !isCorrect
                              ? Colors.red
                              : AppColors.primaryTeal.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        String.fromCharCode(65 + index),
                        style: TextStyle(
                          color: _answered && (isCorrect || (isSelected && !isCorrect))
                              ? Colors.white
                              : AppColors.primaryTeal,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      option,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ),
                  if (_answered && isCorrect)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 20,
                      ),
                    )
                  else if (_answered && isSelected && !isCorrect)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildResultsScreen() {
    final accuracy = _correctCount > 0
        ? (_correctCount / _questions.length * 100).round()
        : 0;
    final isAudioMaster = accuracy >= 80 && _perfectListens >= _correctCount ~/ 2;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isAudioMaster
              ? [Colors.teal.shade100, Colors.white]
              : [Colors.grey.shade100, Colors.white],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              _buildResultsBadge(isAudioMaster, accuracy),
              const SizedBox(height: 32),
              _buildResultsStats(accuracy),
              const SizedBox(height: 40),
              _buildResultsActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultsBadge(bool isAudioMaster, int accuracy) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Glow effect
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    isAudioMaster
                        ? AppColors.primaryTeal.withValues(alpha: 0.3)
                        : Colors.grey.withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            
            // Main badge
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                gradient: isAudioMaster
                    ? const LinearGradient(
                        colors: [
                          AppColors.primaryTeal,
                          AppColors.darkTeal,
                        ],
                      )
                    : const LinearGradient(
                        colors: [Colors.orange, Colors.amber],
                      ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (isAudioMaster ? AppColors.primaryTeal : Colors.orange)
                        .withValues(alpha: 0.4),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(
                isAudioMaster ? Icons.hearing : Icons.headphones,
                color: Colors.white,
                size: 70,
              ),
            )
            .animate()
            .scale(duration: 600.ms, curve: Curves.elasticOut),
          ],
        ),
        
        const SizedBox(height: 24),
        
        Text(
          isAudioMaster ? 'Audio Master!' : 'Practice Complete!',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: isAudioMaster ? AppColors.primaryTeal : AppColors.textDark,
          ),
        )
        .animate()
        .fadeIn(delay: 300.ms)
        .slideY(begin: 0.2, end: 0),
        
        const SizedBox(height: 8),
        
        Text(
          isAudioMaster
              ? 'Perfect ear for the language!'
              : 'Keep training your listening skills!',
          style: const TextStyle(
            fontSize: 16,
            color: AppColors.textMedium,
          ),
          textAlign: TextAlign.center,
        )
        .animate()
        .fadeIn(delay: 400.ms),
      ],
    );
  }

  Widget _buildResultsStats(int accuracy) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildResultStatCard(
                  icon: Icons.star,
                  value: '$_totalXP',
                  label: 'Total XP',
                  color: Colors.amber,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildResultStatCard(
                  icon: Icons.check_circle,
                  value: '$_correctCount',
                  label: 'Correct',
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildResultStatCard(
                  icon: Icons.local_fire_department,
                  value: '$_maxStreak',
                  label: 'Best Streak',
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildResultStatCard(
                  icon: Icons.hearing,
                  value: '$_perfectListens',
                  label: 'Perfect',
                  color: AppColors.primaryTeal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Accuracy',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '$accuracy%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: accuracy >= 80 ? Colors.green : AppColors.textDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: accuracy / 100,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    accuracy >= 80 ? Colors.green : Colors.orange,
                  ),
                  minHeight: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    )
    .animate()
    .fadeIn(delay: 500.ms)
    .slideY(begin: 0.1, end: 0);
  }

  Widget _buildResultStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }


  Map<String, dynamic> _buildPracticeResult() {
    final accuracy = (_questions.isNotEmpty ? _correctCount / _questions.length : 0).clamp(0.0, 1.0);
    return {
      'correct': _correctCount,
      'total': _questions.length,
      'accuracy': accuracy,
      'avgResponseSeconds': 0.0,
    };
  }

  Widget _buildResultsActions() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _restartQuiz,
            icon: const Icon(Icons.replay),
            label: const Text(
              'Practice Again',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryTeal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 8,
              shadowColor: AppColors.primaryTeal.withValues(alpha: 0.4),
            ),
          ),
        )
        .animate()
        .fadeIn(delay: 700.ms)
        .slideY(begin: 0.2, end: 0),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context, _buildPracticeResult()),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textMedium,
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Back to Practice',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(delay: 800.ms),
      ],
    );
  }
}

