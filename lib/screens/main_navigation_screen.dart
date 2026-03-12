import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../theme/app_theme.dart';
import 'home/integrated_home_screen.dart';
import 'competitions/competitions_screen.dart';
import 'social/social_screen.dart';
import 'leaderboard/leaderboard_screen.dart';
import 'profile/profile_screen.dart';
import 'guest_restriction_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await context.read<NotificationProvider>().loadNotificationCount();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isGuest = authProvider.isGuest;

    // All nav items for everyone
    final navItems = [
      {'icon': Icons.home, 'label': 'Home', 'index': 0},
      {'icon': Icons.emoji_events, 'label': 'Play', 'index': 1},
      {'icon': Icons.people, 'label': 'Social', 'index': 2},
      {'icon': Icons.leaderboard, 'label': 'Rank', 'index': 3},
      {'icon': Icons.person, 'label': 'Profile', 'index': 4},
    ];

    // All screens - guests see restriction screens for some
    final screens = [
      const IntegratedHomeScreen(),
      isGuest
          ? const GuestRestrictionScreen(
              featureName: 'Competitions',
              featureDescription: 'Challenge yourself and compete with other learners in exciting language games and competitions!',
              icon: Icons.emoji_events,
            )
          : const CompetitionsScreen(),
      isGuest
          ? const GuestRestrictionScreen(
              featureName: 'Social',
              featureDescription: 'Connect with other learners, make friends, and practice languages together!',
              icon: Icons.people,
            )
          : const SocialScreen(),
      isGuest
          ? const GuestRestrictionScreen(
              featureName: 'Leaderboard',
              featureDescription: 'See how you rank against other learners and climb to the top!',
              icon: Icons.leaderboard,
            )
          : const LeaderboardScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: navItems.map((item) {
                return _buildNavItem(
                  item['icon'] as IconData,
                  item['label'] as String,
                  item['index'] as int,
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;
    final authProvider = context.read<AuthProvider>();
    final isGuest = authProvider.isGuest;
    
    // For guests, tabs 1, 2, 3 show lock icon when not selected
    final isRestrictedTab = isGuest && (index == 1 || index == 2 || index == 3);

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryTeal.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isRestrictedTab && !isSelected ? Icons.lock : icon,
              color: isSelected
                  ? AppColors.primaryTeal
                  : AppColors.textLight,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? AppColors.primaryTeal
                    : AppColors.textLight,
                fontSize: 11,
                fontWeight: isSelected
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

