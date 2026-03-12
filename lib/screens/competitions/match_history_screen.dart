import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';

/// Premium Match History & Statistics Screen
/// Features: Game history, performance charts, stats breakdown, achievements
class MatchHistoryScreen extends StatefulWidget {
  const MatchHistoryScreen({super.key});

  @override
  State<MatchHistoryScreen> createState() => _MatchHistoryScreenState();
}

class _MatchHistoryScreenState extends State<MatchHistoryScreen>
    with SingleTickerProviderStateMixin {
  final SupabaseService _supabase = SupabaseService();
  
  late TabController _tabController;
  bool _isLoading = true;
  
  // Statistics
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _matchHistory = [];
  List<Map<String, dynamic>> _achievements = [];
  
  // Filter
  String? _selectedGameType;
  String? _selectedTimeRange;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await Future.wait([
        _loadStatistics(),
        _loadMatchHistory(),
        _loadAchievements(),
      ]);
    } catch (e) {
      // Handle error
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadStatistics() async {
    final userId = _supabase.currentUser?.id;
    if (userId == null) return;
    
    // Load stats from database
    final response = await _supabase.client
        .from('live_game_players')
        .select('score, correct_answers, incorrect_answers, rank, game:game_id(status, game_type)')
        .eq('user_id', userId)
        .not('left_at', 'is', null);
    
    final games = List<Map<String, dynamic>>.from(response);
    
    int totalGames = games.length;
    int totalWins = games.where((g) => g['rank'] == 1).length;
    int totalPoints = games.fold(0, (sum, g) => sum + (g['score'] as int? ?? 0));
    int totalCorrect = games.fold(0, (sum, g) => sum + (g['correct_answers'] as int? ?? 0));
    int totalWrong = games.fold(0, (sum, g) => sum + (g['incorrect_answers'] as int? ?? 0));
    
    setState(() {
      _stats = {
        'totalGames': totalGames,
        'totalWins': totalWins,
        'winRate': totalGames > 0 ? (totalWins / totalGames * 100).round() : 0,
        'totalPoints': totalPoints,
        'averagePoints': totalGames > 0 ? (totalPoints / totalGames).round() : 0,
        'totalCorrect': totalCorrect,
        'totalWrong': totalWrong,
        'accuracy': totalCorrect + totalWrong > 0
            ? (totalCorrect / (totalCorrect + totalWrong) * 100).round()
            : 0,
        'bestStreak': 15, // TODO: Load from database
        'currentStreak': 3, // TODO: Load from database
      };
    });
    }

  Future<void> _loadMatchHistory() async {
    final userId = _supabase.currentUser?.id;
    if (userId == null) return;
    
    final response = await _supabase.client
        .from('live_game_players')
        .select('''
          score,
          correct_answers,
          incorrect_answers,
          rank,
          joined_at,
          game:game_id(
            title,
            game_type,
            language_code,
            status,
            ended_at
          )
        ''')
        .eq('user_id', userId)
        .not('left_at', 'is', null)
        .order('joined_at', ascending: false)
        .limit(50);
    
    setState(() {
      _matchHistory = List<Map<String, dynamic>>.from(response);
    });
    }

  Future<void> _loadAchievements() async {
    // TODO: Load from database
    setState(() {
      _achievements = [
        {
          'id': '1',
          'name': 'First Victory',
          'description': 'Win your first online game',
          'icon': Icons.emoji_events,
          'unlocked_at': DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
          'rarity': 'Common',
        },
        {
          'id': '2',
          'name': 'Winning Streak',
          'description': 'Win 5 games in a row',
          'icon': Icons.local_fire_department,
          'unlocked_at': DateTime.now().subtract(const Duration(days: 15)).toIso8601String(),
          'rarity': 'Rare',
        },
        {
          'id': '3',
          'name': 'Speed Demon',
          'description': 'Answer 10 questions in under 2 seconds',
          'icon': Icons.speed,
          'unlocked_at': DateTime.now().subtract(const Duration(days: 7)).toIso8601String(),
          'rarity': 'Epic',
        },
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 200,
              floating: true,
              pinned: true,
              elevation: 0,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              flexibleSpace: FlexibleSpaceBar(
                background: _buildHeader(),
              ),
              bottom: TabBar(
                controller: _tabController,
                labelColor: AppColors.primaryTeal,
                unselectedLabelColor: AppColors.textLight,
                indicatorColor: AppColors.primaryTeal,
                tabs: const [
                  Tab(text: 'Overview'),
                  Tab(text: 'History'),
                  Tab(text: 'Achievements'),
                ],
              ),
            ),
          ];
        },
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(),
                  _buildHistoryTab(),
                  _buildAchievementsTab(),
                ],
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 60, 16, 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryTeal.withValues(alpha: 0.15),
            AppColors.darkTeal.withValues(alpha: 0.05),
          ],
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Match History',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Track your progress and achievements',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildStatsGrid(),
            const SizedBox(height: 24),
            _buildPerformanceChart(),
            const SizedBox(height: 24),
            _buildRecentActivity(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          title: 'Games Played',
          value: '${_stats['totalGames'] ?? 0}',
          icon: Icons.sports_esports,
          color: AppColors.primaryTeal,
        ),
        _buildStatCard(
          title: 'Win Rate',
          value: '${_stats['winRate'] ?? 0}%',
          icon: Icons.emoji_events,
          color: Colors.amber,
        ),
        _buildStatCard(
          title: 'Total Points',
          value: '${_stats['totalPoints'] ?? 0}',
          icon: Icons.star,
          color: Colors.orange,
        ),
        _buildStatCard(
          title: 'Accuracy',
          value: '${_stats['accuracy'] ?? 0}%',
          icon: Icons.check_circle,
          color: Colors.green,
        ),
      ],
    ).animate().fadeIn().slideY();
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Performance Trend',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: _matchHistory.length >= 2
                ? LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: _matchHistory
                              .take(10)
                              .toList()
                              .reversed
                              .toList()
                              .asMap()
                              .entries
                              .map((e) => FlSpot(
                                    e.key.toDouble(),
                                    (e.value['score'] as int? ?? 0).toDouble(),
                                  ))
                              .toList(),
                          isCurved: true,
                          gradient: const LinearGradient(
                            colors: [
                              AppColors.primaryTeal,
                              AppColors.darkTeal,
                            ],
                          ),
                          barWidth: 4,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primaryTeal.withValues(alpha: 0.3),
                                AppColors.darkTeal.withValues(alpha: 0.0),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.show_chart,
                          size: 48,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Play more games to see trends',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildRecentActivity() {
    final recentGames = _matchHistory.take(5).toList();
    
    if (recentGames.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
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
                'Recent Activity',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              TextButton(
                onPressed: () {
                  _tabController.animateTo(1);
                },
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...recentGames.map((game) => _buildActivityItem(game)),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildActivityItem(Map<String, dynamic> game) {
    final isWin = game['rank'] == 1;
    final score = game['score'] ?? 0;
    final gameData = game['game'] as Map<String, dynamic>? ?? {};
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isWin ? Colors.amber.withValues(alpha: 0.1) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: isWin ? Border.all(color: Colors.amber.withValues(alpha: 0.3)) : null,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isWin ? Colors.amber : Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isWin ? Icons.emoji_events : Icons.sports_esports,
              color: isWin ? Colors.white : Colors.grey.shade600,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  gameData['title'] ?? 'Unknown Game',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${gameData['game_type'] ?? 'Game'} • Rank #${game['rank'] ?? '-'}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMedium,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryTeal.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '+$score',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryTeal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_matchHistory.isEmpty) {
      return _buildEmptyState(
        icon: Icons.history,
        title: 'No match history',
        subtitle: 'Play some online games to see your history',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _matchHistory.length,
        itemBuilder: (context, index) {
          return _buildHistoryCard(_matchHistory[index]);
        },
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> game) {
    final isWin = game['rank'] == 1;
    final score = game['score'] ?? 0;
    final correct = game['correct_answers'] ?? 0;
    final wrong = game['incorrect_answers'] ?? 0;
    final accuracy = correct + wrong > 0 ? (correct / (correct + wrong) * 100).round() : 0;
    final gameData = game['game'] as Map<String, dynamic>? ?? {};
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: isWin
              ? LinearGradient(
                  colors: [
                    Colors.amber.withValues(alpha: 0.05),
                    Colors.orange.withValues(alpha: 0.02),
                  ],
                )
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: isWin ? AppColors.goldGradient : null,
                      color: isWin ? null : Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isWin ? Icons.emoji_events : Icons.sports_esports,
                      color: isWin ? Colors.white : Colors.grey.shade600,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          gameData['title'] ?? 'Unknown Game',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${gameData['game_type'] ?? 'Game'} • ${gameData['language_code'] ?? 'Unknown'}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isWin ? Colors.amber : AppColors.primaryTeal,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isWin ? 'WIN' : '#${game['rank'] ?? '-'}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildHistoryStat(
                    icon: Icons.star,
                    value: '$score',
                    label: 'Points',
                    color: Colors.amber,
                  ),
                  _buildHistoryStat(
                    icon: Icons.check_circle,
                    value: '$correct',
                    label: 'Correct',
                    color: Colors.green,
                  ),
                  _buildHistoryStat(
                    icon: Icons.cancel,
                    value: '$wrong',
                    label: 'Wrong',
                    color: Colors.red,
                  ),
                  _buildHistoryStat(
                    icon: Icons.pie_chart,
                    value: '$accuracy%',
                    label: 'Accuracy',
                    color: AppColors.primaryTeal,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: (50 * _matchHistory.indexOf(game)).ms);
  }

  Widget _buildHistoryStat({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textLight,
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementsTab() {
    if (_achievements.isEmpty) {
      return _buildEmptyState(
        icon: Icons.emoji_events,
        title: 'No achievements yet',
        subtitle: 'Keep playing to unlock achievements',
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _achievements.length,
      itemBuilder: (context, index) {
        return _buildAchievementCard(_achievements[index]);
      },
    );
  }

  Widget _buildAchievementCard(Map<String, dynamic> achievement) {
    final rarityColors = {
      'Common': Colors.grey,
      'Rare': Colors.blue,
      'Epic': Colors.purple,
      'Legendary': Colors.amber,
    };
    
    final color = rarityColors[achievement['rarity']] ?? Colors.grey;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.1),
              color.withValues(alpha: 0.02),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withValues(alpha: 0.7)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                achievement['icon'] as IconData? ?? Icons.emoji_events,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              achievement['name'] ?? 'Unknown',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              achievement['description'] ?? '',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textMedium,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                achievement['rarity'] ?? 'Common',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: (50 * _achievements.indexOf(achievement)).ms);
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: AppColors.textLight.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textMedium,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.textLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

