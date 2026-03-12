import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/vocabulary_item.dart';
import '../../theme/app_theme.dart';

/// Premium Word Match Game
/// Memory-style matching game with rich animations and gamification
class WordMatchGame extends StatefulWidget {
  final List<VocabularyItem> vocabulary;
  final String targetLanguage;
  final String nativeLanguage;

  const WordMatchGame({
    super.key,
    required this.vocabulary,
    required this.targetLanguage,
    required this.nativeLanguage,
  });

  @override
  State<WordMatchGame> createState() => _WordMatchGameState();
}

class _WordMatchGameState extends State<WordMatchGame>
    with TickerProviderStateMixin {
  // Game Data
  late List<VocabularyItem> _gameVocabulary;
  late List<WordCard> _wordCards;
  late List<WordCard> _translationCards;
  
  // Game State
  WordCard? _selectedWord;
  WordCard? _selectedTranslation;
  int _matches = 0;
  int _score = 0;
  int _totalXP = 0;
  int _streak = 0;
  int _maxStreak = 0;
  int _comboMultiplier = 1;
  int _attempts = 0;
  bool _isComplete = false;
  bool _isProcessing = false;
  Duration _timeElapsed = Duration.zero;
  Timer? _timer;
  
  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _setupGame();
    _startTimer();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _shakeController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isComplete && mounted) {
        setState(() {
          _timeElapsed = Duration(seconds: _timeElapsed.inSeconds + 1);
        });
      }
    });
  }

  void _setupGame() {
    final random = Random();
    
    // Select 8 vocabulary items for a good challenge
    _gameVocabulary = [...widget.vocabulary]..shuffle(random);
    _gameVocabulary = _gameVocabulary.take(8).toList();

    // Create word cards
    _wordCards = _gameVocabulary.map((v) => WordCard(
      id: v.id,
      text: v.word,
      type: CardType.word,
      vocabulary: v,
    )).toList();

    // Create translation cards
    _translationCards = _gameVocabulary.map((v) => WordCard(
      id: v.id,
      text: v.translation,
      type: CardType.translation,
      vocabulary: v,
    )).toList();

    // Shuffle translations
    _translationCards.shuffle(random);
  }

  void _selectCard(WordCard card) {
    if (_isProcessing || card.isMatched) return;
    if ((card.type == CardType.word && _selectedWord?.id == card.id) ||
        (card.type == CardType.translation && _selectedTranslation?.id == card.id)) {
      return;
    }

    HapticFeedback.lightImpact();

    setState(() {
      if (card.type == CardType.word) {
        _selectedWord = card;
      } else {
        _selectedTranslation = card;
      }
    });

    // Check for match if both selected
    if (_selectedWord != null && _selectedTranslation != null) {
      _checkMatch();
    }
  }

  void _checkMatch() {
    _isProcessing = true;
    _attempts++;

    final isCorrect = _selectedWord!.id == _selectedTranslation!.id;

    if (isCorrect) {
      // Correct match!
      HapticFeedback.mediumImpact();
      
      Future.delayed(const Duration(milliseconds: 300), () {
        setState(() {
          _selectedWord!.isMatched = true;
          _selectedTranslation!.isMatched = true;
          _matches++;
          
          _streak++;
          if (_streak > _maxStreak) _maxStreak = _streak;
          
          // Combo system
          _comboMultiplier = 1 + (_streak ~/ 2);
          const baseXP = 15;
          final earnedXP = baseXP * _comboMultiplier;
          
          _score += 15;
          _totalXP += earnedXP;
          
          _selectedWord = null;
          _selectedTranslation = null;
          _isProcessing = false;
        });

        // Check completion
        if (_matches == _gameVocabulary.length) {
          _timer?.cancel();
          Future.delayed(const Duration(milliseconds: 800), () {
            if (mounted) {
              setState(() {
                _isComplete = true;
              });
            }
          });
        }
      });
    } else {
      // Wrong match
      HapticFeedback.heavyImpact();
      _shakeController.forward(from: 0);
      
      Future.delayed(const Duration(milliseconds: 800), () {
        setState(() {
          _streak = 0;
          _comboMultiplier = 1;
          _selectedWord = null;
          _selectedTranslation = null;
          _isProcessing = false;
        });
      });
    }
  }

  void _restartGame() {
    setState(() {
      _selectedWord = null;
      _selectedTranslation = null;
      _matches = 0;
      _score = 0;
      _totalXP = 0;
      _streak = 0;
      _maxStreak = 0;
      _comboMultiplier = 1;
      _attempts = 0;
      _isComplete = false;
      _isProcessing = false;
      _timeElapsed = Duration.zero;
    });
    _setupGame();
    _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: _isComplete ? _buildResultsScreen() : _buildGameScreen(),
    );
  }

  Widget _buildGameScreen() {
    final progress = _matches / _gameVocabulary.length;

    return SafeArea(
      child: Column(
        children: [
          _buildPremiumAppBar(),
          _buildGameStatsBar(),
          _buildProgressBar(progress),
          Expanded(
            child: _buildGameGrid(),
          ),
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
            AppColors.accentCoral.withValues(alpha: 0.15),
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
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Word Match',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Match words to meanings',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMedium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: AppColors.coralGradient,
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
            value: '${_timeElapsed.inMinutes}:${(_timeElapsed.inSeconds % 60).toString().padLeft(2, '0')}',
            label: 'Time',
            color: AppColors.textMedium,
            isActive: false,
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

  Widget _buildProgressBar(double progress) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$_matches/${_gameVocabulary.length} matched',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMedium,
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accentCoral,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentCoral),
              minHeight: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameGrid() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          // Words Column
          Expanded(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  decoration: BoxDecoration(
                    gradient: AppColors.coralGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.translate, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'WORDS',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    itemCount: _wordCards.length,
                    itemBuilder: (context, index) {
                      return _buildCard(_wordCards[index], index);
                    },
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Connection Icon
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Icon(
              Icons.compare_arrows,
              color: AppColors.textMedium.withValues(alpha: 0.5),
              size: 28,
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Meanings Column
          Expanded(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  decoration: BoxDecoration(
                    gradient: AppColors.tealGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.menu_book, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'MEANINGS',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    itemCount: _translationCards.length,
                    itemBuilder: (context, index) {
                      return _buildCard(_translationCards[index], index);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(WordCard card, int index) {
    final isSelected = (_selectedWord?.id == card.id && card.type == CardType.word) ||
                       (_selectedTranslation?.id == card.id && card.type == CardType.translation);
    final isMatched = card.isMatched;
    final isWrong = _isProcessing && isSelected && !isMatched;

    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        final shakeOffset = isWrong
            ? sin(_shakeController.value * pi * 4) * 4
            : 0.0;
        
        return Transform.translate(
          offset: Offset(shakeOffset, 0),
          child: GestureDetector(
            onTap: () => _selectCard(card),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: isMatched
                    ? const LinearGradient(
                        colors: [Colors.green, Colors.greenAccent],
                      )
                    : isSelected
                        ? (card.type == CardType.word
                            ? AppColors.coralGradient
                            : AppColors.tealGradient)
                        : const LinearGradient(
                            colors: [Colors.white, Colors.white],
                          ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isMatched
                      ? Colors.green
                      : isSelected
                          ? Colors.transparent
                          : Colors.grey.shade200,
                  width: 2,
                ),
                boxShadow: [
                  if (!isMatched)
                    BoxShadow(
                      color: isSelected
                          ? (card.type == CardType.word
                              ? AppColors.accentCoral
                              : AppColors.primaryTeal).withValues(alpha: 0.3)
                          : Colors.black.withValues(alpha: 0.05),
                      blurRadius: isSelected ? 15 : 8,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      card.text,
                      style: TextStyle(
                        color: isMatched || isSelected
                            ? Colors.white
                            : AppColors.textDark,
                        fontSize: 15,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        decoration: isMatched ? TextDecoration.lineThrough : null,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (isMatched)
                    const Icon(Icons.check_circle, color: Colors.white, size: 20)
                    .animate()
                    .scale(duration: 300.ms)
                    .fadeIn(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildResultsScreen() {
    final accuracy = _attempts > 0 ? (_matches / _attempts * 100).round() : 0;
    final isPerfect = _matches == _gameVocabulary.length && _attempts == _matches;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isPerfect
              ? [Colors.amber.shade100, Colors.white]
              : [AppColors.accentCoral.withValues(alpha: 0.1), Colors.white],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              _buildResultsBadge(isPerfect),
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

  Widget _buildResultsBadge(bool isPerfect) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    isPerfect
                        ? Colors.amber.withValues(alpha: 0.3)
                        : AppColors.accentCoral.withValues(alpha: 0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                gradient: isPerfect
                    ? const LinearGradient(
                        colors: [Colors.amber, Colors.orange],
                      )
                    : AppColors.coralGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (isPerfect ? Colors.amber : AppColors.accentCoral)
                        .withValues(alpha: 0.4),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(
                isPerfect ? Icons.emoji_events : Icons.compare_arrows,
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
          isPerfect ? 'Perfect Match!' : 'Great Job!',
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
              ? 'Perfect accuracy! You\'re a memory master!'
              : 'All pairs matched! Keep practicing!',
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
                  value: '$_matches',
                  label: 'Matched',
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
                  icon: Icons.timer,
                  value: '${_timeElapsed.inMinutes}:${(_timeElapsed.inSeconds % 60).toString().padLeft(2, '0')}',
                  label: 'Time',
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
                      color: accuracy >= 80 ? Colors.green : AppColors.accentCoral,
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
                    accuracy >= 80 ? Colors.green : AppColors.accentCoral,
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
    final accuracy = (_attempts > 0 ? _matches / _attempts : 0).clamp(0.0, 1.0);
    return {
      'correct': _matches,
      'total': _attempts > 0 ? _attempts : widget.vocabulary.length,
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

enum CardType { word, translation }

class WordCard {
  final String id;
  final String text;
  final CardType type;
  final VocabularyItem vocabulary;
  bool isMatched;

  WordCard({
    required this.id,
    required this.text,
    required this.type,
    required this.vocabulary,
    this.isMatched = false,
  });
}

class WordMatchLauncher extends StatelessWidget {
  final List<VocabularyItem> vocabulary;
  final String targetLanguage;
  final String nativeLanguage;

  const WordMatchLauncher({
    super.key,
    required this.vocabulary,
    required this.targetLanguage,
    required this.nativeLanguage,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: AppColors.coralGradient,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentCoral.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.compare_arrows,
                  size: 60,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Word Match',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Match words with their translations!\nTap cards to find pairs.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textMedium,
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _startGame(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentCoral,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 8,
                    shadowColor: AppColors.accentCoral.withValues(alpha: 0.4),
                  ),
                  child: const Text(
                    'START GAME',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context, _buildPracticeResult()),
                child: const Text(
                  'Back',
                  style: TextStyle(
                    color: AppColors.textMedium,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startGame(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WordMatchGame(
          vocabulary: vocabulary,
          targetLanguage: targetLanguage,
          nativeLanguage: nativeLanguage,
        ),
      ),
    );
  }
}

