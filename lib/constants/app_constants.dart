class AppConstants {
  // App Info
  static const String appName = 'Soma';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';

  // Premium Tiers
  static const String freeTier = 'free';
  static const String premiumMonthly = 'premium_monthly';
  static const String premiumYearly = 'premium_yearly';
  static const String premiumLifetime = 'premium_lifetime';

  // Game Constants
  static const int maxPlayersPerGame = 8;
  static const int minPlayersPerGame = 2;
  static const int gameExpiryHours = 24;
  static const int maxFriendsFree = 50;
  static const int maxFriendsPremium = 500;
  static const int maxMessageHistoryDaysFree = 7;
  static const int maxMessageHistoryDaysPremium = 365;

  // XP Multipliers
  static const double xpMultiplierFree = 1.0;
  static const double xpMultiplierPremium = 2.0;
  static const int dailyXPCapFree = 500;
  static const int dailyXPCapPremium = 10000;

  // Timeouts
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration connectionTimeout = Duration(seconds: 10);
  static const Duration gameTurnTimeout = Duration(minutes: 2);
  static const Duration matchmakingTimeout = Duration(minutes: 5);

  // Cache
  static const Duration cacheExpiry = Duration(hours: 1);
  static const int maxCacheSizeMB = 100;

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Leaderboard
  static const int leaderboardTopCount = 100;
  static const int leaderboardFriendsCount = 50;

  // Notification Types
  static const String notificationGameInvite = 'game_invite';
  static const String notificationFriendRequest = 'friend_request';
  static const String notificationGameStarted = 'game_started';
  static const String notificationGameEnded = 'game_ended';
  static const String notificationMessage = 'message';
  static const String notificationAchievement = 'achievement';
  static const String notificationLeaderboard = 'leaderboard';
  static const String notificationDailyReminder = 'daily_reminder';

  // Game Status
  static const String gameStatusWaiting = 'waiting';
  static const String gameStatusActive = 'active';
  static const String gameStatusPaused = 'paused';
  static const String gameStatusCompleted = 'completed';
  static const String gameStatusCancelled = 'cancelled';

  // Friend Status
  static const String friendStatusPending = 'pending';
  static const String friendStatusAccepted = 'accepted';
  static const String friendStatusBlocked = 'blocked';

  // Privacy Settings
  static const String privacyPublic = 'public';
  static const String privacyFriends = 'friends';
  static const String privacyPrivate = 'private';

  // Rate Limits
  static const int maxMessagesPerMinute = 30;
  static const int maxFriendRequestsPerDay = 50;
  static const int maxGamesPerDayFree = 5;
  static const int maxGamesPerDayPremium = 100;
}
