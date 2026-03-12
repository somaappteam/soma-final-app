import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/vocabulary_item.dart';
import '../../theme/app_theme.dart';

/// Premium Falling Words Game
/// Arcade-style vocabulary game with rich animations and gamification
class FallingWordsGame extends StatefulWidget {
  final List<VocabularyItem> vocabulary;
  final String targetLanguage;
  final String nativeLanguage;
  final int durationSeconds;

  const FallingWordsGame({
    super.key,
    required this.vocabulary,
    required this.targetLanguage,
    required this.nativeLanguage,
    this.durationSeconds = 60,
  });

  @override
  State<FallingWordsGame> createState() => _FallingWordsGameState();
}

class _FallingWordsGameState extends State<FallingWordsGame>
    with TickerProviderStateMixin {
  // Game State
  final List<FallingWord> _fallingWords = [];
  final Random _random = Random();
  
  int _score = 0;
  int _totalXP = 0;
  int _streak = 0;
  int _maxStreak = 0;
  int _comboMultiplier = 1;
  int _correctMatches = 0;
  int _missedWords = 0;
  int _timeRemaining = 60;
  bool _isGameActive = false;
  bool _isPaused = false;
  bool _isGameOver = false;
  Duration _timeElapsed = Duration.zero;
  
  // Target word to match
  VocabularyItem? _targetWord;
  List<String> _currentOptions = [];
  
  // Game mechanics
  double _fallSpeed = 2.5;
  Timer? _spawnTimer;
  Timer? _gameTimer;
  Timer? _elapsedTimer;
  
  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _timeRemaining = widget.durationSeconds;
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _startGame();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _shakeController.dispose();
    _spawnTimer?.cancel();
    _gameTimer?.cancel();
    _elapsedTimer?.cancel();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      _isGameActive = true;
      _isPaused = false;
      _score = 0;
      _totalXP = 0;
      _streak = 0;
      _maxStreak = 0;
      _comboMultiplier = 1;
      _correctMatches = 0;
      _missedWords = 0;
      _timeRemaining = widget.durationSeconds;
      _fallingWords.clear();
      _fallSpeed = 2.5;
      _isGameOver = false;
      _timeElapsed = Duration.zero;
    });

    _spawnTimer = Timer.periodic(
      const Duration(milliseconds: 2500),
      (_) => _spawnWord(),
    );
    
    _gameTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (_timeRemaining > 0 && !_isPaused) {
          setState(() {
            _timeRemaining--;
            // Increase difficulty
            if (_timeRemaining % 10 == 0 && _fallSpeed < 5.0) {
              _fallSpeed += 0.3;
            }
          });
        } else if (_timeRemaining == 0) {
          _endGame();
        }
      },
    );

    _elapsedTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (!_isPaused && _isGameActive) {
          setState(() {
            _timeElapsed = Duration(seconds: _timeElapsed.inSeconds + 1);
          });
        }
      },
    );

    // Initial spawn
    Future.delayed(const Duration(milliseconds: 500), () {
      _spawnWord();
      _setNewTarget();
    });
  }

  void _spawnWord() {
    if (_fallingWords.isNotEmpty || !_isGameActive || _isPaused || !mounted) return;

    final vocabItem = widget.vocabulary[_random.nextInt(widget.vocabulary.length)];
    
    setState(() {
      _fallingWords.clear();
      _fallingWords.add(
        FallingWord(
          vocabulary: vocabItem,
          x: _random.nextDouble() * 0.75 + 0.125,
          y: -0.1,
          speed: _fallSpeed + _random.nextDouble() * 0.8,
          id: DateTime.now().millisecondsSinceEpoch.toString(),
        ),
      );
    });
  }

  void _setNewTarget() {
    if (_fallingWords.isEmpty) {
      // Spawn a word if none exist
      Future.delayed(const Duration(milliseconds: 500), () {
        if (_fallingWords.isEmpty && _isGameActive) {
          _spawnWord();
        }
      });
      return;
    }

    // Single active falling word is always the target
    final target = _fallingWords.first;
    setState(() {
      _targetWord = target.vocabulary;
    });
    
    _generateOptions();
  }

  void _generateOptions() {
    if (_targetWord == null) return;

    final options = <String>[_targetWord!.translation];
    final otherWords = widget.vocabulary
        .where((w) => w.id != _targetWord!.id)
        .toList();
    
    otherWords.shuffle();
    options.addAll(otherWords.take(3).map((w) => w.translation));
    options.shuffle();

    setState(() {
      _currentOptions = options;
    });
  }

  void _checkMatch(String selectedTranslation) {
    if (_targetWord == null || _isPaused) return;

    if (selectedTranslation == _targetWord!.translation) {
      // Correct match!
      HapticFeedback.mediumImpact();
      
      setState(() {
        _fallingWords.clear();
        _streak++;
        if (_streak > _maxStreak) _maxStreak = _streak;
        
        // Combo system
        _comboMultiplier = 1 + (_streak ~/ 3);
        final earnedXP = 10 * _comboMultiplier;
        
        _score += 10;
        _totalXP += earnedXP;
        _correctMatches++;
      });

      _spawnWord();
      _setNewTarget();
    } else {
      // Wrong match
      HapticFeedback.heavyImpact();
      _shakeController.forward(from: 0);
      
      setState(() {
        _streak = 0;
        _comboMultiplier = 1;
        _score = _score > 5 ? _score - 5 : 0;
      });
    }
  }

  void _updateGame() {
    if (_isPaused || !_isGameActive) return;

    setState(() {
      for (var word in _fallingWords) {
        word.y += word.speed * 0.003;
        
        // Word reached bottom
        if (word.y > 0.75 && !word.isMissed) {
          word.isMissed = true;
          _missedWords++;
          _streak = 0;
          _comboMultiplier = 1;

          // Remove after delay
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              setState(() {
                _fallingWords.clear();
                _targetWord = null;
                _currentOptions = [];
              });
              _spawnWord();
              _setNewTarget();
            }
          });
        }
      }
    });
  }

  void _endGame() {
    _spawnTimer?.cancel();
    _gameTimer?.cancel();
    _elapsedTimer?.cancel();
    
    setState(() {
      _isGameActive = false;
      _isGameOver = true;
    });
  }

  void _restartGame() {
    _startGame();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: _isGameOver ? _buildResultsScreen() : _buildGameScreen(),
    );
  }

  Widget _buildGameScreen() {
    return SafeArea(
      child: Column(
        children: [
          _buildPremiumAppBar(),
          _buildGameStatsBar(),
          if (_targetWord != null) _buildTargetDisplay(),
          Expanded(
            child: _buildGameArea(),
          ),
          _buildOptionsPanel(),
        ],
      ),
    );
  }

  Widget _buildPremiumAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF667eea).withValues(alpha: 0.15),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
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
                const Text(
                  'Falling Words',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: _timeRemaining / widget.durationSeconds,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _timeRemaining <= 10 ? Colors.red : const Color(0xFF667eea),
                    ),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
              borderRadius: BorderRadius.circular(12),
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
    );
  }

  Widget _buildGameStatsBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: Icons.local_fire_department,
            value: '$_streak',
            label: 'Streak',
            color: Colors.orange,
            isActive: _streak > 0,
          ),
          if (_comboMultiplier > 1)
            _buildStatItem(
              icon: Icons.flash_on,
              value: 'x$_comboMultiplier',
              label: 'Combo',
              color: Colors.purple,
              isActive: true,
            )
            .animate()
            .scale(duration: 200.ms)
            .shake(hz: 3),
          _buildStatItem(
            icon: Icons.timer,
            value: '$_timeRemaining',
            label: 'Sec',
            color: _timeRemaining <= 10 ? Colors.red : AppColors.textMedium,
            isActive: _timeRemaining <= 10,
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _isPaused = !_isPaused;
              });
            },
            icon: Icon(
              _isPaused ? Icons.play_arrow : Icons.pause,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required bool isActive,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? color.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isActive ? Border.all(color: color.withValues(alpha: 0.3), width: 2) : null,
      ),
      child: Row(
        children: [
          Icon(icon, color: isActive ? color : AppColors.textMedium, size: 20),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isActive ? color : AppColors.textDark,
                ),
              ),
              Text(
                label,
                style: const TextStyle(fontSize: 10, color: AppColors.textMedium),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTargetDisplay() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF667eea),
                Color(0xFF764ba2),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF667eea).withValues(alpha: 0.3 + (_pulseController.value * 0.2)),
                blurRadius: 20 + (_pulseController.value * 10),
                spreadRadius: -2,
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                'CATCH THE TRANSLATION FOR:',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _targetWord!.word,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_targetWord!.pronunciationIpa != null) ...[
                const SizedBox(height: 4),
                Text(
                  '/${_targetWord!.pronunciationIpa}/',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildGameArea() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Update game loop
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _updateGame();
        });

        return Stack(
          children: [
            // Background grid pattern
            CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              painter: GridPainter(),
            ),
            
            // Falling words
            ..._fallingWords.map((word) => _buildFallingWord(word, constraints)),
            
            // Pause overlay
            if (_isPaused)
              Container(
                color: Colors.black.withValues(alpha: 0.7),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.pause_circle_filled,
                        size: 80,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'PAUSED',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap anywhere to resume',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildFallingWord(FallingWord word, BoxConstraints constraints) {
    final x = word.x * constraints.maxWidth;
    final y = word.y * constraints.maxHeight;

    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        final isTarget = _targetWord?.id == word.vocabulary.id;
        
        return Positioned(
          left: x,
          top: y,
          child: Transform.translate(
            offset: word.isMissed 
                ? Offset(sin(_shakeController.value * pi * 8) * 5, 0)
                : Offset.zero,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: word.isMissed
                      ? [Colors.red.shade400, Colors.red.shade600]
                      : isTarget
                          ? [Colors.amber.shade400, Colors.orange.shade500]
                          : [Colors.white, Colors.grey.shade100],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: (word.isMissed 
                            ? Colors.red 
                            : isTarget 
                                ? Colors.amber 
                                : Colors.grey)
                        .withValues(alpha: 0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(
                  color: isTarget 
                      ? Colors.amber.shade300 
                      : Colors.transparent,
                  width: 3,
                ),
              ),
              child: Text(
                word.vocabulary.translation,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: word.isMissed || isTarget
                      ? Colors.white
                      : AppColors.textDark,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOptionsPanel() {
    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(sin(_shakeController.value * pi * 4) * 3, 0),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 30,
                  offset: const Offset(0, -10),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Tap the correct translation:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMedium,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: _currentOptions.map((option) {
                      return ElevatedButton(
                        onPressed: _isPaused ? null : () => _checkMatch(option),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF667eea),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 6,
                          shadowColor: const Color(0xFF667eea).withValues(alpha: 0.4),
                        ),
                        child: Text(
                          option,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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
      },
    );
  }

  Widget _buildResultsScreen() {
    final accuracy = _correctMatches + _missedWords > 0
        ? (_correctMatches / (_correctMatches + _missedWords) * 100).round()
        : 0;
    final isPerfect = _missedWords == 0 && _correctMatches > 0;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isPerfect
              ? [Colors.amber.shade100, Colors.white]
              : [const Color(0xFF667eea).withValues(alpha: 0.1), Colors.white],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              _buildResultsBadge(isPerfect, accuracy),
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

  Widget _buildResultsBadge(bool isPerfect, int accuracy) {
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
                    isPerfect
                        ? Colors.amber.withValues(alpha: 0.3)
                        : const Color(0xFF667eea).withValues(alpha: 0.3),
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
                gradient: isPerfect
                    ? const LinearGradient(
                        colors: [Colors.amber, Colors.orange],
                      )
                    : const LinearGradient(
                        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                      ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (isPerfect ? Colors.amber : const Color(0xFF667eea))
                        .withValues(alpha: 0.4),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(
                isPerfect ? Icons.emoji_events : Icons.arrow_downward,
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
          isPerfect ? 'Perfect Game!' : 'Game Over!',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: isPerfect ? Colors.amber.shade700 : AppColors.textDark,
          ),
        )
        .animate()
        .fadeIn(delay: 300.ms)
        .slideY(begin: 0.2, end: 0),
        
        const SizedBox(height: 8),
        
        Text(
          isPerfect
              ? 'You caught every word! Amazing reflexes!'
              : 'Great effort! Practice makes perfect.',
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
                  icon: Icons.check_circle,
                  value: '$_correctMatches',
                  label: 'Caught',
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildResultStatCard(
                  icon: Icons.star,
                  value: '$_totalXP',
                  label: 'XP Earned',
                  color: Colors.amber,
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
                  icon: Icons.close,
                  value: '$_missedWords',
                  label: 'Missed',
                  color: Colors.red,
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
                      color: accuracy >= 80 ? Colors.green : AppColors.primaryTeal,
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
                    accuracy >= 80 ? Colors.green : AppColors.primaryTeal,
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
    final total = _correctMatches + _missedWords;
    final accuracy = total > 0 ? (_correctMatches / total).clamp(0.0, 1.0) : 0.0;
    return {
      'correct': _correctMatches,
      'total': total,
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
            onPressed: _restartGame,
            icon: const Icon(Icons.replay),
            label: const Text(
              'Play Again',
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
              elevation: 8,
              shadowColor: const Color(0xFF667eea).withValues(alpha: 0.4),
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

class FallingWord {
  final VocabularyItem vocabulary;
  double x;
  double y;
  double speed;
  final String id;
  bool isMissed;

  FallingWord({
    required this.vocabulary,
    required this.x,
    required this.y,
    required this.speed,
    required this.id,
    this.isMissed = false,
  });
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.1)
      ..strokeWidth = 1;
    
    const spacing = 50.0;
    
    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    
    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
