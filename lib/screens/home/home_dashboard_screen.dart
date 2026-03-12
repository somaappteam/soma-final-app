import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../providers/course_provider.dart';
import '../../services/csv_data_service.dart';

/// Main Home Dashboard - Central hub combining all app features
class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  int _currentIndex = 0;
  final ScrollController _scrollController = ScrollController();
  
  bool _isLoadingConcepts = true;
  List<String> _concepts = [];
  String? _error;

  // Demo user stats
  final Map<String, dynamic> _userStats = {
    'streak': 12,
    'xp': 2450,
    'level': 8,
    'gems': 150,
    'dailyGoal': 30,
    'dailyProgress': 20,
  };

  @override
  void initState() {
    super.initState();
    _loadConcepts();
  }

  Future<void> _loadConcepts() async {
    try {
      // Must schedule this after the layout phase to access provider
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final courseProvider = context.read<CourseProvider>();
        final activeCourse = courseProvider.activeCourse;
        if (activeCourse != null) {
          final csvService = CsvDataService();
          final concepts = await csvService.getConcepts(
            activeCourse.targetLanguage, 
            activeCourse.nativeLanguage,
          );
          if (mounted) {
            setState(() {
              _concepts = concepts;
              _isLoadingConcepts = false;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _concepts = ['Basics', 'Greeting', 'Numbers', 'Food']; // Demo
              _isLoadingConcepts = false;
            });
          }
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoadingConcepts = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: _buildDailyProgress(),
          ),
          SliverToBoxAdapter(
            child: _buildDailyProgress(),
          ),
          SliverToBoxAdapter(
            child: _buildConceptProgression(),
          ),
          SliverToBoxAdapter(
            child: _buildPracticeModes(),
          ),
          SliverToBoxAdapter(
            child: _buildRecommendedSection(),
          ),
          SliverToBoxAdapter(
            child: _buildLeaderboardPreview(),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: _buildQuickActionButton(),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 140,
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFF667eea),
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Soma',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            ),
          ),
          child: Stack(
            children: [
              // Decorative circles
              Positioned(
                right: -30,
                top: -30,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
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
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              // Stats row
              Positioned(
                bottom: 60,
                left: 16,
                right: 16,
                child: Row(
                  children: [
                    _buildStatChip(
                      icon: Icons.local_fire_department,
                      value: '${_userStats['streak']}',
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 12),
                    _buildStatChip(
                      icon: Icons.star,
                      value: '${_userStats['xp']}',
                      color: Colors.amber,
                    ),
                    const SizedBox(width: 12),
                    _buildStatChip(
                      icon: Icons.diamond,
                      value: '${_userStats['gems']}',
                      color: Colors.blue,
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Consumer<CourseProvider>(
                        builder: (context, courseProvider, child) {
                          final activeCourse = courseProvider.activeCourse;
                          return Row(
                            children: [
                              const Icon(Icons.flag, color: Colors.white, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                activeCourse != null ? activeCourse.targetLanguage.toUpperCase() : 'Spanish',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.keyboard_arrow_down,
                                color: Colors.white.withOpacity(0.7),
                                size: 16,
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.person_outline),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyProgress() {
    final progress = _userStats['dailyProgress'] / _userStats['dailyGoal'];
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
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
                'Daily Goal',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF667eea).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_userStats['dailyProgress']}/${_userStats['dailyGoal']} min',
                  style: const TextStyle(
                    color: Color(0xFF667eea),
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
              value: progress,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF667eea)),
              minHeight: 12,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${(progress * 100).round()}% of daily goal completed',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.2, end: 0);
  }

  Widget _buildConceptProgression() {
    if (_isLoadingConcepts) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_concepts.isEmpty) {
      return const SizedBox.shrink(); // Don't show if no concepts
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Learning Concepts',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('See All'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _concepts.length,
              itemBuilder: (context, index) {
                final concept = _concepts[index];
                
                // Demo progress logic (e.g. earlier concepts have higher progress)
                double progress = 1.0 - (index * 0.15);
                if (progress < 0) progress = 0;
                if (index == 0) progress = 1.0;
                
                final isLocked = progress == 0 && index > _concepts.length / 2;
                final isActive = progress > 0 && progress < 1.0;
                final isCompleted = progress == 1.0;

                return GestureDetector(
                  onTap: () {
                    if (!isLocked) {
                      // Optionally: Navigator.push to PracticeModesScreen with chosen concept
                    }
                  },
                  child: Container(
                    width: 140,
                    margin: const EdgeInsets.only(right: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isLocked ? Colors.grey.shade100 : Colors.white,
                      gradient: isActive
                          ? const LinearGradient(
                              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        if (!isLocked)
                          BoxShadow(
                            color: isActive
                                ? const Color(0xFF667eea).withOpacity(0.3)
                                : Colors.black.withOpacity(0.05),
                            blurRadius: isActive ? 15 : 10,
                            offset: isActive ? const Offset(0, 8) : const Offset(0, 4),
                          ),
                      ],
                      border: isLocked
                          ? Border.all(color: Colors.grey.shade300)
                          : isActive ? null : Border.all(color: Colors.grey.shade100),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isLocked ? Icons.lock : isCompleted ? Icons.check_circle : Icons.school,
                          color: isLocked ? Colors.grey : isActive ? Colors.white : const Color(0xFF667eea),
                          size: 32,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          concept,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isLocked ? Colors.grey : isActive ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        if (!isLocked)
                           ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: isActive ? Colors.white.withOpacity(0.3) : Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation<Color>(isActive ? Colors.white : const Color(0xFF667eea)),
                              minHeight: 6,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildPracticeModes() {
    final modes = [
      {
        'icon': Icons.flash_on,
        'title': 'Speed Review',
        'color': Colors.orange,
        'subtitle': '60 sec sprint',
      },
      {
        'icon': Icons.translate,
        'title': 'Translation',
        'color': Colors.blue,
        'subtitle': 'Challenge mode',
      },
      {
        'icon': Icons.hearing,
        'title': 'Listening',
        'color': Colors.purple,
        'subtitle': 'Dictation',
      },
      {
        'icon': Icons.edit,
        'title': 'Writing',
        'color': Colors.green,
        'subtitle': 'AI feedback',
      },
    ];

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Practice Modes',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('See All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: modes.length,
            itemBuilder: (context, index) {
              final mode = modes[index];
              return _buildModeCard(mode);
            },
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildModeCard(Map<String, dynamic> mode) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (mode['color'] as Color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                mode['icon'] as IconData,
                color: mode['color'] as Color,
                size: 24,
              ),
            ),
            const Spacer(),
            Text(
              mode['title'] as String,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              mode['subtitle'] as String,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendedSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recommended for You',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildRecommendationCard(
            title: 'Grammar: Past Tense',
            subtitle: 'Master the preterite',
            icon: Icons.school,
            color: Colors.purple,
            progress: 0.3,
          ),
          const SizedBox(height: 12),
          _buildRecommendationCard(
            title: 'Story: A Day in Madrid',
            subtitle: 'Reading • 5 min',
            icon: Icons.menu_book,
            color: Colors.teal,
            progress: 0.0,
          ),
          const SizedBox(height: 12),
          _buildRecommendationCard(
            title: 'Podcast: Food Vocabulary',
            subtitle: 'Listening • 12 min',
            icon: Icons.headphones,
            color: Colors.orange,
            progress: 0.0,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildRecommendationCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required double progress,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
                if (progress > 0) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 6,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: Colors.grey.shade400,
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardPreview() {
    final topUsers = [
      {'name': 'Maria', 'xp': 3250, 'avatar': '👩'},
      {'name': 'You', 'xp': 2450, 'avatar': '😊', 'isYou': true},
      {'name': 'Carlos', 'xp': 2100, 'avatar': '👨'},
    ];

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber.shade100, Colors.orange.shade100],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.emoji_events, color: Colors.amber.shade700),
                  const SizedBox(width: 8),
                  const Text(
                    'Weekly Leaderboard',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {},
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...topUsers.asMap().entries.map((entry) {
            final index = entry.key;
            final user = entry.value;
            final isYou = user['isYou'] as bool? ?? false;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isYou ? Colors.white : Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: isYou
                    ? Border.all(color: const Color(0xFF667eea), width: 2)
                    : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: index == 0
                          ? Colors.amber
                          : index == 1
                              ? Colors.grey.shade300
                              : Colors.orange.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    user['avatar'] as String,
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      user['name'] as String,
                      style: TextStyle(
                        fontWeight: isYou ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                  Text(
                    '${user['xp']} XP',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home, 'Home', 0),
              _buildNavItem(Icons.menu_book, 'Learn', 1),
              const SizedBox(width: 48), // Space for FAB
              _buildNavItem(Icons.emoji_events, 'Achieve', 2),
              _buildNavItem(Icons.person, 'Profile', 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;
    
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? const Color(0xFF667eea) : Colors.grey,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? const Color(0xFF667eea) : Colors.grey,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton() {
    return FloatingActionButton(
      onPressed: () {},
      backgroundColor: const Color(0xFF667eea),
      child: const Icon(Icons.add, size: 28),
    );
  }
}
