import 'package:flutter/material.dart';
import 'dart:math';
import '../../models/vocabulary_item.dart';
import 'dart:async';
import '../../services/audio_service.dart';
import '../../widgets/practice_results_screen.dart';
import '../../theme/app_theme.dart';

/// Word Association Mode
/// Match words with their meanings in a grid
class WordAssociationScreen extends StatefulWidget {
  final List<VocabularyItem> vocabulary;
  final String targetLanguage;
  final String nativeLanguage;

  const WordAssociationScreen({
    super.key,
    required this.vocabulary,
    required this.targetLanguage,
    required this.nativeLanguage,
  });

  @override
  State<WordAssociationScreen> createState() => _WordAssociationScreenState();
}

class _WordAssociationScreenState extends State<WordAssociationScreen> {
  int _score = 0;
  int _matches = 0;
  int _moves = 0;
  Duration _timeElapsed = Duration.zero;
  Timer? _timer;
  bool _isGameComplete = false;
  
  String? _selectedWord;
  int? _selectedIndex;
  
  late List<Map<String, dynamic>> _wordPairs;
  late List<GameCard> _cards;

  @override
  void initState() {
    super.initState();
    _wordPairs = widget.vocabulary.take(6).map((v) => {
      'id': v.id,
      'word': v.word,
      'translation': v.translation,
      'emoji': null, // No emoji in VocabularyItem yet
    }).toList();
    _initializeGame();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && !_isGameComplete) {
        setState(() {
          _timeElapsed = Duration(seconds: _timeElapsed.inSeconds + 1);
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _initializeGame() {
    _cards = [];
    
    // Create pairs
    for (var pair in _wordPairs) {
      _cards.add(GameCard(
        id: '${pair['id']}_word',
        text: pair['word'],
        matchId: pair['id'],
        type: CardType.word,
        emoji: pair['emoji'],
      ));
      _cards.add(GameCard(
        id: '${pair['id']}_trans',
        text: pair['translation'],
        matchId: pair['id'],
        type: CardType.translation,
        emoji: pair['emoji'],
      ));
    }
    
    _cards.shuffle(Random());
  }

  void _onCardTap(int index) {
    if (_cards[index].isMatched || _cards[index].isRevealed) return;
    
    setState(() {
      _cards[index].isRevealed = true;
      _moves++;
      
      if (_selectedWord == null) {
        // First selection
        _selectedWord = _cards[index].matchId;
        _selectedIndex = index;
      } else {
        // Second selection
        if (_cards[index].matchId == _selectedWord && index != _selectedIndex) {
          // Match!
          _cards[index].isMatched = true;
          _cards[_selectedIndex!].isMatched = true;
          _matches++;
          _score += 100;
          AudioService().playCorrect();
          
          // Check if game complete
          if (_matches == _wordPairs.length) {
            _timer?.cancel();
            _isGameComplete = true;
          }
        } else {
          // No match
          AudioService().playWrong();
          Future.delayed(const Duration(milliseconds: 800), () {
            if (mounted) {
              setState(() {
                _cards[index].isRevealed = false;
                _cards[_selectedIndex!].isRevealed = false;
              });
            }
          });
        }
        
        _selectedWord = null;
        _selectedIndex = null;
      }
    });
  }

  Map<String, dynamic> _buildPracticeResult() {
    return {
      'correct': _matches,
      'total': _wordPairs.length,
      'accuracy': 1.0,
      'avgResponseSeconds': 0.0,
    };
  }

  void _replayGame() {
    setState(() {
      _score = 0;
      _matches = 0;
      _moves = 0;
      _isGameComplete = false;
      _timeElapsed = Duration.zero;
      _selectedWord = null;
      _selectedIndex = null;
      _initializeGame();
    });
    _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    if (_isGameComplete) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: PracticeResultsScreen(
          correctCount: _matches,
          totalCount: _wordPairs.length,
          xpEarned: _score,
          timeElapsed: _timeElapsed,
          bestStreak: 0,
          hasMistakes: true,
          replayButtonLabel: 'Play Again',
          onReplayMistakes: _replayGame,
          onContinueToNext: () => Navigator.pop(context, _buildPracticeResult()),
          onBackToHome: () => Navigator.of(context).popUntil((route) => route.isFirst),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Word Match'),
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
        child: Column(
          children: [
            // Progress
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatCard('Matches', '$_matches/${_wordPairs.length}', AppColors.success),
                  _buildStatCard('Moves', '$_moves', AppColors.primaryTeal),
                ],
              ),
            ),
            
            // Game grid
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _cards.length,
                  itemBuilder: (context, index) {
                    return _buildCard(index);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(int index) {
    final card = _cards[index];
    
    return GestureDetector(
      onTap: () => _onCardTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: card.isMatched
              ? const LinearGradient(
                  colors: [AppColors.success, Colors.lightGreen],
                )
              : card.isRevealed
                  ? const LinearGradient(
                      colors: [AppColors.primaryPurple, AppColors.secondaryPurple],
                    )
                  : const LinearGradient(
                      colors: [
                        AppColors.neutralDark,
                        AppColors.neutralDark,
                      ],
                    ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: card.isRevealed || card.isMatched
              ? [
                  BoxShadow(
                    color: (card.isMatched ? AppColors.success : AppColors.primaryPurple)
                        .withValues(alpha: 0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: card.isRevealed || card.isMatched
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (card.emoji != null)
                      Text(
                        card.emoji!,
                        style: const TextStyle(fontSize: 32),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      card.text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                )
              : const Icon(
                  Icons.help_outline,
                  color: Colors.white54,
                  size: 40,
                ),
        ),
      ),
    );
  }
}

class GameCard {
  final String id;
  final String text;
  final String matchId;
  final CardType type;
  final String? emoji;
  bool isRevealed;
  bool isMatched;

  GameCard({
    required this.id,
    required this.text,
    required this.matchId,
    required this.type,
    this.emoji,
    this.isRevealed = false,
    this.isMatched = false,
  });
}

enum CardType {
  word,
  translation,
}
