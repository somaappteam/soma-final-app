import 'package:flutter/material.dart';
import '../screens/auth/register_screen.dart';
import '../theme/app_theme.dart';

/// Guest Mode Restrictions
/// Defines what features are available to guest users vs authenticated users
class GuestRestrictions {
  // Features available to guests
  static const List<String> guestFeatures = [
    'basic_lessons',
    'vocabulary_quiz',
    'falling_words_game',
    'view_courses',
    'practice_basic',
  ];

  // Features requiring authentication
  static const List<String> authOnlyFeatures = [
    'multiplayer_games',
    'leaderboards',
    'achievements',
    'friends',
    'chat',
    'pronunciation',
    'listening',
    'sentences',
    'speed_challenge',
    'ai_tutor',
    'progress_sync',
    'streak_tracking',
    'competitions',
    'premium_features',
  ];

  /// Check if a feature is available to guests
  static bool isFeatureAvailable(String feature) {
    return guestFeatures.contains(feature);
  }

  /// Show guest restriction dialog
  static void showRestrictionDialog(BuildContext context, {String? featureName}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lock, color: AppColors.accentCoral),
            SizedBox(width: 8),
            Expanded(
              child: Text('Sign In Required'),
            ),
          ],
        ),
        content: Text(
          featureName != null
              ? 'The "$featureName" feature is only available for registered users. Create a free account to unlock all features and save your progress!'
              : 'This feature is only available for registered users. Create a free account to unlock all features and save your progress!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Maybe Later'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const RegisterScreen(),
                ),
              );
            },
            icon: const Icon(Icons.person_add),
            label: const Text('Create Account'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentCoral,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Show guest mode banner
  static Widget buildGuestBanner(BuildContext context, {VoidCallback? onAction}) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accentCoral,
            Colors.deepOrange.shade400,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentCoral.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Playing as Guest',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Your progress is only saved on this device. Create an account to:\n'
            '• Save progress across devices\n'
            '• Access all practice modes\n'
            '• Compete on leaderboards\n'
            '• Connect with friends',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.95),
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onAction ?? () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.deepOrange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Create Free Account',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

