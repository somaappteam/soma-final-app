import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/vocabulary_item.dart';
import '../../theme/app_theme.dart';
import '../../services/tts_service.dart';

/// Premium Pronunciation Practice - Voice Recognition Training
/// Users practice speaking with visual feedback and scoring
class PronunciationPracticeScreen extends StatefulWidget {
  final List<VocabularyItem> vocabulary;
  final String targetLanguage;
  final String nativeLanguage;

  const PronunciationPracticeScreen({
    super.key,
    required this.vocabulary,
    required this.targetLanguage,
    required this.nativeLanguage,
  });

  @override
  State<PronunciationPracticeScreen> createState() => _PronunciationPracticeScreenState();
}

class _PronunciationPracticeScreenState extends State<PronunciationPracticeScreen>
    with TickerProviderStateMixin {
  // Game Data
  late List<VocabularyItem> _practiceVocabulary;
  
  // Game State
  int _currentIndex = 0;
  int _score = 0;
  int _totalXP = 0;
  int _stars = 0;
  int _correctCount = 0;
  int _streak = 0;
  int _maxStreak = 0;
  int _comboMultiplier = 1;
  bool _isComplete = false;
  bool _showingPhonetics = false;
  
  // Recording State
  bool _isRecording = false;
  int _recordingProgress = 0;
  Timer? _recordingTimer;
  
  // Voice Wave Animation
  late AnimationController _waveController;
  List<double> _waveHeights = [];
  
  // Result State
  int? _lastResult;
  bool _showResult = false;

  @override
  void initState() {
    super.initState();
    _prepareVocabulary();
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _generateWaveHeights();
    
    if (_practiceVocabulary.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _playWord();
      });
    }
  }

  @override
  void dispose() {
    TtsService().stop();
    _waveController.dispose();
    _recordingTimer?.cancel();
    super.dispose();
  }

  void _playWord() async {
    if (_practiceVocabulary.isEmpty) return;
    final word = _practiceVocabulary[_currentIndex];
    await TtsService().speak(word.word, languageCode: widget.targetLanguage, context: context);
  }

  void _generateWaveHeights() {
    _waveHeights = List.generate(30, (index) {
      return 0.2 + (Random().nextDouble() * 0.6);
    });
  }

  void _prepareVocabulary() {
    _practiceVocabulary = List.from(widget.vocabulary)..shuffle();
    if (_practiceVocabulary.length > 15) {
      _practiceVocabulary = _practiceVocabulary.sublist(0, 15);
    }
  }

  void _showPhonetics() {
    HapticFeedback.lightImpact();
    setState(() {
      _showingPhonetics = true;
    });
  }

  void _startRecording() {
    HapticFeedback.mediumImpact();
    
    setState(() {
      _isRecording = true;
      _recordingProgress = 0;
      _showResult = false;
    });

    _waveController.repeat();
    
    // Simulate recording progress
    _recordingTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      setState(() {
        _recordingProgress += 2;
        // Animate wave heights
        _waveHeights = List.generate(30, (index) {
          return 0.3 + (Random().nextDouble() * 0.7);
        });
      });

      if (_recordingProgress >= 100) {
        _stopRecording();
      }
    });
  }

  void _stopRecording() {
    _recordingTimer?.cancel();
    _waveController.stop();
    
    setState(() {
      _isRecording = false;
    });

    // Simulate scoring with random result
    Future.delayed(const Duration(milliseconds: 300), () {
      final result = Random().nextInt(3); // 0-2 stars
      _processResult(result);
    });
  }

  void _processResult(int result) {
    HapticFeedback.mediumImpact();
    
    setState(() {
      _lastResult = result;
      _showResult = true;
      _stars += result + 1;
      
      if (result >= 1) {
        _correctCount++;
        _streak++;
        if (_streak > _maxStreak) _maxStreak = _streak;
        
        // Combo multiplier
        _comboMultiplier = 1 + (_streak ~/ 3);
        final baseXP = (result + 1) * 5;
        final earnedXP = baseXP * _comboMultiplier;
        
        _score += baseXP;
        _totalXP += earnedXP;
      } else {
        _streak = 0;
        _comboMultiplier = 1;
        HapticFeedback.heavyImpact();
      }
    });

    // Auto advance after showing result
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && _showResult) {
        _nextWord();
      }
    });
  }

  void _nextWord() {
    if (_currentIndex < _practiceVocabulary.length - 1) {
      setState(() {
        _currentIndex++;
        _showingPhonetics = false;
        _showResult = false;
        _lastResult = null;
        _recordingProgress = 0;
      });
      _generateWaveHeights();
      _playWord();
    } else {
      setState(() {
        _isComplete = true;
      });
    }
  }

  void _restartPractice() {
    setState(() {
      _currentIndex = 0;
      _score = 0;
      _totalXP = 0;
      _stars = 0;
      _correctCount = 0;
      _streak = 0;
      _maxStreak = 0;
      _comboMultiplier = 1;
      _showingPhonetics = false;
      _isComplete = false;
      _isRecording = false;
      _recordingProgress = 0;
      _showResult = false;
      _lastResult = null;
    });
    _prepareVocabulary();
    _generateWaveHeights();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: _isComplete ? _buildResultsScreen() : _buildPracticeScreen(),
    );
  }

  Widget _buildPracticeScreen() {
    final word = _practiceVocabulary[_currentIndex];
    final progress = (_currentIndex + 1) / _practiceVocabulary.length;

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
                  _buildWordCard(word),
                  const SizedBox(height: 32),
                  if (!_showResult) ...[
                    _buildVoiceVisualizer(),
                    const SizedBox(height: 32),
                    _buildRecordButton(),
                  ] else ...[
                    _buildResultOverlay(),
                  ],
                  const SizedBox(height: 24),
                  if (!_showingPhonetics && !_showResult)
                    _buildPhoneticsButton(),
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
            AppColors.accentCoral.withValues(alpha: 0.15),
            AppColors.accentOrange.withValues(alpha: 0.05),
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
                      'Pronunciation',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Word ${_currentIndex + 1} of ${_practiceVocabulary.length}',
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
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentCoral),
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

  Widget _buildWordCard(VocabularyItem word) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accentCoral,
            AppColors.accentOrange,
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentCoral.withValues(alpha: 0.4),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                word.word,
                style: const TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.volume_up, color: Colors.white, size: 32),
                onPressed: _playWord,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          if (_showingPhonetics && word.pronunciationIpa != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                word.pronunciationIpa!,
                style: TextStyle(
                  fontSize: 22,
                  color: Colors.white.withValues(alpha: 0.9),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'Means: ${word.translation}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).scale(delay: 100.ms);
  }

  Widget _buildVoiceVisualizer() {
    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: AnimatedBuilder(
        animation: _waveController,
        builder: (context, child) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _waveHeights.asMap().entries.map((entry) {
              final index = entry.key;
              final baseHeight = entry.value;
              
              double animatedHeight = baseHeight;
              if (_isRecording) {
                final phase = (_waveController.value * 2 * pi) + (index * 0.2);
                animatedHeight = baseHeight * (0.4 + 0.6 * sin(phase).abs());
              }
              
              return AnimatedContainer(
                duration: const Duration(milliseconds: 50),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: 6,
                height: 15 + (animatedHeight * 80),
                decoration: BoxDecoration(
                  color: _isRecording
                      ? AppColors.accentCoral.withValues(alpha: 0.8)
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildRecordButton() {
    return GestureDetector(
      onTap: _isRecording ? _stopRecording : _startRecording,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: _isRecording
              ? const LinearGradient(
                  colors: [Colors.red, Colors.redAccent],
                )
              : const LinearGradient(
                  colors: [
                    AppColors.accentCoral,
                    AppColors.accentOrange,
                  ],
                ),
          boxShadow: [
            BoxShadow(
              color: (_isRecording ? Colors.red : AppColors.accentCoral)
                  .withValues(alpha: 0.5),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (_isRecording)
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  value: _recordingProgress / 100,
                  strokeWidth: 4,
                  backgroundColor: Colors.white.withValues(alpha: 0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            Icon(
              _isRecording ? Icons.stop : Icons.mic,
              size: 48,
              color: Colors.white,
            ),
          ],
        ),
      ),
    )
    .animate()
    .scale(duration: 400.ms, curve: Curves.elasticOut)
    .then()
    .animate(onComplete: (controller) => controller.repeat(reverse: true))
    .scale(duration: 1000.ms, begin: const Offset(1, 1), end: const Offset(1.05, 1.05));
  }

  Widget _buildResultOverlay() {
    final result = _lastResult ?? 0;
    final colors = [
      Colors.red.shade400,      // 0 stars
      Colors.orange.shade400,   // 1 star  
      Colors.green.shade400,    // 2 stars
    ];
    final messages = [
      'Keep Practicing!',
      'Good Try!',
      'Perfect!',
    ];
    final icons = [
      Icons.refresh,
      Icons.thumb_up,
      Icons.emoji_events,
    ];

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: colors[result].withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colors[result].withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: colors[result],
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: colors[result].withValues(alpha: 0.4),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Icon(
              icons[result],
              color: Colors.white,
              size: 40,
            ),
          ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
          const SizedBox(height: 16),
          Text(
            messages[result],
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: colors[result],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  index <= result ? Icons.star : Icons.star_border,
                  color: index <= result ? Colors.amber : Colors.grey.shade300,
                  size: 36,
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          if (result >= 1)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.amber, Colors.orange],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '+${(result + 1) * 5 * _comboMultiplier} XP',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ).animate().shake(),
        ],
      ),
    ).animate().fadeIn().scale();
  }

  Widget _buildPhoneticsButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _showPhonetics,
        icon: const Icon(Icons.info_outline),
        label: const Text(
          'Show Pronunciation Guide',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.accentCoral,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
        ),
      ),
    );
  }

  Widget _buildResultsScreen() {
    final accuracy = _correctCount > 0
        ? (_correctCount / _practiceVocabulary.length * 100).round()
        : 0;
    final isPronunciationPro = accuracy >= 80 && _stars >= _practiceVocabulary.length * 2;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isPronunciationPro
              ? [AppColors.accentCoral.withValues(alpha: 0.2), Colors.white]
              : [Colors.grey.shade100, Colors.white],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              _buildResultsBadge(isPronunciationPro, accuracy),
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

  Widget _buildResultsBadge(bool isPronunciationPro, int accuracy) {
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
                    isPronunciationPro
                        ? AppColors.accentCoral.withValues(alpha: 0.3)
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
                gradient: isPronunciationPro
                    ? const LinearGradient(
                        colors: [
                          AppColors.accentCoral,
                          AppColors.accentOrange,
                        ],
                      )
                    : const LinearGradient(
                        colors: [Colors.orange, Colors.amber],
                      ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (isPronunciationPro ? AppColors.accentCoral : Colors.orange)
                        .withValues(alpha: 0.4),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(
                isPronunciationPro ? Icons.mic : Icons.record_voice_over,
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
          isPronunciationPro ? 'Pronunciation Pro!' : 'Practice Complete!',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: isPronunciationPro ? AppColors.accentCoral : AppColors.textDark,
          ),
        )
        .animate()
        .fadeIn(delay: 300.ms)
        .slideY(begin: 0.2, end: 0),
        
        const SizedBox(height: 8),
        
        Text(
          isPronunciationPro
              ? 'Your speaking skills are impressive!'
              : 'Keep practicing to improve your accent!',
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
                  icon: Icons.mic,
                  value: '$_correctCount',
                  label: 'Good',
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
                  icon: Icons.stars,
                  value: '$_stars',
                  label: 'Stars',
                  color: AppColors.accentCoral,
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
    final accuracy = (_practiceVocabulary.isNotEmpty ? _correctCount / _practiceVocabulary.length : 0).clamp(0.0, 1.0);
    return {
      'correct': _correctCount,
      'total': _practiceVocabulary.length,
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
            onPressed: _restartPractice,
            icon: const Icon(Icons.replay),
            label: const Text(
              'Practice Again',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentCoral,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 8,
              shadowColor: AppColors.accentCoral.withValues(alpha: 0.4),
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

