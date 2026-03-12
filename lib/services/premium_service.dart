import '../models/premium_model.dart';
import '../constants/app_constants.dart';
import 'supabase_service.dart';

class PremiumService {
  final SupabaseService _supabase = SupabaseService();
  final String _table = 'subscriptions';
  final String _purchasesTable = 'purchase_history';

  Future<bool> isPremium() async {
    final userId = _supabase.currentUserId;
    if (userId == null) return false;

    final response = await _supabase.client
        .from('users')
        .select('is_premium')
        .eq('id', userId)
        .single();

    return response['is_premium'] ?? false;
  }

  Future<SubscriptionInfo?> getCurrentSubscription() async {
    final userId = _supabase.currentUserId;
    if (userId == null) return null;

    final response = await _supabase.client
        .from(_table)
        .select()
        .eq('user_id', userId)
        .eq('is_active', true)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response == null) return null;

    return SubscriptionInfo.fromJson(response);
  }

  Future<void> activatePremium({
    required String tier,
    required DateTime expiryDate,
    String? platform,
    String? transactionId,
  }) async {
    final userId = _supabase.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    await _supabase.client.rpc('activate_premium', params: {
      'user_id': userId,
      'sub_tier': tier,
      'expiry': expiryDate.toIso8601String(),
      'sub_platform': platform,
      'trans_id': transactionId,
    });
  }

  Future<void> cancelSubscription() async {
    final userId = _supabase.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    await _supabase.client
        .from(_table)
        .update({
          'will_renew': false,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('user_id', userId)
        .eq('is_active', true);
  }

  Future<void> restorePurchases() async {
    final userId = _supabase.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    await _supabase.client.rpc('restore_premium_purchases', params: {
      'user_id': userId,
    });
  }

  Future<void> recordPurchase({
    required String productId,
    required String platform,
    required String transactionId,
    required double price,
    required String currency,
    required String status,
  }) async {
    final userId = _supabase.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    await _supabase.client.from(_purchasesTable).insert({
      'user_id': userId,
      'product_id': productId,
      'platform': platform,
      'transaction_id': transactionId,
      'price': price,
      'currency': currency,
      'status': status,
    });
  }

  Future<List<Map<String, dynamic>>> getPurchaseHistory() async {
    final userId = _supabase.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _supabase.client
        .from(_purchasesTable)
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List).cast<Map<String, dynamic>>();
  }

  Stream<bool> subscribeToPremiumStatus() {
    final userId = _supabase.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    return _supabase.client
        .from('users')
        .stream(primaryKey: ['id'])
        .map((data) {
          final user = data.firstWhere(
            (u) => u['id'] == userId,
            orElse: () => {'is_premium': false},
          );
          return user['is_premium'] ?? false;
        });
  }

  Future<Map<String, dynamic>> getPremiumBenefits() async {
    final userId = _supabase.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final isPremium = await this.isPremium();

    return {
      'is_premium': isPremium,
      'xp_multiplier': isPremium
          ? AppConstants.xpMultiplierPremium
          : AppConstants.xpMultiplierFree,
      'daily_xp_cap': isPremium
          ? AppConstants.dailyXPCapPremium
          : AppConstants.dailyXPCapFree,
      'max_friends': isPremium
          ? AppConstants.maxFriendsPremium
          : AppConstants.maxFriendsFree,
      'max_games_per_day': isPremium
          ? AppConstants.maxGamesPerDayPremium
          : AppConstants.maxGamesPerDayFree,
      'max_message_history_days': isPremium
          ? AppConstants.maxMessageHistoryDaysPremium
          : AppConstants.maxMessageHistoryDaysFree,
      'features': isPremium
          ? PremiumFeature.allFeatures.map((f) => f.id).toList()
          : [],
    };
  }
}
