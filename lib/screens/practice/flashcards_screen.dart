import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/vocabulary_item.dart';
import '../../theme/app_theme.dart';
import '../../services/tts_service.dart';
import '../../services/audio_service.dart';
import '../../widgets/practice_results_screen.dart';

/// Premium Flashcards with Spaced Repetition System
/// 3D flip animations, gamification, and rich statistics
class FlashcardsScreen extends StatefulWidget {
  final List<VocabularyItem> vocabulary;
  final String targetLanguage;
  final String nativeLanguage;
  final String courseId;

  const FlashcardsScreen({
    super.key,
    required this.vocabulary,
    required this.targetLanguage,
    required this.nativeLanguage,
    this.courseId = 'demo',
  });

  @override
  State<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen>
    with TickerProviderStateMixin {
  // Card Data
  late List<CardSession> _cardSessions;
  int _currentIndex = 0;
  bool _isFlipped = false;
  bool _showTranslationFirst = false;
  
  // Game State
  int _score = 0;
  int _totalXP = 0;
  int _streak = 0;
  int _maxStreak = 0;
  int _comboMultiplier = 1;
  int _knownCount = 0;
  int _learningCount = 0;
  int _masteredCount = 0;
  bool _isComplete = false;
  Duration _timeElapsed = Duration.zero;
  Timer? _timer;
  
  // Animation Controllers
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _loadCardsAndStart();
    
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _flipController,
        curve: Curves.easeInOutCubic,
      ),
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-1.5, 0),
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeInOutCubic,
    ));
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    TtsService().stop();
    _flipController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
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

  void _loadCardsAndStart() {
    final items = List<VocabularyItem>.from(widget.vocabulary)..shuffle();
    final selected = items.take(15).toList();
    setState(() {
      _cardSessions = selected
          .map((v) => CardSession(
                vocabulary: v,
                difficulty: _calculateDifficulty(v.difficultyLevel),
              ))
          .toList();
    });
    _startTimer();
  }

  void _prepareCards() {
    _cardSessions = widget.vocabulary.map((vocab) => CardSession(
      vocabulary: vocab,
      difficulty: _calculateDifficulty(vocab.difficultyLevel),
    )).toList()..shuffle();
    
    if (_cardSessions.length > 15) {
      _cardSessions = _cardSessions.sublist(0, 15);
    }
  }

  DifficultyLevel _calculateDifficulty(int level) {
    if (level <= 1) return DifficultyLevel.easy;
    if (level <= 3) return DifficultyLevel.medium;
    return DifficultyLevel.hard;
  }

  void _flipCard() {
    HapticFeedback.lightImpact();
    
    if (_isFlipped) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }
    
    setState(() {
      _isFlipped = !_isFlipped;
    });
  }

  void _rateCard(CardRating rating) {
    HapticFeedback.mediumImpact();
    
    final currentSession = _cardSessions[_currentIndex];
    
    setState(() {
      currentSession.rating = rating;
      currentSession.reviewedAt = DateTime.now();
      
      if (rating == CardRating.good || rating == CardRating.easy) {
        AudioService().playCorrect();
      } else {
        AudioService().playWrong();
      }
      
      // Update counts
      switch (rating) {
        case CardRating.again:
          _learningCount++;
          _streak = 0;
          _comboMultiplier = 1;
          break;
        case CardRating.hard:
          _learningCount++;
          _streak = 0;
          _comboMultiplier = 1;
          break;
        case CardRating.good:
          _knownCount++;
          _streak++;
          if (_streak > _maxStreak) _maxStreak = _streak;
          break;
        case CardRating.easy:
          _masteredCount++;
          _streak++;
          if (_streak > _maxStreak) _maxStreak = _streak;
          break;
      }
      
      // Calculate XP
      _comboMultiplier = 1 + (_streak ~/ 3);
      final baseXP = _getXPForRating(rating);
      final earnedXP = baseXP * _comboMultiplier;
      _score += baseXP;
      _totalXP += earnedXP;
    });

    // Animate card away
    _slideController.forward().then((_) {
      _slideController.reset();
      _flipController.reset();
      
      setState(() {
        _isFlipped = false;
        
        if (_currentIndex < _cardSessions.length - 1) {
          _currentIndex++;
        } else {
          _timer?.cancel();
          _isComplete = true;
        }
      });
    });

    // Note: SRS updates are now handled centrally by PracticeModesScreen
  }

  int _getXPForRating(CardRating rating) {
    switch (rating) {
      case CardRating.again:
        return 5;
      case CardRating.hard:
        return 10;
      case CardRating.good:
        return 15;
      case CardRating.easy:
        return 20;
    }
  }

  void _replayMistakes() {
    setState(() {
      _cardSessions = _cardSessions
          .where((s) => s.rating == CardRating.again || s.rating == CardRating.hard)
          .toList();
      _cardSessions.shuffle();
      _currentIndex = 0;
      _isFlipped = false;
      _score = 0;
      _totalXP = 0;
      _streak = 0;
      _maxStreak = 0;
      _comboMultiplier = 1;
      _knownCount = 0;
      _learningCount = 0;
      _masteredCount = 0;
      _isComplete = false;
      _timeElapsed = Duration.zero;
    });
    _startTimer();
    _flipController.reset();
    _slideController.reset();
  }

  void _restartSession() {
    setState(() {
      _currentIndex = 0;
      _isFlipped = false;
      _score = 0;
      _totalXP = 0;
      _streak = 0;
      _maxStreak = 0;
      _comboMultiplier = 1;
      _knownCount = 0;
      _learningCount = 0;
      _masteredCount = 0;
      _isComplete = false;
      _timeElapsed = Duration.zero;
    });
    _prepareCards();
    _startTimer();
    _flipController.reset();
    _slideController.reset();
  }

  void _toggleSide() {
    setState(() {
      _showTranslationFirst = !_showTranslationFirst;
      _isFlipped = false;
      _flipController.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: _isComplete ? _buildResultsScreen() : _buildCardScreen(),
    );
  }

  Widget _buildCardScreen() {
    final cardSession = _cardSessions[_currentIndex];
    final card = cardSession.vocabulary;
    final progress = (_currentIndex + 1) / _cardSessions.length;

    return SafeArea(
      child: Column(
        children: [
          _buildPremiumAppBar(),
          _buildGameStatsBar(),
          _buildProgressSection(progress),
          Expanded(
            child: _buildCardArea(cardSession, card),
          ),
          if (_isFlipped) _buildRatingButtons(),
          if (!_isFlipped) _buildFlipHint(),
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
            AppColors.primaryTeal.withValues(alpha: 0.1),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
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
                  'Flashcards',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Spaced Repetition Practice',
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
              gradient: AppColors.tealGradient,
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
        color: Theme.of(context).cardTheme.color ?? Colors.white,
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
            color: AppColors.accentCoral,
            isActive: _streak > 0,
          ),
          if (_comboMultiplier > 1)
            _buildStatItem(
              icon: Icons.flash_on,
              value: 'x$_comboMultiplier',
              label: 'Combo',
              color: AppColors.darkAccentPurple,
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
                  color: isActive ? color : Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                label,
                style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection(double progress) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Card ${_currentIndex + 1}/${_cardSessions.length}',
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
                  color: AppColors.primaryTeal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryTeal),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 12),
          // Mastery stats
          Row(
            children: [
              _buildMasteryBadge('Again', _learningCount, AppColors.error),
              const SizedBox(width: 8),
              _buildMasteryBadge('Learning', _learningCount, AppColors.accentCoral),
              const SizedBox(width: 8),
              _buildMasteryBadge('Known', _knownCount, AppColors.primaryTeal),
              const SizedBox(width: 8),
              _buildMasteryBadge('Mastered', _masteredCount, AppColors.success),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMasteryBadge(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardArea(CardSession session, VocabularyItem card) {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: GestureDetector(
            onTap: _flipCard,
            child: AnimatedBuilder(
              animation: _flipAnimation,
              builder: (context, child) {
                final angle = _flipAnimation.value * pi;
                final isFront = angle < pi / 2;
                
                return Transform(
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.0015)
                    ..rotateY(angle),
                  alignment: Alignment.center,
                  child: isFront
                      ? _buildCardFront(card)
                      : Transform(
                          transform: Matrix4.identity()..rotateY(pi),
                          alignment: Alignment.center,
                          child: _buildCardBack(card),
                        ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildCardFront(VocabularyItem card) {
    final displayText = _showTranslationFirst ? card.translation : card.word;
    final subText = _showTranslationFirst
        ? widget.targetLanguage == 'es' ? 'Spanish' : widget.targetLanguage
        : widget.nativeLanguage == 'en' ? 'English' : widget.nativeLanguage;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).cardTheme.color ?? Colors.white,
            Theme.of(context).colorScheme.surfaceContainerHighest,
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryTeal.withValues(alpha: 0.15 + (_pulseController.value * 0.1)),
            blurRadius: 30 + (_pulseController.value * 10),
            offset: const Offset(0, 15),
            spreadRadius: -5,
          ),
        ],
        border: Border.all(
          color: AppColors.primaryTeal.withValues(alpha: 0.2),
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // Background pattern
            CustomPaint(
              size: Size.infinite,
              painter: CardPatternPainter(),
            ),
            // Content
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Language badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: AppColors.tealGradient,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryTeal.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        subText.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Main word
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            displayText,
                            style: TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.volume_up, color: AppColors.primaryTeal),
                          onPressed: () {
                            TtsService().speak(
                              displayText,
                              languageCode: _showTranslationFirst ? widget.nativeLanguage : widget.targetLanguage,
                              context: context,
                            );
                          },
                        ),
                      ],
                    ),
                    if (card.pronunciationIpa != null && !_showTranslationFirst) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.neutralLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          card.pronunciationIpa!,
                          style: TextStyle(
                            fontSize: 20,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 40),
                    // Difficulty indicator
                    _buildDifficultyIndicator(card.difficultyLevel),
                    const SizedBox(height: 24),
                    // Tap hint
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Opacity(
                          opacity: 0.5 + (_pulseController.value * 0.5),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.touch_app,
                                color: AppColors.textMedium,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Tap to flip',
                                style: TextStyle(
                                  color: AppColors.textMedium,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardBack(VocabularyItem card) {
    final displayText = _showTranslationFirst ? card.word : card.translation;
    final subText = _showTranslationFirst
        ? widget.nativeLanguage == 'en' ? 'English' : widget.nativeLanguage
        : widget.targetLanguage == 'es' ? 'Spanish' : widget.targetLanguage;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        gradient: AppColors.tealGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryTeal.withValues(alpha: 0.4),
            blurRadius: 30,
            offset: const Offset(0, 15),
            spreadRadius: -5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // Background pattern
            CustomPaint(
              size: Size.infinite,
              painter: CardPatternPainter(isDark: true),
            ),
            // Content
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Language badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        subText.toUpperCase(),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Translation
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            displayText,
                            style: const TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.volume_up, color: Colors.white),
                          onPressed: () {
                            TtsService().speak(
                              displayText,
                              languageCode: _showTranslationFirst ? widget.targetLanguage : widget.nativeLanguage,
                              context: context,
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Example sentence
                    if (card.exampleSentences.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.format_quote,
                              color: Colors.white54,
                              size: 24,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '"${card.exampleSentences.first}"',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white.withValues(alpha: 0.95),
                                fontStyle: FontStyle.italic,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyIndicator(int level) {
    final color = level <= 1
        ? AppColors.success
        : level <= 3
            ? AppColors.accentCoral
            : AppColors.error;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.signal_cellular_alt,
          color: color,
          size: 16,
        ),
        const SizedBox(width: 6),
        Text(
          'Level $level',
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildFlipHint() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          TextButton.icon(
            onPressed: _toggleSide,
            icon: const Icon(Icons.swap_horiz),
            label: Text(_showTranslationFirst ? 'Show Word First' : 'Show Translation First'),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingButtons() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
              'How well did you know this?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textMedium,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildRatingButton(
                    label: 'Again',
                    subtitle: '< 1m',
                    color: AppColors.error,
                    icon: Icons.refresh,
                    onTap: () => _rateCard(CardRating.again),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildRatingButton(
                    label: 'Hard',
                    subtitle: '< 6m',
                    color: AppColors.accentCoral,
                    icon: Icons.sentiment_dissatisfied,
                    onTap: () => _rateCard(CardRating.hard),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildRatingButton(
                    label: 'Good',
                    subtitle: '10m',
                    color: AppColors.primaryTeal,
                    icon: Icons.thumb_up,
                    onTap: () => _rateCard(CardRating.good),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildRatingButton(
                    label: 'Easy',
                    subtitle: '4d',
                    color: AppColors.success,
                    icon: Icons.sentiment_very_satisfied,
                    onTap: () => _rateCard(CardRating.easy),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingButton({
    required String label,
    required String subtitle,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color, color.withValues(alpha: 0.8)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsScreen() {
    final correctCount = _knownCount + _masteredCount;
    final hasMistakes = _learningCount > 0;

    return PracticeResultsScreen(
      correctCount: correctCount,
      totalCount: _cardSessions.length,
      xpEarned: _totalXP,
      timeElapsed: _timeElapsed,
      bestStreak: _maxStreak,
      hasMistakes: hasMistakes,
      onReplayMistakes: _replayMistakes,
      onContinueToNext: () => Navigator.pop(context, _buildPracticeResult()),
      onBackToHome: () => Navigator.of(context).popUntil((route) => route.isFirst),
    );
  }

  Map<String, dynamic> _buildPracticeResult() {
    final accuracy = (_cardSessions.isNotEmpty ? (_knownCount + _masteredCount) / _cardSessions.length : 0).clamp(0.0, 1.0);
    
    // Build word-level performance map
    final Map<String, bool> wordPerformance = {};
    for (final session in _cardSessions) {
      if (session.rating != null) {
        // Considered correct if rated 'good' or 'easy'
        wordPerformance[session.vocabulary.id] = session.rating == CardRating.good || session.rating == CardRating.easy;
      }
    }
    
    return {
      'correct': _knownCount + _masteredCount,
      'total': _cardSessions.length,
      'accuracy': accuracy,
      'avgResponseSeconds': 0.0,
      'wordPerformance': wordPerformance,
    };
  }
}

enum DifficultyLevel { easy, medium, hard }
enum CardRating { again, hard, good, easy }

class CardSession {
  final VocabularyItem vocabulary;
  final DifficultyLevel difficulty;
  CardRating? rating;
  DateTime? reviewedAt;

  CardSession({
    required this.vocabulary,
    required this.difficulty,
    this.rating,
    this.reviewedAt,
  });
}

class CardPatternPainter extends CustomPainter {
  final bool isDark;

  CardPatternPainter({this.isDark = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (isDark ? Colors.white : AppColors.primaryTeal).withValues(alpha: 0.03)
      ..strokeWidth = 1;
    
    const spacing = 40.0;
    
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

