import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../profile/public_profile_screen.dart';
import '../../services/user_service.dart';
import '../../models/leaderboard_model.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final UserService _userService = UserService();
  late Future<List<LeaderboardEntry>> _globalLeaderboardFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _globalLeaderboardFuture = _userService.getGlobalLeaderboard();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Leaderboard',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryTeal,
          unselectedLabelColor: AppColors.textLight,
          indicatorColor: AppColors.primaryTeal,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Global'),
            Tab(text: 'Friends'),
            Tab(text: 'Weekly'),
            Tab(text: 'By Language'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLeaderboardList('global'),
          _buildLeaderboardList('friends'),
          _buildLeaderboardList('weekly'),
          _buildLeaderboardList('language'),
        ],
      ),
    );
  }

  Widget _buildLeaderboardList(String type) {
    Future<List<LeaderboardEntry>> future;
    
    switch (type) {
      case 'global':
        future = _globalLeaderboardFuture;
        break;
      case 'friends':
        future = _userService.getFriendsLeaderboard();
        break;
      case 'weekly':
        future = _userService.getWeeklyLeaderboard();
        break;
      case 'language':
        future = _userService.getLanguageLeaderboard('en'); // Default to 'en' for now
        break;
      default:
        future = _globalLeaderboardFuture;
    }

    return FutureBuilder<List<LeaderboardEntry>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final entries = snapshot.data ?? [];
        if (entries.isEmpty) {
          String emptyMessage = 'No leaderboard data yet.';
          if (type == 'friends') emptyMessage = 'Add friends to see them here!';
          return Center(child: Text(emptyMessage));
        }
        
        final topThree = entries.take(3).toList();
        final remaining = entries.skip(3).toList();

        return Column(
          children: [
            _buildTopThreeReal(topThree),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: remaining.length,
                itemBuilder: (context, index) {
                  return _buildLeaderboardTileReal(remaining[index]);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTopThreeReal(List<LeaderboardEntry> topThree) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (topThree.length > 1)
            _buildPodiumItemReal(topThree[1], Colors.grey.shade300),
          if (topThree.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildPodiumItemReal(topThree[0], const Color(0xFFFFD700)),
            ),
          if (topThree.length > 2)
            _buildPodiumItemReal(topThree[2], const Color(0xFFCD7F32)),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms);
  }

  Widget _buildPodiumItemReal(LeaderboardEntry entry, Color color) {
    final isFirst = entry.rank == 1;
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PublicProfileScreen(
              userId: entry.userId,
            ),
          ),
        );
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: AppColors.goldGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: isFirst ? 40 : 30,
              backgroundColor: Colors.white,
              backgroundImage: entry.avatarUrl != null ? NetworkImage(entry.avatarUrl!) : null,
              child: entry.avatarUrl == null
                  ? Text(
                      entry.username.isNotEmpty ? entry.username[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontSize: isFirst ? 32 : 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryTeal,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 60,
            height: isFirst ? 100 : 70,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [color, color.withValues(alpha: 0.7)],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '#${entry.rank}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${entry.totalXP}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            entry.username,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardTileReal(LeaderboardEntry entry) {
    final isTop10 = entry.rank <= 10;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isTop10 ? Colors.white : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isTop10
            ? const BorderSide(color: AppColors.primaryTeal, width: 1)
            : BorderSide.none,
      ),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PublicProfileScreen(
                userId: entry.userId,
              ),
            ),
          );
        },
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isTop10
                ? AppColors.primaryTeal.withValues(alpha: 0.1)
                : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              '#${entry.rank}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isTop10 ? AppColors.primaryTeal : AppColors.textMedium,
              ),
            ),
          ),
        ),
        title: Text(
          entry.username,
          style: TextStyle(
            fontWeight: isTop10 ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text('Level ${entry.currentLevel}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star, color: Colors.amber, size: 18),
            const SizedBox(width: 4),
            Text(
              '${entry.totalXP}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: ((entry.rank % 10) * 50).ms);
  }

}

