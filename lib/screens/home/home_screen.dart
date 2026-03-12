import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../models/course_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/course_provider.dart';
import '../../services/csv_data_service.dart';
import '../../theme/app_theme.dart';
import '../auth/register_screen.dart';
import 'add_course_screen.dart';
import 'course_selector_sheet.dart';
import '../practice_modes_screen.dart';
import '../games/falling_words_launcher.dart';
import '../games/word_match_game.dart';
import '../practice/vocabulary_quiz_screen.dart';
import '../practice/flashcards_screen.dart';
import '../practice/fill_in_blank_screen.dart';
import '../practice/listening_practice_screen.dart';
import '../practice/speed_challenge_screen.dart';
import '../practice/pronunciation_practice_screen.dart';
import '../../models/vocabulary_item.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Load courses when screen initializes
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
            child: _buildCourseSection(context, activeCourse, courseProvider),
          ),
          SliverToBoxAdapter(
            child: _buildDailyQuest(context),
          ),
          SliverToBoxAdapter(
            child: _buildPracticeModes(context),
          ),
          SliverToBoxAdapter(
            child: _buildRecentActivity(context),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          const SizedBox(height: 24),
          if (activeCourse != null) ...[
            Container(
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
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        activeCourse.targetLanguageFlag,
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activeCourse.targetLanguageName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: activeCourse.progress / 100,
                            backgroundColor: Colors.white.withValues(alpha: 0.2),
                            valueColor: const AlwaysStoppedAnimation(Colors.white),
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${activeCourse.progress.toInt()}% Complete',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  '${user?.totalXP ?? 0}',
                  'Total XP',
                  Icons.star,
                  Colors.amber,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  '${user?.currentLevel ?? 1}',
                  'Level',
                  Icons.trending_up,
                  Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms);
  }

  Widget _buildCourseSection(BuildContext context, CourseModel? activeCourse, CourseProvider courseProvider) {
    final courses = courseProvider.courses;
    
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: AppColors.tealGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.school,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Current Course',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
              if (courses.isNotEmpty)
                TextButton.icon(
                  onPressed: () => _showCourseSelector(context),
                  icon: const Icon(Icons.menu_book, size: 18),
                  label: Text(
                    '${courses.length} ${courses.length == 1 ? 'Course' : 'Courses'}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Active Course Display
          if (activeCourse != null) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.tealGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryTeal.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Course Info Row
                  Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            activeCourse.targetLanguageFlag,
                            style: const TextStyle(fontSize: 36),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'ACTIVE',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryTeal,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              activeCourse.targetLanguageName,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  activeCourse.nativeLanguageFlag,
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'from ${activeCourse.nativeLanguageName}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Progress Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progress',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      Text(
                        '${activeCourse.progress.toInt()}% Complete',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: activeCourse.progress / 100,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      minHeight: 10,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Stats Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildActiveCourseStat(
                          icon: Icons.star,
                          value: '${activeCourse.totalXP}',
                          label: 'XP Earned',
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                      Expanded(
                        child: _buildActiveCourseStat(
                          icon: Icons.trending_up,
                          value: 'Level ${activeCourse.currentLevel}',
                          label: 'Current Level',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Manage Courses Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showCourseSelector(context),
                icon: const Icon(Icons.menu_book),
                label: const Text('Manage My Courses'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryTeal,
                  side: const BorderSide(color: AppColors.primaryTeal),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ] else ...[
            // Empty State
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.school_outlined,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Start Your Language Journey',
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Add your first course to begin learning',
                    style: TextStyle(
                      color: AppColors.textMedium,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _navigateToAddCourse(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Add First Course'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryTeal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildActiveCourseStat({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.white.withValues(alpha: 0.8),
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  void _navigateToAddCourse(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddCourseScreen(),
      ),
    );
  }

  void _showCourseSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CourseSelectorSheet(),
    );
  }

  void _navigateToPracticeModes(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PracticeModesScreen(),
      ),
    );
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

  Widget _buildGuestBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF8A65), Color(0xFFFF6E40)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
                      'Create an account to save your progress and access all features!',
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Create Account',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.2, end: 0);
  }

  Widget _buildDailyQuest(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
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
                      padding: const EdgeInsets.all(8),
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
                      'Daily Quest',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accentCoral.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '65%',
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
                value: 0.65,
                minHeight: 10,
                backgroundColor: Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation(AppColors.accentCoral),
              ),
            ).animate().shimmer(duration: 2000.ms),
            const SizedBox(height: 12),
            const Text(
              'Complete 3 more lessons to earn 50 bonus XP!',
              style: TextStyle(
                color: AppColors.textMedium,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPracticeModes(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isGuest = authProvider.isGuest;

    final modes = [
      {
        'name': 'Falling Words',
        'icon': Icons.arrow_downward,
        'color': Colors.purple,
        'count': 20,
        'available': true,
        'isNew': true,
        'modeType': 'falling_words',
      },
      {
        'name': 'Word Match',
        'icon': Icons.compare_arrows,
        'color': Colors.teal,
        'count': 15,
        'available': true,
        'isNew': true,
        'modeType': 'word_match',
      },
      {
        'name': 'Vocabulary Quiz',
        'icon': Icons.quiz,
        'color': AppColors.primaryTeal,
        'count': 15,
        'available': true,
        'isNew': false,
        'modeType': 'vocabulary_quiz',
      },
      {
        'name': 'Flashcards',
        'icon': Icons.style,
        'color': Colors.orange,
        'count': 30,
        'available': !isGuest,
        'isNew': false,
        'modeType': 'flashcards',
      },
      {
        'name': 'Fill in Blank',
        'icon': Icons.edit_note,
        'color': Colors.indigo,
        'count': 12,
        'available': !isGuest,
        'isNew': false,
        'modeType': 'fill_in_blank',
      },
      {
        'name': 'Listening',
        'icon': Icons.hearing,
        'color': Colors.purple,
        'count': 12,
        'available': !isGuest,
        'isNew': false,
        'modeType': 'listening',
      },
      {
        'name': 'Pronunciation',
        'icon': Icons.mic,
        'color': AppColors.accentOrange,
        'count': 8,
        'available': !isGuest,
        'isNew': false,
        'modeType': 'pronunciation',
      },
      {
        'name': 'Speed Challenge',
        'icon': Icons.speed,
        'color': Colors.red,
        'count': 25,
        'available': !isGuest,
        'isNew': false,
        'modeType': 'speed_challenge',
      },
    ];

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
                onPressed: () => _navigateToPracticeModes(context),
                child: const Text('See All'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: modes.length,
            itemBuilder: (context, index) {
              final mode = modes[index];
              final isAvailable = mode['available'] as bool;
              final isNew = mode['isNew'] as bool? ?? false;
              final modeType = mode['modeType'] as String;

              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: GestureDetector(
                  onTap: isAvailable
                      ? () => _launchPracticeMode(context, modeType)
                      : () => _showGuestRestriction(context),
                  child: Container(
                    width: 140,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isAvailable
                            ? [
                                mode['color'] as Color,
                                (mode['color'] as Color).withValues(alpha: 0.8),
                              ]
                            : [
                                Colors.grey,
                                Colors.grey.shade600,
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isAvailable
                                    ? mode['icon'] as IconData
                                    : Icons.lock,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            if (isNew)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text(
                                    'NEW',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          mode['name'] as String,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          isAvailable
                              ? '${mode['count']} questions'
                              : 'Sign in to unlock',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12,
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

  Future<void> _launchPracticeMode(BuildContext context, String modeType) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Load vocabulary
      final courseProvider = context.read<CourseProvider>();
      final activeCourse = courseProvider.activeCourse;
      
      List<VocabularyItem> vocabulary = [];
      if (activeCourse != null) {
        final csvService = CsvDataService();
        vocabulary = await csvService.getVocabulary(
          activeCourse.targetLanguage,
          activeCourse.nativeLanguage,
        );
      }
      
      if (vocabulary.isEmpty) {
        vocabulary = _getDemoVocabulary();
      }

      // Close loading dialog
      if (context.mounted) {
        Navigator.pop(context);
      }
      
      if (!mounted) return;

      // Check minimum vocabulary requirement
      if (vocabulary.length < 4) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Need at least 4 vocabulary words to play'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Navigate to specific mode
      switch (modeType) {
        case 'falling_words':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FallingWordsLauncher(
                vocabulary: vocabulary,
                targetLanguage: 'es',
                nativeLanguage: 'en',
              ),
            ),
          );
          break;
        case 'word_match':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WordMatchLauncher(
                vocabulary: vocabulary,
                targetLanguage: 'es',
                nativeLanguage: 'en',
              ),
            ),
          );
          break;
        case 'vocabulary_quiz':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VocabularyQuizScreen(
                vocabulary: vocabulary,
                targetLanguage: 'es',
                nativeLanguage: 'en',
              ),
            ),
          );
          break;
        case 'flashcards':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FlashcardsScreen(
                vocabulary: vocabulary,
                targetLanguage: 'es',
                nativeLanguage: 'en',
              ),
            ),
          );
          break;
        case 'fill_in_blank':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FillInBlankScreen(
                sentences: const [],
                targetLanguage: 'es',
                nativeLanguage: 'en',
              ),
            ),
          );
          break;
        case 'listening':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ListeningPracticeScreen(
                vocabulary: vocabulary,
                targetLanguage: 'es',
                nativeLanguage: 'en',
              ),
            ),
          );
          break;
        case 'speed_challenge':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SpeedChallengeScreen(
                vocabulary: vocabulary,
                targetLanguage: 'es',
                nativeLanguage: 'en',
              ),
            ),
          );
          break;
        case 'pronunciation':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PronunciationPracticeScreen(
                vocabulary: vocabulary,
                targetLanguage: 'es',
                nativeLanguage: 'en',
              ),
            ),
          );
          break;
        default:
          // Fallback to practice modes list
          _navigateToPracticeModes(context);
      }
    } catch (e) {
      // Close loading dialog
      if (context.mounted) {
        Navigator.pop(context);
      }
      
      if (!mounted) return;
      
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
          'This practice mode is only available for registered users. '
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

  Widget _buildRecentActivity(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Achievements',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildAchievementBadge(
                'Perfect Week',
                Icons.emoji_events,
                AppColors.goldGradient,
              ),
              const SizedBox(width: 12),
              _buildAchievementBadge(
                'Speed Demon',
                Icons.bolt,
                const LinearGradient(
                  colors: [Colors.purple, Colors.deepPurple],
                ),
              ),
              const SizedBox(width: 12),
              _buildAchievementBadge(
                'Word Master',
                Icons.book,
                const LinearGradient(
                  colors: [Colors.blue, Colors.blueAccent],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementBadge(String title, IconData icon, Gradient gradient) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
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
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

