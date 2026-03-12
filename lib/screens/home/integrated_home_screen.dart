import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/auth_provider.dart';
import '../../providers/course_provider.dart';
import '../../theme/app_theme.dart';
import '../../models/study_models.dart';
import '../../models/course_model.dart';

// Import all feature screens
import '../audio/podcast_player_screen.dart';
import '../achievements/achievements_screen.dart';
import '../practice_modes_screen.dart';
import '../auth/register_screen.dart';
import '../home/course_selector_sheet.dart';
import '../home/add_course_screen.dart';
import '../settings_screen.dart';

class IntegratedHomeScreen extends StatefulWidget {
  const IntegratedHomeScreen({super.key});

  @override
  State<IntegratedHomeScreen> createState() => _IntegratedHomeScreenState();
}

class _IntegratedHomeScreenState extends State<IntegratedHomeScreen> {
  Map<String, dynamic>? _lastSession;
  Map<String, dynamic>? _weeklyInsights;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CourseProvider>().loadCourses();
      _loadLastSession();
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
            child: _buildActiveCourseSection(context, activeCourse, courseProvider),
          ),
          SliverToBoxAdapter(
            child: _buildFeatureGrid(context),
          ),
          if (_lastSession != null)
            SliverToBoxAdapter(
              child: _buildQuickResumeCard(context),
            ),
          if (_weeklyInsights != null)
            SliverToBoxAdapter(
              child: _buildWeeklyInsightsCard(),
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
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _navigateToSettings(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.settings,
                        color: Colors.white,
                        size: 20,
                      ),
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

  Widget _buildFeatureGrid(BuildContext context) {
    final features = [
      {
        'icon': Icons.headphones,
        'title': 'Podcasts',
        'subtitle': 'Listen & learn',
        'color': Colors.orange,
        'screen': 'podcasts',
        'available': true,
      },
    ];

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Podcast',
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


  Future<void> _loadLastSession() async {
    final activeCourse = context.read<CourseProvider>().activeCourse;
    final courseId = activeCourse?.id ?? 'demo';
    final targetLanguage = activeCourse?.targetLanguage ?? 'es';
    final nativeLanguage = activeCourse?.nativeLanguage ?? 'en';

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('practice_last_session_${courseId}_$targetLanguage_$nativeLanguage');
    final rawHistory = prefs.getString('practice_session_history_${courseId}_$targetLanguage_$nativeLanguage');

    final history = rawHistory == null
        ? <Map<String, dynamic>>[]
        : (jsonDecode(rawHistory) as List<dynamic>)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();

    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final weekEntries = history.where((entry) {
      final timestamp = entry['timestamp']?.toString();
      final parsed = timestamp == null ? null : DateTime.tryParse(timestamp);
      return parsed != null && parsed.isAfter(weekAgo);
    }).toList();

    String bestMode = 'N/A';
    String improvedArea = 'Consistency';
    double avgAccuracy = 0;

    if (weekEntries.isNotEmpty) {
      final modeCount = <String, int>{};
      final movedCount = <String, int>{};
      double accuracySum = 0;
      int accuracyCount = 0;

      for (final e in weekEntries) {
        final mode = e['mode']?.toString() ?? 'Practice';
        modeCount[mode] = (modeCount[mode] ?? 0) + 1;

        final accuracy = (e['accuracy'] as num?)?.toDouble();
        if (accuracy != null) {
          accuracySum += accuracy;
          accuracyCount++;
        }

        final moved = e['adaptiveMovedTo']?.toString();
        if (moved != null) {
          movedCount[moved] = (movedCount[moved] ?? 0) + 1;
        }
      }

      bestMode = modeCount.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
      if (movedCount.isNotEmpty) {
        improvedArea = 'Difficulty: ${movedCount.entries.reduce((a, b) => a.value >= b.value ? a : b).key}';
      } else if (accuracyCount > 0) {
        improvedArea = 'Accuracy trend';
      }
      avgAccuracy = accuracyCount > 0 ? (accuracySum / accuracyCount) : 0;
    }

    if (!mounted) return;
    setState(() {
      _lastSession = raw == null
          ? null
          : Map<String, dynamic>.from(
              raw.isEmpty ? <String, dynamic>{} : (jsonDecode(raw) as Map<String, dynamic>),
            );
      _weeklyInsights = {
        'sessions': weekEntries.length,
        'avg': avgAccuracy,
        'bestMode': bestMode,
        'improvedArea': improvedArea,
      };
    });
  }

  Widget _buildQuickResumeCard(BuildContext context) {
    final mode = _lastSession?['mode']?.toString() ?? 'Practice';
    final difficulty = _lastSession?['difficulty']?.toString() ?? 'beginner';
    final count = _lastSession?['count']?.toString() ?? '10';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryTeal.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.play_arrow, color: AppColors.primaryTeal),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Quick Resume', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark)),
                const SizedBox(height: 2),
                Text('Continue $mode • ${difficulty[0].toUpperCase()}${difficulty.substring(1)} • $count questions', style: const TextStyle(color: AppColors.textMedium)),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _navigateToAllPracticeModes(context, initialMode: mode),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }


  Widget _buildWeeklyInsightsCard() {
    final sessions = _weeklyInsights?['sessions'] ?? 0;
    final avg = (_weeklyInsights?['avg'] ?? 0).toDouble();
    final bestMode = _weeklyInsights?['bestMode']?.toString() ?? 'N/A';
    final improvedArea = _weeklyInsights?['improvedArea']?.toString() ?? 'Consistency';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Weekly Insights', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark)),
          const SizedBox(height: 8),
          Text('Sessions this week: $sessions', style: const TextStyle(color: AppColors.textMedium)),
          Text('Average accuracy: ${(avg * 100).toStringAsFixed(0)}%', style: const TextStyle(color: AppColors.textMedium)),
          Text('Best mode: $bestMode', style: const TextStyle(color: AppColors.textMedium)),
          Text('Most improved: $improvedArea', style: const TextStyle(color: AppColors.textMedium)),
        ],
      ),
    );
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


  Widget _buildActiveCourseSection(
    BuildContext context,
    CourseModel? activeCourse,
    CourseProvider courseProvider,
  ) {
    final courses = courseProvider.courses;

    return Container(
      margin: const EdgeInsets.all(16),
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
                      gradient: AppColors.tealGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.school, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'My Course',
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
                                Text(activeCourse.nativeLanguageFlag, style: const TextStyle(fontSize: 16)),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progress',
                        style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.8)),
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
                ],
              ),
            ),
            const SizedBox(height: 12),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Icon(Icons.school_outlined, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  const Text(
                    'No Course Selected',
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Add a course to start learning',
                    style: TextStyle(color: AppColors.textMedium, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _navigateToAddCourse(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Course'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryTeal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  void _navigateToSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
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

  void _navigateToAddCourse(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddCourseScreen()),
    );
  }

  void _navigateToFeature(BuildContext context, String feature) {
    switch (feature) {
      case 'podcasts':
        _navigateToPodcasts(context);
        break;
      default:
        _navigateToAllPracticeModes(context);
    }
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

  void _navigateToAllPracticeModes(BuildContext context, {String? initialMode}) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PracticeModesScreen(initialMode: initialMode)),
    );
  }

  void _launchPracticeMode(BuildContext context, String modeType) {
    _navigateToAllPracticeModes(context);

    if (modeType != 'all') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Set your session configuration before starting a quiz.'),
          backgroundColor: AppColors.primaryTeal,
        ),
      );
    }
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
