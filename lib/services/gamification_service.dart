import 'package:logger/logger.dart';
import '../models/daily_quest.dart';
import 'supabase_service.dart';

class GamificationService {
  static final GamificationService _instance = GamificationService._internal();
  factory GamificationService() => _instance;
  GamificationService._internal();

  final Logger _logger = Logger();
  final SupabaseService _supabase = SupabaseService();

  // ==================== DAILY QUESTS ====================

  // Get or generate today's quests for a user
  Future<DailyQuestsData?> getDailyQuests(String userId) async {
    try {
      final today = DateTime.now();
      final todayString = today.toIso8601String().split('T')[0];

      // Check if quests already exist for today
      var response = await _supabase.client
          .from('daily_quests')
          .select()
          .eq('user_id', userId)
          .eq('quest_date', todayString)
          .maybeSingle();

      if (response != null) {
        return DailyQuestsData.fromJson(response);
      }
    
      // Generate new quests for today
      await _supabase.client.rpc('generate_daily_quests', params: {
        'p_user_id': userId,
      });

      // Fetch the newly generated quests
      response = await _supabase.client
          .from('daily_quests')
          .select()
          .eq('user_id', userId)
          .eq('quest_date', todayString)
          .single();

      return DailyQuestsData.fromJson(response);
    } catch (e) {
      _logger.e('Failed to get daily quests', error: e);
      return null;
    }
  }

  // Update quest progress
  Future<void> updateQuestProgress(
    String userId,
    String questType,
    int amount, {
    String? specificQuestId,
  }) async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];

      // Get today's quests
      final response = await _supabase.client
          .from('daily_quests')
          .select()
          .eq('user_id', userId)
          .eq('quest_date', today)
          .single();

      final questsData = DailyQuestsData.fromJson(response);
      bool hasUpdates = false;

      // Update matching quests
      for (var quest in questsData.quests) {
        if (quest.type == questType && !quest.completed) {
          if (specificQuestId == null || quest.id == specificQuestId) {
            quest.updateProgress(amount);
            hasUpdates = true;

            // Move to completed if done
            if (quest.completed) {
              questsData.completedQuests.add(quest);
            }
          }
        }
      }

      if (hasUpdates) {
        await _supabase.client
            .from('daily_quests')
            .update({
              'quests': questsData.quests.map((q) => q.toJson()).toList(),
              'completed_quests': questsData.completedQuests.map((q) => q.toJson()).toList(),
            })
            .eq('user_id', userId)
            .eq('quest_date', today);
      }
    } catch (e) {
      _logger.e('Failed to update quest progress', error: e);
    }
  }

  // Claim quest rewards
  Future<Map<String, int>?> claimQuestRewards(String userId) async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];

      final response = await _supabase.client
          .from('daily_quests')
          .select()
          .eq('user_id', userId)
          .eq('quest_date', today)
          .single();

      final questsData = DailyQuestsData.fromJson(response);

      if (!questsData.allQuestsCompleted || questsData.claimedRewards) {
        return null;
      }

      // Calculate rewards
      int totalXP = 0;
      int totalGems = 0;

      for (var quest in questsData.completedQuests) {
        totalXP += quest.rewardXP;
        totalGems += quest.rewardGems;
      }

      // Update database
      await _supabase.client
          .from('daily_quests')
          .update({
            'claimed_rewards': true,
            'total_xp_earned': totalXP,
            'total_gems_earned': totalGems,
          })
          .eq('user_id', userId)
          .eq('quest_date', today);

      // Add XP to user
      await _supabase.client.rpc('increment_user_xp', params: {
        'user_id': userId,
        'xp_amount': totalXP,
      });

      return {'xp': totalXP, 'gems': totalGems};
    } catch (e) {
      _logger.e('Failed to claim quest rewards', error: e);
      return null;
    }
  }

  // ==================== ACHIEVEMENTS ====================

  // Get all achievements for a user
  Future<List<Achievement>> getUserAchievements(String userId) async {
    try {
      final response = await _supabase.client
          .from('achievements')
          .select('*, achievement_definitions(*)')
          .eq('user_id', userId)
          .order('unlocked_at', ascending: false);

      return (response as List)
          .map((json) => Achievement.fromJson(json))
          .toList();
    } catch (e) {
      _logger.e('Failed to get user achievements', error: e);
      return [];
    }
  }

  // Get achievement definitions
  Future<List<AchievementDefinition>> getAchievementDefinitions() async {
    try {
      final response = await _supabase.client
          .from('achievement_definitions')
          .select()
          .eq('is_active', true);

      return (response as List)
          .map((json) => AchievementDefinition.fromJson(json))
          .toList();
    } catch (e) {
      _logger.e('Failed to get achievement definitions', error: e);
      return [];
    }
  }

  // Check and unlock achievements
  Future<List<Achievement>> checkAndUnlockAchievements(String userId) async {
    try {
      final unlockedAchievements = <Achievement>[];

      // Get user's stats
      final userStats = await _supabase.client
          .from('profiles')
          .select('total_xp, streak_days, total_games_won, total_friends')
          .eq('id', userId)
          .single();

      // Get already unlocked achievements
      final existingResponse = await _supabase.client
          .from('achievements')
          .select('achievement_id')
          .eq('user_id', userId);

      final existingIds = (existingResponse as List).map((a) => a['achievement_id'] as String).toSet();

      // Get definitions
      final definitions = await getAchievementDefinitions();

      for (var definition in definitions) {
        if (existingIds.contains(definition.id)) continue;

        // Check if user meets requirements
        String? tier;
        
        switch (definition.id) {
          case 'vocab_100':
            // Need to check vocabulary count
            final vocabCount = await _getVocabularyCount(userId);
            tier = _checkTier(definition.tiers, vocabCount);
            break;
            
          case 'lessons_10':
            final lessonCount = await _getCompletedLessonsCount(userId);
            tier = _checkTier(definition.tiers, lessonCount);
            break;
            
          case 'first_win':
          case 'wins_10':
            final wins = userStats['total_games_won'] ?? 0;
            tier = _checkTier(definition.tiers, wins);
            break;
            
          case 'friends_10':
            final friends = userStats['total_friends'] ?? 0;
            tier = _checkTier(definition.tiers, friends);
            break;
            
          case 'streak_7':
          case 'streak_30':
            final streak = userStats['streak_days'] ?? 0;
            tier = _checkTier(definition.tiers, streak);
            break;
            
          case 'xp_1000':
            final xp = userStats['total_xp'] ?? 0;
            tier = _checkTier(definition.tiers, xp);
            break;
        }

        if (tier != null) {
          // Unlock achievement
          final achievement = await _unlockAchievement(userId, definition.id, tier);
          if (achievement != null) {
            unlockedAchievements.add(achievement);
          }
        }
      }

      return unlockedAchievements;
    } catch (e) {
      _logger.e('Failed to check achievements', error: e);
      return [];
    }
  }

  String? _checkTier(List<AchievementTier> tiers, int value) {
    // Check from highest tier to lowest
    for (var tier in tiers.reversed) {
      if (value >= tier.requirement) {
        return tier.tier;
      }
    }
    return null;
  }

  Future<int> _getVocabularyCount(String userId) async {
    try {
      final response = await _supabase.client
          .from('user_vocabulary')
          .select('id')
          .eq('user_id', userId)
          .eq('is_learned', true);

      return response.length ?? 0;
    } catch (e) {
      return 0;
    }
  }

  Future<int> _getCompletedLessonsCount(String userId) async {
    try {
      final response = await _supabase.client
          .from('user_lessons')
          .select('id')
          .eq('user_id', userId)
          .eq('is_completed', true);

      return response.length ?? 0;
    } catch (e) {
      return 0;
    }
  }

  Future<Achievement?> _unlockAchievement(String userId, String achievementId, String tier) async {
    try {
      final response = await _supabase.client
          .from('achievements')
          .insert({
            'user_id': userId,
            'achievement_id': achievementId,
            'tier': tier,
            'unlocked_at': DateTime.now().toIso8601String(),
            'is_new': true,
          })
          .select()
          .single();

      return Achievement.fromJson(response);
          return null;
    } catch (e) {
      _logger.e('Failed to unlock achievement', error: e);
      return null;
    }
  }

  // Mark achievement as viewed
  Future<void> markAchievementAsViewed(String achievementId) async {
    try {
      await _supabase.client
          .from('achievements')
          .update({
            'is_new': false,
            'viewed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', achievementId);
    } catch (e) {
      _logger.e('Failed to mark achievement as viewed', error: e);
    }
  }

  // ==================== STREAKS ====================

  // Get user's streak data
  Future<StreakData?> getStreakData(String userId) async {
    try {
      final response = await _supabase.client
          .from('user_streaks')
          .select()
          .eq('user_id', userId)
          .single();

      return StreakData.fromJson(response);
    
      // Create new streak record if doesn't exist
      final newStreak = StreakData(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
      );

      await _supabase.client.from('user_streaks').insert(newStreak.toJson());
      return newStreak;
    } catch (e) {
      _logger.e('Failed to get streak data', error: e);
      return null;
    }
  }

  // Update streak (called when user completes an activity)
  Future<void> updateStreak(String userId) async {
    try {
      await _supabase.client.rpc('update_user_streak', params: {
        'p_user_id': userId,
      });
    } catch (e) {
      _logger.e('Failed to update streak', error: e);
    }
  }

  // Use streak freeze
  Future<bool> useStreakFreeze(String userId) async {
    try {
      final streakData = await getStreakData(userId);
      if (streakData == null) return false;

      final today = DateTime.now();
      
      if (streakData.streakFreezeCount <= 0) return false;
      if (!streakData.canUseStreakFreeze(today)) return false;

      await _supabase.client
          .from('user_streaks')
          .update({
            'streak_freeze_count': streakData.streakFreezeCount - 1,
            'freeze_used_dates': [
              ...streakData.freezeUsedDates.map((d) => d.toIso8601String()),
              today.toIso8601String(),
            ],
          })
          .eq('user_id', userId);

      return true;
    } catch (e) {
      _logger.e('Failed to use streak freeze', error: e);
      return false;
    }
  }

  // Purchase streak freezes (with gems)
  Future<bool> purchaseStreakFreeze(String userId, int count, int gemCost) async {
    try {
      // Check if user has enough gems
      final userResponse = await _supabase.client
          .from('profiles')
          .select('gems')
          .eq('id', userId)
          .single();

      final currentGems = userResponse['gems'] ?? 0;
      if (currentGems < gemCost) return false;

      // Deduct gems
      await _supabase.client
          .from('profiles')
          .update({'gems': currentGems - gemCost})
          .eq('id', userId);

      // Add streak freezes
      final streakData = await getStreakData(userId);
      if (streakData == null) return false;

      await _supabase.client
          .from('user_streaks')
          .update({
            'streak_freeze_count': streakData.streakFreezeCount + count,
          })
          .eq('user_id', userId);

      return true;
    } catch (e) {
      _logger.e('Failed to purchase streak freeze', error: e);
      return false;
    }
  }

  // Create streak recovery challenge
  Future<StreakRecoveryChallenge?> createRecoveryChallenge(String userId) async {
    try {
      final challengeTypes = [
        {
          'type': 'perfect_lesson',
          'description': 'Complete a lesson with 100% accuracy',
        },
        {
          'type': 'xp_marathon',
          'description': 'Earn 50 XP today',
          'requirements': {'xp_amount': 50},
        },
        {
          'type': 'vocabulary_sprint',
          'description': 'Review 10 vocabulary words',
          'requirements': {'vocab_count': 10},
        },
      ];

      // Select random challenge
      final challenge = challengeTypes[DateTime.now().millisecondsSinceEpoch % challengeTypes.length];

      final response = await _supabase.client
          .from('streak_recovery_challenges')
          .insert({
            'user_id': userId,
            'challenge_type': challenge['type'],
            'requirements': challenge['requirements'] ?? {},
            'expires_at': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
          })
          .select()
          .single();

      return StreakRecoveryChallenge.fromJson(response);
          return null;
    } catch (e) {
      _logger.e('Failed to create recovery challenge', error: e);
      return null;
    }
  }

  // Complete recovery challenge
  Future<bool> completeRecoveryChallenge(String challengeId) async {
    try {
      final response = await _supabase.client
          .from('streak_recovery_challenges')
          .update({
            'is_completed': true,
            'completed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', challengeId)
          .select()
          .single();

      if (response['is_completed'] == true) {
        // Restore streak
        await _supabase.client
            .from('streak_recovery_challenges')
            .update({'streak_restored': true})
            .eq('id', challengeId);

        return true;
      }
      return false;
    } catch (e) {
      _logger.e('Failed to complete recovery challenge', error: e);
      return false;
    }
  }

  // Toggle weekend protection
  Future<void> toggleWeekendProtection(String userId, bool enabled) async {
    try {
      await _supabase.client
          .from('user_streaks')
          .update({
            'is_weekend_protection_enabled': enabled,
          })
          .eq('user_id', userId);
    } catch (e) {
      _logger.e('Failed to toggle weekend protection', error: e);
    }
  }

  // ==================== XP AND LEVELS ====================

  // Calculate level from XP
  int calculateLevel(int totalXP) {
    // Exponential level curve
    // Level 1: 0 XP
    // Level 2: 100 XP
    // Level 3: 250 XP
    // Level 4: 450 XP
    // etc.
    
    if (totalXP < 100) return 1;
    
    int level = 1;
    int xpForNextLevel = 100;
    
    while (totalXP >= xpForNextLevel) {
      level++;
      xpForNextLevel += (100 + (level - 1) * 50); // Increase XP needed per level
    }
    
    return level;
  }

  // Get XP needed for next level
  int getXPForNextLevel(int currentLevel) {
    int xp = 0;
    for (int i = 1; i <= currentLevel; i++) {
      xp += (100 + (i - 1) * 50);
    }
    return xp;
  }

  // Get XP progress in current level
  Map<String, int> getLevelProgress(int totalXP) {
    final currentLevel = calculateLevel(totalXP);
    final xpForCurrentLevel = currentLevel > 1 ? getXPForNextLevel(currentLevel - 1) : 0;
    final xpForNextLevel = getXPForNextLevel(currentLevel);
    final xpInCurrentLevel = totalXP - xpForCurrentLevel;
    final xpNeeded = xpForNextLevel - xpForCurrentLevel;
    
    return {
      'current_level': currentLevel,
      'xp_in_level': xpInCurrentLevel,
      'xp_needed': xpNeeded,
      'total_xp': totalXP,
    };
  }
}
