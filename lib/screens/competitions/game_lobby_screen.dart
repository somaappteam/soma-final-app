import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/live_game_service.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';
import '../profile/public_profile_screen.dart';
import 'live_game_play_screen.dart';

/// Premium Game Lobby Screen - Enhanced with real-time updates and animations
/// Features: Live player updates, chat, ready system, countdown, animations
class GameLobbyScreen extends StatefulWidget {
  final String gameId;

  const GameLobbyScreen({super.key, required this.gameId});

  @override
  State<GameLobbyScreen> createState() => _GameLobbyScreenState();
}

class _GameLobbyScreenState extends State<GameLobbyScreen>
    with TickerProviderStateMixin {
  final LiveGameService _gameService = LiveGameService();
  final SupabaseService _supabase = SupabaseService();
  
  // Game Data
  Map<String, dynamic>? _gameData;
  List<Map<String, dynamic>> _players = [];
  String? _userId;
  bool _isHost = false;
  bool _isReady = false;
  
  // Chat
  final List<Map<String, dynamic>> _chatMessages = [];
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  bool _showChat = false;
  int _unreadMessages = 0;
  
  // State
  bool _isLoading = true;
  bool _showCountdown = false;
  int _countdownValue = 5;
  Timer? _countdownTimer;
  
  // Subscriptions
  StreamSubscription? _gameSubscription;
  StreamSubscription? _playersSubscription;
  StreamSubscription? _chatSubscription;
  
  // Animation
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _userId = _supabase.currentUser?.id;
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    
    _loadGameData();
    _subscribeToUpdates();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _countdownTimer?.cancel();
    _gameSubscription?.cancel();
    _playersSubscription?.cancel();
    _chatSubscription?.cancel();
    _chatController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadGameData() async {
    try {
      final gameResponse = await _supabase.client
          .from('live_games')
          .select('*, host:host_id(username, avatar_url)')
          .eq('id', widget.gameId)
          .single();
      
      setState(() {
        _gameData = gameResponse;
        _isHost = gameResponse['host_id'] == _userId;
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
          .order('joined_at');
      
      setState(() {
        _players = List<Map<String, dynamic>>.from(response);
        
        // Update my ready status
        for (var player in _players) {
          if (player['user_id'] == _userId) {
            _isReady = player['is_ready'] ?? false;
            break;
          }
        }
      });
        } catch (e) {
      // Handle error
    }
  }

  void _subscribeToUpdates() {
    // Subscribe to game status changes
    _gameSubscription = _supabase.client
        .from('live_games')
        .stream(primaryKey: ['id'])
        .eq('id', widget.gameId)
        .listen((data) {
          if (data.isNotEmpty) {
            final game = data.first;
            setState(() {
              _gameData = game;
            });
            
            if (game['status'] == 'in_progress' && !_showCountdown) {
              _startCountdown();
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
    
    // Subscribe to chat messages
    _chatSubscription = _supabase.client
        .from('live_game_chat')
        .stream(primaryKey: ['id'])
        .eq('game_id', widget.gameId)
        .order('created_at')
        .listen((data) {
          setState(() {
            _chatMessages.clear();
            _chatMessages.addAll(List<Map<String, dynamic>>.from(data));
          });
          
          if (!_showChat && _chatMessages.isNotEmpty) {
            setState(() {
              _unreadMessages = _chatMessages.length;
            });
          }
          
          // Scroll to bottom
          if (_showChat && _chatScrollController.hasClients) {
            Future.delayed(const Duration(milliseconds: 100), () {
              _chatScrollController.animateTo(
                _chatScrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            });
          }
        });
  }

  Future<void> _toggleReady() async {
    HapticFeedback.mediumImpact();
    
    try {
      await _gameService.setReadyStatus(widget.gameId, _userId!, !_isReady);
      setState(() {
        _isReady = !_isReady;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update ready status: $e')),
      );
    }
  }

  Future<void> _startGame() async {
    if (!_isHost) return;
    
    // Check if all players are ready
    final allReady = _players.every((p) => p['is_ready'] == true);
    if (!allReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not all players are ready')),
      );
      return;
    }
    
    HapticFeedback.heavyImpact();
    
    try {
      await _gameService.startGame(widget.gameId, _userId!);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start game: $e')),
      );
    }
  }

  void _startCountdown() {
    setState(() {
      _showCountdown = true;
      _countdownValue = 5;
    });
    
    HapticFeedback.heavyImpact();
    
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _countdownValue--;
      });
      
      HapticFeedback.lightImpact();
      
      if (_countdownValue <= 0) {
        timer.cancel();
        _navigateToGame();
      }
    });
  }

  void _navigateToGame() {
    if (_gameData != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LiveGamePlayScreen(
            gameId: widget.gameId,
            gameData: _gameData!,
          ),
        ),
      );
    }
  }

  Future<void> _leaveGame() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Game?'),
        content: const Text('Are you sure you want to leave this game?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        await _gameService.leaveGame(widget.gameId, _userId!);
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to leave game: $e')),
        );
      }
    }
  }

  Future<void> _sendChatMessage() async {
    final message = _chatController.text.trim();
    if (message.isEmpty) return;
    
    try {
      await _supabase.client.from('live_game_chat').insert({
        'game_id': widget.gameId,
        'user_id': _userId,
        'message': message,
        'created_at': DateTime.now().toIso8601String(),
      });
      
      _chatController.clear();
    } catch (e) {
      // Handle error
    }
  }

  void _showInviteByUsernameDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => InviteByUsernameDialog(
        gameId: widget.gameId,
        onInviteSent: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invite sent!')),
          );
        },
      ),
    );
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
      body: Stack(
        children: [
          Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: _buildPlayersSection(),
                    ),
                    if (_showChat)
                      Expanded(
                        flex: 2,
                        child: _buildChatSection(),
                      ),
                  ],
                ),
              ),
              _buildBottomBar(),
            ],
          ),
          if (!_showChat && _unreadMessages > 0)
            _buildChatFab(),
        ],
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
            Text('Loading Lobby...'),
          ],
        ),
      ),
    );
  }

  Widget _buildCountdownScreen() {
    return Container(
      color: Colors.black.withValues(alpha: 0.95),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Game Starting In',
              style: TextStyle(
                fontSize: 24,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 32),
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final scale = 1 + (_pulseController.value * 0.2);
                return Transform.scale(
                  scale: scale,
                  child: Text(
                    '$_countdownValue',
                    style: TextStyle(
                      fontSize: 150,
                      fontWeight: FontWeight.bold,
                      color: _countdownValue <= 3 ? Colors.red : Colors.green,
                      shadows: [
                        Shadow(
                          color: (_countdownValue <= 3 ? Colors.red : Colors.green)
                              .withValues(alpha: 0.5),
                          blurRadius: 30,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            Text(
              'Get Ready!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);
    final title = _gameData?['title'] ?? 'Game Lobby';
    final gameCode = _gameData?['game_code'] ?? '';
    final currentPlayers = _players.length;
    final maxPlayers = _gameData?['max_players'] ?? 4;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryTeal.withValues(alpha: 0.2),
            AppColors.darkTeal.withValues(alpha: 0.1),
          ],
        ),
      ),
      child: SafeArea(
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
                    icon: const Icon(Icons.arrow_back),
                    onPressed: _leaveGame,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primaryTeal.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Code: $gameCode',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.primaryTeal,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.people, size: 16, color: AppColors.textMedium),
                          const SizedBox(width: 4),
                          Text(
                            '$currentPlayers/$maxPlayers',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMedium,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _showChat ? Icons.chat_bubble : Icons.chat_bubble_outline,
                    color: AppColors.primaryTeal,
                  ),
                  onPressed: () {
                    setState(() {
                      _showChat = !_showChat;
                      if (_showChat) {
                        _unreadMessages = 0;
                      }
                    });
                  },
                ),
                if (_isHost) ...[
                  IconButton(
                    icon: const Icon(Icons.person_add),
                    onPressed: _showInviteByUsernameDialog,
                    tooltip: 'Invite Player',
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: () {
                      // Show settings
                    },
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayersSection() {
    final maxPlayers = _gameData?['max_players'] ?? 4;
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Players',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryTeal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${_players.where((p) => p['is_ready'] == true).length}/${_players.length} Ready',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryTeal,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: maxPlayers,
              itemBuilder: (context, index) {
                if (index < _players.length) {
                  return _buildPlayerCard(_players[index]);
                } else {
                  return _buildEmptySlot();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerCard(Map<String, dynamic> player) {
    final isMe = player['user_id'] == _userId;
    final isHost = player['user_id'] == _gameData?['host_id'];
    final isReady = player['is_ready'] ?? false;
    final username = player['user']?['username'] ?? 'Unknown';
    final avatarUrl = player['user']?['avatar_url'];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: isMe
            ? LinearGradient(
                colors: [
                  AppColors.primaryTeal.withValues(alpha: 0.1),
                  AppColors.darkTeal.withValues(alpha: 0.05),
                ],
              )
            : null,
        color: isMe ? null : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isReady
              ? Colors.green.withValues(alpha: 0.5)
              : isMe
                  ? AppColors.primaryTeal.withValues(alpha: 0.3)
                  : Colors.grey.shade200,
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
      child: GestureDetector(
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
        child: Row(
          children: [
            Stack(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: isReady ? Colors.green.withValues(alpha: 0.1) : Colors.grey.shade200,
                backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                child: avatarUrl == null
                    ? Text(
                        username[0].toUpperCase(),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isReady ? Colors.green : AppColors.textDark,
                        ),
                      )
                    : null,
              ),
              if (isReady)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      username,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    if (isMe)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryTeal,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'You',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (isHost)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          gradient: AppColors.goldGradient,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star, color: Colors.white, size: 10),
                            SizedBox(width: 2),
                            Text(
                              'Host',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isReady
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isReady ? 'Ready' : 'Not Ready',
                        style: TextStyle(
                          color: isReady ? Colors.green : Colors.orange,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    ).animate().fadeIn().slideX();
  }

  Widget _buildEmptySlot() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey.shade300,
          style: BorderStyle.solid,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.grey.shade200,
            child: Icon(Icons.person_outline, color: Colors.grey.shade400),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Waiting for player...',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Share the game code to invite',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatSection() {
    return Container(
      margin: const EdgeInsets.only(right: 16, bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryTeal.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                const Icon(Icons.chat, color: AppColors.primaryTeal),
                const SizedBox(width: 8),
                const Text(
                  'Lobby Chat',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () {
                    setState(() {
                      _showChat = false;
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _chatMessages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 48,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No messages yet',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _chatScrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: _chatMessages.length,
                    itemBuilder: (context, index) {
                      final message = _chatMessages[index];
                      final isMe = message['user_id'] == _userId;
                      
                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isMe ? AppColors.primaryTeal : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!isMe)
                                Text(
                                  message['user']?['username'] ?? 'Unknown',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textMedium,
                                  ),
                                ),
                              Text(
                                message['message'] ?? '',
                                style: TextStyle(
                                  color: isMe ? Colors.white : AppColors.textDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => _sendChatMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: AppColors.primaryTeal),
                  onPressed: _sendChatMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatFab() {
    return Positioned(
      right: 16,
      bottom: 100,
      child: Stack(
        children: [
          FloatingActionButton(
            onPressed: () {
              setState(() {
                _showChat = true;
                _unreadMessages = 0;
              });
            },
            backgroundColor: AppColors.primaryTeal,
            child: const Icon(Icons.chat),
          ),
          if (_unreadMessages > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$_unreadMessages',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
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
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _toggleReady,
                icon: Icon(_isReady ? Icons.cancel : Icons.check_circle),
                label: Text(_isReady ? 'Not Ready' : 'I\'m Ready'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isReady ? Colors.orange : Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            if (_isHost) ...[
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _startGame,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start Game'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentCoral,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 8,
                    shadowColor: AppColors.accentCoral.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Invite by Username Dialog
class InviteByUsernameDialog extends StatefulWidget {
  final String gameId;
  final VoidCallback onInviteSent;

  const InviteByUsernameDialog({
    super.key,
    required this.gameId,
    required this.onInviteSent,
  });

  @override
  State<InviteByUsernameDialog> createState() => _InviteByUsernameDialogState();
}

class _InviteByUsernameDialogState extends State<InviteByUsernameDialog> {
  final TextEditingController _searchController = TextEditingController();
  final LiveGameService _gameService = LiveGameService();
  final SupabaseService _supabase = SupabaseService();

  bool _isSearching = false;
  List<Map<String, dynamic>> _searchResults = [];
  String? _errorMessage;

  Future<void> _searchUsers() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _errorMessage = null;
    });

    try {
      final results = await _gameService.searchUsersByUsername(query);
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to search users';
        _isSearching = false;
      });
    }
  }

  Future<void> _inviteUser(String username) async {
    final userId = _supabase.currentUser?.id;
    if (userId == null) return;

    try {
      await _gameService.inviteUserByUsername(
        gameId: widget.gameId,
        inviterId: userId,
        username: username,
      );
      widget.onInviteSent();
      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Invite Player',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Search by username',
                        style: TextStyle(
                          color: AppColors.textMedium,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Enter username...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _isSearching
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.arrow_forward),
                        onPressed: _searchUsers,
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onSubmitted: (_) => _searchUsers(),
            ),
          ),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          Expanded(
            child: _searchResults.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchController.text.isEmpty
                              ? 'Search for players to invite'
                              : 'No users found',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final user = _searchResults[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage: user['avatar_url'] != null
                                ? NetworkImage(user['avatar_url'])
                                : null,
                            child: user['avatar_url'] == null
                                ? Text((user['username'] ?? '?')[0].toUpperCase())
                                : null,
                          ),
                          title: Text(user['username'] ?? 'Unknown'),
                          subtitle: user['is_premium'] == true
                              ? const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.star, color: Colors.amber, size: 14),
                                    SizedBox(width: 4),
                                    Text(
                                      'Premium',
                                      style: TextStyle(
                                        color: Colors.amber,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                )
                              : null,
                          trailing: ElevatedButton.icon(
                            onPressed: () => _inviteUser(user['username']),
                            icon: const Icon(Icons.person_add, size: 18),
                            label: const Text('Invite'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryTeal,
                              foregroundColor: Colors.white,
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

