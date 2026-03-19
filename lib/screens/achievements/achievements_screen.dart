import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/achievement_models.dart';
import '../../theme/app_theme.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  AchievementCategory _selectedCategory = AchievementCategory.general;
  bool _showUnlockedOnly = false;
  final int _unlockedCount = 12;
  final int _totalCount = 48;
  
  // Demo achievements data
  late List<Achievement> _achievements;

  @override
  void initState() {
    super.initState();
    _achievements = AchievementDefinitions.defaultAchievements;
    // Add some demo data
    _achievements = [
      ..._achievements,
      Achievement(
        id: 'demo_1',
        title: 'Early Bird',
        description: 'Complete a study session before 8 AM',
        icon: '🌅',
        category: AchievementCategory.general,
        tier: AchievementTier.bronze,
        color: AppColors.accentCoral,
        requirement: 1,
        xpReward: 50,
        isUnlocked: true,
        unlockedAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
      Achievement(
        id: 'demo_2',
        title: 'Night Owl',
        description: 'Study after 10 PM',
        icon: '🦉',
        category: AchievementCategory.general,
        tier: AchievementTier.bronze,
        color: Colors.indigo,
        requirement: 1,
        xpReward: 50,
        isUnlocked: true,
        unlockedAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final filteredAchievements = _getFilteredAchievements();
    
    return Scaffold(
      backgroundColor: AppColors.lightGreyBackground,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: _buildOverallProgress(),
          ),
          SliverToBoxAdapter(
            child: _buildCategoryFilter(),
          ),
          SliverToBoxAdapter(
            child: _buildFilterToggle(),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return _buildAchievementCard(filteredAchievements[index]);
                },
                childCount: filteredAchievements.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Achievement> _getFilteredAchievements() {
    var filtered = _achievements.where((a) {
      if (_selectedCategory != AchievementCategory.general) {
        return a.category == _selectedCategory;
      }
      return true;
    }).toList();

    if (_showUnlockedOnly) {
      filtered = filtered.where((a) => a.isUnlocked).toList();
    }

    // Sort: unlocked first, then by tier
    filtered.sort((a, b) {
      if (a.isUnlocked && !b.isUnlocked) return -1;
      if (!a.isUnlocked && b.isUnlocked) return 1;
      return b.tier.index.compareTo(a.tier.index);
    });

    return filtered;
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 180,
      floating: false,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Achievements',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primaryPurple, AppColors.secondaryPurple],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -30,
                top: -30,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ),
              Positioned(
                left: -20,
                bottom: -20,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.emoji_events, color: AppColors.accentOrange, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            '$_unlockedCount / $_totalCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverallProgress() {
    final percentage = _unlockedCount / _totalCount;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Your Progress',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryPurple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${(percentage * 100).toInt()}%',
                  style: const TextStyle(
                    color: AppColors.primaryPurple,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: AppColors.neutralLight,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryPurple),
              minHeight: 12,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildProgressStat('Unlocked', '$_unlockedCount', AppColors.success),
              _buildProgressStat('Locked', '${_totalCount - _unlockedCount}', AppColors.neutralMid),
              _buildProgressStat('Next Tier', '8 more', AppColors.accentOrange),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.2, end: 0);
  }

  Widget _buildProgressStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.neutralDark,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 100,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: AchievementCategory.values.length,
        itemBuilder: (context, index) {
          final category = AchievementCategory.values[index];
          final isSelected = _selectedCategory == category;
          final count = _achievements
              .where((a) => a.category == category && a.isUnlocked)
              .length;
          
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = category),
            child: Container(
              width: 80,
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? category.color : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: (isSelected ? category.color : AppColors.neutralMid)
                        .withValues(alpha: 0.1),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    category.icon,
                    color: isSelected ? Colors.white : category.color,
                    size: 28,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    category.displayName.split(' ').first,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : AppColors.neutralDark,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isSelected 
                          ? Colors.white.withValues(alpha: 0.1) 
                          : AppColors.neutralMid,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          FilterChip(
            label: const Text('Show All'),
            selected: !_showUnlockedOnly,
            onSelected: (selected) {
              if (selected) setState(() => _showUnlockedOnly = false);
            },
            selectedColor: AppColors.primaryPurple.withValues(alpha: 0.1),
            checkmarkColor: AppColors.primaryPurple,
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Unlocked Only'),
            selected: _showUnlockedOnly,
            onSelected: (selected) {
              setState(() => _showUnlockedOnly = selected);
            },
            selectedColor: AppColors.success.withValues(alpha: 0.1),
            checkmarkColor: AppColors.success,
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementCard(Achievement achievement) {
    final isUnlocked = achievement.isUnlocked;
    
    return GestureDetector(
      onTap: () => _showAchievementDetail(achievement),
      child: Container(
        decoration: BoxDecoration(
          color: isUnlocked ? Colors.white : AppColors.neutralLight,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isUnlocked
              ? [
                  BoxShadow(
                    color: achievement.tier.color.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
          border: Border.all(
            color: isUnlocked 
                ? achievement.tier.color.withValues(alpha: 0.1)
                : AppColors.neutralLight,
            width: isUnlocked ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: isUnlocked
                          ? achievement.tier.color.withValues(alpha: 0.1)
                          : AppColors.neutralLight,
                      shape: BoxShape.circle,
                      border: isUnlocked
                          ? Border.all(
                              color: achievement.tier.color.withValues(alpha: 0.1),
                              width: 2,
                            )
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        achievement.icon,
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Tier badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isUnlocked
                          ? achievement.tier.color.withValues(alpha: 0.1)
                          : AppColors.neutralLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      achievement.tier.displayName,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isUnlocked
                            ? achievement.tier.color
                            : AppColors.neutralMid,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Title
                  Text(
                    achievement.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isUnlocked ? Colors.black87 : AppColors.neutralMid,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Description
                  Text(
                    achievement.displayDescription,
                    style: TextStyle(
                      fontSize: 11,
                      color: isUnlocked 
                          ? AppColors.neutralDark 
                          : AppColors.neutralMid,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  // Progress or XP
                  if (!isUnlocked) ...[
                    LinearProgressIndicator(
                      value: achievement.progressPercentage,
                      backgroundColor: AppColors.neutralLight,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        achievement.tier.color.withValues(alpha: 0.1),
                      ),
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${achievement.currentValue}/${achievement.targetValue}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.neutralMid,
                      ),
                    ),
                  ] else ...[
                    Row(
                      children: [
                        const Icon(Icons.star, size: 14, color: AppColors.accentOrange),
                        const SizedBox(width: 4),
                        Text(
                          '${achievement.xpReward} XP',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.accentOrange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // Lock overlay for locked achievements
            if (!isUnlocked)
              const Positioned(
                top: 12,
                right: 12,
                child: Icon(
                  Icons.lock,
                  color: AppColors.neutralMid,
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    ).animate().fadeIn().scale(
      begin: const Offset(0.9, 0.9),
      end: const Offset(1, 1),
    );
  }

  void _showAchievementDetail(Achievement achievement) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.neutralMid,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Large icon
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: achievement.isUnlocked
                            ? LinearGradient(
                                colors: [
                                  achievement.tier.color,
                                  achievement.tier.color.withValues(alpha: 0.1),
                                ],
                              )
                            : null,
                        color: achievement.isUnlocked 
                            ? null 
                            : AppColors.neutralLight,
                        shape: BoxShape.circle,
                        boxShadow: achievement.isUnlocked
                            ? [
                                BoxShadow(
                                  color: achievement.tier.color.withValues(alpha: 0.1),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          achievement.icon,
                          style: const TextStyle(fontSize: 56),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Tier badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: achievement.tier.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: achievement.tier.color.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Text(
                        achievement.tier.displayName.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: achievement.tier.color,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Title
                    Text(
                      achievement.title,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Description
                    Text(
                      achievement.displayDescription,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.neutralDark,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    // XP reward
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.accentOrange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.accentOrange.withValues(alpha: 0.1)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.star, color: AppColors.accentOrange, size: 32),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Reward',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.neutralMid,
                                ),
                              ),
                              Text(
                                '${achievement.xpReward} XP',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.accentOrange,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Progress or unlocked date
                    if (!achievement.isUnlocked) ...[
                      const Text(
                        'Progress',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: achievement.progressPercentage,
                          backgroundColor: AppColors.neutralLight,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            achievement.tier.color,
                          ),
                          minHeight: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${achievement.currentValue} / ${achievement.targetValue}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.neutralDark,
                        ),
                      ),
                    ] else if (achievement.isUnlocked) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.success.withValues(alpha: 0.1)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle, color: AppColors.success),
                            const SizedBox(width: 8),
                            Text(
                              'Unlocked on ${_formatDate(achievement.unlockedAt!)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Close button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

