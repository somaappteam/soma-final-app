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
  final String? country;

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
    this.country,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      userId: json['user_id'] ?? '',
      username: json['username'] ?? 'Anonymous',
      avatarUrl: json['avatar_url'],
      rank: json['rank'] ?? 0,
      totalXP: json['total_xp'] ?? 0,
      currentLevel: json['current_level'] ?? 1,
      gamesPlayed: json['games_played'] ?? 0,
      gamesWon: json['games_won'] ?? 0,
      winRate: (json['win_rate'] ?? 0).toDouble(),
      isPremium: json['is_premium'] ?? false,
      country: json['country'],
    );
  }
}

class LeaderboardCategory {
  final String id;
  final String name;
  final String description;
  final String icon;
  final String type;

  LeaderboardCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.type,
  });

  static List<LeaderboardCategory> get categories => [
    LeaderboardCategory(
      id: 'global',
      name: 'Global',
      description: 'Top players worldwide',
      icon: '🌍',
      type: 'global',
    ),
    LeaderboardCategory(
      id: 'friends',
      name: 'Friends',
      description: 'Compete with friends',
      icon: '👥',
      type: 'friends',
    ),
    LeaderboardCategory(
      id: 'weekly',
      name: 'Weekly',
      description: 'This week\'s top performers',
      icon: '📅',
      type: 'time_period',
    ),
    LeaderboardCategory(
      id: 'language',
      name: 'By Language',
      description: 'Rankings by language',
      icon: '🗣️',
      type: 'language',
    ),
    LeaderboardCategory(
      id: 'competition',
      name: 'Competitions',
      description: 'Tournament winners',
      icon: '🏆',
      type: 'competition',
    ),
  ];
}

class SeasonInfo {
  final String id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final String? theme;
  final List<SeasonReward> rewards;

  SeasonInfo({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    this.theme,
    required this.rewards,
  });

  factory SeasonInfo.fromJson(Map<String, dynamic> json) {
    return SeasonInfo(
      id: json['id'],
      name: json['name'],
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      theme: json['theme'],
      rewards: (json['rewards'] as List)
          .map((r) => SeasonReward.fromJson(r))
          .toList(),
    );
  }
}

class SeasonReward {
  final int rank;
  final String name;
  final String description;
  final String type;
  final String? iconUrl;
  final int xpBonus;

  SeasonReward({
    required this.rank,
    required this.name,
    required this.description,
    required this.type,
    this.iconUrl,
    required this.xpBonus,
  });

  factory SeasonReward.fromJson(Map<String, dynamic> json) {
    return SeasonReward(
      rank: json['rank'],
      name: json['name'],
      description: json['description'],
      type: json['type'],
      iconUrl: json['icon_url'],
      xpBonus: json['xp_bonus'],
    );
  }
}
