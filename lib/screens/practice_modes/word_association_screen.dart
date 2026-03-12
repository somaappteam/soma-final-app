import 'package:flutter/material.dart';
import 'dart:math';

/// Word Association Mode
/// Match words with their meanings in a grid
class WordAssociationScreen extends StatefulWidget {
  const WordAssociationScreen({super.key});

  @override
  State<WordAssociationScreen> createState() => _WordAssociationScreenState();
}

class _WordAssociationScreenState extends State<WordAssociationScreen> {
  int _score = 0;
  int _matches = 0;
  int _moves = 0;
  final int _timeElapsed = 0;
  bool _isGameComplete = false;
  
  String? _selectedWord;
  int? _selectedIndex;
  
  final List<Map<String, dynamic>> _wordPairs = [
    {'word': 'Gato', 'translation': 'Cat', 'emoji': '🐱'},
    {'word': 'Perro', 'translation': 'Dog', 'emoji': '🐶'},
    {'word': 'Casa', 'translation': 'House', 'emoji': '🏠'},
    {'word': 'Sol', 'translation': 'Sun', 'emoji': '☀️'},
    {'word': 'Luna', 'translation': 'Moon', 'emoji': '🌙'},
    {'word': 'Agua', 'translation': 'Water', 'emoji': '💧'},
  ];
  
  late List<GameCard> _cards;

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  void _initializeGame() {
    _cards = [];
    
    // Create pairs
    for (var pair in _wordPairs) {
      _cards.add(GameCard(
        id: '${pair['word']}_word',
        text: pair['word'],
        matchId: pair['word'],
        type: CardType.word,
        emoji: pair['emoji'],
      ));
      _cards.add(GameCard(
        id: '${pair['word']}_trans',
        text: pair['translation'],
        matchId: pair['word'],
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
          
          // Check if game complete
          if (_matches == _wordPairs.length) {
            _isGameComplete = true;
            _showWinDialog();
          }
        } else {
          // No match
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

  void _showWinDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Center(
          child: Text(
            '🎉 Perfect!',
            style: TextStyle(fontSize: 28),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildResultRow('Score', '$_score'),
            const SizedBox(height: 8),
            _buildResultRow('Moves', '$_moves'),
            const SizedBox(height: 8),
            _buildResultRow('Time', '$_timeElapsed sec'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Exit'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _score = 0;
                _matches = 0;
                _moves = 0;
                _isGameComplete = false;
                _initializeGame();
              });
            },
            child: const Text('Play Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade600)),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  _buildStatCard('Matches', '$_matches/${_wordPairs.length}', Colors.green),
                  _buildStatCard('Moves', '$_moves', Colors.blue),
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
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
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
              color: color.withOpacity(0.7),
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
                  colors: [Colors.green, Colors.lightGreen],
                )
              : card.isRevealed
                  ? const LinearGradient(
                      colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                    )
                  : LinearGradient(
                      colors: [
                        Colors.grey.shade800,
                        Colors.grey.shade900,
                      ],
                    ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: card.isRevealed || card.isMatched
              ? [
                  BoxShadow(
                    color: (card.isMatched ? Colors.green : const Color(0xFF667eea))
                        .withOpacity(0.4),
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
