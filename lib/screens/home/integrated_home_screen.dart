import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/course_provider.dart';
import '../../providers/podcast_provider.dart';
import '../../providers/gamification_provider.dart';
import '../../providers/learning_path_provider.dart';
import '../../theme/app_theme.dart';
import '../../models/course_model.dart';

// Import all feature screens
import '../audio/podcast_player_screen.dart';
import '../achievements/achievements_screen.dart';
import '../practice_modes_screen.dart';
import '../auth/register_screen.dart';
import '../home/course_selector_sheet.dart';
import '../settings_screen.dart';
import '../story/stories_screen.dart';
import '../learning/grammar/grammar_module_screen.dart';
import '../../widgets/ai_tutor/ai_tutor_floating_button.dart';
import '../../services/sound_service.dart';

class IntegratedHomeScreen extends StatefulWidget {
  const IntegratedHomeScreen({super.key});

  @override
  State<IntegratedHomeScreen> createState() => _IntegratedHomeScreenState();
}

class _IntegratedHomeScreenState extends State<IntegratedHomeScreen> {
  late final ScrollController _scrollController;
  int? _previousXP;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CourseProvider>().loadCourses();
      context.read<PodcastProvider>().loadPodcasts();
      _loadProviderData();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadProviderData() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final courseProvider = context.read<CourseProvider>();
      
      final user = authProvider.currentUser;
      final guestUser = authProvider.guestUser;
      final userId = user?.id ?? guestUser?.id;
      
      final activeCourse = courseProvider.activeCourse;

      if (userId != null) {
        final gProvider = context.read<GamificationProvider>();
        gProvider.loadDailyQuests(userId);
        gProvider.loadAchievements(userId);
        gProvider.loadStreakData(userId);
        
        if (activeCourse != null) {
          context.read<LearningPathProvider>().loadLearningPath(userId, activeCourse.id);
        }
      }
    } catch (e) {
      debugPrint('Error loading provider data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final courseProvider = context.watch<CourseProvider>();
    final podcastProvider = context.watch<PodcastProvider>();
    final gamificationProvider = context.watch<GamificationProvider>();
    final learningPathProvider = context.watch<LearningPathProvider>();

    final dynamic user = authProvider.currentUser ?? authProvider.guestUser;
    final activeCourse = courseProvider.activeCourse;
    final bool isGuest = authProvider.isGuest;

    // Play shimmer sound if XP increases
    final currentXP = activeCourse?.totalXP ?? 0;
    if (_previousXP != null && currentXP > _previousXP!) {
      SoundService().playShimmer();
    }
    _previousXP = currentXP;

    return Scaffold(
      backgroundColor: AppColors.softWhite,
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async {
              await _loadProviderData();
              await Future.delayed(const Duration(seconds: 1));
            },
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: _buildHeader(context, user, isGuest, activeCourse),
                ),
                if (isGuest)
                  SliverToBoxAdapter(child: _buildGuestBanner(context)),
                SliverToBoxAdapter(
                  child: _buildDailyProgress(context, gamificationProvider),
                ),
                SliverToBoxAdapter(
                  child: _buildContinueLearning(context, activeCourse, learningPathProvider),
                ),
                SliverToBoxAdapter(
                  child: _buildActiveCourseSection(context, activeCourse),
                ),
                SliverToBoxAdapter(
                  child: _buildLearningModes(context, podcastProvider),
                ),
                SliverToBoxAdapter(
                  child: _buildPracticeModes(context, isGuest),
                ),
                SliverToBoxAdapter(
                  child: _buildRecommendedSection(context, isGuest),
                ),
                const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: const AITutorFloatingButton(lessonId: 'home'),
    );
  }

  Widget _buildHeader(BuildContext context, dynamic user, bool isGuest, CourseModel? activeCourse) {
    final String username = user?.username ?? 'Guest';
    final int xp = user?.totalXP ?? 0;
    final int level = user?.currentLevel ?? 1;
    final int gems = (user != null && user is! String) ? (user.toJson()['gems'] ?? 0) : 0; 

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
      decoration: const BoxDecoration(
        gradient: AppColors.tealGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Welcome back,',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 16)),
                  Text(username,
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
              Row(
                children: [
                  if (activeCourse != null)
                    _buildFlagIcon(activeCourse.targetLanguageFlag, () => _showCourseSelector(context)),
                  _buildStatBadge(Icons.emoji_events, AppColors.accentOrange, xp.toString(), () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AchievementsScreen()))),
                  _buildStatBadge(Icons.settings, Colors.white, '', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _buildHeaderStat('Level', level.toString(), Icons.trending_up, AppColors.accentCoral)),
              const SizedBox(width: 12),
              Expanded(child: _buildHeaderStat('Gems', gems.toString(), Icons.diamond, AppColors.primaryTeal)),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms);
  }

  Widget _buildFlagIcon(String flag, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
        child: Text(flag, style: const TextStyle(fontSize: 20)),
      ),
    );
  }

  Widget _buildStatBadge(IconData icon, Color color, String value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        margin: const EdgeInsets.only(left: 8),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            if (value.isNotEmpty) ...[const SizedBox(width: 4), Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))],
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderStat(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.2), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGuestBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.accentCoral, AppColors.accentCoral]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(Icons.person_outline, color: Colors.white, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Guest Mode', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                Text('Sign up to save progress!', style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.accentCoral),
            child: const Text('Sign Up'),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.2, end: 0);
  }

  Widget _buildDailyProgress(BuildContext context, GamificationProvider gProvider) {
    final double progress = gProvider.dailyQuests?.completionPercentage ?? 0.0;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Daily Goals', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text('${(progress * 100).toInt()}%', style: const TextStyle(color: AppColors.primaryTeal, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.primaryTeal.withValues(alpha: 0.1),
            valueColor: const AlwaysStoppedAnimation(AppColors.primaryTeal),
            minHeight: 10,
            borderRadius: BorderRadius.circular(5),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.2, end: 0);
  }

  Widget _buildContinueLearning(BuildContext context, CourseModel? activeCourse, LearningPathProvider lpProvider) {
    final nextLesson = lpProvider.recommendedLessons.isNotEmpty ? lpProvider.recommendedLessons.first : null;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.tealGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: AppColors.primaryTeal.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('CONTINUE LEARNING', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Text(nextLesson?.title ?? 'Start your journey', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () { /* Navigate to lesson */ },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.primaryTeal, minimumSize: const Size(double.infinity, 50)),
            child: const Text('RESUME LESSON'),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildActiveCourseSection(BuildContext context, CourseModel? activeCourse) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.neutralMid.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Hero(
                tag: activeCourse != null ? 'course_flag_${activeCourse.id}' : 'course_flag_empty',
                child: Material(
                  color: Colors.transparent,
                  child: Text(activeCourse?.targetLanguageFlag ?? '🌍', style: const TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ACTIVE COURSE', style: TextStyle(fontSize: 10, color: AppColors.neutralMid, fontWeight: FontWeight.bold)),
                    Text(activeCourse?.targetLanguageName ?? 'No course selected', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              IconButton(onPressed: () => _showCourseSelector(context), icon: const Icon(Icons.swap_horiz, color: AppColors.primaryTeal)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLearningModes(BuildContext context, PodcastProvider podcastProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8), child: Text('Learning Modes', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
        SizedBox(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildModeIcon('Grammar', Icons.school, Colors.indigo, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GrammarModuleScreen()))),
              _buildModeIcon('Stories', Icons.menu_book, Colors.teal, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StoriesScreen()))),
              _buildModeIcon('Podcasts', Icons.headphones, AppColors.accentCoral, () => podcastProvider.podcasts.isNotEmpty ? Navigator.push(context, MaterialPageRoute(builder: (_) => PodcastPlayerScreen(podcast: podcastProvider.podcasts.first))) : null),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModeIcon(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  void _goToPractice(String modeName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PracticeModesScreen(initialMode: modeName),
      ),
    );
  }

  Widget _buildPracticeModes(BuildContext context, bool isGuest) {
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

  Widget _buildRecommendedSection(BuildContext context, bool isGuest) {
    return Container(
      margin: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Recommended', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildRecCard(context, 'Spaced Repetition', 'Review 15 due words', Icons.history, AppColors.primaryTeal),
          _buildRecCard(context, 'Grammar Focus', 'Articles & Genders', Icons.title, AppColors.darkAccentPurple),
        ],
      ),
    );
  }

  Widget _buildRecCard(BuildContext context, String title, String subtitle, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold)), Text(subtitle, style: const TextStyle(color: AppColors.neutralMid, fontSize: 12))])),
          const Icon(Icons.chevron_right, color: AppColors.neutralMid),
        ],
      ),
    );
  }

  void _showCourseSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CourseSelectorSheet(),
    ).then((_) {
      // Reload courses after sheet is dismissed to refresh active course on home screen
      if (context.mounted) {
        context.read<CourseProvider>().loadCourses();
      }
    });
  }
}
