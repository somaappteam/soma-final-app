import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../providers/course_provider.dart';
import '../../services/csv_data_service.dart';
import '../practice_modes_screen.dart';
import '../../theme/app_theme.dart';

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
      backgroundColor: AppColors.lightGreyBackground,
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
      backgroundColor: AppColors.primaryPurple,
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
              colors: [AppColors.primaryPurple, AppColors.secondaryPurple],
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
                      color: AppColors.accentCoral,
                    ),
                    const SizedBox(width: 12),
                    _buildStatChip(
                      icon: Icons.star,
                      value: '${_userStats['xp']}',
                      color: AppColors.accentOrange,
                    ),
                    const SizedBox(width: 12),
                    _buildStatChip(
                      icon: Icons.diamond,
                      value: '${_userStats['gems']}',
                      color: AppColors.primaryTeal,
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
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
                                color: Colors.white.withValues(alpha: 0.1),
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
        color: Colors.white.withValues(alpha: 0.1),
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
            color: Colors.black.withValues(alpha: 0.1),
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
                  color: AppColors.primaryPurple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_userStats['dailyProgress']}/${_userStats['dailyGoal']} min',
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
              value: progress,
              backgroundColor: AppColors.neutralLight,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryPurple),
              minHeight: 12,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${(progress * 100).round()}% of daily goal completed',
            style: const TextStyle(
              color: AppColors.neutralDark,
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
                      color: isLocked ? AppColors.neutralLight : Colors.white,
                      gradient: isActive
                          ? const LinearGradient(
                              colors: [AppColors.primaryPurple, AppColors.secondaryPurple],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        if (!isLocked)
                          BoxShadow(
                            color: isActive
                                ? AppColors.primaryPurple.withValues(alpha: 0.1)
                                : Colors.black.withValues(alpha: 0.1),
                            blurRadius: isActive ? 15 : 10,
                            offset: isActive ? const Offset(0, 8) : const Offset(0, 4),
                          ),
                      ],
                      border: isLocked
                          ? Border.all(color: AppColors.neutralMid)
                          : isActive ? null : Border.all(color: AppColors.neutralLight),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isLocked ? Icons.lock : isCompleted ? Icons.check_circle : Icons.school,
                          color: isLocked ? AppColors.neutralMid : isActive ? Colors.white : AppColors.primaryPurple,
                          size: 32,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          concept,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isLocked ? AppColors.neutralMid : isActive ? Colors.white : Colors.black87,
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
                              backgroundColor: isActive ? Colors.white.withValues(alpha: 0.1) : AppColors.neutralLight,
                              valueColor: AlwaysStoppedAnimation<Color>(isActive ? Colors.white : AppColors.primaryPurple),
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

  void _goToPractice(String modeName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PracticeModesScreen(initialMode: modeName),
      ),
    );
  }

  Widget _buildPracticeModes() {
    // ── Vocabulary Focus modes ──────────────────────────────────────
    final vocabModes = [
      {'icon': Icons.arrow_downward,    'title': 'Falling Words',    'color': AppColors.darkAccentPurple,     'subtitle': 'Catch & match'},
      {'icon': Icons.compare_arrows,    'title': 'Word Match',       'color': Colors.teal,       'subtitle': 'Pair translations'},
      {'icon': Icons.quiz,              'title': 'Vocabulary Quiz',  'color': AppColors.brandTeal, 'subtitle': 'Multiple choice'},
      {'icon': Icons.psychology_alt,    'title': 'Weak Areas Quiz',  'color': Colors.deepOrange, 'subtitle': 'Focus on weak spots'},
      {'icon': Icons.image,             'title': 'Picture Quiz',     'color': Colors.pink,       'subtitle': 'Visual matching'},
      {'icon': Icons.style,             'title': 'Flashcards',       'color': AppColors.accentCoral,     'subtitle': 'SRS system'},
      {'icon': Icons.spellcheck,        'title': 'Spelling Bee',     'color': AppColors.accentOrange,      'subtitle': 'Spell what you hear'},
      {'icon': Icons.hub,               'title': 'Word Association', 'color': Colors.cyan,       'subtitle': 'Connect concepts'},
      {'icon': Icons.bolt,              'title': 'Speed Review',     'color': Colors.orangeAccent,'subtitle': 'Quick-fire sprint'},
    ];

    // ── Sentences Focus modes ───────────────────────────────────────
    final sentenceModes = [
      {'icon': Icons.edit_note,         'title': 'Fill in Blank',       'color': Colors.indigo,      'subtitle': 'Complete sentences'},
      {'icon': Icons.hearing,           'title': 'Listening Practice',   'color': Colors.deepPurple,  'subtitle': 'Type what you hear'},
      {'icon': Icons.mic,               'title': 'Pronunciation',        'color': AppColors.primaryTeal,        'subtitle': 'AI speaking feedback'},
      {'icon': Icons.speed,             'title': 'Speed Challenge',      'color': AppColors.error,         'subtitle': 'Race the clock'},
      {'icon': Icons.history_edu,       'title': 'Writing Practice',     'color': Colors.deepOrange, 'subtitle': 'Grammar exercises'},
      {'icon': Icons.record_voice_over, 'title': 'Listening Dictation',  'color': Colors.teal,        'subtitle': 'Transcribe sentences'},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Practice Modes',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Vocabulary Focus ──
          _buildCategoryHeader(
            icon: Icons.library_books,
            label: 'Vocabulary Focus',
            color: AppColors.brandTeal,
          ),
          const SizedBox(height: 10),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            childAspectRatio: 0.9,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            children: vocabModes
                .map((m) => _buildPracticeTile(m))
                .toList(),
          ),

          const SizedBox(height: 20),

          // ── Sentences Focus ──
          _buildCategoryHeader(
            icon: Icons.notes,
            label: 'Sentences Focus',
            color: Colors.indigo,
          ),
          const SizedBox(height: 10),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            childAspectRatio: 0.9,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            children: sentenceModes
                .map((m) => _buildPracticeTile(m))
                .toList(),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildCategoryHeader({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPracticeTile(Map<String, dynamic> mode) {
    final color = mode['color'] as Color;
    final title = mode['title'] as String;
    return GestureDetector(
      onTap: () => _goToPractice(title),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(mode['icon'] as IconData, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              mode['subtitle'] as String,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.neutralMid,
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
            color: AppColors.darkAccentPurple,
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
            color: AppColors.accentCoral,
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
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
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
                  style: const TextStyle(
                    color: AppColors.neutralDark,
                    fontSize: 13,
                  ),
                ),
                if (progress > 0) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: AppColors.neutralLight,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 6,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right,
            color: AppColors.neutralMid,
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
        gradient: const LinearGradient(
          colors: [AppColors.accentOrange, AppColors.accentCoral],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.emoji_events, color: AppColors.accentOrange),
                  SizedBox(width: 8),
                  Text(
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
                color: isYou ? Colors.white : Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: isYou
                    ? Border.all(color: AppColors.primaryPurple, width: 2)
                    : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: index == 0
                          ? AppColors.accentOrange
                          : index == 1
                              ? AppColors.neutralMid
                              : AppColors.accentCoral,
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
            color: Colors.black.withValues(alpha: 0.1),
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
            color: isSelected ? AppColors.primaryPurple : AppColors.neutralMid,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.primaryPurple : AppColors.neutralMid,
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
      backgroundColor: AppColors.primaryPurple,
      child: const Icon(Icons.add, size: 28),
    );
  }
}

