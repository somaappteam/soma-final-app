class LeaderboardEntry {
  final String userId;
  final String username;
  final String? avatarUrl;
  final int rank;
  final int totalXP;
  final int currentLevel;
  final int gamesPlayed;
  final int gamesWon;
  final double winRate;
  final bool isPremium;

  LeaderboardEntry({
    required this.userId,
    required this.username,
    this.avatarUrl,
    required this.rank,
    required this.totalXP,
    required this.currentLevel,
    required this.gamesPlayed,
    required this.gamesWon,
    required this.winRate,
    this.isPremium = false,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    final totalPlayed = json['total_games_played'] ?? 0;
    final totalWon = json['total_games_won'] ?? 0;
    final winRate = totalPlayed > 0 ? (totalWon / totalPlayed) * 100.0 : 0.0;
    
    return LeaderboardEntry(
      userId: json['id'] ?? json['user_id'] ?? '',
      username: json['username'] ?? 'Anonymous',
      avatarUrl: json['avatar_url'],
      rank: json['rank'] ?? 0,
      totalXP: json['total_xp'] ?? 0,
      currentLevel: json['current_level'] ?? json['level'] ?? 1,
      gamesPlayed: totalPlayed,
      gamesWon: totalWon,
      winRate: (json['win_rate'] ?? winRate).toDouble(),
      isPremium: json['is_premium'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'username': username,
      'avatar_url': avatarUrl,
      'rank': rank,
      'total_xp': totalXP,
      'current_level': currentLevel,
      'total_games_played': gamesPlayed,
      'total_games_won': gamesWon,
      'win_rate': winRate,
      'is_premium': isPremium,
    };
  }
}
