import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/live_game_service.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';
import '../profile/public_profile_screen.dart';

/// Premium Spectator Mode Screen - Watch live games
/// Features: Live leaderboard, real-time updates, no interaction
class SpectatorModeScreen extends StatefulWidget {
  final String gameId;

  const SpectatorModeScreen({super.key, required this.gameId});

  @override
  State<SpectatorModeScreen> createState() => _SpectatorModeScreenState();
}

class _SpectatorModeScreenState extends State<SpectatorModeScreen> {
  final LiveGameService _gameService = LiveGameService();
  final SupabaseService _supabase = SupabaseService();

  Map<String, dynamic>? _gameData;
  List<Map<String, dynamic>> _players = [];
  List<Map<String, dynamic>> _questions = [];
  final int _currentQuestionIndex = 0;
  Map<String, dynamic>? _currentQuestion;
  bool _isLoading = true;
  int _spectatorCount = 0;

  // Subscriptions
  StreamSubscription? _gameSubscription;
  StreamSubscription? _playersSubscription;
  StreamSubscription? _spectatorsSubscription;

  @override
  void initState() {
    super.initState();
    _loadGameData();
    _subscribeToUpdates();
    _joinAsSpectator();
  }

  @override
  void dispose() {
    _gameSubscription?.cancel();
    _playersSubscription?.cancel();
    _spectatorsSubscription?.cancel();
    _leaveAsSpectator();
    super.dispose();
  }

  Future<void> _loadGameData() async {
    try {
      final gameResponse = await _supabase.client
          .from('live_games')
          .select('*, questions:live_game_questions(*)')
          .eq('id', widget.gameId)
          .single();

      setState(() {
        _gameData = gameResponse;
        _questions = List<Map<String, dynamic>>.from(gameResponse['questions'] ?? []);
        _spectatorCount = gameResponse['spectator_count'] ?? 0;
      });
    
      await _loadPlayers();
    } catch (e) {
      // Handle error
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPlayers() async {
    try {
      final response = await _supabase.client
          .from('live_game_players')
          .select('*, user:user_id(username, avatar_url)')
          .eq('game_id', widget.gameId)
          .isFilter('left_at', null)
          .order('score', ascending: false);

      setState(() {
        _players = List<Map<String, dynamic>>.from(response);
      });
        } catch (e) {
      // Handle error
    }
  }

  void _subscribeToUpdates() {
    // Subscribe to game updates
    _gameSubscription = _supabase.client
        .from('live_games')
        .stream(primaryKey: ['id'])
        .eq('id', widget.gameId)
        .listen((data) {
          if (data.isNotEmpty) {
            final game = data.first;
            setState(() {
              _gameData = game;
              _spectatorCount = game['spectator_count'] ?? 0;
            });

            if (game['status'] == 'finished') {
              _showGameEndedDialog();
            }
          }
        });

    // Subscribe to player updates
    _playersSubscription = _supabase.client
        .from('live_game_players')
        .stream(primaryKey: ['id'])
        .eq('game_id', widget.gameId)
        .listen((data) {
          _loadPlayers();
        });

    // Subscribe to spectator count
    _spectatorsSubscription = _supabase.client
        .from('live_game_spectators')
        .stream(primaryKey: ['id'])
        .eq('game_id', widget.gameId)
        .listen((data) {
          setState(() {
            _spectatorCount = data.length;
          });
        });
  }

  Future<void> _joinAsSpectator() async {
    final userId = _supabase.currentUser?.id;
    if (userId == null) return;

    try {
      await _gameService.joinAsSpectator(widget.gameId, userId);
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _leaveAsSpectator() async {
    final userId = _supabase.currentUser?.id;
    if (userId == null) return;

    try {
      await _gameService.leaveSpectatorMode(widget.gameId, userId);
    } catch (e) {
      // Handle error
    }
  }

  void _showGameEndedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Game Ended'),
        content: const Text('The game has finished. Check the final results!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildSpectatorHeader(),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildLeaderboard(),
                  ),
                  Expanded(
                    flex: 3,
                    child: _buildGameView(),
                  ),
                ],
              ),
            ),
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
            SizedBox(height: 16),
            Text('Joining as spectator...'),
          ],
        ),
      ),
    );
  }

  Widget _buildSpectatorHeader() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.purple.withValues(alpha: 0.15),
            Colors.deepPurple.withValues(alpha: 0.05),
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
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.purple.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.visibility, color: Colors.purple, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'SPECTATOR MODE',
                            style: TextStyle(
                              color: Colors.purple,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _gameData?['title'] ?? 'Live Game',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.visibility, color: AppColors.textMedium, size: 16),
                const SizedBox(width: 4),
                Text(
                  '$_spectatorCount',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Live Leaderboard',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _players.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _players.length,
                    itemBuilder: (context, index) {
                      final player = _players[index];
                      final isLeader = index == 0;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: isLeader
                              ? LinearGradient(
                                  colors: [
                                    Colors.amber.withValues(alpha: 0.1),
                                    Colors.orange.withValues(alpha: 0.05),
                                  ],
                                )
                              : null,
                          color: isLeader ? null : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isLeader ? Colors.amber.withValues(alpha: 0.3) : Colors.grey.shade200,
                            width: 2,
                          ),
                          boxShadow: [
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
                                if (player['user_id'] != null) {
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
                                radius: 20,
                                backgroundColor: Colors.grey.shade300,
                                backgroundImage: player['user']?['avatar_url'] != null
                                    ? NetworkImage(player['user']!['avatar_url'])
                                    : null,
                                child: player['user']?['avatar_url'] == null
                                    ? Text(
                                        (player['user']?['username'] ?? 'P')[0].toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: AppColors.textDark,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    player['user']?['username'] ?? 'Unknown',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textDark,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${player['correct_answers'] ?? 0} correct',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textMedium,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primaryTeal.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${player['score'] ?? 0}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryTeal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: (50 * index).ms);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameView() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Question display
          Container(
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
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  'Current Question',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _currentQuestion?['question_data']?['question'] ?? 'Waiting for question...',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Answer options (disabled)
          Expanded(
            child: _currentQuestion == null
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Waiting for game to start...'),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: (_currentQuestion?['question_data']?['options'] as List?)?.length ?? 0,
                    itemBuilder: (context, index) {
                      final options = _currentQuestion?['question_data']?['options'] as List? ?? [];
                      final option = options[index];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  String.fromCharCode(65 + index),
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.bold,
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
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.lock,
                              color: Colors.grey.shade400,
                              size: 20,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          // Spectator notice
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.purple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.visibility, color: Colors.purple),
                SizedBox(width: 8),
                Text(
                  'You are watching this game as a spectator',
                  style: TextStyle(
                    color: Colors.purple,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

