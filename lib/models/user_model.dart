
class UserModel {
  final String id;
  final String email;
  final String username;
  final String? displayName;
  final String? avatarUrl;
  final String? bio;
  final String nativeLanguage;
  final List<String> learningLanguages;
  final int totalXP;
  final int currentLevel;
  final int streakDays;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String subscriptionTier;
  final DateTime? subscriptionExpiry;
  final bool isPremium;
  final bool isActive;
  final String privacyLevel;
  final int totalGamesPlayed;
  final int totalGamesWon;
  final int totalFriends;
  final int rank;
  final String? country;
  final DateTime? lastActiveAt;
  final List<String>? achievements;
  final Map<String, dynamic>? settings;

  UserModel({
    required this.id,
    required this.email,
    required this.username,
    this.displayName,
    this.avatarUrl,
    this.bio,
    required this.nativeLanguage,
    required this.learningLanguages,
    required this.totalXP,
    required this.currentLevel,
    required this.streakDays,
    required this.createdAt,
    required this.updatedAt,
    this.subscriptionTier = 'free',
    this.subscriptionExpiry,
    this.isPremium = false,
    this.isActive = true,
    this.privacyLevel = 'public',
    this.totalGamesPlayed = 0,
    this.totalGamesWon = 0,
    this.totalFriends = 0,
    this.rank = 0,
    this.country,
    this.lastActiveAt,
    this.achievements,
    this.settings,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      username: json['username'] ?? 'Anonymous',
      displayName: json['display_name'],
      avatarUrl: json['avatar_url'],
      bio: json['bio'],
      nativeLanguage: json['native_language'] ?? 'en',
      learningLanguages: List<String>.from(json['learning_languages'] ?? []),
      totalXP: json['total_xp'] ?? 0,
      currentLevel: json['current_level'] ?? 1,
      streakDays: json['streak_days'] ?? 0,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : DateTime.now(),
      subscriptionTier: json['subscription_tier'] ?? 'free',
      subscriptionExpiry: json['subscription_expiry'] != null
          ? DateTime.parse(json['subscription_expiry'])
          : null,
      isPremium: json['is_premium'] ?? false,
      isActive: json['is_active'] ?? true,
      privacyLevel: json['privacy_level'] ?? 'public',
      totalGamesPlayed: json['total_games_played'] ?? 0,
      totalGamesWon: json['total_games_won'] ?? 0,
      totalFriends: json['total_friends'] ?? 0,
      rank: json['rank'] ?? 0,
      country: json['country'],
      lastActiveAt: json['last_active_at'] != null
          ? DateTime.parse(json['last_active_at'])
          : null,
      achievements: json['achievements'] != null
          ? List<String>.from(json['achievements'])
          : null,
      settings: json['settings'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'bio': bio,
      'native_language': nativeLanguage,
      'learning_languages': learningLanguages,
      'total_xp': totalXP,
      'current_level': currentLevel,
      'streak_days': streakDays,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'subscription_tier': subscriptionTier,
      'subscription_expiry': subscriptionExpiry?.toIso8601String(),
      'is_premium': isPremium,
      'is_active': isActive,
      'privacy_level': privacyLevel,
      'total_games_played': totalGamesPlayed,
      'total_games_won': totalGamesWon,
      'total_friends': totalFriends,
      'rank': rank,
      'country': country,
      'last_active_at': lastActiveAt?.toIso8601String(),
      'achievements': achievements,
      'settings': settings,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? username,
    String? displayName,
    String? avatarUrl,
    String? bio,
    String? nativeLanguage,
    List<String>? learningLanguages,
    int? totalXP,
    int? currentLevel,
    int? streakDays,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? subscriptionTier,
    DateTime? subscriptionExpiry,
    bool? isPremium,
    bool? isActive,
    String? privacyLevel,
    int? totalGamesPlayed,
    int? totalGamesWon,
    int? totalFriends,
    int? rank,
    String? country,
    DateTime? lastActiveAt,
    List<String>? achievements,
    Map<String, dynamic>? settings,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      nativeLanguage: nativeLanguage ?? this.nativeLanguage,
      learningLanguages: learningLanguages ?? this.learningLanguages,
      totalXP: totalXP ?? this.totalXP,
      currentLevel: currentLevel ?? this.currentLevel,
      streakDays: streakDays ?? this.streakDays,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      subscriptionTier: subscriptionTier ?? this.subscriptionTier,
      subscriptionExpiry: subscriptionExpiry ?? this.subscriptionExpiry,
      isPremium: isPremium ?? this.isPremium,
      isActive: isActive ?? this.isActive,
      privacyLevel: privacyLevel ?? this.privacyLevel,
      totalGamesPlayed: totalGamesPlayed ?? this.totalGamesPlayed,
      totalGamesWon: totalGamesWon ?? this.totalGamesWon,
      totalFriends: totalFriends ?? this.totalFriends,
      rank: rank ?? this.rank,
      country: country ?? this.country,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      achievements: achievements ?? this.achievements,
      settings: settings ?? this.settings,
    );
  }
}

class UserStats {
  final String userId;
  final int totalXP;
  final int currentLevel;
  final int streakDays;
  final int totalGamesPlayed;
  final int totalGamesWon;
  final int totalFriends;
  final double winRate;
  final int averageScore;
  final int bestScore;
  final int rank;
  final int globalRank;
  final Map<String, int> languageXP;
  final Map<String, int> categoryStats;
  final DateTime updatedAt;

  UserStats({
    required this.userId,
    required this.totalXP,
    required this.currentLevel,
    required this.streakDays,
    required this.totalGamesPlayed,
    required this.totalGamesWon,
    required this.totalFriends,
    required this.winRate,
    required this.averageScore,
    required this.bestScore,
    required this.rank,
    required this.globalRank,
    required this.languageXP,
    required this.categoryStats,
    required this.updatedAt,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      userId: json['user_id'] ?? '',
      totalXP: json['total_xp'] ?? 0,
      currentLevel: json['current_level'] ?? 1,
      streakDays: json['streak_days'] ?? 0,
      totalGamesPlayed: json['total_games_played'] ?? 0,
      totalGamesWon: json['total_games_won'] ?? 0,
      totalFriends: json['total_friends'] ?? 0,
      winRate: (json['win_rate'] ?? 0).toDouble(),
      averageScore: json['average_score'] ?? 0,
      bestScore: json['best_score'] ?? 0,
      rank: json['rank'] ?? 0,
      globalRank: json['global_rank'] ?? 0,
      languageXP: Map<String, int>.from(json['language_xp'] ?? {}),
      categoryStats: Map<String, int>.from(json['category_stats'] ?? {}),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : DateTime.now(),
    );
  }
}
