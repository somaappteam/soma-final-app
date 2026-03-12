import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/course_provider.dart';
import '../../services/csv_data_service.dart';
import '../../theme/app_theme.dart';
import '../../models/vocabulary_item.dart';
import '../../models/study_models.dart';

// Import all feature screens
import '../grammar/grammar_module_screen.dart';
import '../story/story_reader_screen.dart';
import '../audio/podcast_player_screen.dart';
import '../ai/ai_conversation_screen.dart';
import '../achievements/achievements_screen.dart';
import '../comprehensive_settings_screen.dart';
import '../practice_modes_screen.dart';
import '../practice/flashcards_screen.dart';
import '../practice/listening_practice_screen.dart';
import '../games/word_match_game.dart';
import '../practice/speed_challenge_screen.dart';
import '../practice_modes/translation_challenge_screen.dart';
import '../practice_modes/spelling_bee_screen.dart';
import '../practice_modes/writing_practice_screen.dart';
import '../practice_modes/sentence_completion_screen.dart';
import '../practice/vocabulary_quiz_screen.dart';
import '../practice/fill_in_blank_screen.dart';
import '../practice/pronunciation_practice_screen.dart';
import '../games/falling_words_launcher.dart';
import '../auth/register_screen.dart';

class IntegratedHomeScreen extends StatefulWidget {
  const IntegratedHomeScreen({super.key});

  @override
  State<IntegratedHomeScreen> createState() => _IntegratedHomeScreenState();
}

class _IntegratedHomeScreenState extends State<IntegratedHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CourseProvider>().loadCourses();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final courseProvider = context.watch<CourseProvider>();
    final user = authProvider.currentUser;
    final guestUser = authProvider.guestUser;
    final isGuest = authProvider.isGuest;
    final activeCourse = courseProvider.activeCourse;

    final displayUser = isGuest ? guestUser : user;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _buildHeader(context, displayUser, isGuest, activeCourse),
          ),
          if (isGuest)
            SliverToBoxAdapter(
              child: _buildGuestBanner(context),
            ),
          SliverToBoxAdapter(
            child: _buildDailyProgress(context),
          ),
          SliverToBoxAdapter(
            child: _buildContinueLearning(context, activeCourse),
          ),
          SliverToBoxAdapter(
            child: _buildFeatureGrid(context, isGuest),
          ),
          SliverToBoxAdapter(
            child: _buildPracticeModes(context, isGuest),
          ),
          SliverToBoxAdapter(
            child: _buildRecommendedSection(context, isGuest),
          ),
          SliverToBoxAdapter(
            child: _buildAchievementsPreview(context),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, user, bool isGuest, activeCourse) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back,',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.username ?? 'Guest',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => _navigateToAchievements(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.emoji_events,
                            color: Colors.amber,
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${user?.totalXP ?? 0}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.local_fire_department,
                          color: Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${user?.streakDays ?? 0}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  '${user?.currentLevel ?? 1}',
                  'Level',
                  Icons.trending_up,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  '150',
                  'Gems',
                  Icons.diamond,
                  Colors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms);
  }

  Widget _buildStatCard(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDailyProgress(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.accentCoral.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.flag,
                      color: AppColors.accentCoral,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Daily Goal',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.accentCoral.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '15/30 min',
                  style: TextStyle(
                    color: AppColors.accentCoral,
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
              value: 0.5,
              minHeight: 10,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation(AppColors.accentCoral),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '50% of daily goal completed',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.2, end: 0);
  }

  Widget _buildContinueLearning(BuildContext context, activeCourse) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.tealGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryTeal.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.book,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Continue Learning',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Unit 3: Travel & Directions',
                      style: TextStyle(
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
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: 0.6,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '6 of 10 lessons completed',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.play_arrow),
              label: const Text(
                'CONTINUE',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primaryTeal,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildFeatureGrid(BuildContext context, bool isGuest) {
    final features = [
      {
        'icon': Icons.school,
        'title': 'Grammar',
        'subtitle': 'Master rules',
        'color': Colors.purple,
        'screen': 'grammar',
        'available': true,
      },
      {
        'icon': Icons.menu_book,
        'title': 'Stories',
        'subtitle': 'Read & learn',
        'color': Colors.teal,
        'screen': 'stories',
        'available': true,
      },
      {
        'icon': Icons.headphones,
        'title': 'Podcasts',
        'subtitle': 'Listen & learn',
        'color': Colors.orange,
        'screen': 'podcasts',
        'available': true,
      },
      {
        'icon': Icons.chat_bubble,
        'title': 'AI Chat',
        'subtitle': 'Practice talking',
        'color': Colors.blue,
        'screen': 'ai_chat',
        'available': !isGuest,
      },
    ];

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Learning Features',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: features.length,
            itemBuilder: (context, index) {
              final feature = features[index];
              final isAvailable = feature['available'] as bool;
              
              return GestureDetector(
                onTap: isAvailable 
                    ? () => _navigateToFeature(context, feature['screen'] as String)
                    : () => _showGuestRestriction(context),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isAvailable ? Colors.white : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
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
                          color: isAvailable 
                              ? (feature['color'] as Color).withValues(alpha: 0.1)
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isAvailable ? feature['icon'] as IconData : Icons.lock,
                          color: isAvailable ? feature['color'] as Color : Colors.grey,
                          size: 24,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        feature['title'] as String,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isAvailable ? AppColors.textDark : Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isAvailable 
                            ? feature['subtitle'] as String
                            : 'Sign in to unlock',
                        style: TextStyle(
                          color: isAvailable ? Colors.grey.shade600 : Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildPracticeModes(BuildContext context, bool isGuest) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Practice Modes',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              TextButton(
                onPressed: () => _navigateToAllPracticeModes(context),
                child: const Text('See All'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildPracticeCategory(
          context,
          title: 'Vocabulary',
          isGuest: isGuest,
          modes: [
            {'name': 'Word Match', 'icon': Icons.compare_arrows, 'color': Colors.teal, 'available': true, 'modeType': 'word_match'},
            {'name': 'Falling Words', 'icon': Icons.arrow_downward, 'color': Colors.purple, 'available': true, 'modeType': 'falling_words'},
            {'name': 'Quiz', 'icon': Icons.quiz, 'color': AppColors.primaryTeal, 'available': true, 'modeType': 'vocabulary_quiz'},
            {'name': 'Flashcards', 'icon': Icons.style, 'color': Colors.orange, 'available': !isGuest, 'modeType': 'flashcards'},
            {'name': 'Listening', 'icon': Icons.hearing, 'color': AppColors.accentOrange, 'available': !isGuest, 'modeType': 'listening'},
            {'name': 'Pronunciation', 'icon': Icons.mic, 'color': Colors.blue, 'available': !isGuest, 'modeType': 'pronunciation'},
            {'name': 'Speed Challenge', 'icon': Icons.speed, 'color': Colors.red, 'available': !isGuest, 'modeType': 'speed_review'},
            {'name': 'Spelling', 'icon': Icons.spellcheck, 'color': Colors.green, 'available': !isGuest, 'modeType': 'spelling'},
          ],
        ),
        const SizedBox(height: 16),
        _buildPracticeCategory(
          context,
          title: 'Sentences',
          isGuest: isGuest,
          modes: [
            {'name': 'Completion', 'icon': Icons.wrap_text, 'color': Colors.deepOrange, 'available': !isGuest, 'modeType': 'sentence_completion'},
            {'name': 'Fill in Blank', 'icon': Icons.edit_note, 'color': Colors.indigo, 'available': !isGuest, 'modeType': 'fill_in_blank'},
            {'name': 'Translation', 'icon': Icons.translate, 'color': Colors.blue, 'available': !isGuest, 'modeType': 'translation'},
            {'name': 'Writing', 'icon': Icons.edit, 'color': Colors.indigo, 'available': !isGuest, 'modeType': 'writing'},
          ],
        ),
      ],
    );
  }

  Widget _buildPracticeCategory(BuildContext context, {required String title, required bool isGuest, required List<Map<String, dynamic>> modes}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textMedium,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: modes.length,
            itemBuilder: (context, index) {
              final mode = modes[index];
              final isAvailable = mode['available'] as bool;
              final modeType = mode['modeType'] as String;

              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: isAvailable
                      ? () => _launchPracticeMode(context, modeType)
                      : () => _showGuestRestriction(context),
                  child: Container(
                    width: 110,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isAvailable
                            ? [
                                mode['color'] as Color,
                                (mode['color'] as Color).withValues(alpha: 0.8),
                              ]
                            : [Colors.grey, Colors.grey.shade600],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isAvailable
                                ? mode['icon'] as IconData
                                : Icons.lock,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          mode['name'] as String,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendedSection(BuildContext context, bool isGuest) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recommended for You',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 16),
          _buildRecommendationCard(
            context: context,
            title: 'Grammar: Past Tense',
            subtitle: 'Master the preterite in Spanish',
            icon: Icons.school,
            color: Colors.purple,
            progress: 0.3,
            onTap: () => _navigateToFeature(context, 'grammar'),
          ),
          const SizedBox(height: 12),
          _buildRecommendationCard(
            context: context,
            title: 'Story: A Day in Madrid',
            subtitle: 'Reading • 5 min • Beginner',
            icon: Icons.menu_book,
            color: Colors.teal,
            progress: 0.0,
            onTap: () => _navigateToFeature(context, 'stories'),
          ),
          const SizedBox(height: 12),
          _buildRecommendationCard(
            context: context,
            title: 'Podcast: Food Vocabulary',
            subtitle: 'Listening • 12 min',
            icon: Icons.headphones,
            color: Colors.orange,
            progress: 0.0,
            onTap: () => _navigateToFeature(context, 'podcasts'),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildRecommendationCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required double progress,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
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
      ),
    );
  }

  Widget _buildAchievementsPreview(BuildContext context) {
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
                    'Your Achievements',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => _navigateToAchievements(context),
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildAchievementBadge('Perfect Week', Icons.emoji_events, AppColors.goldGradient),
              const SizedBox(width: 12),
              _buildAchievementBadge('Speed Demon', Icons.bolt, const LinearGradient(
                colors: [Colors.purple, Colors.deepPurple],
              )),
              const SizedBox(width: 12),
              _buildAchievementBadge('Word Master', Icons.book, const LinearGradient(
                colors: [Colors.blue, Colors.blueAccent],
              )),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildAchievementBadge(String title, IconData icon, Gradient gradient) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _navigateToAchievements(context),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: (gradient as LinearGradient).colors.first.withValues(alpha: 0.4),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 28),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuestBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF8A65), Color(0xFFFF6E40)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Playing as Guest',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Create an account to unlock all features!',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RegisterScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFFFF6E40),
              ),
              child: const Text('Create Account'),
            ),
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  // Navigation Methods
  void _navigateToFeature(BuildContext context, String feature) {
    switch (feature) {
      case 'grammar':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const GrammarModuleScreen()),
        );
        break;
      case 'stories':
        _navigateToStories(context);
        break;
      case 'podcasts':
        _navigateToPodcasts(context);
        break;
      case 'ai_chat':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AIConversationScreen()),
        );
        break;
      case 'settings':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ComprehensiveSettingsScreen()),
        );
        break;
    }
  }

  void _navigateToStories(BuildContext context) {
    // Create a demo story with all required properties
    const demoStory = Story(
      id: 'demo-story-1',
      title: 'A Day in Madrid',
      content: 'María se despierta temprano en la mañana. Ella vive en Madrid, una ciudad hermosa y llena de vida. Después de desayunar, María toma el metro para ir al trabajo. El metro de Madrid es uno de los mejores de Europa.',
      language: 'es',
      difficulty: 'beginner',
      author: 'LinguaQuest Team',
      estimatedReadTime: 5,
      wordCount: 45,
      tags: ['travel', 'daily life', 'beginner'],
      annotations: [],
    );
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const StoryReaderScreen(story: demoStory),
      ),
    );
  }

  void _navigateToPodcasts(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PodcastPlayerScreen(),
      ),
    );
  }

  void _navigateToAchievements(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AchievementsScreen()),
    );
  }

  void _navigateToAllPracticeModes(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PracticeModesScreen()),
    );
  }

  Future<void> _launchPracticeMode(BuildContext context, String modeType) async {
    if (modeType == 'all') {
      _navigateToAllPracticeModes(context);
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final courseProvider = context.read<CourseProvider>();
      final activeCourse = courseProvider.activeCourse;
      final csvService = CsvDataService();
      
      final targetLanguage = activeCourse?.targetLanguage ?? 'es';
      final nativeLanguage = activeCourse?.nativeLanguage ?? 'en';
      
      if (['sentence_completion', 'fill_in_blank', 'translation', 'writing'].contains(modeType)) {
        List<Map<String, dynamic>> sentences = [];
        if (activeCourse != null) {
          sentences = await csvService.getSentences(
            activeCourse.targetLanguage,
            activeCourse.nativeLanguage,
          );
        }
        
        if (!context.mounted) return;
        Navigator.pop(context);
        
        if (sentences.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No sentences available to play'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }

        if (sentences.length < 4) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Need at least 4 sentences to play'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
        
        switch (modeType) {
          case 'sentence_completion':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SentenceCompletionScreen(
                  sentences: sentences,
                  targetLanguage: targetLanguage,
                  nativeLanguage: nativeLanguage,
                ),
              ),
            );
            break;
          case 'fill_in_blank':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FillInBlankScreen(
                  sentences: sentences,
                  targetLanguage: targetLanguage,
                  nativeLanguage: nativeLanguage,
                ),
              ),
            );
            break;
          case 'translation':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TranslationChallengeScreen(
                  sentences: sentences,
                  targetLanguage: targetLanguage,
                  nativeLanguage: nativeLanguage,
                ),
              ),
            );
            break;
          case 'writing':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => WritingPracticeScreen(
                  sentences: sentences,
                  targetLanguage: targetLanguage,
                  nativeLanguage: nativeLanguage,
                ),
              ),
            );
            break;
        }
        return;
      }
      
      List<VocabularyItem> vocabulary = [];
      if (activeCourse != null) {
        vocabulary = await csvService.getVocabulary(
          activeCourse.targetLanguage,
          activeCourse.nativeLanguage,
        );
      }
      
      if (!context.mounted) return;
      if (vocabulary.isEmpty) {
        vocabulary = _getDemoVocabulary();
      }

      Navigator.pop(context);

      if (vocabulary.length < 4) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Need at least 4 vocabulary words to play'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      switch (modeType) {
        case 'flashcards':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FlashcardsScreen(
                vocabulary: vocabulary,
                targetLanguage: targetLanguage,
                nativeLanguage: nativeLanguage,
              ),
            ),
          );
          break;
        case 'speed_review':
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => SpeedChallengeScreen(
                vocabulary: vocabulary,
                targetLanguage: targetLanguage,
                nativeLanguage: nativeLanguage,
              )),
          );
          break;
        case 'spelling':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SpellingBeeScreen(
                vocabulary: vocabulary,
                targetLanguage: targetLanguage,
                nativeLanguage: nativeLanguage,
              ),
            ),
          );
          break;
        case 'listening':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ListeningPracticeScreen(
                vocabulary: vocabulary,
                targetLanguage: targetLanguage,
                nativeLanguage: nativeLanguage,
              ),
            ),
          );
          break;

        case 'word_match':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => WordMatchLauncher(
                vocabulary: vocabulary,
                targetLanguage: targetLanguage,
                nativeLanguage: nativeLanguage,
              ),
            ),
          );
          break;
        case 'falling_words':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FallingWordsLauncher(
                vocabulary: vocabulary,
                targetLanguage: targetLanguage,
                nativeLanguage: nativeLanguage,
              ),
            ),
          );
          break;
        case 'vocabulary_quiz':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VocabularyQuizScreen(
                vocabulary: vocabulary,
                targetLanguage: targetLanguage,
                nativeLanguage: nativeLanguage,
              ),
            ),
          );
          break;

        case 'pronunciation':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PronunciationPracticeScreen(
                vocabulary: vocabulary,
                targetLanguage: targetLanguage,
                nativeLanguage: nativeLanguage,
              ),
            ),
          );
          break;
        default:
          _navigateToAllPracticeModes(context);
      }
    } catch (e) {
      if (Navigator.canPop(context)) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading practice mode: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<VocabularyItem> _getDemoVocabulary() {
    return [
      VocabularyItem(
        id: '1',
        courseId: 'demo',
        word: 'Hello',
        translation: 'Hola',
        difficultyLevel: 1,
        createdAt: DateTime.now(),
      ),
      VocabularyItem(
        id: '2',
        courseId: 'demo',
        word: 'Goodbye',
        translation: 'Adiós',
        difficultyLevel: 1,
        createdAt: DateTime.now(),
      ),
      VocabularyItem(
        id: '3',
        courseId: 'demo',
        word: 'Thank you',
        translation: 'Gracias',
        difficultyLevel: 1,
        createdAt: DateTime.now(),
      ),
      VocabularyItem(
        id: '4',
        courseId: 'demo',
        word: 'Please',
        translation: 'Por favor',
        difficultyLevel: 1,
        createdAt: DateTime.now(),
      ),
      VocabularyItem(
        id: '5',
        courseId: 'demo',
        word: 'Water',
        translation: 'Agua',
        difficultyLevel: 1,
        createdAt: DateTime.now(),
      ),
      VocabularyItem(
        id: '6',
        courseId: 'demo',
        word: 'Food',
        translation: 'Comida',
        difficultyLevel: 1,
        createdAt: DateTime.now(),
      ),
      VocabularyItem(
        id: '7',
        courseId: 'demo',
        word: 'Friend',
        translation: 'Amigo',
        difficultyLevel: 1,
        createdAt: DateTime.now(),
      ),
      VocabularyItem(
        id: '8',
        courseId: 'demo',
        word: 'House',
        translation: 'Casa',
        difficultyLevel: 1,
        createdAt: DateTime.now(),
      ),
    ];
  }

  void _showGuestRestriction(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign In Required'),
        content: const Text(
          'This feature is only available for registered users. '
          'Create a free account to unlock all features!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Maybe Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const RegisterScreen(),
                ),
              );
            },
            child: const Text('Create Account'),
          ),
        ],
      ),
    );
  }
}
