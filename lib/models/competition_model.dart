class CompetitionModel {
  final String id;
  final String hostId;
  final String hostName;
  final String? hostAvatarUrl;
  final String title;
  final String? description;
  final String gameType;
  final String language;
  final String difficulty;
  final int maxPlayers;
  final int currentPlayers;
  final String status;
  final DateTime createdAt;
  final DateTime scheduledStart;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final int durationMinutes;
  final bool isPrivate;
  final String? inviteCode;
  final bool isPremiumOnly;
  final int entryFee;
  final int prizeXP;
  final List<String>? allowedCategories;
  final Map<String, dynamic>? gameSettings;
  final List<CompetitionPlayer>? players;
  final List<CompetitionRound>? rounds;
  final CompetitionResult? result;
  final bool allowSpectators;
  final int? spectatorCount;
  final String? chatRoomId;

  CompetitionModel({
    required this.id,
    required this.hostId,
    required this.hostName,
    this.hostAvatarUrl,
    required this.title,
    this.description,
    required this.gameType,
    required this.language,
    required this.difficulty,
    required this.maxPlayers,
    required this.currentPlayers,
    required this.status,
    required this.createdAt,
    required this.scheduledStart,
    this.startedAt,
    this.endedAt,
    required this.durationMinutes,
    this.isPrivate = false,
    this.inviteCode,
    this.isPremiumOnly = false,
    required this.entryFee,
    required this.prizeXP,
    this.allowedCategories,
    this.gameSettings,
    this.players,
    this.rounds,
    this.result,
    this.allowSpectators = false,
    this.spectatorCount,
    this.chatRoomId,
  });

  factory CompetitionModel.fromJson(Map<String, dynamic> json) {
    return CompetitionModel(
      id: json['id'],
      hostId: json['host_id'],
      hostName: json['host_name'],
      hostAvatarUrl: json['host_avatar_url'],
      title: json['title'],
      description: json['description'],
      gameType: json['game_type'],
      language: json['language'],
      difficulty: json['difficulty'],
      maxPlayers: json['max_players'],
      currentPlayers: json['current_players'],
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
      scheduledStart: DateTime.parse(json['scheduled_start']),
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'])
          : null,
      endedAt: json['ended_at'] != null
          ? DateTime.parse(json['ended_at'])
          : null,
      durationMinutes: json['duration_minutes'],
      isPrivate: json['is_private'] ?? false,
      inviteCode: json['invite_code'],
      isPremiumOnly: json['is_premium_only'] ?? false,
      entryFee: json['entry_fee'],
      prizeXP: json['prize_xp'],
      allowedCategories: json['allowed_categories'] != null
          ? List<String>.from(json['allowed_categories'])
          : null,
      gameSettings: json['game_settings'],
      players: json['players'] != null
          ? (json['players'] as List)
              .map((p) => CompetitionPlayer.fromJson(p))
              .toList()
          : null,
      rounds: json['rounds'] != null
          ? (json['rounds'] as List)
              .map((r) => CompetitionRound.fromJson(r))
              .toList()
          : null,
      result: json['result'] != null
          ? CompetitionResult.fromJson(json['result'])
          : null,
      allowSpectators: json['allow_spectators'] ?? false,
      spectatorCount: json['spectator_count'],
      chatRoomId: json['chat_room_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'host_id': hostId,
      'host_name': hostName,
      'host_avatar_url': hostAvatarUrl,
      'title': title,
      'description': description,
      'game_type': gameType,
      'language': language,
      'difficulty': difficulty,
      'max_players': maxPlayers,
      'current_players': currentPlayers,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'scheduled_start': scheduledStart.toIso8601String(),
      'started_at': startedAt?.toIso8601String(),
      'ended_at': endedAt?.toIso8601String(),
      'duration_minutes': durationMinutes,
      'is_private': isPrivate,
      'invite_code': inviteCode,
      'is_premium_only': isPremiumOnly,
      'entry_fee': entryFee,
      'prize_xp': prizeXP,
      'allowed_categories': allowedCategories,
      'game_settings': gameSettings,
      'allow_spectators': allowSpectators,
      'spectator_count': spectatorCount,
      'chat_room_id': chatRoomId,
    };
  }
}

class CompetitionPlayer {
  final String userId;
  final String username;
  final String? avatarUrl;
  final DateTime joinedAt;
  final int score;
  final int correctAnswers;
  final int wrongAnswers;
  final int streak;
  final bool isHost;
  final bool isReady;
  final bool isActive;
  final DateTime? lastActiveAt;
  final String? status;

  CompetitionPlayer({
    required this.userId,
    required this.username,
    this.avatarUrl,
    required this.joinedAt,
    this.score = 0,
    this.correctAnswers = 0,
    this.wrongAnswers = 0,
    this.streak = 0,
    this.isHost = false,
    this.isReady = false,
    this.isActive = true,
    this.lastActiveAt,
    this.status,
  });

  factory CompetitionPlayer.fromJson(Map<String, dynamic> json) {
    return CompetitionPlayer(
      userId: json['user_id'],
      username: json['username'],
      avatarUrl: json['avatar_url'],
      joinedAt: DateTime.parse(json['joined_at']),
      score: json['score'] ?? 0,
      correctAnswers: json['correct_answers'] ?? 0,
      wrongAnswers: json['wrong_answers'] ?? 0,
      streak: json['streak'] ?? 0,
      isHost: json['is_host'] ?? false,
      isReady: json['is_ready'] ?? false,
      isActive: json['is_active'] ?? true,
      lastActiveAt: json['last_active_at'] != null
          ? DateTime.parse(json['last_active_at'])
          : null,
      status: json['status'],
    );
  }
}

class CompetitionRound {
  final int roundNumber;
  final String questionId;
  final String question;
  final List<String> options;
  final String correctAnswer;
  final int timeLimitSeconds;
  final DateTime startedAt;
  final Map<String, PlayerAnswer>? playerAnswers;

  CompetitionRound({
    required this.roundNumber,
    required this.questionId,
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.timeLimitSeconds,
    required this.startedAt,
    this.playerAnswers,
  });

  factory CompetitionRound.fromJson(Map<String, dynamic> json) {
    return CompetitionRound(
      roundNumber: json['round_number'],
      questionId: json['question_id'],
      question: json['question'],
      options: List<String>.from(json['options']),
      correctAnswer: json['correct_answer'],
      timeLimitSeconds: json['time_limit_seconds'],
      startedAt: DateTime.parse(json['started_at']),
      playerAnswers: json['player_answers'] != null
          ? Map<String, PlayerAnswer>.from(
              (json['player_answers'] as Map).map(
                (key, value) => MapEntry(
                  key.toString(),
                  PlayerAnswer.fromJson(value),
                ),
              ),
            )
          : null,
    );
  }
}

class PlayerAnswer {
  final String userId;
  final String answer;
  final DateTime answeredAt;
  final bool isCorrect;
  final int timeTakenMs;
  final int pointsEarned;

  PlayerAnswer({
    required this.userId,
    required this.answer,
    required this.answeredAt,
    required this.isCorrect,
    required this.timeTakenMs,
    required this.pointsEarned,
  });

  factory PlayerAnswer.fromJson(Map<String, dynamic> json) {
    return PlayerAnswer(
      userId: json['user_id'],
      answer: json['answer'],
      answeredAt: DateTime.parse(json['answered_at']),
      isCorrect: json['is_correct'],
      timeTakenMs: json['time_taken_ms'],
      pointsEarned: json['points_earned'],
    );
  }
}

class CompetitionResult {
  final List<CompetitionPlayer> finalStandings;
  final DateTime completedAt;
  final int totalRounds;
  final String? winnerId;
  final String? winnerName;
  final Map<String, int> xpEarned;
  final Map<String, List<String>> achievementsUnlocked;

  CompetitionResult({
    required this.finalStandings,
    required this.completedAt,
    required this.totalRounds,
    this.winnerId,
    this.winnerName,
    required this.xpEarned,
    required this.achievementsUnlocked,
  });

  factory CompetitionResult.fromJson(Map<String, dynamic> json) {
    return CompetitionResult(
      finalStandings: (json['final_standings'] as List)
          .map((p) => CompetitionPlayer.fromJson(p))
          .toList(),
      completedAt: DateTime.parse(json['completed_at']),
      totalRounds: json['total_rounds'],
      winnerId: json['winner_id'],
      winnerName: json['winner_name'],
      xpEarned: Map<String, int>.from(json['xp_earned'] ?? {}),
      achievementsUnlocked:
          Map<String, List<String>>.from(json['achievements_unlocked'] ?? {}),
    );
  }
}

class GameInvite {
  final String id;
  final String competitionId;
  final String inviterId;
  final String inviterName;
  final String? inviterAvatarUrl;
  final String inviteeId;
  final DateTime createdAt;
  final String status;
  final DateTime? respondedAt;
  final String? competitionTitle;

  GameInvite({
    required this.id,
    required this.competitionId,
    required this.inviterId,
    required this.inviterName,
    this.inviterAvatarUrl,
    required this.inviteeId,
    required this.createdAt,
    this.status = 'pending',
    this.respondedAt,
    this.competitionTitle,
  });

  factory GameInvite.fromJson(Map<String, dynamic> json) {
    return GameInvite(
      id: json['id'],
      competitionId: json['competition_id'],
      inviterId: json['inviter_id'],
      inviterName: json['inviter_name'],
      inviterAvatarUrl: json['inviter_avatar_url'],
      inviteeId: json['invitee_id'],
      createdAt: DateTime.parse(json['created_at']),
      status: json['status'] ?? 'pending',
      respondedAt: json['responded_at'] != null
          ? DateTime.parse(json['responded_at'])
          : null,
      competitionTitle: json['competition_title'],
    );
  }
}

class ActiveGame {
  final String id;
  final String title;
  final String hostName;
  final String? hostAvatarUrl;
  final String gameType;
  final String language;
  final String difficulty;
  final int maxPlayers;
  final int currentPlayers;
  final DateTime createdAt;
  final String status;
  final bool isPrivate;
  final bool isPremiumOnly;
  final int entryFee;
  final int prizeXP;
  final int? timeRemaining;

  ActiveGame({
    required this.id,
    required this.title,
    required this.hostName,
    this.hostAvatarUrl,
    required this.gameType,
    required this.language,
    required this.difficulty,
    required this.maxPlayers,
    required this.currentPlayers,
    required this.createdAt,
    required this.status,
    this.isPrivate = false,
    this.isPremiumOnly = false,
    required this.entryFee,
    required this.prizeXP,
    this.timeRemaining,
  });

  factory ActiveGame.fromJson(Map<String, dynamic> json) {
    return ActiveGame(
      id: json['id'],
      title: json['title'],
      hostName: json['host_name'],
      hostAvatarUrl: json['host_avatar_url'],
      gameType: json['game_type'],
      language: json['language'],
      difficulty: json['difficulty'],
      maxPlayers: json['max_players'],
      currentPlayers: json['current_players'],
      createdAt: DateTime.parse(json['created_at']),
      status: json['status'],
      isPrivate: json['is_private'] ?? false,
      isPremiumOnly: json['is_premium_only'] ?? false,
      entryFee: json['entry_fee'],
      prizeXP: json['prize_xp'],
      timeRemaining: json['time_remaining'],
    );
  }
}
