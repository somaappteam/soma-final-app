class PremiumTier {
  final String id;
  final String name;
  final String description;
  final double price;
  final String currency;
  final String period;
  final List<PremiumFeature> features;
  final bool isPopular;
  final double? originalPrice;
  final String? trialPeriod;

  PremiumTier({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.currency = 'USD',
    required this.period,
    required this.features,
    this.isPopular = false,
    this.originalPrice,
    this.trialPeriod,
  });

  static List<PremiumTier> get tiers => [
    PremiumTier(
      id: 'premium_monthly',
      name: 'Premium Monthly',
      description: 'Full access to all premium features',
      price: 9.99,
      period: 'month',
      features: PremiumFeature.allFeatures,
    ),
    PremiumTier(
      id: 'premium_yearly',
      name: 'Premium Yearly',
      description: 'Save 50% with annual billing',
      price: 59.99,
      originalPrice: 119.88,
      period: 'year',
      features: PremiumFeature.allFeatures,
      isPopular: true,
      trialPeriod: '7 days',
    ),
    PremiumTier(
      id: 'premium_lifetime',
      name: 'Premium Lifetime',
      description: 'One-time purchase, forever access',
      price: 199.99,
      period: 'lifetime',
      features: PremiumFeature.allFeatures,
    ),
  ];
}

class PremiumFeature {
  final String id;
  final String name;
  final String description;
  final String icon;
  final bool isNew;

  PremiumFeature({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    this.isNew = false,
  });

  static List<PremiumFeature> get allFeatures => [
    PremiumFeature(
      id: 'unlimited_games',
      name: 'Unlimited Games',
      description: 'Play as many competitions as you want',
      icon: '🎮',
    ),
    PremiumFeature(
      id: 'xp_boost',
      name: '2x XP Boost',
      description: 'Earn double XP on all activities',
      icon: '⚡',
    ),
    PremiumFeature(
      id: 'exclusive_games',
      name: 'Exclusive Games',
      description: 'Access to premium-only competitions',
      icon: '🔒',
    ),
    PremiumFeature(
      id: 'advanced_stats',
      name: 'Advanced Stats',
      description: 'Detailed analytics and insights',
      icon: '📊',
    ),
    PremiumFeature(
      id: 'custom_themes',
      name: 'Custom Themes',
      description: 'Unlock all app themes and colors',
      icon: '🎨',
    ),
    PremiumFeature(
      id: 'badge_premium',
      name: 'Premium Badge',
      description: 'Show off your premium status',
      icon: '👑',
    ),
    PremiumFeature(
      id: 'priority_support',
      name: 'Priority Support',
      description: 'Get help faster with priority queue',
      icon: '🚀',
    ),
    PremiumFeature(
      id: 'unlimited_friends',
      name: 'Unlimited Friends',
      description: 'Add unlimited friends',
      icon: '👥',
    ),
    PremiumFeature(
      id: 'message_history',
      name: 'Full Message History',
      description: 'Access all your messages forever',
      icon: '💬',
    ),
    PremiumFeature(
      id: 'ad_free',
      name: 'Ad-Free Experience',
      description: 'Enjoy the app without interruptions',
      icon: '✨',
      isNew: true,
    ),
  ];
}

class SubscriptionInfo {
  final String tier;
  final DateTime startDate;
  final DateTime expiryDate;
  final bool isActive;
  final bool willRenew;
  final String? platform;
  final String? transactionId;

  SubscriptionInfo({
    required this.tier,
    required this.startDate,
    required this.expiryDate,
    required this.isActive,
    required this.willRenew,
    this.platform,
    this.transactionId,
  });

  factory SubscriptionInfo.fromJson(Map<String, dynamic> json) {
    return SubscriptionInfo(
      tier: json['tier'],
      startDate: DateTime.parse(json['start_date']),
      expiryDate: DateTime.parse(json['expiry_date']),
      isActive: json['is_active'],
      willRenew: json['will_renew'] ?? false,
      platform: json['platform'],
      transactionId: json['transaction_id'],
    );
  }
}
