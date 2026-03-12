import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/live_game_service.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';
import '../profile/public_profile_screen.dart';

/// Premium Live Game Play Screen - Real-time Multiplayer Experience
/// Features: Live leaderboard, countdown timers, power-ups, streaks, animations
class LiveGamePlayScreen extends StatefulWidget {
  final String gameId;
  final Map<String, dynamic> gameData;

  const LiveGamePlayScreen({
    super.key,
    required this.gameId,
    required this.gameData,
  });

  @override
  State<LiveGamePlayScreen> createState() => _LiveGamePlayScreenState();
}

class _LiveGamePlayScreenState extends State<LiveGamePlayScreen>
    with TickerProviderStateMixin {
  final LiveGameService _gameService = LiveGameService();
  final SupabaseService _supabase = SupabaseService();
  
  // Game State
  bool _isLoading = true;
  bool _isGameActive = false;
  bool _isPaused = false;
  bool _showCountdown = true;
  int _countdownValue = 3;
  
  // Question State
  int _currentQuestionIndex = 0;
  Map<String, dynamic>? _currentQuestion;
  List<Map<String, dynamic>> _questions = [];
  
  // Player State
  String? _userId;
  int _myScore = 0;
  int _myStreak = 0;
  int _myRank = 1;
  int _correctAnswers = 0;
  int _wrongAnswers = 0;
  
  // Power-ups
  bool _hasDoublePoints = false;
  bool _hasTimeFreeze = false;
  bool _hasFiftyFifty = false;
  bool _doublePointsActive = false;
  bool _fiftyFiftyUsed = false;
  
  // Timer
  late int _timeLimit;
  double _timeLeft = 0;
  Timer? _timer;
  Timer? _countdownTimer;
  DateTime? _questionStartTime;
  
  // Leaderboard
  List<Map<String, dynamic>> _leaderboard = [];
  StreamSubscription? _gameSubscription;
  StreamSubscription? _playersSubscription;
  
  // Animation Controllers
  late AnimationController _pulseController;
  late AnimationController _shakeController;
  late AnimationController _countdownController;
  
  // UI State
  int? _selectedAnswer;
  bool _answered = false;
  List<bool> _eliminatedOptions = [];

  @override
  void initState() {
    super.initState();
    _userId = _supabase.currentUser?.id;
    _timeLimit = widget.gameData['time_limit_seconds'] ?? 15;
    _timeLeft = _timeLimit.toDouble();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..repeat(reverse: true);
    
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _countdownController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _loadQuestions();
    _subscribeToGameUpdates();
    _startCountdown();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _shakeController.dispose();
    _countdownController.dispose();
    _timer?.cancel();
    _countdownTimer?.cancel();
    _gameSubscription?.cancel();
    _playersSubscription?.cancel();
    super.dispose();
  }

  void _subscribeToGameUpdates() {
    // Subscribe to game status changes
    _gameSubscription = _supabase.client
        .from('live_games')
        .stream(primaryKey: ['id'])
        .eq('id', widget.gameId)
        .listen((data) {
          if (data.isNotEmpty) {
            final game = data.first;
            if (game['status'] == 'finished') {
              _endGame();
            }
          }
        });
    
    // Subscribe to player scores
    _playersSubscription = _supabase.client
        .from('live_game_players')
        .stream(primaryKey: ['id'])
        .eq('game_id', widget.gameId)
        .order('score', ascending: false)
        .listen((data) {
          setState(() {
            _leaderboard = List<Map<String, dynamic>>.from(data);
            _updateMyRank();
          });
        });
  }

  void _updateMyRank() {
    for (int i = 0; i < _leaderboard.length; i++) {
      if (_leaderboard[i]['user_id'] == _userId) {
        _myRank = i + 1;
        _myScore = _leaderboard[i]['score'] ?? 0;
        break;
      }
    }
  }

  Future<void> _loadQuestions() async {
    try {
      final response = await _supabase.client
          .from('live_game_questions')
          .select()
          .eq('game_id', widget.gameId)
          .order('question_number');
      
      setState(() {
        _questions = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
        } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _startCountdown() {
    setState(() {
      _countdownValue = 3;
      _showCountdown = true;
    });
    
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _countdownValue--;
      });
      
      _countdownController.forward(from: 0);
      HapticFeedback.lightImpact();
      
      if (_countdownValue <= 0) {
        timer.cancel();
        setState(() {
          _showCountdown = false;
        });
        _startGame();
      }
    });
  }

  void _startGame() {
    setState(() {
      _isGameActive = true;
      _currentQuestionIndex = 0;
      _loadCurrentQuestion();
    });
  }

  void _loadCurrentQuestion() {
    if (_currentQuestionIndex >= _questions.length) {
      _endGame();
      return;
    }
    
    setState(() {
      _currentQuestion = _questions[_currentQuestionIndex];
      _timeLeft = _timeLimit.toDouble();
      _answered = false;
      _selectedAnswer = null;
      _fiftyFiftyUsed = false;
      _doublePointsActive = false;
      _eliminatedOptions = [];
      _questionStartTime = DateTime.now();
    });
    
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!_isPaused && _timeLeft > 0) {
        setState(() {
          _timeLeft = (_timeLeft - 0.1).clamp(0, _timeLimit.toDouble());
        });
        
        if (_timeLeft <= 0) {
          timer.cancel();
          _submitAnswer('');
        }
      }
    });
  }

  void _selectAnswer(int index) {
    if (_answered || _timeLeft <= 0) return;
    
    HapticFeedback.mediumImpact();
    
    setState(() {
      _answered = true;
      _selectedAnswer = index;
    });
    
    final options = _currentQuestion?['question_data']?['options'] as List?;
    final answer = options != null ? options[index].toString() : '';
    
    _submitAnswer(answer);
  }

  Future<void> _submitAnswer(String answer) async {
    _timer?.cancel();
    
    final questionId = _currentQuestion?['id'];
    final now = DateTime.now();
    final responseTime = _questionStartTime != null
        ? now.difference(_questionStartTime!).inMilliseconds
        : _timeLimit * 1000;
    
    final result = await _gameService.submitAnswer(
      widget.gameId,
      _userId!,
      questionId,
      answer,
      responseTime,
    );
    
    if (result != null) {
      final isCorrect = result['is_correct'] as bool;
      
      setState(() {
        if (isCorrect) {
          _correctAnswers++;
          _myStreak++;
        } else {
          _wrongAnswers++;
          _myStreak = 0;
          _shakeController.forward(from: 0);
        }
      });
      
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() {
            _currentQuestionIndex++;
          });
          _loadCurrentQuestion();
        }
      });
    }
  }

  void _endGame() {
    _timer?.cancel();
    setState(() {
      _isGameActive = false;
    });
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => LiveGameResultsScreen(
          gameId: widget.gameId,
          gameData: widget.gameData,
          myScore: _myScore,
          myRank: _myRank,
          correctAnswers: _correctAnswers,
          wrongAnswers: _wrongAnswers,
          leaderboard: _leaderboard,
        ),
      ),
    );
  }

  // Power-ups
  void _useDoublePoints() {
    if (!_hasDoublePoints || _doublePointsActive) return;
    
    HapticFeedback.mediumImpact();
    setState(() {
      _doublePointsActive = true;
      _hasDoublePoints = false;
    });
  }

  void _useFiftyFifty() {
    if (!_hasFiftyFifty || _fiftyFiftyUsed || _answered) return;
    
    HapticFeedback.mediumImpact();
    final correctIndex = _currentQuestion?['question_data']?['correct_index'] as int? ?? 0;
    final options = _currentQuestion?['question_data']?['options'] as List? ?? [];
    
    setState(() {
      _fiftyFiftyUsed = true;
      _hasFiftyFifty = false;
      _eliminatedOptions = List.generate(options.length, (i) {
        if (i == correctIndex) return false;
        // Randomly eliminate 2 wrong options
        return Random().nextBool() && _eliminatedOptions.where((e) => e).length < 2;
      });
    });
  }

  void _useTimeFreeze() {
    if (!_hasTimeFreeze || _isPaused) return;
    
    HapticFeedback.mediumImpact();
    setState(() {
      _isPaused = true;
      _hasTimeFreeze = false;
    });
    
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _isPaused = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingScreen();
    }
    
    if (_showCountdown) {
      return _buildCountdownScreen();
    }
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildGameHeader(),
            _buildLeaderboard(),
            Expanded(
              child: _currentQuestion != null
                  ? _buildQuestionArea()
                  : const Center(child: CircularProgressIndicator()),
            ),
            _buildPowerUpsBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text(
              'Preparing Game...',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountdownScreen() {
    return Container(
      color: Colors.black.withValues(alpha: 0.95),
      child: Center(
        child: AnimatedBuilder(
          animation: _countdownController,
          builder: (context, child) {
            final scale = 1 + (_countdownController.value * 0.3);
            
            return Transform.scale(
              scale: scale,
              child: Text(
                _countdownValue > 0 ? '$_countdownValue' : 'GO!',
                style: TextStyle(
                  fontSize: _countdownValue > 0 ? 150 : 100,
                  fontWeight: FontWeight.bold,
                  color: _countdownValue > 0
                      ? (_countdownValue == 3 ? Colors.red : _countdownValue == 2 ? Colors.orange : Colors.green)
                      : const Color(0xFF00FF00),
                  shadows: [
                    Shadow(
                      color: (_countdownValue > 0
                              ? (_countdownValue == 3 ? Colors.red : _countdownValue == 2 ? Colors.orange : Colors.green)
                              : const Color(0xFF00FF00))
                          .withValues(alpha: 0.5),
                      blurRadius: 30,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    ).animate().fadeIn(duration: 200.ms);
  }

  Widget _buildGameHeader() {
    final isDanger = _timeLeft <= 5;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
      child: Row(
        children: [
          // Timer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: isDanger
                  ? const LinearGradient(colors: [Colors.red, Colors.orange])
                  : null,
              color: isDanger ? null : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.timer,
                  color: isDanger ? Colors.white : AppColors.textMedium,
                  size: 20,
                ),
                const SizedBox(width: 6),
                Text(
                  _timeLeft.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDanger ? Colors.white : AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Question Counter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '${_currentQuestionIndex + 1}/${_questions.length}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textMedium,
              ),
            ),
          ),
          
          const Spacer(),
          
          // Score
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
                const Icon(Icons.star, color: Colors.white, size: 18),
                const SizedBox(width: 4),
                Text(
                  '$_myScore',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Rank
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _myRank == 1
                  ? Colors.amber.withValues(alpha: 0.2)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
              border: _myRank == 1
                  ? Border.all(color: Colors.amber, width: 2)
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.emoji_events,
                  color: _myRank == 1 ? Colors.amber : AppColors.textMedium,
                  size: 18,
                ),
                const SizedBox(width: 4),
                Text(
                  '#$_myRank',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _myRank == 1 ? Colors.amber : AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboard() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _leaderboard.length,
        itemBuilder: (context, index) {
          final player = _leaderboard[index];
          final isMe = player['user_id'] == _userId;
          
          return Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: isMe
                  ? const LinearGradient(
                      colors: [AppColors.primaryTeal, AppColors.darkTeal],
                    )
                  : null,
              color: isMe ? null : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
              border: index == 0
                  ? Border.all(color: Colors.amber, width: 2)
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isMe ? Colors.white : AppColors.textMedium,
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () {
                    if (!isMe && player['user_id'] != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PublicProfileScreen(
                            userId: player['user_id'],
                          ),
                        ),
                      );
                    }
                  },
                  child: CircleAvatar(
                    radius: 12,
                    backgroundColor: isMe ? Colors.white.withValues(alpha: 0.3) : Colors.grey.shade300,
                    child: Text(
                      (player['username'] ?? 'P')[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        color: isMe ? Colors.white : AppColors.textDark,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${player['score'] ?? 0}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isMe ? Colors.white : AppColors.textDark,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuestionArea() {
    final questionData = _currentQuestion?['question_data'] as Map<String, dynamic>? ?? {};
    final question = questionData['question'] ?? '';
    final options = questionData['options'] as List? ?? [];
    final questionType = questionData['type'] ?? 'multiple_choice';
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Question Card
          AnimatedBuilder(
            animation: _shakeController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(sin(_shakeController.value * pi * 4) * 5, 0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primaryTeal,
                        AppColors.darkTeal,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryTeal.withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      if (_doublePointsActive)
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.stars, color: Colors.white, size: 16),
                              SizedBox(width: 4),
                              Text(
                                '2X POINTS ACTIVE!',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ).animate().shake(),
                      Text(
                        question,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 24),
          
          // Streak Indicator
          if (_myStreak >= 2)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.orange, Colors.red],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withValues(alpha: 0.4),
                    blurRadius: 15,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.local_fire_department, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    '$_myStreak STREAK!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ).animate().shake(hz: 3),
          
          // Options
          Expanded(
            child: ListView.builder(
              itemCount: options.length,
              itemBuilder: (context, index) {
                final option = options[index];
                final isEliminated = _eliminatedOptions.length > index && _eliminatedOptions[index];
                final isSelected = _selectedAnswer == index;
                final isCorrect = index == (questionData['correct_index'] ?? 0);
                
                Color bgColor = Colors.white;
                Color borderColor = Colors.grey.shade300;
                Color textColor = AppColors.textDark;
                
                if (_answered) {
                  if (isCorrect) {
                    bgColor = Colors.green.shade50;
                    borderColor = Colors.green;
                    textColor = Colors.green.shade700;
                  } else if (isSelected) {
                    bgColor = Colors.red.shade50;
                    borderColor = Colors.red;
                    textColor = Colors.red.shade700;
                  }
                } else if (isSelected) {
                  bgColor = AppColors.primaryTeal.withValues(alpha: 0.1);
                  borderColor = AppColors.primaryTeal;
                  textColor = AppColors.primaryTeal;
                }
                
                if (isEliminated) {
                  bgColor = Colors.grey.shade100;
                  textColor = Colors.grey.shade400;
                }
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onTap: isEliminated ? null : () => _selectAnswer(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: borderColor,
                          width: 2,
                        ),
                        boxShadow: [
                          if (!_answered && !isEliminated)
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
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: _answered && isCorrect
                                  ? Colors.green
                                  : _answered && isSelected && !isCorrect
                                      ? Colors.red
                                      : isEliminated
                                          ? Colors.grey.shade300
                                          : AppColors.primaryTeal.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                String.fromCharCode(65 + index),
                                style: TextStyle(
                                  color: _answered && (isCorrect || (isSelected && !isCorrect))
                                      ? Colors.white
                                      : isEliminated
                                          ? Colors.grey.shade500
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
                              option.toString(),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                          ),
                          if (_answered && isCorrect)
                            const Icon(Icons.check_circle, color: Colors.green, size: 28)
                          else if (_answered && isSelected && !isCorrect)
                            const Icon(Icons.cancel, color: Colors.red, size: 28),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPowerUpsBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildPowerUpButton(
              icon: Icons.stars,
              label: '2X Points',
              color: Colors.amber,
              isAvailable: _hasDoublePoints,
              isActive: _doublePointsActive,
              onTap: _useDoublePoints,
            ),
            _buildPowerUpButton(
              icon: Icons.filter_2,
              label: '50:50',
              color: Colors.blue,
              isAvailable: _hasFiftyFifty,
              isActive: _fiftyFiftyUsed,
              onTap: _useFiftyFifty,
            ),
            _buildPowerUpButton(
              icon: Icons.pause_circle,
              label: 'Freeze',
              color: Colors.purple,
              isAvailable: _hasTimeFreeze,
              isActive: _isPaused,
              onTap: _useTimeFreeze,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPowerUpButton({
    required IconData icon,
    required String label,
    required Color color,
    required bool isAvailable,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: isAvailable ? onTap : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: isActive
                  ? LinearGradient(colors: [color, color.withValues(alpha: 0.7)])
                  : isAvailable
                      ? LinearGradient(colors: [color, color.withValues(alpha: 0.8)])
                      : null,
              color: !isAvailable && !isActive ? Colors.grey.shade200 : null,
              shape: BoxShape.circle,
              boxShadow: isAvailable || isActive
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              icon,
              color: isAvailable || isActive ? Colors.white : Colors.grey.shade400,
              size: 28,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isAvailable || isActive ? color : Colors.grey.shade400,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Live Game Results Screen - Shows final standings and rewards
class LiveGameResultsScreen extends StatelessWidget {
  final String gameId;
  final Map<String, dynamic> gameData;
  final int myScore;
  final int myRank;
  final int correctAnswers;
  final int wrongAnswers;
  final List<Map<String, dynamic>> leaderboard;

  const LiveGameResultsScreen({
    super.key,
    required this.gameId,
    required this.gameData,
    required this.myScore,
    required this.myRank,
    required this.correctAnswers,
    required this.wrongAnswers,
    required this.leaderboard,
  });

  @override
  Widget build(BuildContext context) {
    final isWinner = myRank == 1;
    final totalQuestions = correctAnswers + wrongAnswers;
    final accuracy = totalQuestions > 0
        ? (correctAnswers / totalQuestions * 100).round()
        : 0;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              _buildResultsBadge(isWinner),
              const SizedBox(height: 32),
              _buildStatsCards(accuracy),
              const SizedBox(height: 32),
              _buildLeaderboard(context),
              const SizedBox(height: 40),
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultsBadge(bool isWinner) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Glow effect
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    isWinner
                        ? Colors.amber.withValues(alpha: 0.4)
                        : AppColors.primaryTeal.withValues(alpha: 0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            
            // Main badge
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                gradient: isWinner
                    ? AppColors.goldGradient
                    : const LinearGradient(
                        colors: [AppColors.primaryTeal, AppColors.darkTeal],
                      ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (isWinner ? Colors.amber : AppColors.primaryTeal)
                        .withValues(alpha: 0.5),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Icon(
                isWinner ? Icons.emoji_events : Icons.stars,
                color: Colors.white,
                size: 80,
              ),
            )
            .animate()
            .scale(duration: 600.ms, curve: Curves.elasticOut),
          ],
        ),
        
        const SizedBox(height: 24),
        
        Text(
          isWinner ? 'Victory!' : 'Game Over',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: isWinner ? Colors.amber : AppColors.textDark,
          ),
        )
        .animate()
        .fadeIn(delay: 300.ms)
        .slideY(begin: 0.2, end: 0),
        
        const SizedBox(height: 8),
        
        Text(
          'Rank #$myRank • $myScore Points',
          style: const TextStyle(
            fontSize: 18,
            color: AppColors.textMedium,
          ),
        )
        .animate()
        .fadeIn(delay: 400.ms),
      ],
    );
  }

  Widget _buildStatsCards(int accuracy) {
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
                child: _buildStatCard(
                  icon: Icons.check_circle,
                  value: '$correctAnswers',
                  label: 'Correct',
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.cancel,
                  value: '$wrongAnswers',
                  label: 'Wrong',
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

  Widget _buildStatCard({
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
              fontSize: 24,
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

  Widget _buildLeaderboard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Final Standings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...leaderboard.asMap().entries.map((entry) {
            final index = entry.key;
            final player = entry.value;
            final isMe = index + 1 == myRank;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: isMe
                    ? LinearGradient(
                        colors: [AppColors.primaryTeal.withValues(alpha: 0.1), AppColors.darkTeal.withValues(alpha: 0.05)],
                      )
                    : null,
                color: isMe ? null : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: index == 0
                    ? Border.all(color: Colors.amber, width: 2)
                    : isMe
                        ? Border.all(color: AppColors.primaryTeal, width: 2)
                        : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: index == 0
                          ? Colors.amber
                          : index == 1
                              ? Colors.grey.shade400
                              : index == 2
                                  ? Colors.orange.shade300
                                  : Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: index < 3 ? Colors.white : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {
                      if (!isMe && player['user_id'] != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PublicProfileScreen(
                              userId: player['user_id'],
                            ),
                          ),
                        );
                      }
                    },
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.grey.shade300,
                      child: Text(
                        (player['username'] ?? 'P')[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      player['username'] ?? 'Player',
                      style: TextStyle(
                        fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  Text(
                    '${player['score'] ?? 0}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: index == 0 ? Colors.amber : AppColors.textDark,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    )
    .animate()
    .fadeIn(delay: 600.ms)
    .slideY(begin: 0.1, end: 0);
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            icon: const Icon(Icons.home),
            label: const Text(
              'Back to Home',
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
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
              // Navigate to competitions
            },
            icon: const Icon(Icons.sports_esports),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textMedium,
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            label: const Text(
              'Play Again',
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

