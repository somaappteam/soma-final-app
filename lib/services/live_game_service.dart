import 'dart:async';
import 'dart:math';
import 'package:logger/logger.dart';
import '../services/supabase_service.dart';

class LiveGameService {
  static final LiveGameService _instance = LiveGameService._internal();
  factory LiveGameService() => _instance;
  LiveGameService._internal();

  final Logger _logger = Logger();
  final SupabaseService _supabase = SupabaseService();

  StreamSubscription? _gameSubscription;
  Function(Map<String, dynamic>)? onGameUpdate;
  Function(Map<String, dynamic>)? onPlayerUpdate;
  Function(Map<String, dynamic>)? onNewQuestion;

  // Generate a random game code
  String _generateGameCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    return List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
  }

  // Create a new live game
  Future<Map<String, dynamic>?> createGame({
    required String hostId,
    required String gameType,
    required String languageCode,
    String? title,
    String? description,
    int maxPlayers = 4,
    int timeLimitSeconds = 15,
    int questionCount = 10,
    bool isPrivate = false,
    String? password,
    bool isPremiumOnly = false,
    int difficultyLevel = 1,
  }) async {
    try {
      final gameCode = _generateGameCode();

      final response = await _supabase.client
          .from('live_games')
          .insert({
            'host_id': hostId,
            'game_type': gameType,
            'game_code': gameCode,
            'title': title ?? _getDefaultTitle(gameType),
            'description': description,
            'language_code': languageCode,
            'difficulty_level': difficultyLevel,
            'max_players': maxPlayers,
            'time_limit_seconds': timeLimitSeconds,
            'question_count': questionCount,
            'is_private': isPrivate,
            'password': password,
            'is_premium_only': isPremiumOnly,
            'status': 'waiting',
            'current_players': 1,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      // Add host as first player
      await _supabase.client.from('live_game_players').insert({
        'game_id': response['id'],
        'user_id': hostId,
        'is_ready': false,
        'joined_at': DateTime.now().toIso8601String(),
      });

      return response;
          return null;
    } catch (e) {
      _logger.e('Failed to create game', error: e);
      return null;
    }
  }

  String _getDefaultTitle(String gameType) {
    switch (gameType) {
      case 'word_race':
        return 'Word Race';
      case 'vocabulary_challenge':
        return 'Vocabulary Challenge';
      case 'translation_battle':
        return 'Translation Battle';
      case 'grammar_showdown':
        return 'Grammar Showdown';
      default:
        return 'Live Game';
    }
  }

  // Join an existing game
  Future<Map<String, dynamic>?> joinGame(
    String gameCode,
    String userId, {
    String? password,
  }) async {
    try {
      // Find game by code
      final gameResponse = await _supabase.client
          .from('live_games')
          .select()
          .eq('game_code', gameCode.toUpperCase())
          .eq('status', 'waiting')
          .single();

      // Check password if required
      if (gameResponse['is_private'] == true) {
        if (gameResponse['password'] != password) {
          throw Exception('Incorrect password');
        }
      }

      // Check if premium only
      if (gameResponse['is_premium_only'] == true) {
        final userResponse = await _supabase.client
            .from('users')
            .select('is_premium')
            .eq('id', userId)
            .single();

        if (userResponse['is_premium'] != true) {
          throw Exception('This game is for premium users only');
        }
      }

      // Check if game is full
      if (gameResponse['current_players'] >= gameResponse['max_players']) {
        throw Exception('Game is full');
      }

      // Check if user is already in game
      final existingPlayer = await _supabase.client
          .from('live_game_players')
          .select()
          .eq('game_id', gameResponse['id'])
          .eq('user_id', userId)
          .single();

      return gameResponse;
    } catch (e) {
      _logger.e('Failed to join game', error: e);
      rethrow;
    }
  }

  // Set player ready status
  Future<void> setReadyStatus(String gameId, String userId, bool isReady) async {
    try {
      await _supabase.client
          .from('live_game_players')
          .update({'is_ready': isReady})
          .eq('game_id', gameId)
          .eq('user_id', userId);
    } catch (e) {
      _logger.e('Failed to set ready status', error: e);
    }
  }

  // Start the game (host only)
  Future<void> startGame(String gameId, String hostId) async {
    try {
      // Verify user is host
      final gameResponse = await _supabase.client
          .from('live_games')
          .select()
          .eq('id', gameId)
          .eq('host_id', hostId)
          .single();

      // Check if all players are ready
      final playersResponse = await _supabase.client
          .from('live_game_players')
          .select('is_ready')
          .eq('game_id', gameId);

      final allReady = (playersResponse as List).every((p) => p['is_ready'] == true);
      if (!allReady) {
        throw Exception('Not all players are ready');
      }
    
      // Generate questions
      await _generateQuestions(gameId, gameResponse);

      // Update game status
      await _supabase.client
          .from('live_games')
          .update({
            'status': 'in_progress',
            'starts_at': DateTime.now().toIso8601String(),
          })
          .eq('id', gameId);
    } catch (e) {
      _logger.e('Failed to start game', error: e);
      rethrow;
    }
  }

  // Generate questions for the game
  Future<void> _generateQuestions(String gameId, Map<String, dynamic> gameData) async {
    try {
      final gameType = gameData['game_type'];
      final languageCode = gameData['language_code'];
      final difficultyLevel = gameData['difficulty_level'];
      final questionCount = gameData['question_count'];

      List<Map<String, dynamic>> questions = [];

      switch (gameType) {
        case 'word_race':
          questions = await _generateWordRaceQuestions(
            languageCode,
            difficultyLevel,
            questionCount,
          );
          break;
        case 'vocabulary_challenge':
          questions = await _generateVocabularyQuestions(
            languageCode,
            difficultyLevel,
            questionCount,
          );
          break;
        case 'translation_battle':
          questions = await _generateTranslationQuestions(
            languageCode,
            difficultyLevel,
            questionCount,
          );
          break;
        case 'grammar_showdown':
          questions = await _generateGrammarQuestions(
            languageCode,
            difficultyLevel,
            questionCount,
          );
          break;
      }

      // Insert questions
      for (var i = 0; i < questions.length; i++) {
        await _supabase.client.from('live_game_questions').insert({
          'game_id': gameId,
          'question_number': i + 1,
          'question_data': questions[i],
          'correct_answer': questions[i]['correct_answer'],
          'time_limit_seconds': gameData['time_limit_seconds'],
        });
      }
    } catch (e) {
      _logger.e('Failed to generate questions', error: e);
    }
  }

  Future<List<Map<String, dynamic>>> _generateWordRaceQuestions(
    String languageCode,
    int difficulty,
    int count,
  ) async {
    // Fetch random vocabulary words
    final response = await _supabase.client
        .from('vocabulary')
        .select('word, translation')
        .eq('course_id', languageCode)
        .eq('difficulty_level', difficulty)
        .limit(count * 2);

    final words = (response as List)..shuffle();
    final questions = <Map<String, dynamic>>[];

    for (var i = 0; i < min(count, words.length); i++) {
      final word = words[i];
      questions.add({
        'type': 'word_race',
        'question': 'Type this word: ${word['word']}',
        'correct_answer': word['word'],
        'hint': word['translation'],
      });
    }

    return questions;
  }

  Future<List<Map<String, dynamic>>> _generateVocabularyQuestions(
    String languageCode,
    int difficulty,
    int count,
  ) async {
    // Fetch vocabulary with multiple choice
    final response = await _supabase.client
        .from('vocabulary')
        .select('word, translation')
        .eq('course_id', languageCode)
        .eq('difficulty_level', difficulty)
        .limit(count * 4);

    if (response.length < 4) return [];

    final words = (response as List)..shuffle();
    final questions = <Map<String, dynamic>>[];

    for (var i = 0; i < min(count, words.length ~/ 4); i++) {
      final correctWord = words[i * 4];
      final options = words.sublist(i * 4, i * 4 + 4)
          .map((w) => w['translation'] as String)
          .toList()
        ..shuffle();

      questions.add({
        'type': 'multiple_choice',
        'question': 'What does "${correctWord['word']}" mean?',
        'options': options,
        'correct_answer': correctWord['translation'],
      });
    }

    return questions;
  }

  Future<List<Map<String, dynamic>>> _generateTranslationQuestions(
    String languageCode,
    int difficulty,
    int count,
  ) async {
    // Similar to vocabulary but for translation
    final response = await _supabase.client
        .from('vocabulary')
        .select('word, translation, example_sentences')
        .eq('course_id', languageCode)
        .eq('difficulty_level', difficulty)
        .limit(count);

    final words = (response as List)..shuffle();
    final questions = <Map<String, dynamic>>[];

    for (var i = 0; i < min(count, words.length); i++) {
      final word = words[i];
      final examples = word['example_sentences'] as List? ?? [];
      
      questions.add({
        'type': 'translation',
        'question': examples.isNotEmpty 
            ? 'Translate: "${examples[0]}"'
            : 'Translate: "${word['word']}"',
        'correct_answer': word['translation'],
        'hint': word['word'],
      });
    }

    return questions;
  }

  Future<List<Map<String, dynamic>>> _generateGrammarQuestions(
    String languageCode,
    int difficulty,
    int count,
  ) async {
    // Fetch grammar exercises
    final response = await _supabase.client
        .from('grammar_rules')
        .select('exercises')
        .eq('course_id', languageCode)
        .eq('difficulty_level', difficulty)
        .limit(count);

    final questions = <Map<String, dynamic>>[];
    
    for (var item in response) {
      final exercises = item['exercises'] as List? ?? [];
      if (exercises.isNotEmpty) {
        final exercise = exercises[Random().nextInt(exercises.length)];
        questions.add({
          'type': 'grammar',
          'question': exercise['question'],
          'options': exercise['options'],
          'correct_answer': exercise['correct_answer'],
        });
      }
    }

    return questions.take(count).toList();
  }

  // Submit answer
  Future<Map<String, dynamic>?> submitAnswer(
    String gameId,
    String userId,
    String questionId,
    String answer,
    int responseTimeMs,
  ) async {
    try {
      // Get the question
      final questionResponse = await _supabase.client
          .from('live_game_questions')
          .select()
          .eq('id', questionId)
          .single();

      final correctAnswer = questionResponse['correct_answer'];
      final isCorrect = answer.toLowerCase().trim() == correctAnswer.toString().toLowerCase().trim();

      // Calculate points (faster = more points)
      int points = 0;
      if (isCorrect) {
        final maxTime = questionResponse['time_limit_seconds'] * 1000;
        final timeBonus = ((1 - (responseTimeMs / maxTime)) * 50).round();
        points = 100 + timeBonus.clamp(0, 50);
      }

      // Save answer
      await _supabase.client.from('live_game_answers').insert({
        'game_id': gameId,
        'player_id': await _getPlayerId(gameId, userId),
        'question_id': questionId,
        'answer': answer,
        'is_correct': isCorrect,
        'response_time_ms': responseTimeMs,
        'points_earned': points,
      });

      // Update player score
      await _updatePlayerScore(gameId, userId, points, isCorrect);

      return {
        'is_correct': isCorrect,
        'correct_answer': correctAnswer,
        'points_earned': points,
      };
    } catch (e) {
      _logger.e('Failed to submit answer', error: e);
      return null;
    }
  }

  Future<String?> _getPlayerId(String gameId, String userId) async {
    try {
      final response = await _supabase.client
          .from('live_game_players')
          .select('id')
          .eq('game_id', gameId)
          .eq('user_id', userId)
          .single();

      return response['id'];
    } catch (e) {
      return null;
    }
  }

  Future<void> _updatePlayerScore(
    String gameId,
    String userId,
    int points,
    bool isCorrect,
  ) async {
    try {
      final playerResponse = await _supabase.client
          .from('live_game_players')
          .select('score, correct_answers, incorrect_answers')
          .eq('game_id', gameId)
          .eq('user_id', userId)
          .single();

      await _supabase.client
          .from('live_game_players')
          .update({
            'score': (playerResponse['score'] ?? 0) + points,
            'correct_answers': (playerResponse['correct_answers'] ?? 0) + (isCorrect ? 1 : 0),
            'incorrect_answers': (playerResponse['incorrect_answers'] ?? 0) + (isCorrect ? 0 : 1),
          })
          .eq('game_id', gameId)
          .eq('user_id', userId);
        } catch (e) {
      _logger.e('Failed to update player score', error: e);
    }
  }

  // End game
  Future<void> endGame(String gameId, String hostId) async {
    try {
      // Verify user is host
      final gameResponse = await _supabase.client
          .from('live_games')
          .select()
          .eq('id', gameId)
          .eq('host_id', hostId)
          .single();

      // Calculate final rankings
      await _calculateRankings(gameId);

      // Update game status
      await _supabase.client
          .from('live_games')
          .update({
            'status': 'finished',
            'ended_at': DateTime.now().toIso8601String(),
          })
          .eq('id', gameId);
    } catch (e) {
      _logger.e('Failed to end game', error: e);
      rethrow;
    }
  }

  Future<void> _calculateRankings(String gameId) async {
    try {
      final playersResponse = await _supabase.client
          .from('live_game_players')
          .select('id, score')
          .eq('game_id', gameId)
          .order('score', ascending: false);

      final players = playersResponse as List;
      for (var i = 0; i < players.length; i++) {
        await _supabase.client
            .from('live_game_players')
            .update({'rank': i + 1})
            .eq('id', players[i]['id']);
      }
        } catch (e) {
      _logger.e('Failed to calculate rankings', error: e);
    }
  }

  // Get available games
  Future<List<Map<String, dynamic>>> getAvailableGames(String languageCode) async {
    try {
      final response = await _supabase.client
          .from('live_games')
          .select('*, host:host_id(username, avatar_url)')
          .eq('language_code', languageCode)
          .eq('status', 'waiting')
          .eq('is_private', false)
          .order('created_at', ascending: false)
          .limit(20);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      _logger.e('Failed to get available games', error: e);
      return [];
    }
  }

  // Subscribe to game updates
  void subscribeToGameUpdates(String gameId, {
    Function(Map<String, dynamic>)? onGameUpdate,
    Function(Map<String, dynamic>)? onPlayerUpdate,
    Function(Map<String, dynamic>)? onNewQuestion,
  }) {
    this.onGameUpdate = onGameUpdate;
    this.onPlayerUpdate = onPlayerUpdate;
    this.onNewQuestion = onNewQuestion;

    _gameSubscription = _supabase.client
        .from('live_games')
        .stream(primaryKey: ['id'])
        .eq('id', gameId)
        .listen((data) {
          if (data.isNotEmpty && onGameUpdate != null) {
            onGameUpdate(data.first);
          }
        });
  }

  // Leave game
  Future<void> leaveGame(String gameId, String userId) async {
    try {
      await _supabase.client
          .from('live_game_players')
          .update({'left_at': DateTime.now().toIso8601String()})
          .eq('game_id', gameId)
          .eq('user_id', userId);

      // Update player count
      final gameResponse = await _supabase.client
          .from('live_games')
          .select('current_players')
          .eq('id', gameId)
          .single();

      await _supabase.client
          .from('live_games')
          .update({'current_players': max<int>(0, ((gameResponse['current_players'] ?? 1) as int) - 1)})
          .eq('id', gameId);
        } catch (e) {
      _logger.e('Failed to leave game', error: e);
    }
  }

  // ==================== RECONNECTION LOGIC ====================
  
  /// Check if user can reconnect to an active game
  Future<Map<String, dynamic>?> checkReconnectionAvailability(String userId) async {
    try {
      // Find any in-progress games where this user is a player
      final response = await _supabase.client
          .from('live_game_players')
          .select('*, game:game_id(*)')
          .eq('user_id', userId)
          .eq('game.status', 'in_progress')
          .isFilter('left_at', null)
          .order('joined_at', ascending: false)
          .limit(1)
          .single();

      return {
        'can_reconnect': true,
        'game': response['game'],
        'player_data': response,
      };
          return null;
    } catch (e) {
      _logger.d('No active game found for reconnection');
      return null;
    }
  }

  /// Reconnect to an active game
  Future<Map<String, dynamic>?> reconnectToGame(String gameId, String userId) async {
    try {
      // Get current game state
      final gameResponse = await _supabase.client
          .from('live_games')
          .select('*, questions:live_game_questions(*)')
          .eq('id', gameId)
          .single();

      // Get player progress
      final playerResponse = await _supabase.client
          .from('live_game_players')
          .select('*')
          .eq('game_id', gameId)
          .eq('user_id', userId)
          .single();

      // Get last answered question
      final lastAnswerResponse = await _supabase.client
          .from('live_game_answers')
          .select('*, question:question_id(question_number)')
          .eq('game_id', gameId)
          .eq('player_id', playerResponse['id'])
          .order('created_at', ascending: false)
          .limit(1)
          .single();

      int currentQuestionIndex = 0;
      currentQuestionIndex = (lastAnswerResponse['question']?['question_number'] as int? ?? 0);
    
      return {
        'game': gameResponse,
        'player': playerResponse,
        'current_question_index': currentQuestionIndex,
        'questions': gameResponse['questions'] ?? [],
      };
    } catch (e) {
      _logger.e('Failed to reconnect to game', error: e);
      rethrow;
    }
  }

  /// Mark player as disconnected (called when app loses connection)
  Future<void> markPlayerDisconnected(String gameId, String userId) async {
    try {
      await _supabase.client
          .from('live_game_players')
          .update({
            'is_disconnected': true,
            'disconnected_at': DateTime.now().toIso8601String(),
          })
          .eq('game_id', gameId)
          .eq('user_id', userId);
    } catch (e) {
      _logger.e('Failed to mark player disconnected', error: e);
    }
  }

  /// Mark player as reconnected
  Future<void> markPlayerReconnected(String gameId, String userId) async {
    try {
      await _supabase.client
          .from('live_game_players')
          .update({
            'is_disconnected': false,
            'disconnected_at': null,
            'reconnected_at': DateTime.now().toIso8601String(),
          })
          .eq('game_id', gameId)
          .eq('user_id', userId);
    } catch (e) {
      _logger.e('Failed to mark player reconnected', error: e);
    }
  }

  // ==================== SPECTATOR MODE ====================
  
  /// Join game as spectator
  Future<Map<String, dynamic>?> joinAsSpectator(String gameId, String userId) async {
    try {
      final gameResponse = await _supabase.client
          .from('live_games')
          .select()
          .eq('id', gameId)
          .single();

      if (gameResponse['allow_spectators'] != true) {
        throw Exception('Spectator mode is not enabled for this game');
      }

      // Add spectator
      await _supabase.client.from('live_game_spectators').insert({
        'game_id': gameId,
        'user_id': userId,
        'joined_at': DateTime.now().toIso8601String(),
      });

      // Update spectator count
      await _supabase.client
          .from('live_games')
          .update({
            'spectator_count': (gameResponse['spectator_count'] ?? 0) + 1,
          })
          .eq('id', gameId);

      return gameResponse;
    } catch (e) {
      _logger.e('Failed to join as spectator', error: e);
      rethrow;
    }
  }

  /// Leave spectator mode
  Future<void> leaveSpectatorMode(String gameId, String userId) async {
    try {
      await _supabase.client
          .from('live_game_spectators')
          .update({'left_at': DateTime.now().toIso8601String()})
          .eq('game_id', gameId)
          .eq('user_id', userId);

      // Update spectator count
      final gameResponse = await _supabase.client
          .from('live_games')
          .select('spectator_count')
          .eq('id', gameId)
          .single();

      await _supabase.client
          .from('live_games')
          .update({
            'spectator_count': max(0, ((gameResponse['spectator_count'] ?? 1) as int) - 1),
          })
          .eq('id', gameId);
        } catch (e) {
      _logger.e('Failed to leave spectator mode', error: e);
    }
  }

  /// Get games available for spectating
  Future<List<Map<String, dynamic>>> getSpectatableGames() async {
    try {
      final response = await _supabase.client
          .from('live_games')
          .select('*, host:host_id(username, avatar_url), player_count:live_game_players(count)')
          .eq('status', 'in_progress')
          .eq('allow_spectators', true)
          .order('created_at', ascending: false)
          .limit(20);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      _logger.e('Failed to get spectatable games', error: e);
      return [];
    }
  }

  // ==================== INVITE BY USERNAME ====================
  
  /// Search users by username
  Future<List<Map<String, dynamic>>> searchUsersByUsername(String query) async {
    try {
      final response = await _supabase.client
          .from('users')
          .select('id, username, avatar_url, is_premium')
          .ilike('username', '%$query%')
          .limit(20);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      _logger.e('Failed to search users', error: e);
      return [];
    }
  }

  /// Invite user to game by username
  Future<void> inviteUserByUsername({
    required String gameId,
    required String inviterId,
    required String username,
  }) async {
    try {
      // Find user by username
      final userResponse = await _supabase.client
          .from('users')
          .select('id')
          .eq('username', username)
          .single();

      final inviteeId = userResponse['id'];

      // Check if already invited
      final existingInvite = await _supabase.client
          .from('live_game_invites')
          .select()
          .eq('game_id', gameId)
          .eq('invitee_id', inviteeId)
          .eq('status', 'pending')
          .single();

      throw Exception('User already invited');
    
      // Create invite
      await _supabase.client.from('live_game_invites').insert({
        'game_id': gameId,
        'inviter_id': inviterId,
        'invitee_id': inviteeId,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      _logger.e('Failed to invite user', error: e);
      rethrow;
    }
  }

  /// Get pending invites for a user
  Future<List<Map<String, dynamic>>> getPendingInvites(String userId) async {
    try {
      final response = await _supabase.client
          .from('live_game_invites')
          .select('*, game:game_id(title, game_code), inviter:inviter_id(username, avatar_url)')
          .eq('invitee_id', userId)
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      _logger.e('Failed to get pending invites', error: e);
      return [];
    }
  }

  /// Respond to invite
  Future<void> respondToInvite({
    required String inviteId,
    required bool accept,
  }) async {
    try {
      await _supabase.client
          .from('live_game_invites')
          .update({
            'status': accept ? 'accepted' : 'declined',
            'responded_at': DateTime.now().toIso8601String(),
          })
          .eq('id', inviteId);
    } catch (e) {
      _logger.e('Failed to respond to invite', error: e);
      rethrow;
    }
  }

  void dispose() {
    _gameSubscription?.cancel();
  }
}
